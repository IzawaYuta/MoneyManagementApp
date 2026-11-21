
import Testing
import Foundation
import SwiftData
@testable import MoneyManagementApp

// MARK: - 予算の基本部品(期間の判定・年月・表示)

@MainActor
struct BudgetBasicsTests {

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }

    private func makeBudget(_ start: Int, _ end: Int? = nil) -> Budget {
        Budget(categoryID: UUID(), type: .expense, amount: 1000, startMonth: start, endMonth: end)
    }
    
    // MARK: 適用期間の判定(contains)

    @Test("開始月より前の月は、含まれない")
    func containsBeforeStart() {
        #expect(!makeBudget(202611, 202612).contains(month: 202610))
    }

    @Test("開始月は、含まれる")
    func containsStart() {
        #expect(makeBudget(202611, 202612).contains(month: 202611))
    }

    @Test("終了月は、含まれる(終了月を含む)")
    func containsEnd() {
        #expect(makeBudget(202611, 202612).contains(month: 202612))
    }

    @Test("終了月より後の月は、含まれない")
    func containsAfterEnd() {
        #expect(!makeBudget(202611, 202612).contains(month: 202701))
    }

    @Test("終了月がnilなら、開始月以降ずっと含まれる")
    func containsOpenEnded() {
        let b = makeBudget(202611, nil)

        #expect(b.contains(month: 202611))
        #expect(b.contains(month: 203512))
        #expect(!b.contains(month: 202610))
    }

    @Test("開始月と終了月が同じなら、その1か月だけ含まれる")
    func containsSingleMonth() {
        let b = makeBudget(202611, 202611)

        #expect(!b.contains(month: 202610))
        #expect(b.contains(month: 202611))
        #expect(!b.contains(month: 202612))
    }

    @Test("年をまたぐ期間(2025年12月〜2026年1月)も判定できる")
    func containsAcrossYear() {
        let b = makeBudget(202512, 202601)

        #expect(!b.contains(month: 202511))
        #expect(b.contains(month: 202512))
        #expect(b.contains(month: 202601))
        #expect(!b.contains(month: 202602))
    }

    // MARK: 年月(YearMonth)

    @Test("日付から、yyyymm の数値が作られる")
    func makeFromDate() {
        #expect(YearMonth.make(from: date(2026, 11, 15), calendar: calendar) == 202611)
        #expect(YearMonth.make(from: date(2026, 1, 1), calendar: calendar) == 202601)
    }

    @Test("前月を求められる")
    func previousMonth() {
        #expect(YearMonth.previous(202611) == 202610)
    }

    @Test("1月の前月は、前年の12月")
    func previousAcrossYear() {
        #expect(YearMonth.previous(202601) == 202512)
    }

    @Test("翌月を求められる")
    func nextMonth() {
        #expect(YearMonth.next(202611) == 202612)
    }

    @Test("12月の翌月は、翌年の1月")
    func nextAcrossYear() {
        #expect(YearMonth.next(202512) == 202601)
    }

    @Test("表示用の文字列になる(月の0埋めなし)")
    func label() {
        #expect(YearMonth.label(202611) == "2026年11月")
        #expect(YearMonth.label(202601) == "2026年1月")
    }

    @Test("月の範囲は、月初の0:00から翌月初の0:00まで")
    func dateRange() {
        let range = YearMonth.dateRange(202611, calendar: calendar)

        #expect(range.lowerBound == date(2026, 11, 1))
        #expect(range.upperBound == date(2026, 12, 1))
    }

    @Test("12月の範囲の終わりは、翌年の1月1日")
    func dateRangeDecember() {
        let range = YearMonth.dateRange(202612, calendar: calendar)

        #expect(range.lowerBound == date(2026, 12, 1))
        #expect(range.upperBound == date(2027, 1, 1))
    }

    // MARK: バーの割合

    @Test("予算が0以下のときは、使用額に関係なく0")
    func ratioWithZeroBudget() {
        #expect(budgetRemainingRatio(budget: 0, spent: 0) == 0)
        #expect(budgetRemainingRatio(budget: 0, spent: 500) == 0)
        #expect(budgetRemainingRatio(budget: -100, spent: 0) == 0)
    }

    @Test("使っていなければ1、半分使えば0.5")
    func ratioNormal() {
        #expect(budgetRemainingRatio(budget: 1000, spent: 0) == 1)
        #expect(budgetRemainingRatio(budget: 1000, spent: 500) == 0.5)
        #expect(budgetRemainingRatio(budget: 1000, spent: 250) == 0.75)
    }

    @Test("使い切った・超過したときは、0(空のバー)")
    func ratioWhenUsedUpOrOver() {
        #expect(budgetRemainingRatio(budget: 1000, spent: 1000) == 0)
        #expect(budgetRemainingRatio(budget: 1000, spent: 1500) == 0)
    }

    // MARK: 金額の表示

    @Test("金額は、¥とカンマ区切りで表示される")
    func yenFormat() {
        #expect(budgetYen(1234) == "¥1,234")
        #expect(budgetYen(0) == "¥0")
    }

    @Test("【現状の仕様】マイナスの金額は、「+¥」で表示される(超過額の表示)")
    func yenNegative() {
        #expect(budgetYen(-500) == "+¥500")
    }

    // MARK: 適用期間の表示

    @Test("予算がなければ、nil")
    func periodTextNil() {
        #expect(BudgetService.periodText(of: nil) == nil)
    }

    @Test("単月の予算は、「〇年〇月のみ」")
    func periodTextSingle() {
        #expect(BudgetService.periodText(of: makeBudget(202611, 202611)) == "2026年11月のみ")
    }

    @Test("期間のある予算は、「開始〜終了」")
    func periodTextRange() {
        #expect(BudgetService.periodText(of: makeBudget(202611, 202612)) == "2026年11月〜2026年12月")
    }

    @Test("終了のない予算は、「開始〜」")
    func periodTextOpenEnded() {
        #expect(BudgetService.periodText(of: makeBudget(202611, nil)) == "2026年11月〜")
    }
}

// MARK: - 予算の更新ルール・行データ・合計

@MainActor
struct BudgetServiceTests {

    // MARK: - Helper

    private let foodID = UUID()
    private let transportID = UUID()
    private let funID = UUID()

    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func budget(
        _ id: UUID, _ amount: Int, _ start: Int, _ end: Int? = nil,
        type: TransactionType = .expense,
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> Budget {
        Budget(
            categoryID: id, type: type, amount: amount,
            startMonth: start, endMonth: end,
            createdAt: updatedAt, updatedAt: updatedAt
        )
    }

    /// DBに予算を1行入れる(カテゴリーを指定する)
    @discardableResult
    private func seed(
        _ context: ModelContext, _ id: UUID, _ amount: Int, _ start: Int, _ end: Int? = nil,
        type: TransactionType = .expense
    ) throws -> Budget {
        let b = budget(id, amount, start, end, type: type)
        context.insert(b)
        try context.save()
        return b
    }
    
    /// DBに予算を1行入れる(カテゴリーは食費)
    @discardableResult
    private func seed(
        _ context: ModelContext, _ amount: Int, _ start: Int, _ end: Int? = nil,
        type: TransactionType = .expense
    ) throws -> Budget {
        try seed(context, foodID, amount, start, end, type: type)
    }
    
    private func apply(
        _ context: ModelContext, _ amount: Int, _ month: Int, _ scope: BudgetScope, id: UUID? = nil
    ) throws {
        try BudgetService.apply(
            amount: amount, categoryID: id ?? foodID, type: .expense,
            month: month, scope: scope, context: context
        )
    }

    private func fetchRows(
        _ context: ModelContext, id: UUID? = nil, type: TransactionType = .expense
    ) throws -> [Budget] {
        try context.fetch(FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.startMonth)]))
            .filter { $0.categoryID == (id ?? foodID) && $0.type == type }
    }

    /// 行の並びを「開始-終了:金額」の文字列にする(終了がnilなら空)
    private func shape(
        _ context: ModelContext, id: UUID? = nil, type: TransactionType = .expense
    ) throws -> [String] {
        try fetchRows(context, id: id, type: type).map {
            "\($0.startMonth)-\($0.endMonth.map(String.init) ?? ""):\($0.amount)"
        }
    }

    // MARK: - applied(月に適用される予算)

    @Test("予算がなければ、nil")
    func appliedEmpty() {
        #expect(BudgetService.applied(in: [], type: .expense, month: 202611) == nil)
    }

    @Test("対象月が期間に入っている予算が返る")
    func appliedSingle() {
        let b = budget(foodID, 30000, 202610, 202612)

        let result = BudgetService.applied(in: [b], type: .expense, month: 202611)

        #expect(result?.amount == 30000)
    }

    @Test("対象月が期間の外なら、nil")
    func appliedOutOfRange() {
        let b = budget(foodID, 30000, 202610, 202612)

        #expect(BudgetService.applied(in: [b], type: .expense, month: 202609) == nil)
        #expect(BudgetService.applied(in: [b], type: .expense, month: 202701) == nil)
    }

    @Test("種別(収入/支出)が違う予算は、返らない")
    func appliedFiltersByType() {
        let income = budget(foodID, 99999, 202610, type: .income)

        #expect(BudgetService.applied(in: [income], type: .expense, month: 202611) == nil)
        #expect(BudgetService.applied(in: [income], type: .income, month: 202611)?.amount == 99999)
    }

    @Test("期間が重なっているときは、開始月が新しい方が使われる")
    func appliedPrefersNewerStartMonth() {
        let old = budget(foodID, 1000, 202601)
        let new = budget(foodID, 2000, 202610)

        #expect(BudgetService.applied(in: [old, new], type: .expense, month: 202611)?.amount == 2000)
        #expect(BudgetService.applied(in: [new, old], type: .expense, month: 202611)?.amount == 2000)
    }

    @Test("開始月も同じなら、更新日時が新しい方が使われる")
    func appliedPrefersNewerUpdatedAt() {
        let old = budget(foodID, 1000, 202610, updatedAt: Date(timeIntervalSince1970: 100))
        let new = budget(foodID, 2000, 202610, updatedAt: Date(timeIntervalSince1970: 200))

        #expect(BudgetService.applied(in: [old, new], type: .expense, month: 202611)?.amount == 2000)
        #expect(BudgetService.applied(in: [new, old], type: .expense, month: 202611)?.amount == 2000)
    }

    // MARK: - apply: この月以降すべて

    @Test("この月以降すべて: 予算がなければ、終了なしの行が1つ追加される")
    func fromThisMonthWithNoExisting() throws {
        let context = try makeContext()

        try apply(context, 30000, 202611, .fromThisMonth)

        #expect(try shape(context) == ["202611-:30000"])
    }

    @Test("この月以降すべて: 前の月から続く予算は、前月で終わり、新しい行が始まる")
    func fromThisMonthSplitsOpenEnded() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610)

        try apply(context, 40000, 202611, .fromThisMonth)

        #expect(try shape(context) == ["202610-202610:30000", "202611-:40000"])
    }

    @Test("この月以降すべて: この月から始まる行は、置き換えられる")
    func fromThisMonthReplacesRowStartingThisMonth() throws {
        let context = try makeContext()
        try seed(context, 30000, 202611)

        try apply(context, 40000, 202611, .fromThisMonth)

        #expect(try shape(context) == ["202611-:40000"])
    }

    @Test("この月以降すべて: 以降に設定済みの個別の行は、削除される")
    func fromThisMonthDeletesFutureRows() throws {
        let context = try makeContext()
        try seed(context, 10000, 202701, 202701)
        try seed(context, 5000, 202703)

        try apply(context, 40000, 202611, .fromThisMonth)

        #expect(try shape(context) == ["202611-:40000"])
    }

    @Test("この月以降すべて: 前月までに終わっている行は、そのまま残る")
    func fromThisMonthKeepsPastRows() throws {
        let context = try makeContext()
        try seed(context, 10000, 202609, 202610)

        try apply(context, 40000, 202611, .fromThisMonth)

        #expect(try shape(context) == ["202609-202610:10000", "202611-:40000"])
    }

    @Test("この月以降すべて: 期間の途中の月から変えると、元の終了月は無くなり終了なしになる")
    func fromThisMonthDropsOldEnd() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610, 202612)

        try apply(context, 40000, 202611, .fromThisMonth)

        #expect(try shape(context) == ["202610-202610:30000", "202611-:40000"])
    }

    @Test("この月以降すべて: 他のカテゴリーと、収入の予算には影響しない")
    func fromThisMonthDoesNotAffectOthers() throws {
        let context = try makeContext()
        try seed(context, transportID, 7000, 202610)
        try seed(context, 9000, 202610, type: .income)

        try apply(context, 40000, 202611, .fromThisMonth)

        #expect(try shape(context, id: transportID) == ["202610-:7000"])
        #expect(try shape(context, type: .income) == ["202610-:9000"])
        #expect(try shape(context) == ["202611-:40000"])
    }

    // MARK: - apply: この月のみ

    @Test("この月のみ: その月に予算がなければ、単月の行が追加される")
    func thisMonthOnlyWithNoExisting() throws {
        let context = try makeContext()

        try apply(context, 5000, 202611, .thisMonthOnly)

        #expect(try shape(context) == ["202611-202611:5000"])
    }

    @Test("この月のみ: 金額が同じなら、何も変わらない")
    func thisMonthOnlySameAmount() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610)

        try apply(context, 30000, 202611, .thisMonthOnly)

        #expect(try shape(context) == ["202610-:30000"])
    }

    @Test("この月のみ: 前の月から続く予算は、前・この月・後ろの3行に分かれる")
    func thisMonthOnlySplitsIntoThree() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610)

        try apply(context, 5000, 202611, .thisMonthOnly)

        #expect(try shape(context) == [
            "202610-202610:30000",
            "202611-202611:5000",
            "202612-:30000"
        ])
    }

    @Test("この月のみ: この月から始まる終了なしの行は、単月の行と、翌月からの行に分かれる")
    func thisMonthOnlyOnRowStartingThisMonth() throws {
        let context = try makeContext()
        try seed(context, 30000, 202611)

        try apply(context, 5000, 202611, .thisMonthOnly)

        #expect(try shape(context) == ["202611-202611:5000", "202612-:30000"])
    }

    @Test("この月のみ: 単月の行は、金額だけが変わる")
    func thisMonthOnlyOnSingleMonthRow() throws {
        let context = try makeContext()
        try seed(context, 30000, 202611, 202611)

        try apply(context, 5000, 202611, .thisMonthOnly)

        #expect(try shape(context) == ["202611-202611:5000"])
    }

    @Test("この月のみ: 期間の真ん中の月を変えると、前・この月・後ろの3行になり、元の終了月は保たれる")
    func thisMonthOnlyInMiddleOfRange() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610, 202612)

        try apply(context, 5000, 202611, .thisMonthOnly)

        #expect(try shape(context) == [
            "202610-202610:30000",
            "202611-202611:5000",
            "202612-202612:30000"
        ])
    }

    @Test("この月のみ: 期間の最後の月を変えると、後ろの行は作られない")
    func thisMonthOnlyAtEndOfRange() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610, 202611)

        try apply(context, 5000, 202611, .thisMonthOnly)

        #expect(try shape(context) == ["202610-202610:30000", "202611-202611:5000"])
    }

    @Test("この月のみ: 期間の最初の月を変えると、前の行は作られない")
    func thisMonthOnlyAtStartOfRange() throws {
        let context = try makeContext()
        try seed(context, 30000, 202611, 202612)

        try apply(context, 5000, 202611, .thisMonthOnly)

        #expect(try shape(context) == ["202611-202611:5000", "202612-202612:30000"])
    }

    @Test("この月のみ: 年をまたぐ場合(2026年1月)も、前月・翌月が正しく計算される")
    func thisMonthOnlyAcrossYear() throws {
        let context = try makeContext()
        try seed(context, 30000, 202512)

        try apply(context, 5000, 202601, .thisMonthOnly)

        #expect(try shape(context) == [
            "202512-202512:30000",
            "202601-202601:5000",
            "202602-:30000"
        ])
    }
    
    // MARK: - apply: 0円で保存(未設定)
    
    @Test("この月以降すべて: 0で保存すると、前月で終わり、この月以降は未設定になる")
    func zeroFromThisMonth() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610)
        
        try apply(context, 0, 202611, .fromThisMonth)
        
        let rows = try fetchRows(context)
        #expect(try shape(context) == ["202610-202610:30000"])
        #expect(BudgetService.applied(in: rows, type: .expense, month: 202611) == nil)
        #expect(BudgetService.applied(in: rows, type: .expense, month: 203001) == nil)
    }
    
    @Test("この月以降すべて: 0で保存すると、以降の個別の行も削除される")
    func zeroFromThisMonthDeletesFutureRows() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610)
        try seed(context, 10000, 202701, 202701)
        
        try apply(context, 0, 202611, .fromThisMonth)
        
        #expect(try shape(context) == ["202610-202610:30000"])
    }
    
    @Test("この月以降すべて: 予算がない月に0で保存しても、何も作られない")
    func zeroFromThisMonthWithNoExisting() throws {
        let context = try makeContext()
        
        try apply(context, 0, 202611, .fromThisMonth)
        
        #expect(try shape(context).isEmpty)
    }
    
    @Test("この月のみ: 0で保存すると、この月だけが未設定になり、前後の月は元の金額のまま")
    func zeroThisMonthOnly() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610)
        
        try apply(context, 0, 202611, .thisMonthOnly)
        
        let rows = try fetchRows(context)
        #expect(try shape(context) == ["202610-202610:30000", "202612-:30000"])
        #expect(BudgetService.applied(in: rows, type: .expense, month: 202610)?.amount == 30000)
        #expect(BudgetService.applied(in: rows, type: .expense, month: 202611) == nil)
        #expect(BudgetService.applied(in: rows, type: .expense, month: 202612)?.amount == 30000)
    }
    
    @Test("この月のみ: この月から始まる行を0にすると、その行は消え、翌月以降の行が残る")
    func zeroThisMonthOnlyOnRowStartingThisMonth() throws {
        let context = try makeContext()
        try seed(context, 30000, 202611)
        
        try apply(context, 0, 202611, .thisMonthOnly)
        
        #expect(try shape(context) == ["202612-:30000"])
    }
    
    @Test("この月のみ: 単月の行を0にすると、その行が消える")
    func zeroThisMonthOnlyOnSingleMonthRow() throws {
        let context = try makeContext()
        try seed(context, 30000, 202611, 202611)
        
        try apply(context, 0, 202611, .thisMonthOnly)
        
        #expect(try shape(context).isEmpty)
    }
    
    @Test("この月のみ: 期間の真ん中の月を0にすると、前と後ろの2行に分かれる")
    func zeroThisMonthOnlyInMiddleOfRange() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610, 202612)
        
        try apply(context, 0, 202611, .thisMonthOnly)
        
        #expect(try shape(context) == ["202610-202610:30000", "202612-202612:30000"])
    }
    
    @Test("この月のみ: 予算がない月に0で保存しても、何も作られない")
    func zeroThisMonthOnlyWithNoExisting() throws {
        let context = try makeContext()
        
        try apply(context, 0, 202611, .thisMonthOnly)
        
        #expect(try shape(context).isEmpty)
    }
    
    @Test("0円で保存したあと、金額を入れて保存し直せる")
    func setAgainAfterZero() throws {
        let context = try makeContext()
        try seed(context, 30000, 202610)
        try apply(context, 0, 202611, .fromThisMonth)
        
        try apply(context, 20000, 202611, .fromThisMonth)
        
        #expect(try shape(context) == ["202610-202610:30000", "202611-:20000"])
    }

    // MARK: - apply: 続けて変更したとき

    @Test("続けて変更しても、どの月にも予算が1つだけ適用され、期間は重ならない")
    func sequenceKeepsNoOverlap() throws {
        let context = try makeContext()

        try apply(context, 30000, 202611, .fromThisMonth)
        try apply(context, 50000, 202612, .thisMonthOnly)
        try apply(context, 20000, 202701, .fromThisMonth)

        let rows = try fetchRows(context)
        for m in [202611, 202612, 202701, 202702, 202703] {
            #expect(rows.filter { $0.contains(month: m) }.count == 1)
        }
        #expect(rows.filter { $0.contains(month: 202610) }.isEmpty)

        #expect(BudgetService.applied(in: rows, type: .expense, month: 202611)?.amount == 30000)
        #expect(BudgetService.applied(in: rows, type: .expense, month: 202612)?.amount == 50000)
        #expect(BudgetService.applied(in: rows, type: .expense, month: 202701)?.amount == 20000)
        #expect(BudgetService.applied(in: rows, type: .expense, month: 202702)?.amount == 20000)
    }

    @Test("後から「この月以降すべて」で変更すると、以降の個別の変更は上書きされる")
    func laterFromThisMonthOverwritesIndividualChanges() throws {
        let context = try makeContext()
        try seed(context, 30000, 202611, 202611)
        try seed(context, 50000, 202612, 202612)
        try seed(context, 20000, 202701)

        try apply(context, 10000, 202612, .fromThisMonth)

        #expect(try shape(context) == ["202611-202611:30000", "202612-:10000"])
    }

    // MARK: - removeBudgets(カテゴリー削除時の整理)

    /// 本番どおり、呼び出し側が最後に保存する
    private func remove(_ context: ModelContext, _ id: UUID, from month: Int) throws {
        try BudgetService.removeBudgets(categoryID: id, fromMonth: month, context: context)
        try context.save()
    }

    @Test("削除月以降に始まる予算は、削除される")
    func removeDeletesFutureRows() throws {
        let context = try makeContext()
        try seed(context, 1000, 202611, 202611)
        try seed(context, 2000, 202612)

        try remove(context, foodID, from: 202611)

        #expect(try shape(context).isEmpty)
    }

    @Test("削除月をまたぐ予算は、前月で終わる(削除月以降の分は無くなる)")
    func removeEndsSpanningRow() throws {
        let context = try makeContext()
        try seed(context, 1000, 202610)
        try seed(context, 2000, 202609, 202612)

        try remove(context, foodID, from: 202611)

        #expect(try shape(context) == ["202609-202610:2000", "202610-202610:1000"])
    }

    @Test("過去の月で終わっている予算は、残る")
    func removeKeepsPastRows() throws {
        let context = try makeContext()
        try seed(context, 1000, 202609, 202610)

        try remove(context, foodID, from: 202611)

        #expect(try shape(context) == ["202609-202610:1000"])
    }

    @Test("他のカテゴリーの予算には、影響しない")
    func removeDoesNotAffectOtherCategories() throws {
        let context = try makeContext()
        try seed(context, transportID, 7000, 202611)

        try remove(context, foodID, from: 202611)

        #expect(try shape(context, id: transportID) == ["202611-:7000"])
    }

    @Test("年をまたぐ場合(2026年1月に削除)も、前月は2025年12月になる")
    func removeAcrossYear() throws {
        let context = try makeContext()
        try seed(context, 1000, 202512)

        try remove(context, foodID, from: 202601)

        #expect(try shape(context) == ["202512-202512:1000"])
    }

    // MARK: - rows(カテゴリー別の行データ)

    private func category(
        _ id: UUID, _ name: String, _ image: String = "tray", _ color: String = "#4DABF7", sort: Int = 0
    ) -> Category {
        let c = Category(name: name, imageName: image, colorHex: color, sortIndex: sort)
        c.id = id
        return c
    }

    private func spend(
        _ categoryID: UUID?, _ amount: Int, _ type: TransactionType = .expense,
        name: String? = nil, image: String? = nil, color: String? = nil
    ) -> SchemaV2.Transaction {
        SchemaV2.Transaction(
            date: Date(), amount: amount, type: type,
            categoryID: categoryID, categoryName: name,
            categoryImageName: image, categoryColorHex: color
        )
    }

    private func makeRows(
        budgets: [Budget], categories: [Category], transactions: [SchemaV2.Transaction] = [],
        month: Int = 202611
    ) -> [BudgetRow] {
        BudgetService.rows(
            budgets: budgets, categories: categories, transactions: transactions,
            month: month, type: .expense
        )
    }

    @Test("予算がなければ、行も空")
    func rowsEmpty() {
        #expect(makeRows(budgets: [], categories: [category(foodID, "食費")]).isEmpty)
    }

    @Test("その月に適用される予算のカテゴリーだけが、行になる")
    func rowsOnlyAppliedBudgets() {
        let budgets = [
            budget(foodID, 30000, 202611),
            budget(transportID, 10000, 202601, 202610),   // 前月で終了
            budget(funID, 5000, 202612),                  // 翌月から開始
        ]
        let categories = [category(foodID, "食費"), category(transportID, "交通費"), category(funID, "娯楽")]

        let rows = makeRows(budgets: budgets, categories: categories)

        #expect(rows.map(\.id) == [foodID])
    }

    @Test("カテゴリーの名前・アイコン・色と、予算額が入る")
    func rowsContainCategoryInfo() throws {
        let rows = makeRows(
            budgets: [budget(foodID, 30000, 202611)],
            categories: [category(foodID, "食費", "fork.knife", "#FF6B6B", sort: 3)]
        )

        let row = try #require(rows.first)
        #expect(row.name == "食費")
        #expect(row.imageName == "fork.knife")
        #expect(row.colorHex == "#FF6B6B")
        #expect(row.budget == 30000)
        #expect(row.sortIndex == 3)
    }

    @Test("カテゴリーのsortIndex順に並び、同じなら名前順")
    func rowsSorted() {
        let budgets = [budget(foodID, 1, 202611), budget(transportID, 1, 202611), budget(funID, 1, 202611)]
        let categories = [
            category(foodID, "B食費", sort: 1),
            category(transportID, "C交通費", sort: 0),
            category(funID, "A娯楽", sort: 1),
        ]

        let rows = makeRows(budgets: budgets, categories: categories)

        #expect(rows.map(\.name) == ["C交通費", "A娯楽", "B食費"])
    }

    @Test("使用額は、そのカテゴリーの支出の合計")
    func rowsSpentIsSumOfExpenses() {
        let budgets = [budget(foodID, 30000, 202611), budget(transportID, 10000, 202611)]
        let categories = [category(foodID, "食費", sort: 0), category(transportID, "交通費", sort: 1)]
        let transactions = [spend(foodID, 1000), spend(foodID, 2500), spend(transportID, 400)]

        let rows = makeRows(budgets: budgets, categories: categories, transactions: transactions)

        #expect(rows.map(\.spent) == [3500, 400])
    }

    @Test("収入の記録は、使用額に含まれない")
    func rowsIgnoreIncome() {
        let rows = makeRows(
            budgets: [budget(foodID, 30000, 202611)],
            categories: [category(foodID, "食費")],
            transactions: [spend(foodID, 1000), spend(foodID, 9000, .income)]
        )

        #expect(rows.first?.spent == 1000)
    }

    @Test("記録のないカテゴリーは、使用額0で残りは予算と同じ")
    func rowsWithoutTransactions() {
        let rows = makeRows(
            budgets: [budget(foodID, 30000, 202611)],
            categories: [category(foodID, "食費")]
        )

        #expect(rows.first?.spent == 0)
        #expect(rows.first?.remaining == 30000)
        #expect(rows.first?.isOver == false)
    }

    @Test("予算のないカテゴリーの記録は、行にならない")
    func rowsIgnoreCategoriesWithoutBudget() {
        let rows = makeRows(
            budgets: [budget(foodID, 30000, 202611)],
            categories: [category(foodID, "食費"), category(transportID, "交通費")],
            transactions: [spend(transportID, 5000)]
        )

        #expect(rows.map(\.id) == [foodID])
    }

    @Test("カテゴリー未設定の記録は、どの行の使用額にも入らない")
    func rowsIgnoreUncategorizedTransactions() {
        let rows = makeRows(
            budgets: [budget(foodID, 30000, 202611)],
            categories: [category(foodID, "食費")],
            transactions: [spend(nil, 5000)]
        )

        #expect(rows.first?.spent == 0)
    }

    @Test("予算を超えると、残りはマイナスで超過になる。ちょうど使い切りは超過ではない")
    func rowsOverBudget() {
        let over = makeRows(
            budgets: [budget(foodID, 1000, 202611)],
            categories: [category(foodID, "食費")],
            transactions: [spend(foodID, 1500)]
        )
        let exact = makeRows(
            budgets: [budget(foodID, 1000, 202611)],
            categories: [category(foodID, "食費")],
            transactions: [spend(foodID, 1000)]
        )

        #expect(over.first?.remaining == -500)
        #expect(over.first?.isOver == true)
        #expect(exact.first?.remaining == 0)
        #expect(exact.first?.isOver == false)
    }

    @Test("バーの割合(残りの割合)が、行から求められる")
    func rowsRemainingRatio() {
        let rows = makeRows(
            budgets: [budget(foodID, 1000, 202611)],
            categories: [category(foodID, "食費")],
            transactions: [spend(foodID, 250)]
        )

        #expect(rows.first?.remainingRatio == 0.75)
    }

    @Test("削除済みのカテゴリーは、記録に保存された名前・アイコン・色が使われる")
    func rowsDeletedCategoryUsesSnapshot() throws {
        let rows = makeRows(
            budgets: [budget(foodID, 30000, 202611)],
            categories: [],
            transactions: [spend(foodID, 800, name: "食費", image: "fork.knife", color: "#FF6B6B")]
        )

        let row = try #require(rows.first)
        #expect(row.name == "食費")
        #expect(row.imageName == "fork.knife")
        #expect(row.colorHex == "#FF6B6B")
        #expect(row.spent == 800)
        #expect(row.sortIndex == Int.max)
    }

    @Test("削除済みで記録もないカテゴリーは、「削除済みのカテゴリー」と表示される")
    func rowsDeletedCategoryWithoutTransactions() throws {
        let rows = makeRows(budgets: [budget(foodID, 30000, 202611)], categories: [])

        let row = try #require(rows.first)
        #expect(row.name == "削除済みのカテゴリー")
        #expect(row.imageName == "questionmark.circle")
        #expect(row.colorHex == "#9E9E9E")
        #expect(row.spent == 0)
    }

    @Test("削除済みのカテゴリーは、通常のカテゴリーの後ろに並ぶ")
    func rowsDeletedCategoryComesLast() {
        let rows = makeRows(
            budgets: [budget(foodID, 1, 202611), budget(transportID, 1, 202611)],
            categories: [category(transportID, "交通費", sort: 5)]
        )

        #expect(rows.map(\.id) == [transportID, foodID])
    }

    // MARK: - totals(総予算・使用済み)

    @Test("総予算と使用済みは、各行の合計")
    func totalsSum() {
        let rows = makeRows(
            budgets: [budget(foodID, 30000, 202611), budget(transportID, 10000, 202611)],
            categories: [category(foodID, "食費", sort: 0), category(transportID, "交通費", sort: 1)],
            transactions: [spend(foodID, 3500), spend(transportID, 400)]
        )

        let totals = BudgetService.totals(of: rows)

        #expect(totals.budget == 40000)
        #expect(totals.spent == 3900)
    }

    @Test("行がなければ、どちらも0")
    func totalsEmpty() {
        let totals = BudgetService.totals(of: [])

        #expect(totals.budget == 0)
        #expect(totals.spent == 0)
    }

    @Test("使用済みは、予算のあるカテゴリー分だけが集計される")
    func totalsExcludeUnbudgetedSpending() {
        let rows = makeRows(
            budgets: [budget(foodID, 30000, 202611)],
            categories: [category(foodID, "食費"), category(transportID, "交通費")],
            transactions: [spend(foodID, 1000), spend(transportID, 5000)]
        )

        #expect(BudgetService.totals(of: rows).spent == 1000)
    }

    // MARK: - totalAmount(予算設定シートの総予算)

    @Test("設定シートの総予算は、その月に適用される予算の合計")
    func totalAmountSum() {
        let budgets = [
            budget(foodID, 30000, 202611),
            budget(transportID, 10000, 202601),
            budget(funID, 5000, 202601, 202610),   // 前月で終了
        ]

        #expect(BudgetService.totalAmount(of: budgets, type: .expense, month: 202611) == 40000)
    }

    @Test("同じカテゴリーに複数の行があっても、その月に適用される1件だけが合計される")
    func totalAmountOnePerCategory() {
        let budgets = [
            budget(foodID, 30000, 202610, 202610),
            budget(foodID, 50000, 202611, 202611),
            budget(foodID, 20000, 202612),
        ]

        #expect(BudgetService.totalAmount(of: budgets, type: .expense, month: 202611) == 50000)
    }

    @Test("予算がなければ、総予算は0")
    func totalAmountEmpty() {
        #expect(BudgetService.totalAmount(of: [], type: .expense, month: 202611) == 0)
    }
}
