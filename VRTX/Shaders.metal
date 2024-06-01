#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float4 color    [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut vertex_main(VertexIn v_in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut v_out;
    v_out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * v_in.position;
    v_out.color = v_in.color;
    return v_out;
}

fragment float4 fragment_main(VertexOut frag_in [[stage_in]]) {
    return frag_in.color;
}
