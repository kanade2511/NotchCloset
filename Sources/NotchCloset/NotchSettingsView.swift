//
//  NotchSettingsView.swift
//  NotchCloset
//

import SwiftUI
import AppKit

struct NotchSettingsView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject var tvm = TrayDrop.shared

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            PluginStoreView()
                .tabItem {
                    Label("Plugins", systemImage: "puzzlepiece.extension")
                }

            if PluginManager.shared.isEnabled(pluginId: "ocr") {
                OCRSettingsView()
                    .tabItem {
                        Label("OCR", systemImage: "text.viewfinder")
                    }
            }

            aboutView
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .tabViewStyle(.automatic)
        .frame(width: 380, height: 350)
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
                Text("MIT — based on NotchDrop by Lakr Aream")
                    .foregroundStyle(.secondary)

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
