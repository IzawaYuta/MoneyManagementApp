
import SwiftUI

struct OnboardingDoneAnimationView: View {
    
    var onFinished: () -> Void
    
    @State private var showText = false
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0
    @State private var imageOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 16) {
                AnimatedCheckmarkView(onComplete: {
                    // チェック描画が終わったら、テキストを表示しつつ少し押し上げる
                    withAnimation(.easeOut(duration: 0.45)) {
                        imageOffset = -20
                        textOpacity = 1
                        textOffset = 0
                    }
                    showText = true
                    
                    // テキストを見せてから、実際に完了処理へ
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                        onFinished()
                    }
                })
                .offset(y: imageOffset)
                
                Text("さっそく始めましょう")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.gray)
                    .opacity(textOpacity)
                    .offset(y: textOffset)
            }
        }
    }
}

#Preview {
    OnboardingDoneAnimationView(onFinished: {})
}
