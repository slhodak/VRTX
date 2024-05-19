#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertex_main(VertexIn vertex_in [[stage_in]], constant float4x4 &projectionMatrix [[buffer(1)]]) {
    VertexOut vertex_out;
    vertex_out.position = projectionMatrix * vertex_in.position;
    return vertex_out;
}

//fragment float4 fragment_main(VertexOut frag_in [[stage_in]]) {
//    // Output a static color for all fragments
//    return float4(0.0, 1.0, 0.0, 1.0);  // Green color
//}

fragment float4 fragment_main(VertexOut frag_in [[stage_in]]) {
    // Calculate a color gradient based on the y-coordinate
    float green = (frag_in.position.y + 1.0) / 2.0;  // Normalize y to range [0, 1]
    return float4(0.0, green, 0.0, 1.0);  // Gradient of green based on y position
}
