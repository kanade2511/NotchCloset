//
//  NotchHeaderView.swift
//  NotchCloset
//

import SwiftUI

struct NotchHeaderView: View {
    @StateObject var vm: NotchViewModel

    var body: some View {
        HStack {
            Spacer()
            Button {
                vm.openSettings()
            } label: {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    NotchHeaderView(vm: .init())
}
