import SwiftUI

struct OnboardingDoneAnimationTestView: View {
    
    @State private var replayTrigger = 0
    
    var body: some View {
        ZStack {
            OnboardingDoneAnimationView(onFinished: {
                print("onFinished が呼ばれました(実際はここで hasCompletedOnboarding = true)")
            })
            .id(replayTrigger) // idを変えることでViewを作り直し、最初から再生する
            
            VStack {
                Spacer()
                
                Button {
                    replayTrigger += 1
                } label: {
                    Text("再生")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    OnboardingDoneAnimationTestView()
}

