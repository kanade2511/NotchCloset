import AppKit
import SwiftUI

struct OCRSettingsView: View {
    @ObservedObject var ocrPlugin: OCRPlugin = {
        PluginManager.shared.plugin(for: "ocr") as! OCRPlugin
    }()

    /// Available recognition languages with their display labels.
    private let availableLanguages: [(id: String, label: String)] = [
        ("ja-JP", "Japanese"),
        ("en-US", "English"),
        ("zh-Hans", "Chinese (Simplified)"),
        ("zh-Hant", "Chinese (Traditional)"),
        ("ko-KR", "Korean"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recognition Level
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recognition Level")
                        .font(.system(.headline, design: .rounded))

                    Text("Choose between maximum accuracy or faster processing speed.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)

                    Picker("", selection: $ocrPlugin.recognitionLevel) {
                        Text("Accurate").tag(0)
                        Text("Fast").tag(1)
                    }
                    .pickerStyle(.radioGroup)
                }

                Divider()

                // Recognition Languages
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recognition Languages")
                        .font(.system(.headline, design: .rounded))

                    Text("Select the languages OCR should detect. Enabling multiple languages may increase processing time.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        ForEach(availableLanguages, id: \.id) { lang in
                            HStack {
                                Text(lang.label)
                                    .font(.system(.body, design: .rounded))
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { ocrPlugin.recognitionLanguages.contains(lang.id) },
                                    set: { enabled in
                                        if enabled {
                                            if !ocrPlugin.recognitionLanguages.contains(lang.id) {
                                                ocrPlugin.recognitionLanguages.append(lang.id)
                                            }
                                        } else {
                                            ocrPlugin.recognitionLanguages.removeAll { $0 == lang.id }
                                        }
                                    }
                                ))
                                .toggleStyle(.switch)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.primary.opacity(0.04))
                            )
                        }
                    }
                }

                Divider()

                // Output Settings section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Output Settings")
                        .font(.system(.headline, design: .rounded))

                    // Output directory
                    Toggle(isOn: $ocrPlugin.outputToSourceDir) {
                        Text("Save next to source file")
                    }

                    if !ocrPlugin.outputToSourceDir {
                        HStack(spacing: 8) {
                            TextField("Custom directory", text: $ocrPlugin.customOutputDir)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse…") {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = false
                                panel.canChooseDirectories = true
                                panel.canCreateDirectories = true
                                panel.begin { response in
                                    if response == .OK, let url = panel.url {
                                        ocrPlugin.customOutputDir = url.path
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // Filename template for images
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image filename template")
                            .font(.system(.subheadline, design: .rounded))
                        TextField("", text: $ocrPlugin.imageNameTemplate)
                            .textFieldStyle(.roundedBorder)
                        Text("Use {name} for base name, {ext} for original extension")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                        // Preview
                        let previewName = ocrPlugin.imageNameTemplate
                            .replacingOccurrences(of: "{name}", with: "photo")
                            .replacingOccurrences(of: "{ext}", with: "png")
                        Text("Example: photo.png → \(previewName)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    // Filename template for PDFs
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PDF filename template")
                            .font(.system(.subheadline, design: .rounded))
                        TextField("", text: $ocrPlugin.pdfNameTemplate)
                            .textFieldStyle(.roundedBorder)
                        Text("Use {name} for base name, {ext} for original extension")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                        // Preview
                        let previewName = ocrPlugin.pdfNameTemplate
                            .replacingOccurrences(of: "{name}", with: "document")
                            .replacingOccurrences(of: "{ext}", with: "pdf")
                        Text("Example: document.pdf → \(previewName)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .font(.system(.body, design: .rounded))
    }
}
