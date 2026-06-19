//
//  NotchHeaderView.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/7.
//

import SwiftUI

struct NotchHeaderView: View {
    @StateObject var vm: NotchViewModel

    var body: some View {
        HStack {
            Text("NotchCloset")
                .font(.system(.headline, design: .rounded))
            Spacer()
        }
    }
}

#Preview {
    NotchHeaderView(vm: .init())
}
