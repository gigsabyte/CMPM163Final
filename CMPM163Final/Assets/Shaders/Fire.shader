// Combination of hologram and multi texture phong shader

Shader "CM163/Fire"
{

	Properties
	{
		_Amplitude("Amplitude", Float) = 1					// Amplitude of the flame
		_Speed("Speed", Float) = 1							// Speed that flame moves
		_FlameBase("FlameBase", Float) = 0					// Starting point for where in the mesh the flame begins ( 0 = center on y-axis)
		_SampleSpace("SampleSpace", Float) = 0.2			// Noise Sampler for flame height
		_SampleSpace2("SampleSpace2", Float) = 0.2			// Noise Sampler for transparency variance
		_Color1("Color1", Color) = (1,0,0,1)				// Bottom color
		_Color2("Color2", Color) = (1,1,0,1)				// Top color
		_ColorMixer("ColorMixer", Float) = 2				// How the colors mix ( the math was hard, just slide it around til it looks good)
		_Transparency("Transparency", Float) = 1			// Base Transparency (gets modified +/- by noise)
		_Outline("Outline", Float) = 0.1					// Outline Thickness
		_OutlineColor("OutlineColor", Color) = (1,1,0,0)	// Outline Color
		_OutlineTrans("OutlineTrans", Float) = 0.5			// Outline Transparency
	}

	SubShader
	{
		// tags for transparency
		Tags {"Queue" = "Transparent" "RenderType" = "Transparent" }

		// Level Of Detail
		LOD 100
		// depth buffer control
		ZWrite Off
		// traditional transparency
		Blend SrcAlpha OneMinusSrcAlpha

		// PASS 1:
		//========
		// Outliner
		//	with outline color
		Pass
		{
			Cull Front

			CGPROGRAM
			// set pragmas
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			//======================================================================================================================
			// Noise Shader Library for Unity - https://github.com/keijiro/NoiseShader
			//
			// Original work (webgl-noise) Copyright (C) 2011 Stefan Gustavson
			// Translation and modification was made by Keijiro Takahashi.
			//
			// This shader is based on the webgl-noise GLSL shader. For further details
			// of the original shader, please see the following description from the
			// original source code.
			//

			//
			// GLSL textureless classic 2D noise "cnoise",
			// with an RSL-style periodic variant "pnoise".
			// Author:  Stefan Gustavson (stefan.gustavson@liu.se)
			// Version: 2011-08-22
			//
			// Many thanks to Ian McEwan of Ashima Arts for the
			// ideas for permutation and gradient selection.
			//
			// Copyright (c) 2011 Stefan Gustavson. All rights reserved.
			// Distributed under the MIT license. See LICENSE file.
			// https://github.com/ashima/webgl-noise
			//

			float4 mod(float4 x, float4 y)
			{
				return x - y * floor(x / y);
			}

			float4 mod289(float4 x)
			{
				return x - floor(x / 289.0) * 289.0;
			}

			float4 permute(float4 x)
			{
				return mod289(((x*34.0) + 1.0)*x);
			}

			float4 taylorInvSqrt(float4 r)
			{
				return (float4)1.79284291400159 - r * 0.85373472095314;
			}

			float2 fade(float2 t) {
				return t * t*t*(t*(t*6.0 - 15.0) + 10.0);
			}

			// Classic Perlin noise
			float cnoise(float2 P)
			{
				float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
				float4 Pf = frac(P.xyxy) - float4(0.0, 0.0, 1.0, 1.0);
				Pi = mod289(Pi); // To avoid truncation effects in permutation
				float4 ix = Pi.xzxz;
				float4 iy = Pi.yyww;
				float4 fx = Pf.xzxz;
				float4 fy = Pf.yyww;

				float4 i = permute(permute(ix) + iy);

				float4 gx = frac(i / 41.0) * 2.0 - 1.0;
				float4 gy = abs(gx) - 0.5;
				float4 tx = floor(gx + 0.5);
				gx = gx - tx;

				float2 g00 = float2(gx.x, gy.x);
				float2 g10 = float2(gx.y, gy.y);
				float2 g01 = float2(gx.z, gy.z);
				float2 g11 = float2(gx.w, gy.w);

				float4 norm = taylorInvSqrt(float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
				g00 *= norm.x;
				g01 *= norm.y;
				g10 *= norm.z;
				g11 *= norm.w;

				float n00 = dot(g00, float2(fx.x, fy.x));
				float n10 = dot(g10, float2(fx.y, fy.y));
				float n01 = dot(g01, float2(fx.z, fy.z));
				float n11 = dot(g11, float2(fx.w, fy.w));

				float2 fade_xy = fade(Pf.xy);
				float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
				float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
				return 2.3 * n_xy;
			}
			//======================================================================================================================

			// initialize structs used by the gpu
			struct VertexIn
			{
				float4 pos: POSITION;
				float2 uv: TEXCOORD0;
				float3 normal : NORMAL;
			};
			struct VertexOut
			{
				float4 pos: SV_POSITION;
				float2 uv: TEXCOORD0;
				float4 objectPosition: float4;
			};

			// set uniforms
			uniform float _Amplitude;
			uniform float _Speed;
			uniform float _FlameBase;
			uniform float _SampleSpace;
			uniform float _Outline;
			uniform float4 _OutlineColor;
			uniform float _Transparency;
			uniform float _OutlineTrans;

			// VERTEX SHADER
			VertexOut vert(VertexIn v)
			{
				// return val
				VertexOut o;

				float4 tendril = v.pos;

				// only manipulate if above center
				if (tendril.y > _FlameBase)
				{
					float speed = (_Time.y * _Speed);

					// sample noise from x-z at speed
					float sampleX = (v.pos.x + speed) / _SampleSpace;
					float sampleZ = (v.pos.z + speed) / _SampleSpace;

					// get noise an modify by amplitude and center dist
					float n = 1 + cnoise(float2(sampleX, sampleZ));
					float centerDist = distance(v.pos.x, v.pos.z);
					if (centerDist == 0)
						centerDist = 1;

					n = n * _Amplitude / clamp(centerDist, 0.1, 1);

					// increase tendril
					tendril.y += n;

					//*********************************************
					// add some trwist and other motion
					float useTwist = 0.001;

					float rad = sin(speed) / 2;

					float ct = cos(tendril.y / useTwist);
					float st = sin(tendril.y / useTwist);

					tendril.x += (tendril.x * rad - tendril.z * rad);
					tendril.z += (tendril.x * rad + tendril.z * rad);
				}

				// outlining
				float newx = v.normal.x * _Outline;
				float newy = v.normal.y * _Outline;
				float newz = v.normal.z * _Outline;

				float4 outlineMod = float4(newx, newy, newz, 1.0);

				o.pos = UnityObjectToClipPos(tendril + outlineMod);
				o.uv = v.uv;
				o.objectPosition = tendril;

				// return
				return o;
			}

			// FRAGMENT SHADER
			float4 frag(VertexOut i) : SV_TARGET
			{
				float4 col = _OutlineColor;
				col.a = _OutlineTrans;
				return col;
			}

			// finish pass
			ENDCG
		}

		// PASS 2:
		//========
		// Manipulate the Vertices by:
		//		only manipulating y > 0
		//		applying distortion to y across x-z plane
		//			based on noise function 
		//		sample noise over time
		//		center of x-z plane is taller		
		// Color the Flame by:
		//		increase opacity as y decreases
		//		go from color1 to color2 as y increases
		Pass
		{
			// BEGIN
			CGPROGRAM

			// setup commands
			#pragma vertex vert
			#pragma fragment frag

			// include this for more functionality
			// specifically what...?
			#include "UnityCG.cginc"

			//======================================================================================================================
			// Noise Shader Library for Unity - https://github.com/keijiro/NoiseShader
			// https://github.com/ashima/webgl-noise
			//

			float4 mod(float4 x, float4 y)
			{
				return x - y * floor(x / y);
			}

			float4 mod289(float4 x)
			{
				return x - floor(x / 289.0) * 289.0;
			}

			float4 permute(float4 x)
			{
				return mod289(((x*34.0) + 1.0)*x);
			}

			float4 taylorInvSqrt(float4 r)
			{
				return (float4)1.79284291400159 - r * 0.85373472095314;
			}

			float2 fade(float2 t) {
				return t * t*t*(t*(t*6.0 - 15.0) + 10.0);
			}

			// Classic Perlin noise
			float cnoise(float2 P)
			{
				float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
				float4 Pf = frac(P.xyxy) - float4(0.0, 0.0, 1.0, 1.0);
				Pi = mod289(Pi); // To avoid truncation effects in permutation
				float4 ix = Pi.xzxz;
				float4 iy = Pi.yyww;
				float4 fx = Pf.xzxz;
				float4 fy = Pf.yyww;

				float4 i = permute(permute(ix) + iy);

				float4 gx = frac(i / 41.0) * 2.0 - 1.0;
				float4 gy = abs(gx) - 0.5;
				float4 tx = floor(gx + 0.5);
				gx = gx - tx;

				float2 g00 = float2(gx.x, gy.x);
				float2 g10 = float2(gx.y, gy.y);
				float2 g01 = float2(gx.z, gy.z);
				float2 g11 = float2(gx.w, gy.w);

				float4 norm = taylorInvSqrt(float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
				g00 *= norm.x;
				g01 *= norm.y;
				g10 *= norm.z;
				g11 *= norm.w;

				float n00 = dot(g00, float2(fx.x, fy.x));
				float n10 = dot(g10, float2(fx.y, fy.y));
				float n01 = dot(g01, float2(fx.z, fy.z));
				float n11 = dot(g11, float2(fx.w, fy.w));

				float2 fade_xy = fade(Pf.xy);
				float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
				float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
				return 2.3 * n_xy;
			}
			//======================================================================================================================

			// initialize structs used by the gpu
			struct VertexIn
			{
				float4 pos: POSITION;
				float2 uv: TEXCOORD0;
			};
			struct VertexOut
			{
				float4 pos: SV_POSITION;
				float2 uv: TEXCOORD0;
				float4 objectPosition: float4;
			};

			// uniforms
			uniform float _Amplitude;
			uniform float _Speed;
			uniform float _FlameBase;
			uniform float _SampleSpace;
			uniform float _SampleSpace2;
			uniform float4 _Color1;
			uniform float4 _Color2;
			uniform float _ColorMixer;
			uniform float _Transparency;

			// VERTEX SHADER
			VertexOut vert(VertexIn v)
			{
				VertexOut o;

				float4 tendril = v.pos;

				// only manipulate if above center
				if (tendril.y > _FlameBase)
				{
					float speed = (_Time.y * _Speed);

					//*********************************************
					// sample noise from x-z at speed
					float sampleX = (v.pos.x + speed) / _SampleSpace;
					float sampleZ = (v.pos.z + speed) / _SampleSpace;

					// get noise an modify by amplitude and center dist
					float n = 1 + cnoise(float2(sampleX, sampleZ));
					float centerDist = distance(v.pos.x, v.pos.z);
					if (centerDist == 0)
						centerDist = 1;

					n = n * _Amplitude / clamp(centerDist, 0.1, 1);

					// increase tendril
					tendril.y += n;

					//*********************************************
					// add some trwist and other motion
					float useTwist = 0.01;

					float rad = (sin(cnoise(float2(sampleX, sampleX)))) * (cos(cnoise(float2(sampleZ, sampleZ))));

					float ct = cos(tendril.y / useTwist);
					float st = sin(tendril.y / useTwist);

					tendril.x += (tendril.x * rad - tendril.z * rad);
					tendril.z += (tendril.x * rad + tendril.z * rad);
				}

				o.pos = UnityObjectToClipPos(tendril);
				o.objectPosition = tendril;
				o.uv = v.uv;

				v.pos = o.pos;

				return o;
			}

			// FRAGMENT SHADER
			float4 frag(VertexOut i) : SV_Target
			{
				// mix colors
				float height = i.objectPosition.y / _ColorMixer;
				float4 col = lerp(_Color1, _Color2, height);

				// mix transparency
				// sample a bunch of noise
				float speed = (_Time.y * _Speed);
				float sampleX = (i.objectPosition.x - speed) / _SampleSpace2;
				float sampleZ = (i.objectPosition.z - speed) / _SampleSpace2;
				float sampleY = (i.objectPosition.y - speed) / _SampleSpace2;

				float nx = cnoise(float2(sampleY, sampleX));
				float nz = cnoise(float2(sampleY, sampleZ));
				float m = cnoise(float2(sampleY, sampleZ));

				// make it less as y increases
				float tendrilFade = -i.objectPosition.y / 4;

				col.a = _Transparency + (m / 4) + (((nx + nz) / 2) / 4) + tendrilFade;

				return col;
			}

			// END
			ENDCG
		}

	}
}