import SwiftUI
import os

struct InputsView: View {
    @State var renderer: Renderer
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "InputsView")
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                NodesView(renderer: renderer)
                
                ProjectionUIView(renderer: renderer, projection: renderer.projection)
            }
        }
    }
}

