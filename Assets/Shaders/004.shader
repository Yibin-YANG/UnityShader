// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "TOON/004" {
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

		// 光泽度
		_SpecPow("SpecPow", Range(0, 1)) = 0.1
		// 高光
        _SpecularColor ("SpecularColor", Color) = (1.0, 1.0, 1.0, 1)
		// 高光强度
        _SpecIntensity("SpecIntensity", Range(0, 1)) = 0
		// 高光柔和度
        _SpecSmooth("SpecSmooth", Range(0, 0.5)) = 0.1

		// 边缘光
        _RimColor ("RimColor", Color) = (1.0, 1.0, 1.0, 1)
		// 边缘光阈值
        _RimThreshold("RimThreshold", Range(0, 1)) = 0.45
		// 边缘光柔和度
        _RimSmooth("RimSmooth", Range(0, 0.5)) = 0.1
	}
	SubShader {	
		Pass {
			// Tags { "LightMode"="ForwardBase" }

			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"

			// 色阶
			fixed _RampStart;
			fixed _RampSize;
			int _RampStep;
			float _RampSmooth;
			float4 _DarkColor;
			float4 _LightColor;

			// 高光
			float _SpecPow;
			float3 _SpecularColor;
			float _SpecIntensity;
			float _SpecSmooth;

			// 边缘光
			float3 _RimColor;
			float _RimThreshold;
			float _RimSmooth;

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
				float3 worldPos : TEXCOORD1;
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
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.pos));
				fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;

				float ramp = linearstep(_RampStart, _RampStart + _RampSize, halfLambert);
				float step = ramp * _RampStep;
				float gridStep = floor(step);
				float smoothStep = smoothstep(gridStep, gridStep + _RampSmooth, step) + gridStep;
				ramp = smoothStep / _RampStep;
				float3 rampColor = lerp(_DarkColor, _LightColor, ramp);

				fixed3 diffuse = _LightColor0.rgb * rampColor.rgb * halfLambert;	
				
				// Phong光照模型实现
				/*
				fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float phong = pow(saturate(dot(reflectDir, viewDir)), _SpecPow * 128.0);
				fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * phong;
				*/

				// Blinn_Phong光照模型实现
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(viewDir + worldLightDir);
				float bilnn_phong = dot(halfDir, worldNormal);
				float3 specular = smoothstep(0.7 - _SpecSmooth / 2, 0.7 + _SpecSmooth / 2, bilnn_phong) 
									* _SpecularColor * _SpecIntensity;      

				float cos_rim = dot(viewDir, worldNormal);
				float value_rim = (1 - saturate(cos_rim)) * (halfLambert - 0.5) * 2; // 也可直接 * halfLambert
				float rim = smoothstep(_RimThreshold - _RimSmooth / 2, _RimThreshold + _RimSmooth / 2, value_rim) * _RimColor;

				return fixed4(saturate(ambient + diffuse + specular + rim), 1.0);
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
	fallback "Specular"
}