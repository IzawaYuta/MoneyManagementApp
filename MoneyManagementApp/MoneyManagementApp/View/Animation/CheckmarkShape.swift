import SwiftUI

// MARK: - チェックマークの形状

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: rect.minX + rect.width * 0.15, y: rect.midY + rect.height * 0.05)
        let middle = CGPoint(x: rect.minX + rect.width * 0.42, y: rect.maxY - rect.height * 0.15)
        let end = CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.18)
        path.move(to: start)
        path.addLine(to: middle)
        path.addLine(to: end)
        return path
    }
}

// MARK: - アニメーション付きチェックマークView

struct AnimatedCheckmarkView: View {
    
    @State private var circleTrimEnd: CGFloat = 0   // 追加
    @State private var trimEnd: CGFloat = 0
    @State private var circleScale: CGFloat = 0.5
    @State private var circleOpacity: Double = 0
    
    var onComplete: (() -> Void)? = nil   // ← 追加
    
    var body: some View {
        ZStack {
            // 背景の円
//            Circle()
//                .fill(Color.black)
//                .scaleEffect(circleScale)
//                .opacity(circleOpacity)
            
            // 背景の円(線のみ)
            Circle()
                .trim(from: 0, to: circleTrimEnd)
                .stroke(
                    Color.black,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-215)) // 12時の位置から時計回りに描き始める

            
            // チェックマーク本体
            CheckmarkShape()
                .trim(from: 0, to: trimEnd)
                .stroke(
                    Color.black,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                )
                .padding(20)
        }
        .frame(width: 120, height: 120)
        .onAppear {
            play()
        }
    }
    
    private func play() {
        circleTrimEnd = 0   // 追加
        trimEnd = 0
        circleScale = 0.5
        circleOpacity = 0
        
        withAnimation(.easeInOut(duration: 0.4)) {
            circleTrimEnd = 1.0   // 追加(円を線で一周描く)
        }
        
        withAnimation(.easeOut(duration: 0.3)) {
            circleScale = 1.0
            circleOpacity = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.4).delay(0.15)) {
            trimEnd = 1.0
        }
        
        // アニメーション終了(0.35 + 0.4)から少し間を置いてから完了通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + 0.4 + 0.4) {
            onComplete?()
        }
    }
}

// MARK: - テスト用画面(リプレイボタン付き)

struct CheckmarkAnimationTestView: View {
    
    @State private var replayTrigger = 0
    
    var body: some View {
        VStack(spacing: 40) {
            AnimatedCheckmarkView()
                .id(replayTrigger) // idを変えることでViewを作り直し、アニメーションを最初から再生
            
            Button {
                replayTrigger += 1
            } label: {
                Text("もう一度再生")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGray6).opacity(0.5))
    }
}

#Preview {
    CheckmarkAnimationTestView()
}
