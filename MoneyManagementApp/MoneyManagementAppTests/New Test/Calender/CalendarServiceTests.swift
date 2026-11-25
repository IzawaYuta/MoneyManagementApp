//
//  CalendarServiceTests.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/11/21.
//


import Testing
import Foundation
import SwiftData
@testable import MoneyManagementApp 

@MainActor
struct CalendarServiceTests {

    // MARK: - Helper

    /// 実行環境のタイムゾーンに左右されないよう、日本時間のグレゴリオ暦で固定する
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func makeTransaction(
        _ date: Date,
        _ amount: Int,
        _ type: TransactionType = .expense
    ) -> SchemaV2.Transaction {
        SchemaV2.Transaction(date: date, amount: amount, type: type)
    }

    private func summary(_ day: Date, _ items: [SchemaV2.Transaction]) -> CalendarService.DailySummary {
        CalendarService.dailySummary(for: day, in: items, calendar: calendar)
    }

    private func items(_ day: Date, _ items: [SchemaV2.Transaction]) -> [SchemaV2.Transaction] {
        CalendarService.transactions(for: day, in: items, calendar: calendar)
            .sorted {
                if $0.date != $1.date { return $0.date > $1.date }
                return $0.createdAt > $1.createdAt
            }
    }

    // MARK: - 日ごとの合計(dailySummary)

    @Test("記録がない日は、収入も支出も0")
    func summaryEmpty() {
        let result = summary(date(2026, 11, 15), [])

        #expect(result == CalendarService.DailySummary(income: 0, expense: 0))
    }

    @Test("支出が複数あれば、合計される")
    func summarySumsExpenses() {
        let all = [
            makeTransaction(date(2026, 11, 15, 9, 0), 500),
            makeTransaction(date(2026, 11, 15, 12, 0), 1200),
            makeTransaction(date(2026, 11, 15, 20, 0), 300),
        ]

        let result = summary(date(2026, 11, 15), all)

        #expect(result.expense == 2000)
        #expect(result.income == 0)
    }

    @Test("収入と支出は、別々に合計される")
    func summarySeparatesIncomeAndExpense() {
        let all = [
            makeTransaction(date(2026, 11, 25, 10, 0), 250_000, .income),
            makeTransaction(date(2026, 11, 25, 12, 0), 800, .expense),
            makeTransaction(date(2026, 11, 25, 15, 0), 5_000, .income),
            makeTransaction(date(2026, 11, 25, 18, 0), 1_200, .expense),
        ]

        let result = summary(date(2026, 11, 25), all)

        #expect(result.income == 255_000)
        #expect(result.expense == 2_000)
    }

    @Test("収入だけの日は、支出が0")
    func summaryIncomeOnly() {
        let all = [makeTransaction(date(2026, 11, 25), 250_000, .income)]

        let result = summary(date(2026, 11, 25), all)

        #expect(result == CalendarService.DailySummary(income: 250_000, expense: 0))
    }

    @Test("他の日の記録は、合計に含まれない")
    func summaryIgnoresOtherDays() {
        let all = [
            makeTransaction(date(2026, 11, 14, 12, 0), 100),
            makeTransaction(date(2026, 11, 15, 12, 0), 200),
            makeTransaction(date(2026, 11, 16, 12, 0), 400),
        ]

        let result = summary(date(2026, 11, 15), all)

        #expect(result.expense == 200)
    }

    @Test("同じ日なら、時刻が違っても合計され、0:00と23:59も同じ日になる")
    func summaryIncludesWholeDay() {
        let all = [
            makeTransaction(date(2026, 11, 15, 0, 0), 100),
            makeTransaction(date(2026, 11, 15, 12, 30), 200),
            makeTransaction(date(2026, 11, 15, 23, 59), 400),
        ]

        let result = summary(date(2026, 11, 15), all)

        #expect(result.expense == 700)
    }

    @Test("日をまたぐ境界(23:59と翌日0:00)は、別の日として集計される")
    func summarySplitsAtMidnight() {
        let all = [
            makeTransaction(date(2026, 11, 30, 23, 59), 100),
            makeTransaction(date(2026, 12, 1, 0, 0), 200),
        ]

        #expect(summary(date(2026, 11, 30), all).expense == 100)
        #expect(summary(date(2026, 12, 1), all).expense == 200)
    }

    @Test("月をまたいでも、同じ日付(日)の別の月の記録は含まれない")
    func summaryIgnoresSameDayOfOtherMonth() {
        let all = [
            makeTransaction(date(2026, 10, 15), 100),
            makeTransaction(date(2026, 11, 15), 200),
            makeTransaction(date(2026, 12, 15), 400),
        ]

        let result = summary(date(2026, 11, 15), all)

        #expect(result.expense == 200)
    }

    @Test("集計の基準日は、時刻が違っても同じ結果になる")
    func summaryDoesNotDependOnQueryTime() {
        let all = [makeTransaction(date(2026, 11, 15, 12, 0), 500)]

        #expect(summary(date(2026, 11, 15, 0, 0), all).expense == 500)
        #expect(summary(date(2026, 11, 15, 23, 59), all).expense == 500)
    }

    // MARK: - 選択日の記録(transactions(for:))

    @Test("記録がない日は、空の配列")
    func itemsEmpty() {
        #expect(items(date(2026, 11, 15), []).isEmpty)
    }

    @Test("その日の記録だけが返る")
    func itemsOnlyThatDay() {
        let all = [
            makeTransaction(date(2026, 11, 14, 12, 0), 100),
            makeTransaction(date(2026, 11, 15, 12, 0), 200),
            makeTransaction(date(2026, 11, 16, 12, 0), 400),
        ]

        let result = items(date(2026, 11, 15), all)

        #expect(result.map(\.amount) == [200])
    }

    @Test("時刻の新しい順に並ぶ")
    func itemsNewestFirst() {
        let all = [
            makeTransaction(date(2026, 11, 15, 9, 0), 100),
            makeTransaction(date(2026, 11, 15, 20, 0), 300),
            makeTransaction(date(2026, 11, 15, 12, 0), 200),
        ]

        let result = items(date(2026, 11, 15), all)

        #expect(result.map(\.amount) == [300, 200, 100])
    }

    @Test("収入と支出の両方が含まれる")
    func itemsIncludeBothTypes() {
        let all = [
            makeTransaction(date(2026, 11, 25, 9, 0), 250_000, .income),
            makeTransaction(date(2026, 11, 25, 12, 0), 800, .expense),
        ]

        let result = items(date(2026, 11, 25), all)

        #expect(result.count == 2)
    }

    @Test("日をまたぐ境界(23:59と翌日0:00)は、別の日の記録として分けられる")
    func itemsSplitAtMidnight() {
        let all = [
            makeTransaction(date(2026, 11, 30, 23, 59), 100),
            makeTransaction(date(2026, 12, 1, 0, 0), 200),
        ]

        #expect(items(date(2026, 11, 30), all).map(\.amount) == [100])
        #expect(items(date(2026, 12, 1), all).map(\.amount) == [200])
    }

    // MARK: - 月の日付の並び(daysInMonth)

    private func daysInMonth(_ month: Date) -> [Date?] {
        CalendarService.daysInMonth(of: month, calendar: calendar)
    }

    private func leadingEmptyCount(_ days: [Date?]) -> Int {
        days.prefix(while: { $0 == nil }).count
    }

    private func dayNumbers(_ days: [Date?]) -> [Int] {
        days.compactMap { $0 }.map { calendar.component(.day, from: $0) }
    }

    @Test("月初が日曜日なら、先頭の空白は0個(2026年11月・30日)")
    func monthStartingOnSunday() {
        let days = daysInMonth(date(2026, 11, 15))

        #expect(leadingEmptyCount(days) == 0)
        #expect(dayNumbers(days) == Array(1...30))
        #expect(days.count == 30)
    }

    @Test("月初が火曜日なら、先頭に空白が2個入る(2026年12月・31日)")
    func monthStartingOnTuesday() {
        let days = daysInMonth(date(2026, 12, 15))

        #expect(leadingEmptyCount(days) == 2)
        #expect(dayNumbers(days) == Array(1...31))
        #expect(days.count == 33)
    }

    @Test("月初が木曜日なら、先頭に空白が4個入る(2026年10月・31日)")
    func monthStartingOnThursday() {
        let days = daysInMonth(date(2026, 10, 15))

        #expect(leadingEmptyCount(days) == 4)
        #expect(dayNumbers(days) == Array(1...31))
    }

    @Test("うるう年の2月は29日まである(2024年2月)")
    func leapYearFebruary() {
        let days = daysInMonth(date(2024, 2, 10))

        #expect(dayNumbers(days) == Array(1...29))
        #expect(leadingEmptyCount(days) == 4)
    }

    @Test("うるう年でない2月は28日まで(2026年2月)")
    func nonLeapYearFebruary() {
        let days = daysInMonth(date(2026, 2, 10))

        #expect(dayNumbers(days) == Array(1...28))
        #expect(leadingEmptyCount(days) == 0)
    }

    @Test("日付は、各日の0:00で、月初から順に並ぶ")
    func daysAreStartOfDayAndOrdered() throws {
        let days = daysInMonth(date(2026, 12, 20, 15, 45)).compactMap { $0 }

        #expect(days.first == date(2026, 12, 1, 0, 0))
        #expect(days.last == date(2026, 12, 31, 0, 0))
        #expect(days == days.sorted())
    }

    @Test("月の途中の日付を渡しても、同じ月の配列になる")
    func anyDateInMonthGivesSameResult() {
        let fromFirst = daysInMonth(date(2026, 12, 1, 0, 0))
        let fromLast = daysInMonth(date(2026, 12, 31, 23, 59))

        #expect(fromFirst == fromLast)
    }

    @Test("カレンダーの日付で集計した結果が、その日の合計と一致する")
    func summaryMatchesCalendarCell() {
        let all = [
            makeTransaction(date(2026, 12, 3, 10, 0), 1_000),
            makeTransaction(date(2026, 12, 3, 18, 0), 500),
            makeTransaction(date(2026, 12, 4, 9, 0), 300),
        ]
        let days = daysInMonth(date(2026, 12, 1)).compactMap { $0 }

        let dec3 = days.first { calendar.component(.day, from: $0) == 3 }!
        let dec5 = days.first { calendar.component(.day, from: $0) == 5 }!

        #expect(summary(dec3, all).expense == 1_500)
        #expect(summary(dec5, all) == CalendarService.DailySummary(income: 0, expense: 0))
    }
}
