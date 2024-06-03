import MetalKit
import simd
import os

extension Notification.Name {
    static let drawMessage = Notification.Name("drawMessage")
}

struct Uniforms {
    var modelViewMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
}

@Observable
class Renderer: NSObject, MTKViewDelegate {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Renderer")
    var view: MTKView
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState!
    var modelVertexDescriptor: MDLVertexDescriptor!
    var vertexDescriptor: MTLVertexDescriptor!
    var projection: Projection
    var useModel = false
    var nodes = [Node]()
    
    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            return nil
        }
        
        self.view = metalView
        self.device = device
        self.commandQueue = queue
        self.projection = Projection(size: metalView.bounds.size)
        let modelVertexDescriptor = Renderer.getModelVertexDescriptor()
        self.modelVertexDescriptor = modelVertexDescriptor
        let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(modelVertexDescriptor)!
        self.vertexDescriptor = vertexDescriptor
        self.pipelineState = Renderer.makePipelineState(device: device, vertexDescriptor: vertexDescriptor)
        
        super.init()
        
        metalView.device = device
        metalView.delegate = self
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDrawMessage(_:)),
                                               name: .drawMessage,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleDrawMessage(_ notification: Notification) {
        draw()
    }
    
    func updateProjectionMatrixBuffer() {
        projection.setupProjectionMatrixBuffer(for: device)
    }
    
    func loadModel(vertexDescriptor: MDLVertexDescriptor) -> ModelNode? {
        let modelURL = Bundle.main.url(forResource: "suzanne", withExtension: "obj")!
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        do {
            let mesh = try MTKMesh.newMeshes(asset: asset, device: device).metalKitMeshes.first!
            return ModelNode(name: "suzanne", mesh: mesh)
        } catch {
            logger.error("Could not extract meshes from Model I/O asset")
            return nil
        }
    }
    
    func loadCustomGeometry() -> CustomNode {
        let geometry = Geometry()
        geometry.initVertices()
        geometry.setupVertexBuffer(for: device)
        
        return CustomNode(name: "custom", geometry: geometry)
    }
    
    static func getModelVertexDescriptor() -> MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: .float3,
                                                            offset: 0,
                                                            bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                            format: .float3,
                                                            offset: MemoryLayout<Float>.size * 3,
                                                            bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                            format: .float2,
                                                            offset: MemoryLayout<Float>.size * 6,
                                                            bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        
        return vertexDescriptor
    }
    
    static func makePipelineState(device: MTLDevice, vertexDescriptor: MTLVertexDescriptor) -> MTLRenderPipelineState {
        let defaultLibrary = device.makeDefaultLibrary()!
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        let vertexFunction = defaultLibrary.makeFunction(name: "vertex_main")
        let fragmentFunction = defaultLibrary.makeFunction(name: "fragment_main")
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
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
        
        self.nodes = []
        let modelNode = loadModel(vertexDescriptor: self.modelVertexDescriptor)!
        self.nodes.append(modelNode)
        let customNode = loadCustomGeometry()
        self.nodes.append(customNode)
        
        let viewMatrix = simd_float4x4(translationBy: SIMD3<Float>(0, 0, -2))
        let modelViewMatrix = viewMatrix * customNode.modelMatrix
        var uniforms = Uniforms(modelViewMatrix: modelViewMatrix,
                                projectionMatrix: projection.projectionMatrix)
        
        projection.setupProjectionMatrixBuffer(for: device)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        if useModel {
            let vertexBuffer = modelNode.mesh.vertexBuffers.first!
            renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            
            for submesh in modelNode.mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                renderEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                    indexCount: submesh.indexCount,
                                                    indexType: submesh.indexType,
                                                    indexBuffer: indexBuffer.buffer,
                                                    indexBufferOffset: indexBuffer.offset)
            }
        } else {
            customNode.geometry.updateVertexBuffer(for: device)
            renderEncoder.setVertexBuffer(customNode.geometry.vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle window resize
    }
}
