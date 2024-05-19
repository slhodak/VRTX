import Cocoa
import MetalKit
import os

/// I want to add a slider for every property that needs one
/// i want to add that slider by name and associate it with the correct value automatically
/// I want a single method that creates labeled sliders, and takes target properties etc as parameters
///     i can use the label to name the slider in the dictionary, and then read that label to get it back out
///     i could use a switch statement to alter the appropriate value based on the name of the slider...
///         the switch could be exhaustive and safe if I make it choose from an enum

enum ProjectionSlider: String {
    case orthographicLeft
    case orthographicRight
    case orthographicTop
    case orthographicBottom
    case projectionNearZ
    case projectionFarZ
}

protocol LabeledSliderDelegate: AnyObject {
    func sliderValueChanged(name: String, value: Float)
}

class LabeledSlider {
    /// Initialize everything to empty here because we need to use self in the setup function, but cannot use it in init()
    var name = ""
    var label = NSTextField()
    var slider = NSSlider()
    var valueLabel = NSTextField()
    var delegate: LabeledSliderDelegate?
    
    func setup(view: NSView, topAnchor: NSLayoutYAxisAnchor, name: String, value: Double, minValue: Double, maxValue: Double) {
        self.name = name
        label = NSTextField(labelWithString: name)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.widthAnchor.constraint(equalToConstant: 62)
        ])
        
        slider = NSSlider(value: value, minValue: minValue, maxValue: maxValue, target: self, action: #selector(valueChanged(_:)))
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        
        NSLayoutConstraint.activate([
            slider.topAnchor.constraint(equalTo: label.topAnchor),
            slider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        valueLabel = NSTextField(labelWithString: "0")
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.doubleValue = value
        view.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: slider.topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 5),
            valueLabel.widthAnchor.constraint(equalToConstant: 62)
        ])
    }
    
    @objc func valueChanged(_ sender: NSSlider) {
        let value = sender.floatValue.rounded(to: 2)
        delegate?.sliderValueChanged(name: name, value: value)
    }
}

class ProjectionUIViewController: NSViewController, LabeledSliderDelegate {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "ProjectionUIViewController")
    let renderer: Renderer
    var labeledSliders: [String: LabeledSlider] = [:]
    var projectionMatrixSwitch: NSSwitch!
    var projectionMatrixTypeSwitch: NSSwitch!
    
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
        
        var topAnchor = view.topAnchor
        topAnchor = setupLabeledSwitch(name: "Projection", topAnchor: topAnchor, action: #selector(toggleProjectionSwitch(_:)), value: renderer.projection.useProjection)
        topAnchor = setupLabeledSwitch(name: "Ortho/Persp", topAnchor: topAnchor, action: #selector(toggleProjectionTypeSwitch(_:)), value: renderer.projection.usePerspectiveProjection)
        _ = setupProjectionMatrixSliders(topAnchor: topAnchor)
    }
    
    func sliderValueChanged(name: String, value: Float) {
        guard let property = ProjectionProperty.fromString(name) else {
            logger.error("Failed to cast \(name) to ProjectionProperty")
            return
        }
        
        labeledSliders[name]?.valueLabel.stringValue = String(value)
        renderer.projection.updateProjection(property: property, value: value)
        renderer.draw()
    }
    
    func setupProjectionMatrixSliders(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        var bottomAnchor = addProjectionMatrixSlider(property: .FOVDenominator, topAnchor: topAnchor, value: renderer.projection.perspectiveFOVDenominator, maxValue: 16)
        bottomAnchor = addProjectionMatrixSlider(property: .orthoLeft, topAnchor: bottomAnchor)
        bottomAnchor = addProjectionMatrixSlider(property: .orthoRight, topAnchor: bottomAnchor)
        bottomAnchor = addProjectionMatrixSlider(property: .orthoTop, topAnchor: bottomAnchor)
        bottomAnchor = addProjectionMatrixSlider(property: .orthoBottom, topAnchor: bottomAnchor)
        bottomAnchor = addProjectionMatrixSlider(property: .near, topAnchor: bottomAnchor, value: renderer.projection.projectionNear)
        bottomAnchor = addProjectionMatrixSlider(property: .far, topAnchor: bottomAnchor, value: renderer.projection.projectionFar)
        
        return bottomAnchor
    }
    
    func addProjectionMatrixSlider(property: ProjectionProperty, topAnchor: NSLayoutYAxisAnchor, value: Float = 0, minValue: Float = 0, maxValue: Float = 100) -> NSLayoutYAxisAnchor {
        let labeledSlider = LabeledSlider()
        labeledSlider.setup(view: view,
                            topAnchor: topAnchor,
                            name: property.rawValue,
                            value: Double(value),
                            minValue: Double(minValue),
                            maxValue: Double(maxValue))
        labeledSlider.delegate = self
        labeledSliders[property.rawValue] = labeledSlider
        
        return labeledSlider.slider.bottomAnchor
    }
    
    func setupLabeledSwitch(name: String, topAnchor: NSLayoutYAxisAnchor, action: Selector, value: Bool) -> NSLayoutYAxisAnchor {
        let label = NSTextField(labelWithString: name)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.widthAnchor.constraint(equalToConstant: 100)
        ])
        
        projectionMatrixSwitch = NSSwitch(frame: NSRect(x: 20, y: 20, width: 40, height: 20))
        projectionMatrixSwitch.state = value ? .on : .off
        projectionMatrixSwitch.target = self
        projectionMatrixSwitch.action = action
        view.addSubview(projectionMatrixSwitch)
        projectionMatrixSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            projectionMatrixSwitch.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            projectionMatrixSwitch.centerXAnchor.constraint(equalTo: label.trailingAnchor),
        ])
        
        return projectionMatrixSwitch.bottomAnchor
    }
    
    @objc func toggleProjectionSwitch(_ sender: NSSwitch) {
        renderer.projection.useProjection = sender.state == .on
        renderer.draw()
    }
    
    @objc func toggleProjectionTypeSwitch(_ sender: NSSwitch) {
        renderer.projection.usePerspectiveProjection = sender.state == .on
        renderer.draw()
    }
}

class GeometryUIViewController: NSViewController, LabeledSliderDelegate {
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "GeometryUIViewController")
    let renderer: Renderer
    var labeledSliders: [String: LabeledSlider] = [:]
    
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
        
        setupVertexSliders(topAnchor: view.topAnchor)
    }
    
    func sliderValueChanged(name: String, value: Float) {
        labeledSliders[name]?.valueLabel.stringValue = String(value)
        
        let nameParts = name.split(separator: "_")
        guard let index = Int(nameParts[0]) else {
            logger.error("Name part \(nameParts[0]) cast to Int failed")
            return
        }
        renderer.geometry.updateVertex(index: index, axis: String(nameParts[1]), value: value)
        renderer.draw()
    }
    
    func setupVertexSliders(topAnchor: NSLayoutYAxisAnchor) {
        let axisLabels = ["x", "y", "z"]
        var lastTopAnchor = view.topAnchor
        
        for (i, vertex) in renderer.geometry.vertices.enumerated() {
            for axisLabel in axisLabels {
                let name = "\(i)_\(axisLabel)"
                let labeledSlider = LabeledSlider()
                var vertexAxisValue: Float = 0.0
                switch axisLabel {
                case "x":
                    vertexAxisValue = vertex.position.x
                case "y":
                    vertexAxisValue = vertex.position.y
                case "z":
                    vertexAxisValue = vertex.position.z
                default:
                    break
                }
                labeledSlider.setup(view: view,
                                    topAnchor: lastTopAnchor,
                                    name: name,
                                    value: Double(vertexAxisValue),
                                    minValue: -1.0,
                                    maxValue: 1.0)
                
                labeledSlider.delegate = self
                labeledSliders[name] = labeledSlider
                lastTopAnchor = labeledSlider.slider.bottomAnchor
            }
        }
    }
}

class InputsViewController: NSViewController {
    let renderer: Renderer
    var scrollView: NSScrollView!
    var contentView: NSView!
    var geometryUIViewController: GeometryUIViewController!
    var projectionUIViewController: ProjectionUIViewController!
    
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "InputsViewController")
    
    var redrawButton: NSButton!
    
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
        geometryUIViewController = GeometryUIViewController(renderer: renderer)
        projectionUIViewController = ProjectionUIViewController(renderer: renderer)
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.hasVerticalScroller = true
        contentView = NSView(frame: NSRect(x: 0, y: 0, width: scrollView.bounds.width, height: 1000))
        contentView.addSubview(geometryUIViewController.view)
        
        NSLayoutConstraint.activate([
            geometryUIViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor)
        ])
        
//        contentView.addSubview(projectionUIViewController.view)
//        
//        NSLayoutConstraint.activate([
//            projectionUIViewController.view.topAnchor.constraint(equalTo: geometryUIViewController.view.bottomAnchor)
//        ])
//        setupRedrawButton(topAnchor: projectionUIViewController.view.bottomAnchor)
        
        scrollView.documentView = contentView
        view.addSubview(scrollView)
    }
    
//    func setupRedrawButton(topAnchor: NSLayoutYAxisAnchor) {
//        // Create a button to apply changes and redraw
//        redrawButton = NSButton(title: "Redraw", target: self, action: #selector(redraw))
//        redrawButton.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(redrawButton)
//        
//        NSLayoutConstraint.activate([
//            redrawButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            redrawButton.topAnchor.constraint(equalTo: topAnchor, constant: 10)
//        ])
//    }
//    
//    @objc func redraw() {
//        renderer.draw()
//    }
}
