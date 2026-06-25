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

    let openAnimation: Animation = NotchDesignTokens.openAnimation
    let closeAnimation: Animation = NotchDesignTokens.closeAnimation
    let contentAnimation: Animation = NotchDesignTokens.contentAnimation
    let insertAnimation: Animation = NotchDesignTokens.insertAnimation
    let removeAnimation: Animation = NotchDesignTokens.removeAnimation
    let hoverAnimation: Animation = NotchDesignTokens.hoverAnimation
    let trashAnimation: Animation = NotchDesignTokens.trashAnimation
    let popAnimation: Animation = NotchDesignTokens.popAnimation
    let notchOpenedSize: CGSize = NotchDesignTokens.notchOpenedSize
    let dropDetectorRange: CGFloat = NotchDesignTokens.dropDetectorRange

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
        withAnimation(openAnimation) { status = .opened }
        NSApp.activate(ignoringOtherApps: true)
    }

    func notchClose() {
        closeWorkItem?.cancel()
        closeWorkItem = nil
        dragOpenWorkItem?.cancel()
        dragOpenWorkItem = nil
        openReason = .unknown
        withAnimation(closeAnimation) { status = .closed }
        contentType = .normal
    }

    func notchPop() {
        openReason = .unknown
        withAnimation(popAnimation) { status = .popping }
    }

    func openSettings() {
        (NSApp.delegate as? AppDelegate)?.openSettings()
    }
}
