
import SwiftUI
import SwiftData

struct PaymentMethodView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \PaymentMethod.sortIndex)
    private var paymentMethods: [PaymentMethod]
    
    @State private var showAddPaymentMethodView: Bool = false
    @State private var isEditing: Bool = false
    
    @Binding var selectedPaymentMethodID: UUID?
    
    var body: some View {
        NavigationStack {
            List {
                if paymentMethods.isEmpty {
                    VStack(alignment: .center, spacing: 20) {
                        Image(systemName: "wallet.bifold")
                            .font(.system(size: 30))
                        Text("支払い方法を追加してください")
                    }
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 250)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                } else {
                    ForEach(paymentMethods, id: \.id) { paymentMethod in
                        Section {
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
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 3)
                        }
                    }
                    .onMove(perform: movePaymentMethod)
                    .onDelete(perform: deletePaymentMethods)
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
                    .sheet(isPresented: $showAddPaymentMethodView) {
                        AddPaymentMethodView()
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
        }
    }
    
    private func deletePaymentMethods(at offsets: IndexSet) {
        let targets = offsets.map { paymentMethods[$0] }
        
        for paymentMethod in targets {
            if selectedPaymentMethodID == paymentMethod.id {
                selectedPaymentMethodID = nil
            }
            modelContext.delete(paymentMethod)
        }
        
        let remaining = paymentMethods
            .filter { item in !targets.contains(where: { $0.id == item.id }) }
            .sorted { $0.sortIndex < $1.sortIndex }
        
        for (index, item) in remaining.enumerated() {
            item.sortIndex = index
        }
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
