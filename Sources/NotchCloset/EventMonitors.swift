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

    private var mouseMoveEvent: EventMonitor!
    private var mouseDownEvent: EventMonitor!
    private var mouseDraggingFileEvent: EventMonitor!
    private var optionKeyPressEvent: EventMonitor!
    private var spaceKeyEvent: EventMonitor!

    let mouseLocation: CurrentValueSubject<NSPoint, Never> = .init(.zero)
    let mouseDown: PassthroughSubject<Void, Never> = .init()
    let mouseDraggingFile: PassthroughSubject<Void, Never> = .init()
    let optionKeyPress: CurrentValueSubject<Bool, Never> = .init(false)
    let dragBegan: PassthroughSubject<Void, Never> = .init()
    let spaceKeyDown: PassthroughSubject<Void, Never> = .init()

    private var dragPasteboardBaseline = 0

    private init() {
        mouseMoveEvent = EventMonitor(mask: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            let mouseLocation = NSEvent.mouseLocation
            self.mouseLocation.send(mouseLocation)
        }
        mouseMoveEvent.start()

        mouseDownEvent = EventMonitor(mask: .leftMouseDown) { [weak self] _ in
            guard let self else { return }
            mouseDown.send()
            dragPasteboardBaseline = NSPasteboard(name: .drag).changeCount
        }
        mouseDownEvent.start()

        mouseDraggingFileEvent = EventMonitor(mask: .leftMouseDragged) { [weak self] _ in
            guard let self else { return }
            mouseDraggingFile.send()
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
        }
        mouseDraggingFileEvent.start()

        optionKeyPressEvent = EventMonitor(mask: .flagsChanged) { [weak self] event in
            guard let self else { return }
            if event?.modifierFlags.contains(.option) == true {
                optionKeyPress.send(true)
            } else {
                optionKeyPress.send(false)
            }
        }
        optionKeyPressEvent.start()

        spaceKeyEvent = EventMonitor(mask: .keyDown) { [weak self] event in
            guard let self, let event, event.keyCode == 49 else { return }
            spaceKeyDown.send()
        }
        spaceKeyEvent.start()
    }
}
