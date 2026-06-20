//
//  NotchContentView.swift
//  NotchCloset
//

import SwiftUI

struct NotchContentView: View {
    @StateObject var vm: NotchViewModel

    var body: some View {
        TrayView(vm: vm)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 600, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
