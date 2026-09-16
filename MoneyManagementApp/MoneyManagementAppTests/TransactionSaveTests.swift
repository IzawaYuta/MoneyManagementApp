import Testing
import SwiftData
import Foundation
@testable import MoneyManagementApp

// MARK: - テスト用の共通セットアップ

struct TransactionSaveTests {
    
    @MainActor
    /// インメモリのModelContainerとContextを毎回新しく作る
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Transaction.self, Category.self, PaymentMethod.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }
    
    // MARK: - 正常系(16パターン)
    // 軸: 種別(収入/支出) × 金額(0円/0円より大きい) × メモ(あり/nil) × 支払方法(あり/nil)
    
    @Test(arguments: [
        (TransactionType.income, 0, true, true),
        (TransactionType.income, 0, true, false),
        (TransactionType.income, 0, false, true),
        (TransactionType.income, 0, false, false),
        (TransactionType.income, 1500, true, true),
        (TransactionType.income, 1500, true, false),
        (TransactionType.income, 1500, false, true),
        (TransactionType.income, 1500, false, false),
        (TransactionType.expense, 0, true, true),
        (TransactionType.expense, 0, true, false),
        (TransactionType.expense, 0, false, true),
        (TransactionType.expense, 0, false, false),
        (TransactionType.expense, 1500, true, true),
        (TransactionType.expense, 1500, true, false),
        (TransactionType.expense, 1500, false, true),
        (TransactionType.expense, 1500, false, false),
    ])
    
    @MainActor
    func 正常系_収入支出の保存パターン(
        type: TransactionType,
        amount: Int,
        hasMemo: Bool,
        hasPaymentMethod: Bool
    ) throws {
        let context = try makeContext()
        
        let category = MoneyManagementApp.Category(name: "テストカテゴリー", imageName: "tag", sortIndex: 0)
        context.insert(category)
        
        var paymentMethod: PaymentMethod? = nil
        if hasPaymentMethod {
            let method = PaymentMethod(name: "現金", type: .cash, sortIndex: 0)
            context.insert(method)
            paymentMethod = method
        }
        
        let memo: String? = hasMemo ? "テストメモ" : nil
        
        let transaction = Transaction(
            amount: amount,
            type: type,
            category: category,
            memo: memo,
            paymentMethod: paymentMethod
        )
        context.insert(transaction)
        
        // 保存した値がそのまま反映されているか
        #expect(transaction.type == type)
        #expect(transaction.amount == amount)
        #expect(transaction.category.name == "テストカテゴリー")
        #expect(transaction.memo == memo)
        #expect(transaction.paymentMethod?.name == (hasPaymentMethod ? "現金" : nil))
        
        // 実際にストアへ登録された件数も確認
        let descriptor = FetchDescriptor<Transaction>()
        let saved = try context.fetch(descriptor)
        #expect(saved.count == 1)
    }
    
    // MARK: - 異常系: カテゴリー未選択(アプリ側のガードロジックを模した検証)
    //
    // Category は Transaction.init 上 Optional ではないため、
    // 「カテゴリーなしで保存しようとする」こと自体はコンパイルレベルで不可能。
    // そのため HomeView.saveTransaction() 内にある
    //   guard let category = selectedCategory else { return }
    // と同じロジックを模したヘルパーで、「未選択時は保存が実行されない」ことを検証する。
    
    private func trySave(
        selectedCategory: MoneyManagementApp.Category?,
        context: ModelContext,
        type: TransactionType
    ) -> Bool {
        guard let category = selectedCategory else {
            return false // 保存されなかった
        }
        let transaction = Transaction(amount: 1000, type: type, category: category)
        context.insert(transaction)
        return true // 保存された
    }
    
    @Test
    @MainActor
    func 異常系_カテゴリー未選択で収入を保存しようとする() throws {
        let context = try makeContext()
        let didSave = trySave(selectedCategory: nil, context: context, type: .income)
        
        #expect(didSave == false)
        
        let saved = try context.fetch(FetchDescriptor<Transaction>())
        #expect(saved.isEmpty)
    }
    
    @Test
    @MainActor
    func 異常系_カテゴリー未選択で支出を保存しようとする() throws {
        let context = try makeContext()
        let didSave = trySave(selectedCategory: nil, context: context, type: .expense)
        
        #expect(didSave == false)
        
        let saved = try context.fetch(FetchDescriptor<Transaction>())
        #expect(saved.isEmpty)
    }
    
    // MARK: - 異常系: マイナス金額
    //
    // 現状のTransactionモデル・init は金額の妥当性チェックを行っていないため、
    // このテストは「マイナス金額が"弾かれる"」ことの確認ではなく、
    // 「現状はマイナス金額もそのまま保存されてしまう」という"現状の挙動"を明文化するテスト。
    // もし将来バリデーションを追加する場合、このテストが最初に失敗するようになる想定。
    
//    @Test
//    @MainActor
//    func 異常系_マイナス金額の収入を保存しようとする() throws {
//        let context = try makeContext()
//        let category = MoneyManagementApp.Category(name: "テストカテゴリー", imageName: "tag", sortIndex: 0)
//        context.insert(category)
//        
//        let transaction = Transaction(amount: -500, type: .income, category: category)
//        context.insert(transaction)
//        
//        // 現状は検証ロジックがないため、マイナスのまま保存されてしまう
//        #expect(transaction.amount == -500)
//        // TODO: バリデーションを追加した場合、ここを amount >= 0 の期待値に変更する
//    }
//    
//    @Test
//    @MainActor
//    func 異常系_マイナス金額の支出を保存しようとする() throws {
//        let context = try makeContext()
//        let category = MoneyManagementApp.Category(name: "テストカテゴリー", imageName: "tag", sortIndex: 0)
//        context.insert(category)
//        
//        let transaction = Transaction(amount: -500, type: .expense, category: category)
//        context.insert(transaction)
//        
//        #expect(transaction.amount == -500)
//        // TODO: バリデーションを追加した場合、ここを amount >= 0 の期待値に変更する
//    }
}
