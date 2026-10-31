
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

// MARK: カテゴリー
@Model
final class Category {
    var id: UUID = UUID()
    var name: String
    var imageName: String
    var colorHex: String
    var sortIndex: Int = 0
    
    init(
        name: String,
        imageName: String,
        colorHex: String,
        sortIndex: Int = 0
    ) {
        self.name = name
        self.imageName = imageName
        self.colorHex = colorHex
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
//    var category: Category
    var memo: String?
    var sortIndex: Int = 0
    
    // カテゴリーのコピー保存
    var categoryID: UUID
    var categoryName: String
    var categoryImageName: String
    var categoryColorHex: String
    // 支払方法のコピー保存
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

//MARK: 予算
/// カテゴリーごとの予算(支出)/目標(収入)。
/// 期間(startMonth...endMonth)ごとに1行を持つ。同じカテゴリー・同じtypeの行は期間を重ねない。
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

//MARK: 年月(yyyymm)ヘルパー
enum YearMonth {
    /// Date → yyyymm
    static func make(from date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year, .month], from: date)
        return (c.year ?? 0) * 100 + (c.month ?? 0)
    }
    
    /// 前月(202601 → 202512)
    static func previous(_ yyyymm: Int) -> Int {
        let year = yyyymm / 100
        let month = yyyymm % 100
        return month == 1 ? (year - 1) * 100 + 12 : year * 100 + (month - 1)
    }
    
    /// 翌月(202512 → 202601)
    static func next(_ yyyymm: Int) -> Int {
        let year = yyyymm / 100
        let month = yyyymm % 100
        return month == 12 ? (year + 1) * 100 + 1 : year * 100 + (month + 1)
    }
}
