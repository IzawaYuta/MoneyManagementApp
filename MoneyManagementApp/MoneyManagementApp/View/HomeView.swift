
import SwiftUI
import SwiftData

struct HomeView: View {
    
    @FocusState private var focusedField: Field?
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    
    @State private var selectedTransactionType: TransactionType = .income
    @State /*private*/ var selectedCategory: Category?
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var memo = ""
    @State private var selectedDate = Date()
    @State private var isShowingTemplates = false
    @State private var isShowingDatePicker = false
    @State private var showCategorySelectionView: Bool = false
    @State private var showClearAlert = false
    @State private var showPaymentMethodView = false
    
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
                        DatePicker(
                            "日付を選択",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        .presentationDetents([.medium])
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
                
                
                VStack(spacing: 0) {
                    Text("金額")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                    
                    ZStack {
                        HStack(spacing: 4) {
                            Text("￥")
                                .font(.system(size: 42, weight: .semibold))
                            Text(Decimal(string: priceTextField) ?? 0, format: .number)
                                .font(.system(size: 42, weight: .semibold))
                        }
                        //                                .background(Color.red.opacity(0.5)) //確認用
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
                                
                                Text(selectedCategory?.name ?? categories.first?.name ?? "-")
                                    .foregroundStyle(.black.opacity(0.7))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showCategorySelectionView) {
                            CategorySelectionView(
                                selectedCategory: $selectedCategory
                            )
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
                                Text("支払方法")
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text(selectedPaymentMethod?.name ?? "未選択")
                                    .foregroundStyle(.black.opacity(0.7))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showPaymentMethodView) {
                            PaymentMethodView(selectedPaymentMethod: $selectedPaymentMethod)
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
                        }
                    } message: {
                        Text("入力した内容がすべてクリアされます。")
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .onAppear {
                addInitialCategories()
                print("===== Category一覧 =====")
                for category in categories {
                    print(
                        "id: \(category.id), name: \(category.name), imageName: \(category.imageName), sortIndex: \(category.sortIndex)"
                    )
                }
                print("========================")
            }
            .onChange(of: categories) {
                if selectedCategory == nil {
                    selectedCategory = categories.first(where: { $0.sortIndex == 0 })
                }
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
        
        guard let category = selectedCategory ?? categories.first else {
            return
        }
        
        let transaction = Transaction(
            date: selectedDate,
            amount: Int(priceTextField) ?? 0,
            type: selectedTransactionType,
            category: category,
            memo: memo,
            paymentMethod: selectedPaymentMethod
        )
        
        modelContext.insert(transaction)
        print("🔥新規保存情報🔥")
        print("✅type: \(selectedTransactionType)")
        print("✅date: \(selectedDate)")
        print("✅amount: \(priceTextField)")
        print("✅category: \(String(describing: selectedCategory))")
        print("✅memo: \(memo)")
        print("✅paymentMethod: \(String(describing: selectedPaymentMethod))")
    }
    
    private func addInitialCategories() {
        guard categories.isEmpty else {
            if selectedCategory == nil {
                selectedCategory = categories.first(where: { $0.sortIndex == 0 })
            }
            return
        }
        
        let initialCategories = [
            Category(name: "家賃", imageName: "house", sortIndex: 0),
            Category(name: "食費", imageName: "fork.knife", sortIndex: 1),
            Category(name: "日用品", imageName: "basket", sortIndex: 2),
            Category(name: "交通費", imageName: "car", sortIndex: 3),
            Category(name: "医療費", imageName: "cross.case", sortIndex: 4),
            Category(name: "その他", imageName: "ellipsis.circle", sortIndex: 5)
        ]
        
        for category in initialCategories {
            modelContext.insert(category)
        }
        
        didAddInitialCategories = true
    }
    
//    private func addInitialPaymentMethods() {
//        guard !didAddInitialPaymentMethods else { return }
//        
//        let paymentTypesName = [
//            PaymentType(name: "現金", sortIndex: 0),
//            PaymentType(name: "クレジットカード", sortIndex: 1),
//            PaymentType(name: "デビッドカード", sortIndex: 2),
//            PaymentType(name: "電子マネー", sortIndex: 3),
//            PaymentType(name: "口座振替", sortIndex: 4),
//            PaymentType(name: "その他", sortIndex: 5)
//        ]
//        
//        for paymentType in paymentTypesName {
//            modelContext.insert(paymentType)
//        }
//        
//        didAddInitialPaymentMethods = true
//    }
}

#Preview {
    HomeView(
        selectedCategory: Category(
            name: "家賃",
            imageName: "house",
            sortIndex: 0
        )
    )
}
