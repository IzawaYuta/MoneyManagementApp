
import SwiftUI

struct MainTabView: View {
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                }
                .tag(0)
            TransactionCalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                }
                .tag(1)
        }
    }
}

#Preview {
    MainTabView()
}
