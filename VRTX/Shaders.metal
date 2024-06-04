#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 viewProjectionMatrix;
    float4x4 modelMatrix;
    float3x3 normalMatrix;
};

struct VertexIn {
    float3 position     [[attribute(0)]];
    float3 normal       [[attribute(1)]];
    float2 texCoords    [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float4 color;
};

vertex VertexOut vertex_main(VertexIn v_in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut v_out;
    float4 worldPosition = uniforms.modelMatrix * float4(v_in.position, 1);
    v_out.position = uniforms.viewProjectionMatrix * worldPosition;
    v_out.worldPosition = worldPosition.xyz;
    v_out.worldNormal = uniforms.normalMatrix * v_in.normal;
    return v_out;
}

fragment float4 fragment_main(VertexOut frag_in [[stage_in]]) {
    float3 normal = normalize(frag_in.worldNormal.xyz);
    return float4(abs(normal), 1);
}

