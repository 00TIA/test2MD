import SwiftUI
import SwiftData

@main
struct InfantinoApp: App {
    private let container: ModelContainer
    private let repository: ReviewRepository

    init() {
        do {
            container = try SwiftDataStack.makeContainer()
        } catch {
            fatalError("Impossibile inizializzare SwiftDataStack: \(error.localizedDescription)")
        }

        repository = ReviewRepository(modelContext: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView(viewModel: HomeViewModel(repository: repository))
            }
            .modelContainer(container)
            .environment(\.reviewRepository, repository)
        }
    }
}
