// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "CMPM163/CookTorrance"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Shininess("Shininess", Float) = 1.0
        _MainTex ("Main Tex", 2D) = "white" {}
		_SecondTex ("Second Tex", 2D) = "white" {}
		_Roughness("Roughness", Range(0.00, 3.0)) = 0.1 
		_Absorption("Absorption", Range(0.0, 16.0)) = 0.0
		_Gooch("Gooch", Range(0.0, 1.0)) = 0.0
		_Warm("Warm", Color) = (1,0,0,1)
		_Cool("Cool", Color) = (0,0,1,1)
        
    }
    SubShader
    {
        Pass 
        {
			Tags { "LightMode" = "ForwardAdd"}
			/*Stencil {
		        Ref 2
		        Comp NotEqual
		        Pass Replace
		    }*/
			//Blend One One
			
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            float4 _LightColor0;
            float4 _Color;
            float4 _SpecularColor;
            float _Shininess;
            sampler2D _MainTex;
			sampler2D _SecondTex;
			float _Roughness;
			float _Absorption;
			float _Gooch;
			float4 _Warm;
			float4 _Cool;
            
            struct vertexShaderInput 
            {
                float4 position: POSITION;
                float3 normal: NORMAL; 
                float2 uv: TEXCOORD0;
            };
            
            struct vertexShaderOutput
            {
                float4 position: SV_POSITION;
                float3 normal: NORMAL;
                float3 vertInWorldCoords: TEXCOORD1;
                float2 uv: TEXCOORD0;
            };

			// Beckmann distribution function
			// D = (1 / (m^2 * cos^4(alpha))) * e^(-(tan(alpha)/m)^2)
			float beckmann(float NdotH, float alpha) {
				
				float NdotH2 = NdotH * NdotH; // m^2
				float cos4a = pow(cos(alpha), 4); // cos^4(alpha)
				float frac = 1 / (NdotH2 * cos4a); // 1 / (m^2 * cos^4(alpha))

				float e = 2.71828; // constant e
				float exp = pow((tan(alpha)/NdotH), 2) * -1; // -(tan(alpha)/m)^2

				float D = frac * pow(e, exp);
				
				return(D);
			}

			// Schlick approximation of Fresnel function
			// F = r0 + (1 - r0) * (1 - cos(theta))^5
			// r0 = ((n1 - n2) / (n1 + n2))^2
			// n1 = 1 (for air)
			// n2 = ior
			float schlick(float NdotV, float ior) {
				float r0 = pow(((1 - ior) / (1 + ior)), 2);

				float a = 1 - r0;
				float b = pow((1 - NdotV), 5);

				return(r0 + (a*b));
			}

			// Fresnel function approximation for metals
			// from Lazányi and Sxirmay-Kalos's paper here 
			// http://wscg.zcu.cz/WSCG2005/Papers_2005/Short/H29-full.pdf
			// F = ((n-1)^2 + 4n(1 - cos(theta))^5 + k^2)/((n+1)^2 + k^2)
			float conductor(float NdotV, float ior, float k) {
				float k2 = pow(k, 2);
				float num = pow((ior - 1), 2);
				num += (4 * ior * pow(1 - NdotV, 5));
				num += k2;

				float denom = pow(ior + 1, 2);
				denom += k2;

				return(num/denom);
			}

			// microsurface self shadows function
			// G = min(1, ((2 * HdotN * VdotN) / VdotH), ((2 * HdotN * LdotN) / VdotH))
			float microsurface(float HdotN, float VdotN, float LdotN, float VdotH) {
				
				float a = (2 * HdotN * VdotN) / VdotH ;
				float b = (2 * HdotN * LdotN) / VdotH ;
				
				float G = min(1, a);
				G = min(G, b);

				return(G);
			}
            
            vertexShaderOutput vert(vertexShaderInput v)
            {
                vertexShaderOutput o;
                o.vertInWorldCoords = mul(unity_ObjectToWorld, v.position);
                o.position = UnityObjectToClipPos(v.position);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                return o;
            }
            
            float4 frag(vertexShaderOutput i):SV_Target
            {
				float4 col = tex2D(_MainTex, i.uv);
				
                float3 Ka = float3(1, 1, 1);
                float3 globalAmbient = float3(0.1, 0.1, 0.1);
                float3 ambientComponent = Ka * globalAmbient;

                float3 P = i.vertInWorldCoords.xyz;
                float3 N = normalize(i.normal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz - P);
				float3 V = normalize(_WorldSpaceCameraPos - P);
                float3 H = normalize(L + V);
				float3 R = reflect(L, N);

				float NdotL = dot(N, L);
				float HdotN = dot(H, N);
				float VdotH = dot(V, H);
				float VdotN = dot(V, N);
				float NdotR = dot(N, R);

                float3 Kd = _Color.rgb;
                float3 lightColor = _LightColor0.rgb;		
                float3 diffuseComponent;
				if(_Gooch == 1) {
					float it = (1 + NdotL)/2;
					float a = 0.0002;
					float b = 0.0006;

					float3 warm = _Warm.rgb;
					float3 cool = _Cool.rgb;
					diffuseComponent = ((it * warm) + a * col.xyz) + (((1 - it) * cool) + b * col.xyz);
				}
				else {
					diffuseComponent = Kd * lightColor * max(NdotL, 0);
                }
                float3 Ks = _SpecularColor.rgb;

				float D = beckmann(HdotN, _Roughness);

				float3 ior = float3(col.r + 1, col.g + 1, col.b +1);
				float3 F;
				if(_Absorption > 0.0) {
					F = float3(conductor(NdotR, ior.r, _Absorption), conductor(NdotR, ior.g, _Absorption),conductor(NdotR, ior.b, _Absorption));
				}
				else {
					F = float3(schlick(NdotR, ior.r), schlick(NdotR, ior.g), schlick(NdotR, ior.b));
				}

				float G = microsurface(HdotN, VdotN, NdotL, VdotH);

				float denom = 4 * VdotN * NdotL;

				lightColor += F;
                
                float3 specularComponent = Ks * lightColor * ((D*G) / denom); //Ks * lightColor * pow(max(dot(N, H), 0), _Shininess);
                
                
                float3 finalColor = ambientComponent + diffuseComponent + specularComponent;
				if(i.vertInWorldCoords.x < 0) {
					finalColor = finalColor * tex2D(_MainTex, i.uv);
				}
				else {
					finalColor = finalColor * tex2D(_SecondTex, i.uv); 
				}
                return float4(finalColor, 1.0);
            }
            
            ENDCG
        }
    }
    FallBack "Diffuse"
}
