import SwiftUI
import MetalKit

@main
struct VRTXApp: App {
    var renderer: Renderer
    var metalView: MTKView
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Could not create system default Metal device")
        }
        
        metalView = MTKView()
        metalView.device = device
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = true
        renderer = Renderer(device: device, metalView: metalView)
        metalView.delegate = renderer
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(renderer: renderer, metalView: metalView)
        }
    }
}
