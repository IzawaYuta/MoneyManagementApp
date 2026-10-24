
import SwiftUI
import SwiftData
import Charts

struct TransactionGraphView: View {
    
    @Query(sort: \Transaction.date)
    private var transactions: [Transaction]
    
    var body: some View {
        Chart {
            ForEach(weeklyData) { data in
                BarMark(
                    x: .value("曜日", data.date, unit: .day),
                    y: .value("金額", data.amount)
                )
            }
        }
        .frame(height: 250)
        .chartXScale(domain: weekInterval.start...weekInterval.end)
        .chartXAxis {
            AxisMarks(values: weeklyData.map(\.date)) { value in
                AxisTick()
                AxisValueLabel(centered: true) {
                    if let date = value.as(Date.self) {
                        Text(
                            date,
                            format: .dateTime
                                .weekday(.abbreviated)
                                .locale(Locale(identifier: "ja_JP"))
                        )
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .padding()
    }
    
    private var calendar: Calendar { Calendar.current }
    
    private var weekInterval: DateInterval {
        let today = calendar.startOfDay(for: Date())
        return calendar.dateInterval(of: .weekOfYear, for: today)
        ?? DateInterval(start: today, duration: 0)
    }
    
    private var weeklyData: [DailyAmount] {
        (0..<7).map { index in
            let date = calendar.date(
                byAdding: .day,
                value: index,
                to: weekInterval.start
            )!
            
            let amount = transactions
                .filter {
                    calendar.isDate($0.date, inSameDayAs: date)
                }
                .reduce(0) {
                    $0 + $1.amount
                }
            
            return DailyAmount(date: date, amount: amount)
        }
    }
}

private struct DailyAmount: Identifiable {
    
    let date: Date
    let amount: Int
    
    var id: Date {
        date
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Transaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    for day in 0..<7 {
        let date = calendar.date(
            byAdding: .day,
            value: day,
            to: today
        )!
        
        let transaction = Transaction(
            date: date,
            amount: [3000, 5000, 2000, 8000, 4000, 6000, 10000][day],
            type: .expense,
            categoryID: UUID(),
            categoryName: "食費",
            categoryImageName: "fork.knife"
        )
        
        container.mainContext.insert(transaction)
    }
    
    return TransactionGraphView()
        .modelContainer(container)
}
