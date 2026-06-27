//
//  EventMonitors.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/7.
//

import Cocoa
import Combine

class EventMonitors {
    static let shared = EventMonitors()

    private var globalMonitors: [Any] = []
    private var localMonitors: [Any] = []

    let mouseLocation: CurrentValueSubject<NSPoint, Never> = .init(.zero)
    let mouseDown: PassthroughSubject<Void, Never> = .init()
    let optionKeyPress: CurrentValueSubject<Bool, Never> = .init(false)
    let dragBegan: PassthroughSubject<Void, Never> = .init()
    let spaceKeyDown: PassthroughSubject<Void, Never> = .init()
    let backspaceKeyDown: PassthroughSubject<Void, Never> = .init()
    let commandBackspaceKeyDown: PassthroughSubject<Void, Never> = .init()

    private var dragPasteboardBaseline = 0

    private init() {
        // mouseMove
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            let mouseLocation = NSEvent.mouseLocation
            self.mouseLocation.send(mouseLocation)
        } {
            globalMonitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self else { return event }
            let mouseLocation = NSEvent.mouseLocation
            self.mouseLocation.send(mouseLocation)
            return event
        } {
            localMonitors.append(monitor)
        }

        // mouseDown
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            guard let self else { return }
            mouseDown.send()
            dragPasteboardBaseline = NSPasteboard(name: .drag).changeCount
        } {
            globalMonitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self else { return event }
            mouseDown.send()
            dragPasteboardBaseline = NSPasteboard(name: .drag).changeCount
            return event
        } {
            localMonitors.append(monitor)
        }

        // mouseDraggingFile
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            guard let self else { return }
            if NSPasteboard(name: .drag).changeCount != dragPasteboardBaseline {
                dragPasteboardBaseline = NSPasteboard(name: .drag).changeCount
                let types = NSPasteboard(name: .drag).types ?? []
                let hasTarget = types.contains { t in
                    t.rawValue.hasPrefix("public.file-url") ||
                    t.rawValue.hasPrefix("public.url") ||
                    t.rawValue.hasPrefix("public.utf") ||
                    t.rawValue.hasPrefix("public.plain-text") ||
                    t.rawValue.hasPrefix("public.rtf") ||
                    t == .fileURL
                }
                if hasTarget {
                    dragBegan.send()
                }
            }
        } {
            globalMonitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            guard let self else { return event }
            if NSPasteboard(name: .drag).changeCount != dragPasteboardBaseline {
                dragPasteboardBaseline = NSPasteboard(name: .drag).changeCount
                let types = NSPasteboard(name: .drag).types ?? []
                let hasTarget = types.contains { t in
                    t.rawValue.hasPrefix("public.file-url") ||
                    t.rawValue.hasPrefix("public.url") ||
                    t.rawValue.hasPrefix("public.utf") ||
                    t.rawValue.hasPrefix("public.plain-text") ||
                    t.rawValue.hasPrefix("public.rtf") ||
                    t == .fileURL
                }
                if hasTarget {
                    dragBegan.send()
                }
            }
            return event
        } {
            localMonitors.append(monitor)
        }

        // optionKeyPress
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return }
            if event.modifierFlags.contains(.option) {
                optionKeyPress.send(true)
            } else {
                optionKeyPress.send(false)
            }
        } {
            globalMonitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self else { return event }
            if event.modifierFlags.contains(.option) {
                optionKeyPress.send(true)
            } else {
                optionKeyPress.send(false)
            }
            return event
        } {
            localMonitors.append(monitor)
        }

        // spaceKey
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.keyCode == 49 else { return }
            spaceKeyDown.send()
        } {
            globalMonitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.keyCode == 49 else { return event }
            spaceKeyDown.send()
            return event
        } {
            localMonitors.append(monitor)
        }

        // backspaceKey
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  event.keyCode == 51,
                  !event.modifierFlags.contains(.command)
            else { return }
            backspaceKeyDown.send()
        } {
            globalMonitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  event.keyCode == 51,
                  !event.modifierFlags.contains(.command)
            else { return event }
            backspaceKeyDown.send()
            return event
        } {
            localMonitors.append(monitor)
        }

        // commandBackspaceKey
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  event.keyCode == 51,
                  event.modifierFlags.contains(.command)
            else { return }
            commandBackspaceKeyDown.send()
        } {
            globalMonitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  event.keyCode == 51,
                  event.modifierFlags.contains(.command)
            else { return event }
            commandBackspaceKeyDown.send()
            return event
        } {
            localMonitors.append(monitor)
        }
    }
}
