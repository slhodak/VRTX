import SwiftUI
import os

struct ProjectionUIView: View {
    let renderer: Renderer
    @State var projection: Projection
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "ProjectionUIViewController")
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Toggle(isOn: $projection.useProjection) {
                    Text("Use Projection")
                }
                Spacer()
            }
            if projection.useProjection {
                Toggle(isOn: $projection.usePerspectiveProjection) {
                    Text("Orthographic / Perspective")
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
                
                Text("Current Projection Matrix").fontWeight(.bold)
                Text(projection.projectionMatrix.toString())
            }
        }
        .padding()
    }
}
