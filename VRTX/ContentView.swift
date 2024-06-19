import SwiftUI
import MetalKit

struct ContentView: View {
    let renderer: Renderer
    let metalView: MTKView
    let totalHeight: CGFloat = 700
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                NodesView(renderer: renderer)
            }
                .frame(width: 400)
            
            VStack {
                let metalViewHeight = 500 / CGFloat(Renderer.aspectRatio)
                MaterialUIView(material: renderer.scene.rootNode.children.first!.material)
                    .frame(height: (totalHeight - metalViewHeight) / 2)
                MetalView(metalView: metalView)
                    .frame(height: metalViewHeight)
                Spacer()
            }
                .frame(width: 500)
            
            ScrollView {
                ProjectionUIView(renderer: renderer, projection: renderer.projection)
            }
                .frame(width: 400)
            
        }.frame(height: totalHeight)
    }
}
