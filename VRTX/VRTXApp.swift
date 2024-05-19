import SwiftUI
import MetalKit

@main
struct VRTXApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var renderer = Renderer()
    var metalView = MTKView()
    
    var body: some View {
        HStack {
            Text("hi")
            InputsView(renderer: renderer)
            MetalView(metalView: metalView)
        }
        .onAppear() {
            renderer.setup(metalView: metalView)
        }
    }
}
