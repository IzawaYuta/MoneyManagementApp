//
//  UITestSupport.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/11/21.
//


import Foundation
import SwiftData

/// UIテスト用の起動設定。起動引数 "-uiTesting" があるときだけ有効になる
enum UITestSupport {
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")
    /// "-uiTestingNoSeed" を付けると、テスト用データを入れずに起動する
    static let usesSeedData = !ProcessInfo.processInfo.arguments.contains("-uiTestingNoSeed")

    /// テスト用のカテゴリー・支払方法(記録は入れない)
    @MainActor
    static func seed(_ context: ModelContext) {
        guard usesSeedData else { return }

        context.insert(Category(name: "食費", imageName: "fork.knife", colorHex: "#FF6B6B", sortIndex: 0))
        context.insert(Category(name: "交通費", imageName: "car", colorHex: "#FFD43B", sortIndex: 1))

        context.insert(PaymentMethod(name: "現金", type: .cash, sortIndex: 0))
        context.insert(PaymentMethod(name: "メインカード", type: .creditCard, memo: "毎月27日引き落とし", sortIndex: 1))

        try? context.save()
    }
}