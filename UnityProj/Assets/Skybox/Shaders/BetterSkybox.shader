Shader "Tholin/Unlit/BetterSky"
{
	Properties
	{
		_GalaxyTex ("Galaxy Texture", 2D) = "black" {}
		_StarTex ("Stars Texture", 2D) = "black" {}
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
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float biasFunction(float x, float bias);

			sampler2D _GalaxyTex;
			sampler2D _StarTex;
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
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 colG = tex2D(_GalaxyTex, i.uv) * i.fades.x;
				colG.r = biasFunction(colG.r, _GalaxyColorBias);
				colG.g = biasFunction(colG.g, _GalaxyColorBias);
				colG.b = biasFunction(colG.b, _GalaxyColorBias);
				fixed4 colS = tex2D(_StarTex, i.uv) * i.fades.y;
				colS.r = biasFunction(colS.r, _StarColorBias);
				colS.g = biasFunction(colS.g, _StarColorBias);
				colS.b = biasFunction(colS.b, _StarColorBias);
				colG *= 1.0 - colS;
				colG += colS;
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
