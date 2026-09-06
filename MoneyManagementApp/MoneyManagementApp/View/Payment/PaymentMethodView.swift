
import SwiftUI

struct PaymentMethod: Identifiable {
    let id = UUID()
    let type: PaymentType
    let name: String
    let memo: String
}
enum PaymentType {
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

struct PaymentMethodView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let paymentMethods: [PaymentMethod] = [
        PaymentMethod(type: .cash, name: "現金", memo: ""),
        PaymentMethod(type: .creditCard, name: "楽天カード", memo: "楽天市場用"),
        PaymentMethod(type: .creditCard, name: "三井住友カード", memo: "メインカード"),
        PaymentMethod(type: .bankAccount, name: "福岡銀行", memo: "生活費用"),
        PaymentMethod(type: .electronicMoney, name: "Suica", memo: "交通費"),
        PaymentMethod(type: .QRPayment, name: "PayPay", memo: "コンビニなど")
    ]
    
    var body: some View {
        NavigationStack {
            List(paymentMethods) { paymentMethod in
                Button {
                    // 選択処理
                } label: {
                    HStack {
                        Text(paymentMethod.name)
                            .foregroundStyle(.black)
                        
                        Spacer()
                        
                        Text(paymentMethod.type.title)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("支払方法")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#Preview {
    PaymentMethodView()
}
