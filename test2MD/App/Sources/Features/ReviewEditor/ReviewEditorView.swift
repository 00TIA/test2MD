import SwiftUI
import UIKit

struct ReviewEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReviewEditorViewModel

    @FocusState private var focusedField: ReviewEditorViewModel.Field?
    @State private var shakeTriggers: [ReviewEditorViewModel.Field: Int] = [:]
    @State private var scrollProxy: ScrollViewProxy?
    @State private var successDismissTask: Task<Void, Never>?

    init(viewModel: ReviewEditorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    ratingSection
                        .id(ReviewEditorViewModel.Field.rating)
                        .modifier(shakeEffect(for: .rating))

                    titleSection
                        .id(ReviewEditorViewModel.Field.title)
                        .modifier(shakeEffect(for: .title))

                    placeDescriptionSection
                        .id(ReviewEditorViewModel.Field.placeDescription)
                        .modifier(shakeEffect(for: .placeDescription))

                    experienceSection
                        .id(ReviewEditorViewModel.Field.experience)
                        .modifier(shakeEffect(for: .experience))

                    submitSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 48)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(InfantinoColorTokens.background.ignoresSafeArea())
            .onAppear { scrollProxy = proxy }
            .onDisappear { successDismissTask?.cancel() }
        }
        .navigationTitle(LocalizedStringKey("review_editor_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { keyboardToolbar }
        .onChange(of: viewModel.truncatedField) { field in
            guard field != nil else { return }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            viewModel.clearTruncatedField()
        }
        .onChange(of: viewModel.submitState) { state in
            handleSubmitStateChange(state)
        }
    }
}

private extension ReviewEditorView {
    var ratingSection: some View {
        ReviewEditorBox(titleKey: "review.rating.label", error: viewModel.error(for: .rating)) {
            InteractiveStarRating(rating: viewModel.rating) { newValue in
                let previous = viewModel.rating
                viewModel.setRating(newValue)
                if newValue != previous {
                    let generator = UIImpactFeedbackGenerator(style: .soft)
                    generator.impactOccurred(intensity: 0.7)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(LocalizedStringKey("review.rating.label")))
            .accessibilityValue(Text(String(localized: "home_star_rating_accessibility", arguments: [viewModel.rating])))
            .accessibilityAdjustableAction { direction in
                let newValue: Int
                switch direction {
                case .increment:
                    newValue = min(5, (viewModel.rating == 0 ? 1 : viewModel.rating + 1))
                case .decrement:
                    newValue = max(0, viewModel.rating - 1)
                @unknown default:
                    newValue = viewModel.rating
                }
                viewModel.setRating(newValue)
            }
        }
    }

    var titleSection: some View {
        ReviewEditorBox(titleKey: "review.title.label", error: viewModel.error(for: .title), counter: counterText(current: viewModel.title.count, max: 80)) {
            TextField(LocalizedStringKey("review.title.placeholder"), text: viewModel.binding(for: .title))
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .focused($focusedField, equals: .title)
                .font(.body)
                .padding(.vertical, 8)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .placeDescription
                }
        }
    }

    var placeDescriptionSection: some View {
        ReviewEditorBox(titleKey: "review.place.label", error: viewModel.error(for: .placeDescription), counter: counterText(current: viewModel.placeDescription.count, max: 500)) {
            PlaceholderTextEditor(text: viewModel.binding(for: .placeDescription), placeholderKey: "review.place.placeholder")
                .frame(minHeight: 140, maxHeight: 240)
                .focused($focusedField, equals: .placeDescription)
        }
    }

    var experienceSection: some View {
        ReviewEditorBox(titleKey: "review.experience.label", error: viewModel.error(for: .experience), counter: counterText(current: viewModel.experience.count, max: 1000)) {
            PlaceholderTextEditor(text: viewModel.binding(for: .experience), placeholderKey: "review.experience.placeholder")
                .frame(minHeight: 180, maxHeight: 320)
                .focused($focusedField, equals: .experience)
        }
    }

    var submitSection: some View {
        VStack(spacing: 16) {
            Button(action: handleSubmitTapped) {
                HStack(spacing: 12) {
                    if case .loading = viewModel.submitState {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }

                    Text(LocalizedStringKey("review.submit"))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(viewModel.isSubmitButtonDisabled ? InfantinoColorTokens.primary.opacity(0.4) : InfantinoColorTokens.primary)
            )
            .foregroundStyle(InfantinoColorTokens.onPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2))
            )
            .disabled(viewModel.isSubmitButtonDisabled)
            .scaleEffect(viewModel.isSubmitButtonDisabled ? 1.0 : 0.98, anchor: .center)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.isSubmitButtonDisabled)
            .accessibilityHint(Text(LocalizedStringKey("review.submit.hint")))

            if let alert = attachedAlertState {
                AttachedAlertView(state: alert) {
                    viewModel.clearFailureState()
                    handleSubmitTapped()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: attachedAlertState?.message)
    }

    var attachedAlertState: AttachedAlertState? {
        switch viewModel.submitState {
        case .success(let message):
            return AttachedAlertState(style: .success, message: message, showsRetry: false)
        case .failure(let message):
            return AttachedAlertState(style: .error, message: message, showsRetry: true)
        default:
            return nil
        }
    }

    func counterText(current: Int, max: Int) -> String {
        String(localized: "review.character_count_format", arguments: [current, max])
    }

    func shakeEffect(for field: ReviewEditorViewModel.Field) -> ShakeEffect {
        ShakeEffect(animatableData: CGFloat(shakeTriggers[field, default: 0]))
    }

    func triggerShake(for field: ReviewEditorViewModel.Field) {
        shakeTriggers[field, default: 0] += 1
    }

    func keyboardToolbarContent() -> some View {
        HStack {
            Spacer()
            Button(LocalizedStringKey("action.done")) {
                focusedField = nil
            }
        }
    }

    var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            keyboardToolbarContent()
        }
    }

    func handleSubmitTapped() {
        let proxy = scrollProxy
        if !viewModel.isSubmitButtonDisabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        Task {
            let outcome = await viewModel.submit()
            await MainActor.run {
                switch outcome {
                case .validationFailed(let field):
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    if field != .rating {
                        focusedField = field
                    } else {
                        focusedField = nil
                    }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy?.scrollTo(field, anchor: .center)
                    }
                    triggerShake(for: field)
                case .failure:
                    break
                case .success:
                    focusedField = nil
                }
            }
        }
    }

    func handleSubmitStateChange(_ state: ReviewEditorViewModel.SubmitState) {
        switch state {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            successDismissTask?.cancel()
            successDismissTask = Task { [dismiss] in
                try? await Task.sleep(for: .milliseconds(1800))
                await MainActor.run {
                    viewModel.resetSubmitState()
                    dismiss()
                }
            }
        case .failure:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        default:
            break
        }
    }
}

private struct ReviewEditorBox<Content: View>: View {
    let titleKey: String
    let error: String?
    var counter: String?
    @ViewBuilder var content: Content

    init(titleKey: String, error: String?, counter: String? = nil, @ViewBuilder content: () -> Content) {
        self.titleKey = titleKey
        self.error = error
        self.counter = counter
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStringKey(titleKey))
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(InfantinoColorTokens.onSurface)
                Spacer()
                if let counter {
                    Text(counter)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text(counter))
                }
            }

            content
                .padding(16)
                .accessibilityLabel(Text(LocalizedStringKey(titleKey)))
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(error == nil ? Color.white.opacity(0.25) : InfantinoColorTokens.primary.opacity(0.8), lineWidth: error == nil ? 1 : 2)
                )

            if let error {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(InfantinoColorTokens.primary)
                    .accessibilityLabel(Text(error))
            }
        }
    }
}

private struct PlaceholderTextEditor: View {
    @Binding var text: String
    let placeholderKey: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(LocalizedStringKey(placeholderKey))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .accessibilityHidden(true)
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, -4)
                .padding(.vertical, -8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.body)
        }
    }
}

private struct InteractiveStarRating: View {
    let rating: Int
    let onUpdate: (Int) -> Void

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) {
                            onUpdate(star)
                        }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(star <= rating ? InfantinoColorTokens.primary : InfantinoColorTokens.primary.opacity(0.35))
                            .scaleEffect(star == rating ? 1.08 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: rating)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityLabel(Text(String(localized: "home_star_rating_accessibility", arguments: [star])))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateRating(with: value.location.x, width: geometry.size.width)
                    }
            )
        }
        .frame(height: 52)
    }

    private func updateRating(with xPosition: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let normalized = max(0, min(width, xPosition)) / width
        let star = max(1, min(5, Int(round(normalized * 5))))
        onUpdate(star)
    }
}

private struct AttachedAlertState {
    enum Style {
        case success
        case error

        var iconName: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.octagon.fill"
            }
        }

        var tint: Color {
            switch self {
            case .success:
                return InfantinoColorTokens.primary
            case .error:
                return InfantinoColorTokens.primary.opacity(0.85)
            }
        }
    }

    let style: Style
    let message: String
    let showsRetry: Bool
}

private struct AttachedAlertView: View {
    let state: AttachedAlertState
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: state.style.iconName)
                    .foregroundStyle(state.style.tint)
                    .imageScale(.large)
                Text(state.message)
                    .font(.callout)
                    .foregroundStyle(state.style.tint)
                    .multilineTextAlignment(.leading)
                Spacer()
            }

            if state.showsRetry {
                Button(LocalizedStringKey("review.retry"), action: retryAction)
                    .buttonStyle(.bordered)
                    .tint(InfantinoColorTokens.primary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(InfantinoColorTokens.primary.opacity(0.3))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(state.message))
    }
}

private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 6 * sin(animatableData * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

#Preview {
    let repository = ReviewRepository.previewRepository()
    let viewModel = ReviewEditorViewModel(reviewRepository: repository)
    return NavigationStack {
        ReviewEditorView(viewModel: viewModel)
    }
}
