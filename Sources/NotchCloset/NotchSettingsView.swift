//
//  NotchSettingsView.swift
//  NotchCloset
//

import SwiftUI

struct NotchSettingsView: View {
    @StateObject var vm: NotchViewModel
    @State private var selectedLanguage: Language = .system

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Language")
                    .frame(width: 80, alignment: .leading)
                Picker("", selection: $selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.localized).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
                .onChange(of: selectedLanguage) { _, lang in
                    vm.selectedLanguage = lang
                    lang.apply()
                }
            }

            Toggle("Haptic Feedback", isOn: $vm.hapticFeedback)
        }
        .padding()
        .font(.system(.body, design: .rounded))
        .onAppear {
            selectedLanguage = vm.selectedLanguage
        }
    }
}
