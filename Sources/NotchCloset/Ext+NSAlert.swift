//
//  Ext+NSAlert.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/9.
//

import Cocoa

extension NSAlert {
    /// 確認ダイアログを表示する。
    /// - Parameters:
    ///   - title: タイトル
    ///   - message: 説明文
    ///   - acceptButton: 実行ボタンのラベル（左側）
    ///   - cancelButton: キャンセルボタンのラベル（右側、Returnキーで選択）
    ///   - destructive: acceptButton を破壊的操作としてマークするか
    /// - Returns: acceptButton が押されたら true
    @discardableResult
    static func confirm(
        title: String,
        message: String,
        acceptButton: String,
        cancelButton: String = "Cancel",
        destructive: Bool = true
    ) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: cancelButton)  // 右側（Returnキー）
        alert.addButton(withTitle: acceptButton)  // 左側
        if destructive {
            alert.buttons.last?.hasDestructiveAction = true
        }
        return alert.runModal() == .alertSecondButtonReturn
    }

    static func popError(_ error: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Error", comment: "")
        alert.alertStyle = .critical
        alert.informativeText = error
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.runModal()
    }

    static func popRestart(_ error: String, completion: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Need Restart", comment: "")
        alert.alertStyle = .critical
        alert.informativeText = error
        alert.addButton(withTitle: NSLocalizedString("Exit", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Later", comment: ""))
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completion()
        }
    }

    static func popError(_ error: Error) {
        popError(error.localizedDescription)
    }
}
