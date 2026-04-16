import Foundation

final class KeySubstitutionEvent: CinderellaEvent {
    let id = "key_substitution"
    let name = "Key Substitution"
    let baseIntensity = 2

    // mapping from input char to list of possible substitutions
    let baseMap: [Character: [Character]] = [
        "i": ["u","o"],
        "o": ["i","p"],
        "u": ["y","i"]
    ]

    func apply(intensity: Int) {
        // duration grows with intensity but capped
        let dur = min(60, 5 + intensity * 5) // seconds
        InputInterceptor.shared.enableSubstitution(map: baseMap, duration: TimeInterval(dur))
    }
}
