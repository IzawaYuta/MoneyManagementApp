
import SwiftUI

struct TransactionCalendarView: View {
    
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
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
            
            // 選択日の詳細(ダミー)
            selectedDayDetail
                .padding(.horizontal, 20)
                .padding(.top, 4)
            
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
        let amount = dummyAmount(for: date)
        
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 3) {
                Text("\(dayNumber)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(isSelected ? .black : .black)
                
                if amount != 0 {
                    Text(amount > 0 ? "+\(amount / 1000)k" : "\(amount / 1000)k")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(
                            amount > 0 ? Color.green.opacity(0.8) : Color.red.opacity(0.8)
                        )
                } else {
                    Text(" ")
                        .font(.system(size: 9))
                }
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
                        isSelected ? Color.black : Color.black.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 選択日の詳細カード(ダミーデータ)
    
    @ViewBuilder
    private var selectedDayDetail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedDateTitle(for: selectedDate))
                .font(.system(size: 13))
                .foregroundStyle(.black)
            
            if hasData(for: selectedDate) {
                VStack(spacing: 0) {
                    dummyTransactionRow(icon: "fork.knife", title: "食費", amount: -1280)
                    Divider().padding(.leading, 44)
                    dummyTransactionRow(icon: "car", title: "交通費", amount: -420)
                    Divider().padding(.leading, 44)
                    dummyTransactionRow(icon: "yensign.circle", title: "給与", amount: 250000)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                )
            } else {
                Text("この日の記録はありません")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
    }
    
    private func hasData(for date: Date) -> Bool {
        dummyAmount(for: date) != 0
    }
    
    @ViewBuilder
    private func dummyTransactionRow(icon: String, title: String, amount: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.black)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(.black)
            
            Spacer()
            
            Text(amount > 0 ? "+\(amount.formatted())円" : "\(amount.formatted())円")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(amount > 0 ? .green : .red)
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
    
    /// ダミーの金額データ(日付ごとに疑似ランダムだが再現性のある値を生成)
    private func dummyAmount(for date: Date) -> Int {
        let day = calendar.component(.day, from: date)
        // 日付に応じて、それっぽいダミー値を再現性を持って生成
        if day % 5 == 0 {
            return 0 // データなしの日
        } else if day % 7 == 0 {
            return 250000 // 給与日っぽい日
        } else {
            return -((day * 137) % 4000 + 300)
        }
    }
}

#Preview {
    TransactionCalendarView()
}
