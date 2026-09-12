
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
        }
    }
}

#Preview {
    MainTabView()
}
