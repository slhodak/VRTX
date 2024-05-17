import Cocoa
import MetalKit
import Metal

class ViewController: NSViewController {
    var renderer: Renderer?
    var metalView: MTKView!
    var inputsViewController: InputsViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? MTKView,
              let renderer = Renderer(metalView: metalView) else { return }
            
        setupInputsView(renderer: renderer)
        setupMetalView()
    }
    
    func setupInputsView(renderer: Renderer) {
        inputsViewController = InputsViewController(renderer: renderer)
        let inputsView = inputsViewController.view
        inputsView.translatesAutoresizingMaskIntoConstraints = false
        inputsView.wantsLayer = true  // Make the container view layer-backed
        inputsView.layer?.backgroundColor = NSColor.white.cgColor  // Set background color to white
        view.addSubview(inputsView)
        
        NSLayoutConstraint.activate([
            inputsView.topAnchor.constraint(equalTo: view.topAnchor),
            inputsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            inputsView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
        ])
    }
    
    func setupMetalView() {
        metalView = MTKView()
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.device = MTLCreateSystemDefaultDevice()
        view.addSubview(metalView)
        
        NSLayoutConstraint.activate([
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.leadingAnchor.constraint(equalTo: inputsViewController!.view.trailingAnchor)
        ])
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
