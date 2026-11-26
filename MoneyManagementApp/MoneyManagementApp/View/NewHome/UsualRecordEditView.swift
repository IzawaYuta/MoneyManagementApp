
import SwiftUI
import SwiftData

// MARK: - いつもの収支 入力・編集画面
/// `record` が nil なら新規登録、渡されていれば編集。保存時に modelContext へ反映する。
struct UsualRecordEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var titleFocus: Bool
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    @Query(sort: \PaymentMethod.sortIndex)
    private var paymentMethods: [PaymentMethod]
    
    let record: UsualRecord?
    
    @State private var type: TransactionType
    @State private var title: String
    @State private var amountText: String
    @State private var memo: String
    @State private var categoryID: UUID?
    @State private var paymentMethodID: UUID?
    
    @State private var showCategorySelection = false
    @State private var showPaymentMethod = false
    
    init(record: UsualRecord? = nil) {
        self.record = record
        _type = State(initialValue: TransactionType(rawValue: record?.typeRaw ?? "") ?? .expense)
        _title = State(initialValue: record?.title ?? "")
        _amountText = State(initialValue: record.map { String($0.amount) } ?? "")
        _memo = State(initialValue: record?.memo ?? "")
        _categoryID = State(initialValue: record?.categoryID)
        _paymentMethodID = State(initialValue: record?.paymentMethodID)
    }
    
    private var selectedCategory: Category? {
        categories.first { $0.id == categoryID }
    }
    
    private var selectedPaymentMethod: PaymentMethod? {
        paymentMethods.first { $0.id == paymentMethodID }
    }
    
    private var canSave: Bool {
        (Int(amountText) ?? 0) > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("種類", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("内容") {
                    TextField("タイトル", text: $title)
                        .focused($titleFocus)
                        .accessibilityIdentifier("usualEdit.titleField")
                    
                    HStack {
                        Text("金額")
                        Spacer()
                        TextField("0", text: $amountText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: amountText) {
                                let filtered = amountText.filter(\.isNumber)
                                if filtered != amountText { amountText = filtered }
                            }
                            .accessibilityIdentifier("usualEdit.amountField")
                    }
                    
                    selectionRow(title: "カテゴリー", value: selectedCategory?.name ?? "未選択") {
                        showCategorySelection = true
                    }
                    
                    selectionRow(title: "支払方法", value: selectedPaymentMethod?.name ?? "未選択") {
                        showPaymentMethod = true
                    }
                    
                    TextField("メモ", text: $memo)
                        .accessibilityIdentifier("usualEdit.memoField")
                }
            }
            .navigationTitle(record == nil ? "いつもの収支を登録" : "いつもの収支を編集")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { titleFocus = true }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                        .accessibilityIdentifier("usualEdit.saveButton")
                }
            }
            .fullScreenCover(isPresented: $showCategorySelection) {
                CategorySelectionView(selectedCategoryID: $categoryID)
                    .interactiveDismissDisabled(true)
            }
            .fullScreenCover(isPresented: $showPaymentMethod) {
                PaymentMethodView(selectedPaymentMethodID: $paymentMethodID)
            }
            .onAppear {
                // 新規のときだけ、先頭のカテゴリー・支払方法を初期選択にする
                if categoryID == nil { categoryID = categories.first?.id }
                if paymentMethodID == nil { paymentMethodID = paymentMethods.first?.id }
            }
        }
    }
    
    private func selectionRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let resolvedTitle = !trimmedTitle.isEmpty
            ? trimmedTitle
            : (!memo.isEmpty ? memo : (selectedCategory?.name ?? "いつもの"))
        
        let target = record ?? UsualRecord(
            title: resolvedTitle,
            amount: Int(amountText) ?? 0,
            typeRaw: type.rawValue,
            memo: memo
        )
        
        target.title = resolvedTitle
        target.amount = Int(amountText) ?? 0
        target.typeRaw = type.rawValue
        target.memo = memo
        target.categoryID = selectedCategory?.id
        target.categoryName = selectedCategory?.name
        target.categoryImageName = selectedCategory?.imageName
        target.categoryColorHex = selectedCategory?.colorHex
        target.paymentMethodID = selectedPaymentMethod?.id
        target.paymentMethodName = selectedPaymentMethod?.name
        
        if record == nil {
            modelContext.insert(target)
        }
        dismiss()
    }
}
