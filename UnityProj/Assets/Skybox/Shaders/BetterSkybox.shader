Shader "Tholin/Unlit/BetterSky"
{
	Properties
	{
		[NoScaleOffset] _GalaxyTex ("Galaxy Texture", 2D) = "black" {}
		[NoScaleOffset] _StarsTex ("Stars Texture", 2D) = "black" {}
		_Color ("Color", Color) = (1, 1, 1, 1)
		_GalaxyFadeBias ("Galaxy fade bias", Range(-1, 1)) = 0
		_StarsFadeBias ("Stars fade bias", Range(-1, 1)) = 0
		_GalaxyMinBrightness ("Galaxy min brightness", Range(0, 1)) = 0
		_GalaxyMaxBrightness ("Galaxy max brightness", Range(0, 1)) = 1
		_StarsMinBrightness ("Stars min brightness", Range(0, 1)) = 0
		_StarsMaxBrightness ("Stars max brightness", Range(0, 1)) = 1
		_GalaxyColorBias ("Galaxy Color bias", Range(-1, 1)) = 0
		_StarColorBias ("Star Color bias", Range(-1, 1)) = 0
		[Toggle] _NegYFix ("Negative Y texture fix", int) = 0
		_AtmoFade ("Atmo Fade", float) = 0
		_GalaxyAtmoFadeMax ("Galaxy Atmo Fade Max", float) = 1
		_StarsAtmoFadeMax ("Stars Atmo Fade Max", float) = 1
		
		_HaloThreshold ("Halo Threshold Magnitude", float) = 1
		_MaxHalo ("Max Halo Magnitude", float) = 10
		_StarScale ("Star Scale", float) = 2.5
		_HaloBrightness ("Halo Brightness", Range(0, 1)) = 0.1
		
		_GalaxyExposure ("Galaxy Exposure", float) = 1
		_StarsExposure ("Stars Exposure", float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 fades : TEXCOORD1;
				float3 rd : TEXCOORD2;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float biasFunction(float x, float bias);

			sampler2D _GalaxyTex;
			fixed4 _Color;
			float _GalaxyFadeBias;
			float _StarsFadeBias;
			float _GalaxyMinBrightness;
			float _GalaxyMaxBrightness;
			float _StarsMinBrightness;
			float _StarsMaxBrightness;
			float _GalaxyColorBias;
			float _StarColorBias;
			int _NegYFix;
			float _AtmoFade;
			float _GalaxyAtmoFadeMax;
			float _StarsAtmoFadeMax;
			
			Texture2D<float4> _StarsTex;
			float _HaloThreshold;
			float _MaxHalo;
			float _StarScale;
			float _HaloBrightness;
			
			float _GalaxyExposure;
			float _StarsExposure;

			#define MAX_STAR_SIZE 10
			#define TEX_WIDTH 4096
			#define TEX_HEIGHT 2048

			float gcDistance(float2 LL1, float2 LL2) {
				float diffLong = abs(LL1.y - LL2.y);
				float a = sin(LL1.x) * sin(LL2.x);
				float b = cos(LL1.x) * cos(LL2.x) * cos(diffLong);
				float dist = acos(a + b) / UNITY_PI;
				return dist;
			}
			
			half3 starPass(float3 rd) {
				//Star pass
				half3 col = 0;
				{
					float2 uv;
					uv.y = acos(rd.y) / UNITY_PI;
					uv.x = (atan2(rd.z, rd.x) + UNITY_PI) / 2 / UNITY_PI;

					uint2 pixel_base;
					pixel_base.x = (uint)(uv.x * TEX_WIDTH);
					pixel_base.y = (uint)(uv.y * TEX_HEIGHT);

					int star_width = (int)(MAX_STAR_SIZE * (1 + abs(tan((uv.y - 0.5) * UNITY_PI))));
					if(star_width < 0 || star_width >= 256) return 0;

					float2 baseLL = float2(uv.y * UNITY_PI - UNITY_PI * 0.5, uv.x * UNITY_PI * 2 - UNITY_PI);

					for(int i = 0; i < star_width; i++) {
						for(int j = 0; j < MAX_STAR_SIZE; j++) {
							uint2 localuv = pixel_base + uint2(i - star_width / 2 + 1, j - MAX_STAR_SIZE / 2 + 1);
							localuv.x %= TEX_WIDTH;
							if(localuv.x < 0) localuv.x += TEX_WIDTH;
							float4 test = _StarsTex[localuv];
							if(test.a <= 0) continue;
							float2 pixelLL = float2((float)localuv.y / TEX_HEIGHT * UNITY_PI - UNITY_PI * 0.5, (float)localuv.x / TEX_WIDTH * UNITY_PI * 2 - UNITY_PI);
							float gcdist = gcDistance(baseLL, pixelLL);
							gcdist /= _StarScale;
							float magnitude = exp(test.a * 7) - 1;
							float brightness = min(1, magnitude);
							float dotRadius = 4000;
							brightness *= max(0, 1 - gcdist * dotRadius);
							col += test.rgb * brightness;
							#ifndef ON_QUEST
							if(magnitude >= _HaloThreshold) {
								float haloStr = min(1, (magnitude - _HaloThreshold) / (_MaxHalo - _HaloThreshold));
								col += test.rgb * _HaloBrightness * biasFunction(max(0, 1 - gcdist * (1000 + (1 - haloStr) * 2000)), 0.01) * (1 - brightness);
							}
							#endif
						}
					}
				}
				return col * _StarsExposure;
			}

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				if(_NegYFix) o.uv = float2(1, 1) - o.uv;
				float fade = clamp(_Color.r, 0, 1);
				o.fades.x = clamp(biasFunction(fade, _GalaxyFadeBias), _GalaxyMinBrightness * (1.0 - clamp(_AtmoFade, 0, _GalaxyAtmoFadeMax)), _GalaxyMaxBrightness);
				o.fades.y = clamp(biasFunction(fade, _StarsFadeBias), _StarsMinBrightness * (1.0 - clamp(_AtmoFade, 0, _StarsAtmoFadeMax)), _StarsMaxBrightness);
				o.fades.z = _Color.r;
				o.rd = v.vertex.xyz;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 colG = tex2D(_GalaxyTex, i.uv) * _GalaxyExposure * i.fades.x;
				colG.r = biasFunction(colG.r, _GalaxyColorBias);
				colG.g = biasFunction(colG.g, _GalaxyColorBias);
				colG.b = biasFunction(colG.b, _GalaxyColorBias);
				fixed3 aaa = starPass(normalize(i.rd));
				fixed4 colS = fixed4(aaa.r, aaa.g, aaa.b, 1) * i.fades.y;
				colS.r = biasFunction(colS.r, _StarColorBias);
				colS.g = biasFunction(colS.g, _StarColorBias);
				colS.b = biasFunction(colS.b, _StarColorBias);
				colG *= 1.0 - colS;
				colG += colS;
				colG.a = 1;
				return colG;
			}

			float biasFunction(float x, float bias) {
				float k = 1.0 - bias;
				k = k * k * k;
				return (x * k) / (x * k - x + 1.0);
			}
			ENDCG
			}
		}
}
