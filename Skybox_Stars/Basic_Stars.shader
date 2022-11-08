// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Basic_Stars" {
    Properties {
        _StarNoiseTex ("StarNoise", 2D) = "white" {}

        _StarShinningSpeed ("星星闪烁速度 StarShinningSpeed", Range(0, 1)) = 0.1
        _StarCount("星星数量 StarCount", Range(0,1)) = 0.3
        
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

            sampler2D _StarNoiseTex;
            float4 _StarNoiseTex_ST;
            float _StarShinningSpeed;
            float _StarCount;

            float3 _SkyColor;
            float _SkyCurvature;
            float _SkyLineSize;
            float _SkyLineBasePow;

            fixed4 frag(v2f i) : SV_Target {
                float3 color = 0;

                float starTime = _Time.y * _StarShinningSpeed;

                float2 beginMove = floor(starTime) * 0.3;
                float2 endMove = ceil(starTime) * 0.3;
                float2 beginUV = i.uv + beginMove;
                float2 endUV = i.uv + endMove;

                float beginNoise = tex2D(_StarNoiseTex, TRANSFORM_TEX(beginUV, _StarNoiseTex)).r;
                float endNoise = tex2D(_StarNoiseTex, TRANSFORM_TEX(endUV, _StarNoiseTex)).r;

                beginNoise = saturate(beginNoise - (1 - _StarCount)) / _StarCount;
                endNoise = saturate(endNoise - (1 - _StarCount)) / _StarCount;

                float fracStarTime = frac(starTime);
                float starColor = saturate(beginNoise - fracStarTime) + saturate(endNoise - (1 - fracStarTime)); 

                // 天空色
                color += _SkyColor;
                color += starColor * 0.9;

                return fixed4(color, 1);
            }
            ENDCG
        }
    }
    // FallBack "Diffuse"
}
