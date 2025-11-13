import Testing
@testable import test2MD

@MainActor
struct ReviewEditorViewModelTests {
    @Test
    func initialState_isInvalidAndButtonDisabled() {
        let repository = ReviewRepository.previewRepository()
        let viewModel = ReviewEditorViewModel(reviewRepository: repository)

        #expect(viewModel.isSubmitButtonDisabled)
        #expect(viewModel.error(for: .rating) == nil)
    }

    @Test
    func validationFailsWhenFieldsAreEmpty() async {
        let repository = ReviewRepository.previewRepository()
        let viewModel = ReviewEditorViewModel(reviewRepository: repository)

        let outcome = await viewModel.submit()

        #expect(outcome == .validationFailed(field: .rating))
        #expect(viewModel.error(for: .rating) == String(localized: "error.rating.required"))
    }

    @Test
    func submitSuccessResetsFormAndCallsCallback() async throws {
        let repository = ReviewRepository.previewRepository()
        var didCallOnSaved = false
        let viewModel = ReviewEditorViewModel(reviewRepository: repository) {
            didCallOnSaved = true
        }

        viewModel.setRating(5)
        viewModel.setText("Ottimo pranzo", for: .title)
        viewModel.setText("Locale accogliente nel cuore della città.", for: .placeDescription)
        viewModel.setText("Servizio impeccabile e piatti deliziosi.", for: .experience)

        let outcome = await viewModel.submit()

        #expect(outcome == .success)
        #expect(didCallOnSaved)
        #expect(viewModel.rating == 0)
        #expect(viewModel.title.isEmpty)
        #expect(viewModel.placeDescription.isEmpty)
        #expect(viewModel.experience.isEmpty)

        let storedReviews = try repository.fetchReviews()
        #expect(storedReviews.count == 1)
    }

    @Test
    func truncationSetsFlagAndLimit() {
        let repository = ReviewRepository.previewRepository()
        let viewModel = ReviewEditorViewModel(reviewRepository: repository)

        let longTitle = String(repeating: "a", count: 120)
        viewModel.setText(longTitle, for: .title)

        #expect(viewModel.title.count == 80)
        #expect(viewModel.truncatedField == .title)
    }
}
