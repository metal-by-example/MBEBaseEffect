
import Cocoa
import AppKit

class FogParameterInspectorView : InspectorView {
    var effect: MBEBaseEffect? {
        didSet {
            bindToEffect()
        }
    }

    @IBOutlet weak var enabledButton: NSButton!
    @IBOutlet weak var modePopupButton: NSPopUpButton!
    @IBOutlet weak var fogColorWell: NSColorWell!
    @IBOutlet weak var fogDensityTextField: NSTextField!
    @IBOutlet weak var fogStartDistanceField: NSTextField!
    @IBOutlet weak var fogEndDistanceField: NSTextField!

    override var disclosedHeight: CGFloat { return 152 }

    func bindToEffect() {
        guard let fog = effect?.fog else { return }

        self.enabledButton.state = fog.enabled ? .on : .off
        modePopupButton.selectItem(at: Int(fog.mode.rawValue) - 1)
        self.fogColorWell.color = NSColor(red: CGFloat(fog.color.x),
                                          green: CGFloat(fog.color.y),
                                          blue: CGFloat(fog.color.z),
                                          alpha: CGFloat(fog.color.w))
        self.fogDensityTextField.stringValue = NSString(format: "%0.1f", fog.density) as String
        self.fogStartDistanceField.stringValue = NSString(format: "%0.1f", fog.start) as String
        self.fogEndDistanceField.stringValue = NSString(format: "%0.1f", fog.end) as String
    }

    @IBAction func disclosureButtonValueDidChange(_ sender: Any) {
        setDisclosed(disclosureButton!.state == .on, animate: true)
    }

    @IBAction func enableButtonValueDidChange(_ sender: Any) {
        guard let fog = effect?.fog else { return }
        fog.enabled = (enabledButton.state == .on)
    }

    @IBAction func modeButtonValueDidChange(_ sender: Any) {
        guard let fog = effect?.fog else { return }
        fog.mode = MBEFogMode(rawValue: UInt32(modePopupButton.indexOfSelectedItem) + 1) ?? .exp
    }

    @IBAction func fogColorWellValueDidChange(_ sender: Any) {
        guard let fog = effect?.fog else { return }
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        fogColorWell.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        fog.color = MBEVector4(Float(red), Float(green), Float(blue), Float(alpha))
    }

    @IBAction func fogDensityTextFieldValueDidChange(_ sender: Any) {
        guard let fog = effect?.fog else { return }
        fog.density = fogDensityTextField.floatValue
    }

    @IBAction func fogStartDistanceFieldValueDidChange(_ sender: Any) {
        guard let fog = effect?.fog else { return }
        fog.start = fogStartDistanceField.floatValue
    }

    @IBAction func fogEndDistanceFieldValueDidChange(_ sender: Any) {
        guard let fog = effect?.fog else { return }
        fog.end = fogEndDistanceField.floatValue
    }
}
