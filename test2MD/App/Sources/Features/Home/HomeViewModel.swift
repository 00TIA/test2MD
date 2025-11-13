import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    struct Restaurant {
        struct OpeningHour: Identifiable, Hashable {
            let id = UUID()
            let weekday: Int
            let openingTime: String
            let closingTime: String
        }

        let nameLocalizationKey: String
        let heroImageName: String
        let descriptionLocalizationKey: String
        let phoneDisplay: String
        let phoneDial: String
        let openingHours: [OpeningHour]

        var phoneURL: URL? {
            URL(string: "tel://\(phoneDial)")
        }
    }

    struct ReviewItem: Identifiable, Equatable {
        let id: UUID
        let title: String
        let rating: Int
        let placeDescription: String
        let experience: String
        let userName: String
        let formattedDate: String
    }

    enum Destination: Identifiable, Hashable {
        case reviewEditor

        var id: String {
            switch self {
            case .reviewEditor:
                return "reviewEditor"
            }
        }
    }

    private let reviewRepository: ReviewRepository
    private let dateFormatter: DateFormatter

    @Published private(set) var restaurant: Restaurant
    @Published private(set) var reviews: [ReviewItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var destination: Destination?
    @Published var isShowingPhoneConfirmation = false

    init(repository: ReviewRepository, locale: Locale = .current) {
        reviewRepository = repository
        dateFormatter = Self.makeDateFormatter(locale: locale)
        restaurant = Self.makeRestaurant()
    }

    func refreshReviews() {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedReviews = try reviewRepository.fetchReviews()
            reviews = fetchedReviews.map { review in
                ReviewItem(
                    id: review.id,
                    title: review.title,
                    rating: review.rating,
                    placeDescription: review.placeDescription,
                    experience: review.experience,
                    userName: review.userName,
                    formattedDate: dateFormatter.string(from: review.reviewDate)
                )
            }
        } catch {
            errorMessage = String(localized: "home_reviews_loading_error")
        }

        isLoading = false
    }

    func handleFabTap() {
        destination = .reviewEditor
    }

    func clearDestination() {
        destination = nil
    }

    func showPhoneConfirmation() {
        isShowingPhoneConfirmation = true
    }

    func hidePhoneConfirmation() {
        isShowingPhoneConfirmation = false
    }

    func weekdayName(for weekday: Int, locale: Locale = .current) -> String {
        var calendar = Calendar.current
        calendar.locale = locale
        let weekdays = calendar.weekdaySymbols

        let index = (weekday - calendar.firstWeekday + 7) % 7
        guard weekdays.indices.contains(index) else {
            return ""
        }

        return weekdays[index].capitalized
    }
}

private extension HomeViewModel {
    static func makeDateFormatter(locale: Locale) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    static func makeRestaurant() -> Restaurant {
        Restaurant(
            nameLocalizationKey: "app_title",
            heroImageName: "restaurant_hero",
            descriptionLocalizationKey: "home_restaurant_description",
            phoneDisplay: "+39 02 1234 5678",
            phoneDial: "+390212345678",
            openingHours: [
                .init(weekday: 2, openingTime: "12:00", closingTime: "23:00"),
                .init(weekday: 3, openingTime: "12:00", closingTime: "23:00"),
                .init(weekday: 4, openingTime: "12:00", closingTime: "23:00"),
                .init(weekday: 5, openingTime: "12:00", closingTime: "23:30"),
                .init(weekday: 6, openingTime: "12:00", closingTime: "00:30"),
                .init(weekday: 7, openingTime: "11:00", closingTime: "00:30"),
                .init(weekday: 1, openingTime: "11:00", closingTime: "22:00")
            ]
        )
    }
}
