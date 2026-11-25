
import SwiftUI
import SwiftData

// MARK: - 収支入力画面
struct Home: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    @Query private var paymentMethod: [PaymentMethod]
    @Query(sort: \UsualRecord.createdAt, order: .reverse)
    private var usualRecords: [UsualRecord]
    
    /// 選択中のカテゴリー
    private var selectedCategory: Category? {
        categories.first(where: { $0.id == selectedCategoryID })
    }
    
    private var selectedPaymentMethod: PaymentMethod? {
        paymentMethod.first(where: { $0.id == selectedPaymentMethodID })
    }
    
    @FocusState private var focusedField: Field?
    
    @State private var selectedTransactionType: TransactionType = .expense
    @State private var selectedDate = Date()
    @State private var onTapDate: Bool = false
    @State private var priceTextField = ""
    @State private var showZeroAmountAlert = false
    @State private var memoTextField = ""
    
    @State private var showCategorySelectionView: Bool = false
    @State var selectedCategoryID: UUID?
    @State private var showPaymentMethodView = false
    @State private var selectedPaymentMethodID: UUID?
    @State private var showUsualRecordSheet: Bool = false
    
    /// 下の白いシートが画面の高さに占める割合
    private let sheetHeightRatio: CGFloat = 0.75
    
    // 追加するプロパティ
    @State private var selectedUsualRecordID: UUID?
    
    private var selectedUsualRecord: UsualRecord? {
        usualRecords.first { $0.id == selectedUsualRecordID }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    backgroundGradient
                    topSection
                    inputSheet(height: geometry.size.height * sheetHeightRatio)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    transactionTypePicker
                }
            }
        }
        .alert("金額が0円です", isPresented: $showZeroAmountAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("0円で記録") {
                saveTransaction()
            }
        } message: {
            Text("0円のまま記録しますか？")
        }
        .onAppear { selectDefaultsIfNeeded() }
        .onChange(of: categories.map(\.id)) { selectDefaultsIfNeeded() }
        .onChange(of: paymentMethod.map(\.id)) { selectDefaultsIfNeeded() }
    }
    
    // MARK: 背景
    private var backgroundGradient: some View {
//        LinearGradient(
//            colors: selectedTransactionType == .expense
//            ? [Color(red: 255.0 / 255.0, green: 137.0 / 255.0, blue: 114.0 / 255.0),
//               Color(red: 241.0 / 255.0, green: 237.0 / 255.0, blue: 235.0 / 255.0)]
//            : [Color(red: 139.0 / 255.0, green: 192.0 / 255.0, blue: 255.0 / 255.0),
//               Color(red: 233.0 / 255.0, green: 241.0 / 255.0, blue: 255.0 / 255.0)],
//            startPoint: .topLeading,
//            endPoint: .center
//        )
//        .opacity(0.8)
        ZStack {
            Color.black
//            RadialGradient(
//                colors: [
//                    .red.opacity(0.6),
//                    .red.opacity(0.15),
//                    .clear
//                ],
//                center: .topLeading,
//                startRadius: 0,
//                endRadius: 500
//            )
            LinearGradient(
                colors: selectedTransactionType == .expense
                ? [Color(red: 255.0 / 255.0, green: 137.0 / 255.0, blue: 114.0 / 255.0),
                   Color(red: 241.0 / 255.0, green: 237.0 / 255.0, blue: 235.0 / 255.0)]
                : [Color(red: 139.0 / 255.0, green: 192.0 / 255.0, blue: 255.0 / 255.0),
                   Color(red: 233.0 / 255.0, green: 241.0 / 255.0, blue: 255.0 / 255.0)],
                startPoint: .topLeading,
                endPoint: .center
            )
            .opacity(0.8)
        }
        .ignoresSafeArea()
    }
    
    // MARK: ボタンの色
    /// 確定・クリアボタンの下に敷く色(背景グラデーションの2色目に合わせて、収入/支出で切り替える)
    private var accentColor: Color {
        selectedTransactionType == .expense ? Color(red: 241.0 / 255.0, green: 237.0 / 255.0, blue: 235.0 / 255.0) : Color(red: 233.0 / 255.0, green: 241.0 / 255.0, blue: 255.0 / 255.0)
    }
    
    // MARK: 上部(日付・金額・クイック金額ボタン)
    private var topSection: some View {
        VStack(spacing: 20) {
            AmountDisplay(text: $priceTextField, focus: $focusedField)
            
            QuickAmountButtons(priceText: $priceTextField)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, -13)
    }
    
    // MARK: 下部の白いシート(カテゴリー・支払方法・メモ・ボタン)
    private func inputSheet(height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: 45,
                topTrailingRadius: 45
            )
            .fill(.white)
            .ignoresSafeArea(edges: .bottom)
            
            VStack(spacing: 12) {
                SelectionDate(selectedDate: $selectedDate, onTapDatePicker: $onTapDate)
                HStack(spacing: 12) {
                    SelectionCard(title: "カテゴリー", value: selectedCategory?.name ?? "あいうえお", corners: .categoryCard) {
                        showCategorySelectionView.toggle()
                    }
                    .accessibilityIdentifier("home.categoryCard")
                    .fullScreenCover(isPresented: $showCategorySelectionView) {
                        CategorySelectionView(
                            selectedCategoryID: $selectedCategoryID
                        )
                        .interactiveDismissDisabled(true)
                    }
                    SelectionCard(title: "支払方法", value: selectedPaymentMethod?.name ?? "あいうえおかきくけこさしすせそたちつてと", corners: .paymentCard) {
                        showPaymentMethodView.toggle()
                    }
                    .accessibilityIdentifier("home.paymentCard")
                    .fullScreenCover(isPresented: $showPaymentMethodView) {
                        PaymentMethodView(selectedPaymentMethodID: $selectedPaymentMethodID)
                    }
                }
                
                MemoCard(text: $memoTextField, focus: $focusedField)
                
                UsualRecordCard(
                    selectedTitle: selectedUsualRecord?.title,
                    onOpenList: { showUsualRecordSheet = true },
                )
                .fullScreenCover(isPresented: $showUsualRecordSheet) {
                    UsualRecordCardSheet(
                        records: usualRecords,
                        onApply: { applyUsualRecord($0) },
                        onDelete: { modelContext.delete($0) }
                    )
                }
                
                Spacer()
                
                InputActionButtons(
                    accentColor: accentColor,
                    onConfirm: {
                        requestSave()
                    },
                    onClear: {
                        clearButton()
                    }
                )
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .frame(height: height)
    }
    
    // MARK: 収入/支出の切り替え
    private var transactionTypePicker: some View {
        Picker("", selection: $selectedTransactionType) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Text(type.rawValue)
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 160)
        .padding(.vertical, 5)
    }
    
    // MARK: 収支確定
    /// 金額が0円(空を含む)ならアラートを出して保留し、それ以外は保存する
    /// - Returns: 保存したら true、アラートを出して保留したら false
    private func requestSave() -> Bool {
        focusedField = nil
        if TransactionService.isZeroAmount(priceTextField) {
            showZeroAmountAlert = true
            return false
        }
        return saveTransaction()
    }
    
    @discardableResult
    private func saveTransaction() -> Bool {
        focusedField = nil
        do {
            try TransactionService.save(
                date: selectedDate,
                amountText: priceTextField,
                type: selectedTransactionType,
                memo: memoTextField,
                category: selectedCategory,
                paymentMethod: selectedPaymentMethod,
                in: modelContext
            )
            priceTextField = ""
            memoTextField = ""
            return true
        } catch {
            print("保存に失敗しました: \(error)")
            return false
        }
    }
    
    private func clearButton() {
        selectedDate = Date()
        priceTextField = ""
        selectedCategoryID = categories.sorted { $0.sortIndex < $1.sortIndex }.first?.id
        memoTextField = ""
        selectedPaymentMethodID = paymentMethod.sorted { $0.sortIndex < $1.sortIndex }.first?.id
    }
    
    /// 未選択、または選択中のものが削除されたときは、先頭のカテゴリー・支払方法を選ぶ
    private func selectDefaultsIfNeeded() {
        if selectedCategory == nil {
            selectedCategoryID = categories.first?.id
        }
        if selectedPaymentMethod == nil {
            selectedPaymentMethodID = paymentMethod.sorted { $0.sortIndex < $1.sortIndex }.first?.id
        }
    }
    
    // MARK: いつもの収支
    private func registerUsualRecord() {
        let record = UsualRecord(
            title: memoTextField.isEmpty ? (selectedCategory?.name ?? "いつもの") : memoTextField,
            amount: Int(priceTextField) ?? 0,
            typeRaw: selectedTransactionType.rawValue,
            memo: memoTextField
        )
        record.categoryID = selectedCategory?.id
        record.categoryName = selectedCategory?.name
        record.categoryImageName = selectedCategory?.imageName
        record.categoryColorHex = selectedCategory?.colorHex
        record.paymentMethodID = selectedPaymentMethod?.id
        record.paymentMethodName = selectedPaymentMethod?.name
        modelContext.insert(record)
    }
    
    private func applyUsualRecord(_ record: UsualRecord) {
        priceTextField = String(record.amount)
        memoTextField = record.memo
        if let type = TransactionType(rawValue: record.typeRaw) {
            selectedTransactionType = type
        }
        // 削除済みのカテゴリー・支払方法は反映しない(現在の選択のまま)
        if let id = record.categoryID, categories.contains(where: { $0.id == id }) {
            selectedCategoryID = id
        }
        if let id = record.paymentMethodID, paymentMethod.contains(where: { $0.id == id }) {
            selectedPaymentMethodID = id
        }
    }
}

#Preview {
    Home()
}
