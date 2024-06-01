import SwiftUI
import os

struct GeometryUIView: View {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "GeometryUIViewController")
    let renderer: Renderer
    @State var geometry: Geometry
    @State var parseError: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $geometry.useModel) {
                Text("Use Model")
            }
            Text("Triangle Vertices")
            Matrix3x4View(mat: $geometry.triangleVertexPositions)
            
            LabeledSlider(name: "Scale", value: $geometry.scale, min: 0.1, max: 10.0)
            LabeledSlider(name: "Translate X", value: $geometry.translation.x, min: -2.0, max: 2.0)
            LabeledSlider(name: "Translate Y", value: $geometry.translation.y, min: -2.0, max: 2.0)
            LabeledSlider(name: "Translate Z", value: $geometry.translation.z, min: -0.5, max: 0.5)
            
            if parseError != nil {
                Text(parseError!).padding().border(.red, width: 2)
            }
        }
        .onChange(of: geometry.useModel) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: geometry.triangleVertexPositions) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: geometry.scale) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: geometry.translation) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .padding()
    }
}
