
import SwiftUI

// MARK: - 使用率バー
struct BudgetProgressBar: View {
    let progress: Double
    let fill: Color
    let track: Color
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(fill)
                    .frame(width: geo.size.width * max(0, min(progress, 1)))
            }
        }
        .frame(height: height)
    }
}

// MARK: - 種別ごとの表示ラベル
extension TransactionType {
    var totalTitle: String { self == .expense ? "総予算" : "総目標" }
    var budgetTitle: String { self == .expense ? "予算" : "目標" }
    var spentTitle: String { self == .expense ? "使用済み" : "受取済み" }
    var remainingTitle: String { "残り" }
    var overTitle: String { self == .expense ? "超過" : "目標超過" }
}

// MARK: - 年月の表示・範囲
extension YearMonth {
    /// 202611 → "2026年11月"
    static func label(_ yyyymm: Int) -> String {
        "\(yyyymm / 100)年\(yyyymm % 100)月"
    }

    /// 202611 → 2026/11/1 〜 2026/12/1(終端は含まない)
    static func dateRange(_ yyyymm: Int, calendar: Calendar = .current) -> Range<Date> {
        let start = calendar.date(from: DateComponents(year: yyyymm / 100, month: yyyymm % 100, day: 1)) ?? Date()
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return start..<end
    }
}

// MARK: - 金額・色
func budgetYen(_ value: Int) -> String {
    value < 0 ? "-¥\(abs(value).formatted())" : "¥\(value.formatted())"
}

extension Color {
    /// "#FF6B6B" 形式の文字列から生成(既存の変換処理があれば、そちらに置き換え可)
    init(budgetHex hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        guard s.count == 6, Scanner(string: s).scanHexInt64(&v) else {
            self = .gray
            return
        }
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}
