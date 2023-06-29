Shader "Custom/PBR - Cook Torrance" {
	Properties {
		_Color("Color", Color) = (255,255,255,255)
		_MainTex ("Diffuse Map", 2D) = "white" {}
		_BumpTex ("Normal Map", 2D) = "bump" {}
		_Metalness ("Metalness", Range(0,1)) = 1 
		_Roughness ("Roughness", Range(0.01, 1)) = 1
		_SpecTex ("Roughness Map", 2D) = "white" {}
		_Cubemap ("Reflection Cubemap", CUBE) = "black" {}
	}
	SubShader {
		Tags { "Queue"="Geometry" }
		LOD 450
		
		CGPROGRAM
		#pragma surface surf CookTorrance
		#pragma target 3.0

		half4 _Color;
		half _Roughness;
		half _Metalness;
		half _Fresnel;
		sampler2D _MainTex;
		sampler2D _SpecTex;
		sampler2D _BumpTex;
		samplerCUBE _Cubemap;
		
		struct Input {
			float2 uv_MainTex;
			float3 worldRefl;
			INTERNAL_DATA
		};
		
		half3 GetLuminance(float3 color)
		{
			half lum = dot(color, half3(0.22, 0.707, 0.071));
			return half3(lum, lum, lum);
		}
		
		half SpecFunc(SurfaceOutput s, half3 lightDir, half3 viewDir)
		{
			const float pi = 3.14159265f;
			
			float3 halfV = normalize((lightDir + viewDir));
			float HdotVInverse = 1f - saturate(dot(halfV, viewDir));
		
			float NdotH = saturate(dot(s.Normal, halfV));
			float NdotV = saturate(dot(s.Normal, viewDir));
			float VdotH = saturate(dot(viewDir, halfV));
			float NdotL = saturate(dot(s.Normal, lightDir));
			float HdotL = saturate(dot(halfV, lightDir));
			
			float NdotHsq = NdotH * NdotH;
			
			float roughness2 = pow(s.Specular, 0.3f);
			float specPower = lerp(1f, 250f, s.Specular);
			float beck1 = 1f / pi * roughness2 * pow(NdotH, specPower);
			float beckExp = (NdotHsq - 1f) / (roughness2 * NdotHsq);
			
			float beckmann = beck1 * exp(beckExp);
			
			float fSchlick = pow(HdotVInverse, 5f) * (1f - 1f);
			fSchlick = fSchlick + 1f;
			
			float geomAttenA = (2f * (NdotH) * (NdotV))/VdotH;
			float geomAttenB = (2f * (NdotH) * (NdotL))/VdotH;
			
			float geomAtten = min(geomAttenA, geomAttenB);
			geomAtten = min(1f, geomAtten);
			
			float spec = saturate((fSchlick * beckmann * geomAtten)/(pi*NdotL*NdotV));
			return spec;
		}

		half4 LightingCookTorrance(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
		{
			float lambert = saturate(dot(s.Normal, lightDir));
			float3 diff = lambert * s.Albedo * _LightColor0.rgb;
			float3 diffLuminance = GetLuminance(diff);
			
			float specReflect = SpecFunc(s, lightDir, viewDir);
			float diffFactor = lerp(0.18f, 0.05f, s.Specular);
			
			float3 finalDiffuse = lerp(diff, diffLuminance, (1f - _Metalness));
			
			float4 cookTorrance =  (float4(finalDiffuse, 1)) * (diffFactor + ((1f - diffFactor) * specReflect));
			
			return cookTorrance * atten * 2.8f;
		}
		
		void surf (Input IN, inout SurfaceOutput o)
		{
			half3 color = tex2D(_MainTex, IN.uv_MainTex).rgb;
			half3 spec = GetLuminance(tex2D(_SpecTex, IN.uv_MainTex).rgb);
			
			float cubeMapBlur = lerp(15f, 0f, ((_Metalness + _Roughness)/2f));
			
			o.Normal = UnpackNormal(tex2D(_BumpTex, IN.uv_MainTex));
			half3 cubeMap = texCUBElod(_Cubemap, float4(WorldReflectionVector(IN, o.Normal), cubeMapBlur)).rgb;
			
			color = lerp(color.rgb, cubeMap, float3(_Metalness, _Metalness, _Metalness));
			
			o.Albedo = color * _Color.rgb;
			o.Specular = spec.r * _Roughness;
		}

		ENDCG
	}
	Fallback "Bumped Specular"
}