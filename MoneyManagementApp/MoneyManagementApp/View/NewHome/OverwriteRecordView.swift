
import SwiftUI
import SwiftData

//MARK: - 収支記録上書き画面
struct OverwriteRecordView: View {
    
    let transaction: Transaction
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    
    @Query private var paymentMethods: [PaymentMethod]
    
    // 編集中の値(「上書きする」を押すまで元データには反映しない)
    @State private var type: TransactionType
    @State private var date: Date
    @State private var priceTextField: String
    @State private var selectedCategoryID: UUID?
    @State private var selectedPaymentMethodID: UUID?
    @State private var memoTextField: String
    
    @State private var showDeleteAlert: Bool = false
    @State private var showCancelAlert: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showCategorySelectionView: Bool = false
    @State private var showPaymentMethodSelectionView: Bool = false
    @State private var showZeroAmountAlert: Bool = false
    
    init(transaction: Transaction) {
        self.transaction = transaction
        _type = State(initialValue: transaction.type)
        _date = State(initialValue: transaction.date)
        _priceTextField = State(initialValue: Self.formatPrice(String(transaction.amount)))
        _selectedCategoryID = State(initialValue: transaction.categoryID)
        _selectedPaymentMethodID = State(initialValue: transaction.paymentMethodID)
        _memoTextField = State(initialValue: transaction.memo ?? "")
    }
    
    /// 入力文字列を「¥1,280」の形に整える(数字以外は無視、最大9桁)
    private static func formatPrice(_ text: String) -> String {
        let digits = text.filter(\.isNumber).prefix(9)
        guard let value = Int(digits) else { return "" }
        return "¥" + value.formatted(.number.locale(Locale(identifier: "ja_JP")))
    }
    
    private var selectedCategory: Category? {
        categories.first(where: { $0.id == selectedCategoryID })
    }
    
    private var selectedPaymentMethod: PaymentMethod? {
        paymentMethods.first(where: { $0.id == selectedPaymentMethodID })
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        Picker("種類", selection: $type) {
                            Text("収入").tag(TransactionType.income)
                            Text("支出").tag(TransactionType.expense)
                        }
                        .tint(.black)
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("overwrite.typePicker")
                    }
                    .padding(.horizontal, 7)
                    
                    Section {
                        HStack {
                            Text("日付")
                            Spacer()
                            Button(action: {
                                showDatePicker.toggle()
                            }) {
                                Text(date.formattedDateJP)
                                    .tint(.black)
                            }
                            .accessibilityIdentifier("overwrite.dateButton")
                            .sheet(isPresented: $showDatePicker) {
                                DatePickerSheet(date: $date, isPresented: $showDatePicker)
                                    .presentationDetents([.medium])
                                    .presentationBackground(.white)
                                    .onChange(of: date) { _, _ in
                                        showDatePicker = false
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 7)
                    
                    Section {
                        HStack {
                            Text("金額")
                            Spacer()
                            TextField("¥0", text: $priceTextField)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                                .accessibilityIdentifier("overwrite.amountField")   
                                .onChange(of: priceTextField) { _, newValue in
                                    let formatted = Self.formatPrice(newValue)
                                    if formatted != newValue {
                                        priceTextField = formatted
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 7)
                    
                    Section {
                        HStack {
                            Text("カテゴリー")
                            Spacer()
                            Button(action: {
                                showCategorySelectionView.toggle()
                            }) {
                                Text(selectedCategory?.name ?? transaction.categoryName ?? "未選択")
                                    .tint((transaction.categoryName == nil) ? .gray : .black)
                            }
                            .accessibilityIdentifier("overwrite.categoryButton")
                            .sheet(isPresented: $showCategorySelectionView) {
                                CategorySelectionView(
                                    selectedCategoryID: $selectedCategoryID
                                )
                            }
                        }
                        HStack {
                            Text("支払方法")
                            Spacer()
                            Button(action: {
                                showPaymentMethodSelectionView.toggle()
                            }) {
                                Text(selectedPaymentMethod?.name ?? transaction.paymentMethodName ?? "未選択")
                                    .tint((transaction.paymentMethodName == nil) ? .gray : .black)
                            }
                            .accessibilityIdentifier("overwrite.paymentButton") 
                            .sheet(isPresented: $showPaymentMethodSelectionView) {
                                PaymentMethodView(selectedPaymentMethodID: $selectedPaymentMethodID)
                            }
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
                        requestSave()
                    }) {
                        Text("上書きする")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .padding(.horizontal, 20)
                    .alert("金額が0円です", isPresented: $showZeroAmountAlert) {
                        Button("キャンセル", role: .cancel) {}
                        Button("0円で上書き") {
                            save()
                        }
                    } message: {
                        Text("0円のまま上書きしますか？")
                    }
                    
                    Button(action: {
                        showDeleteAlert.toggle()
                    }) {
                        Text("削除")
                            .foregroundColor(.red)
                    }
                    .alert("削除確認", isPresented: $showDeleteAlert) {
                        Button("キャンセル", role: .cancel) {}
                        Button("削除", role: .destructive) {
                            TransactionService.delete(transaction, in: modelContext)
                            dismiss()
                        }
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
                    .accessibilityIdentifier("overwrite.closeButton")  
                }
            }
            .alert("変更を破棄", isPresented: $showCancelAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("破棄", role: .destructive) { dismiss() }
            } message: {
                Text("変更を破棄しますか？")
            }
        }
    }
    
    // MARK: - 上書き保存
    
    /// 金額が0円(空を含む)ならアラートを出して保留し、それ以外は上書きする
    private func requestSave() {
        if TransactionService.isZeroAmount(priceTextField) {
            showZeroAmountAlert = true
        } else {
            save()
        }
    }
    
    private func save() {
        TransactionService.update(
            transaction,
            type: type,
            date: date,
            amountText: priceTextField,
            memo: memoTextField,
            category: selectedCategory,
            paymentMethod: selectedPaymentMethod
        )
        dismiss()
    }
}

extension Date {
    var formattedDateJP: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: self)
    }
}

#Preview {
    OverwriteRecordView(transaction: Transaction())
}
