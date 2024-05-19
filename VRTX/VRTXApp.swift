import SwiftUI
import MetalKit

@main
struct VRTXApp: App {
    var renderer: Renderer
    var metalView: MTKView
    
    init() {
        metalView = MTKView()
        guard let renderer = Renderer(metalView: metalView) else {
            fatalError("Could not initialize renderer")
        }
        self.renderer = renderer
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(renderer: renderer, metalView: metalView)
        }
    }
}

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