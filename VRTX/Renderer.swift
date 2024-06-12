import MetalKit
import simd
import os

extension Notification.Name {
    static let drawMessage = Notification.Name("drawMessage")
}

struct VertexUniforms {
    var viewProjectionMatrix: simd_float4x4
    var modelMatrix: simd_float4x4
    var normalMatrix: simd_float3x3
}

struct FragmentUniforms {
    var cameraWorldPosition = simd_float3(0, 0, 0)
    var ambientLightColor = simd_float3(1, 1, 1)
    var specularColor = simd_float3(1, 1, 1)
    var specularPower: Float = 1
    var light0 = Light()
    var light1 = Light()
    var light2 = Light()
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
    var baseColorTexture: MTLTexture?
    let samplerState: MTLSamplerState
    var projection: Projection
    
    var cameraWorldPosition = simd_float3(0, 0, 2)
    static let aspectRatio: Float = 1.78
    let scene: VScene
    let rootNode = Node(name: "root")
    var nodes = [Node]()
    
    init(device: MTLDevice, metalView: MTKView) {
        self.device = device
        self.view = metalView
        self.commandQueue = device.makeCommandQueue()!
        self.projection = Projection(aspect: Renderer.aspectRatio)
        let modelVertexDescriptor = Renderer.getModelVertexDescriptor()
        self.modelVertexDescriptor = modelVertexDescriptor
        let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(modelVertexDescriptor)!
        self.vertexDescriptor = vertexDescriptor
        self.scene = Renderer.buildScene()
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
    
    static func buildScene() -> VScene {
        let scene = VScene()
        scene.ambientLightColor = simd_float3(0.1, 0.1, 0.1)
        let light0 = Light(worldPosition: simd_float3(5, 5, 0), color: simd_float3(1, 1, 1))
        let light1 = Light(worldPosition: simd_float3(0, 5, 0), color: simd_float3(1, 1, 1))
        let light2 = Light(worldPosition: simd_float3(-5, 5, 0), color: simd_float3(1, 1, 1))
        scene.lights = [light0, light1, light2]
        return scene
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
        var vertexUniforms = VertexUniforms(viewProjectionMatrix: projection.viewProjectionMatrix,
                                            modelMatrix: modelMatrix,
                                            normalMatrix: modelMatrix.normalMatrix)
        renderEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<VertexUniforms>.size, index: 1)
        
        var fragmentUniforms = FragmentUniforms(cameraWorldPosition: projection.viewMatrix.toXYZ(),
                                                ambientLightColor: scene.ambientLightColor,
                                                specularColor: node.material.specularColor,
                                                specularPower: node.material.specularPower,
                                                light0: scene.lights[0],
                                                light1: scene.lights[1],
                                                light2: scene.lights[2])
        renderEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
        renderEncoder.setFragmentTexture(baseColorTexture, index: 0)
        
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
