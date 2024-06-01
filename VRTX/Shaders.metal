#include <metal_stdlib>
using namespace metal;


struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
};

// MARK: Custom Geometry

struct CustomVertexIn {
    float4 position [[attribute(0)]];
    float4 color    [[attribute(1)]];
};

vertex VertexOut vertex_custom(CustomVertexIn v_in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut v_out;
    v_out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * v_in.position;
    v_out.color = v_in.color;
    return v_out;
}

fragment float4 fragment_custom(VertexOut frag_in [[stage_in]]) {
    return frag_in.color;
}

// MARK: OBJ Geometry

struct OBJVertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
    float4 color    [[attribute(2)]];
};

struct OBJVertexOut {
    float4 position [[position]];
    float4 eyeNormal;
    float4 eyePosition;
    float4 color;
};

vertex OBJVertexOut vertex_obj(OBJVertexIn v_in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    OBJVertexOut v_out;
    v_out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(v_in.position, 1);
    v_out.eyeNormal = uniforms.modelViewMatrix * float4(v_in.normal, 0);
    v_out.color = v_in.color;
    return v_out;
}

fragment float4 fragment_obj(OBJVertexOut frag_in [[stage_in]]) {
    float3 normal = normalize(frag_in.eyeNormal.xyz);
    return float4(abs(normal), 1);
}
