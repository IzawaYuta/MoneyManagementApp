
import SwiftUI
import SwiftData

struct TransactionCalendarView: View {
    
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 16) {
            
            // MARK: - カレンダー全体(月ナビゲーター〜日付グリッド)を枠線で囲む
            VStack(spacing: 16) {
                
                // 月ナビゲーター
                HStack {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(Color(uiColor: .systemGray6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(monthTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                    
                    Spacer()
                    
                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(Color(uiColor: .systemGray6))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 8)
                
                // 曜日ヘッダー
                HStack(spacing: 0) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // 日付グリッド
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                        if let date {
                            dayCell(for: date)
                        } else {
                            Color.clear
                                .frame(height: 56)
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            if value.translation.width < -30 {
                                changeMonth(by: 1)
                            } else if value.translation.width > 30 {
                                changeMonth(by: -1)
                            }
                        }
                )
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 5)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.horizontal, 5)
            
            // 選択日の詳細
            ScrollView {
                selectedDayDetail
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.top, 16)
        .background(Color(uiColor: .systemGray6).opacity(0.5))
        .animation(.easeInOut(duration: 0.2), value: currentMonth)
    }
    
    // MARK: - 各日付セル
    
    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(selectedDate, inSameDayAs: date)
        let isToday = calendar.isDateInToday(date)
        let dayNumber = calendar.component(.day, from: date)
        let summary = dailySummary(for: date)
        
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 3) {
                Text("\(dayNumber)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.black)
                    .frame(height: 16)
                
                // 収入・支出、両方あれば収入を上に
                VStack(spacing: 1) {
                    if summary.income > 0 {
                        Text("\(summary.income)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.green.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    if summary.expense > 0 {
                        Text("\(summary.expense)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                .frame(height: 22)
                .padding(.horizontal, 3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isToday ? Color.gray.opacity(0.35) : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? Color.black : Color.black.opacity(0.1),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 選択日の詳細カード(実データ)
    
    @ViewBuilder
    private var selectedDayDetail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedDateTitle(for: selectedDate))
                .font(.system(size: 13))
                .foregroundStyle(.black)
            
            let dayItems = transactions(for: selectedDate)
            
            if dayItems.isEmpty {
                Text("この日の記録はありません")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(dayItems.enumerated()), id: \.element.id) { index, transaction in
                        transactionRow(transaction)
                        
                        if index < dayItems.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                )
            }
        }
    }
    
    @ViewBuilder
    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 10) {
            Image(systemName: transaction.categoryImageName)
                .font(.system(size: 14))
                .foregroundStyle(.black)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.categoryName)
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                
                if let memo = transaction.memo {
                    Text(memo)
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                }
                
                if let paymentMethodName = transaction.paymentMethodName {
                    Text(paymentMethodName)
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            Text(
                transaction.type == .income
                ? "+\(transaction.amount.formatted())円"
                : "-\(transaction.amount.formatted())円"
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(transaction.type == .income ? .green : .red)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    // MARK: - 月の切り替え
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    // MARK: - 表示用の計算プロパティ
    
    private var monthTitle: String {
        currentMonth.formatted(
            .dateTime
                .year()
                .month()
                .locale(Locale(identifier: "ja_JP"))
        )
    }
    
    private func selectedDateTitle(for date: Date) -> String {
        date.formatted(
            .dateTime
                .month()
                .day()
                .weekday(.wide)
                .locale(Locale(identifier: "ja_JP"))
        )
    }
    
    private var weekdaySymbols: [String] {
        ["日", "月", "火", "水", "木", "金", "土"]
    }
    
    /// 現在の月に表示する日付の配列(月初の曜日オフセット分はnilで埋める)
    private var daysInMonth: [Date?] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
            let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else {
            return []
        }
        
        let leadingEmptyCount = firstWeekday - 1
        let daysCount = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyCount)
        
        for dayOffset in 0..<daysCount {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // MARK: - 実データの集計
    
    /// 指定した日付に該当するTransactionを、時刻の新しい順に返す
    private func transactions(for date: Date) -> [Transaction] {
        transactions
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }
    
    /// 指定した日付の収入合計・支出合計
    private func dailySummary(for date: Date) -> (income: Int, expense: Int) {
        let dayItems = transactions
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
        
        let income = dayItems
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let expense = dayItems
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        return (income, expense)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Transaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let context = container.mainContext
    
    let today = Date()
    let calendar = Calendar.current
    
    context.insert(
        Transaction(
            date: today,
            amount: 1280,
            type: .expense,
            categoryID: UUID(),
            categoryName: "食費",
            categoryImageName: "fork.knife",
            paymentMethodID: UUID(),
            paymentMethodName: "現金",
            paymentMethodType: .cash
        )
    )
    
    context.insert(
        Transaction(
            date: today,
            amount: 2500000,
            type: .income,
            categoryID: UUID(),
            categoryName: "給与",
            categoryImageName: "yensign.circle"
        )
    )
    
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
        context.insert(
            Transaction(
                date: yesterday,
                amount: 420,
                type: .expense,
                categoryID: UUID(),
                categoryName: "交通費",
                categoryImageName: "car"
            )
        )
    }
    
    return TransactionCalendarView()
        .modelContainer(container)
}
