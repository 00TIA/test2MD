import Foundation
import SwiftData

enum SwiftDataStack {
    private static let storeName = "InfantinoStore"

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([Review.self])
        let configuration = ModelConfiguration(storeName)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    static func makeInMemoryContainer() -> ModelContainer {
        let schema = Schema([Review.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Impossibile creare il container in-memory: \(error.localizedDescription)")
        }
    }
}
