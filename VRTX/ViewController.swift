import Cocoa
import MetalKit
import Metal

class ViewController: NSViewController {
    var renderer: Renderer?
    var sliders: [NSSlider] = []
    var labels: [NSTextField] = []
    var redrawButton: NSButton!
    var metalView: MTKView!
    var uiContainerView: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let window = view.window {
            let screenSize = window.screen?.frame.size ?? CGSize(width: 800, height: 400)
            let windowWidth = screenSize.width * 0.5 // Use 50% of screen width
            let windowHeight = windowWidth * 0.5 // Maintain 2:1 ratio
            window.setFrame(CGRect(x: 0, y: 0, width: windowWidth, height: windowHeight), display: true)
        }
        
        if let metalView = view as? MTKView {
            renderer = Renderer(metalView: metalView)
            setupUI()
        }
    }
    
    func setupUI() {
        uiContainerView = NSView()
        uiContainerView.translatesAutoresizingMaskIntoConstraints = false
        uiContainerView.wantsLayer = true  // Make the container view layer-backed
        uiContainerView.layer?.backgroundColor = NSColor.white.cgColor  // Set background color to white
        view.addSubview(uiContainerView)
        
        NSLayoutConstraint.activate([
            uiContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            uiContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            uiContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            uiContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
        ])
        
        // Setup Metal View
        metalView = MTKView()
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.device = MTLCreateSystemDefaultDevice()
        view.addSubview(metalView)
        
        NSLayoutConstraint.activate([
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.leadingAnchor.constraint(equalTo: uiContainerView.trailingAnchor)
        ])
        
        let coordinates = ["X", "Y", "Z"]
        var topConstraint = view.topAnchor
        
        // Create 3 sliders for each vertex
        for i in 0..<3 {
            // Create one slider each for x, y, and z
            for j in 0..<3 {
                let label = NSTextField(labelWithString: "Vertex \(i+1) \(coordinates[j])")
                label.translatesAutoresizingMaskIntoConstraints = false
                uiContainerView.addSubview(label)
                
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: topConstraint, constant: 20),
                    label.leadingAnchor.constraint(equalTo: uiContainerView.leadingAnchor, constant: 20),
                    label.widthAnchor.constraint(equalToConstant: 62)
                ])
                
                let slider = NSSlider(value: 0.0, minValue: 0.0, maxValue: 10.0, target: self, action: #selector(sliderValueChanged(_:)))
                slider.tag = i * 3 + j // Use tag to identify the slider
                slider.translatesAutoresizingMaskIntoConstraints = false
                uiContainerView.addSubview(slider)
                sliders.append(slider)
                
                NSLayoutConstraint.activate([
                    slider.topAnchor.constraint(equalTo: label.topAnchor),
                    slider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5),
                    slider.trailingAnchor.constraint(equalTo: uiContainerView.trailingAnchor, constant: -20)
                ])
                
                topConstraint = slider.bottomAnchor
            }
        }

        // Create a button to apply changes and redraw
        redrawButton = NSButton(title: "Redraw", target: self, action: #selector(redrawPressed))
        redrawButton.translatesAutoresizingMaskIntoConstraints = false
        uiContainerView.addSubview(redrawButton)
        
        NSLayoutConstraint.activate([
            redrawButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            redrawButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }
    
    @objc func sliderValueChanged(_ sender: NSSlider) {
        // This function will now only record changes, not apply them immediately
        print("Slider \(sender.tag) value changed to \(sender.doubleValue)")
    }
    
    @objc func redrawPressed() {
            // Apply slider values to vertex positions
            var vertexData: [Vertex] = []
            for i in 0..<3 {
                let x = Float(sliders[i * 3].doubleValue)
                let y = Float(sliders[i * 3 + 1].doubleValue)
                let z = Float(sliders[i * 3 + 2].doubleValue)
                vertexData.append(Vertex(position: [x, y, z, 1.0]))
            }
            
            renderer?.updateVertexBuffer(with: vertexData)
            renderer?.view.setNeedsDisplay(renderer!.view.bounds) // Request redraw
        }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

class Renderer: NSObject, MTKViewDelegate {
    var view: MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var vertexData: [Vertex] = [
        Vertex(position: [0.0, 0.0, 0.0, 1.0]),
        Vertex(position: [0.4, 0.0, 0.0, 1.0]),
        Vertex(position: [0.4, 0.0, 0.0, 1.0])
    ]
    var vertexBuffer: MTLBuffer!
    var projectionMatrix: matrix_float4x4!
    var projectionMatrixBuffer: MTLBuffer?
    
    
    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            return nil
        }
        
        self.view = metalView
        self.device = device
        self.commandQueue = queue
        super.init()
        
        metalView.device = device
        metalView.delegate = self
        
        createGraphicsPipelineState()
        createVertexBuffer()
    }
    
    func updateVertexBuffer(with vertexData: [Vertex]) {
        let bufferPointer = vertexBuffer.contents()
        bufferPointer.copyMemory(from: vertexData, byteCount: vertexData.count * MemoryLayout<Vertex>.stride)
    }
    
    func createGraphicsPipelineState() {
        
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: vertexData.count * MemoryLayout<vector_float3>.size,
                                         options: .storageModeShared)
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        let aspect = Float(view.bounds.width / view.bounds.size.height)
//        projectionMatrix = makePerspectiveMatrix(fovyRadians: Float.pi / 4,
//                                                 aspect: aspect,
//                                                 nearZ: Float(0.1),
//                                                 farZ: Float(100.0))
        
        projectionMatrix = makeOrthographicMatrix(left: 0, right: 100, bottom: 100, top: 0, nearZ: 0.1, farZ: 100.0)
        projectionMatrixBuffer = device.makeBuffer(bytes: &projectionMatrix,length: MemoryLayout<matrix_float4x4>.stride, options: .storageModeShared)
        
        /// Load shaders
        let defaultLibrary = device.makeDefaultLibrary()!
        let vertexFunction = defaultLibrary.makeFunction(name: "vertex_main")
        let fragmentFunction = defaultLibrary.makeFunction(name: "fragment_main")
        
        /// Create render pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }
    
    func createVertexBuffer() {
        /// Buffer created in `createGraphicsPipelineState`
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(projectionMatrixBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle window resize
    }
    
    func makePerspectiveMatrix(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
        let yScale = 1 / tan(fovyRadians * 0.5)
        let xScale = yScale / aspect
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2 * farZ * nearZ / zRange
        
        let p00 = xScale
        let p11 = yScale
        let p22 = zScale
        let p23: Float = -1
        let p32 = wzScale
        
        var mat = matrix_float4x4(columns: (
            vector_float4(p00, 0, 0, 0),
            vector_float4(0, p11, 0, 0),
            vector_float4(0, 0, p22, p23),
            vector_float4(0, 0, p32, 0)
        ))
        
        return mat
    }
    
    func makeOrthographicMatrix(left: Float, right: Float, bottom: Float, top: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
        let ral = right + left
        let rsl = right - left
        let tab = top + bottom
        let tsb = top - bottom
        let fan = farZ + nearZ
        let fsn = farZ - nearZ
        
        let P = matrix_float4x4(
            columns: (
                vector_float4(2.0 / rsl, 0.0, 0.0, 0.0),
                vector_float4(0.0, 2.0 / tsb, 0.0, 0.0),
                vector_float4(0.0, 0.0, -2.0 / fsn, 0.0),
                vector_float4(-ral / rsl, -tab / tsb, -fan / fsn, 1.0)
            )
        )
        return P
    }
    
    

}

struct Vertex {
    var position: vector_float4
}
