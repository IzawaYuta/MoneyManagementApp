
import SwiftUI
import SwiftData

struct PaymentMethodView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Query private var paymentMethods: [PaymentMethod]
    
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
