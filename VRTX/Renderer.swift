import MetalKit
import os

class Renderer: NSObject, MTKViewDelegate {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Renderer")
    var view: MTKView
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState!
    var geometry: Geometry
    var projection: Projection
    
    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            return nil
        }
        
        self.view = metalView
        self.device = device
        self.commandQueue = queue
        self.geometry = Geometry()
        self.projection = Projection()
        super.init()
        
        projection.setProjectionMatrixAspect(for: view)
        metalView.device = device
        metalView.delegate = self
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = true
        
        createGraphicsPipelineState()
    }
    
    func updateProjectionMatrixBuffer() {
        projection.setupProjectionMatrixBuffer(for: device)
    }
    
    func createGraphicsPipelineState() {
        geometry.setupVertexBuffer(for: device)
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
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
    
    func draw() {
        view.setNeedsDisplay(view.bounds)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
//        var vertexData = self.vertexData
//        if useProjection && usePerspectiveProjection {
//            logger.debug("Using scaled vertex data")
//            vertexData = scale(vertices: vertexData, by: 1)
//        }
        geometry.updateVertexBuffer(for: device)
        renderEncoder.setVertexBuffer(geometry.vertexBuffer, offset: 0, index: 0)
        
        projection.setupProjectionMatrixBuffer(for: device)
        renderEncoder.setVertexBuffer(projection.projectionMatrixBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle window resize
    }
}
