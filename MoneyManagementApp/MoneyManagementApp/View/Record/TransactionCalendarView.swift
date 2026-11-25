
import SwiftUI
import SwiftData

struct TransactionCalendarView: View {
    
    @Query(sort: [SortDescriptor(\Transaction.date), SortDescriptor(\Transaction.createdAt)])
    private var transactions: [Transaction]
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date = Date()
    
    @State private var editingTransaction: Transaction?
    
    private let calendar = Calendar.current
    
    let customGreen: Color = Color(red: 0.0, green: 180 / 255.0, blue: 0.0)
    let customRed: Color = Color(red: 230.0 / 255.0, green: 0.0, blue: 0.0)
    
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
                    .accessibilityIdentifier("calendar.prevMonth")
                    
                    Spacer()
                    
                    Text(monthTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .accessibilityIdentifier("calendar.monthTitle")
                    
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
                    .accessibilityIdentifier("calendar.nextMonth")
                }
                .padding(.horizontal, 30)
                
                // 曜日ヘッダー
                HStack(spacing: 0) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(symbol == "日" ? .orange : symbol == "土" ? .cyan : .gray)
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
            
            // 選択日の詳細
            ScrollView {
                selectedDayDetail
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.top, 16)
        .background(Color(uiColor: .systemGray6))
        .animation(.easeInOut(duration: 0.2), value: currentMonth)
        .sheet(item: $editingTransaction) { transaction in
            OverwriteRecordView(transaction: transaction)
                .interactiveDismissDisabled(true)
        }
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
                            .foregroundStyle(customGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    if summary.expense > 0 {
                        Text("\(summary.expense)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(customRed)
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
                isToday ? Color.gray.opacity(0.25) : Color.clear
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
        .accessibilityIdentifier("calendar.day.\(dayNumber)")
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
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(dayItems.enumerated()), id: \.element.id) { index, transaction in
                        Button {
                            editingTransaction = transaction
                        } label: {
                            transactionRow(transaction)
                                .contentShape(Rectangle())
                        }
                        .accessibilityIdentifier("calendar.transactionRow")  
                        
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
        let color = transaction.categoryColorHex.map(colorFromHex) ?? .black
        
        return HStack(spacing: 12) {
            // アイコン(カテゴリー色の薄い丸の上に表示)
            Image(systemName: transaction.categoryImageName ?? "questionmark")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(
                    Circle().fill(color.opacity(0.15))
                )
            
            // カテゴリー名 + メモ
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.categoryName ?? "未設定")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black)
                
                if let memo = transaction.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
                
                if let paymentMethodName = transaction.paymentMethodName {
                    Text(paymentMethodName)
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.gray.opacity(0.12))
                        )
                }
            }
            
            Spacer(minLength: 8)
            
            // 金額 + 支払方法
            Text(
                transaction.type == .income
                ? "+\(transaction.amount.formatted())円"
                : "-\(transaction.amount.formatted())円"
            )
            .font(.system(size: 17, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(transaction.type == .income ? customGreen : customRed)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    // MARK: - カラー変換
    
    private func colorFromHex(_ hex: String) -> Color {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let number = UInt64(value, radix: 16) ?? 0
        
        return Color(
            .sRGB,
            red: Double((number >> 16) & 0xFF) / 255,
            green: Double((number >> 8) & 0xFF) / 255,
            blue: Double(number & 0xFF) / 255,
            opacity: 1
        )
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
        CalendarService.daysInMonth(of: currentMonth, calendar: calendar)
    }
    
    // MARK: - 実データの集計
    
    /// 指定した日付に該当するTransactionを、時刻の新しい順に返す
    private func transactions(for date: Date) -> [Transaction] {
        CalendarService.transactions(for: date, in: transactions, calendar: calendar)
    }
    
    /// 指定した日付の収入合計・支出合計
    private func dailySummary(for date: Date) -> CalendarService.DailySummary {
        CalendarService.dailySummary(for: date, in: transactions, calendar: calendar)
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
            categoryColorHex: "#FF9800",
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
            categoryImageName: "yensign.circle",
            categoryColorHex: "#4CAF50"
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
                categoryImageName: "car",
                categoryColorHex: "#2196F3"
            )
        )
    }
    return TransactionCalendarView()
        .modelContainer(container)
}
