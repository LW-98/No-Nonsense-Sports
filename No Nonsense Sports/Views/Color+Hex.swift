//
//  Color+Hex.swift
//  No Nonsense Sports
//

import SwiftUI

extension Color {
    /// Initialise from a 3, 6, or 8-digit hex string. Leading `#` is optional.
    /// Returns `nil` for unparseable input so callers can fall back gracefully.
    init?(hex string: String?) {
        guard let raw = string?.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "#", with: ""),
              !raw.isEmpty,
              let value = UInt64(raw, radix: 16)
        else { return nil }

        let r, g, b, a: Double
        switch raw.count {
        case 3: // RGB (12-bit)
            r = Double((value >> 8) & 0xF) / 15
            g = Double((value >> 4) & 0xF) / 15
            b = Double( value       & 0xF) / 15
            a = 1
        case 6: // RGB (24-bit)
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >>  8) & 0xFF) / 255
            b = Double( value        & 0xFF) / 255
            a = 1
        case 8: // ARGB / RGBA (32-bit) — assume RGBA
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >>  8) & 0xFF) / 255
            a = Double( value        & 0xFF) / 255
        default:
            return nil
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Returns RGB components as a tuple (0-1 range).
    var rgbComponents: (r: Double, g: Double, b: Double) {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #else
        let nsColor = NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #endif
    }
}

/// Check if two hex colours clash (Euclidean distance < threshold)
func colorsClash(_ hex1: String?, _ hex2: String?, threshold: Double = 100) -> Bool {
    guard let color1 = Color(hex: hex1),
          let color2 = Color(hex: hex2) else { return false }

    let c1 = color1.rgbComponents
    let c2 = color2.rgbComponents

    // Euclidean distance in RGB
    let distance = sqrt(pow(c1.r - c2.r, 2) + pow(c1.g - c2.g, 2) + pow(c1.b - c2.b, 2)) * 255

    return distance < threshold
}
