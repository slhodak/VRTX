import SwiftUI
import os

struct GeometryUIView: View {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "GeometryUIViewController")
    let renderer: Renderer
    @State var geometry: Geometry
    @State var triangleText: String = ""
    @State var parseError: String?
    
    var body: some View {
        VStack {
            /// A 2D array to create a triangle from
            HStack {
                Text("Triangle Vertices")
                TextField("Enter your 3x3 array of vertices", text: $triangleText, onCommit: parseTriangleInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            
            if parseError != nil {
                Text(parseError!)
            }
        }
    }

    func parseTriangleInput() {
        let jsonData = Data(triangleText.utf8)
        let decoder = JSONDecoder()
        do {
            let float2DArray = try decoder.decode([[Float]].self, from: jsonData)
            geometry.updateVertices(float2DArray)
            parseError = nil
        } catch {
            parseError = "Failed to parse JSON: \(error)"
        }
    }
}
