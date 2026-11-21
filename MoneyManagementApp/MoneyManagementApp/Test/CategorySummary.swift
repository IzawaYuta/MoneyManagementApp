//
//  CategorySummary.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/11/21.
//


import Foundation
import CoreGraphics

// MARK: - 集計用モデル(カテゴリーごとの月合計)
struct CategorySummary: Identifiable {
    let id: UUID            // Transaction.categoryID
    let name: String
    let imageName: String   // SF Symbols名を想定
    let amount: Int
    let color: String       // Category.colorHex
}

enum MonthlyChartService {

    /// カテゴリー未設定の取引をまとめるための固定ID
    static let uncategorizedID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    /// 指定した月・種別(収入/支出)で絞り込み、カテゴリーごとに合計する
    /// 並びは、金額の大きい順(同額なら名前順)
    static func summaries(
        from transactions: [SchemaV2.Transaction],
        month: Date,
        type: TransactionType,
        calendar: Calendar = .current
    ) -> [CategorySummary] {
        let filtered = transactions.filter { t in
            t.type == type &&
            calendar.isDate(t.date, equalTo: month, toGranularity: .month)
        }

        let grouped: [UUID: [SchemaV2.Transaction]] = Dictionary(grouping: filtered) { t in
            t.categoryID ?? uncategorizedID
        }

        var result: [CategorySummary] = []
        for (id, items) in grouped {
            guard let first = items.first else { continue }
            let total = items.reduce(0) { $0 + $1.amount }
            result.append(
                CategorySummary(
                    id: id,
                    name: first.categoryName ?? "未分類",
                    imageName: first.categoryImageName ?? "questionmark",
                    amount: total,
                    color: first.categoryColorHex ?? "#111111"
                )
            )
        }

        return result.sorted { a, b in
            if a.amount != b.amount { return a.amount > b.amount }
            return a.name < b.name
        }
    }

    /// 合計金額
    static func total(of items: [CategorySummary]) -> Int {
        items.reduce(0) { $0 + $1.amount }
    }

    /// 角度に対応する累計金額から、カテゴリーを求める
    static func categoryID(at value: Double, items: [CategorySummary]) -> UUID? {
        var cumulative = 0.0
        for item in items {
            cumulative += Double(item.amount)
            if value <= cumulative { return item.id }
        }
        return nil
    }

    /// 選択中は大きく、他は小さく、未選択時は標準
    static func radiusRatio(for id: UUID, selectedID: UUID?) -> Double {
        guard let selected = selectedID else { return 0.9 }
        return selected == id ? 1.0 : 0.8
    }

    /// 選択中以外は薄くする
    static func opacity(for id: UUID, selectedID: UUID?) -> Double {
        guard let selected = selectedID else { return 1.0 }
        return selected == id ? 1.0 : 0.3
    }

    /// タップ位置が扇形の内側にあるときだけ、そのカテゴリーのIDを返す(余白なら nil)
    static func tappedCategoryID(
        at point: CGPoint,
        center: CGPoint,
        fullRadius: CGFloat,
        items: [CategorySummary],
        selectedID: UUID?
    ) -> UUID? {
        let dx = Double(point.x - center.x)
        let dy = Double(point.y - center.y)
        let distance = hypot(dx, dy)

        // 12時方向を0として時計回りの角度(0〜2π)
        var angle = atan2(dx, -dy)
        if angle < 0 { angle += 2 * .pi }
        let value = angle / (2 * .pi) * Double(total(of: items))

        guard let tapped = categoryID(at: value, items: items) else { return nil }
        // 現在の表示半径(拡大・縮小後)の外側(余白)は無視
        guard distance <= Double(fullRadius) * radiusRatio(for: tapped, selectedID: selectedID) else {
            return nil
        }
        return tapped
    }

    /// 全体に対する割合の表示(例: "12.5%")。合計が0以下のときは "0.0%"
    static func percentText(amount: Int, total: Int) -> String {
        guard total > 0 else { return "0.0%" }
        return String(format: "%.1f%%", Double(amount) / Double(total) * 100)
    }
}