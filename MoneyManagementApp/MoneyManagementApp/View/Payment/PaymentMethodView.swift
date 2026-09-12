
import SwiftUI
import SwiftData

struct PaymentMethodView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \PaymentMethod.sortIndex)
    private var paymentMethods: [PaymentMethod]
    
    @State private var showAddPaymentMethodView: Bool = false
    
    @Binding var selectedPaymentMethod: PaymentMethod?
    
    var body: some View {
        NavigationStack {
            Group {
                if paymentMethods.isEmpty {
                    Text("支払方法を追加してください")
                } else {
                    List {
                        ForEach(paymentMethods, id: \.id) { paymentMethod in
                            Section {
                                Button {
                                    selectedPaymentMethod = paymentMethod
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
                    }
                    .listSectionSpacing(13)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        showAddPaymentMethodView.toggle()
                    }
                    .sheet(isPresented: $showAddPaymentMethodView) {
                        AddPaymentMethodView()
                    }
                }
            }
        }
    }
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
        selectedPaymentMethod: .constant(nil)
    )
    .modelContainer(container)
}
