
import SwiftUI

struct AddPaymentMethodView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: PaymentType = .cash
    @State private var name: String = ""
    @State private var memo: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("支払方法", selection: $selectedType) {
                        Text("現金")
                            .tag(PaymentType.cash)
                        
                        Text("クレジットカード")
                            .tag(PaymentType.creditCard)
                        
                        Text("デビットカード")
                            .tag(PaymentType.debitCard)
                        
                        Text("銀行口座")
                            .tag(PaymentType.bankAccount)
                        
                        Text("電子マネー")
                            .tag(PaymentType.electronicMoney)
                        
                        Text("QR決済")
                            .tag(PaymentType.QRPayment)
                        
                        Text("プリペイド")
                            .tag(PaymentType.prepaid)
                        
                        Text("ポイント")
                            .tag(PaymentType.points)
                        
                        Text("その他")
                            .tag(PaymentType.other)
                    }
                    
                    TextField("名前", text: $name)
                    
                    TextField("メモ", text: $memo)
                }
            }
            .navigationTitle("支払方法を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        let paymentMethod = PaymentMethod(
                            name: name,
                            type: selectedType,
                            memo: memo
                        )
                        
                        print(paymentMethod)
                        
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddPaymentMethodView()
}
