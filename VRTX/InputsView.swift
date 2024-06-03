import SwiftUI
import os

struct InputsView: View {
    @State var renderer: Renderer
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "InputsView")
    
    var body: some View {
        ScrollView {
            VStack {
                Button(action: renderer.draw) {
                    Text("Draw")
                }
                
                Toggle(isOn: $renderer.useModel) {
                    Text("Use Model")
                }
                
                ForEach(renderer.nodes) { node in
                    Text(node.name)
                    if let node = node as? CustomNode {
                        GeometryUIView(geometry: node.geometry)
                    }
                }
                
                ProjectionUIView(renderer: renderer, projection: renderer.projection)
            }
        }
        .onChange(of: renderer.useModel) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
    }
}
