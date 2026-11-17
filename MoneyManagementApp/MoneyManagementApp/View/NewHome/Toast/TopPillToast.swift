//
//  TopPillToast.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/11/17.
//


import SwiftUI

// MARK: - 案F: 上から降りてくる黒ピル
/// 緑のチェックと文言だけの、控えめなピル型トースト。
struct TopPillToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(Color.green, in: Circle())

            Text(message)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.leading, 8)
        .padding(.trailing, 18)
        .frame(height: 44)
        .background(.black, in: Capsule())
        .shadow(color: .black.opacity(0.25), radius: 8, y: 6)
    }
}

private struct TopPillToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let duration: Double

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            ZStack {
                if isPresented {
                    TopPillToast(message: message)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .accessibilityAddTraits(.isStaticText)
                        .task {
                            try? await Task.sleep(for: .seconds(duration))
                            isPresented = false
                        }
                }
            }
            .animation(.spring(duration: 0.4, bounce: 0.3), value: isPresented)
        }
    }
}

extension View {
    /// 画面の上から黒いピルのトーストを出し、`duration` 秒後に自動で消す
    func topPillToast(isPresented: Binding<Bool>, message: String, duration: Double = 2) -> some View {
        modifier(TopPillToastModifier(isPresented: isPresented, message: message, duration: duration))
    }
}

// MARK: - 案J: ボタンから出る吹き出し
/// 白い吹き出し + 黒い枠 + ずらした黒い影(確定ボタンと同じポップな見た目)。
struct BubbleToast: View {
    let text: String

    private let tailHeight: CGFloat = 10

    var body: some View {
        HStack(spacing: 8) {
            Text("記録しました!")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .padding(.bottom, tailHeight)   // しっぽの分の高さ
        .background {
            ZStack {
                BubbleShape(tailHeight: tailHeight)
                    .fill(.black)
                    .offset(x: 4, y: 4)
                BubbleShape(tailHeight: tailHeight)
                    .fill(.white)
                BubbleShape(tailHeight: tailHeight)
                    .stroke(.black, lineWidth: 2)
            }
        }
    }
}

/// 下側の中央に「しっぽ」が付いた角丸の吹き出しの形
struct BubbleShape: Shape {
    var cornerRadius: CGFloat = 20
    var tailWidth: CGFloat = 18
    var tailHeight: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        // しっぽを除いた本体の範囲
        let body = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailHeight)
        let r = min(cornerRadius, body.height / 2)

        var p = Path()
        p.move(to: CGPoint(x: body.minX + r, y: body.minY))
        // 上辺 → 右上の角
        p.addLine(to: CGPoint(x: body.maxX - r, y: body.minY))
        p.addArc(center: CGPoint(x: body.maxX - r, y: body.minY + r), radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        // 右辺 → 右下の角
        p.addLine(to: CGPoint(x: body.maxX, y: body.maxY - r))
        p.addArc(center: CGPoint(x: body.maxX - r, y: body.maxY - r), radius: r,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        // 下辺(右 → しっぽ → 左)
        p.addLine(to: CGPoint(x: rect.midX + tailWidth / 2, y: body.maxY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - tailWidth / 2, y: body.maxY))
        p.addLine(to: CGPoint(x: body.minX + r, y: body.maxY))
        // 左下の角 → 左辺 → 左上の角
        p.addArc(center: CGPoint(x: body.minX + r, y: body.maxY - r), radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: body.minX, y: body.minY + r))
        p.addArc(center: CGPoint(x: body.minX + r, y: body.minY + r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

private struct BubbleToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let text: String
    let duration: Double

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            ZStack {
                if isPresented {
                    BubbleToast(text: text)
                        .fixedSize()
                        .transition(.scale(scale: 0.5, anchor: .bottom).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .task {
                            try? await Task.sleep(for: .seconds(duration))
                            isPresented = false
                        }
                }
            }
            // 吹き出しの下端が、ボタンの上端より6pt上に来るようにそろえる
            .alignmentGuide(.top) { $0[.bottom] + 6 }
            .animation(.spring(duration: 0.4, bounce: 0.45), value: isPresented)
        }
    }
}

extension View {
    /// このビューの真上に吹き出しのトーストを出し、`duration` 秒後に自動で消す
    func bubbleToast(isPresented: Binding<Bool>, text: String, duration: Double = 2) -> some View {
        modifier(BubbleToastModifier(isPresented: isPresented, text: text, duration: duration))
    }
}

// MARK: - Preview
#Preview {
    struct Demo: View {
        @State private var showTop = false
        @State private var showBubble = false

        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.8)
                .ignoresSafeArea()

                Button("確定") {
                    showTop = true
                    showBubble = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .bubbleToast(isPresented: $showBubble, text: "¥1,280 記録!")
            }
            .topPillToast(isPresented: $showTop, message: "保存しました")
        }
    }
    return Demo()
}
