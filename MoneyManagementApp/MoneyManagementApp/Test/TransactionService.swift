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
            memo: memo,
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
}