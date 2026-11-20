
import Foundation
import SwiftData

@MainActor
enum PaymentMethodService {

    /// 追加ボタンを押せる条件(AddPaymentMethodView と同じ)
    static func isValid(name: String) -> Bool {
        !name.isEmpty
    }

    /// 末尾(最大sortIndex + 1)に支払方法を追加する。メモが空文字ならnilで保存する
    @discardableResult
    static func add(
        name: String,
        type: PaymentType,
        memo: String,
        in context: ModelContext
    ) throws -> PaymentMethod {
        let all = try context.fetch(FetchDescriptor<PaymentMethod>())
        let nextSortIndex = (all.map(\.sortIndex).max() ?? -1) + 1

        let paymentMethod = PaymentMethod(
            name: name,
            type: type,
            memo: memo.isEmpty ? nil : memo,
            sortIndex: nextSortIndex
        )
        context.insert(paymentMethod)
        return paymentMethod
    }

    /// 指定IDの支払方法を削除し、残りのsortIndexを0から詰め直す
    static func delete(ids: Set<UUID>, in context: ModelContext) throws {
        let all = try context.fetch(
            FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.sortIndex)])
        )

        for method in all where ids.contains(method.id) {
            context.delete(method)
        }

        let remaining = all.filter { !ids.contains($0.id) }
        for (index, method) in remaining.enumerated() {
            method.sortIndex = index
        }
    }

    /// 最近使った支払方法(重複なし・新しい順・最大limit件)
    /// - transactions は新しい順に並んでいる前提(View の @Query と同じ)
    static func recent(
        from methods: [PaymentMethod],
        transactions: [SchemaV2.Transaction],
        limit: Int = 3
    ) -> [PaymentMethod] {
        var seen = Set<UUID>()
        var result: [PaymentMethod] = []

        for t in transactions {
            guard let id = t.paymentMethodID, seen.insert(id).inserted else { continue }
            if let method = methods.first(where: { $0.id == id }) {
                result.append(method)
                if result.count == limit { break }
            }
        }
        return result
    }
}
