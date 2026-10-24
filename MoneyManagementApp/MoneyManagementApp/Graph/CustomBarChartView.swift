
import SwiftUI
import SwiftData

struct CustomBarChartView: View {
    
    @Query(sort: \Transaction.date)
    private var transactions: [Transaction]
    
    private var maxValue: Int {
        weeklyAmounts.max() ?? 0
    }
    
    var body: some View {
        
        let dailyAmounts = weeklyAmounts
        
        HStack(spacing: 8) {
            
            // 左側：金額
//            VStack {
//                Text("10,000")
//                Spacer()
//                Text("5,000")
//                Spacer()
//                Text("0")
//            }
//            .font(.caption)
//            .foregroundStyle(.secondary)
//            .frame(width: 50)
            
            VStack {
                Text("\(maxValue)")
                Spacer()
                Text("\(maxValue / 2)")
                Spacer()
                Text("0")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: 50)
            
            VStack(spacing: 8) {
                
                GeometryReader { geometry in
                    ZStack {
                        
                        // 横線
                        VStack {
                            Rectangle()
                                .frame(height: 1)
                            
                            Spacer()
                            
                            Rectangle()
                                .frame(height: 1)
                            
                            Spacer()
                            
                            Rectangle()
                                .frame(height: 1)
                        }
                        .foregroundStyle(.secondary.opacity(0.3))
                        
                        // 棒グラフ
                        HStack(
                            alignment: .bottom,
                            spacing: 0
                        ) {
                            ForEach(
                                dailyAmounts.indices,
                                id: \.self
                            ) { index in
                                
                                VStack {
                                    Spacer()
                                    
                                    Rectangle()
                                        .frame(
                                            width: 24,
                                            height: barHeight(
                                                value: dailyAmounts[index],
                                                maxHeight: geometry.size.height
                                            )
                                        )
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                
                HStack(spacing: 0) {
                    ForEach(
                        ["月", "火", "水", "木", "金", "土", "日"],
                        id: \.self
                    ) { day in
                        
                        Text(day)
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(.caption)
            }
        }
        .frame(height: 300)
        .padding()
    }
    
    // MARK: - 週間集計
    
    private var weeklyAmounts: [Int] {
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let weekStart = calendar.dateInterval(
            of: .weekOfYear,
            for: today
        )?.start else {
            return Array(repeating: 0, count: 7)
        }
        
        return (0..<7).map { index in
            
            guard let date = calendar.date(
                byAdding: .day,
                value: index,
                to: weekStart
            ) else {
                return 0
            }
            
            return transactions
                .filter {
                    calendar.isDate(
                        $0.date,
                        inSameDayAs: date
                    )
                }
                .reduce(0) {
                    $0 + $1.amount
                }
        }
    }
    
    private func barHeight(
        value: Int,
        maxHeight: CGFloat
    ) -> CGFloat {
        
        guard maxValue > 0 else {
            return 0
        }
        
        return CGFloat(value)
        / CGFloat(maxValue)
        * maxHeight
    }
}

#Preview {
    
    let container = try! ModelContainer(
        for: Transaction.self,
        configurations: ModelConfiguration(
            isStoredInMemoryOnly: true
        )
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
            amount: (day + 1) * 1_000,
            type: .expense,
            categoryID: UUID(),
            categoryName: "食費",
            categoryImageName: "fork.knife"
        )
        
        container.mainContext.insert(transaction)
    }
    
    return CustomBarChartView()
        .modelContainer(container)
}
