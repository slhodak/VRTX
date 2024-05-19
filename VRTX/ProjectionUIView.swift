import SwiftUI
import os

struct ProjectionUIView: View {
    let renderer: Renderer
    @State var projection: Projection
    // make projection a property here, wrangle the need to expose it in various places
    // or use a publisher for update events
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "ProjectionUIViewController")
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack() {
                Toggle(isOn: $projection.useProjection) {
                    Text("Projection")
                }
                Toggle(isOn: $projection.usePerspectiveProjection) {
                    Text("Ortho/Persp")
                }
            }
            LabeledSlider(name: "FOV Y Radians Denominator (x in Float.pi / x)", value: $projection.perspectiveFOVYDenominator)
            LabeledSlider(name: "Orthographic Top", value: $projection.orthographicTop)
            LabeledSlider(name: "Orthographic Bottom", value: $projection.orthographicBottom)
            LabeledSlider(name: "Orthographic Left", value: $projection.orthographicLeft)
            LabeledSlider(name: "Orthographic Right", value: $projection.orthographicRight)
            LabeledSlider(name: "Near Z", value: $projection.projectionNear)
            LabeledSlider(name: "Far Z", value: $projection.projectionFar)
        }
        .padding()
    }
}

struct LabeledSlider: View {
    let name: String
    @Binding var value: Float
    
    var body: some View {
        HStack {
            Slider(value: $value) {
                Text(name)
            }
            Text("\(value)")
        }
    }
}
