import SwiftUI
import simd
import os

struct NodeUIView: View {
    @State var node: Node
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(node.name)
            LabeledSlider(name: "Scale", value: $node.scale, min: 0, max: 10)
            LabeledSlider(name: "TranslateX", value: $node.translation.x, min: -10, max: 10)
            LabeledSlider(name: "TranslateY", value: $node.translation.y, min: -10, max: 10)
            LabeledSlider(name: "TranslateZ", value: $node.translation.z, min: -10, max: 10)
            VectorView(vector: $node.rotationAxis)
            LabeledSlider(name: "RotationAngle", value: $node.rotationAngle, min: 0, max: 2)
        }
    }
}

struct CustomNodeUIView: View {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "GeometryUIViewController")
    @State var geometry: Geometry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Triangle Vertices")
            Matrix3x3View(mat: $geometry.triangleVertexPositions)
        }
        .onChange(of: geometry.triangleVertexPositions) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .padding()
    }
}

struct NodesView: View {
    @State var renderer: Renderer
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Nodes").bold()
            ForEach(renderer.rootNode.children) { node in
                NodeUIView(node: node)
                if let node = node as? CustomNode {
                    CustomNodeUIView(geometry: node.geometry)
                }
                Divider()
            }
        }.padding()
    }
}
