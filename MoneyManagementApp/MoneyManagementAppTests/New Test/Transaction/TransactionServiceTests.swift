

import Testing
import Foundation
import SwiftData
@testable import MoneyManagementApp

@MainActor
struct TransactionServiceTests {

    // MARK: - Helper

    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func fetchAll(_ context: ModelContext) throws -> [SchemaV2.Transaction] {
        try context.fetch(
            FetchDescriptor<SchemaV2.Transaction>(sortBy: [SortDescriptor(\.sortIndex)])
        )
    }

    private func makeCategory(in context: ModelContext) -> Category {
        let category = Category(name: "食費", imageName: "fork.knife", colorHex: "#FF6B6B", sortIndex: 0)
        context.insert(category)
        return category
    }

    private func makePaymentMethod(in context: ModelContext) -> PaymentMethod {
        let method = PaymentMethod(name: "三井住友カード", type: .creditCard, memo: "メインカード", sortIndex: 0)
        context.insert(method)
        return method
    }

    /// 引数を省略すると、支出・1000円・カテゴリーなし・支払方法なしで保存する
    @discardableResult
    private func save(
        in context: ModelContext,
        date: Date = Date(),
        amountText: String = "1000",
        type: TransactionType = .expense,
        memo: String = "",
        category: Category? = nil,
        paymentMethod: PaymentMethod? = nil
    ) throws -> SchemaV2.Transaction {
        try TransactionService.save(
            date: date,
            amountText: amountText,
            type: type,
            memo: memo,
            category: category,
            paymentMethod: paymentMethod,
            in: context
        )
    }

    // MARK: - 種別・金額

    @Test("支出を保存できる")
    func saveExpense() throws {
        let context = try makeContext()

        try save(in: context, amountText: "1200", type: .expense)

        let saved = try #require(try fetchAll(context).first)
        #expect(saved.type == .expense)
        #expect(saved.amount == 1200)
    }

    @Test("収入を保存できる")
    func saveIncome() throws {
        let context = try makeContext()

        try save(in: context, amountText: "250000", type: .income)

        let saved = try #require(try fetchAll(context).first)
        #expect(saved.type == .income)
        #expect(saved.amount == 250_000)
    }

    @Test("金額の文字列が整数に変換されて保存される")
    func amountTextIsConverted() throws {
        let context = try makeContext()

        let t = try save(in: context, amountText: "35800")

        #expect(t.amount == 35_800)
    }

    @Test("【現状の仕様】金額が空でも、0円で保存される")
    func emptyAmountBecomesZero() throws {
        let context = try makeContext()

        let t = try save(in: context, amountText: "")

        #expect(t.amount == 0)
        #expect(try fetchAll(context).count == 1)
    }

    @Test("【現状の仕様】数字として読めない金額は、0円で保存される")
    func invalidAmountBecomesZero() throws {
        let context = try makeContext()

        let t = try save(in: context, amountText: "abc")

        #expect(t.amount == 0)
    }

    // MARK: - 日付・メモ

    @Test("指定した日時がそのまま保存される")
    func dateIsStoredAsIs() throws {
        let context = try makeContext()
        let target = date(2026, 11, 15, 14, 30)

        let t = try save(in: context, date: target)

        #expect(t.date == target)
    }

    @Test("メモが保存される")
    func memoIsStored() throws {
        let context = try makeContext()

        let t = try save(in: context, memo: "ランチ")

        #expect(t.memo == "ランチ")
    }

    @Test("【現状の仕様】メモが空のときは、nilではなく空文字で保存される")
    func emptyMemoStaysEmptyString() throws {
        let context = try makeContext()

        let t = try save(in: context, memo: "")

        #expect(t.memo == "")
    }

    // MARK: - カテゴリー

    @Test("選択したカテゴリーの内容がコピーして保存される")
    func categorySnapshotIsStored() throws {
        let context = try makeContext()
        let category = makeCategory(in: context)

        let t = try save(in: context, category: category)

        #expect(t.categoryID == category.id)
        #expect(t.categoryName == "食費")
        #expect(t.categoryImageName == "fork.knife")
        #expect(t.categoryColorHex == "#FF6B6B")
    }

    @Test("カテゴリーが未選択(nil)でも保存でき、カテゴリー情報はすべてnil")
    func saveWithoutCategory() throws {
        let context = try makeContext()

        let t = try save(in: context, category: nil)

        #expect(t.categoryID == nil)
        #expect(t.categoryName == nil)
        #expect(t.categoryImageName == nil)
        #expect(t.categoryColorHex == nil)
    }

    @Test("保存後にカテゴリーを編集しても、保存済みの記録は変わらない")
    func categoryEditDoesNotAffectSavedTransaction() throws {
        let context = try makeContext()
        let category = makeCategory(in: context)
        let t = try save(in: context, category: category)

        category.name = "外食"
        category.imageName = "mug"
        category.colorHex = "#4DABF7"

        #expect(t.categoryName == "食費")
        #expect(t.categoryImageName == "fork.knife")
        #expect(t.categoryColorHex == "#FF6B6B")
    }

    // MARK: - 支払方法

    @Test("選択した支払方法の内容がコピーして保存される")
    func paymentMethodSnapshotIsStored() throws {
        let context = try makeContext()
        let method = makePaymentMethod(in: context)

        let t = try save(in: context, paymentMethod: method)

        #expect(t.paymentMethodID == method.id)
        #expect(t.paymentMethodName == "三井住友カード")
        #expect(t.paymentMethodType == .creditCard)
        #expect(t.paymentMethodMemo == "メインカード")
    }

    @Test("支払方法が未選択(nil)でも保存でき、支払方法情報はすべてnil")
    func saveWithoutPaymentMethod() throws {
        let context = try makeContext()

        let t = try save(in: context, paymentMethod: nil)

        #expect(t.paymentMethodID == nil)
        #expect(t.paymentMethodName == nil)
        #expect(t.paymentMethodType == nil)
        #expect(t.paymentMethodMemo == nil)
    }

    @Test("保存後に支払方法を編集しても、保存済みの記録は変わらない")
    func paymentMethodEditDoesNotAffectSavedTransaction() throws {
        let context = try makeContext()
        let method = makePaymentMethod(in: context)
        let t = try save(in: context, paymentMethod: method)

        method.name = "別のカード"
        method.type = .debitCard
        method.memo = nil

        #expect(t.paymentMethodName == "三井住友カード")
        #expect(t.paymentMethodType == .creditCard)
        #expect(t.paymentMethodMemo == "メインカード")
    }

    // MARK: - sortIndex

    @Test("最初の記録のsortIndexは0")
    func firstSortIndexIsZero() throws {
        let context = try makeContext()

        let t = try save(in: context)

        #expect(t.sortIndex == 0)
    }

    @Test("保存するたびにsortIndexが増えていく")
    func sortIndexIncrements() throws {
        let context = try makeContext()
        
        let a = try save(in: context)
        let b = try save(in: context)
        let c = try save(in: context)
        
        let indexes: [Int] = [a.sortIndex, b.sortIndex, c.sortIndex]
        #expect(indexes == [0, 1, 2])
    }
    
    @Test("sortIndexが飛んでいても、最大値+1で保存される")
    func sortIndexAfterGap() throws {
        let context = try makeContext()
        context.insert(SchemaV2.Transaction(sortIndex: 0))
        context.insert(SchemaV2.Transaction(sortIndex: 7))

        let t = try save(in: context)

        #expect(t.sortIndex == 8)
    }

    @Test("日付が違っても、sortIndexは全記録の通し番号になる")
    func sortIndexIsGlobalAcrossDates() throws {
        let context = try makeContext()
        
        let a = try save(in: context, date: date(2026, 11, 1))
        let b = try save(in: context, date: date(2026, 11, 20))
        let c = try save(in: context, date: date(2026, 11, 1))
        
        let indexes: [Int] = [a.sortIndex, b.sortIndex, c.sortIndex]
        #expect(indexes == [0, 1, 2])
    }
    
    // MARK: - 複数回の保存

    @Test("同じ内容を2回保存すると、2件の記録になる")
    func sameInputTwiceCreatesTwoRecords() throws {
        let context = try makeContext()
        let category = makeCategory(in: context)

        try save(in: context, amountText: "500", category: category)
        try save(in: context, amountText: "500", category: category)

        let all = try fetchAll(context)
        #expect(all.count == 2)
        #expect(all[0].id != all[1].id)
    }
}
