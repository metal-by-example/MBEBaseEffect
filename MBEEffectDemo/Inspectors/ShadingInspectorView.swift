
import Cocoa
import AppKit

class ShadingInspectorView : InspectorView {
    var effect: MBEBaseEffect? {
        didSet {
            bindToEffect()
        }
    }

    @IBOutlet weak var lightingModePopUpButton: NSPopUpButton!
    @IBOutlet weak var twoSidedLightingCheckbox: NSButton!
    @IBOutlet weak var ambientColorWell: NSColorWell!
    @IBOutlet weak var constantColorWell: NSColorWell!
    @IBOutlet weak var constantColorCheckbox: NSButton!

    override var disclosedHeight: CGFloat { return 125 }

    func bindToEffect() {
        guard let effect = effect else { return }
        self.lightingModePopUpButton.selectItem(at: Int(effect.lightingMode.rawValue))
        self.twoSidedLightingCheckbox.state = effect.lightModelTwoSided ? .on : .off
        self.ambientColorWell.color = NSColor(red: CGFloat(effect.ambientLightColor.x),
                                              green: CGFloat(effect.ambientLightColor.y),
                                              blue: CGFloat(effect.ambientLightColor.z),
                                              alpha: CGFloat(effect.ambientLightColor.w))
        self.constantColorWell.color = NSColor(red: CGFloat(effect.constantColor.x),
                                              green: CGFloat(effect.constantColor.y),
                                              blue: CGFloat(effect.constantColor.z),
                                              alpha: CGFloat(effect.constantColor.w))
        self.constantColorCheckbox.state = effect.useConstantColor ? .on : .off
    }

    @IBAction func disclosureButtonValueDidChange(_ sender: Any) {
        setDisclosed(disclosureButton!.state == .on, animate: true)
    }

    @IBAction func lightingModeValueDidChange(_ sender: Any) {
        effect?.lightingMode = MBEEffectLightingMode(rawValue: UInt32(lightingModePopUpButton.indexOfSelectedItem)) ?? .perVertex
    }

    @IBAction func twoSidedLightingValueDidChange(_ sender: Any) {
        effect?.lightModelTwoSided = (twoSidedLightingCheckbox.state == .on)
    }

    @IBAction func ambientColorWellValueDidChange(_ sender: Any) {
        guard let effect = effect else { return }
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        ambientColorWell.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        effect.ambientLightColor = MBEVector4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    @IBAction func constantColorWellValueDidChange(_ sender: Any) {
        guard let effect = effect else { return }
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        constantColorWell.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        effect.constantColor = MBEVector4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    @IBAction func useConstantColorValueDidChange(_ sender: Any) {
        effect?.useConstantColor = constantColorCheckbox.state == .on
    }
}
