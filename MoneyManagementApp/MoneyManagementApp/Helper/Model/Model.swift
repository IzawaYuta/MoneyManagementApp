
import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
    case income = "収入"
    case expense = "支出"
}

enum PaymentType: String, Codable, CaseIterable {
    case cash
    case creditCard
    case debitCard
    case bankAccount
    case electronicMoney
    case QRPayment
    case prepaid
    case points
    case other
    
    var title: String {
        switch self {
        case .cash:
            return "現金"
        case .creditCard:
            return "クレジットカード"
        case .debitCard:
            return "デビットカード"
        case .bankAccount:
            return "銀行口座"
        case .electronicMoney:
            return "電子マネー"
        case .QRPayment:
            return "QR決済"
        case .prepaid:
            return "プリペイド"
        case .points:
            return "ポイント"
        case .other:
            return "その他"
        }
    }
}

//MARK: カテゴリー
@Model
final class Category {
    var id: UUID = UUID()
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

//MARK: 支払方法
@Model
final class PaymentMethod {
    var id: UUID = UUID()
    var name: String
    var type: PaymentType
    var memo: String
    
    init(
        name: String,
        type: PaymentType,
        memo: String = ""
    ) {
        self.name = name
        self.type = type
        self.memo = memo
    }
}

//MARK: 収支
@Model
final class Transaction {
    var id: UUID = UUID()
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
