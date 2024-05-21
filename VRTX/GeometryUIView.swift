import SwiftUI
import os

struct GeometryUIView: View {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "GeometryUIViewController")
    let renderer: Renderer
    @State var geometry: Geometry
    @State var triangleText: String = ""
    @State var parseError: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            /// A 2D array to create a triangle from
            HStack {
                Text("Triangle Vertices")
                TextField("Enter your 3x3 array of vertices", text: $triangleText, onCommit: parseTriangleInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            LabeledSlider(name: "Scale", value: $geometry.scale, min: 0.1, max: 10.0)
                .onChange(of: geometry.scale) {
                    NotificationCenter.default.post(name: .drawMessage, object: nil)
                }
            
            LabeledSlider(name: "Translate X", value: $geometry.translateX, min: -2.0, max: 2.0)
                .onChange(of: geometry.translateX) {
                    NotificationCenter.default.post(name: .drawMessage, object: nil)
                }
            
            LabeledSlider(name: "Translate Y", value: $geometry.translateY, min: -2.0, max: 2.0)
                .onChange(of: geometry.translateY) {
                    NotificationCenter.default.post(name: .drawMessage, object: nil)
                }
            
            LabeledSlider(name: "Translate Z", value: $geometry.translateZ, min: -0.5, max: 0.5)
                .onChange(of: geometry.translateZ) {
                    NotificationCenter.default.post(name: .drawMessage, object: nil)
                }
            
            if parseError != nil {
                Text(parseError!).padding().border(.red, width: 2)
            }
        }
        .padding()
    }
    
    func parseTriangleInput() {
        let jsonData = Data(triangleText.utf8)
        let decoder = JSONDecoder()
        do {
            let float2DArray = try decoder.decode([[Float]].self, from: jsonData)
            geometry.updateVertices(float2DArray)
            NotificationCenter.default.post(name: .drawMessage, object: nil)
            parseError = nil
        } catch {
            parseError = "Failed to parse JSON: \(error)"
        }
    }
}
