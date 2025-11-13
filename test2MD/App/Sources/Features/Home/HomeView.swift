import SwiftUI

struct HomeView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                RestaurantHeaderView(
                    restaurant: viewModel.restaurant,
                    weekdayProvider: { value in viewModel.weekdayName(for: value) },
                    isShowingPhoneConfirmation: $viewModel.isShowingPhoneConfirmation,
                    onCallRequest: viewModel.showPhoneConfirmation,
                    onConfirmCall: callRestaurant
                )

                ReviewsSection(viewModel: viewModel)
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 120)
        }
        .background(Color.clear)
        .navigationTitle(LocalizedStringKey(viewModel.restaurant.nameLocalizationKey))
        .task {
            if viewModel.reviews.isEmpty {
                viewModel.refreshReviews()
            }
        }
        .navigationDestination(item: $viewModel.destination) { destination in
            switch destination {
            case .reviewEditor:
                Text(LocalizedStringKey("home_review_editor_placeholder"))
                    .onDisappear { viewModel.clearDestination() }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingActionButton(action: viewModel.handleFabTap)
                .padding(.trailing, 24)
                .padding(.bottom, 32)
                .accessibilityLabel(Text(LocalizedStringKey("home_fab_accessibility_label")))
                .accessibilityHint(Text(LocalizedStringKey("home_fab_accessibility_hint")))
        }
    }

    private func callRestaurant() {
        guard let url = viewModel.restaurant.phoneURL else { return }
        viewModel.hidePhoneConfirmation()
        openURL(url)
    }
}

private struct RestaurantHeaderView: View {
    let restaurant: HomeViewModel.Restaurant
    let weekdayProvider: (Int) -> String
    @Binding var isShowingPhoneConfirmation: Bool
    let onCallRequest: () -> Void
    let onConfirmCall: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(LocalizedStringKey(restaurant.nameLocalizationKey))
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            HStack(alignment: .top, spacing: 20) {
                Image(restaurant.heroImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(.white.opacity(0.25))
                    )
                    .accessibilityLabel(Text(LocalizedStringKey("home_hero_image_accessibility")))

                VStack(alignment: .leading, spacing: 16) {
                    Text(LocalizedStringKey(restaurant.descriptionLocalizationKey))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .accessibilityLabel(Text(LocalizedStringKey("home_restaurant_description_accessibility")))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("home_opening_hours_title"))
                            .font(.title3.weight(.semibold))

                        ForEach(restaurant.openingHours) { hour in
                            HStack {
                                Text(weekdayProvider(hour.weekday))
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(hour.openingTime) – \(hour.closingTime)")
                                    .font(.body.monospaced())
                                    .accessibilityHidden(true)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(
                                Text(
                                    String(
                                        localized: "home_opening_hours_accessibility",
                                        arguments: [
                                            weekdayProvider(hour.weekday),
                                            hour.openingTime,
                                            hour.closingTime
                                        ]
                                    )
                                )
                            )
                        }
                    }

                    PhoneButton(
                        displayNumber: restaurant.phoneDisplay,
                        isShowingConfirmation: $isShowingPhoneConfirmation,
                        onCallRequest: onCallRequest,
                        onConfirmCall: onConfirmCall
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(.white.opacity(0.25))
        )
    }
}

private struct PhoneButton: View {
    let displayNumber: String
    @Binding var isShowingConfirmation: Bool
    let onCallRequest: () -> Void
    let onConfirmCall: () -> Void

    var body: some View {
        Button(action: onCallRequest) {
            Label(displayNumber, systemImage: "phone.fill")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text(
                String(
                    localized: "home_phone_accessibility_label",
                    arguments: [displayNumber]
                )
            )
        )
        .popover(isPresented: $isShowingConfirmation, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            VStack(spacing: 12) {
                Text(
                    String(
                        localized: "home_call_confirmation_title",
                        arguments: [displayNumber]
                    )
                )
                .font(.headline)

                Text(
                    String(
                        localized: "home_call_confirmation_message",
                        arguments: [displayNumber]
                    )
                )
                .font(.subheadline)
                .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button(LocalizedStringKey("home_call_confirmation_cancel_action")) {
                        isShowingConfirmation = false
                    }

                    Button(LocalizedStringKey("home_call_confirmation_call_action")) {
                        isShowingConfirmation = false
                        onConfirmCall()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .presentationCompactAdaptation(.none)
        }
    }
}

private struct ReviewsSection: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("home_reviews_section_title"))
                .font(.title2.bold())
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(Text(LocalizedStringKey("home_reviews_loading_accessibility")))
            } else if let message = viewModel.errorMessage {
                InformativeLabel(text: message)
            } else if viewModel.reviews.isEmpty {
                InformativeLabel(text: String(localized: "home_reviews_empty_state"))
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.reviews) { review in
                        ReviewCard(review: review)
                    }
                }
                .accessibilityElement(children: .contain)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.25))
        )
    }
}

private struct InformativeLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityLabel(Text(text))
    }
}

private struct ReviewCard: View {
    let review: HomeViewModel.ReviewItem
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.title)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Text(
                        String(
                            localized: "home_review_card_user_format",
                            arguments: [review.userName, review.formattedDate]
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                StarRatingView(rating: review.rating)
            }

            Text(review.placeDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(review.experience)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
                .foregroundStyle(.primary)

            if review.experience.count > 160 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(LocalizedStringKey(isExpanded ? "home_review_card_collapse" : "home_review_card_expand"))
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text(LocalizedStringKey("home_review_card_expand_hint")))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.25))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text(
                String(
                    localized: "home_review_card_accessibility",
                    arguments: [
                        review.title,
                        review.userName,
                        review.formattedDate,
                        review.rating
                    ]
                )
            )
        )
    }
}

private struct StarRatingView: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(star <= rating ? .yellow : .secondary)
                    .imageScale(.medium)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(
                String(
                    localized: "home_star_rating_accessibility",
                    arguments: [rating]
                )
            )
        )
    }
}

private struct FloatingActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .padding(22)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 12)
                )
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}

#Preview {
    let repository = ReviewRepository.previewRepository()
    try? repository.createReview(
        title: "Pranzo perfetto",
        rating: 5,
        placeDescription: "Locale accogliente con tavoli all'aperto.",
        experience: "Il servizio è stato rapido e cortese. Il menù degustazione era equilibrato e molto gustoso.",
        userName: "Giulia"
    )
    return NavigationStack {
        HomeView(viewModel: HomeViewModel(repository: repository))
    }
}
