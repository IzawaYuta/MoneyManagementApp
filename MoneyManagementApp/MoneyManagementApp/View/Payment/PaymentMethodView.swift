
import SwiftUI

//struct PaymentMethod: Identifiable {
//    let id = UUID()
//    let type: PaymentType
//    let name: String
//    let memo: String
//}
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
        PaymentMethod(name: "現金", type: .cash, memo: ""),
        PaymentMethod(name: "楽天カード", type: .creditCard, memo: "楽天市場用"),
        PaymentMethod(name: "三井住友カード", type: .creditCard, memo: "メインカード"),
        PaymentMethod(name: "福岡銀行", type: .bankAccount, memo: "生活費用"),
        PaymentMethod(name: "Suica", type: .electronicMoney, memo: "交通費"),
        PaymentMethod(name: "PayPay", type: .qRPayment, memo: "コンビニなど")
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
