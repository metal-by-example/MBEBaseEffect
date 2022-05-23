
#include <metal_stdlib>
using namespace metal;

enum {
    VertexAttributePosition,
    VertexAttributeNormal,
    VertexAttributeColor,
    VertexAttributeTexCoord0,
    //VertexAttributeTexCoord1,
};

enum {
    VertexBufferIndexInstanceConstants = 16,
};

enum {
    FragmentBufferIndexInstanceConstants = 16
};

constexpr constant int MBELightCount = 3;
constexpr constant int MBETextureStageCount = 2;

enum class TextureMode: uint32_t {
    Disabled,
    Replace,
    Modulate,
    Decal,
};

enum class FogMode: uint32_t {
    Disabled,
    Exp,
    Exp2,
    Linear,
};

enum class LightingMode: uint32_t {
    PerVertex,
    PerFragment
};

struct Light { // 96 bytes
    float4 position;
    float4 ambientColor;
    float4 diffuseColor;
    float4 specularColor;
    packed_float3 spotDirection;
    float spotExponent;
    float spotCosCutoff; // cosine of cutoff angle
    float constantAttenuation;
    float linearAttenuation;
    float quadraticAttenuation;
};

struct Material { // 80 bytes
    float4 ambientColor;
    float4 diffuseColor;
    float4 specularColor;
    float4 emissiveColor;
    float shininess;
    packed_float3 _pad;
};

struct FogParams { // 32 bytes
    float4 color;
    FogMode mode;
    float density;
    float start;
    float end;
};

struct InstanceConstants { // 640 bytes
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
    float3x3 normalMatrix;
    Material material;
    FogParams fog;
    Light lights[MBELightCount];
    float4 ambientLightColor;
    float4 constantVertexColor;
    LightingMode lightingMode;
    TextureMode textureModes[MBETextureStageCount];
    uint32_t colorMaterialEnabled;
    uint32_t lightModelTwoSided;
    uint32_t useConstantColor;
    uint32_t activeLightCount;
    float _pad;
};


struct VertexIn {
    float3 position  [[attribute(VertexAttributePosition)]];
    float3 normal    [[attribute(VertexAttributeNormal)]];
    float4 color     [[attribute(VertexAttributeColor)]];
    float2 texCoord0 [[attribute(VertexAttributeTexCoord0)]];
    //float2 texCoord1 [[attribute(VertexAttributeTexCoord1)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 eyePosition;
    float3 normal;
    float4 color;
    float2 texCoord0;
    //float2 texCoord1;
};

struct FragmentIn {
    float4 position [[position]];
    float3 eyePosition;
    float3 normal;
    float4 color;
    float2 texCoord0;
    //float2 texCoord1;
    bool frontFacing [[front_facing]];
};

static float calculateFogFactor(constant FogParams &fog, float3 eyePosition) {
    const float dist = abs(eyePosition.z);
    const float fogScale =  1.0 / (fog.end - fog.start);
    float fogFactor = 1.0;
    switch (fog.mode) {
        case FogMode::Disabled:
            break;
        case FogMode::Exp:
            fogFactor = exp(-fog.density * dist);
            break;
        case FogMode::Exp2:
            fogFactor = exp(-fog.density * fog.density * dist * dist);
            break;
        case FogMode::Linear:
            fogFactor = (fog.end - dist) * fogScale;
            break;
    }
    fogFactor = saturate(fogFactor);
    return 1 - fogFactor;
}

void evaluateDirectionalLight(constant Light &light, float shininess, float3 N, float3 H,
                              thread float3 &ambient, thread float3 &diffuse, thread float3 &specular)
{
    float3 L = normalize(light.position.xyz);
    float NdotL = max(0.0, dot(N, L));
    float NdotH = max(0.0, dot(N, H));
    float specularFactor = (NdotL > 0) ? powr(NdotH, shininess) : 0;

    ambient  += light.ambientColor.rgb;
    diffuse  += light.diffuseColor.rgb * NdotL;
    specular += light.specularColor.rgb * specularFactor;
}

void evaluatePointLight(constant Light &light, float3 eye, float3 eyePosition, float shininess, float3 N,
                        thread float3 &ambient, thread float3 &diffuse, thread float3 &specular)
{
    float3 L = light.position.xyz - eyePosition;
    float d = length(L);
    L = normalize(L);
    float3 V = normalize(eye - eyePosition);

    float attenDenom = (light.constantAttenuation + light.linearAttenuation * d + light.quadraticAttenuation * d * d);
    float attenuation = 1.0 / max(1e-5, attenDenom);
    float3 H = normalize(L + V);
    float NdotL = max(0.0, dot(N, L));
    float NdotH = max(0.0, dot(N, H));
    float specularFactor = (NdotL > 0) ? powr(NdotH, shininess) : 0;

    ambient  += light.ambientColor.rgb * attenuation;
    diffuse  += light.diffuseColor.rgb * NdotL * attenuation;
    specular += light.specularColor.rgb * specularFactor * attenuation;
}

void evaluateSpotLight(constant Light &light, float3 eye, float3 eyePosition, float shininess, float3 N,
                       thread float3 &ambient, thread float3 &diffuse, thread float3 &specular)
{
    float3 L = light.position.xyz - eyePosition;
    float d = length(L);
    L = normalize(L);
    float3 V = normalize(eye - eyePosition);

    float attenDenom = (light.constantAttenuation + light.linearAttenuation * d + light.quadraticAttenuation * d * d);
    float attenuation = 1.0 / max(1e-5, attenDenom);

    float spotDot = max(0.0f, dot(-L, normalize(light.spotDirection)));
    float spotAttenuation;
    if (spotDot < light.spotCosCutoff) {
        spotAttenuation = 0.0;
    } else {
        spotAttenuation = powr(spotDot, light.spotExponent);
    }

    attenuation *= spotAttenuation;

    float3 H = normalize(L + V);
    float NdotL = max(0.0, dot(N, L));
    float NdotH = max(0.0, dot(N, H));
    float specularFactor = (NdotL > 0) ? powr(NdotH, shininess) : 0;

    ambient  += light.ambientColor.rgb * attenuation;
    diffuse  += light.diffuseColor.rgb * NdotL * attenuation;
    specular += light.specularColor.rgb * specularFactor * attenuation;
}

static float4 evaluateLighting(float3 N, float4 color, float3 eyePosition, constant InstanceConstants &instance) {
    constexpr float3 eyeOrigin { 0 };
    float3 V = normalize(eyeOrigin - eyePosition);

    float3 surfaceAmbient = instance.material.ambientColor.rgb * color.rgb;
    float3 surfaceDiffuse = instance.material.diffuseColor.rgb * color.rgb;
    float3 surfaceSpecular = instance.material.specularColor.rgb * color.rgb;
    float3 surfaceEmissive = instance.material.emissiveColor.rgb;
    float shininess = instance.material.shininess;
    float opacity = instance.material.diffuseColor.a * color.a;

    float3 ambientIntensity  { 0 };
    float3 diffuseIntensity { 0 };
    float3 specularIntensity { 0 };
    for (unsigned i = 0; i < instance.activeLightCount; ++i) {
        constant Light &light = instance.lights[i];
        if (light.position.w == 0.0) {
            float3 L = normalize(-light.position.xyz);
            float3 H = normalize(L + V);
            evaluateDirectionalLight(light, shininess, N, H,
                                     ambientIntensity, diffuseIntensity, specularIntensity);
        } else if (light.spotCosCutoff == -1.0f) {
            evaluatePointLight(light, eyeOrigin, eyePosition, shininess, N,
                               ambientIntensity, diffuseIntensity, specularIntensity);
        } else {
            evaluateSpotLight(light, eyeOrigin, eyePosition, shininess, N,
                              ambientIntensity, diffuseIntensity, specularIntensity);
        }
    }

    float3 sceneColor = surfaceEmissive + surfaceAmbient * instance.ambientLightColor.rgb;

    color = float4(sceneColor +
                   ambientIntensity * surfaceAmbient +
                   diffuseIntensity * surfaceDiffuse +
                   specularIntensity * surfaceSpecular,
                   opacity);
    return color;
}

vertex VertexOut vertex_base_effect(VertexIn in [[stage_in]],
                                    constant InstanceConstants &instance [[buffer(VertexBufferIndexInstanceConstants)]])
{
    float4 eyePosition = instance.modelViewMatrix * float4(in.position, 1);
    VertexOut out;
    out.position = instance.projectionMatrix * eyePosition;
    out.eyePosition = eyePosition.xyz;
    out.normal = normalize(instance.normalMatrix * in.normal);
    out.color = instance.useConstantColor ? instance.constantVertexColor : in.color;
    out.texCoord0 = in.texCoord0;
    //out.texCoord1 = in.texCoord1;

    // TODO: Implement two-sided lighting for vertex lighting

    if (instance.lightingMode == LightingMode::PerVertex) {
        out.color = evaluateLighting(out.normal, out.color, out.eyePosition, instance);
    }

    return out;
}

fragment float4 fragment_base_effect(FragmentIn in [[stage_in]],
                                     constant InstanceConstants &instance [[buffer(FragmentBufferIndexInstanceConstants)]],
                                     texture2d<float, access::sample> texture0 [[texture(0)]],
                                     texture2d<float, access::sample> texture1 [[texture(1)]])
{
    constexpr sampler bilinearSampler(coord::normalized, filter::linear, mip_filter::linear, address::repeat);

    float3 N = normalize(in.normal);
    if (!in.frontFacing && instance.lightModelTwoSided) {
        N = -N;
    }

    float4 color = in.color;
    float3 eyePosition = in.eyePosition;
    if (instance.lightingMode == LightingMode::PerFragment) {
        color = evaluateLighting(N, in.color, eyePosition, instance);
    }

    float4 texColors[MBETextureStageCount] { 0 };
    if (!is_null_texture(texture0)) {
        texColors[0] = texture0.sample(bilinearSampler, in.texCoord0);
    }
    if (!is_null_texture(texture1)) {
        texColors[1] = texture1.sample(bilinearSampler, in.texCoord0);
    }
    for (int i = 0; i < MBETextureStageCount; ++i) {
        switch (instance.textureModes[i]) {
            case TextureMode::Disabled:
                break;
            case TextureMode::Replace:
                color = texColors[i];
                break;
            case TextureMode::Modulate:
                color *= texColors[i];
                break;
            case TextureMode::Decal: {
                float4 texColor = texColors[i];
                float3 decalColor = mix(color.rgb, texColor.rgb, texColor.a);
                color = float4(decalColor, color.a);
                break;
            }
        }
    }

    float fogFactor = calculateFogFactor(instance.fog, eyePosition);
    color = mix(color, instance.fog.color, fogFactor);

    return color;
}
