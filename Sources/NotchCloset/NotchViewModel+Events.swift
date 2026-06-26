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

        events.backspaceKeyDown
            .receive(on: DispatchQueue.main)
            .sink { _ in
                let tvm = TrayDrop.shared
                guard !tvm.selectedIDs.isEmpty else { return }
                tvm.deleteSelected()
            }
            .store(in: &cancellables)

        events.commandBackspaceKeyDown
            .receive(on: DispatchQueue.main)
            .sink { _ in
                let tvm = TrayDrop.shared
                guard !tvm.selectedIDs.isEmpty else { return }
                tvm.trashFiles(ids: tvm.selectedIDs)
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
                    if hoveringNotch {
                        notchPop()
                        hapticSender.send()
                    }
                case .popping:
                    if hoveringNotch {
                        if closeWorkItem == nil {
                            let work = DispatchWorkItem { [weak self] in
                                guard let self else { return }
                                notchOpen(.click)
                            }
                            closeWorkItem = work
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
                        }
                    } else {
                        closeWorkItem?.cancel()
                        closeWorkItem = nil
                        notchClose()
                    }
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
                withAnimation(NotchDesignTokens.openAnimation) { self?.notchVisible = true }
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
                withAnimation(NotchDesignTokens.closeAnimation) {
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
