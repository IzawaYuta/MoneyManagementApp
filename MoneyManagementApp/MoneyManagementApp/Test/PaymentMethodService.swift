
import Foundation
import SwiftData


enum PaymentMethodError: Error {
    case emptyName
}

@MainActor
enum PaymentMethodService {

    /// 名前の前後の空白・改行(全角スペース、タブを含む)を取り除く。途中の空白は残す
    static func trimmedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 追加ボタンを押せる条件(名前が空・空白だけではないこと)
    static func isValid(name: String) -> Bool {
        !trimmedName(name).isEmpty
    }
    
    /// 末尾(最大sortIndex + 1)に支払方法を追加する
    /// - 名前の前後の空白は削除して保存する。メモが空文字ならnilで保存する
    /// - 名前が空・空白だけのときは、何も保存せずエラーを投げる
    @discardableResult
    static func add(
        name: String,
        type: PaymentType,
        memo: String,
        in context: ModelContext
    ) throws -> PaymentMethod {
        let name = trimmedName(name)
        guard !name.isEmpty else { throw PaymentMethodError.emptyName }
        
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
    
    /// 名前・種類・メモを更新する(sortIndexは変えない)
    /// - 名前の前後の空白は削除して保存する。メモが空文字ならnilで保存する
    /// - 名前が空・空白だけのときは、何も変えずエラーを投げる
    /// - 記録済みの収支・いつもの収支のコピーも、同じ内容に更新する
    static func update(
        _ paymentMethod: PaymentMethod,
        name: String,
        type: PaymentType,
        memo: String,
        in context: ModelContext
    ) throws {
        let name = trimmedName(name)
        guard !name.isEmpty else { throw PaymentMethodError.emptyName }
        
        paymentMethod.name = name
        paymentMethod.type = type
        paymentMethod.memo = memo.isEmpty ? nil : memo
        
        try RecordSyncService.sync(paymentMethod, in: context)
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
