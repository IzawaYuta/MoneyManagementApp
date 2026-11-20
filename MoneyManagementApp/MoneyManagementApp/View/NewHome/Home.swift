
import SwiftUI
import SwiftData

// MARK: - 収支入力画面
struct Home: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    @Query private var paymentMethod: [PaymentMethod]
    @Query private var transactions: [Transaction]
    
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
    @State private var isShowingDatePicker = false
    @State private var priceTextField = ""
    @State private var memoTextField = ""
    
    @State private var isShowingTopToast = false
    @State private var isShowingBubbleToast = false
    
    @State private var showCategorySelectionView: Bool = false
    @State var selectedCategoryID: UUID?
    @State private var showPaymentMethodView = false
    @State private var selectedPaymentMethodID: UUID?
    
    /// 下の白いシートが画面の高さに占める割合
    private let sheetHeightRatio: CGFloat = 0.705
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    backgroundGradient
                    topSection
                    inputSheet(height: geometry.size.height * sheetHeightRatio)
                        .padding(.bottom, -geometry.safeAreaInsets.bottom)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    transactionTypePicker
                }
            }
        }
        .topPillToast(isPresented: $isShowingTopToast, message: "保存しました")
        .onAppear { selectDefaultsIfNeeded() }
        .onChange(of: categories.map(\.id)) { selectDefaultsIfNeeded() }
        .onChange(of: paymentMethod.map(\.id)) { selectDefaultsIfNeeded() }
    }
    
    // MARK: 背景
    private var backgroundGradient: some View {
        LinearGradient(
            colors: selectedTransactionType == .expense
            ? [Color(red: 255.0 / 255.0, green: 137.0 / 255.0, blue: 114.0 / 255.0),
               Color(red: 241.0 / 255.0, green: 237.0 / 255.0, blue: 235.0 / 255.0)]
            : [Color(red: 139.0 / 255.0, green: 192.0 / 255.0, blue: 255.0 / 255.0),
               Color(red: 233.0 / 255.0, green: 241.0 / 255.0, blue: 255.0 / 255.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(0.8)
        .ignoresSafeArea()
    }
    
    // MARK: ボタンの色
    /// 確定・クリアボタンの下に敷く色(背景グラデーションの2色目に合わせて、収入/支出で切り替える)
    private var accentColor: Color {
        selectedTransactionType == .expense ? Color(red: 241.0 / 255.0, green: 237.0 / 255.0, blue: 235.0 / 255.0) : Color(red: 233.0 / 255.0, green: 241.0 / 255.0, blue: 255.0 / 255.0)
    }
    
    // MARK: 上部(日付・金額・クイック金額ボタン)
    private var topSection: some View {
        VStack(spacing: 30) {
            DateNavigator(date: $selectedDate) {
                isShowingDatePicker = true
            }
            .sheet(isPresented: $isShowingDatePicker) {
                DatePickerSheet(date: $selectedDate, isPresented: $isShowingDatePicker)
            }
            
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
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    SelectionCard(title: "カテゴリー", value: selectedCategory?.name ?? "未選択", corners: .categoryCard) {
                        showCategorySelectionView.toggle()
                    }
                    .sheet(isPresented: $showCategorySelectionView) {
                        CategorySelectionView(
                            selectedCategoryID: $selectedCategoryID
                        )
                        .interactiveDismissDisabled(true)
                    }
                    SelectionCard(title: "支払方法", value: selectedPaymentMethod?.name ?? "未選択", corners: .paymentCard) {
                        showPaymentMethodView.toggle()
                    }
                    .sheet(isPresented: $showPaymentMethodView) {
                        PaymentMethodView(selectedPaymentMethodID: $selectedPaymentMethodID)
                    }
                }
                
                MemoCard(text: $memoTextField)
                
                Spacer()
                
                InputActionButtons(
                    accentColor: accentColor,
                    onConfirm: {
                        saveTransaction()
                    },
                    onClear: {
                        clearButton()
                    }
                )
                .padding(.bottom, 50)
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
    private func saveTransaction() {
        
        let nextSortIndex = (transactions.map(\.sortIndex).max() ?? -1) + 1
        
        let transaction = Transaction(
            date: selectedDate,
            amount: Int(priceTextField) ?? 0,
            type: selectedTransactionType,
            //            category: category,
            memo: memoTextField,
            sortIndex: nextSortIndex,
            categoryID: selectedCategory?.id,
            categoryName: selectedCategory?.name,
            categoryImageName: selectedCategory?.imageName,
            categoryColorHex: selectedCategory?.colorHex,
            paymentMethodID: selectedPaymentMethod?.id,
            paymentMethodName: selectedPaymentMethod?.name,
            paymentMethodType: selectedPaymentMethod?.type,
            paymentMethodMemo: selectedPaymentMethod?.memo
        )
        
        modelContext.insert(transaction)
        
        priceTextField = ""
        memoTextField = ""
        isShowingTopToast = true
        print("🔥新規保存情報🔥")
        print("✅type: \(transaction.type.rawValue)")
        
        let japanDate = transaction.date.formatted(
            .dateTime
                .year()
                .month()
                .day()
                .hour()
                .minute()
                .second()
                .locale(Locale(identifier: "ja_JP"))
        )
        print("✅date: \(japanDate)")
        
        print("✅amount: \(transaction.amount)")
        print("✅category: \(transaction.categoryName)")
        print("category.imageName: \(selectedCategory?.imageName)")
        print("transaction.categoryImageName: \(transaction.categoryImageName)")
        
        if let memo = transaction.memo {
            print("✅memo: \"\(memo)\"")
        } else {
            print("✅memo: nil")
        }
        
        print("✅sortIndex: \(transaction.sortIndex)")
        print("✅paymentMethodID: \(transaction.paymentMethodID?.uuidString ?? "nil")")
        print("✅paymentMethodName: \(transaction.paymentMethodName ?? "nil")")
        print("✅paymentMethodType: \(transaction.paymentMethodType?.title ?? "nil")")
        print("✅paymentMethodMemo: \(transaction.paymentMethodMemo ?? "nil")")
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
}

#Preview {
    Home()
}
