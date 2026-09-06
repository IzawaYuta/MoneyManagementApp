
import Foundation
import SwiftData

enum TransactionType: String, Codable {
    case income = "収入"
    case expense = "支出"
}

enum PaymentMethodType: String, Codable {
    case cash = "現金"
    case creditCard = "クレジットカード"
    case debitCard = "デビットカード"
    case bankTransfer = "銀行振込"
    case bankAccount = "銀行"
    case electronicMoney = "電子マネー"
    case qRPayment = "QR決済"
    case other = "その他"
}

@Model
final class Category {
    var id: UUID = UUID()
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

@Model
final class PaymentMethod {
    var id: UUID = UUID()
    var name: String
    var type: PaymentMethodType
    var memo: String
    
    init(
        name: String,
        type: PaymentMethodType,
        memo: String = ""
    ) {
        self.name = name
        self.type = type
        self.memo = memo
    }
}

@Model
final class Transaction {
    var date: Date
    var amount: Int
    var type: TransactionType
    var category: Category?
    var memo: String
    var paymentMethod: PaymentMethod?
    
    init(
        date: Date = Date(),
        amount: Int = 0,
        type: TransactionType = .expense,
        category: Category? = nil,
        memo: String = "",
        paymentMethod: PaymentMethod? = nil
    ) {
        self.date = date
        self.amount = amount
        self.type = type
        self.category = category
        self.memo = memo
        self.paymentMethod = paymentMethod
    }
}
