
import Foundation

// MARK: - 表示用の行データ
struct BudgetRow: Identifiable {
    let id: UUID          // categoryID
    let name: String
    let imageName: String
    let colorHex: String
    let budget: Int
    let spent: Int
    let sortIndex: Int

    var remaining: Int { budget - spent }
    var isOver: Bool { remaining < 0 }
    var remainingRatio: Double { budgetRemainingRatio(budget: budget, spent: spent) }
}

extension BudgetService {

    /// 月ごとの行データを作る
    /// - transactions は「その月の取引」を渡す(View の @Query と同じ)。種別はここで絞り込む
    /// - 行になるのは、その月に予算が適用されているカテゴリーだけ
    static func rows(
        budgets: [Budget],
        categories: [Category],
        transactions: [SchemaV2.Transaction],
        month: Int,
        type: TransactionType
    ) -> [BudgetRow] {
        // 対象月に適用される予算(カテゴリーごとに1件)
        var appliedByCategory: [UUID: Budget] = [:]
        for (id, items) in Dictionary(grouping: budgets, by: \.categoryID) {
            if let b = applied(in: items, type: type, month: month) {
                appliedByCategory[id] = b
            }
        }

        // カテゴリーごとの使用額
        let monthTransactions = transactions.filter { $0.type == type }
        let spentByCategory = Dictionary(grouping: monthTransactions, by: \.categoryID)
            .mapValues { $0.map(\.amount).reduce(0, +) }

        let categoryByID = Dictionary(categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        let rows: [BudgetRow] = appliedByCategory.values.map { b in
            let spent = spentByCategory[b.categoryID] ?? 0
            if let c = categoryByID[b.categoryID] {
                return BudgetRow(
                    id: b.categoryID, name: c.name, imageName: c.imageName, colorHex: c.colorHex,
                    budget: b.amount, spent: spent, sortIndex: c.sortIndex
                )
            }
            // 削除済みカテゴリー: 取引にコピー保存された情報を使う
            if let t = monthTransactions.first(where: { $0.categoryID == b.categoryID }) {
                return BudgetRow(
                    id: b.categoryID, name: t.categoryName ?? "-", imageName: t.categoryImageName ?? "-",
                    colorHex: t.categoryColorHex ?? "-",
                    budget: b.amount, spent: spent, sortIndex: Int.max
                )
            }
            return BudgetRow(
                id: b.categoryID, name: "削除済みのカテゴリー", imageName: "questionmark.circle",
                colorHex: "#9E9E9E",
                budget: b.amount, spent: spent, sortIndex: Int.max
            )
        }

        return rows.sorted {
            $0.sortIndex != $1.sortIndex ? $0.sortIndex < $1.sortIndex : $0.name < $1.name
        }
    }

    /// 総予算(行の予算の合計)と、使用済み(予算のあるカテゴリー分のみ)
    static func totals(of rows: [BudgetRow]) -> (budget: Int, spent: Int) {
        (rows.reduce(0) { $0 + $1.budget }, rows.reduce(0) { $0 + $1.spent })
    }

    /// 予算設定シートの総予算(その月に適用される予算の合計。削除済みカテゴリー分も含む)
    static func totalAmount(of budgets: [Budget], type: TransactionType, month: Int) -> Int {
        Dictionary(grouping: budgets, by: \.categoryID).values
            .compactMap { applied(in: $0, type: type, month: month)?.amount }
            .reduce(0, +)
    }

    /// 適用期間の表示(例: "2026年11月のみ" / "2026年11月〜2026年12月" / "2026年11月〜")
    static func periodText(of budget: Budget?) -> String? {
        guard let b = budget else { return nil }
        if let end = b.endMonth {
            return b.startMonth == end
            ? "\(YearMonth.label(b.startMonth))のみ"
            : "\(YearMonth.label(b.startMonth))〜\(YearMonth.label(end))"
        }
        return "\(YearMonth.label(b.startMonth))〜"
    }
}
