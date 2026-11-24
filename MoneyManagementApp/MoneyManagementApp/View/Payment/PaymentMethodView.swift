
import SwiftUI
import SwiftData

struct PaymentMethodView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \PaymentMethod.sortIndex)
    private var paymentMethods: [PaymentMethod]
    
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    
    @State private var showAddPaymentMethodView: Bool = false
    @State private var isEditing: Bool = false
    
    @Binding var selectedPaymentMethodID: UUID?
    
    /// 最近使った支払方法(最大3件、新しい順)
    private var recentPaymentMethods: [PaymentMethod] {
        PaymentMethodService.recent(from: paymentMethods, transactions: transactions)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if paymentMethods.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "wallet.bifold")
                                .font(.system(size: 32))
                                .foregroundStyle(.gray)
                            
                            Text("支払方法がありません")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.black)
                            
                            Button(action: {
                                showAddPaymentMethodView.toggle()
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("追加")
                                }
                                .padding(13)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue.opacity(0.1))
                            )
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .padding(.top, 200)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    
                } else {
                    if !recentPaymentMethods.isEmpty {
                        Section("最近の支払い") {
                            ForEach(recentPaymentMethods, id: \.id) { paymentMethod in
                                paymentMethodRow(paymentMethod)
                            }
                        }
                    }
                    
                    Section(recentPaymentMethods.isEmpty ? "" : "すべて") {
                        ForEach(paymentMethods, id: \.id) { paymentMethod in
                            paymentMethodRow(paymentMethod)
                        }
                        .onDelete(perform: deletePaymentMethods)
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .listSectionSpacing(13)
            .navigationTitle("支払い方法")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button("完了") {
                            isEditing = false
                        }
                    } else {
                        Button("閉じる") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showAddPaymentMethodView.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                //                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                //
                //                ToolbarItem(placement: .topBarTrailing) {
                //                    Button(action: {
                //                        isEditing.toggle()
                //                    }) {
                //                        Image(systemName: "list.bullet")
                //                    }
                //                }
            }
            .sheet(isPresented: $showAddPaymentMethodView) {
                AddPaymentMethodView()
            }
        }
    }
    
    private func paymentMethodRow(_ paymentMethod: PaymentMethod) -> some View {
        Button {
            guard !isEditing else { return }
            selectedPaymentMethodID = paymentMethod.id
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(paymentMethod.name)
                        .foregroundStyle(.black)
                    
                    Spacer()
                    
                    Text(paymentMethod.type.title)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                if let memo = paymentMethod.memo, !memo.isEmpty {
                    Text(memo)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            }
            .contentShape(Rectangle())      
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 3)
    }
    
    private func deletePaymentMethods(at offsets: IndexSet) {
        let targets = offsets.map { paymentMethods[$0] }
        
        // 選択中の支払方法が削除対象なら、参照が消える前にリセット
        if let selected = selectedPaymentMethodID,
           targets.contains(where: { $0.id == selected }) {
            selectedPaymentMethodID = nil
        }
        
        try? PaymentMethodService.delete(ids: Set(targets.map(\.id)), in: modelContext)
    }
    
    private func movePaymentMethod(from source: IndexSet, to destination: Int) {
        var reordered = paymentMethods
        reordered.move(fromOffsets: source, toOffset: destination)
        
        for (index, item) in reordered.enumerated() {
            item.sortIndex = index
        }
    }
}

#Preview("データなし") {
    let container = try! ModelContainer(
        for: PaymentMethod.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    return PaymentMethodView(
        selectedPaymentMethodID: .constant(nil)
    )
    .modelContainer(container)
}

#Preview {
    let container = try! ModelContainer(
        for: PaymentMethod.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let context = container.mainContext
    
    context.insert(
        PaymentMethod(
            name: "三井住友カード",
            type: .creditCard,
            memo: "メインカード",
            sortIndex: 0
        )
    )
    
    context.insert(
        PaymentMethod(
            name: "PayPay",
            type: .qrCode,
            sortIndex: 1
        )
    )
    
    context.insert(
        PaymentMethod(
            name: "現金",
            type: .cash,
            sortIndex: 2
        )
    )
    
    return PaymentMethodView(
        selectedPaymentMethodID: .constant(nil)
    )
    .modelContainer(container)
}
