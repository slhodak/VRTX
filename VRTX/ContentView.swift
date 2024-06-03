import SwiftUI
import MetalKit

struct ContentView: View {
    let renderer: Renderer
    let metalView: MTKView
    
    var body: some View {
        HStack {
            InputsView(renderer: renderer)
            MetalView(metalView: metalView)
        }
    }
}
