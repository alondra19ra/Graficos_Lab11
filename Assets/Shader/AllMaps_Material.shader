Shader "Custom/AllMaps_Material"
{
    Properties
    {
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
        _SpecMap("Specular Map (R)", 2D) = "white" {}
        _HeightMap("Height Map (Parallax)", 2D) = "black" {}
        _AOMap("Ambient Occlusion", 2D) = "white" {}
        _EmissionMap("Emission Map", 2D) = "black" {}

        _Color("Tint", Color) = (1,1,1,1)
        _Gloss("Glossiness / Shininess", Range(1,128)) = 32
        _SpecIntensity("Specular Intensity", Range(0,5)) = 1.0
        _ParallaxScale("Parallax Scale", Range(0,0.1)) = 0.02
        _EmissionColor("Emission Color", Color) = (1,0.85,0.6,1)
    }

        SubShader
        {
            Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
            LOD 300

            Pass
            {
                Tags { "LightMode" = "UniversalForward" }

                HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float3 worldNormal : TEXCOORD2;
                    float3 viewDir : TEXCOORD3;
                };

                // --- Texturas y Samplers ---
                TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
                TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
                TEXTURE2D(_SpecMap); SAMPLER(sampler_SpecMap);
                TEXTURE2D(_HeightMap); SAMPLER(sampler_HeightMap);
                TEXTURE2D(_AOMap); SAMPLER(sampler_AOMap);
                TEXTURE2D(_EmissionMap); SAMPLER(sampler_EmissionMap);

                float4 _MainTex_ST;
                float4 _Color;
                float _Gloss;
                float _SpecIntensity;
                float _ParallaxScale;
                float4 _EmissionColor;

                // --- Función Vertex ---
                v2f vert(appdata v)
                {
                    v2f o;
                    float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    o.worldPos = worldPos;
                    o.worldNormal = normalize(TransformObjectToWorldNormal(v.normal));
                    o.viewDir = normalize(GetWorldSpaceViewDir(worldPos));
                    return o;
                }

                // --- Parallax básico ---
                float2 ParallaxOffset(float2 uv, float3 viewDir)
                {
                    float height = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv).r;
                    float2 offset = (height - 0.5) * _ParallaxScale * normalize(viewDir.xy);
                    return uv + offset;
                }

                // --- Función Fragment ---
                half4 frag(v2f i) : SV_Target
                {
                    // Ajuste Parallax
                    float2 uvP = ParallaxOffset(i.uv, normalize(i.viewDir));

                    // --- Muestras de Texturas ---
                    float3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvP).rgb * _Color.rgb;
                    float4 nmap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvP);
                    float specMap = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, uvP).r;
                    float ao = SAMPLE_TEXTURE2D(_AOMap, sampler_AOMap, uvP).r;
                    float3 emissionMap = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, uvP).rgb;

                    // --- Normal Map ---
                    float3 N = normalize(UnpackNormal(nmap)); // ahora correcto (float4)

                    // --- Luz principal ---
                    Light mainLight = GetMainLight();
                    float3 L = normalize(-mainLight.direction);
                    float3 V = normalize(i.viewDir);
                    float3 H = normalize(L + V);

                    // --- Difusa (Lambert) ---
                    float NdotL = saturate(dot(N, L));
                    float3 diffuse = albedo * mainLight.color.rgb * NdotL;

                    // --- Especular (Blinn-Phong) ---
                    float NdotH = saturate(dot(N, H));
                    float spec = pow(NdotH, _Gloss) * _SpecIntensity * specMap;
                    float3 specular = spec * mainLight.color.rgb;

                    // --- Ambiental con AO ---
                    float3 ambient = albedo * 0.2 * ao;

                    // --- Emisión ---
                    float3 emission = emissionMap * _EmissionColor.rgb;

                    // --- Color final ---
                    float3 colorOut = ambient + diffuse + specular + emission;

                    return float4(colorOut, 1.0);
                }

                ENDHLSL
            }
        }

            FallBack "Universal Forward"
}
