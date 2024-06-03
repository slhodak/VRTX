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
                
                ForEach(renderer.rootNode.children) { node in
                    NodeUIView(node: node)
                    if let node = node as? CustomNode {
                        CustomNodeUIView(geometry: node.geometry)
                    }
                }
                
                ProjectionUIView(renderer: renderer, projection: renderer.projection)
            }
        }
    }
}
