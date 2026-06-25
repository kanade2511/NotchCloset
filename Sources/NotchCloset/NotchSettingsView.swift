//
//  NotchSettingsView.swift
//  NotchCloset
//

import SwiftUI

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
            }
            .padding()
        }
        .font(.system(.body, design: .rounded))
    }
}
