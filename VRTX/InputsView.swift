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

struct NodesView: View {
    @State var renderer: Renderer
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Nodes").bold()
            ForEach(renderer.rootNode.children) { node in
                NodeUIView(node: node)
                if let node = node as? CustomNode {
                    CustomNodeUIView(geometry: node.geometry)
                }
                Divider()
            }
        }.padding()
    }
}
