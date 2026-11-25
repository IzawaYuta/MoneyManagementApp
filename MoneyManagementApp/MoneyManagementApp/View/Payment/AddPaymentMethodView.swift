
import SwiftUI
import SwiftData

struct AddPaymentMethodView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @FocusState private var amountFocus: Bool
    
    @Query(sort: \PaymentMethod.sortIndex)
    private var paymentMethods: [PaymentMethod]
    
//    @Query(sort: \PaymentType.sortIndex)
//    private var paymentTypes: [PaymentType]
    
    @State private var paymentType: PaymentType
    @State private var name: String
    @State private var memo: String
//    @State private var shoeAddPaymentTypeAlert: Bool = false
//    @State private var newPaymentTypeTextField: String = ""
    
    // オンボーディング用: 追加後にdismiss()の代わりにこちらを呼ぶ
    var onSave: (() -> Void)? = nil
    // オンボーディング用: キャンセルボタンを非表示にする
    var hideCancelButton: Bool = false
    
    // 編集対象(nilなら新規追加)
    let editingPaymentMethod: PaymentMethod?
    
    private var isEditing: Bool { editingPaymentMethod != nil }
    
    init(
        editingPaymentMethod: PaymentMethod? = nil,
        onSave: (() -> Void)? = nil,
        hideCancelButton: Bool = false
    ) {
        self.editingPaymentMethod = editingPaymentMethod
        self.onSave = onSave
        self.hideCancelButton = hideCancelButton
        // 編集時は既存の値を初期値にする
        _paymentType = State(initialValue: editingPaymentMethod?.type ?? .cash)
        _name = State(initialValue: editingPaymentMethod?.name ?? "")
        _memo = State(initialValue: editingPaymentMethod?.memo ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("登録名", text: $name)
                        .focused($amountFocus)
                    
                    TextField("メモ", text: $memo)
                }
                
                Section {
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
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(isEditing ? "支払方法を編集" : "支払方法を追加")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { amountFocus = true }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "保存" : "追加") {
                        save()
                    }
                    .disabled(!PaymentMethodService.isValid(name: name))
                }
            }
        }
    }
    
    private func save() {
        do {
            if let editingPaymentMethod {
                try PaymentMethodService.update(
                    editingPaymentMethod,
                    name: name,
                    type: paymentType,
                    memo: memo,
                    in: modelContext
                )
            } else {
                try PaymentMethodService.add(
                    name: name,
                    type: paymentType,
                    memo: memo,
                    in: modelContext
                )
            }
            dismiss()
        } catch {
            print("支払方法の保存に失敗しました: \(error)")
        }
    }
}


#Preview {
    AddPaymentMethodView()
}
