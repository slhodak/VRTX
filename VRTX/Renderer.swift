import MetalKit
import Metal
import os

struct Vertex {
    var position: vector_float4
}

class Renderer: NSObject, MTKViewDelegate {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Renderer")
    var view: MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var vertexData: [Vertex] = [
        Vertex(position: [0.0, -1.0, 0.0, 1.0]),
        Vertex(position: [0.5, 0.0, 0.0, 1.0]),
        Vertex(position: [1.0, -1.0, 0.0, 1.0]),
    ]
    var vertexBuffer: MTLBuffer!
    
    var projectionMatrix = matrix_identity_float4x4
    var projectionMatrixBuffer: MTLBuffer?
    var projectionPerspectiveAspect: Float!
    var usePerspectiveProjection: Bool = false
    var useProjection: Bool = false
    var perspectiveFovyRadians: Float = Float.pi / 4
    var orthographicLeft: Float = 0
    var orthographicRight: Float = 0
    var orthographicTop: Float = 0
    var orthographicBottom: Float = 0
    var projectionNearZ: Float = 0.1
    var projectionFarZ: Float = 100.0
    
    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            return nil
        }
        
        self.view = metalView
        self.device = device
        self.commandQueue = queue
        super.init()
        
        self.projectionPerspectiveAspect = Float(view.bounds.width / view.bounds.size.height)
        metalView.device = device
        metalView.delegate = self
        
        createGraphicsPipelineState()
    }
    
    func updateVertex(index: Int, axis: String, value: Float) {
        switch axis {
        case "x":
            vertexData[index].position.x = value
        case "y":
            vertexData[index].position.y = value
        case "z":
            vertexData[index].position.z = value
        default:
            logger.error("Could not update vertex: unrecognized axis")
            break
        }
        updateVertexBuffer()
        draw()
    }
    
    func updateVertexBuffer() {
        let newBufferSize = vertexData.count * MemoryLayout<Vertex>.stride
        
        // Check if the existing buffer can accommodate the new data
        if newBufferSize > vertexBuffer.length {
            // Reallocate the buffer if new data size exceeds the current buffer size
            vertexBuffer = device.makeBuffer(bytes: vertexData,
                                             length: newBufferSize,
                                             options: .storageModeShared)
            if vertexBuffer == nil {
                print("Failed to allocate vertex buffer.")
                return
            }
        } else {
            // Update the buffer contents directly if it fits
            let bufferPointer = vertexBuffer.contents()
            bufferPointer.copyMemory(from: vertexData, byteCount: newBufferSize)
        }
    }
    
    func createGraphicsPipelineState() {
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: vertexData.count * MemoryLayout<Vertex>.stride,
                                         options: .storageModeShared)
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride

        if useProjection {
            if usePerspectiveProjection {
                projectionMatrix = makePerspectiveMatrix(fovyRadians: perspectiveFovyRadians,
                                                         aspect: projectionPerspectiveAspect,
                                                         nearZ: projectionNearZ,
                                                         farZ: projectionFarZ)
            } else {
                projectionMatrix = makeOrthographicMatrix(left: orthographicLeft,
                                                          right: orthographicRight,
                                                          bottom: orthographicBottom,
                                                          top: orthographicTop,
                                                          nearZ: projectionNearZ,
                                                          farZ: projectionFarZ)
            }
        } else {
            projectionMatrix = matrix_identity_float4x4
        }
        
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
        
        let mat = matrix_float4x4(columns: (
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
