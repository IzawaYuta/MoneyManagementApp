
import SwiftUI
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

@MainActor
enum PreviewContainer {
    static func make() -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(
            for: schema,
            migrationPlan: MigrationPlan.self,
            configurations: config
        )
    }
}
