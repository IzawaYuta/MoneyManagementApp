
import SwiftUI

struct MainTabView: View {
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                }
                .tag(0)
            TransactionListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                }
                .tag(1)
            OnboardingView()
                .tabItem {
                    Image(systemName: "list.bullet")
                }
                .tag(2)
            OnboardingDoneAnimationTestView()
                .tabItem {
                    Image(systemName: "list.bullet")
                }
                .tag(3)
        }
    }
}

#Preview {
    MainTabView()
}
