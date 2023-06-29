Shader "Custom/Refraction - Realtime" {
	Properties {
		_Color("Tint Color", Color) = (255,255,255,255)
		_MainTex ("Tint Map", 2D) = "white" {}
		_BumpMap ("Refraction Bump", 2D) = "bump" {}
		_Distortion("Distortion", Range(0.00,0.5)) = 0.05
	}
	SubShader {
		Tags { "Queue"="Transparency" }
		LOD 450
		
		GrabPass {                            
            Name "BASE"
            Tags { "LightMode" = "Always" }
         }
		
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			sampler2D _GrabTexture;
			half4 _Color;
			sampler2D _MainTex;
			sampler2D _BumpMap;
			half _Distortion;

			struct vIn
			{
				float4 vertex: POSITION;
				float3 normal: NORMAL;
				float3 tangent: TANGENT;
				float2 uv: TEXCOORD0;
			};
			
			struct vOut
			{
				float4 pos: SV_POSITION;
				float3 normal: TEXCOORD1;
				float3 tangent: TEXCOORD2;
				float3 binormal: TEXCOORD3;
				float3 viewDir: TEXCOORD4;
				float2 uv: TEXCOORD0;
				float4 screenUV: TEXCOORD5;
			};
			
			vOut vert(vIn i)
			{
				vOut o;
				
				float4x4 modelMatrix = _Object2World;
				float4x4 modelMatrixInverse = _World2Object;
				
				o.viewDir = mul(modelMatrix, i.vertex).xyz - _WorldSpaceCameraPos;
				
				o.normal = normalize(mul(float4(i.normal, 0.0), modelMatrixInverse).xyz);
				o.tangent = normalize(mul(float4(i.tangent, 0.0), modelMatrixInverse).xyz);
				o.binormal = normalize(cross(o.normal, o.tangent));
				
				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
				
				o.uv = i.uv;
				o.screenUV = o.pos;
				
				return o;
			}
			
			half4 frag(vOut i) : COLOR
			{
				half4 bumpMap = tex2D(_BumpMap, i.uv);
				half3 normalMap = UnpackNormal(bumpMap);
				half3 finalNormal = normalize(i.normal + (normalMap.x * i.tangent + normalMap.y * i.binormal));
				
				half4 finalColor = _Color * tex2D(_MainTex, i.uv);
				finalColor.w = 0;
			
				half2 screenUV = i.screenUV.xy/i.screenUV.w;
				screenUV.xy = (screenUV.xy + 1) * 0.5; // Transform screen position grab from -1-1, to 0-1
				screenUV.y = 1 - screenUV.y; // Invert y position of the screen grab UVs
				
				half4 grabTexDistort = tex2D(_GrabTexture, screenUV +  finalNormal.xy * _Distortion);
				grabTexDistort.w = 1;
				half4 finalDistortion = grabTexDistort;
				
				return finalDistortion * finalColor;
			}
			ENDCG
		}
	}
}
