//
//  MonthlyChartServiceTests.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/11/21.
//


import Testing
import Foundation
import CoreGraphics
@testable import MoneyManagementApp  // ← Product Module Name に合わせる

@MainActor
struct MonthlyChartServiceTests {

    // MARK: - Helper

    /// 実行環境のタイムゾーンに左右されないよう、日本時間のグレゴリオ暦で固定する
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private let foodID = UUID()
    private let transportID = UUID()
    private let salaryID = UUID()

    private func tx(
        _ date: Date,
        _ amount: Int,
        _ type: TransactionType = .expense,
        categoryID: UUID? = nil,
        name: String? = nil,
        image: String? = nil,
        color: String? = nil
    ) -> SchemaV2.Transaction {
        SchemaV2.Transaction(
            date: date,
            amount: amount,
            type: type,
            categoryID: categoryID,
            categoryName: name,
            categoryImageName: image,
            categoryColorHex: color
        )
    }

    private func summaries(
        _ all: [SchemaV2.Transaction],
        month: Date? = nil,
        type: TransactionType = .expense
    ) -> [CategorySummary] {
        MonthlyChartService.summaries(
            from: all,
            month: month ?? date(2026, 11, 15),
            type: type,
            calendar: calendar
        )
    }

    private func item(_ id: UUID, _ name: String, _ amount: Int) -> CategorySummary {
        CategorySummary(id: id, name: name, imageName: "tray", amount: amount, color: "#000000")
    }

    // MARK: - カテゴリーごとの合計

    @Test("記録がなければ、空の配列")
    func summariesEmpty() {
        #expect(summaries([]).isEmpty)
    }

    @Test("同じカテゴリーの記録は、1つにまとめて合計される")
    func sumsSameCategory() {
        let all = [
            tx(date(2026, 11, 1), 500, categoryID: foodID, name: "食費"),
            tx(date(2026, 11, 10), 1200, categoryID: foodID, name: "食費"),
            tx(date(2026, 11, 20), 300, categoryID: foodID, name: "食費"),
        ]

        let result = summaries(all)

        #expect(result.count == 1)
        #expect(result.first?.amount == 2000)
        #expect(result.first?.id == foodID)
    }

    @Test("カテゴリーごとに別々に集計され、金額の大きい順に並ぶ")
    func sortedByAmountDescending() {
        let all = [
            tx(date(2026, 11, 1), 500, categoryID: transportID, name: "交通費"),
            tx(date(2026, 11, 2), 3000, categoryID: foodID, name: "食費"),
            tx(date(2026, 11, 3), 1000, categoryID: transportID, name: "交通費"),
        ]

        let result = summaries(all)

        #expect(result.map(\.name) == ["食費", "交通費"])
        #expect(result.map(\.amount) == [3000, 1500])
    }

    @Test("金額が同じときは、名前の順に並ぶ")
    func sortedByNameWhenAmountsEqual() {
        let all = [
            tx(date(2026, 11, 1), 1000, categoryID: foodID, name: "B食費"),
            tx(date(2026, 11, 2), 1000, categoryID: transportID, name: "A交通費"),
        ]

        let result = summaries(all)

        #expect(result.map(\.name) == ["A交通費", "B食費"])
    }

    // MARK: - 種別・月の絞り込み

    @Test("選択した種別(支出/収入)の記録だけが集計される")
    func filtersByType() {
        let all = [
            tx(date(2026, 11, 1), 800, .expense, categoryID: foodID, name: "食費"),
            tx(date(2026, 11, 25), 250_000, .income, categoryID: salaryID, name: "給与"),
        ]

        #expect(summaries(all, type: .expense).map(\.name) == ["食費"])
        #expect(summaries(all, type: .income).map(\.name) == ["給与"])
    }

    @Test("選択した月の記録だけが集計される(他の月・他の年の同じ月は除く)")
    func filtersByMonth() {
        let all = [
            tx(date(2026, 10, 15), 100, categoryID: foodID, name: "食費"),
            tx(date(2026, 11, 15), 200, categoryID: foodID, name: "食費"),
            tx(date(2026, 12, 15), 400, categoryID: foodID, name: "食費"),
            tx(date(2025, 11, 15), 800, categoryID: foodID, name: "食費"),
        ]

        let result = summaries(all)

        #expect(result.map(\.amount) == [200])
    }

    @Test("月の境界(11/30 23:59 と 12/1 0:00)は、別の月に入る")
    func monthBoundary() {
        let all = [
            tx(date(2026, 11, 30, 23, 59), 100, categoryID: foodID, name: "食費"),
            tx(date(2026, 12, 1, 0, 0), 200, categoryID: foodID, name: "食費"),
        ]

        #expect(summaries(all, month: date(2026, 11, 1)).map(\.amount) == [100])
        #expect(summaries(all, month: date(2026, 12, 1)).map(\.amount) == [200])
    }

    @Test("月の初日と最終日の記録も、その月に入る")
    func firstAndLastDayAreIncluded() {
        let all = [
            tx(date(2026, 11, 1, 0, 0), 100, categoryID: foodID, name: "食費"),
            tx(date(2026, 11, 30, 23, 59), 200, categoryID: foodID, name: "食費"),
        ]

        let result = summaries(all)

        #expect(result.map(\.amount) == [300])
    }

    // MARK: - カテゴリー未設定・表示内容

    @Test("カテゴリー未設定の記録は、「未分類」にまとめられる")
    func uncategorizedAreGrouped() {
        let all = [
            tx(date(2026, 11, 1), 100),
            tx(date(2026, 11, 2), 200),
        ]

        let result = summaries(all)

        #expect(result.count == 1)
        #expect(result.first?.id == MonthlyChartService.uncategorizedID)
        #expect(result.first?.name == "未分類")
        #expect(result.first?.imageName == "questionmark")
        #expect(result.first?.amount == 300)
    }

    @Test("未分類は、カテゴリーありの記録とは別の行になる")
    func uncategorizedIsSeparateFromCategorized() {
        let all = [
            tx(date(2026, 11, 1), 100),
            tx(date(2026, 11, 2), 500, categoryID: foodID, name: "食費"),
        ]

        let result = summaries(all)

        #expect(result.map(\.name) == ["食費", "未分類"])
    }

    @Test("名前・アイコン・色は、記録に保存されている内容が使われる")
    func usesSnapshotValues() {
        let all = [
            tx(date(2026, 11, 1), 800, categoryID: foodID,
               name: "食費", image: "fork.knife", color: "#FF6B6B"),
        ]

        let result = summaries(all)

        #expect(result.first?.name == "食費")
        #expect(result.first?.imageName == "fork.knife")
        #expect(result.first?.color == "#FF6B6B")
    }

    @Test("色が保存されていない記録は、#111111になる")
    func missingColorFallsBack() {
        let all = [tx(date(2026, 11, 1), 800, categoryID: foodID, name: "食費")]

        let result = summaries(all)

        #expect(result.first?.color == "#111111")
    }

    @Test("【現状の仕様】カテゴリー名を変えた場合、一番古い記録の名前で表示される")
    func nameComesFromOldestTransaction() {
        // View は日付の古い順で渡す(@Query の sort: \.date と同じ)
        let all = [
            tx(date(2026, 11, 1), 500, categoryID: foodID, name: "食費"),
            tx(date(2026, 11, 20), 700, categoryID: foodID, name: "外食"),
        ]

        let result = summaries(all)

        #expect(result.count == 1)
        #expect(result.first?.name == "食費")
        #expect(result.first?.amount == 1200)
    }

    @Test("金額0の記録も、集計に含まれる")
    func zeroAmountIsIncluded() {
        let all = [tx(date(2026, 11, 1), 0, categoryID: foodID, name: "食費")]

        let result = summaries(all)

        #expect(result.count == 1)
        #expect(result.first?.amount == 0)
    }

    // MARK: - 合計

    @Test("合計は、全カテゴリーの金額の合計")
    func totalOfItems() {
        let items = [item(foodID, "食費", 3000), item(transportID, "交通費", 1500)]

        #expect(MonthlyChartService.total(of: items) == 4500)
    }

    @Test("カテゴリーがなければ、合計は0")
    func totalOfEmpty() {
        #expect(MonthlyChartService.total(of: []) == 0)
    }

    // MARK: - 角度からカテゴリーを求める

    @Test("角度に対応する累計金額から、カテゴリーが決まる")
    func categoryAtValue() {
        let items = [item(foodID, "食費", 300), item(transportID, "交通費", 100)]

        #expect(MonthlyChartService.categoryID(at: 0, items: items) == foodID)
        #expect(MonthlyChartService.categoryID(at: 150, items: items) == foodID)
        #expect(MonthlyChartService.categoryID(at: 350, items: items) == transportID)
    }

    @Test("境目ちょうどの値は、手前のカテゴリーになる")
    func categoryAtBoundary() {
        let items = [item(foodID, "食費", 300), item(transportID, "交通費", 100)]

        #expect(MonthlyChartService.categoryID(at: 300, items: items) == foodID)
        #expect(MonthlyChartService.categoryID(at: 400, items: items) == transportID)
    }

    @Test("合計を超える値や、カテゴリーが空のときは nil")
    func categoryOutOfRange() {
        let items = [item(foodID, "食費", 300)]

        #expect(MonthlyChartService.categoryID(at: 301, items: items) == nil)
        #expect(MonthlyChartService.categoryID(at: 0, items: []) == nil)
    }

    // MARK: - 選択時の見た目(半径・濃さ)

    @Test("未選択のときは、半径0.9・濃さ1.0")
    func styleWhenNothingSelected() {
        #expect(MonthlyChartService.radiusRatio(for: foodID, selectedID: nil) == 0.9)
        #expect(MonthlyChartService.opacity(for: foodID, selectedID: nil) == 1.0)
    }

    @Test("選択中のカテゴリーは、半径1.0・濃さ1.0")
    func styleOfSelected() {
        #expect(MonthlyChartService.radiusRatio(for: foodID, selectedID: foodID) == 1.0)
        #expect(MonthlyChartService.opacity(for: foodID, selectedID: foodID) == 1.0)
    }

    @Test("選択されていないカテゴリーは、半径0.8・濃さ0.3")
    func styleOfNotSelected() {
        #expect(MonthlyChartService.radiusRatio(for: transportID, selectedID: foodID) == 0.8)
        #expect(MonthlyChartService.opacity(for: transportID, selectedID: foodID) == 0.3)
    }

    // MARK: - 割合の表示

    @Test("割合が小数第1位まで表示される")
    func percentText() {
        #expect(MonthlyChartService.percentText(amount: 1, total: 8) == "12.5%")
        #expect(MonthlyChartService.percentText(amount: 1, total: 3) == "33.3%")
        #expect(MonthlyChartService.percentText(amount: 5, total: 5) == "100.0%")
    }

    @Test("合計が0のときは、nanではなく0.0%になる")
    func percentTextWithZeroTotal() {
        #expect(MonthlyChartService.percentText(amount: 0, total: 0) == "0.0%")
    }

    // MARK: - タップの判定

    // 円の中心(100, 100)・半径100。食費300(75%)・交通費100(25%)
    // 12時方向から時計回りに、食費は0〜75%、交通費は75〜100%(左上)
    private let center = CGPoint(x: 100, y: 100)
    private var items: [CategorySummary] {
        [item(foodID, "食費", 300), item(transportID, "交通費", 100)]
    }

    private func tap(dx: CGFloat, dy: CGFloat, selectedID: UUID? = nil) -> UUID? {
        MonthlyChartService.tappedCategoryID(
            at: CGPoint(x: center.x + dx, y: center.y + dy),
            center: center,
            fullRadius: 100,
            items: items,
            selectedID: selectedID
        )
    }

    @Test("右上(時計回り12.5%)をタップすると、食費")
    func tapUpperRight() {
        #expect(tap(dx: 30, dy: -30) == foodID)
    }

    @Test("右(25%)・下(50%)をタップしても、食費")
    func tapRightAndBottom() {
        #expect(tap(dx: 50, dy: 0) == foodID)
        #expect(tap(dx: 0, dy: 50) == foodID)
    }

    @Test("左上(時計回り87.5%)をタップすると、交通費")
    func tapUpperLeft() {
        #expect(tap(dx: -30, dy: -30) == transportID)
    }

    @Test("未選択のときは、半径90の内側だけ反応し、外側の余白は無視される")
    func tapRadiusWhenNothingSelected() {
        #expect(tap(dx: 85, dy: 0) == foodID)
        #expect(tap(dx: 95, dy: 0) == nil)
    }

    @Test("選択中のカテゴリーは半径100まで反応する")
    func tapRadiusOfSelected() {
        #expect(tap(dx: 95, dy: 0, selectedID: foodID) == foodID)
    }

    @Test("選択されていないカテゴリーは、半径80までしか反応しない")
    func tapRadiusOfNotSelected() {
        // 左上、中心からの距離 約84.9(80より外)
        #expect(tap(dx: -60, dy: -60, selectedID: foodID) == nil)
        // 左上、中心からの距離 約70(80より内)
        #expect(tap(dx: -49.5, dy: -49.5, selectedID: foodID) == transportID)
    }

    @Test("カテゴリーが空のときは、タップしても nil")
    func tapWithNoItems() {
        let result = MonthlyChartService.tappedCategoryID(
            at: CGPoint(x: 150, y: 100),
            center: center,
            fullRadius: 100,
            items: [],
            selectedID: nil
        )

        #expect(result == nil)
    }
}