import SwiftUI
import MetalKit
import os

/// I want to add a slider for every property that needs one
/// i want to add that slider by name and associate it with the correct value automatically
/// I want a single method that creates labeled sliders, and takes target properties etc as parameters
///     i can use the label to name the slider in the dictionary, and then read that label to get it back out
///     i could use a switch statement to alter the appropriate value based on the name of the slider...
///         the switch could be exhaustive and safe if I make it choose from an enum

struct InputsView: View {
    var renderer: Renderer
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "InputsView")
    
    var body: some View {
        ScrollView {
            VStack {
                GeometryUIView(renderer: renderer)
                ProjectionUIView(renderer: renderer)
                Button("Redraw") {
                    renderer.draw()
                }
            }
        }
    }
}

struct ProjectionUIView: View {
    let renderer: Renderer
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "ProjectionUIViewController")
    
    @State var orthographicLeft: Float = 0
    @State var orthographicRight: Float = 0
    @State var orthographicTop: Float = 0
    @State var orthographicBottom: Float = 0
    @State var nearZ: Float = 0
    @State var farZ: Float = 100.0
    @State var useProjection: Bool = false
    @State var usePerspectiveProjection: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Toggle(isOn: $useProjection) {
                    Text("Projection")
                }
                .onChange(of: useProjection) {
                    renderer.projection.useProjection = useProjection
                    renderer.draw()
                }
                Toggle(isOn: $usePerspectiveProjection) {
                    Text("Ortho/Persp")
                }
                .onChange(of: usePerspectiveProjection) {
                    renderer.projection.useProjection = usePerspectiveProjection
                    renderer.draw()
                }
            }
            Slider(value: $orthographicTop) {
                Text("Orthographic Top")
            }
            .onChange(of: orthographicTop) {
                sliderValueChanged(name: "orthographicTop", value: orthographicTop)
            }
            //... more sliders
        }
    }
    
    func sliderValueChanged(name: String, value: Float) {
        guard let property = ProjectionProperty.fromString(name) else {
            logger.error("Failed to cast \(name) to ProjectionProperty")
            return
        }
        
        renderer.projection.updateProjection(property: property, value: value)
        renderer.draw()
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
