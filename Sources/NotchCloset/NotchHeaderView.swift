//
//  NotchHeaderView.swift
//  NotchCloset
//

import SwiftUI

struct NotchHeaderView: View {
    @StateObject var vm: NotchViewModel

    var body: some View {
        HStack {
            Text("NotchCloset")
                .font(.system(.headline, design: .rounded))
            Spacer()
            Button {
                (NSApp.delegate as? AppDelegate)?.openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    NotchHeaderView(vm: .init())
}
