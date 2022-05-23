
import Cocoa

class FlippedView : NSView {
    override var isFlipped: Bool { return true }
}

class EffectInspectorView: NSView {
    var effect: MBEBaseEffect? {
        didSet {
            bindInspectors()
        }
    }

    var scrollView: NSScrollView!
    var inspectorHostingView: NSView!

    var materialInspectorView: MaterialInspectorView!
    var fogInspectorView: FogParameterInspectorView!
    var lightInspectorViews = [LightInspectorView]()
    var textureInspectorViews = [TextureInspectorView]()
    var shadingInspectorView: ShadingInspectorView!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        makeInspectorViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        makeInspectorViews()
    }

    private func makeInspectorViews() {
        scrollView = NSScrollView(frame: self.bounds)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(scrollView)

        inspectorHostingView = FlippedView(frame: self.bounds)
        inspectorHostingView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = inspectorHostingView

        var topLevels: NSArray?

        let materialInspectorNib = NSNib(nibNamed: "MaterialInspectorView", bundle: nil)
        materialInspectorNib!.instantiate(withOwner: nil, topLevelObjects: &topLevels)
        if let materialInspectorView = topLevels?.first(where: { $0 is MaterialInspectorView }) as? MaterialInspectorView {
            inspectorHostingView.addSubview(materialInspectorView)
            self.materialInspectorView = materialInspectorView
        }

        let lightInspectorNib = NSNib(nibNamed: "LightInspectorView", bundle: nil)
        for lightIndex in 0..<3 {
            lightInspectorNib!.instantiate(withOwner: nil, topLevelObjects: &topLevels)
            if let lightInspectorView = topLevels?.first(where: { $0 is LightInspectorView }) as? LightInspectorView {
                inspectorHostingView.addSubview(lightInspectorView)
                lightInspectorView.title = "Light \(lightIndex + 1)"
                lightInspectorViews.append(lightInspectorView)
            }
        }

        let textureInspectorNib = NSNib(nibNamed: "TextureInspectorView", bundle: nil)
        for textureIndex in 0..<2 {
            textureInspectorNib!.instantiate(withOwner: nil, topLevelObjects: &topLevels)
            if let textureInspectorView = topLevels?.first(where: { $0 is TextureInspectorView }) as? TextureInspectorView {
                inspectorHostingView.addSubview(textureInspectorView)
                textureInspectorView.titleLabel.stringValue = "Texture \(textureIndex + 1)"
                textureInspectorViews.append(textureInspectorView)
            }
        }

        let fogInspectorNib = NSNib(nibNamed: "FogParameterInspectorView", bundle: nil)
        fogInspectorNib!.instantiate(withOwner: nil, topLevelObjects: &topLevels)
        if let fogInspectorView = topLevels?.first(where: { $0 is FogParameterInspectorView }) as? FogParameterInspectorView {
            inspectorHostingView.addSubview(fogInspectorView)
            self.fogInspectorView = fogInspectorView
        }

        let shadingInspectorNib = NSNib(nibNamed: "ShadingInspectorView", bundle: nil)
        shadingInspectorNib!.instantiate(withOwner: nil, topLevelObjects: &topLevels)
        if let shadingInspectorView = topLevels?.first(where: { $0 is ShadingInspectorView }) as? ShadingInspectorView {
            inspectorHostingView.addSubview(shadingInspectorView)
            self.shadingInspectorView = shadingInspectorView
        }

        let views: [String : Any] = [
            "scroll" : scrollView!,
            "content" : scrollView.contentView,
            "document" : inspectorHostingView!,
            "material" : materialInspectorView!,
            "light0" : lightInspectorViews[0],
            "light1" : lightInspectorViews[1],
            "light2" : lightInspectorViews[2],
            "texture0" : textureInspectorViews[0],
            "texture1" : textureInspectorViews[1],
            "fog" : fogInspectorView!,
            "shading" : shadingInspectorView!,
        ]

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[scroll]|", metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scroll]|", metrics: nil, views: views))

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[content]|", metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", metrics: nil, views: views))

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[document]|", metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[document]", metrics: nil, views: views))

        let inspectorViews = [materialInspectorView!, fogInspectorView!] + lightInspectorViews + textureInspectorViews
        for inspector in inspectorViews {
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[inspector]|",
                                                          metrics: nil,
                                                          views: ["inspector" : inspector]))
        }

        addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[material][texture0][texture1][light0][light1][light2][fog][shading]|",
            metrics: nil,
            views: views))

        lightInspectorViews[1].setDisclosed(false)
        lightInspectorViews[2].setDisclosed(false)
        textureInspectorViews[1].setDisclosed(false)
        fogInspectorView.setDisclosed(false)
    }

    func bindInspectors() {
        materialInspectorView.effect = effect
        lightInspectorViews[0].light = effect?.light0
        lightInspectorViews[1].light = effect?.light1
        lightInspectorViews[2].light = effect?.light2
        textureInspectorViews[0].device = effect?.device
        textureInspectorViews[0].texture = effect?.texture0
        textureInspectorViews[1].device = effect?.device
        textureInspectorViews[1].texture = effect?.texture1
        fogInspectorView.effect = effect
        shadingInspectorView.effect = effect
    }
}
