import Combine
import SwiftUI

class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @PublishedPersist(key: "PluginEnabledStates", defaultValue: [:])
    var enabledStates: [String: Bool]

    @Published var plugins: [any NotchPlugin] = []

    var enabledPlugins: [any NotchPlugin] {
        plugins.filter { $0.isEnabled }
    }

    private init() {
        registerBuiltInPlugins()
    }

    func register(_ plugin: any NotchPlugin) {
        var mutablePlugin = plugin
        mutablePlugin.isEnabled = enabledStates[plugin.id] ?? true
        plugins.append(mutablePlugin)
    }

    private func registerBuiltInPlugins() {
        register(AirDropPlugin())
        register(OCRPlugin())
        register(ZipPlugin())
    }

    func updateEnabledState(for pluginId: String, enabled: Bool) {
        enabledStates[pluginId] = enabled
        if let index = plugins.firstIndex(where: { $0.id == pluginId }) {
            plugins[index].isEnabled = enabled
        }
    }

    func isEnabled(pluginId: String) -> Bool {
        enabledStates[pluginId] ?? true
    }

    func plugin(for id: String) -> (any NotchPlugin)? {
        plugins.first { $0.id == id }
    }

    func isEnabledBinding(for pluginId: String) -> Binding<Bool> {
        Binding(
            get: { self.enabledStates[pluginId] ?? false },
            set: { self.updateEnabledState(for: pluginId, enabled: $0) }
        )
    }
}
