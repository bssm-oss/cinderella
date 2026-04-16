import Foundation

// Events model: protocol + example event descriptors
protocol CinderellaEvent {
    var id: String { get }
    var name: String { get }
    var baseIntensity: Int { get }
    func apply(intensity: Int)
    func deactivate()
}

extension CinderellaEvent {
    // default no-op
    func deactivate() {}
}

struct EventDescriptor {
    let id: String
    let name: String
    let params: [String: Any]
}

// Example event descriptors live here
let builtinEvents: [EventDescriptor] = []
