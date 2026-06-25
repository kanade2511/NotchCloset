import SwiftUI

// TODO: 赤系tint（.red）は暖色の前進錯視により青系より約5〜10%大きく知覚される。
// コード上のサイズは同一だが、視覚的な統一には赤系のmaxWidthを少し下げる補正が必要か。
// 例: tint == .red のとき maxWidth: 60、それ以外は 64 など。

struct ActionTile: View {
    let icon: String
    let label: String
    let tint: Color
    var isHovered: Bool = false

    private var fillOpacity: CGFloat { isHovered ? 0.3 : 0.06 }
    private var foregroundOpacity: CGFloat { isHovered ? 1 : 0.35 }

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(tint.opacity(fillOpacity))
                .overlay {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(foregroundOpacity))
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 64)

            Text(label)
                .multilineTextAlignment(.center)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.white.opacity(foregroundOpacity))
                .frame(maxWidth: 64)
        }
        .contentShape(Rectangle())
    }
}
