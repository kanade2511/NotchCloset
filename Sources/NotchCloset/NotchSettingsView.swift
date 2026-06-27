//
//  NotchSettingsView.swift
//  NotchCloset
//

import SwiftUI
import AppKit

struct NotchSettingsView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject var tvm = TrayDrop.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var showingLicense = false

    enum SettingsTab: String, CaseIterable {
        case general
        case plugins
        case ocr
        case about

        var icon: String {
            switch self {
            case .general: "gearshape"
            case .plugins: "puzzlepiece.extension"
            case .ocr: "text.viewfinder"
            case .about: "info.circle"
            }
        }

        var label: String {
            switch self {
            case .general: NSLocalizedString("General", comment: "")
            case .plugins: NSLocalizedString("Plugins", comment: "")
            case .ocr: NSLocalizedString("OCR", comment: "")
            case .about: NSLocalizedString("About", comment: "")
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 560, height: 380)
    }

    private var sidebar: some View {
        List(selection: $selectedTab) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                if tab != .ocr || PluginManager.shared.isEnabled(pluginId: "ocr") {
                    Label(tab.label, systemImage: tab.icon)
                        .tag(tab)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(width: 170)
        .scrollIndicators(.never)
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .general:
            generalSettings
        case .plugins:
            PluginStoreView()
        case .ocr:
            OCRSettingsView()
        case .about:
            aboutView
        }
    }

    private var generalSettings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Haptic Feedback", isOn: $vm.hapticFeedback)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Keep Files")
                        .font(.system(.headline, design: .rounded))

                    Picker("", selection: $tvm.selectedFileStorageTime) {
                        ForEach(TrayDrop.FileStorageTime.allCases) { time in
                            Text(time.localized).tag(time)
                        }
                    }
                    .pickerStyle(.menu)

                    if tvm.selectedFileStorageTime == .custom {
                        HStack(spacing: 8) {
                            TextField("", value: $tvm.customStorageTime, format: .number)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                            Picker("", selection: $tvm.customStorageTimeUnit) {
                                ForEach(TrayDrop.CustomStorageTimeUnit.allCases) { unit in
                                    Text(unit.localized).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                        }
                        .padding(.leading, 16)
                    }
                }

                Divider()

                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        guard NSAlert.confirm(
                            title: NSLocalizedString("Quit NotchCloset?", comment: ""),
                            message: NSLocalizedString("Any items in the tray will be preserved.", comment: ""),
                            acceptButton: NSLocalizedString("Quit", comment: "")
                        ) else { return }
                        NSApp.terminate(nil)
                    } label: {
                        Label("Quit NotchCloset", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .controlSize(.small)
                    Spacer()
                }
            }
            .padding()
        }
        .font(.system(.body, design: .rounded))
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private var aboutView: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            Text("NotchCloset")
                .font(.system(.title2, design: .rounded, weight: .bold))

            Text("Version \(appVersion)")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("Author", systemImage: "person")
                    .font(.system(.headline, design: .rounded))
                Text("@kanade2511")
                    .foregroundStyle(.secondary)

                Label("License", systemImage: "doc.text")
                    .font(.system(.headline, design: .rounded))
                Button("MIT License — View") {
                    showingLicense = true
                }
                .buttonStyle(.link)
                .sheet(isPresented: $showingLicense) {
                    LicenseView()
                }

                Label("Repository", systemImage: "link")
                    .font(.system(.headline, design: .rounded))
                Button("github.com/kanade2511/NotchCloset") {
                    guard let url = URL(string: "https://github.com/kanade2511/NotchCloset") else { return }
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.link)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LicenseView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("License")
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
            Divider()
            ScrollView {
                Text("""
MIT License

Copyright (c) 2025 @kanade2511
Based on NotchDrop (c) 2024 Lakr Aream

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
""")
                .font(.system(.caption, design: .monospaced))
                .padding()
                .textSelection(.enabled)
            }
        }
        .frame(width: 450, height: 350)
    }
}
