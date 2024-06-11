import MetalKit
import simd
import os

extension Notification.Name {
    static let drawMessage = Notification.Name("drawMessage")
}

struct Uniforms {
    var viewProjectionMatrix: simd_float4x4
    var modelMatrix: simd_float4x4
    var normalMatrix: simd_float3x3
}

@Observable
class Renderer: NSObject, MTKViewDelegate {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Renderer")
    var view: MTKView
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState
    var modelVertexDescriptor: MDLVertexDescriptor
    var vertexDescriptor: MTLVertexDescriptor
    let depthStencilState: MTLDepthStencilState
    var projection: Projection
    static let aspectRatio: Float = 1.78
    let rootNode = Node(name: "root")
    var nodes = [Node]()
    var baseColorTexture: MTLTexture?
    let samplerState: MTLSamplerState
    
    init(device: MTLDevice, metalView: MTKView) {
        self.device = device
        self.view = metalView
        self.commandQueue = device.makeCommandQueue()!
        self.projection = Projection(aspect: Renderer.aspectRatio)
        let modelVertexDescriptor = Renderer.getModelVertexDescriptor()
        self.modelVertexDescriptor = modelVertexDescriptor
        let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(modelVertexDescriptor)!
        self.vertexDescriptor = vertexDescriptor
        self.pipelineState = Renderer.makePipelineState(device: device,
                                                        view: metalView,
                                                        vertexDescriptor: vertexDescriptor)
        self.depthStencilState = Renderer.buildDepthStencilState(device: device)
        self.samplerState = Renderer.buildSamplerState(device: device)
        
        super.init()
        
        loadTexture()
        let modelNode = loadModel(vertexDescriptor: self.modelVertexDescriptor)!
        self.rootNode.children.append(modelNode)
        let customNode = loadCustomGeometry()
        self.rootNode.children.append(customNode)
        projection.updateProjectionMatrix()
        
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
    
    func loadTexture() {
        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option: Any] = [.generateMipmaps: true, .SRGB: true]
        baseColorTexture = try? textureLoader.newTexture(name: "neon_purple_grid", scaleFactor: 1, bundle: nil, options: options)
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
    
    static func buildDepthStencilState(device: MTLDevice) -> MTLDepthStencilState {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        return device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
    }
    
    static func buildSamplerState(device: MTLDevice) -> MTLSamplerState {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.rAddressMode = .repeat
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        return device.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    static func makePipelineState(device: MTLDevice, view: MTKView, vertexDescriptor: MTLVertexDescriptor) -> MTLRenderPipelineState {
        let defaultLibrary = device.makeDefaultLibrary()!
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        let vertexFunction = defaultLibrary.makeFunction(name: "vertex_main")
        let fragmentFunction = defaultLibrary.makeFunction(name: "fragment_main")
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        
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
        
        renderEncoder.setFragmentTexture(baseColorTexture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)
        drawNodeRecursive(self.rootNode,
                          parentTransform: matrix_identity_float4x4,
                          renderEncoder: renderEncoder)
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func drawNodeRecursive(_ node: Node, parentTransform: simd_float4x4, renderEncoder: MTLRenderCommandEncoder) {
        let modelMatrix = parentTransform * node.currentModelMatrix
        var uniforms = Uniforms(viewProjectionMatrix: projection.viewProjectionMatrix,
                                modelMatrix: modelMatrix,
                                normalMatrix: modelMatrix.normalMatrix)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        
        if let node = node as? ModelNode {
            let vertexBuffer = node.mesh.vertexBuffers.first!
            renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            
            for submesh in node.mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                renderEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                    indexCount: submesh.indexCount,
                                                    indexType: submesh.indexType,
                                                    indexBuffer: indexBuffer.buffer,
                                                    indexBufferOffset: indexBuffer.offset)
            }
        } else if let node = node as? CustomNode {
            node.geometry.updateVertexBuffer(for: device)
            renderEncoder.setVertexBuffer(node.geometry.vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        }
        
        for childNode in node.children {
            drawNodeRecursive(childNode, parentTransform: modelMatrix, renderEncoder: renderEncoder)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle window resize
    }
}
