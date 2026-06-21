import SwiftUI

struct PluginStoreView: View {
    @StateObject var pluginManager = PluginManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(pluginManager.plugins), id: \.id) { plugin in
                HStack {
                    Image(systemName: plugin.icon)
                        .font(.title3)
                        .foregroundStyle(plugin.tint)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(plugin.name)
                            .font(.system(.body, design: .rounded))
                        Text(plugin.description)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: pluginManager.isEnabledBinding(for: plugin.id))
                        .toggleStyle(.switch)
                }
            }
        }
    }
}
