//
//  NotchViewModel.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/7.
//  Modified by @kanade2511
//

import Cocoa
import Combine
import Foundation
import SwiftUI

class NotchViewModel: NSObject, ObservableObject {
    var cancellables: Set<AnyCancellable> = []
    let inset: CGFloat

    init(inset: CGFloat = -4) {
        self.inset = inset
        super.init()
        setupCancellables()
    }

    deinit {
        destroy()
    }

    let animationOpen: Animation = .timingCurve(0.2, 0, 0, 1, duration: 0.35)
    let animationClose: Animation = .timingCurve(0.4, 0, 0.2, 1, duration: 0.22)
    let animationContent: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.28)
    let animationInsert: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.35)
    let animationRemove: Animation = .timingCurve(0.3, 0, 1, 1, duration: 0.18)
    let animationHover: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.15)
    let animationTrash: Animation = .spring(response: 0.28, dampingFraction: 0.8)
    let animationPop: Animation = .timingCurve(0, 0, 0.2, 1, duration: 0.15)
    let notchOpenedSize: CGSize = .init(width: 600, height: 160)
    let dropDetectorRange: CGFloat = 32

    enum Status: String, Codable, Hashable, Equatable {
        case closed
        case opened
        case popping
    }

    enum OpenReason: String, Codable, Hashable, Equatable {
        case click
        case drag
        case boot
        case unknown
    }

    enum ContentType: Int, Codable, Hashable, Equatable {
        case normal
    }

    var notchOpenedRect: CGRect {
        .init(
            x: screenRect.origin.x + (screenRect.width - notchOpenedSize.width) / 2,
            y: screenRect.origin.y + screenRect.height - notchOpenedSize.height,
            width: notchOpenedSize.width,
            height: notchOpenedSize.height
        )
    }

    @Published private(set) var status: Status = .closed
    @Published var openReason: OpenReason = .unknown
    @Published var contentType: ContentType = .normal

    @Published var spacing: CGFloat = 16
    @Published var cornerRadius: CGFloat = 16
    @Published var deviceNotchRect: CGRect = .zero
    @Published var screenRect: CGRect = .zero
    @Published var optionKeyPressed: Bool = false
    @Published var notchVisible: Bool = true

    @PublishedPersist(key: "hapticFeedback", defaultValue: true)
    var hapticFeedback: Bool

    @PublishedPersist(key: "selectedLanguage", defaultValue: .system)
    var selectedLanguage: Language

    let hapticSender = PassthroughSubject<Void, Never>()
    var closeWorkItem: DispatchWorkItem?
    var dragOpenWorkItem: DispatchWorkItem?

    func notchOpen(_ reason: OpenReason) {
        closeWorkItem?.cancel()
        closeWorkItem = nil
        dragOpenWorkItem?.cancel()
        dragOpenWorkItem = nil
        openReason = reason
        contentType = .normal
        withAnimation(animationOpen) { status = .opened }
        NSApp.activate(ignoringOtherApps: true)
    }

    func notchClose() {
        closeWorkItem?.cancel()
        closeWorkItem = nil
        dragOpenWorkItem?.cancel()
        dragOpenWorkItem = nil
        openReason = .unknown
        withAnimation(animationClose) { status = .closed }
        contentType = .normal
    }

    func notchPop() {
        openReason = .unknown
        withAnimation(animationPop) { status = .popping }
    }
}
