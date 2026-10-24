
import SwiftUI
import SwiftData

struct AddPaymentMethodView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \PaymentMethod.sortIndex)
    private var paymentMethods: [PaymentMethod]
    
//    @Query(sort: \PaymentType.sortIndex)
//    private var paymentTypes: [PaymentType]
    
    @State private var paymentType: PaymentType = .cash
    @State private var name: String = ""
    @State private var memo: String = ""
//    @State private var shoeAddPaymentTypeAlert: Bool = false
//    @State private var newPaymentTypeTextField: String = ""
    
    // オンボーディング用: 追加後にdismiss()の代わりにこちらを呼ぶ
    var onSave: (() -> Void)? = nil
    // オンボーディング用: キャンセルボタンを非表示にする
    var hideCancelButton: Bool = false

    
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
                    Button("追加") {
                        // 追加前
                        print("========== 📋 追加前の支払方法一覧 ==========")
                        for payment in paymentMethods.sorted(by: { $0.sortIndex < $1.sortIndex }) {
                            print("📌 \(payment.name) | type: \(payment.type.title) | memo: \(payment.memo ?? "nil") | sortIndex: \(payment.sortIndex)")
                        }
                        
                        let nextSortIndex = (paymentMethods.map(\.sortIndex).max() ?? -1) + 1
                        
                        let paymentMethod = PaymentMethod(
                            name: name,
                            type: paymentType,
                            memo: memo.isEmpty ? nil : memo,
                            sortIndex: nextSortIndex
                        )
                        
                        // 追加するもの
                        print("========== ➕ 追加する支払方法 ==========")
                        print("📌 名前: \(paymentMethod.name)")
                        print("💳 種類: \(paymentMethod.type.title)")
                        print("📝 メモ: \(paymentMethod.memo ?? "nil")")
                        print("🔢 sortIndex: \(paymentMethod.sortIndex)")
                        
                        modelContext.insert(paymentMethod)
                        
                        // 追加後
                        print("========== 📋 追加後の支払方法一覧 ==========")
                        for payment in paymentMethods.sorted(by: { $0.sortIndex < $1.sortIndex }) {
                            print("📌 名前: \(payment.name)")
                            print("💳 種類: \(payment.type.title)")
                            print("📝 メモ: \(payment.memo ?? "nil")")
                            print("🔢 sortIndex: \(payment.sortIndex)")
                        }
                        
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
