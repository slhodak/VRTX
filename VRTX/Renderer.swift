import MetalKit
import Metal
import os

struct Vertex {
    var position: vector_float4
}

// This is a messy redundancy
enum ProjectionProperty: String {
    case FOVDenominator
    case orthoLeft
    case orthoRight
    case orthoTop
    case orthoBottom
    case near
    case far
    
    static func fromString(_ string: String) -> ProjectionProperty? {
        return ProjectionProperty(rawValue: string)
    }
}

class Projection {
    var projectionMatrix = simd_float4x4(1)
    var projectionMatrixBuffer: MTLBuffer?
    var projectionPerspectiveAspect: Float!
    var usePerspectiveProjection: Bool = true
    var useProjection: Bool = true
    var perspectiveFOVDenominator: Float = 4.0
    var orthographicLeft: Float = 0
    var orthographicRight: Float = 0
    var orthographicTop: Float = 0
    var orthographicBottom: Float = 0
    var projectionNear: Float = 0.0
    var projectionFar: Float = 100.0
    
    func perspectiveFOVRadians() -> Float {
        return Float.pi / perspectiveFOVDenominator
    }
    
    func setProjectionMatrixAspect(for view: NSView) {
        projectionPerspectiveAspect = Float(view.bounds.width / view.bounds.size.height)
    }
    
    func setupProjectionMatrixBuffer(for device: MTLDevice) {
        if useProjection {
            if usePerspectiveProjection {
                projectionMatrix = LinAlg.perspectiveMatrix(fov: perspectiveFOVRadians(),
                                                            aspect: projectionPerspectiveAspect,
                                                            near: projectionNear,
                                                            far: projectionFar)
            } else {
                projectionMatrix = LinAlg.orthographicMatrix(left: orthographicLeft,
                                                             right: orthographicRight,
                                                             bottom: orthographicBottom,
                                                             top: orthographicTop,
                                                             nearZ: projectionNear,
                                                             farZ: projectionFar)
            }
            
            //logger.debug("Projection matrix set with fov: \(self.perspectiveFOVRadians()), aspect: \(self.projectionPerspectiveAspect), near: \(self.projectionNear), far: \(self.projectionFar)")
        } else {
            projectionMatrix = simd_float4x4(1)
        }
        
        projectionMatrixBuffer = device.makeBuffer(bytes: &projectionMatrix,
                                                   length: MemoryLayout<simd_float4x4>.stride,
                                                   options: .storageModeShared)
    }
    
    func updateProjection(property: ProjectionProperty, value: Float) {
        switch property {
        case .FOVDenominator:
            perspectiveFOVDenominator = value
        case .orthoLeft:
            orthographicLeft = value
        case .orthoRight:
            orthographicRight = value
        case .orthoTop:
            orthographicTop = value
        case .orthoBottom:
            orthographicBottom = value
        case .near:
            projectionNear = value
        case .far:
            projectionFar = value
        }
    }
}

class Geometry {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Geometry")
    var vertices: [Vertex] = [
        Vertex(position: [0.0, -1.0, 0.1, 1.0]),
        Vertex(position: [0.5, 0.0, 0.1, 1.0]),
        Vertex(position: [1.0, -1.0, 0.1, 1.0]),
    ]
    var vertexBuffer: MTLBuffer!
    
    func updateVertex(index: Int, axis: String, value: Float) {
        switch axis {
        case "x":
            vertices[index].position.x = value
        case "y":
            vertices[index].position.y = value
        case "z":
            vertices[index].position.z = value
        default:
            logger.error("Could not update vertex: unrecognized axis")
            break
        }
    }
    
    func setupVertexBuffer(for device: MTLDevice) {
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: vertices.count * MemoryLayout<Vertex>.stride,
                                         options: .storageModeShared)
    }
    
    func updateVertexBuffer(for device: MTLDevice) {
        let newBufferSize = vertices.count * MemoryLayout<Vertex>.stride
        
        // Check if the existing buffer can accommodate the new data
        if newBufferSize > vertexBuffer.length {
            // Reallocate the buffer if new data size exceeds the current buffer size
            vertexBuffer = device.makeBuffer(bytes: vertices,
                                             length: newBufferSize,
                                             options: .storageModeShared)
            if vertexBuffer == nil {
                print("Failed to allocate vertex buffer.")
                return
            }
        } else {
            // Update the buffer contents directly if it fits
            let bufferPointer = vertexBuffer.contents()
            bufferPointer.copyMemory(from: vertices, byteCount: newBufferSize)
        }
    }
    
    func scale(vertices: [Vertex], by scalar: Float) -> [Vertex] {
        var scaledVertices: [Vertex] = []
        for vertex in vertices {
            scaledVertices.append(Vertex(position: vertex.position * scalar))
        }
        
        return scaledVertices
    }
}

class Renderer: NSObject, MTKViewDelegate {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Renderer")
    var view: MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var geometry: Geometry!
    var projection: Projection!
    
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
