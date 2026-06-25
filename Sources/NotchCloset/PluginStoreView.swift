import SwiftUI

struct PluginStoreView: View {
    @StateObject var pluginManager = PluginManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(pluginManager.plugins), id: \.id) { plugin in
                    pluginCard(for: plugin)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func pluginCard(for plugin: any NotchPlugin) -> some View {
        let isEnabled = pluginManager.isEnabledBinding(for: plugin.id).wrappedValue

        HStack(spacing: 14) {
            // Icon with tinted background
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(plugin.tint.opacity(isEnabled ? 0.2 : 0.08))
                    .frame(width: 44, height: 44)

                Image(systemName: plugin.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isEnabled ? plugin.tint : plugin.tint.opacity(0.4))
            }

            // Name & Description
            VStack(alignment: .leading, spacing: 3) {
                Text(plugin.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(isEnabled ? .primary : .secondary)

                Text(plugin.description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Status indicator + Toggle
            Toggle(isOn: pluginManager.isEnabledBinding(for: plugin.id)) {
                EmptyView()
            }
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}
