import SwiftUI
import simd
import os

struct GeometryUIView: View {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "GeometryUIViewController")
    @State var geometry: Geometry
    @State var parseError: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Triangle Vertices")
            Matrix3x3View(mat: $geometry.triangleVertexPositions)
            
            LabeledSlider(name: "Scale", value: $geometry.scaleValue, min: 0.1, max: 10.0)
            LabeledSlider(name: "Translate X", value: $geometry.translation.x, min: -2.0, max: 2.0)
            LabeledSlider(name: "Translate Y", value: $geometry.translation.y, min: -2.0, max: 2.0)
            LabeledSlider(name: "Translate Z", value: $geometry.translation.z, min: -0.5, max: 0.5)
            
            if parseError != nil {
                Text(parseError!).padding().border(.red, width: 2)
            }
        }
        .onChange(of: geometry.triangleVertexPositions) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: geometry.scaleValue) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: geometry.translation) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .padding()
    }
}

struct NodeUIView: View {
    @State var node: Node
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(node.name)
            LabeledSlider(name: "Scale", value: $node.scale)
            LabeledSlider(name: "TranslateX", value: $node.translation.x)
            LabeledSlider(name: "TranslateY", value: $node.translation.y)
            LabeledSlider(name: "TranslateZ", value: $node.translation.z)
            VectorView(vector: $node.rotationAxis)
            LabeledSlider(name: "RotationAngle", value: $node.rotationAngle, min: 0, max: 2)
        }
    }
}
