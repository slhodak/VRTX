import SwiftUI
import MetalKit

@main
struct VRTXApp: App {
    var renderer: Renderer
    var metalView: MTKView
    
    init() {
        self.metalView = MTKView()
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Could not create system default Metal device")
        }
        self.renderer = Renderer(device: device, metalView: metalView)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(renderer: renderer, metalView: metalView)
        }
    }
}
