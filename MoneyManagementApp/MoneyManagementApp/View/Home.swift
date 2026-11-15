
import SwiftUI

/// カードの背景
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.95, green: 0.96, blue: 0.97))
                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
            )
    }
}

extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}

struct PriceCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.2))
//                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
            )
    }
}

extension View {
    func priceCardBackground() -> some View {
        modifier(PriceCardBackground())
    }
}

/// メモ
struct MemoCard: View {
    
    @Binding var text: String
    
    var body: some View {
        
        TextField(
            text: $text,
            prompt: Text("メモを入力")
                .font(.callout)
        ) {
            EmptyView()
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(10)
        .frame(height: 64)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 30,
                bottomTrailingRadius: 30,
                topTrailingRadius: 18
            )
            .fill(Color(red: 0.95, green: 0.96, blue: 0.97))
//            .fill(Color(red: 0.91, green: 0.92, blue: 0.93))
            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        }
    }
}

struct Home: View {
    
    @FocusState private var focusedField: Field?
    
    @State private var selectedTransactionType: TransactionType = .expense
    @State private var selectedDate = Date()
    @State private var isShowingDatePicker = false
    @State private var priceTextField: String = ""
    @State private var categoryName: String = "食費"
    @State private var paymentMethodName: String = "現金"
    @State private var memoTextField: String = ""
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    
                    // 背景
                    LinearGradient(
                        colors: selectedTransactionType == .expense
                        ? [.red, .orange]
                        : [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.8)
                    .ignoresSafeArea()
                    
                    // 日付・金額
                    VStack(spacing: 30) {
                        
                        // 日付ナビゲーター
                        HStack(spacing: 20) {
                            
                            Button {
                                selectedDate = Calendar.current.date(
                                    byAdding: .day,
                                    value: -1,
                                    to: selectedDate
                                ) ?? selectedDate
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundStyle(.black)
                                    .frame(width: 25, height: 25)
                                    .background(Color.white.opacity(0.5))
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
                                .font(.system(size: 18, weight: .medium))
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
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundStyle(.black)
                                    .frame(width: 25, height: 25)
                                    .background(Color.white.opacity(0.5))
                                    .clipShape(Circle())
                            }

                        }
                        
                        // 金額
                        ZStack {
                            Text(Decimal(string: priceTextField) ?? 0, format: .number)
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                                .animation(.snappy, value: priceTextField)
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
                        .padding(.top, 10)
                        .padding(.horizontal, 10)
                        
                        HStack(spacing: 12) {
                            ForEach([100, 500, 1000, 5000], id: \.self) { amount in
                                Button {
                                    let currentPrice = Int(priceTextField) ?? 0
                                    priceTextField = String(currentPrice + amount)
                                } label: {
                                    Text(amount.formatted())
                                        .font(.system(size: 15, design: .rounded))
                                        .foregroundStyle(.black.opacity(0.8))
                                        .frame(maxWidth: .infinity)
                                        .padding(10)
                                }
                                .buttonStyle(RaisedButtonStyle(
                                    cornerRadius: 10,
                                    normalShadowRadius: 2,
                                    pressedShadowRadius: 1,
                                    x: 3,
                                    normalY: 7,
                                    pressedY: 3
                                ))
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, -30)
                    
                    // 白いSheet背景 + カード
                    ZStack(alignment: .top) {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 45,
                            topTrailingRadius: 45
                        )
                        .fill(.white)
                        
                        VStack(spacing: 12) {
                            // カテゴリー・支払方法
                            HStack(spacing: 12) {
                                Button {
                                    // カテゴリー選択の処理
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("カテゴリー")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        HStack {
                                            Spacer()
                                            
                                            Text(categoryName)
                                                .font(.system(size: 20))
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .frame(height: 64)
                                    .background {
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 30,
                                            bottomLeadingRadius: 18,
                                            bottomTrailingRadius: 18,
                                            topTrailingRadius: 18
                                        )
                                        .fill(Color(red: 0.95, green: 0.96, blue: 0.97))
                                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    // 支払方法選択の処理
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("支払方法")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        HStack {
                                            Spacer()
                                            
                                            Text(paymentMethodName)
                                                .font(.system(size: 20))
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .frame(height: 64)
                                    .background {
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 18,
                                            bottomLeadingRadius: 18,
                                            bottomTrailingRadius: 18,
                                            topTrailingRadius: 30
                                        )
                                        .fill(Color(red: 0.95, green: 0.96, blue: 0.97))
                                        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            // メモ
                            MemoCard(text: $memoTextField)
                            
                            Spacer ()
                            
                            HStack(spacing: 12) {
                                Button {
//                                    saveTransaction()
                                } label: {
                                    Text("確定")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 35)
                                }
                                .frame(width: 220)
                                .buttonStyle(CustomButtonStyle())
                                //                                .alert("カテゴリーが選択されていません", isPresented: $showNoCategoryAlert) {
//                                    Button("OK", role: .cancel) { }
//                                } message: {
//                                    Text("カテゴリーを選択してから保存してください。")
//                                }
                                
                                Button {
//                                    showClearAlert = true
                                } label: {
                                    Text("クリア")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 35)
                                }
                                .frame(maxWidth: .infinity)
                                .buttonStyle(CustomButtonStyle())
//                                .alert("内容をクリアしますか？", isPresented: $showClearAlert) {
//                                    Button("キャンセル", role: .cancel) {
//                                    }
//                                    
//                                    Button("クリア", role: .destructive) {
//                                        selectedDate = Date()
//                                        priceTextField = ""
//                                        selectedCategoryID = categories.sorted { $0.sortIndex < $1.sortIndex }.first?.id
//                                        memo = ""
//                                        selectedPaymentMethodID = paymentMethod.sorted { $0.sortIndex < $1.sortIndex }.first?.id
//                                    }
//                                } message: {
//                                    Text("入力した内容がすべてクリアされます。")
//                                }
                            }
//                            .padding(.horizontal)
                            .padding(.bottom, 50)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .frame(height: geometry.size.height * 0.705)
                    .padding(.bottom, -geometry.safeAreaInsets.bottom)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
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
        }
    }
}

#Preview {
    Home()
}



struct RaisedButtonStyle: ButtonStyle {
    
    var cornerRadius: CGFloat = 14
    var normalShadowRadius: CGFloat = 2
    var pressedShadowRadius: CGFloat = 1
    var x: CGFloat = 3
    var normalY: CGFloat = 7
    var pressedY: CGFloat = 3
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(configuration.isPressed ? 0.1 : 0.3),
                        radius: configuration.isPressed
                        ? pressedShadowRadius
                        : normalShadowRadius,
                        x: x,
                        y: configuration.isPressed ? pressedY : normalY
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                Color.black.opacity(0.9),
                                lineWidth: 0.1
                            )
                    }
            }
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}


struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .default))
            .padding(.all, 10)
            .background(
                ZStack {
                    Capsule()
                        .fill(.orange)
                        .stroke(.black,
                                lineWidth:configuration.isPressed ? 0.5 : 1.0)
                        .offset(y:configuration.isPressed ? 0 : 8)
                    Capsule()
                        .fill(.white)
                        .stroke(.black,
                                lineWidth:configuration.isPressed ? 0.5 : 1.5)
                }
            )
            .offset(y:configuration.isPressed ? 8 : 0)
    }
}
