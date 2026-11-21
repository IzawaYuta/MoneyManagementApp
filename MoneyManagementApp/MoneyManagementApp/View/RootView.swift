
import SwiftUI

struct RootView: View {
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        ZStack {
            if UITestSupport.isUITesting || hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
                    .transition(.move(edge: .top))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
        .task {
            guard !UITestSupport.isUITesting else { return }      
            await authManager.signInAnonymously()
        }
    }
}

#Preview {
    RootView()
}
