import Foundation
import SwiftData

@Model
final class Review {
    enum ValidationError: LocalizedError, Equatable {
        case titleLength
        case ratingOutOfRange
        case placeDescriptionLength
        case experienceLength
        case emptyUserName

        var errorDescription: String? {
            switch self {
            case .titleLength:
                return "Il titolo deve contenere tra 3 e 80 caratteri."
            case .ratingOutOfRange:
                return "La valutazione deve essere compresa tra 1 e 5 stelle."
            case .placeDescriptionLength:
                return "La descrizione del locale deve contenere tra 10 e 500 caratteri."
            case .experienceLength:
                return "L'esperienza deve contenere tra 10 e 1000 caratteri."
            case .emptyUserName:
                return "Il nome utente non può essere vuoto."
            }
        }
    }

    @Attribute(.unique) var id: UUID
    var title: String
    var rating: Int
    var placeDescription: String
    var experience: String
    var userName: String
    var reviewDate: Date
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        rating: Int,
        placeDescription: String,
        experience: String,
        userName: String,
        reviewDate: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) throws {
        let sanitized = try Review.sanitizedValues(
            id: id,
            title: title,
            rating: rating,
            placeDescription: placeDescription,
            experience: experience,
            userName: userName,
            reviewDate: reviewDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        self.id = sanitized.id
        self.title = sanitized.title
        self.rating = sanitized.rating
        self.placeDescription = sanitized.placeDescription
        self.experience = sanitized.experience
        self.userName = sanitized.userName
        self.reviewDate = sanitized.reviewDate
        self.createdAt = sanitized.createdAt
        self.updatedAt = sanitized.updatedAt
    }

    func update(
        title: String,
        rating: Int,
        placeDescription: String,
        experience: String,
        userName: String,
        reviewDate: Date = .now
    ) throws {
        let sanitized = try Review.sanitizedValues(
            id: id,
            title: title,
            rating: rating,
            placeDescription: placeDescription,
            experience: experience,
            userName: userName,
            reviewDate: reviewDate,
            createdAt: createdAt,
            updatedAt: .now
        )

        self.title = sanitized.title
        self.rating = sanitized.rating
        self.placeDescription = sanitized.placeDescription
        self.experience = sanitized.experience
        self.userName = sanitized.userName
        self.reviewDate = sanitized.reviewDate
        self.updatedAt = sanitized.updatedAt
    }
}

private extension Review {
    struct SanitizedValues {
        let id: UUID
        let title: String
        let rating: Int
        let placeDescription: String
        let experience: String
        let userName: String
        let reviewDate: Date
        let createdAt: Date
        let updatedAt: Date
    }

    static func sanitizedValues(
        id: UUID,
        title: String,
        rating: Int,
        placeDescription: String,
        experience: String,
        userName: String,
        reviewDate: Date,
        createdAt: Date,
        updatedAt: Date
    ) throws -> SanitizedValues {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPlaceDescription = placeDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExperience = experience.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard (3...80).contains(trimmedTitle.count) else {
            throw ValidationError.titleLength
        }

        guard (1...5).contains(rating) else {
            throw ValidationError.ratingOutOfRange
        }

        guard (10...500).contains(trimmedPlaceDescription.count) else {
            throw ValidationError.placeDescriptionLength
        }

        guard (10...1000).contains(trimmedExperience.count) else {
            throw ValidationError.experienceLength
        }

        guard !trimmedUserName.isEmpty else {
            throw ValidationError.emptyUserName
        }

        return SanitizedValues(
            id: id,
            title: trimmedTitle,
            rating: rating,
            placeDescription: trimmedPlaceDescription,
            experience: trimmedExperience,
            userName: trimmedUserName,
            reviewDate: reviewDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
