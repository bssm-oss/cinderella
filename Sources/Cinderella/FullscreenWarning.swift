import Foundation
import AppKit

final class FullscreenWarning: CinderellaEvent {
    let id = "fullscreen_warning"
    let name = "Fullscreen Warning"
    let baseIntensity = 2

    private var window: NSWindow?

    func apply(intensity: Int) {
        DispatchQueue.main.async {
            self.showWarning(duration: 15)
        }
    }

    private func showWarning(duration: TimeInterval) {
        guard window == nil else { return }
        let screenFrame = NSScreen.main?.frame ?? NSRect(x:0,y:0,width:800,height:600)
        let w = NSWindow(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
        w.level = .statusBar
        w.isOpaque = false
        w.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.85)
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let tv = NSTextField(labelWithString: "집에 가세요!")
        tv.font = NSFont.systemFont(ofSize: 96, weight: .bold)
        tv.textColor = .white
        tv.alignment = .center
        tv.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView(frame: screenFrame)
        content.addSubview(tv)
        w.contentView = content

        NSLayoutConstraint.activate([
            tv.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            tv.centerYAnchor.constraint(equalTo: content.centerYAnchor)
        ])

        window = w
        w.makeKeyAndOrderFront(nil)

        // dismiss on click or ESC
        let gesture = NSClickGestureRecognizer(target: self, action: #selector(dismiss))
        content.addGestureRecognizer(gesture)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            if ev.keyCode == 53 { // ESC
                self?.dismiss()
                return nil
            }
            return ev
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.dismiss()
        }

        // play a warning sound
        SoundModule.shared.play(id: "warning", volume: 0.8)
    }

    @objc private func dismiss() {
        window?.orderOut(nil)
        window = nil
    }

    func deactivate() {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss()
        }
    }
}
