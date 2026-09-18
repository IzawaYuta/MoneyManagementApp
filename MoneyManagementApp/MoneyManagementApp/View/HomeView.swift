
import SwiftUI
import SwiftData

struct HomeView: View {
    
    @FocusState private var focusedField: Field?
    @Environment(\.modelContext) private var modelContext
    
    @Query private var categories: [Category]
    @Query private var paymentMethod: [PaymentMethod]
    @Query private var transactions: [Transaction]
    
    @State private var selectedTransactionType: TransactionType = .expense
    @State var selectedCategoryID: UUID?
    @State private var selectedPaymentMethodID: UUID?
    @State private var memo = ""
    @State private var selectedDate = Date()
    @State private var isShowingTemplates = false
    @State private var isShowingDatePicker = false
    @State private var showCategorySelectionView: Bool = false
    @State private var showClearAlert = false
    @State private var showPaymentMethodView = false
    @State private var showNoCategoryAlert = false
    
    @State private var priceTextField: String = ""
    
    @AppStorage("didAddInitialCategories")
    private var didAddInitialCategories = false
    
    //    @AppStorage("didAddInitialPaymentMethods")
    //    private var didAddInitialPaymentMethods = false
    
    var body: some View {
        NavigationStack {
            VStack {
                
                // 日付ナビゲーター
                HStack(spacing: 30) {
                    Button {
                        selectedDate = Calendar.current.date(
                            byAdding: .day,
                            value: -1,
                            to: selectedDate
                        ) ?? selectedDate
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.black)
                            .frame(width: 35, height: 35)
                            .background(Color(uiColor: .systemGray6))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        isShowingDatePicker = true
                    } label: {
                        Text(
                            selectedDate.formatted(
                                .dateTime
                                    .year()
                                    .month()
                                    .day()
                                    .locale(Locale(identifier: "ja_JP"))
                            )
                        )
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(minWidth: 150)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $isShowingDatePicker) {
                        VStack(spacing: 0) {
                            
                            // ヘッダー: タイトル + 今日ボタン
                            HStack {
                                Text("日付を選択")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.black)
                                
                                Spacer()
                                
                                Button {
                                    selectedDate = Date()
                                    isShowingDatePicker = false
                                } label: {
                                    Text("今日")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Color(uiColor: .systemGray6))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 8)
                            
                            DatePicker(
                                "日付を選択",
                                selection: $selectedDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                            .onChange(of: selectedDate) {
                                isShowingDatePicker = false
                            }
                            
                            Spacer(minLength: 0)
                        }
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                    }
                    
                    Button {
                        selectedDate = Calendar.current.date(
                            byAdding: .day,
                            value: 1,
                            to: selectedDate
                        ) ?? selectedDate
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.black)
                            .frame(width: 30, height: 30)
                            .background(Color(uiColor: .systemGray6))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 12)
                
                
                VStack(spacing: -5) {
                    Text("金額")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                    
                    ZStack {
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemName: selectedTransactionType == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(selectedTransactionType == .income ? Color.green.opacity(0.85) : Color.red.opacity(0.85))
                            Text(Decimal(string: priceTextField) ?? 0, format: .number)
                                .font(.system(size: 42, weight: .semibold))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = .price
                        }
                        
                        TextField("", text: $priceTextField)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .price)
                            .foregroundColor(.clear)
                            .tint(.clear)
                            .opacity(0.01)
                            .allowsHitTesting(false)
                    }
                    .frame(height: 90)
                    .padding(.top, -10)
                    .padding(.horizontal, 10)
                }
                .padding(.top, 10)
                
                List {
                    
                    Section {
                        // カテゴリー
                        Button {
                            showCategorySelectionView.toggle()
                        } label: {
                            HStack {
                                Text("カテゴリー")
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text(selectedCategory?.name ?? "-")
                                    .foregroundStyle(.black.opacity(0.7))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showCategorySelectionView) {
                            CategorySelectionView(
                                selectedCategoryID: $selectedCategoryID
                            )
                            .interactiveDismissDisabled(true)
                        }
                        
                        // メモ
                        HStack {
                            Text("メモ")
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            TextField("入力...", text: $memo)
                                .foregroundStyle(.black)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .memo)
                        }
                        
                        // 支払方法
                        Button {
                            showPaymentMethodView.toggle()
                        } label: {
                            HStack {
                                Text("支払い方法")
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text(selectedPaymentMethod?.name ?? "-")
                                    .foregroundStyle(.black.opacity(0.7))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showPaymentMethodView) {
                            PaymentMethodView(selectedPaymentMethodID: $selectedPaymentMethodID)
                        }
                    }
                    
                    // いつもの
                    //                    Section {
                    //                        Button {
                    //                            isShowingTemplates = true
                    //                        } label: {
                    //                            HStack {
                    //                                Text("いつもの")
                    //                                    .foregroundStyle(.black)
                    //
                    //                                Spacer()
                    //
                    //                                Image(systemName: "chevron.right")
                    //                                    .font(.system(size: 13, weight: .medium))
                    //                                    .foregroundStyle(.secondary)
                    //                            }
                    //                        }
                    //                        .buttonStyle(.plain)
                    //                        .sheet(isPresented: $isShowingTemplates) {
                    //                            TemplateListView()
                    //                        }
                    //                    }
                    
                }
                .offset(y: -30)
                .scrollDisabled(true)
                
                HStack(spacing: 12) {
                    Button {
                        saveTransaction()
                    } label: {
                        Text("確定")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 10)
                            )
                    }
                    .frame(width: 220)
                    .alert("カテゴリーが選択されていません", isPresented: $showNoCategoryAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("カテゴリーを選択してから保存してください。")
                    }
                    
                    Button {
                        showClearAlert = true
                    } label: {
                        Text("クリア")
                            .font(.system(size: 16))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(uiColor: .systemGray6))
                            .clipShape(
                                RoundedRectangle(cornerRadius: 10)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .alert("内容をクリアしますか？", isPresented: $showClearAlert) {
                        Button("キャンセル", role: .cancel) {
                        }
                        
                        Button("クリア", role: .destructive) {
                            selectedDate = Date()
                            priceTextField = ""
                            selectedCategoryID = categories.sorted { $0.sortIndex < $1.sortIndex }.first?.id
                            memo = ""
                            selectedPaymentMethodID = paymentMethod.sorted { $0.sortIndex < $1.sortIndex }.first?.id
                        }
                    } message: {
                        Text("入力した内容がすべてクリアされます。")
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .onAppear {
                syncSelectedCategoryIfNeeded()
                syncSelectedPaymentMethodIfNeeded()
            }
            .onChange(of: categories) {
                syncSelectedCategoryIfNeeded()
            }
            .onChange(of: paymentMethod) {
                syncSelectedPaymentMethodIfNeeded()
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGray6).opacity(0.5))
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
            .navigationTitle("記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .principal) {
                    //                    Button {
                    //                        // 将来的な機能
                    //                    } label: {
                    //                        Image(systemName: "ellipsis")
                    //                            .foregroundStyle(.black)
                    //                    }
                    // 収入 / 支出
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
                
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: {
                        focusedField = nil
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        //                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                        //                            .background(Color.black)
                        //                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
//                    .padding(.bottom, 20)
//                    .padding(.horizontal, 10)
                    
                    Spacer()
                }
            }
            //            .toolbarBackground(
            //                Color(.gray.opacity(0.1)),
            //                for: .navigationBar
            //            )
            //            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func saveTransaction() {
        
        guard let category = selectedCategory else {
            showNoCategoryAlert = true
            return
        }
        
        let nextSortIndex = (transactions.map(\.sortIndex).max() ?? -1) + 1
        
        let transaction = Transaction(
            date: selectedDate,
            amount: Int(priceTextField) ?? 0,
            type: selectedTransactionType,
            category: category,
            memo: memo,
            sortIndex: nextSortIndex,
            paymentMethodID: selectedPaymentMethod?.id,
            paymentMethodName: selectedPaymentMethod?.name,
            paymentMethodType: selectedPaymentMethod?.type,
            paymentMethodMemo: selectedPaymentMethod?.memo
        )
        
        modelContext.insert(transaction)
        
        priceTextField = ""
        memo = ""
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
        print("✅category: \(transaction.category.name)")
        
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
    
    //    private func addInitialCategories() {
    //        guard categories.isEmpty else {
    //            if selectedCategory == nil {
    //                selectedCategory = categories.first(where: { $0.sortIndex == 0 })
    //            }
    //            return
    //        }
    //
    //        let initialCategories = [
    //            Category(name: "家賃", imageName: "house", sortIndex: 0),
    //            Category(name: "食費", imageName: "fork.knife", sortIndex: 1),
    //            Category(name: "日用品", imageName: "basket", sortIndex: 2),
    //            Category(name: "交通費", imageName: "car", sortIndex: 3),
    //            Category(name: "医療費", imageName: "cross.case", sortIndex: 4),
    //            Category(name: "その他", imageName: "ellipsis.circle", sortIndex: 5)
    //        ]
    //
    //        for category in initialCategories {
    //            modelContext.insert(category)
    //            print("追加: \(category.name), sortIndex: \(category.sortIndex)")
    //        }
    //
    //        didAddInitialCategories = true
    //    }
    
    /// 読み取り専用
    private var selectedCategory: Category? {
        categories.first(where: { $0.id == selectedCategoryID })
    }
    
    private var selectedPaymentMethod: PaymentMethod? {
        paymentMethod.first(where: { $0.id == selectedPaymentMethodID })
    }
    
    private func syncSelectedCategoryIfNeeded() {
        let isValid = categories.contains { $0.id == selectedCategoryID }
        if !isValid {
            selectedCategoryID = categories.sorted { $0.sortIndex < $1.sortIndex }.first?.id
        }
    }
    
    private func syncSelectedPaymentMethodIfNeeded() {
        let isValid = paymentMethod.contains { $0.id == selectedPaymentMethodID }
        if !isValid {
            selectedPaymentMethodID = paymentMethod.sorted { $0.sortIndex < $1.sortIndex }.first?.id
        }
    }
}

#Preview {
    let category = Category(
        name: "家賃",
        imageName: "house",
        sortIndex: 0
    )
    
    HomeView(selectedCategoryID: category.id)
}
