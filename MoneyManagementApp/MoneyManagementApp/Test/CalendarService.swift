//
//  CalendarService.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/11/21.
//


import Foundation

enum CalendarService {

    /// 1日ぶんの収入合計・支出合計
    struct DailySummary: Equatable {
        let income: Int
        let expense: Int
    }

    /// 指定した日付(同じ日)の記録を、時刻の新しい順に返す
    static func transactions(
        for date: Date,
        in transactions: [SchemaV2.Transaction],
        calendar: Calendar = .current
    ) -> [SchemaV2.Transaction] {
        transactions
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    /// 指定した日付の収入合計・支出合計
    static func dailySummary(
        for date: Date,
        in transactions: [SchemaV2.Transaction],
        calendar: Calendar = .current
    ) -> DailySummary {
        let dayItems = transactions
            .filter { calendar.isDate($0.date, inSameDayAs: date) }

        let income = dayItems
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let expense = dayItems
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }

        return DailySummary(income: income, expense: expense)
    }

    /// 指定した月に表示する日付の配列(月初の曜日ぶんは nil で埋める。日曜始まり)
    static func daysInMonth(
        of month: Date,
        calendar: Calendar = .current
    ) -> [Date?] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: month),
            let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else {
            return []
        }

        let leadingEmptyCount = firstWeekday - 1
        let daysCount = calendar.range(of: .day, in: .month, for: month)?.count ?? 0

        var days: [Date?] = Array(repeating: nil, count: leadingEmptyCount)

        for dayOffset in 0..<daysCount {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: monthInterval.start) {
                days.append(date)
            }
        }

        return days
    }
}