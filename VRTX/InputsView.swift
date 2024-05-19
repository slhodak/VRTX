import SwiftUI
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
