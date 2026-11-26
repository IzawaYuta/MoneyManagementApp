
import SwiftUI

// MARK: - 月の合計(収入・支出・収支)
/// 選択中の月の収入合計・支出合計と、その差額(収入 - 支出)を3列で表示する。
/// 「収入」ラベルは緑、「支出」ラベルは赤。収支は、プラスなら緑、マイナスなら赤、0なら黒。
struct MonthlyTotalsCard: View {
    let income: Int
    let expense: Int
    
    private var balance: Int { income - expense }
    
    private let customGreen = Color(red: 0.0, green: 180 / 255.0, blue: 0.0)
    private let customRed = Color(red: 230.0 / 255.0, green: 0.0, blue: 0.0)
    
    /// 収支の文字色
    private var balanceColor: Color {
        if balance > 0 { return customGreen }
        if balance < 0 { return customRed }
        return .black
    }
    
    /// 収支の背景色(0のときは付けない)
    private var balanceBackground: Color {
        if balance > 0 { return customGreen.opacity(0.12) }
        if balance < 0 { return customRed.opacity(0.12) }
        return .clear
    }
    
    private var balanceText: String {
        let amount = abs(balance).formatted()
        if balance > 0 { return "+¥\(amount)" }
        if balance < 0 { return "-¥\(amount)" }
        return "¥0"
    }
    
    var body: some View {
        HStack(spacing: 6) {
            column(
                title: "収入",
                titleColor: customGreen,
                amount: "¥\(income.formatted())"
            )
            
            Divider()
            
            column(
                title: "支出",
                titleColor: customRed,
                amount: "¥\(expense.formatted())"
            )
            
            Divider()
            
            column(
                title: "合計",
                titleColor: .secondary,
                amount: balanceText,
                textColor: balanceColor
            )
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(balanceBackground)
            )
        }
        .frame(maxHeight: 60)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .accessibilityIdentifier("chart.totalsCard")
    }
    
    private func column(
        title: String,
        titleColor: Color,
        amount: String,
        textColor: Color = .primary
    ) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(titleColor)
            Text(amount)
                .font(.system(size: 15, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview("プラス") {
    MonthlyTotalsCard(income: 325_000, expense: 172_900)
        .padding()
        .background(Color(uiColor: .systemGray6))
}

#Preview("マイナス") {
    MonthlyTotalsCard(income: 120_000, expense: 172_900)
        .padding()
        .background(Color(uiColor: .systemGray6))
}

#Preview("ゼロ") {
    MonthlyTotalsCard(income: 0, expense: 0)
        .padding()
        .background(Color(uiColor: .systemGray6))
}
