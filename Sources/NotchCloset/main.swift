//
//  main.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/7.
//

import AppKit

let productPage = URL(string: "https://github.com/kanade2511/NotchCloset")!
let sponsorPage = URL(string: "https://github.com/kanade2511")!

let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.kanade2511.NotchCloset"
let appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"

let configDirectory = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".config/notchcloset")

let oldDocumentsDirectory: URL = {
    let availableDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return availableDirectories[0].appendingPathComponent("NotchCloset")
}()

var isDirectory: ObjCBool = false
if FileManager.default.fileExists(atPath: oldDocumentsDirectory.path, isDirectory: &isDirectory), isDirectory.boolValue {
    let contents = (try? FileManager.default.contentsOfDirectory(atPath: oldDocumentsDirectory.path)) ?? []
    if contents.isEmpty {
        try? FileManager.default.removeItem(at: oldDocumentsDirectory)
    }
}

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
