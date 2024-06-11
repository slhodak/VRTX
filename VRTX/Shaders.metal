#include <metal_stdlib>
using namespace metal;

constant float3 ambientIntensity = 0.3;
constant float3 lightPosition(2, 2, 2);
constant float3 lightColor(1, 1, 1);
constant float3 worldCameraPosition(0, 0, 2);
constant float specularPower = 200;

struct Light {
    float3 worldPosition;
    float3 color;
};

struct VertexUniforms {
    float4x4 viewProjectionMatrix;
    float4x4 modelMatrix;
    float3x3 normalMatrix;
};

struct VertexIn {
    float3 position     [[attribute(0)]];
    float3 normal       [[attribute(1)]];
    float2 texCoords    [[attribute(2)]];
};

#define LightCount 3

struct FragmentUniforms {
    float3 cameraWorldPosition;
    float3 ambientLightColor;
    float3 specularColor;
    float specularPower;
    Light lights[LightCount];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float2 texCoords;
};

vertex VertexOut vertex_main(VertexIn v_in [[stage_in]],
                             constant VertexUniforms &uniforms [[buffer(1)]]) {
    VertexOut v_out;
    float4 worldPosition = uniforms.modelMatrix * float4(v_in.position, 1);
    v_out.position = uniforms.viewProjectionMatrix * worldPosition;
    v_out.worldPosition = worldPosition.xyz;
    v_out.worldNormal = uniforms.normalMatrix * v_in.normal;
    v_out.texCoords = v_in.texCoords * float2(3, 3);
    return v_out;
}

fragment float4 fragment_main(VertexOut frag_in [[stage_in]],
                              constant FragmentUniforms &uniforms [[buffer(0)]],
                              texture2d<float, access::sample> baseColorTexture [[texture(0)]],
                              sampler baseColorSampler [[sampler(0)]]) {
    float3 baseColor = baseColorTexture.sample(baseColorSampler, frag_in.texCoords).rgb;
    float3 specularColor = uniforms.specularColor;
    float3 N = normalize(frag_in.worldNormal);
    float3 V = normalize(worldCameraPosition - frag_in.worldPosition);
    
    float3 finalColor(0, 0, 0);
    for (int i = 0; i < LightCount; i++) {
        float3 L = normalize(uniforms.lights[i].worldPosition - frag_in.worldPosition);
        float3 diffuseIntensity = saturate(dot(N, L));
        float3 H = normalize(L + V);
        float specularBase = saturate(dot(N, H));
        float specularIntensity = powr(specularBase, uniforms.specularPower);
        finalColor += uniforms.ambientLightColor * baseColor +
                      diffuseIntensity * lightColor * baseColor +
                      specularIntensity * lightColor * specularColor;
    }
    return float4(finalColor, 1);
}
