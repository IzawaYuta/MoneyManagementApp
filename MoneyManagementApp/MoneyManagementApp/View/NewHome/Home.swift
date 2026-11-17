import SwiftUI

// MARK: - 収支入力画面
struct Home: View {
    
    @FocusState private var focusedField: Field?
    
    @State private var selectedTransactionType: TransactionType = .expense
    @State private var selectedDate = Date()
    @State private var isShowingDatePicker = false
    @State private var priceTextField = ""
    @State private var categoryName = "食費"
    @State private var paymentMethodName = "現金"
    @State private var memoTextField = ""
    
    @State private var isShowingTopToast = false
    @State private var isShowingBubbleToast = false
    
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
            .topPillToast(isPresented: $isShowingTopToast, message: "保存しました")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    transactionTypePicker
                }
            }
        }
    }
    
    // MARK: 背景
    private var backgroundGradient: some View {
        LinearGradient(
            colors: selectedTransactionType == .expense
            ? [.red, .orange]
            : [.blue, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(0.8)
        .ignoresSafeArea()
    }
    
    // MARK: ボタンの色
    /// 確定・クリアボタンの下に敷く色(背景グラデーションの2色目に合わせて、収入/支出で切り替える)
    private var accentColor: Color {
        selectedTransactionType == .expense ? .orange : .cyan
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
                    SelectionCard(title: "カテゴリー", value: categoryName, corners: .categoryCard) {
                        // TODO: カテゴリー選択の処理
                    }
                    SelectionCard(title: "支払方法", value: paymentMethodName, corners: .paymentCard) {
                        // TODO: 支払方法選択の処理
                    }
                }
                
                MemoCard(text: $memoTextField)
                
                Spacer()
                
                InputActionButtons(
                    accentColor: accentColor,
                    isShowingBubble: $isShowingBubbleToast,
                    bubbleText: "¥\((Int(priceTextField) ?? 0).formatted()) 記録!",
                    onConfirm: {
                        // TODO: saveTransaction()
                        isShowingTopToast = true
                        isShowingBubbleToast = true
                    },
                    onClear: {
                        // TODO: 「内容をクリアしますか？」の確認アラートを出し、
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
}

#Preview {
    Home()
}
