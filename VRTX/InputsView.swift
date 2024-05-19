import SwiftUI
import MetalKit
import os

struct InputsView: View {
    var renderer: Renderer
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "InputsView")
    
    var body: some View {
        ScrollView {
            VStack {
                GeometryUIView(renderer: renderer, geometry: renderer.geometry)
                ProjectionUIView(renderer: renderer, projection: renderer.projection)
                Button("Redraw") {
                    renderer.draw()
                }
            }
        }
    }
}

struct ProjectionUIView: View {
    let renderer: Renderer
    @State var projection: Projection
    // make projection a property here, wrangle the need to expose it in various places
    // or use a publisher for update events
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "ProjectionUIViewController")
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack() {
                Toggle(isOn: $projection.useProjection) {
                    Text("Projection")
                }
                .onChange(of: projection.useProjection) {
                    renderer.draw()
                }
                Toggle(isOn: $projection.usePerspectiveProjection) {
                    Text("Ortho/Persp")
                }
                .onChange(of: projection.usePerspectiveProjection) {
                    renderer.draw()
                }
            }
            Slider(value: $projection.orthographicTop) {
                Text("Orthographic Top")
            }
            //... more sliders
        }
        .padding()
    }
}

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
