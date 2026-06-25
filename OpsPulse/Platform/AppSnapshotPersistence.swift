import Foundation

actor AppSnapshotPersistence {
    private let store: FileSnapshotStore

    init(store: FileSnapshotStore) {
        self.store = store
    }

    static func defaultStore() -> AppSnapshotPersistence {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("OpsPulse", isDirectory: true)
        return AppSnapshotPersistence(store: FileSnapshotStore(fileURL: folder.appendingPathComponent("demo-snapshot.json")))
    }

    func load() async -> OpsPulseSnapshot? {
        try? await store.load()
    }

    func save(_ snapshot: OpsPulseSnapshot) async {
        try? await store.save(snapshot)
    }
}
