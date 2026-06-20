//
//  NotchDesignTokens.swift
//  NotchCloset
//

import SwiftUI

enum NotchDesignTokens {
    static let spacing: CGFloat = 16
    static let cornerRadius: CGFloat = 16
    static let notchOpenedSize: CGSize = .init(width: 600, height: 160)
    static let dropDetectorRange: CGFloat = 32

    static let openAnimation: Animation = .timingCurve(0.2, 0, 0, 1, duration: 0.35)
    static let closeAnimation: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: 0.22)
    static let contentAnimation: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.28)
    static let insertAnimation: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.35)
    static let removeAnimation: Animation = .timingCurve(0.3, 0, 1, 1, duration: 0.18)
    static let hoverAnimation: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.15)
    static let trashAnimation: Animation = .spring(response: 0.28, dampingFraction: 0.8)
    static let popAnimation: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.15)
}
