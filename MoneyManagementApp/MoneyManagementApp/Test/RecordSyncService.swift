
import Foundation
import SwiftData

/// カテゴリー・支払方法を編集したときに、コピーを持っている記録・いつもの収支へ反映する。
/// 他のサービスと同じく、保存(save)は呼び出し側の autosave に任せる。
@MainActor
enum RecordSyncService {
    
    /// カテゴリーの名前・アイコン・色を、記録といつもの収支へ反映する
    static func sync(_ category: Category, in context: ModelContext) throws {
        let id = category.id
        
        let transactions = try context.fetch(
            FetchDescriptor<SchemaV2.Transaction>(predicate: #Predicate { $0.categoryID == id })
        )
        for t in transactions {
            t.categoryName = category.name
            t.categoryImageName = category.imageName
            t.categoryColorHex = category.colorHex
        }
        
        let usuals = try context.fetch(
            FetchDescriptor<SchemaV2.UsualRecord>(predicate: #Predicate { $0.categoryID == id })
        )
        for u in usuals {
            u.categoryName = category.name
            u.categoryImageName = category.imageName
            u.categoryColorHex = category.colorHex
        }
    }
    
    /// 支払方法の名前・種類・メモを、記録へ、名前をいつもの収支へ反映する
    static func sync(_ paymentMethod: PaymentMethod, in context: ModelContext) throws {
        let id = paymentMethod.id
        
        let transactions = try context.fetch(
            FetchDescriptor<SchemaV2.Transaction>(predicate: #Predicate { $0.paymentMethodID == id })
        )
        for t in transactions {
            t.paymentMethodName = paymentMethod.name
            t.paymentMethodType = paymentMethod.type
            t.paymentMethodMemo = paymentMethod.memo
        }
        
        let usuals = try context.fetch(
            FetchDescriptor<SchemaV2.UsualRecord>(predicate: #Predicate { $0.paymentMethodID == id })
        )
        for u in usuals {
            u.paymentMethodName = paymentMethod.name
        }
    }
    
    /// 既存データをすべてそろえる(今までの変更で食い違っている分を直す用)
    static func syncAll(in context: ModelContext) throws {
        for category in try context.fetch(FetchDescriptor<Category>()) {
            try sync(category, in: context)
        }
        for method in try context.fetch(FetchDescriptor<PaymentMethod>()) {
            try sync(method, in: context)
        }
    }
}
