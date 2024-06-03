#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
};

struct VertexIn {
    float3 position     [[attribute(0)]];
    float3 normal       [[attribute(1)]];
    float2 texCoords    [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 eyeNormal;
    float4 eyePosition;
    float4 color;
};

vertex VertexOut vertex_main(VertexIn v_in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut v_out;
    v_out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(v_in.position, 1);
    v_out.eyeNormal = uniforms.modelViewMatrix * float4(v_in.normal, 0);
    return v_out;
}

fragment float4 fragment_main(VertexOut frag_in [[stage_in]]) {
    float3 normal = normalize(frag_in.eyeNormal.xyz);
    return float4(abs(normal), 1);
}
