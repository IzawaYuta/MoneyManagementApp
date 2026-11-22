
import Testing
import Foundation
import SwiftData
@testable import MoneyManagementApp

@MainActor
struct AggregationAfterChangeTests {

    // MARK: - Helper

    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    /// 実行環境のタイムゾーンに左右されないよう、日本時間のグレゴリオ暦で固定する
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    private func makeCategory(
        _ name: String, _ image: String, _ color: String, in context: ModelContext
    ) -> Category {
        let category = Category(name: name, imageName: image, colorHex: color, sortIndex: 0)
        context.insert(category)
        return category
    }

    /// 本番の保存処理で記録を作る
    @discardableResult
    private func save(
        _ context: ModelContext,
        _ date: Date,
        _ amount: Int,
        _ type: TransactionType = .expense,
        category: Category? = nil
    ) throws -> SchemaV2.Transaction {
        try TransactionService.save(
            date: date,
            amountText: String(amount),
            type: type,
            memo: "",
            category: category,
            paymentMethod: nil,
            in: context
        )
    }

    /// 本番の上書き処理。変えたい項目だけ指定する(省略した項目は今の値のまま)
    @discardableResult
    private func edit(
        _ t: SchemaV2.Transaction,
        type: TransactionType? = nil,
        date: Date? = nil,
        amountText: String? = nil,
        category: Category? = nil
    ) -> Bool {
        TransactionService.update(
            t,
            type: type ?? t.type,
            date: date ?? t.date,
            amountText: amountText ?? String(t.amount),
            memo: t.memo ?? "",
            category: category,
            paymentMethod: nil
        )
    }

    /// View の @Query(sort: \.date) と同じ並びで取得する
    private func fetchAll(_ context: ModelContext) throws -> [SchemaV2.Transaction] {
        try context.fetch(
            FetchDescriptor<SchemaV2.Transaction>(sortBy: [SortDescriptor(\.date)])
        )
    }

    // カレンダーの集計
    private func daily(_ context: ModelContext, _ day: Date) throws -> CalendarService.DailySummary {
        CalendarService.dailySummary(for: day, in: try fetchAll(context), calendar: calendar)
    }

    private func dayItems(_ context: ModelContext, _ day: Date) throws -> [SchemaV2.Transaction] {
        CalendarService.transactions(for: day, in: try fetchAll(context), calendar: calendar)
    }

    // グラフの集計
    private func chart(
        _ context: ModelContext,
        month: Date? = nil,
        type: TransactionType = .expense
    ) throws -> [CategorySummary] {
        MonthlyChartService.summaries(
            from: try fetchAll(context),
            month: month ?? date(2026, 11, 15),
            type: type,
            calendar: calendar
        )
    }

    // MARK: - カレンダー: 編集後

    @Test("カレンダー: 金額を編集すると、その日の合計が変わる")
    func calendarAmountEdit() throws {
        let context = try makeContext()
        let t = try save(context, date(2026, 11, 15), 1000)

        edit(t, amountText: "¥2,500")

        #expect(try daily(context, date(2026, 11, 15)) == .init(income: 0, expense: 2500))
    }

    @Test("カレンダー: 支出を収入に変更すると、支出合計が減り、収入合計が増える")
    func calendarTypeEdit() throws {
        let context = try makeContext()
        let t = try save(context, date(2026, 11, 15), 1000, .expense)
        try save(context, date(2026, 11, 15), 300, .expense)

        edit(t, type: .income)

        #expect(try daily(context, date(2026, 11, 15)) == .init(income: 1000, expense: 300))
    }

    @Test("カレンダー: 日付を別の日に変更すると、元の日から消えて新しい日に入る")
    func calendarDateEdit() throws {
        let context = try makeContext()
        let t = try save(context, date(2026, 11, 15), 700)

        edit(t, date: date(2026, 11, 16))

        #expect(try daily(context, date(2026, 11, 15)) == .init(income: 0, expense: 0))
        #expect(try dayItems(context, date(2026, 11, 15)).isEmpty)
        #expect(try daily(context, date(2026, 11, 16)) == .init(income: 0, expense: 700))
        #expect(try dayItems(context, date(2026, 11, 16)).map(\.amount) == [700])
    }

    @Test("カレンダー: 月末の記録を翌月の1日に変更すると、日付が月をまたいで移る")
    func calendarDateEditAcrossMonth() throws {
        let context = try makeContext()
        let t = try save(context, date(2026, 11, 30), 400)

        edit(t, date: date(2026, 12, 1))

        #expect(try daily(context, date(2026, 11, 30)).expense == 0)
        #expect(try daily(context, date(2026, 12, 1)).expense == 400)
    }

    @Test("カレンダー: 1件を編集しても、他の日の合計は変わらない")
    func calendarEditDoesNotAffectOtherDays() throws {
        let context = try makeContext()
        try save(context, date(2026, 11, 14), 100)
        let t = try save(context, date(2026, 11, 15), 200)

        edit(t, amountText: "900")

        #expect(try daily(context, date(2026, 11, 14)).expense == 100)
        #expect(try daily(context, date(2026, 11, 15)).expense == 900)
    }

    @Test("カレンダー: 金額0で上書きすると、その日の合計は0になり、記録は残る")
    func calendarZeroEdit() throws {
        let context = try makeContext()
        let t = try save(context, date(2026, 11, 15), 1000)
        
        edit(t, amountText: "0")
        
        #expect(try daily(context, date(2026, 11, 15)) == .init(income: 0, expense: 0))
        #expect(try dayItems(context, date(2026, 11, 15)).count == 1)
    }
    
    // MARK: - カレンダー: 削除後

    @Test("カレンダー: 記録を削除すると、その日の合計と一覧から消える")
    func calendarDelete() throws {
        let context = try makeContext()
        let t = try save(context, date(2026, 11, 15), 1000)
        try save(context, date(2026, 11, 15), 300)

        TransactionService.delete(t, in: context)

        #expect(try daily(context, date(2026, 11, 15)).expense == 300)
        #expect(try dayItems(context, date(2026, 11, 15)).map(\.amount) == [300])
    }

    @Test("カレンダー: 1件削除しても、他の日の記録は残る")
    func calendarDeleteKeepsOtherDays() throws {
        let context = try makeContext()
        let a = try save(context, date(2026, 11, 14), 100)
        try save(context, date(2026, 11, 15), 200)

        TransactionService.delete(a, in: context)

        #expect(try daily(context, date(2026, 11, 14)) == .init(income: 0, expense: 0))
        #expect(try daily(context, date(2026, 11, 15)).expense == 200)
    }

    @Test("カレンダー: その日の最後の1件を削除すると、合計は0で一覧は空になる")
    func calendarDeleteLastOfDay() throws {
        let context = try makeContext()
        let t = try save(context, date(2026, 11, 15), 1000, .income)

        TransactionService.delete(t, in: context)

        #expect(try daily(context, date(2026, 11, 15)) == .init(income: 0, expense: 0))
        #expect(try dayItems(context, date(2026, 11, 15)).isEmpty)
    }

    // MARK: - グラフ: 編集後

    @Test("グラフ: 金額を編集すると、カテゴリーの合計が変わる")
    func chartAmountEdit() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let t = try save(context, date(2026, 11, 1), 1000, category: food)
        try save(context, date(2026, 11, 2), 500, category: food)

        edit(t, amountText: "3000")

        let result = try chart(context)
        #expect(result.map(\.amount) == [3500])
        #expect(MonthlyChartService.total(of: result) == 3500)
    }

    @Test("グラフ: カテゴリーを変更すると、元のカテゴリーが減り、新しいカテゴリーに加算される")
    func chartCategoryEdit() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let transport = makeCategory("交通費", "car", "#FFD43B", in: context)
        try save(context, date(2026, 11, 1), 2000, category: food)
        let t = try save(context, date(2026, 11, 2), 1000, category: food)
        try save(context, date(2026, 11, 3), 500, category: transport)

        edit(t, category: transport)

        let result = try chart(context)
        #expect(result.map(\.name) == ["食費", "交通費"])
        #expect(result.map(\.amount) == [2000, 1500])
    }

    @Test("グラフ: カテゴリーの記録がすべて別のカテゴリーに移ると、その行は消える")
    func chartCategoryRowDisappearsAfterEdit() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let transport = makeCategory("交通費", "car", "#FFD43B", in: context)
        let t = try save(context, date(2026, 11, 1), 1000, category: food)
        try save(context, date(2026, 11, 2), 500, category: transport)

        edit(t, category: transport)

        let result = try chart(context)
        #expect(result.map(\.name) == ["交通費"])
        #expect(result.map(\.amount) == [1500])
    }

    @Test("グラフ: 支出を収入に変更すると、支出のグラフから消えて収入のグラフに現れる")
    func chartTypeEdit() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let t = try save(context, date(2026, 11, 1), 1000, .expense, category: food)

        edit(t, type: .income)

        #expect(try chart(context, type: .expense).isEmpty)
        #expect(try chart(context, type: .income).map(\.name) == ["食費"])
        #expect(try chart(context, type: .income).map(\.amount) == [1000])
    }

    @Test("グラフ: 日付を別の月に変更すると、元の月から消えて新しい月に現れる")
    func chartDateEditAcrossMonth() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let t = try save(context, date(2026, 11, 15), 1000, category: food)

        edit(t, date: date(2026, 12, 1))

        #expect(try chart(context, month: date(2026, 11, 1)).isEmpty)
        #expect(try chart(context, month: date(2026, 12, 1)).map(\.amount) == [1000])
    }

    @Test("グラフ: 金額を編集すると、金額の大きい順の並びが入れ替わる")
    func chartOrderChangesAfterEdit() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let transport = makeCategory("交通費", "car", "#FFD43B", in: context)
        let foodRecord = try save(context, date(2026, 11, 1), 3000, category: food)
        try save(context, date(2026, 11, 2), 2000, category: transport)
        #expect(try chart(context).map(\.name) == ["食費", "交通費"])

        edit(foodRecord, amountText: "500")

        #expect(try chart(context).map(\.name) == ["交通費", "食費"])
    }

    @Test("グラフ: カテゴリー未設定の記録にカテゴリーを設定すると、「未分類」から移る")
    func chartSetCategoryOnUncategorized() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let t = try save(context, date(2026, 11, 1), 1000)
        #expect(try chart(context).map(\.name) == ["未分類"])

        edit(t, category: food)

        let result = try chart(context)
        #expect(result.map(\.name) == ["食費"])
        #expect(result.first?.color == "#FF6B6B")
    }

    @Test("グラフ: カテゴリーを削除したあとに金額を編集しても、保存時の名前・色で集計される")
    func chartDeletedCategoryKeepsSnapshotAfterEdit() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let t = try save(context, date(2026, 11, 1), 1000, category: food)
        try CategoryService.delete(ids: [food.id], in: context)

        // 画面では、削除済みのカテゴリーは選べず nil になる
        edit(t, amountText: "2000", category: nil)

        let row = try #require(try chart(context).first)
        #expect(row.name == "食費")
        #expect(row.imageName == "fork.knife")
        #expect(row.color == "#FF6B6B")
        #expect(row.amount == 2000)
    }

    @Test("グラフ: 金額0で上書きすると、カテゴリーの行は残り、合計は0になる")
    func chartZeroEdit() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let t = try save(context, date(2026, 11, 1), 1000, category: food)
        
        edit(t, amountText: "0")
        
        let result = try chart(context)
        #expect(result.map(\.name) == ["食費"])
        #expect(result.map(\.amount) == [0])
        #expect(MonthlyChartService.total(of: result) == 0)
    }
    
    // MARK: - グラフ: 削除後

    @Test("グラフ: 記録を削除すると、カテゴリーの合計が減る")
    func chartDelete() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        try save(context, date(2026, 11, 1), 1000, category: food)
        let t2 = try save(context, date(2026, 11, 2), 500, category: food)

        TransactionService.delete(t2, in: context)

        let result = try chart(context)
        #expect(result.map(\.amount) == [1000])
        #expect(MonthlyChartService.total(of: result) == 1000)
    }

    @Test("グラフ: カテゴリーの最後の1件を削除すると、その行は消える")
    func chartDeleteLastOfCategory() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let transport = makeCategory("交通費", "car", "#FFD43B", in: context)
        let t = try save(context, date(2026, 11, 1), 1000, category: food)
        try save(context, date(2026, 11, 2), 500, category: transport)

        TransactionService.delete(t, in: context)

        #expect(try chart(context).map(\.name) == ["交通費"])
    }

    @Test("グラフ: その月の記録をすべて削除すると、空になり、合計は0")
    func chartDeleteAll() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let a = try save(context, date(2026, 11, 1), 1000, category: food)
        let b = try save(context, date(2026, 11, 2), 500)

        TransactionService.delete(a, in: context)
        TransactionService.delete(b, in: context)

        let result = try chart(context)
        #expect(result.isEmpty)
        #expect(MonthlyChartService.total(of: result) == 0)
    }

    // MARK: - カレンダーとグラフの両方

    @Test("1件の編集が、カレンダーとグラフの両方に反映される")
    func editIsReflectedInBoth() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let t = try save(context, date(2026, 11, 15), 1000, category: food)

        edit(t, amountText: "2500")

        #expect(try daily(context, date(2026, 11, 15)).expense == 2500)
        #expect(try chart(context).map(\.amount) == [2500])
    }

    @Test("1件の削除が、カレンダーとグラフの両方に反映される")
    func deleteIsReflectedInBoth() throws {
        let context = try makeContext()
        let food = makeCategory("食費", "fork.knife", "#FF6B6B", in: context)
        let t = try save(context, date(2026, 11, 15), 1000, category: food)

        TransactionService.delete(t, in: context)

        #expect(try daily(context, date(2026, 11, 15)) == .init(income: 0, expense: 0))
        #expect(try chart(context).isEmpty)
    }
}
