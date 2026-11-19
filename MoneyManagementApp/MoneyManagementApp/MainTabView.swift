
import SwiftUI

struct TabImageModifier: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .environment(
                \.symbolVariants,
                 isSelected ? .fill : .none
            )
            .foregroundStyle(.black)
    }
}

struct MainTabView: View {
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                        .modifier(TabImageModifier(isSelected: selectedTab == 0))
                    Text("入力")
                }
                .tag(0)
            
            TransactionCalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                        .modifier(TabImageModifier(isSelected: selectedTab == 1))
                    Text("記録")
                }
                .tag(1)
            
            MonthlyChartView()
                .tabItem {
                    Image(systemName: "chart.pie")
                        .modifier(TabImageModifier(isSelected: selectedTab == 2))
                    Text("グラフ")
                }
                .tag(2)
            
            BudgetView()
                .tabItem {
                    Image(systemName: "list.clipboard")
                        .modifier(TabImageModifier(isSelected: selectedTab == 3))
                    Text("予算")
                }
                .tag(3)
            
            SettingListView()
                .tabItem {
                    Image(systemName: "gear")
                        .modifier(TabImageModifier(isSelected: selectedTab == 4))
                    Text("設定")
                }
                .tag(4)
        }
        .tint(.black)
    }
}

#Preview {
    MainTabView()
}
