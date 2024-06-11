import SwiftUI

struct MaterialUIView: View {
    @State var material: Material
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Materials").bold()
            Text("Specular Color")
            LabeledSlider(name: "R", value: $material.specularColor.x, min: 0, max: 1)
            LabeledSlider(name: "G", value: $material.specularColor.y, min: 0, max: 1)
            LabeledSlider(name: "B", value: $material.specularColor.z, min: 0, max: 1)
            LabeledSlider(name: "Specular Power",
                          value: $material.specularPower,
                          min: 0.01,
                          max: 300)
            Spacer()
        }
        .padding()
    }
}
