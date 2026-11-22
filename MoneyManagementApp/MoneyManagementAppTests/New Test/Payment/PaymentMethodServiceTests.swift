
import Testing
import Foundation
import SwiftData
@testable import MoneyManagementApp

@MainActor
struct PaymentMethodServiceTests {

    // MARK: - Helper

    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }

    private func fetchAll(_ context: ModelContext) throws -> [PaymentMethod] {
        try context.fetch(FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.sortIndex)]))
    }

    /// 指定した名前の支払方法を sortIndex 0,1,2... で作る
    @discardableResult
    private func seed(_ names: [String], in context: ModelContext) throws -> [PaymentMethod] {
        try names.map {
            try PaymentMethodService.add(name: $0, type: .cash, memo: "", in: context)
        }
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: y, month: m, day: d))!
    }

    /// View の @Query(sort: \.date, order: .reverse) と同じ並びで取得する
    private func fetchTransactionsNewestFirst(_ context: ModelContext) throws -> [SchemaV2.Transaction] {
        try context.fetch(
            FetchDescriptor<SchemaV2.Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        )
    }

    // MARK: - 追加条件

    @Test("名前が入力されていれば追加できる")
    func validWhenNameFilled() {
        #expect(PaymentMethodService.isValid(name: "現金"))
    }

    @Test("名前が空だと追加できない")
    func invalidWhenNameEmpty() {
        #expect(!PaymentMethodService.isValid(name: ""))
    }
    
    // MARK: - 名前の必須入力・空白
    
    @Test("空白だけの名前(全角・タブを含む)は、追加できない")
    func invalidWhenNameIsOnlyWhitespace() {
        for name in ["", "   ", "　", "\t", " \u{3000}\t"] {
            #expect(!PaymentMethodService.isValid(name: name), "名前: [\(name)]")
        }
    }
    
    @Test("前後に空白があっても、名前があれば追加できる")
    func validWhenNameHasSurroundingSpaces() {
        #expect(PaymentMethodService.isValid(name: " 現金 "))
    }
    
    @Test("名前の前後の空白(半角・全角・タブ)は、削除して保存される")
    func addTrimsSpaces() throws {
        let context = try makeContext()
        
        let a = try PaymentMethodService.add(name: "  現金  ", type: .cash, memo: "", in: context)
        let b = try PaymentMethodService.add(name: "　PayPay　", type: .qrCode, memo: "", in: context)
        let c = try PaymentMethodService.add(name: "\tメインカード\t", type: .creditCard, memo: "", in: context)
        
        #expect(a.name == "現金")
        #expect(b.name == "PayPay")
        #expect(c.name == "メインカード")
    }
    
    @Test("名前の途中の空白は、そのまま残る")
    func addKeepsInnerSpaces() throws {
        let context = try makeContext()
        
        let a = try PaymentMethodService.add(name: " 三井住友 カード ", type: .creditCard, memo: "", in: context)
        
        #expect(a.name == "三井住友 カード")
    }
    
    @Test("名前が空・空白のみだと、追加は失敗し、何も保存されない")
    func addRejectsBlankName() throws {
        let context = try makeContext()
        
        for name in ["", "   ", "　", "\t"] {
            #expect(throws: (any Error).self) {
                try PaymentMethodService.add(name: name, type: .cash, memo: "", in: context)
            }
        }
        #expect(try fetchAll(context).isEmpty)
    }

    // MARK: - 追加

    @Test("追加した支払方法に名前・種類・メモが保存される")
    func addStoresValues() throws {
        let context = try makeContext()

        try PaymentMethodService.add(name: "三井住友カード", type: .creditCard, memo: "メインカード", in: context)

        let saved = try #require(try fetchAll(context).first)
        #expect(saved.name == "三井住友カード")
        #expect(saved.type == .creditCard)
        #expect(saved.memo == "メインカード")
    }

    @Test("メモが空文字ならnilで保存される")
    func emptyMemoBecomesNil() throws {
        let context = try makeContext()

        try PaymentMethodService.add(name: "PayPay", type: .qrCode, memo: "", in: context)

        let saved = try #require(try fetchAll(context).first)
        #expect(saved.memo == nil)
    }

    @Test("最初の支払方法のsortIndexは0")
    func firstSortIndexIsZero() throws {
        let context = try makeContext()

        let first = try PaymentMethodService.add(name: "現金", type: .cash, memo: "", in: context)

        #expect(first.sortIndex == 0)
    }

    @Test("追加するたびにsortIndexが末尾に増えていく")
    func sortIndexIncrements() throws {
        let context = try makeContext()

        let items = try seed(["A", "B", "C"], in: context)

        #expect(items.map(\.sortIndex) == [0, 1, 2])
    }

    @Test("sortIndexが飛んでいても、最大値+1で追加される")
    func addAfterGap() throws {
        let context = try makeContext()
        context.insert(PaymentMethod(name: "A", type: .cash, sortIndex: 0))
        context.insert(PaymentMethod(name: "B", type: .cash, sortIndex: 5))

        let added = try PaymentMethodService.add(name: "C", type: .cash, memo: "", in: context)

        #expect(added.sortIndex == 6)
    }

    @Test("追加した支払方法のIDは一意")
    func addedIDsAreUnique() throws {
        let context = try makeContext()

        let items = try seed(["A", "B"], in: context)

        #expect(items[0].id != items[1].id)
    }

    // MARK: - 削除

    @Test("1件削除すると、残りのsortIndexが詰まり順序は保たれる")
    func deleteOneReindexes() throws {
        let context = try makeContext()
        let items = try seed(["A", "B", "C", "D"], in: context)

        try PaymentMethodService.delete(ids: [items[1].id], in: context)

        let remaining = try fetchAll(context)
        #expect(remaining.map(\.name) == ["A", "C", "D"])
        #expect(remaining.map(\.sortIndex) == [0, 1, 2])
    }

    @Test("複数件をまとめて削除できる")
    func deleteMultiple() throws {
        let context = try makeContext()
        let items = try seed(["A", "B", "C", "D", "E"], in: context)

        try PaymentMethodService.delete(ids: [items[0].id, items[2].id, items[4].id], in: context)

        let remaining = try fetchAll(context)
        #expect(remaining.map(\.name) == ["B", "D"])
        #expect(remaining.map(\.sortIndex) == [0, 1])
    }

    @Test("sortIndexが飛んでいても、削除後は0から詰め直される")
    func deleteReindexesFromGaps() throws {
        let context = try makeContext()
        context.insert(PaymentMethod(name: "A", type: .cash, sortIndex: 0))
        let b = PaymentMethod(name: "B", type: .cash, sortIndex: 5)
        context.insert(b)
        context.insert(PaymentMethod(name: "C", type: .cash, sortIndex: 9))

        try PaymentMethodService.delete(ids: [b.id], in: context)

        let remaining = try fetchAll(context)
        #expect(remaining.map(\.name) == ["A", "C"])
        #expect(remaining.map(\.sortIndex) == [0, 1])
    }

    @Test("全件削除して0件になっても削除できる")
    func deleteAll() throws {
        let context = try makeContext()
        let items = try seed(["A", "B"], in: context)

        try PaymentMethodService.delete(ids: Set(items.map(\.id)), in: context)

        #expect(try fetchAll(context).isEmpty)
    }

    @Test("削除対象が空なら何も変わらない")
    func deleteNothing() throws {
        let context = try makeContext()
        try seed(["A", "B"], in: context)

        try PaymentMethodService.delete(ids: [], in: context)

        let remaining = try fetchAll(context)
        #expect(remaining.map(\.name) == ["A", "B"])
        #expect(remaining.map(\.sortIndex) == [0, 1])
    }

    @Test("存在しないIDを指定しても、他の支払方法に影響しない")
    func deleteUnknownID() throws {
        let context = try makeContext()
        try seed(["A", "B"], in: context)

        try PaymentMethodService.delete(ids: [UUID()], in: context)

        #expect(try fetchAll(context).count == 2)
    }

    @Test("削除後に追加すると、詰め直したsortIndexの末尾に入る")
    func addAfterDelete() throws {
        let context = try makeContext()
        let items = try seed(["A", "B", "C"], in: context)
        try PaymentMethodService.delete(ids: [items[0].id], in: context)

        let added = try PaymentMethodService.add(name: "D", type: .cash, memo: "", in: context)

        #expect(added.sortIndex == 2)
    }

    @Test("支払方法を削除しても、過去の収支記録の支払方法情報は残る")
    func deleteKeepsTransactionSnapshot() throws {
        let context = try makeContext()
        let method = try PaymentMethodService.add(name: "三井住友カード", type: .creditCard, memo: "メインカード", in: context)
        context.insert(SchemaV2.Transaction(
            amount: 800,
            paymentMethodID: method.id,
            paymentMethodName: method.name,
            paymentMethodType: method.type,
            paymentMethodMemo: method.memo
        ))

        try PaymentMethodService.delete(ids: [method.id], in: context)

        let saved = try #require(try context.fetch(FetchDescriptor<SchemaV2.Transaction>()).first)
        #expect(saved.paymentMethodName == "三井住友カード")
        #expect(saved.paymentMethodType == .creditCard)
        #expect(saved.paymentMethodMemo == "メインカード")
    }

    // MARK: - 最近の支払い

    @Test("収支記録がなければ、最近の支払いは空")
    func recentEmptyWithoutTransactions() throws {
        let context = try makeContext()
        let methods = try seed(["A", "B"], in: context)

        let result = PaymentMethodService.recent(from: methods, transactions: [])

        #expect(result.isEmpty)
    }

    @Test("最近使った順に返される")
    func recentOrderedByNewestUse() throws {
        let context = try makeContext()
        let m = try seed(["A", "B", "C"], in: context)
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 1), paymentMethodID: m[0].id))
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 3), paymentMethodID: m[2].id))
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 2), paymentMethodID: m[1].id))

        let result = PaymentMethodService.recent(
            from: m,
            transactions: try fetchTransactionsNewestFirst(context)
        )

        #expect(result.map(\.name) == ["C", "B", "A"])
    }

    @Test("同じ支払方法を何度使っても、1件にまとまる")
    func recentDeduplicates() throws {
        let context = try makeContext()
        let m = try seed(["A", "B"], in: context)
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 1), paymentMethodID: m[0].id))
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 2), paymentMethodID: m[0].id))
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 3), paymentMethodID: m[0].id))

        let result = PaymentMethodService.recent(
            from: m,
            transactions: try fetchTransactionsNewestFirst(context)
        )

        #expect(result.map(\.name) == ["A"])
    }

    @Test("4件以上使っていても、最大3件までしか返さない")
    func recentLimitedToThree() throws {
        let context = try makeContext()
        let m = try seed(["A", "B", "C", "D"], in: context)
        for (i, method) in m.enumerated() {
            context.insert(SchemaV2.Transaction(date: date(2026, 11, i + 1), paymentMethodID: method.id))
        }

        let result = PaymentMethodService.recent(
            from: m,
            transactions: try fetchTransactionsNewestFirst(context)
        )

        #expect(result.map(\.name) == ["D", "C", "B"])
    }

    @Test("支払方法が未設定(nil)の収支記録は無視される")
    func recentIgnoresNilPaymentMethod() throws {
        let context = try makeContext()
        let m = try seed(["A"], in: context)
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 2), paymentMethodID: nil))
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 1), paymentMethodID: m[0].id))

        let result = PaymentMethodService.recent(
            from: m,
            transactions: try fetchTransactionsNewestFirst(context)
        )

        #expect(result.map(\.name) == ["A"])
    }

    @Test("削除済みの支払方法は含まれず、3件の枠も消費しない")
    func recentSkipsDeletedMethods() throws {
        let context = try makeContext()
        let m = try seed(["A", "B", "C", "D"], in: context)
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 1), paymentMethodID: m[0].id))
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 2), paymentMethodID: m[1].id))
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 3), paymentMethodID: m[2].id))
        context.insert(SchemaV2.Transaction(date: date(2026, 11, 4), paymentMethodID: m[3].id))

        // 最も新しく使った D を削除する
        try PaymentMethodService.delete(ids: [m[3].id], in: context)
        let remaining = try fetchAll(context)

        let result = PaymentMethodService.recent(
            from: remaining,
            transactions: try fetchTransactionsNewestFirst(context)
        )

        #expect(result.map(\.name) == ["C", "B", "A"])
    }
}
