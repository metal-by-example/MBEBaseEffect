
import Foundation
import Cocoa

class InspectorView : NSView {
    @IBOutlet weak var disclosureButton: NSButton?
    @IBOutlet weak var containerView: NSView?

    var heightConstraint: NSLayoutConstraint!
    var disclosedHeight: CGFloat { return 100 }
    var undisclosedHeight: CGFloat { return 21 }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInspectorInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInspectorInit()
    }

    private func commonInspectorInit() {
        heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal,
                                              toItem: nil, attribute: .notAnAttribute, multiplier: 0.0,
                                              constant: disclosedHeight)
        self.addConstraint(heightConstraint)
    }

    func setDisclosed(_ disclosed: Bool, animate: Bool = false) {
        let targetHeight = disclosed ? disclosedHeight : undisclosedHeight
        if animate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                heightConstraint.constant = targetHeight
                disclosureButton?.state = disclosed ? .on : .off
                containerView?.isHidden = !disclosed
                superview?.layoutSubtreeIfNeeded()
            }
        } else {
            heightConstraint.constant = targetHeight
            disclosureButton?.state = disclosed ? .on : .off
            containerView?.isHidden = !disclosed
            superview?.layoutSubtreeIfNeeded()
        }
    }
}
