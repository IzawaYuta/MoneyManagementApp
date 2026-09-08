
import SwiftUI
import SwiftData

struct AddPaymentMethodView: View {
    
    @Environment(\.dismiss) private var dismiss
    
//    @Query(sort: \PaymentType.sortIndex)
//    private var paymentTypes: [PaymentType]
    
    @State private var paymentType: PaymentType = .cash
    @State private var name: String = ""
    @State private var memo: String = ""
//    @State private var shoeAddPaymentTypeAlert: Bool = false
//    @State private var newPaymentTypeTextField: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("登録名", text: $name)
                    
                    TextField("メモ", text: $memo)
                }
                
                Section("カテゴリー") {
                    ForEach(PaymentType.allCases, id: \.self) { type in
                        Button {
                            paymentType = type
                        } label: {
                            HStack {
                                Text(type.title)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if type == paymentType {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
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
                    HStack {
                        Button("追加") {
                            let paymentMethod = PaymentMethod(
                                name: name,
                                type: paymentType,
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
}

#Preview {
    AddPaymentMethodView()
}
