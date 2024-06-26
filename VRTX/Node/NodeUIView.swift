import SwiftUI
import simd
import os

struct NodeUIView: View {
    @State var node: Node
    @State var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(node.name)
                Spacer()
                Image(systemName: "chevron.down")
                    .frame(width: 10, height: 10)
                    .rotationEffect(.degrees(isExpanded ? 0 : 90))
                    .onTapGesture {
                        isExpanded.toggle()
                    }
            }
            
            if isExpanded {
                LabeledSlider(name: "ScaleX", value: $node.scale.x, min: 0, max: 10)
                LabeledSlider(name: "ScaleY", value: $node.scale.y, min: 0, max: 10)
                LabeledSlider(name: "ScaleZ", value: $node.scale.z, min: 0, max: 10)
                LabeledSlider(name: "TranslateX", value: $node.translation.x, min: -10, max: 10)
                LabeledSlider(name: "TranslateY", value: $node.translation.y, min: -10, max: 10)
                LabeledSlider(name: "TranslateZ", value: $node.translation.z, min: -10, max: 10)
                VectorView(name: "Rotation Axis", vector: $node.rotationAxis)
                LabeledSlider(name: "RotationAngle", value: $node.rotationAngle, min: 0, max: 2)
                
                Text("Transformed Model Matrix")
                Matrix4x4View(mat: $node.localTransform)
                
                if let node = node as? CustomNode {
                    CustomNodeUIView(geometry: node.geometry)
                }
            }
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
            NotificationCenter.default.post(name: .drawMessage, object: self)
        }
    }
}

struct NodesView: View {
    @State var renderer: Renderer
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Nodes").bold()
            ForEach(renderer.scene.rootNode.children) { node in
                NodeUIView(node: node)
                Divider()
            }
        }.padding()
    }
}
