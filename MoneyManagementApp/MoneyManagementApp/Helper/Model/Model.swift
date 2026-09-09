
import Foundation
import SwiftData

//MARK: キーボードフォーカス
enum Field: Hashable {
    case price
    case memo
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "収入"
    case expense = "支出"
}

enum PaymentType: String, Codable, CaseIterable {
    case cash
    case creditCard
    case debitCard
    case electronicMoney
    case qrCode
    case pointCard
    case prepaidCard
    case bankTransfer
    case bankDebit
    case other
    
    var title: String {
        switch self {
        case .cash:
            return "現金"
        case .creditCard:
            return "クレジットカード"
        case .debitCard:
            return "デビットカード"
        case .electronicMoney:
            return "電子マネー"
        case .qrCode:
            return "QRコード"
        case .pointCard:
            return "ポイントカード"
        case .prepaidCard:
            return "プリペイドカード"
        case .bankTransfer:
            return "銀行振込"
        case .bankDebit:
            return "口座振替"
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
    var imageName: String
    var sortIndex: Int = 0

    init(
        name: String,
        imageName: String,
        sortIndex: Int = 0
    ) {
        self.name = name
        self.imageName = imageName
        self.sortIndex = sortIndex
    }
}

//MARK: 支払方法
@Model
final class PaymentMethod {
    var id: UUID = UUID()
    var name: String
    var type: PaymentType
    var memo: String?
    var sortIndex: Int = 0
    
    init(
        name: String,
        type: PaymentType,
        memo: String? = nil,
        sortIndex: Int = 0
    ) {
        self.name = name
        self.type = type
        self.memo = memo
        self.sortIndex = sortIndex
    }
}

//@Model
//final class PaymentType {
//    var id: UUID = UUID()
//    var name: String
//    var sortIndex: Int = 0
//    
//    init(
//        name: String,
//        sortIndex: Int = 0
//    ) {
//        self.name = name
//        self.sortIndex = sortIndex
//    }
//}

//MARK: 収支
@Model
final class Transaction {
    var id: UUID = UUID()
    var date: Date
    var amount: Int
    var type: TransactionType
    var category: Category?
    var memo: String?
    var paymentMethod: PaymentMethod?
    var sortIndex: Int = 0
    
    init(
        date: Date = Date(),
        amount: Int = 0,
        type: TransactionType = .expense,
        category: Category? = nil,
        memo: String? = nil,
        paymentMethod: PaymentMethod? = nil,
        sortIndex: Int = 0
    ) {
        self.date = date
        self.amount = amount
        self.type = type
        self.category = category
        self.memo = memo
        self.paymentMethod = paymentMethod
        self.sortIndex = sortIndex
    }
}
