//
//  TransactionService.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/11/21.
//


import Foundation
import SwiftData

@MainActor
enum TransactionService {

    /// 収支を1件保存する(Home画面の「確定」ボタンの処理)
    /// - 金額は文字列を整数に変換する(変換できなければ0)
    /// - カテゴリー・支払方法は、その時点の内容をコピーして保存する
    /// - sortIndex は、全記録の最大値 + 1
    @discardableResult
    static func save(
        date: Date,
        amountText: String,
        type: TransactionType,
        memo: String,
        category: Category?,
        paymentMethod: PaymentMethod?,
        in context: ModelContext
    ) throws -> SchemaV2.Transaction {
        let all = try context.fetch(FetchDescriptor<SchemaV2.Transaction>())
        let nextSortIndex = (all.map(\.sortIndex).max() ?? -1) + 1

        let transaction = SchemaV2.Transaction(
            date: date,
            amount: Int(amountText) ?? 0,
            type: type,
            memo: memo.isEmpty ? nil : memo,
            sortIndex: nextSortIndex,
            categoryID: category?.id,
            categoryName: category?.name,
            categoryImageName: category?.imageName,
            categoryColorHex: category?.colorHex,
            paymentMethodID: paymentMethod?.id,
            paymentMethodName: paymentMethod?.name,
            paymentMethodType: paymentMethod?.type,
            paymentMethodMemo: paymentMethod?.memo
        )
        context.insert(transaction)
        return transaction
    }
    
    /// 金額の入力文字列を整数にする(数字以外は無視。「¥1,280」→ 1280)
    static func parseAmount(_ text: String) -> Int? {
        Int(text.filter(\.isNumber))
    }
    
    /// 記録を上書きする(OverwriteRecordView の「上書きする」ボタンの処理)
    /// - 金額が読み取れない、または0以下のときは何も変えず false を返す
    /// - カテゴリー・支払方法は「別のものに変えたときだけ」コピーし直す
    ///   (削除済みカテゴリーのまま保存しても、記録の名前・色が消えない)
    /// - id と sortIndex は変わらない
    @discardableResult
    static func update(
        _ transaction: SchemaV2.Transaction,
        type: TransactionType,
        date: Date,
        amountText: String,
        memo: String,
        category: Category?,
        paymentMethod: PaymentMethod?
    ) -> Bool {
        let amount = parseAmount(amountText) ?? 0
        
        transaction.type = type
        transaction.date = date
        transaction.amount = amount
        transaction.memo = memo.isEmpty ? nil : memo
        
        if let category, category.id != transaction.categoryID {
            transaction.categoryID = category.id
            transaction.categoryName = category.name
            transaction.categoryImageName = category.imageName
            transaction.categoryColorHex = category.colorHex
        }
        
        if let paymentMethod, paymentMethod.id != transaction.paymentMethodID {
            transaction.paymentMethodID = paymentMethod.id
            transaction.paymentMethodName = paymentMethod.name
            transaction.paymentMethodType = paymentMethod.type
            transaction.paymentMethodMemo = paymentMethod.memo  
        }
        
        return true
    }
    
    /// 記録を削除する
    static func delete(_ transaction: SchemaV2.Transaction, in context: ModelContext) {
        context.delete(transaction)
    }
    
    /// 金額が0円(空・数字なしを含む)か。保存・上書きの前に確認アラートを出すかの判定に使う
    static func isZeroAmount(_ text: String) -> Bool {
        (parseAmount(text) ?? 0) == 0
    }
}
