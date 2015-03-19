Shader "Linear Lighting/Sprites/Diffuse" {
	Properties {
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		
		_Color ("Tint", Color) = (1,1,1,1)
		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
	}
	
	SubShader {
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
		
		Cull Off
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		
		Blend SrcAlpha OneMinusSrcAlpha
		
		Alphatest Greater 0 ZWrite Off ColorMask RGB
		
		Pass {
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			#include "LinLighting.cginc"
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile DUMMY PIXELSNAP_ON
			#pragma multi_compile_fwdbasealpha
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#define UNITY_PASS_FORWARDBASE
			#include "UnityCGGoLin.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			#define INTERNAL_DATA
			#define WorldReflectionVector(data,normal) data.worldRefl
			#define WorldNormalVector(data,normal) normal
			
			sampler2D _MainTex;
			fixed4 _Color;
			
			struct Input
			{
				float2 uv_MainTex;
				fixed4 color;
			};
			
			void vert (inout appdata_full v, out Input o)
			{
				#if defined(PIXELSNAP_ON) && !defined(SHADER_API_FLASH)
				v.vertex = UnityPixelSnap (v.vertex);
				#endif
				
				v.normal = float3(0,0,-1);
				
				UNITY_INITIALIZE_OUTPUT(Input, o);
				o.color = LLDecodeGamma( _Color );
			}
			
			void surf (Input IN, inout SurfaceOutput o)
			{
				fixed4 c = LLDecodeTex( tex2D(_MainTex, IN.uv_MainTex) ) * IN.color;
				o.Albedo = c.rgb;
				o.Alpha = c.a;
			}
			
			#ifdef LIGHTMAP_OFF
				struct v2f_surf {
					float4 pos : SV_POSITION;
					float2 pack0 : TEXCOORD0;
					half4 cust_color : TEXCOORD1;
					fixed3 normal : TEXCOORD2;
					fixed3 vlight : TEXCOORD3;
					LIGHTING_COORDS(4,5)
				};
			#endif
			
			#ifndef LIGHTMAP_OFF
				struct v2f_surf {
					float4 pos : SV_POSITION;
					float2 pack0 : TEXCOORD0;
					half4 cust_color : TEXCOORD1;
					float2 lmap : TEXCOORD2;
					LIGHTING_COORDS(3,4)
				};
			#endif
			
			#ifndef LIGHTMAP_OFF
				float4 unity_LightmapST;
			#endif
			
			float4 _MainTex_ST;
			
			v2f_surf vert_surf (appdata_full v) {
				v2f_surf o;
				Input customInputData;
				vert (v, customInputData);
				o.cust_color = customInputData.color;
				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				
				#ifndef LIGHTMAP_OFF
					o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif
				
				float3 worldN = mul((float3x3)_Object2World, SCALED_NORMAL);
				
				#ifdef LIGHTMAP_OFF
					o.normal = worldN;
				#endif
				
				#ifdef LIGHTMAP_OFF
					float3 shlight = ShadeSH9 (float4(worldN,1.0));
					o.vlight = shlight;
					
					#ifdef VERTEXLIGHT_ON
						float3 worldPos = mul(_Object2World, v.vertex).xyz;
						o.vlight += Shade4PointLights (
						unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
						unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
						unity_4LightAtten0, worldPos, worldN );
					#endif

				#endif
				
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			
			#ifndef LIGHTMAP_OFF
				sampler2D unity_Lightmap;
				
				#ifndef DIRLIGHTMAP_OFF
					sampler2D unity_LightmapInd;
				#endif

			#endif
			
			fixed4 frag_surf (v2f_surf IN) : COLOR {
				Input surfIN;
				surfIN.uv_MainTex = IN.pack0.xy;
				surfIN.color = IN.cust_color;
				
				#ifdef UNITY_COMPILER_HLSL
					SurfaceOutput o = (SurfaceOutput)0;
					#else
					SurfaceOutput o;
				#endif
				
				o.Albedo = 0.0;
				o.Emission = 0.0;
				o.Specular = 0.0;
				o.Alpha = 0.0;
				o.Gloss = 0.0;
				
				#ifdef LIGHTMAP_OFF
					o.Normal = IN.normal;
				#endif
				
				surf (surfIN, o);
				fixed atten = LIGHT_ATTENUATION(IN);
				fixed4 c = 0;
				
				#ifdef LIGHTMAP_OFF
					c = LightingLambert (o, _WorldSpaceLightPos0.xyz, atten);
				#endif
				
				#ifdef LIGHTMAP_OFF
					c.rgb += o.Albedo * IN.vlight;
				#endif
				
				#ifndef LIGHTMAP_OFF
					
					#ifndef DIRLIGHTMAP_OFF
						fixed4 lmtex = tex2D(unity_Lightmap, IN.lmap.xy);
						fixed4 lmIndTex = tex2D(unity_LightmapInd, IN.lmap.xy);
						half3 lm = LightingLambert_DirLightmap(o, lmtex, lmIndTex, 0).rgb;
						#else 
						fixed4 lmtex = tex2D(unity_Lightmap, IN.lmap.xy);
						fixed3 lm = DecodeLightmap (lmtex);
					#endif
					
					#ifdef SHADOWS_SCREEN
						#if (defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)) && defined(SHADER_API_MOBILE)
						c.rgb += o.Albedo * min(lm, atten*2);
						#else
						c.rgb += o.Albedo * max(min(lm,(atten*2)*lmtex.rgb), lm*atten);
					#endif
					
					#else 
					c.rgb += o.Albedo * lm;
				#endif
				
				c.a = o.Alpha;
			#endif
			
			c.a = o.Alpha;
			
			return LLEncodeGamma( c );
		}
		
		ENDCG
	}
	
	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardAdd" }
		ZWrite Off Blend One One Fog { Color (0,0,0,0) }
		
		Blend SrcAlpha One
		
		CGPROGRAM
		#include "LinLighting.cginc"
		#pragma vertex vert_surf
		#pragma fragment frag_surf
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma multi_compile DUMMY PIXELSNAP_ON
		#pragma multi_compile_fwdadd
		#include "HLSLSupport.cginc"
		#include "UnityShaderVariables.cginc"
		#define UNITY_PASS_FORWARDADD
		#include "UnityCGGoLin.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"
		
		#define INTERNAL_DATA
		#define WorldReflectionVector(data,normal) data.worldRefl
		#define WorldNormalVector(data,normal) normal
		
		sampler2D _MainTex;
		fixed4 _Color;
		
		struct Input
		{
			float2 uv_MainTex;
			fixed4 color;
		};
		
		void vert (inout appdata_full v, out Input o)
		{
			#if defined(PIXELSNAP_ON) && !defined(SHADER_API_FLASH)
			v.vertex = UnityPixelSnap (v.vertex);
			#endif
			
			v.normal = float3(0,0,-1);
			
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.color = LLDecodeGamma( _Color );
		}
		
		void surf (Input IN, inout SurfaceOutput o)
		{
			fixed4 c = LLDecodeTex( tex2D(_MainTex, IN.uv_MainTex) ) * IN.color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		
		struct v2f_surf {
			float4 pos : SV_POSITION;
			float2 pack0 : TEXCOORD0;
			half4 cust_color : TEXCOORD1;
			fixed3 normal : TEXCOORD2;
			half3 lightDir : TEXCOORD3;
			LIGHTING_COORDS(4,5)
		};
		
		float4 _MainTex_ST;
		
		v2f_surf vert_surf (appdata_full v) {
			v2f_surf o;
			Input customInputData;
			vert (v, customInputData);
			o.cust_color = customInputData.color;
			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.normal = mul((float3x3)_Object2World, SCALED_NORMAL);
			float3 lightDir = WorldSpaceLightDir( v.vertex );
			o.lightDir = lightDir;
			TRANSFER_VERTEX_TO_FRAGMENT(o);
			return o;
		}
		
		fixed4 frag_surf (v2f_surf IN) : COLOR {
			Input surfIN;
			surfIN.uv_MainTex = IN.pack0.xy;
			surfIN.color = IN.cust_color;
			
			#ifdef UNITY_COMPILER_HLSL
				SurfaceOutput o = (SurfaceOutput)0;
				#else
				SurfaceOutput o;
			#endif
			
			o.Albedo = 0.0;
			o.Emission = 0.0;
			o.Specular = 0.0;
			o.Alpha = 0.0;
			o.Gloss = 0.0;
			o.Normal = IN.normal;
			surf (surfIN, o);
			
			#ifndef USING_DIRECTIONAL_LIGHT
				fixed3 lightDir = normalize(IN.lightDir);
				#else
				fixed3 lightDir = IN.lightDir;
			#endif
			
			fixed4 c = LightingLambert (o, lightDir, LIGHT_ATTENUATION(IN));
			c.a = o.Alpha;
			
			return LLEncodeGamma( c );
		}
		
		ENDCG
	}
}

Fallback "Linear Lighting/Transparent/VertexLit CG"
}


//Original shader:

//Shader "Sprites/Diffuse"
//{
//	Properties
//	{
//		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
//		_Color ("Tint", Color) = (1,1,1,1)
//		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
//	}
//
//	SubShader
//	{
//		Tags
//		{ 
//			"Queue"="Transparent" 
//			"IgnoreProjector"="True" 
//			"RenderType"="Transparent" 
//			"PreviewType"="Plane"
//			"CanUseSpriteAtlas"="True"
//		}
//
//		Cull Off
//		Lighting Off
//		ZWrite Off
//		Fog { Mode Off }
//		Blend SrcAlpha OneMinusSrcAlpha
//
//		CGPROGRAM
//		#pragma debug
//		#pragma surface surf Lambert alpha vertex:vert
//		#pragma multi_compile DUMMY PIXELSNAP_ON
//
//		sampler2D _MainTex;
//		fixed4 _Color;
//
//		struct Input
//		{
//			float2 uv_MainTex;
//			fixed4 color;
//		};
//		
//		void vert (inout appdata_full v, out Input o)
//		{
//			#if defined(PIXELSNAP_ON) && !defined(SHADER_API_FLASH)
//			v.vertex = UnityPixelSnap (v.vertex);
//			#endif
//			v.normal = float3(0,0,-1);
//			
//			UNITY_INITIALIZE_OUTPUT(Input, o);
//			o.color = _Color;
//		}
//
//		void surf (Input IN, inout SurfaceOutput o)
//		{
//			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * IN.color;
//			o.Albedo = c.rgb;
//			o.Alpha = c.a;
//		}
//		ENDCG
//	}
//
//Fallback "Transparent/VertexLit"
//}