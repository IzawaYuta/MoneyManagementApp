
import Testing
import Foundation
import SwiftData
@testable import MoneyManagementApp

@MainActor
struct TransactionOverwriteTests {

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

    private var originalDate: Date { date(2026, 11, 15, 10, 30) }

    private func makeCategory(
        name: String = "食費", imageName: String = "fork.knife", colorHex: String = "#FF6B6B",
        in context: ModelContext
    ) -> Category {
        let category = Category(name: name, imageName: imageName, colorHex: colorHex, sortIndex: 0)
        context.insert(category)
        return category
    }

    private func makePaymentMethod(
        name: String = "三井住友カード", type: PaymentType = .creditCard, memo: String? = "メインカード",
        in context: ModelContext
    ) -> PaymentMethod {
        let method = PaymentMethod(name: name, type: type, memo: memo, sortIndex: 0)
        context.insert(method)
        return method
    }

    /// 本番の保存処理で、元の記録(支出・1000円・メモ「元のメモ」)を作る
    private func makeSaved(
        in context: ModelContext,
        category: Category? = nil,
        paymentMethod: PaymentMethod? = nil
    ) throws -> SchemaV2.Transaction {
        try TransactionService.save(
            date: originalDate,
            amountText: "1000",
            type: .expense,
            memo: "元のメモ",
            category: category,
            paymentMethod: paymentMethod,
            in: context
        )
    }

    /// 引数を省略すると、元の記録と同じ値で上書きする(変えたい項目だけ指定する)
    @discardableResult
    private func overwrite(
        _ t: SchemaV2.Transaction,
        type: TransactionType = .expense,
        date: Date? = nil,
        amountText: String = "1000",
        memo: String = "元のメモ",
        category: Category? = nil,
        paymentMethod: PaymentMethod? = nil
    ) -> Bool {
        TransactionService.update(
            t,
            type: type,
            date: date ?? originalDate,
            amountText: amountText,
            memo: memo,
            category: category,
            paymentMethod: paymentMethod
        )
    }

    private func fetchAll(_ context: ModelContext) throws -> [SchemaV2.Transaction] {
        try context.fetch(
            FetchDescriptor<SchemaV2.Transaction>(sortBy: [SortDescriptor(\.sortIndex)])
        )
    }

    // MARK: - 金額の読み取り

    @Test("「¥1,280」の形の金額を整数として読み取れる")
    func parseFormattedAmount() {
        #expect(TransactionService.parseAmount("¥1,280") == 1280)
        #expect(TransactionService.parseAmount("250000") == 250_000)
    }

    @Test("空や数字のない文字列は読み取れない(nil)")
    func parseInvalidAmount() {
        #expect(TransactionService.parseAmount("") == nil)
        #expect(TransactionService.parseAmount("abc") == nil)
        #expect(TransactionService.parseAmount("¥") == nil)
    }

    // MARK: - 項目の上書き

    @Test("金額を上書きできる")
    func overwriteAmount() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context)

        let ok = overwrite(t, amountText: "¥2,500")

        #expect(ok)
        #expect(t.amount == 2500)
    }

    @Test("支出を収入に変更できる")
    func overwriteTypeToIncome() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context)

        overwrite(t, type: .income)

        #expect(t.type == .income)
    }

    @Test("日付を上書きできる")
    func overwriteDate() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context)
        let newDate = date(2026, 12, 1, 9, 0)

        overwrite(t, date: newDate)

        #expect(t.date == newDate)
    }

    @Test("メモを上書きできる")
    func overwriteMemo() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context)

        overwrite(t, memo: "新しいメモ")

        #expect(t.memo == "新しいメモ")
    }

    @Test("メモを空にすると、nilで保存される")
    func emptyMemoBecomesNil() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context)

        overwrite(t, memo: "")

        #expect(t.memo == nil)
    }

    @Test("上書きしても、IDとsortIndexは変わらず、件数も増えない")
    func overwriteKeepsIdentity() throws {
        let context = try makeContext()
        try makeSaved(in: context)
        let t = try makeSaved(in: context)
        let originalID = t.id

        overwrite(t, amountText: "9999")

        #expect(t.id == originalID)
        #expect(t.sortIndex == 1)
        #expect(try fetchAll(context).count == 2)
    }

    @Test("1件を上書きしても、他の記録には影響しない")
    func overwriteDoesNotAffectOthers() throws {
        let context = try makeContext()
        let a = try makeSaved(in: context)
        let b = try makeSaved(in: context)

        overwrite(b, type: .income, amountText: "5000", memo: "変更")

        #expect(a.amount == 1000)
        #expect(a.type == .expense)
        #expect(a.memo == "元のメモ")
    }

    // MARK: - 金額0の上書き
    
    @Test("金額が0でも上書きできる(他の項目も更新される)")
    func zeroAmountIsAccepted() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context)
        
        let ok = overwrite(t, type: .income, amountText: "¥0", memo: "変更")
        
        #expect(ok)
        #expect(t.amount == 0)
        #expect(t.type == .income)
        #expect(t.memo == "変更")
    }
    
    @Test("金額が空でも、0円として上書きできる")
    func emptyAmountBecomesZero() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context)
        
        let ok = overwrite(t, amountText: "")
        
        #expect(ok)
        #expect(t.amount == 0)
    }
    
    @Test("0円にしたあと、金額を入れて上書きし直せる")
    func overwriteAgainAfterZero() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context)
        overwrite(t, amountText: "0")
        
        overwrite(t, amountText: "2500")
        
        #expect(t.amount == 2500)
    }
    
    // MARK: - カテゴリー

    @Test("別のカテゴリーに変更すると、新しい内容がコピーされる")
    func changeCategoryCopiesSnapshot() throws {
        let context = try makeContext()
        let food = makeCategory(in: context)
        let t = try makeSaved(in: context, category: food)
        let transport = makeCategory(name: "交通費", imageName: "car", colorHex: "#FFD43B", in: context)

        overwrite(t, category: transport)

        #expect(t.categoryID == transport.id)
        #expect(t.categoryName == "交通費")
        #expect(t.categoryImageName == "car")
        #expect(t.categoryColorHex == "#FFD43B")
    }

    @Test("カテゴリー未設定の記録に、カテゴリーを設定できる")
    func setCategoryOnRecordWithoutCategory() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context, category: nil)
        let food = makeCategory(in: context)

        overwrite(t, category: food)

        #expect(t.categoryID == food.id)
        #expect(t.categoryName == "食費")
    }

    @Test("同じカテゴリーのままなら、保存時の内容が残る(カテゴリー側の編集は反映されない)")
    func sameCategoryKeepsOldSnapshot() throws {
        let context = try makeContext()
        let food = makeCategory(in: context)
        let t = try makeSaved(in: context, category: food)
        food.name = "外食"
        food.colorHex = "#4DABF7"

        overwrite(t, amountText: "2000", category: food)

        #expect(t.categoryName == "食費")
        #expect(t.categoryColorHex == "#FF6B6B")
    }

    @Test("選択中のカテゴリーが削除済み(nil)でも、記録のカテゴリー情報は残る")
    func deletedCategoryKeepsSnapshot() throws {
        let context = try makeContext()
        let food = makeCategory(in: context)
        let t = try makeSaved(in: context, category: food)

        overwrite(t, amountText: "2000", category: nil)

        #expect(t.amount == 2000)
        #expect(t.categoryName == "食費")
        #expect(t.categoryImageName == "fork.knife")
        #expect(t.categoryColorHex == "#FF6B6B")
    }

    // MARK: - 支払方法

    @Test("別の支払方法に変更すると、ID・名前・種類がコピーされる")
    func changePaymentMethodCopiesSnapshot() throws {
        let context = try makeContext()
        let card = makePaymentMethod(in: context)
        let t = try makeSaved(in: context, paymentMethod: card)
        let cash = makePaymentMethod(name: "現金", type: .cash, memo: nil, in: context)

        overwrite(t, paymentMethod: cash)

        #expect(t.paymentMethodID == cash.id)
        #expect(t.paymentMethodName == "現金")
        #expect(t.paymentMethodType == .cash)
    }

    @Test("別の支払方法に変更すると、支払方法のメモもコピーされる")
    func changePaymentMethodCopiesMemo() throws {
        let context = try makeContext()
        let card = makePaymentMethod(in: context)
        let t = try makeSaved(in: context, paymentMethod: card)
        let cash = makePaymentMethod(name: "現金", type: .cash, memo: "財布の現金", in: context)
        
        overwrite(t, paymentMethod: cash)
        
        #expect(t.paymentMethodMemo == "財布の現金")
    }
    
    @Test("メモのない支払方法に変更すると、古いメモは消える")
    func changePaymentMethodClearsOldMemo() throws {
        let context = try makeContext()
        let card = makePaymentMethod(in: context)   // メモ「メインカード」
        let t = try makeSaved(in: context, paymentMethod: card)
        let cash = makePaymentMethod(name: "現金", type: .cash, memo: nil, in: context)
        
        overwrite(t, paymentMethod: cash)
        
        #expect(t.paymentMethodMemo == nil)
    }
    
    @Test("支払方法未設定の記録に、支払方法を設定できる")
    func setPaymentMethodOnRecordWithoutOne() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context, paymentMethod: nil)
        let card = makePaymentMethod(in: context)

        overwrite(t, paymentMethod: card)

        #expect(t.paymentMethodID == card.id)
        #expect(t.paymentMethodName == "三井住友カード")
    }

    @Test("同じ支払方法のままなら、保存時の内容が残る")
    func samePaymentMethodKeepsOldSnapshot() throws {
        let context = try makeContext()
        let card = makePaymentMethod(in: context)
        let t = try makeSaved(in: context, paymentMethod: card)
        card.name = "別のカード"
        card.type = .debitCard

        overwrite(t, amountText: "2000", paymentMethod: card)

        #expect(t.paymentMethodName == "三井住友カード")
        #expect(t.paymentMethodType == .creditCard)
    }

    @Test("選択中の支払方法が削除済み(nil)でも、記録の支払方法情報は残る")
    func deletedPaymentMethodKeepsSnapshot() throws {
        let context = try makeContext()
        let card = makePaymentMethod(in: context)
        let t = try makeSaved(in: context, paymentMethod: card)

        overwrite(t, amountText: "2000", paymentMethod: nil)

        #expect(t.amount == 2000)
        #expect(t.paymentMethodName == "三井住友カード")
        #expect(t.paymentMethodType == .creditCard)
        #expect(t.paymentMethodMemo == "メインカード")
    }

    // MARK: - 削除

    @Test("記録を削除できる")
    func deleteTransaction() throws {
        let context = try makeContext()
        let t = try makeSaved(in: context)

        TransactionService.delete(t, in: context)

        #expect(try fetchAll(context).isEmpty)
    }

    @Test("1件削除しても、他の記録は残り、sortIndexは変わらない")
    func deleteKeepsOthers() throws {
        let context = try makeContext()
        let a = try makeSaved(in: context)
        let b = try makeSaved(in: context)
        let c = try makeSaved(in: context)

        TransactionService.delete(b, in: context)

        let remaining = try fetchAll(context)
        #expect(remaining.count == 2)
        #expect(remaining.contains { $0.id == a.id })
        #expect(remaining.contains { $0.id == c.id })
        #expect(c.sortIndex == 2)
    }

    @Test("削除したあとに保存すると、最大のsortIndex+1が付く")
    func saveAfterDeleteUsesMaxPlusOne() throws {
        let context = try makeContext()
        try makeSaved(in: context)
        try makeSaved(in: context)
        let last = try makeSaved(in: context)
        TransactionService.delete(last, in: context)

        let next = try makeSaved(in: context)

        #expect(next.sortIndex == 2)
    }
}
