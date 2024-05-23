import SwiftUI
import os

struct ProjectionUIView: View {
    let renderer: Renderer
    @State var projection: Projection
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "ProjectionUIViewController")
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Projection Matrix")
            Matrix4x4View(mat: $projection.projectionMatrix)
                .onChange(of: projection.projectionMatrix) {
                    NotificationCenter.default.post(name: .drawMessage, object: nil)
                }
            
            HStack {
                Toggle(isOn: $projection.useProjection) {
                    Text("Use Projection Algorithm")
                }
                Spacer()
            }
            
            if projection.useProjection {
                HStack {
                    Toggle("Orthographic", isOn: $projection.usePerspectiveProjection)
                        .toggleStyle(.switch)
                    Text("Perspective")
                }
                LabeledSlider(name: "FOV Y Radians Denominator (x in Float.pi / x)",
                              value: $projection.perspectiveFOVYDenominator,
                              max: 4.0)
                Text("FOV Y Radians: \(projection.perspectiveFOVYRadians())")
                Text("Aspect Ratio: \(projection.projectionPerspectiveAspect)")
                LabeledSlider(name: "Orthographic Top", value: $projection.orthographicTop)
                LabeledSlider(name: "Orthographic Bottom", value: $projection.orthographicBottom)
                LabeledSlider(name: "Orthographic Left", value: $projection.orthographicLeft)
                LabeledSlider(name: "Orthographic Right", value: $projection.orthographicRight)
                LabeledSlider(name: "Near Z", value: $projection.projectionNear)
                LabeledSlider(name: "Far Z", value: $projection.projectionFar, max: 100.0, step: 5)
            }
        }
        .padding()
        .onChange(of: projection.useProjection) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: projection.usePerspectiveProjection) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: projection.perspectiveFOVYDenominator) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: projection.orthographicTop) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: projection.orthographicBottom) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: projection.orthographicLeft) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: projection.orthographicRight) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: projection.projectionNear) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
        .onChange(of: projection.projectionFar) {
            NotificationCenter.default.post(name: .drawMessage, object: nil)
        }
    }
}
