
import SwiftUI

struct OnboardingView: View {
    
    private enum Step {
        case category
        case paymentMethod
        case doneCheckAnimation
    }
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var step: Step = .category
    
    var body: some View {
        Group {
            switch step {
            case .category:
                OnboardingCategoryView(onNext: {
                    step = .paymentMethod
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .paymentMethod:
                OnboardingPaymentMethodView(onFinish: {
                    step = .doneCheckAnimation
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .doneCheckAnimation:
                ZStack {
                    Color.white.ignoresSafeArea()   // ← 背景真っ白
                    
                    AnimatedCheckmarkView(onComplete: {
                        hasCompletedOnboarding = true   // ← アニメーション完了後にHomeViewへ
                    })
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }
}

#Preview {
    OnboardingView()
}
