import SwiftUI

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
