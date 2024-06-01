import SwiftUI
import MetalKit
import simd
import os

struct Vertex {
    var position: simd_float3
    var normal: simd_float3
    var color: simd_float3
    
    func scale(by scalar: Float) -> Vertex {
        return Vertex(position: [
            position.x * scalar,
            position.y * scalar,
            position.z * scalar
        ],
                      normal: self.normal,
                      color: self.color
        )
    }
}

@Observable
class Geometry {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "Geometry")
    var useModel = true
    var triangleVertexPositions: simd_float3x3 = simd_float3x3(
        [0.0, 2, -5],
        [2, -2, -5],
        [-2, -2, -5]
    )
    var triangleVertexColors: simd_float3x3 = simd_float3x3(
        [1.0, 0.0, 0.0],
        [0.0, 1.0, 0.0],
        [0.0, 0.0, 1.0]
    )

    var vertices = [Vertex]()
    var vertexBuffer: MTLBuffer!
    var scale: Float = 1.0
    var translation: vector_float3 = [0, 0, 0]
    
    func initVertices() {
        for i in 0..<3 {
            vertices.append(Vertex(position: triangleVertexPositions[i], normal: getNormals(), color: triangleVertexColors[i]))
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
    
    func getNormals() -> simd_float3 {
        // Calculate vectors for two edges of the triangle
        let edge1 = triangleVertexPositions[1] - triangleVertexPositions[0]
        let edge2 = triangleVertexPositions[2] - triangleVertexPositions[0]

        // Compute the cross product of the two edge vectors
        let normal = simd_cross(edge1, edge2)

        // Normalize the resulting vector to get the unit normal
        return simd_normalize(normal)
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
            let newPosition = vertex.position + [translation.x, translation.y, translation.z]
            return Vertex(position: newPosition, normal: vertex.normal, color: vertex.color)
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
