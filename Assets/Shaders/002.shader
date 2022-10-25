// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "TOON/001" {
	Properties {
		// 漫反射颜色
		// _Diffuse ("Color", Color) = (1, 1, 1, 1)
		// 描边宽度
		_OutlineWidth ("Outline Width", Range(0.01, 1)) = 0.01
		// 描边颜色
		_OutLineColor ("OutLine Color", Color) = (0.5,0.5,0.5,1)

		// 交界起始
		_RampStart ("RampStart", Range(0.1, 1)) = 0.3
		// 交界大小
        _RampSize ("RampSize", Range(0, 1)) = 0.1
		// 交界段数
        [IntRange] _RampStep("RampStep", Range(1,10)) = 1
		// 交界柔和度
        _RampSmooth ("RampSmooth", Range(0.01, 1)) = 0.1
		// 暗面
		_DarkColor ("DarkColor", Color) = (0.4, 0.4, 0.4, 1)
		// 亮面
        _LightColor ("LightColor", Color) = (0.8, 0.8, 0.8, 1)
	}
	SubShader {	
		Pass {
			// Tags { "LightMode"="ForwardBase" }

			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"

			// fixed4 _Diffuse;

			fixed _RampStart;
			fixed _RampSize;
			int _RampStep;
			float _RampSmooth;
			float4 _DarkColor;
			float4 _LightColor;

			float linearstep (float min, float max, float t)
            {
                return saturate((t - min) / (max - min));
            }

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
			};

			v2f vert (a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				// o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));

				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 worldNormal = normalize(i.worldNormal);
				//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 worldLightDir = UnityWorldSpaceLightDir(i.pos);
				fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;

				float ramp = linearstep(_RampStart, _RampStart + _RampSize, halfLambert);
				float step = ramp * _RampStep;
				float gridStep = floor(step);
				float smoothStep = smoothstep(gridStep, gridStep + _RampSmooth, step) + gridStep;
				ramp = smoothStep / _RampStep;
				float3 rampColor = lerp(_DarkColor, _LightColor, ramp);
				// rampColor *= _Diffuse;

				fixed3 diffuse = _LightColor0.rgb * rampColor.rgb * halfLambert;

				return fixed4(ambient + diffuse, 1.0);
			}
			ENDCG
		}

		Pass {
			Cull Front

			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"

			float _OutlineWidth;
			// 因为直接拾取返回颜色值
			float4 _OutLineColor;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
			};

			v2f vert (a2v v) {
				v2f o;
				float4 outer_vertex = float4(v.vertex.xyz + normalize(v.normal) * 0.05 * _OutlineWidth, 1);
				o.pos = UnityObjectToClipPos(outer_vertex);

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
            {
                return _OutLineColor;
            }

			ENDCG
		}
	}
	fallback"Diffuse"
}