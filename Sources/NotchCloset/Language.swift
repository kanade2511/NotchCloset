//
//  Language.swift
//  NotchCloset
//

import Cocoa

enum Language: String, CaseIterable, Identifiable, Codable {
    case system = "Follow System"
    case english = "English"
    case japanese = "Japanese"
    case simplifiedChinese = "Simplified Chinese"
    case traditionalChinese = "Traditional Chinese"

    var id: String { rawValue }

    var localized: String {
        NSLocalizedString(rawValue, comment: "")
    }

    func apply() {
        let code: String?
        switch self {
        case .system:             code = nil
        case .english:            code = "en"
        case .japanese:           code = "ja"
        case .simplifiedChinese:  code = "zh-Hans"
        case .traditionalChinese: code = "zh-Hant"
        }

        let current = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String]
        if current?.first == code { return }

        Bundle.setLanguage(code)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSAlert.popRestart(
                NSLocalizedString("The language has been changed. The app will restart for the changes to take effect.", comment: ""),
                completion: relaunchApp
            )
        }
    }
}

private func relaunchApp() {
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = ["-n", Bundle.main.bundlePath]
    task.launch()
    exit(0)
}

private extension Bundle {
    private static let _init: Void = {
        object_setClass(Bundle.main, PrivateBundle.self)
    }()

    static func setLanguage(_ code: String?) {
        _init
        if let code {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }
}

private class PrivateBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
              let code = languages.first,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}
