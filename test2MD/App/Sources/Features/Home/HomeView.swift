import SwiftUI

struct HomeView: View {
    var body: some View {
        Text(LocalizedStringKey("home_placeholder_title"))
            .navigationTitle(LocalizedStringKey("app_title"))
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
