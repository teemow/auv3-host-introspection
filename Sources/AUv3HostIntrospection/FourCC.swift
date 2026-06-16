import Foundation
import CoreAudioTypes

// FourCharCode (OSType) -> String helper, used internally by the collectors to
// render an AudioComponentDescription's type/subtype/manufacturer codes. Kept
// internal so it never collides with a host app's own FourCharCode extension.

extension FourCharCode {
    /// Render a FourCharCode (`OSType`) as its 4-character string (e.g. "aumu").
    /// Non-printable bytes become "?" so the output stays human-readable.
    static func string(from code: FourCharCode) -> String {
        let bytes = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF),
        ]
        let chars = bytes.map { byte -> Character in
            (byte >= 0x20 && byte < 0x7F) ? Character(UnicodeScalar(byte)) : "?"
        }
        return String(chars)
    }
}
