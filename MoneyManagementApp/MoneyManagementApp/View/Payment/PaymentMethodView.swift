
import SwiftUI
import SwiftData

struct PaymentMethodView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Query private var paymentMethods: [PaymentMethod]
    
    @State private var showAddPaymentMethodView: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if paymentMethods.isEmpty {
                    Text("支払方法を追加してください")
                } else {
                    List {
                        ForEach(paymentMethods, id: \.id) { paymentMethod in
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
    PaymentMethodView()
}
