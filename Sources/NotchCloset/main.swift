//
//  main.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/7.
//

import AppKit

let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.kanade2511.NotchCloset"

let configDirectory = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".config/notchcloset")

let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(bundleIdentifier)
try? FileManager.default.removeItem(at: temporaryDirectory)
try? FileManager.default.createDirectory(
    at: configDirectory,
    withIntermediateDirectories: true,
    attributes: nil
)
try? FileManager.default.createDirectory(
    at: temporaryDirectory,
    withIntermediateDirectories: true,
    attributes: nil
)

let pidFile = temporaryDirectory.appendingPathComponent("ProcessIdentifier")

do {
    let prevIdentifier = try String(contentsOf: pidFile, encoding: .utf8)
    if let prev = Int(prevIdentifier) {
        if let app = NSRunningApplication(processIdentifier: pid_t(prev)) {
            app.terminate()
        }
    }
} catch {}
try? FileManager.default.removeItem(at: pidFile)

do {
    let pid = String(NSRunningApplication.current.processIdentifier)
    try pid.write(to: pidFile, atomically: true, encoding: .utf8)
} catch {
    NSAlert.popError(error)
    exit(1)
}

_ = TrayDrop.shared
TrayDrop.shared.cleanExpiredFiles()

private let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
