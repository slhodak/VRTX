import SwiftUI
import MetalKit

struct ContentView: View {
    let renderer: Renderer
    let metalView: MTKView
    let aspect: CGFloat = 1.78
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                InputsView(renderer: renderer)
            }
                .frame(width: 400)
            
            VStack {
                Spacer()
                MetalView(metalView: metalView)
                    .frame(height: 500 / aspect)
                Spacer()
            }
                .frame(width: 500)
            
            VStack {
                Spacer()
                Text("Right Column")
                Spacer()
            }
                .frame(width: 400)
            
        }.frame(height: 800)
    }
}
