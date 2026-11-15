
import SwiftUI

// MARK: - カードの色
extension Color {
    /// カード背景の薄いグレー
    static let cardFill = Color(red: 0.95, green: 0.96, blue: 0.97)
}

// MARK: - カードの角の丸み
extension RectangleCornerRadii {
    /// カテゴリーカード(左上だけ大きく丸い)
    static let categoryCard = RectangleCornerRadii(
        topLeading: 30, bottomLeading: 18, bottomTrailing: 18, topTrailing: 18
    )
    /// 支払方法カード(右上だけ大きく丸い)
    static let paymentCard = RectangleCornerRadii(
        topLeading: 18, bottomLeading: 18, bottomTrailing: 18, topTrailing: 30
    )
    /// メモカード(下の2つが大きく丸い)
    static let memoCard = RectangleCornerRadii(
        topLeading: 18, bottomLeading: 30, bottomTrailing: 30, topTrailing: 18
    )
}

// MARK: - カードの背景
/// 薄いグレーの塗り + 軽い影。形(shape)は呼び出し側で指定できる。
struct CardBackground<S: Shape>: ViewModifier {
    let shape: S
    
    func body(content: Content) -> some View {
        content
            .background(
                shape
                    .fill(Color.cardFill)
                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
            )
    }
}

extension View {
    /// 角丸18の標準カード
    func cardBackground() -> some View {
        cardBackground(RoundedRectangle(cornerRadius: 18))
    }
    
    /// 好きな形のカード
    func cardBackground<S: Shape>(_ shape: S) -> some View {
        modifier(CardBackground(shape: shape))
    }
}

// MARK: - 金額カードの背景
struct PriceCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))
            )
    }
}

extension View {
    func priceCardBackground() -> some View {
        modifier(PriceCardBackground())
    }
}
