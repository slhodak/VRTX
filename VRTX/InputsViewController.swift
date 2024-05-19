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
    func vertexSliderValueChanged(name: String, value: Float)
    func projectionSliderValueChanged(name: String, value: Float)
}

class LabeledSlider {
    /// Initialize everything to empty here because we need to use self in the setup function, but cannot use it in init()
    var name = ""
    var type: SliderGroup
    var label = NSTextField()
    var slider = NSSlider()
    var valueLabel = NSTextField()
    var delegate: LabeledSliderDelegate?
    
    init(type: SliderGroup) {
        self.type = type
    }
    
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
        switch self.type {
        case .vertexPosition:
            delegate?.vertexSliderValueChanged(name: name, value: value)
        case .projectionMatrix:
            delegate?.projectionSliderValueChanged(name: name, value: value)
        }
    }
}

enum SliderGroup {
    case vertexPosition
    case projectionMatrix
}

class InputsViewController: NSViewController, LabeledSliderDelegate {
    let renderer: Renderer
    var scrollView: NSScrollView!
    var contentView: NSView!
    let logger = Logger(subsystem: "com.samhodak.VRTX", category: "InputsViewController")
    
    var labeledSliders: [SliderGroup: [String: LabeledSlider]] = [:]
    var redrawButton: NSButton!
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
    
    func vertexSliderValueChanged(name: String, value: Float) {
        labeledSliders[.vertexPosition]?[name]?.valueLabel.stringValue = String(value)
        
        let nameParts = name.split(separator: "_")
        guard let index = Int(nameParts[0]) else {
            logger.error("Name part \(nameParts[0]) cast to Int failed")
            return
        }
        renderer.geometry.updateVertex(index: index, axis: String(nameParts[1]), value: value)
        renderer.draw()
    }
    
    func projectionSliderValueChanged(name: String, value: Float) {
        guard let property = ProjectionProperty.fromString(name) else {
            logger.error("Failed to cast \(name) to ProjectionProperty")
            return
        }
        
        labeledSliders[.projectionMatrix]?[name]?.valueLabel.stringValue = String(value)
        renderer.projection.updateProjection(property: property, value: value)
        renderer.draw()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.hasVerticalScroller = true
        contentView = NSView(frame: NSRect(x: 0, y: 0, width: scrollView.bounds.width, height: 1000))
        scrollView.documentView = contentView
        view.addSubview(scrollView)
        
        var topAnchor = contentView.topAnchor
        topAnchor = setupVertexSliders(topAnchor: topAnchor)
        topAnchor = setupLabeledSwitch(name: "Projection", topAnchor: topAnchor, action: #selector(toggleProjectionSwitch(_:)), value: renderer.projection.useProjection)
        topAnchor = setupLabeledSwitch(name: "Ortho/Persp", topAnchor: topAnchor, action: #selector(toggleProjectionTypeSwitch(_:)), value: renderer.projection.usePerspectiveProjection)
        topAnchor = setupProjectionMatrixSliders(topAnchor: topAnchor)
        _ = setupRedrawButton(topAnchor: topAnchor)
    }
    
    func setupVertexSliders(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        let axisLabels = ["x", "y", "z"]
        var lastTopAnchor = topAnchor
        
        if labeledSliders[.vertexPosition] == nil {
            labeledSliders[.vertexPosition] = [:]
        }
        
        for (i, vertex) in renderer.geometry.vertices.enumerated() {
            for axisLabel in axisLabels {
                let name = "\(i)_\(axisLabel)"
                let labeledSlider = LabeledSlider(type: .vertexPosition)
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
                labeledSlider.setup(view: contentView,
                                    topAnchor: lastTopAnchor,
                                    name: name,
                                    value: Double(vertexAxisValue),
                                    minValue: -1.0,
                                    maxValue: 1.0)
                
                labeledSlider.delegate = self
                labeledSliders[.vertexPosition]![name] = labeledSlider
                lastTopAnchor = labeledSlider.slider.bottomAnchor
            }
        }
        
        return lastTopAnchor
    }
    
    func setupProjectionMatrixSliders(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        if labeledSliders[.projectionMatrix] == nil {
            labeledSliders[.projectionMatrix] = [:]
        }
        
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
        let labeledSlider = LabeledSlider(type: .projectionMatrix)
        labeledSlider.setup(view: contentView,
                            topAnchor: topAnchor,
                            name: property.rawValue,
                            value: Double(value),
                            minValue: Double(minValue),
                            maxValue: Double(maxValue))
        labeledSlider.delegate = self
        labeledSliders[.projectionMatrix]![property.rawValue] = labeledSlider
        
        return labeledSlider.slider.bottomAnchor
    }
    
    func setupLabeledSwitch(name: String, topAnchor: NSLayoutYAxisAnchor, action: Selector, value: Bool) -> NSLayoutYAxisAnchor {
        let label = NSTextField(labelWithString: name)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.widthAnchor.constraint(equalToConstant: 100)
        ])
        
        projectionMatrixSwitch = NSSwitch(frame: NSRect(x: 20, y: 20, width: 40, height: 20))
        projectionMatrixSwitch.state = value ? .on : .off
        projectionMatrixSwitch.target = self
        projectionMatrixSwitch.action = action
        contentView.addSubview(projectionMatrixSwitch)
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
    
    func setupRedrawButton(topAnchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
        // Create a button to apply changes and redraw
        redrawButton = NSButton(title: "Redraw", target: self, action: #selector(redraw))
        redrawButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(redrawButton)
        
        NSLayoutConstraint.activate([
            redrawButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            redrawButton.topAnchor.constraint(equalTo: topAnchor, constant: 10)
        ])
        
        return redrawButton.bottomAnchor
    }
    
    @objc func redraw() {
        renderer.draw()
    }
}
