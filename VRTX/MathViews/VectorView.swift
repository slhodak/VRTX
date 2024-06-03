//
//  VectorView.swift
//  VRTX
//
//  Created by Sam Hodak on 6/3/24.
//

import Foundation
import SwiftUI
import simd

struct VectorView: View {
    @Binding var vector: simd_float3
    
    var body: some View {
        HStack {
            TextField("x", value: $vector[0], format: .number).frame(width: 45)
            TextField("y", value: $vector[1], format: .number).frame(width: 45)
            TextField("z", value: $vector[2], format: .number).frame(width: 45)
        }
    }
}
