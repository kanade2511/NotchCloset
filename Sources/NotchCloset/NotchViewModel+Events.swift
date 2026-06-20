//
//  NotchViewModel+Events.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/8.
//  Modified by @kanade2511
//

import Cocoa
import Combine
import Foundation
import SwiftUI

extension NotchViewModel {
    func setupCancellables() {
        let events = EventMonitors.shared
        events.mouseDown
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                dragOpenWorkItem?.cancel()
                dragOpenWorkItem = nil
                let mouseLocation: NSPoint = NSEvent.mouseLocation
                switch status {
                case .opened:
                    if !notchOpenedRect.contains(mouseLocation) {
                        notchClose()
                    } else if deviceNotchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation) {
                        notchClose()
                    }
                case .closed, .popping:
                    // touch inside, open
                    if deviceNotchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation) {
                        notchOpen(.click)
                    }
                }
            }
            .store(in: &cancellables)

        events.dragBegan
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, status == .closed else { return }
                let mouseY = NSEvent.mouseLocation.y
                guard mouseY > screenRect.maxY - 250 else { return }
                let work = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    notchOpen(.drag)
                }
                dragOpenWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
            }
            .store(in: &cancellables)

        events.spaceKeyDown
            .receive(on: DispatchQueue.main)
            .sink { _ in
                QuickLookHelper.shared.toggle()
            }
            .store(in: &cancellables)

        events.optionKeyPress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] input in
                guard let self else { return }
                optionKeyPressed = input
            }
            .store(in: &cancellables)

        events.mouseLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mouseLocation in
                guard let self else { return }
                let mouseLocation: NSPoint = NSEvent.mouseLocation
                let hoveringNotch = deviceNotchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation)
                switch status {
                case .closed:
                    if hoveringNotch { notchPop() }
                case .popping:
                    if !hoveringNotch { notchClose() }
                case .opened:
                    let keepOpen = notchOpenedRect.contains(mouseLocation) || hoveringNotch
                    if keepOpen {
                        closeWorkItem?.cancel()
                        closeWorkItem = nil
                    } else if closeWorkItem == nil {
                        let work = DispatchWorkItem { [weak self] in
                            guard let self else { return }
                            notchClose()
                        }
                        closeWorkItem = work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
                    }
                }
            }
            .store(in: &cancellables)

        $status
            .filter { $0 != .closed }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation(self?.openAnimation) { self?.notchVisible = true }
            }
            .store(in: &cancellables)

        $status
            .filter { $0 == .popping }
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in
                guard NSEvent.pressedMouseButtons == 0 else { return }
                self?.hapticSender.send()
            }
            .store(in: &cancellables)

        hapticSender
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in
                guard self?.hapticFeedback ?? false else { return }
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .levelChange,
                    performanceTime: .now
                )
            }
            .store(in: &cancellables)

        $status
            .debounce(for: 0.35, scheduler: DispatchQueue.global())
            .filter { $0 == .closed }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation(self?.closeAnimation) {
                    self?.notchVisible = false
                }
            }
            .store(in: &cancellables)

    }

    func destroy() {
        closeWorkItem?.cancel()
        closeWorkItem = nil
        dragOpenWorkItem?.cancel()
        dragOpenWorkItem = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
