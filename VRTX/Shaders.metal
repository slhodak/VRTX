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

vertex VertexOut vertex_main(VertexIn vertex_in [[stage_in]], constant float4x4 &projectionMatrix [[buffer(1)]]) {
    VertexOut vertex_out;
    vertex_out.position = projectionMatrix * vertex_in.position;
    vertex_out.color = vertex_in.color;
    return vertex_out;
}

fragment float4 fragment_main(VertexOut frag_in [[stage_in]]) {
    return frag_in.color;
//    float red = (frag_in.position.x + 1.0) / 2.0;
//    float green = (frag_in.position.y + 1.0) / 2/0;
//    float blue = (frag_in.position.z + 1.0) / 2.0;
//    return float4(red, green, blue, 1.0);
}
