
import SwiftUI
import SwiftData

struct OnboardingPaymentMethodView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var paymentMethodName = ""
    @State private var selectedType: PaymentType = .cash
    @State private var memo = ""
    @State private var selectedQuickName: String?
    
    var onFinish: () -> Void
    
    // よく使う支払方法(名前, 種類)
    private let quickPaymentMethods: [(name: String, type: PaymentType)] = [
        ("現金", .cash),
        ("クレジットカード", .creditCard),
        ("デビットカード", .debitCard),
        ("電子マネー", .qrCode),
        ("口座振替", .bankTransfer),
        ("その他", .other)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 進捗表示
            VStack(spacing: 8) {
                Text("2 / 2")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.gray)
                
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 11, height: 11)
                    
                    Circle()
                        .fill(Color.black)
                        .frame(width: 11, height: 11)
                }
            }
            .padding(.top, 18)
            .padding(.horizontal, 10)
            
            // MARK: - 説明
            VStack(spacing: 16) {
                Image(systemName: "wallet.bifold")
                    .font(.system(size: 40))
                    .foregroundStyle(.black)
                //                    .frame(width: 52, height: 52)
                //                    .background(Color.black)
                //                    .clipShape(Circle())

                VStack(spacing: 6) {
                    Text("お支払い方法を追加")
                        .font(.title)
                        .foregroundStyle(.black)
                    
                    Text("お金の支払い・受け取りに使う\n方法を登録しましょう")
                        .font(.system(size: 17))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 35)
            .padding(.horizontal, 10)
            
            // MARK: - 入力
            VStack(alignment: .leading, spacing: 6) {
                Text("支払い方法名")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                
                TextField("例: 楽天カード、PayPay...", text: $paymentMethodName)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    )
            }
            .padding(.top, 40)
            .padding(.horizontal, 10)
            
            // MARK: - クイック選択
            VStack(alignment: .leading, spacing: 8) {
                Text("よく使う支払方法から選ぶ")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .padding(.top, 20)
                
                QuickPaymentMethodFlowLayout(spacing: 8) {
                    ForEach(quickPaymentMethods, id: \.name) { item in
                        quickPaymentMethodButton(name: item.name, type: item.type)
                    }
                }
            }
            .padding(.top, 15)
            .padding(.horizontal, 10)
            
            Spacer(minLength: 0)
            
            // MARK: - 補足
            Text("あとで設定画面から編集できます")
                .font(.system(size: 13))
                .foregroundStyle(.gray.opacity(0.7))
                .padding(.top, 12)
                .padding(.bottom, 10)
            
            // MARK: - 追加ボタン
            Button {
                addPaymentMethod()
            } label: {
                Text("追加")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        paymentMethodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.black.opacity(0.3)
                        : Color.black
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(
                paymentMethodName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            )
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGray6).opacity(0.5))
    }
    
    @ViewBuilder
    private func quickPaymentMethodButton(name: String, type: PaymentType) -> some View {
        let isSelected = selectedQuickName == name
        
        Button {
            paymentMethodName = name
            selectedType = type
            selectedQuickName = name
        } label: {
            Text(name)
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? .white : .black)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? Color.black : Color.white)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.black : Color.gray.opacity(0.4), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private func addPaymentMethod() {
        
        let trimmedName = paymentMethodName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return
        }
        
        let trimmedMemo = memo
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newPaymentMethod = PaymentMethod(
            name: trimmedName,
            type: selectedType,
            memo: trimmedMemo.isEmpty ? nil : trimmedMemo
        )
        
        modelContext.insert(newPaymentMethod)
        
        onFinish()
    }
}

// MARK: - 折り返し可能なFlowレイアウト(ピルボタンを並べる用)

private struct QuickPaymentMethodFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    OnboardingPaymentMethodView(onFinish: {})
}
