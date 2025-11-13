import Foundation
import SwiftUI

@MainActor
final class ReviewEditorViewModel: ObservableObject {
    enum Field: Hashable, CaseIterable {
        case rating
        case title
        case placeDescription
        case experience
    }

    enum SubmitState: Equatable {
        case idle
        case loading
        case success(message: String)
        case failure(message: String)
    }

    enum SubmitOutcome: Equatable {
        case success
        case validationFailed(field: Field)
        case failure
    }

    private let reviewRepository: ReviewRepository
    private let userNameProvider: () -> String
    private let onReviewSaved: () -> Void

    @Published private(set) var rating: Int = 0
    @Published private(set) var title: String = ""
    @Published private(set) var placeDescription: String = ""
    @Published private(set) var experience: String = ""
    @Published private(set) var fieldErrors: [Field: String] = [:]
    @Published private(set) var submitState: SubmitState = .idle
    @Published private(set) var truncatedField: Field?
    @Published private(set) var lastErrorMessage: String?

    init(
        reviewRepository: ReviewRepository,
        userNameProvider: @escaping () -> String = { String(localized: "review.default_user_name") },
        onReviewSaved: @escaping () -> Void = {}
    ) {
        self.reviewRepository = reviewRepository
        self.userNameProvider = userNameProvider
        self.onReviewSaved = onReviewSaved
    }

    var isSubmitButtonDisabled: Bool {
        if case .loading = submitState { return true }
        return Field.allCases.contains(where: { !isFieldValid($0) })
    }

    func binding(for field: Field) -> Binding<String> {
        Binding(
            get: { self.textValue(for: field) },
            set: { newValue in
                self.setText(newValue, for: field)
            }
        )
    }

    func setText(_ value: String, for field: Field) {
        let limited = limitedText(for: field, value: value)
        applyText(limited, to: field)

        if limited.count != value.count {
            truncatedField = field
        }

        if case .failure = submitState {
            submitState = .idle
        }
    }

    func clearTruncatedField() {
        truncatedField = nil
    }

    func setRating(_ value: Int) {
        let clamped = max(0, min(5, value))
        if clamped != rating {
            rating = clamped
            _ = validate(field: .rating)
        }

        if case .failure = submitState {
            submitState = .idle
        }
    }

    func error(for field: Field) -> String? {
        fieldErrors[field]
    }

    @discardableResult
    func validate(field: Field) -> Bool {
        let message: String?
        switch field {
        case .rating:
            message = (1...5).contains(rating) ? nil : String(localized: "error.rating.required")
        case .title:
            let trimmed = sanitizedText(title)
            message = trimmed.count >= 3 ? nil : String(localized: "error.title.too_short")
        case .placeDescription:
            let trimmed = sanitizedText(placeDescription)
            message = trimmed.count >= 10 ? nil : String(localized: "error.place.too_short")
        case .experience:
            let trimmed = sanitizedText(experience)
            message = trimmed.count >= 10 ? nil : String(localized: "error.experience.too_short")
        }

        fieldErrors[field] = message
        return message == nil
    }

    func resetSubmitState() {
        if case .success = submitState {
            submitState = .idle
        }
    }

    func clearFailureState() {
        if case .failure = submitState {
            submitState = .idle
            lastErrorMessage = nil
        }
    }

    func submit() async -> SubmitOutcome {
        if case .loading = submitState { return .failure }

        if let invalidField = firstInvalidField() {
            return .validationFailed(field: invalidField)
        }

        submitState = .loading

        do {
            let sanitizedTitle = sanitizedText(title)
            let sanitizedPlace = sanitizedText(placeDescription)
            let sanitizedExperience = sanitizedText(experience)
            let userName = sanitizedText(userNameProvider())

            _ = try reviewRepository.createReview(
                title: sanitizedTitle,
                rating: rating,
                placeDescription: sanitizedPlace,
                experience: sanitizedExperience,
                userName: userName
            )

            onReviewSaved()
            resetForm()
            fieldErrors = [:]
            lastErrorMessage = nil
            submitState = .success(message: String(localized: "review.saved"))
            return .success
        } catch {
            let message = String(localized: "review.save_error")
            lastErrorMessage = message
            submitState = .failure(message: message)
            return .failure
        }
    }
}

private extension ReviewEditorViewModel {
    func textValue(for field: Field) -> String {
        switch field {
        case .rating:
            return ""
        case .title:
            return title
        case .placeDescription:
            return placeDescription
        case .experience:
            return experience
        }
    }

    func limitedText(for field: Field, value: String) -> String {
        let limit: Int
        switch field {
        case .rating:
            return value
        case .title:
            limit = 80
        case .placeDescription:
            limit = 500
        case .experience:
            limit = 1000
        }

        if value.count <= limit {
            return value
        }

        let endIndex = value.index(value.startIndex, offsetBy: limit)
        return String(value[..<endIndex])
    }

    func applyText(_ value: String, to field: Field) {
        switch field {
        case .rating:
            break
        case .title:
            if title != value {
                title = value
            }
        case .placeDescription:
            if placeDescription != value {
                placeDescription = value
            }
        case .experience:
            if experience != value {
                experience = value
            }
        }

        _ = validate(field: field)
    }

    func sanitizedText(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func firstInvalidField() -> Field? {
        for field in Field.allCases {
            if !validate(field: field) {
                return field
            }
        }
        return nil
    }

    func isFieldValid(_ field: Field) -> Bool {
        switch field {
        case .rating:
            return (1...5).contains(rating)
        case .title:
            return sanitizedText(title).count >= 3 && title.count <= 80
        case .placeDescription:
            let sanitized = sanitizedText(placeDescription)
            return sanitized.count >= 10 && placeDescription.count <= 500
        case .experience:
            let sanitized = sanitizedText(experience)
            return sanitized.count >= 10 && experience.count <= 1000
        }
    }

    func resetForm() {
        rating = 0
        title = ""
        placeDescription = ""
        experience = ""
    }
}
