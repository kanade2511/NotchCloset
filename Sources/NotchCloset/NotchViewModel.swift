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

    var notchOpenedRect: CGRect {
        .init(
            x: screenRect.origin.x + (screenRect.width - NotchDesignTokens.notchOpenedSize.width) / 2,
            y: screenRect.origin.y + screenRect.height - NotchDesignTokens.notchOpenedSize.height,
            width: NotchDesignTokens.notchOpenedSize.width,
            height: NotchDesignTokens.notchOpenedSize.height
        )
    }

    @Published private(set) var status: Status = .closed
    @Published var openReason: OpenReason = .unknown

    @Published var deviceNotchRect: CGRect = .zero
    @Published var screenRect: CGRect = .zero
    @Published var notchVisible: Bool = true

    @PublishedPersist(key: "hapticFeedback", defaultValue: true)
    var hapticFeedback: Bool

    let hapticSender = PassthroughSubject<Void, Never>()
    var closeWorkItem: DispatchWorkItem?
    var dragOpenWorkItem: DispatchWorkItem?

    func notchOpen(_ reason: OpenReason) {
        closeWorkItem?.cancel()
        closeWorkItem = nil
        dragOpenWorkItem?.cancel()
        dragOpenWorkItem = nil
        openReason = reason
        withAnimation(NotchDesignTokens.openAnimation) { status = .opened }
        NSApp.activate(ignoringOtherApps: true)
    }

    func notchClose() {
        closeWorkItem?.cancel()
        closeWorkItem = nil
        dragOpenWorkItem?.cancel()
        dragOpenWorkItem = nil
        openReason = .unknown
        withAnimation(NotchDesignTokens.closeAnimation) { status = .closed }
    }

    func notchPop() {
        openReason = .unknown
        withAnimation(NotchDesignTokens.popAnimation) { status = .popping }
    }

    func openSettings() {
        (NSApp.delegate as? AppDelegate)?.openSettings()
    }
}
