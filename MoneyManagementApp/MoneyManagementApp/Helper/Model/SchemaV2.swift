
import Foundation
import SwiftData


enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SchemaV1.Category.self, SchemaV1.PaymentMethod.self,
         Transaction.self, Budget.self, UsualRecord.self]
    }
    
    @Model final class Transaction {
        var id: UUID = UUID()
        var date: Date
        var amount: Int
        var type: TransactionType
        var memo: String?
        var sortIndex: Int = 0
        var createdAt: Date = Date()
        // ↓ Optional化
        var categoryID: UUID?
        var categoryName: String?
        var categoryImageName: String?
        var categoryColorHex: String?
        var paymentMethodID: UUID?
        var paymentMethodName: String?
        var paymentMethodType: PaymentType?
        var paymentMethodMemo: String?
        
        init(
            date: Date = Date(),
            amount: Int = 0,
            type: TransactionType = .expense,
            memo: String? = nil,
            sortIndex: Int = 0,
            categoryID: UUID? = nil,
            categoryName: String? = nil,
            categoryImageName: String? = nil,
            categoryColorHex: String? = nil,
            paymentMethodID: UUID? = nil,
            paymentMethodName: String? = nil,
            paymentMethodType: PaymentType? = nil,
            paymentMethodMemo: String? = nil
        ) {
            self.date = date
            self.amount = amount
            self.type = type
            self.memo = memo
            self.sortIndex = sortIndex
            self.categoryID = categoryID
            self.categoryName = categoryName
            self.categoryImageName = categoryImageName
            self.categoryColorHex = categoryColorHex
            self.paymentMethodID = paymentMethodID
            self.paymentMethodName = paymentMethodName
            self.paymentMethodType = paymentMethodType
            self.paymentMethodMemo = paymentMethodMemo
        }
    }
    
    @Model
    final class Budget {
        var id: UUID = UUID()
        /// 対象カテゴリー(Transactionと同様、リレーションではなくID参照)
        var categoryID: UUID = UUID()
        /// 支出=予算、収入=目標
        var type: TransactionType = TransactionType.expense
        var amount: Int = 0
        /// 適用開始月(yyyymm 例: 202611)
        var startMonth: Int = 0
        /// 適用終了月(yyyymm)。nil = 以降ずっと続く。単月のみの場合は startMonth と同じ値
        var endMonth: Int?
        var createdAt: Date = Date()
        var updatedAt: Date = Date()
        
        init(
            categoryID: UUID,
            type: TransactionType = .expense,
            amount: Int = 0,
            startMonth: Int,
            endMonth: Int? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.categoryID = categoryID
            self.type = type
            self.amount = amount
            self.startMonth = startMonth
            self.endMonth = endMonth
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
        
        /// 指定した年月(yyyymm)がこの予算の適用期間に含まれるか
        func contains(month: Int) -> Bool {
            guard startMonth <= month else { return false }
            if let endMonth { return month <= endMonth }
            return true
        }
    }
    
    //いつもの収支
    @Model
    final class UsualRecord {
        var id: UUID = UUID()
        var title: String = ""
        var amount: Int = 0
        var typeRaw: String = ""
        var memo: String = ""
        var categoryID: UUID?
        var categoryName: String?
        var categoryImageName: String?
        var categoryColorHex: String?
        var paymentMethodID: UUID?
        var paymentMethodName: String?
        var createdAt: Date = Date()
        
        init(
            title: String,
            amount: Int,
            typeRaw: String,
            memo: String,
            categoryName: String? = nil,
            paymentMethodName: String? = nil
        ) {
            self.title = title
            self.amount = amount
            self.typeRaw = typeRaw
            self.memo = memo
            self.categoryName = categoryName
            self.paymentMethodName = paymentMethodName
        }
    }
}
