import SwiftUI
import MetalKit
import simd
import os

struct Vertex {
    var position: vector_float4
    var color: vector_float4
    
    func scale(by scalar: Float) -> Vertex {
        return Vertex(position: [
            position.x * scalar,
            position.y * scalar,
            position.z * scalar,
            position.w
        ],
                      color: self.color
        )
    }
}

@Observable
class Geometry {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Geometry")
    var triangleVertexPositions: simd_float3x4 = simd_float3x4(
        [0.0, 2, -5, 1.0],
        [2, -2, -5, 1.0],
        [-2, -2, -5, 1.0]
    )
    var triangleVertexColors: simd_float3x4 = simd_float3x4(
        [1.0, 0.0, 0.0, 1.0],
        [0.0, 1.0, 0.0, 1.0],
        [0.0, 0.0, 1.0, 1.0]
    )

    var vertices = [Vertex]()
    var vertexBuffer: MTLBuffer!
    var scale: Float = 1.0
    var translation: vector_float3 = [0, 0, 0]
    
    func initVertices() {
        for i in 0..<3 {
            vertices.append(Vertex(position: triangleVertexPositions[i], color: triangleVertexColors[i]))
        }
    }
    
    func updateVertices() {
        vertices = []
        initVertices()
        //logger.debug("Updated vertices: \(self.vertices)")
    }
    
    func setupVertexBuffer(for device: MTLDevice) {
        let transformedVertices = transform(self.vertices)
        vertexBuffer = device.makeBuffer(bytes: transformedVertices,
                                         length: transformedVertices.count * MemoryLayout<Vertex>.stride,
                                         options: .storageModeShared)
    }
    
    func updateVertexBuffer(for device: MTLDevice) {
        updateVertices()
        let transformedVertices = transform(self.vertices)
        let newBufferSize = transformedVertices.count * MemoryLayout<Vertex>.stride
        
        // Check if the existing buffer can accommodate the new data
        if newBufferSize > vertexBuffer.length {
            // Reallocate the buffer if new data size exceeds the current buffer size
            vertexBuffer = device.makeBuffer(bytes: transformedVertices,
                                             length: newBufferSize,
                                             options: .storageModeShared)
            if vertexBuffer == nil {
                print("Failed to allocate vertex buffer.")
                return
            }
        } else {
            // Update the buffer contents directly if it fits
            let bufferPointer = vertexBuffer.contents()
            bufferPointer.copyMemory(from: transformedVertices, byteCount: newBufferSize)
        }
    }
    
    func scale(_ vertices: [Vertex]) -> [Vertex] {
        // TODO: Always scale from origin/center of triangle
        let scaledVertices = vertices.map { vertex in
            vertex.scale(by: scale)
        }
        return scaledVertices
    }
    
    func translate(_ vertices: [Vertex]) -> [Vertex] {
        let translatedVertices = vertices.map { vertex in
            let newPosition = vertex.position + [translation.x, translation.y, translation.z, 0]
            return Vertex(position: newPosition, color: vertex.color)
        }
        return translatedVertices
    }
    
    func transform(_ vertices: [Vertex]) -> [Vertex] {
        /// In the future, can apply other transformations here
        var transformedVertices = scale(vertices)
        transformedVertices = translate(transformedVertices)
        return transformedVertices
    }
}
