import SwiftUI
import MetalKit

struct MetalView: NSViewControllerRepresentable {
    var metalView: MTKView
    
    init(metalView: MTKView) {
        self.metalView = metalView
    }
    
    func makeNSViewController(context: Context) -> MetalViewController {
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.device = MTLCreateSystemDefaultDevice()
        
        return MetalViewController(metalView: metalView)
    }
    
    func updateNSViewController(_ nsView: MetalViewController, context: Context) {
        return
    }
}

class MetalViewController: NSViewController {
    var metalView: MTKView
    
    init(metalView: MTKView) {
        self.metalView = metalView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(metalView)
    }
}
