import SwiftUI
import MetalKit

struct ContentView: View {
    let renderer: Renderer
    let metalView: MTKView
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                NodesView(renderer: renderer)
            }
                .frame(width: 400)
            
            VStack {
                Spacer()
                MetalView(metalView: metalView)
                    .frame(height: 500 / CGFloat(Renderer.aspectRatio))
                Spacer()
            }
                .frame(width: 500)
            
            ScrollView {
                ProjectionUIView(renderer: renderer, projection: renderer.projection)
            }
                .frame(width: 400)
            
        }.frame(height: 700)
    }
}
