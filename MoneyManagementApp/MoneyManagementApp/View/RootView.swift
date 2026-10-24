
import SwiftUI

struct RootView: View {
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
                    .transition(.move(edge: .top))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
    }
}

#Preview {
    RootView()
}
