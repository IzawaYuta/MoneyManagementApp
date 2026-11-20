
import SwiftUI
import SwiftData

//MARK: - 収支記録上書き画面
struct OverwriteRecordView: View {
    
    @State private var priceTextField: String = "¥1,000"
    @State private var memoTextField: String = "メモですよ"
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    
    @Query private var paymentMethod: [PaymentMethod]
    
    @State var selectedCategoryID: UUID?
    @State private var selectedPaymentMethodID: UUID?
    
    @State private var showDeleteAlert: Bool = false
    @State private var showCancelAlert: Bool = false
    
    /// 選択中のカテゴリー
    private var selectedCategory: Category? {
        categories.first(where: { $0.id == selectedCategoryID })
    }
    
    private var selectedPaymentMethod: PaymentMethod? {
        paymentMethod.first(where: { $0.id == selectedPaymentMethodID })
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        HStack {
                            Text("日付")
                            Spacer()
                            Text("2026/11/11")
                        }
                    }
                    .padding(.horizontal, 7)
                    
                    Section {
                        HStack {
                            Text("金額")
                            Spacer()
                            TextField("金額", text: $priceTextField)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding(.horizontal, 7)
                    
                    Section {
                        HStack {
                            Text("カテゴリー")
                            Spacer()
                            Text(selectedCategory?.name ?? "-")
                        }
                        HStack {
                            Text("支払方法")
                            Spacer()
                            Text(selectedPaymentMethod?.name ?? "-")
                        }
                    }
                    .padding(.horizontal, 7)
                    
                    Section {
                        TextField("メモ", text: $memoTextField)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 7)
                }
                .padding(.horizontal, 3)
                
                VStack(alignment: .center, spacing: 18) {
                    Button(action: {
                        
                    }) {
                        Text("上書きする")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        showDeleteAlert.toggle()
                    }) {
                        Text("削除")
                            .foregroundColor(.red)
                    }
                    .alert("削除確認", isPresented: $showDeleteAlert) {
                        Button("キャンセル", role: .cancel) {}
                        Button("削除", role: .destructive) {}
                    } message: {
                        Text("記録を削除しますか？")
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("上書き")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showCancelAlert.toggle()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert("変更を破棄", isPresented: $showCancelAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("破棄", role: .destructive) {}
            } message: {
                Text("変更を破棄しますか？")
            }
        }
    }
}

#Preview {
    OverwriteRecordView()
}
