import SwiftUI
import MetalKit
import os

struct InputsView: View {
    var renderer: Renderer
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "InputsView")
    
    var body: some View {
        ScrollView {
            VStack {
                GeometryUIView(renderer: renderer)
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
        VStack {
            HStack {
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
    }
}

struct GeometryUIView: View {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "GeometryUIViewController")
    let renderer: Renderer
    @State var vertexValue: Float = 0.5
    
    var body: some View {
        VStack {
            Slider(value: $vertexValue) {
                Text("Vertex Value")
            }
            .onChange(of: vertexValue) {
                self.logger.debug("changed vertex value to \(vertexValue)")
//                renderer.geometry.updateVertex(index: index, axis: String(nameParts[1]), value: vertexValue)
//                renderer.draw()
            }
        }
    }
}
