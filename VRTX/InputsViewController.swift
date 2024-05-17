import Cocoa

class InputsViewController: NSViewController {
    var sliders: [NSSlider] = []
    var sliderValuelabels: [NSTextField] = []
    var labels: [NSTextField] = []
    var redrawButton: NSButton!
    let renderer: Renderer
    
    init(renderer: Renderer) {
        self.renderer = renderer
        super.init(nibName: nil, bundle: nil)
    }
    
    /// Must implement this method if and only if you plan to instantiate this ViewController in the Storyboard
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        let coordinates = ["X", "Y", "Z"]
        var topConstraint = view.topAnchor
        
        // Create 3 sliders for each vertex
        for i in 0..<3 {
            // Create one slider each for x, y, and z
            for j in 0..<3 {
                let label = NSTextField(labelWithString: "Vertex \(i+1) \(coordinates[j])")
                label.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(label)
                
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: topConstraint, constant: 20),
                    label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    label.widthAnchor.constraint(equalToConstant: 62)
                ])
                
                let slider = NSSlider(value: 0.0, minValue: 0.0, maxValue: 10.0, target: self, action: #selector(sliderValueChanged(_:)))
                slider.tag = i * 3 + j // Use tag to identify the slider
                slider.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(slider)
                sliders.append(slider)
                
                NSLayoutConstraint.activate([
                    slider.topAnchor.constraint(equalTo: label.topAnchor),
                    slider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5),
                    slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
                ])
                
                let sliderValueLabel = NSTextField(labelWithString: "0")
                sliderValueLabel.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(sliderValueLabel)
                sliderValuelabels.append(sliderValueLabel)
                
                NSLayoutConstraint.activate([
                    sliderValueLabel.topAnchor.constraint(equalTo: slider.topAnchor),
                    sliderValueLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 5),
                    sliderValueLabel.widthAnchor.constraint(equalToConstant: 62)
                ])
                
                topConstraint = slider.bottomAnchor
            }
        }
        
        // Create a button to apply changes and redraw
        redrawButton = NSButton(title: "Redraw", target: self, action: #selector(redrawPressed))
        redrawButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(redrawButton)
        
        NSLayoutConstraint.activate([
            redrawButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            redrawButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }
    
    @objc func sliderValueChanged(_ sender: NSSlider) {
        // This function will now only record changes, not apply them immediately
        print("Slider \(sender.tag) value changed to \(sender.doubleValue)")
        sliderValuelabels[sender.tag].stringValue = String(sender.doubleValue)
    }
    
    @objc func redrawPressed() {
        // Apply slider values to vertex positions
        var vertexData: [Vertex] = []
        for i in 0..<3 {
            let x = Float(sliders[i * 3].doubleValue)
            let y = Float(sliders[i * 3 + 1].doubleValue)
            let z = Float(sliders[i * 3 + 2].doubleValue)
            vertexData.append(Vertex(position: [x, y, z, 1.0]))
        }
        
        renderer.updateVertexBuffer(with: vertexData)
        renderer.view.setNeedsDisplay(renderer.view.bounds) // Request redraw
    }
}
