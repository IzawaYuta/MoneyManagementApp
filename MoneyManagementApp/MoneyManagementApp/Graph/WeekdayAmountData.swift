
import SwiftUI
import SwiftData
import Charts

//MARK: 曜日ごとの金額集計データ
struct WeekdayAmountData: Identifiable {
    var id: Int { weekdayIndex }
    let weekdayIndex: Int
    let weekdayLabel: String
    let date: Date
    let totalAmount: Int
}

//MARK: 棒グラフ本体
struct WeekdayAmountChartView: View {
    
    @State private var selectedDay: WeekdayAmountData?
    
    /// 表示対象のTransaction配列（呼び出し側で期間フィルタ等を行ってから渡す）
    let transactions: [Transaction]
    
    /// 収入・支出どちらを集計するか（nilなら両方合算）
    var targetType: TransactionType? = .expense
    
    private static let weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"]
    
    private var chartData: [WeekdayAmountData] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        
        var sums = [Int: Int](minimumCapacity: 7)
        for i in 1...7 { sums[i] = 0 }
        
        for transaction in transactions {
            if let targetType, transaction.type != targetType { continue }
            let weekday = calendar.component(.weekday, from: transaction.date)
            sums[weekday, default: 0] += transaction.amount
        }
        
        // 今週の日曜日の日付を求める
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(todayWeekday - 1), to: today) ?? today
        
        return (1...7).map { index in
            let date = calendar.date(byAdding: .day, value: index - 1, to: startOfWeek) ?? startOfWeek
            return WeekdayAmountData(
                weekdayIndex: index,
                weekdayLabel: Self.weekdayLabels[index - 1],
                date: date,
                totalAmount: sums[index] ?? 0
            )
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(selectedDay.map { dateFormatter.string(from: $0.date) } ?? "-")
                        .font(.system(size: 20))
                    
                    Spacer()
                    Text(selectedDay.map { "\($0.totalAmount)円" } ?? "-")
                        .font(.system(size: 25))
                }
                Text(selectedDay.map { "\($0.weekdayLabel)曜日" } ?? "曜日をタップしてください")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)
            
            Chart(chartData) { data in
                BarMark(
                    x: .value("曜日", data.weekdayLabel),
                    y: .value("金額", max(data.totalAmount, 1))
                )
                .foregroundStyle(Color.blue.opacity(0.7))
                .cornerRadius(6)
                //            .annotation(position: .top) {
                //                if data.totalAmount != 0 {
                //                    Text("\(data.totalAmount)円")
                //                        .font(.caption2)
                //                        .foregroundStyle(.secondary)
                //                }
                //            }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let plotFrame = proxy.plotFrame else { return }
                            let origin = geo[plotFrame].origin
                            let xPosition = location.x - origin.x
                            if let label: String = proxy.value(atX: xPosition) {
                                selectedDay = chartData.first { $0.weekdayLabel == label }
                            }
                        }
                }
            }
            // 日曜始まりの表示順を明示的に固定（縦線なし）
            .chartXAxis {
                AxisMarks(values: chartData.map { $0.weekdayLabel }) { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                        }
                    }
                }
            }
            // y軸の値ラベルを左側に表示
            .chartYAxis {
                let maxAmount = chartData.map(\.totalAmount).max() ?? 0
                AxisMarks(position: .leading, values: [0, maxAmount / 2, maxAmount]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Int.self) {
                            Text("\(amount)")
                        }
                    }
                }
            }
//            .chartYScale(domain: 0...(Double(chartData.map(\.totalAmount).max() ?? 0) * 1.1))
            .frame(height: 240)
        }
        .padding()
        .onAppear {
            let calendar = Calendar(identifier: .gregorian)
            let todayWeekday = calendar.component(.weekday, from: Date()) // 1=日〜7=土
            selectedDay = chartData.first { $0.weekdayIndex == todayWeekday }
        }
    }
}

//MARK: プレビュー用サンプル
#Preview {
    let sample: [Transaction] = [
        Transaction(date: makeDate(weekday: 1), amount: 100, type: .expense, categoryID: UUID(), categoryName: "食費", categoryImageName: "fork.knife"),
        Transaction(date: makeDate(weekday: 2), amount: 2000,  type: .expense, categoryID: UUID(), categoryName: "食費", categoryImageName: "fork.knife"),
        Transaction(date: makeDate(weekday: 3), amount: 3000,  type: .expense, categoryID: UUID(), categoryName: "食費", categoryImageName: "fork.knife"),
        Transaction(date: makeDate(weekday: 4), amount: 4000, type: .expense, categoryID: UUID(), categoryName: "交通費", categoryImageName: "car"),
        Transaction(date: makeDate(weekday: 5), amount: 5000, type: .expense, categoryID: UUID(), categoryName: "娯楽", categoryImageName: "gamecontroller"),
        Transaction(date: makeDate(weekday: 6), amount: 6000, type: .expense, categoryID: UUID(), categoryName: "食費", categoryImageName: "fork.knife"),
        Transaction(date: makeDate(weekday: 7), amount: 7000000, type: .expense, categoryID: UUID(), categoryName: "食費", categoryImageName: "fork.knife"),
    ]
    return WeekdayAmountChartView(transactions: sample)
}

/// プレビュー用: 直近の指定曜日(1=日〜7=土)の日付を作る
private func makeDate(weekday: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "ja_JP")
    let today = Date()
    let todayWeekday = calendar.component(.weekday, from: today)
    let diff = weekday - todayWeekday
    return calendar.date(byAdding: .day, value: diff, to: today) ?? today
}
