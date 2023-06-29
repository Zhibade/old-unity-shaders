Shader "Custom/Refraction - Cubemap" {
	Properties {
		_Color("Tint Color", Color) = (255,255,255,255)
		_MainTex ("Tint Map", 2D) = "white" {}
		_Cube("Cubemap", Cube) = "" {}
		_BumpMap ("Refraction Bump", 2D) = "bump" {}
		_RefractionIndex ("Refractive Index", Float) = 1.5
		
	}
	SubShader {
		Tags { "Queue"="Transparent" }
		LOD 450
		
		Pass {

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			half4 _Color;
			sampler2D _MainTex;
			samplerCUBE _Cube;
			sampler2D _BumpMap;
			half _RefractionIndex;

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
				
				return o;
			}
			
			half4 frag(vOut i) : COLOR
			{
				half4 bumpMap = tex2D(_BumpMap, i.uv);
				half3 normalMap = UnpackNormal(bumpMap);
				half3 finalNormal = normalize(i.normal + (normalMap.x * i.tangent + normalMap.y * i.binormal));
				half3 refractedDir = refract(normalize(i.viewDir), finalNormal, 1.0/_RefractionIndex);
				
				half4 finalColor = _Color * tex2D(_MainTex, i.uv);
				
				return texCUBE(_Cube, refractedDir) * finalColor;
			}
			ENDCG
		}
	}
}
