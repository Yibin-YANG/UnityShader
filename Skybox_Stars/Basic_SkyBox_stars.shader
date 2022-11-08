// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Basic_SkyBox_Stars" {
    Properties {
        _MainTex ("AurorasTexture", 2D) = "white" {}
        _StarNoiseTex ("StarNoise", 2D) = "white" {}

        _StarShinningSpeed ("星星闪烁速度 StarShinningSpeed", Range(0, 1)) = 0.1
        _StarCount("星星数量 StarCount", Range(0,1)) = 0.3
        
        _AurorasNoiseTex ("AurorasNoise", 2D) = "white" {}
        _AurorasTiling("极光平铺 AurorasTiling", Range(0.1, 10)) = 0.4
        _AurorasColor ("极光颜色 AurorasColor", Color) = (0.4, 0.4, 0.4, 1)
        _AurorasIntensity("极光强度 AurorasIntensity", Range(0.1, 20)) = 3
        _AurorasAttenuation("极光衰减 AurorasAttenuation", Range(0, 0.99)) = 0.4
        _AurorasSpeed ("极光变化速度 AurorasSpeed", Range(0.01, 1)) = 0.1

        [IntRange] _RayMarchStep("步进步数 RayMarchStep", Range(1,128)) = 64
        _RayMarchDistance("步进距离 RayMarchDistance", Range(0.01, 1)) = 2.5
        
        _SkyColor ("天空颜色 SkyColor", Color) = (0.4, 0.4, 0.4, 1)
        _SkyCurvature ("天空曲率 SkyCurvature", Range(0, 10)) = 0.4
        _SkyLineSize("天际线大小 SkyLineSize", Range(0, 1)) = 0.06
        _SkyLineBasePow("天际线基础强度 SkyLineBasePow", Range(0, 1)) = 0.1
    }
    SubShader {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
		    #include "UnityLightingCommon.cginc"

            #pragma multi_compile_fog

            struct a2v {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert(a2v v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(v.vertex, unity_ObjectToWorld);
                o.uv = v.uv;

                return o;
            }

            sampler2D _MainTex;
            sampler2D _AurorasNoiseTex;
            sampler2D _StarNoiseTex;
            float4 _MainTex_ST;
            float4 _AurorasNoiseTex_ST;
            float4 _StarNoiseTex_ST;

            float _StarShinningSpeed;
            float _StarCount;

            float3 _SkyColor;
            float _SkyCurvature;
            float _SkyLineSize;
            float _SkyLineBasePow;

            float _AurorasTiling;
            float3 _AurorasColor;
            float _AurorasIntensity;
            float _AurorasAttenuation;
            float _AurorasSpeed;

            float _RayMarchStep;
            float _RayMarchDistance;

            fixed4 frag(v2f i) : SV_Target {

                // 发射射线
                float3 rayOriginal = 0;
                float3 totalDir = i.worldPos - rayOriginal;
                float3 rayDir = normalize(totalDir);
                // 天空曲率
                float skyCurvatureFactor = rcp(rayDir.y + _SkyCurvature);
                float3 basicRayPlane = rayDir * skyCurvatureFactor * _AurorasTiling;
                float3 rayMarchBegin = rayOriginal + basicRayPlane;

                float3 color = 0;
                float3 avgColor = 0;
                float stepSize = rcp(_RayMarchStep);

                for (float j = 0; j < _RayMarchStep; j++) {
                    float curStep = stepSize * j;
                    curStep = curStep * curStep;
                    float curDistance = curStep * _RayMarchDistance;
                    float3 curPos = rayMarchBegin + rayDir * curDistance * skyCurvatureFactor;
                    float2 uv = float2(-curPos.x,curPos.z);

		            float2 warp_vec = tex2D(_AurorasNoiseTex,TRANSFORM_TEX((uv * 2 + _Time.y * _AurorasSpeed),_AurorasNoiseTex));

                    float curNoise = tex2D(_MainTex, TRANSFORM_TEX((uv + warp_vec * 0.1), _MainTex)).r;

                    curNoise = curNoise * saturate(1 - pow(curDistance, 1 - _AurorasAttenuation));

                    float3 curColor = sin((_AurorasColor * 2 - 1) + j * 0.043) * 0.5 + 0.5;

                    avgColor = (avgColor + curColor) / 2;

                    color += avgColor * curNoise * stepSize;
                }
                // 叠加星空
                const float starTime = _Time.y * _StarShinningSpeed;

                const float2 beginMove = floor(starTime) * 0.3;
                const float2 endMove = ceil(starTime) * 0.3;
                const float2 beginUV = i.uv + beginMove;
                const float2 endUV = i.uv + endMove;

                float beginNoise = tex2D(_StarNoiseTex, TRANSFORM_TEX(beginUV, _StarNoiseTex)).r;
                float endNoise = tex2D(_StarNoiseTex, TRANSFORM_TEX(endUV, _StarNoiseTex)).r;

                beginNoise = saturate(beginNoise - (1 - _StarCount)) / _StarCount;
                endNoise = saturate(endNoise - (1 - _StarCount)) / _StarCount;

                const float fracStarTime = frac(starTime);
                float starColor = saturate(beginNoise - fracStarTime) + saturate(endNoise - (1 - fracStarTime));

                color *= _AurorasIntensity;
                
                // 混合天际线
                color *= saturate(rayDir.y / _SkyLineSize + _SkyLineBasePow);

                // 天空色
                color += _SkyColor;

                color = color + starColor * 0.9;

                return fixed4(color, 1);
            }
            ENDCG
        }
    }
    // FallBack "Diffuse"
}
