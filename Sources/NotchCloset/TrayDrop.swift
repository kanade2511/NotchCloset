import Cocoa
import Combine
import Foundation
import OrderedCollections

class TrayDrop: ObservableObject {
    static let shared = TrayDrop()

    var cancellables = Set<AnyCancellable>()

    @Persist(key: "keepInterval", defaultValue: 3600 * 24)
    var keepInterval: TimeInterval

    private init() {
        Publishers.CombineLatest3(
            $selectedFileStorageTime.removeDuplicates(),
            $customStorageTime.removeDuplicates(),
            $customStorageTimeUnit.removeDuplicates()
        )
        .map { selectedFileStorageTime, customStorageTime, customStorageTimeUnit in
            let customTime = switch customStorageTimeUnit {
            case .hours:
                TimeInterval(customStorageTime) * 60 * 60
            case .days:
                TimeInterval(customStorageTime) * 60 * 60 * 24
            case .weeks:
                TimeInterval(customStorageTime) * 60 * 60 * 24 * 7
            case .months:
                TimeInterval(customStorageTime) * 60 * 60 * 24 * 30
            case .years:
                TimeInterval(customStorageTime) * 60 * 60 * 24 * 365
            }
            let ans = selectedFileStorageTime.toTimeInterval(customTime: customTime)
            print("[*] using interval \(ans) to keep files")
            return ans
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] output in
            self?.keepInterval = output
        }
        .store(in: &cancellables)
    }

    var isEmpty: Bool { items.isEmpty }

    @PublishedPersist(key: "TrayDropItems", defaultValue: .init())
    var items: OrderedSet<DropItem>

    @PublishedPersist(key: "selectedFileStorageTime", defaultValue: .oneDay)
    var selectedFileStorageTime: FileStorageTime

    @PublishedPersist(key: "customStorageTime", defaultValue: 1)
    var customStorageTime: Int

    @PublishedPersist(key: "customStorageTimeUnit", defaultValue: .days)
    var customStorageTimeUnit: CustomstorageTimeUnit

    @Published var isLoading: Int = 0

    func load(_ providers: [NSItemProvider]) {
        assert(!Thread.isMainThread)
        DispatchQueue.main.asyncAndWait { isLoading += 1 }
        guard let urls = providers.interfaceConvert() else {
            DispatchQueue.main.asyncAndWait { isLoading -= 1 }
            return
        }
        do {
            let items = try urls.map { try DropItem(url: $0) }
            DispatchQueue.main.async {
                for item in items {
                    let newPath = item.sourceURL.resolvingSymlinksInPath().absoluteString
                    if self.items.contains(where: { $0.sourceURL.resolvingSymlinksInPath().absoluteString == newPath }) {
                        continue
                    }
                    self.items.updateOrInsert(item, at: 0)
                    if item.isWebURL {
                        self.fetchWebPreview(for: item.id, url: item.sourceURL)
                    }
                }
                self.isLoading -= 1
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading -= 1
                NSAlert.popError(error)
            }
        }
    }

    private func fetchWebPreview(for itemId: DropItem.ID, url: URL) {
        guard let host = url.host else { return }
        let faviconURL = URL(string: "https://www.google.com/s2/favicons?sz=64&domain_url=\(host)")

        DispatchQueue.global().async {
            if let favURL = faviconURL,
               let data = try? Data(contentsOf: favURL),
               NSImage(data: data) != nil {
                DispatchQueue.main.async {
                    self.updateItem(id: itemId, iconData: data)
                }
            }

            if let html = try? String(contentsOf: url, encoding: .utf8),
               let titleStart = html.range(of: "<title>"),
               let titleEnd = html.range(of: "</title>", range: titleStart.upperBound..<html.endIndex) {
                let title = String(html[titleStart.upperBound..<titleEnd.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                    DispatchQueue.main.async {
                        self.updateItem(id: itemId, fileName: title)
                    }
                }
            }
        }
    }

    private func updateItem(id: DropItem.ID, fileName: String? = nil, iconData: Data? = nil) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        var item = items.remove(at: idx)
        if let fileName { item.fileName = fileName }
        if let iconData { item.workspacePreviewImageData = iconData }
        items.insert(item, at: idx)
    }

    func cleanExpiredFiles() {
        var inEdit = items
        let shouldCleanItems = items.filter(\.shouldClean)
        for item in shouldCleanItems {
            inEdit.remove(item)
        }
        items = inEdit
    }

    func delete(_ item: DropItem.ID) {
        guard let item = items.first(where: { $0.id == item }) else { return }
        delete(item: item)
    }

    private func delete(item: DropItem) {
        var inEdit = items
        inEdit.remove(item)
        items = inEdit
    }

    func removeAll() {
        items.forEach { delete(item: $0) }
    }
}

extension TrayDrop {
    enum FileStorageTime: String, CaseIterable, Identifiable, Codable {
        case oneHour = "1 Hour"
        case oneDay = "1 Day"
        case twoDays = "2 Days"
        case threeDays = "3 Days"
        case oneWeek = "1 Week"
        case never = "Forever"
        case custom = "Custom"

        var id: String { rawValue }

        var localized: String {
            NSLocalizedString(rawValue, comment: "")
        }

        func toTimeInterval(customTime: TimeInterval) -> TimeInterval {
            switch self {
            case .oneHour:
                60 * 60
            case .oneDay:
                60 * 60 * 24
            case .twoDays:
                60 * 60 * 24 * 2
            case .threeDays:
                60 * 60 * 24 * 3
            case .oneWeek:
                60 * 60 * 24 * 7
            case .never:
                TimeInterval.infinity
            case .custom:
                customTime
            }
        }
    }

    enum CustomstorageTimeUnit: String, CaseIterable, Identifiable, Codable {
        case hours = "Hours"
        case days = "Days"
        case weeks = "Weeks"
        case months = "Months"
        case years = "Years"

        var id: String { rawValue }

        var localized: String {
            NSLocalizedString(rawValue, comment: "")
        }
    }
}
