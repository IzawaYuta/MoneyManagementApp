
import SwiftData
import Foundation

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Category.self, PaymentMethod.self, Transaction.self]
    }
    
    @Model final class Category {
        var id: UUID = UUID()
        var name: String
        var imageName: String
        var colorHex: String
        var sortIndex: Int = 0
        init(name: String, imageName: String, colorHex: String, sortIndex: Int = 0) {
            self.name = name; self.imageName = imageName
            self.colorHex = colorHex; self.sortIndex = sortIndex
        }
    }
    
    @Model final class PaymentMethod {
        var id: UUID = UUID()
        var name: String
        var type: PaymentType
        var memo: String?
        var sortIndex: Int = 0
        init(name: String, type: PaymentType, memo: String? = nil, sortIndex: Int = 0) {
            self.name = name; self.type = type
            self.memo = memo; self.sortIndex = sortIndex
        }
    }
    
    @Model final class Transaction {
        var id: UUID = UUID()
        var date: Date
        var amount: Int
        var type: TransactionType
        var memo: String?
        var sortIndex: Int = 0
        var categoryID: UUID
        var categoryName: String
        var categoryImageName: String
        var categoryColorHex: String
        var paymentMethodID: UUID?
        var paymentMethodName: String?
        var paymentMethodType: PaymentType?
        var paymentMethodMemo: String?
        init(
            date: Date = Date(),
            amount: Int = 0,
            type: TransactionType = .expense,
            //        category: Category,
            memo: String? = nil,
            sortIndex: Int = 0,
            categoryID: UUID,
            categoryName: String,
            categoryImageName: String,
            categoryColorHex: String,
            paymentMethodID: UUID? = nil,
            paymentMethodName: String? = nil,
            paymentMethodType: PaymentType? = nil,
            paymentMethodMemo: String? = nil
        ) {
            self.date = date
            self.amount = amount
            self.type = type
            //        self.category = category
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
}
