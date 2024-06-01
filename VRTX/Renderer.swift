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

class Renderer: NSObject, MTKViewDelegate {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Renderer")
    var view: MTKView
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState!
    var geometry: Geometry
    var modelVertexDescriptor: MTLVertexDescriptor?
    var customGeometryVertexDescriptor: MTLVertexDescriptor?
    var meshes: [MTKMesh] = []
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
        self.projection = Projection(size: view.bounds.size)
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
    
    func loadModel() {
        let modelURL = Bundle.main.url(forResource: "suzanne", withExtension: "obj")!
        let vertexDescriptor = MDLVertexDescriptor()
        // but maybe .obj does not have vertices and normals as float4, but as float3 as in the example
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        // Green Color
        //vertexDescriptor.attributes[2] = simd_float4(0, 1, 0, 1)
        /// Maybe we won't have texture coords
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float3, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        
        self.modelVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        var meshes: [MTKMesh] = []
        do {
            (_, meshes) = try MTKMesh.newMeshes(asset: asset, device: device)
            self.meshes = meshes
        } catch {
            fatalError("Could not extract meshes from Model I/O asset")
        }
    }
    
    func loadCustomGeometry() {
        geometry.initVertices()
        geometry.setupVertexBuffer(for: device)
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<vector_float4>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        self.customGeometryVertexDescriptor = vertexDescriptor
    }
    
    func createGraphicsPipelineState() {
        /// Load shaders
        let defaultLibrary = device.makeDefaultLibrary()!
        
        /// Create render pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        var vertexFunction: MTLFunction!
        var fragmentFunction: MTLFunction!
        
        if geometry.useModel {
            guard let vertexDescriptor = modelVertexDescriptor else {
                fatalError("No vertex descriptor found")
            }
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
            vertexFunction = defaultLibrary.makeFunction(name: "vertex_obj")
            fragmentFunction = defaultLibrary.makeFunction(name: "fragment_obj")
        } else {
            guard let vertexDescriptor = customGeometryVertexDescriptor else {
                fatalError("No vertex descriptor found")
            }
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
            vertexFunction = defaultLibrary.makeFunction(name: "vertex_custom")
            fragmentFunction = defaultLibrary.makeFunction(name: "fragment_custom")
        }
        
        pipelineDescriptor.vertexFunction = vertexFunction
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
        
        if geometry.useModel {
            loadModel()
        } else {
            loadCustomGeometry()
        }
        
        createGraphicsPipelineState()
        
        var modelMatrix: simd_float4x4!
        if geometry.useModel {
            modelMatrix = simd_float4x4(rotationAbout: simd_float3(0, 1, 0),
                                        by: -Float.pi / 6) *  simd_float4x4(scaleBy: 0.25)
        } else {
            modelMatrix = simd_float4x4(1)
        }
        
        let viewMatrix = simd_float4x4(translationBy: SIMD3<Float>(0, 0, -2))
        let modelViewMatrix = viewMatrix * modelMatrix
        var uniforms = Uniforms(modelViewMatrix: modelViewMatrix,
                                projectionMatrix: projection.projectionMatrix)
        
        projection.setupProjectionMatrixBuffer(for: device)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        if geometry.useModel {
            for mesh in meshes {
                let vertexBuffer = mesh.vertexBuffers.first!
                renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
             
                for submesh in mesh.submeshes {
                    let indexBuffer = submesh.indexBuffer
                    renderEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                         indexCount: submesh.indexCount,
                                                         indexType: submesh.indexType,
                                                         indexBuffer: indexBuffer.buffer,
                                                         indexBufferOffset: indexBuffer.offset)
                }
            }
        } else {
            geometry.updateVertexBuffer(for: device)
            renderEncoder.setVertexBuffer(geometry.vertexBuffer, offset: 0, index: 0)
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
