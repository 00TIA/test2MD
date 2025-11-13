import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ReviewRepository {
    private let context: ModelContext

    init(modelContext: ModelContext) {
        context = modelContext
    }

    @discardableResult
    func createReview(
        title: String,
        rating: Int,
        placeDescription: String,
        experience: String,
        userName: String,
        reviewDate: Date = .now
    ) throws -> Review {
        let review = try Review(
            title: title,
            rating: rating,
            placeDescription: placeDescription,
            experience: experience,
            userName: userName,
            reviewDate: reviewDate
        )

        context.insert(review)
        try context.save()
        return review
    }

    func fetchReviews(sortedBy sortDescriptors: [SortDescriptor<Review>] = [
        SortDescriptor(\Review.reviewDate, order: .reverse)
    ]) throws -> [Review] {
        var descriptor = FetchDescriptor<Review>(sortBy: sortDescriptors)
        descriptor.fetchLimit = nil
        return try context.fetch(descriptor)
    }

    func review(withID id: UUID) throws -> Review? {
        var descriptor = FetchDescriptor<Review>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func delete(_ review: Review) throws {
        context.delete(review)
        try context.save()
    }

    func savePendingChanges() throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}

private struct ReviewRepositoryKey: EnvironmentKey {
    static var defaultValue: ReviewRepository {
        fatalError("ReviewRepository non configurato. Iniettare una istanza nell'ambiente dell'app.")
    }
}

public extension EnvironmentValues {
    var reviewRepository: ReviewRepository {
        get { self[ReviewRepositoryKey.self] }
        set { self[ReviewRepositoryKey.self] = newValue }
    }
}

extension ReviewRepository {
    static func previewRepository() -> ReviewRepository {
        let container = SwiftDataStack.makeInMemoryContainer()
        let repository = ReviewRepository(modelContext: container.mainContext)
        return repository
    }
}
