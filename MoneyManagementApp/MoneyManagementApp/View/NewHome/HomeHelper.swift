
import SwiftUI
import SwiftData

// MARK: - 日付ナビゲーター
/// 「‹ 2026年11月15日 ›」。矢印で前日・翌日、日付部分のタップで `onTapDate` を呼ぶ。
struct DateNavigator: View {
    @Binding var date: Date
    let onTapDate: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            arrowButton(systemName: "chevron.left", days: -1)
            
            Button(action: onTapDate) {
                Text(
                    date.formatted(
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
            
            arrowButton(systemName: "chevron.right", days: 1)
        }
    }
    
    private func arrowButton(systemName: String, days: Int) -> some View {
        Button {
            date = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.black)
                .frame(width: 25, height: 25)
                .background(Color.white.opacity(0.5))
                .clipShape(Circle())
        }
    }
}

// MARK: - 日付選択シート
/// 日付を選ぶと自動で閉じる。「今日」ボタンで今日の日付に戻して閉じる。
struct DatePickerSheet: View {
    @Binding var date: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            DatePicker(
                "日付を選択",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ja_JP"))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .onChange(of: date) {
                isPresented = false
            }
            
            Spacer(minLength: 0)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    /// タイトル + 今日ボタン
    private var header: some View {
        HStack {
            Text("日付を選択")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
            
            Spacer()
            
            Button {
                date = Date()
                isPresented = false
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
    }
}

// MARK: - 金額表示
/// 画面には通貨表示のTextを出し、数字キーボードを出すための入力欄(TextField)は透明にして重ねている。
struct AmountDisplay: View {
    @Binding var text: String
    var focus: FocusState<Field?>.Binding
    
    var body: some View {
        ZStack {
            Text(Decimal(string: text) ?? 0, format: .currency(code: "JPY"))
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: text)
                .contentShape(Rectangle())
                .onTapGesture {
                    focus.wrappedValue = .price
                }
                .accessibilityIdentifier("home.amountText")
            
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .focused(focus, equals: .price)
                .foregroundColor(.clear)
                .tint(.clear)
                .opacity(0.01)
                .allowsHitTesting(false)
//                .onTapGesture {
//                    isTextFieldFocused.toggle()
//                }
        }
        .frame(height: 90)
        .padding(.top, 1)
        .padding(.horizontal, 10)
//        .safeAreaInset(edge: .bottom) {
//            if isTextFieldFocused {
//                HStack(alignment: .center, spacing: 0) {
//                    Spacer()
//                    Button(
//                        action: {
//                            isTextFieldFocused = false
//                        },
//                        label: {
//                            Text("閉じる")
//                                .foregroundStyle(Color.primary)
//                                .padding(14)
//                                .glassEffect()
//                        },
//                    )
//                    .padding(8)
//                }
//            }
//        }
    }
}

// MARK: - クイック金額ボタン
/// タップするたびに、押した金額を入力中の金額へ加算する。
struct QuickAmountButtons: View {
    @Binding var priceText: String
    
    private let amounts = [100, 500, 1000, 5000]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(amounts, id: \.self) { amount in
                Button {
                    priceText = String((Int(priceText) ?? 0) + amount)
                } label: {
                    Text(amount.formatted())
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.black.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(10)
                }
                .buttonStyle(RaisedButtonStyle(cornerRadius: 10))
                .accessibilityIdentifier("home.quickAmount.\(amount)")
            }
        }
        .padding(.top, 5)
        .padding(.horizontal, 20)
    }
}

// MARK: - 日付選択カード

struct SelectionDate: View {
    
    @Binding var selectedDate: Date
    @Binding var onTapDatePicker: Bool
    
    var body: some View {
        Button(action: {
            onTapDatePicker.toggle()
        }) {
            HStack {
                Text("日付")
                Spacer()
                Text(selectedDate, format: .dateTime.year().month().day())
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 15)
            .frame(height: 50)
            .customBackground(cornerRadius: 30)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.dateButton")
        .sheet(isPresented: $onTapDatePicker) {
            DatePickerSheet(
                date: $selectedDate,
                isPresented: $onTapDatePicker
            )
            .presentationBackground(.white)
        }
    }
}

// MARK: - 選択カード(カテゴリー・支払方法)
/// 上に小さなタイトル、右寄せで選択中の値を表示するカード。角の丸みは `corners` で指定する。
struct SelectionCard: View {
    let title: String
    let value: String
    let corners: RectangleCornerRadii
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .frame(maxWidth: .infinity, minHeight: 30, maxHeight: 30, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(height: 64)
//            .cardBackground(UnevenRoundedRectangle(cornerRadii: corners))
        }
        .buttonStyle(.plain)
        .customBackground()
    }
}

// MARK: - メモ
struct MemoCard: View {
    @Binding var text: String
    var focus: FocusState<Field?>.Binding
    
    var body: some View {
        HStack {
            Image(systemName: "pencil")
                .scaledToFit()
                .foregroundColor(.primary)
            TextField(
                text: $text,
                prompt: Text("メモを入力")
                    .font(.callout)
            ) {
                EmptyView()
            }
            .focused(focus, equals: .memo) 
            .lineLimit(1)
            .accessibilityIdentifier("home.memoField")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 15)
        .frame(height: 50)
        .customBackground(cornerRadius: 30)
    }
}

// MARK: - いつもの収支カード
/// 左側をタップで一覧シートを開き、右側の「登録」で今の入力を保存する。
struct UsualRecordCard: View {
    let selectedTitle: String?
    let onOpenList: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onOpenList) {
                HStack {
                    Image(systemName: "star")
                        .foregroundColor(.primary)
                    Text("いつもの収支")
                        .font(.callout)
                    Spacer()
                    
                    if let selectedTitle {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text(selectedTitle)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color(uiColor: .systemGray6))
                        .clipShape(Capsule())
                        .frame(maxWidth: 160, alignment: .trailing)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.usualListButton")
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 15)
        .frame(height: 50)
        .customBackground(cornerRadius: 30)
    }
}

// MARK: - いつもの収支一覧シート
/// 行をタップすると入力欄に反映して閉じる。左スワイプで削除。
struct UsualRecordCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showUsualRecordEditView: Bool = false
    
    let records: [UsualRecord]
    let onApply: (UsualRecord) -> Void
    let onDelete: (UsualRecord) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    ContentUnavailableView {
                        Label("", systemImage: "")
                    } description: {
                        Text("いつもの収支がありません")
                    } actions: {
                        Button(action: {
                            showUsualRecordEditView.toggle()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "plus")
                                Text("登録する")
                            }
                            .padding(10)
                            .tint(.blue)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.2))
                        )
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(records) { item in
                        Section {
                            Button {
                                onApply(item)
                                dismiss()
                            } label: {
                                UsualRecordRow(record: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { records[$0] }.forEach(onDelete)
                    }
                }
            }
            .navigationTitle("いつもの収支")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showUsualRecordEditView.toggle()
                    }) {
                        Text("登録")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.usualRegisterButton")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showUsualRecordEditView) {
            UsualRecordEditView()
        }
    }
}

// MARK: - いつもの収支の行
struct UsualRecordRow: View {
    let record: UsualRecord
    
    /// 名前の下に出す補足(カテゴリー・支払方法・メモ)。メモが空のときは行ごと出さない。
    private var details: [String] {
        [
            record.categoryName ?? "カテゴリー未設定",
            record.paymentMethodName ?? "支払方法未設定",
            record.memo
        ]
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .foregroundStyle(.primary)
                ForEach(details, id: \.self) { detail in
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(record.amount, format: .currency(code: "JPY"))
                .foregroundStyle(.primary)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - 確定・クリアボタン
struct InputActionButtons: View {
    
    let accentColor: Color
    let onConfirm: () -> Bool
    let onClear: () -> Void
    
    @State private var isShowingCheck = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                guard !isShowingCheck else { return }
                guard onConfirm() else { return }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowingCheck = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingCheck = false
                    }
                }
                
            } label: {
                ZStack {
                    Text("確定")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.black)
                        .offset(x: isShowingCheck ? -220 : 0)
                        .opacity(isShowingCheck ? 0 : 1)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.checkRGB)
                        .offset(x: isShowingCheck ? 0 : 220)
                        .opacity(isShowingCheck ? 1 : 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 35)
                .clipped()
            }
            .frame(width: 220)
            .buttonStyle(CustomButtonStyle(accentColor: accentColor))
            .disabled(isShowingCheck)
            
            .disabled(isShowingCheck)
            .accessibilityIdentifier("home.confirmButton")
            
            
            Button(action: onClear) {
                Text("クリア")
                    .font(.system(size: 16))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 35)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(CustomButtonStyle(accentColor: accentColor))
            
            .buttonStyle(CustomButtonStyle(accentColor: accentColor))
            .accessibilityIdentifier("home.clearButton")
        }
    }
}

// MARK: カテゴリー・支払方法・メモの背景
struct CustomBackground: ViewModifier {
    
    var cornerRadius: CGFloat = 3
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // 下側の黒い立体部分
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.gray)
                        .offset(x: 2, y: 2)
                    
                    // 上側の白い本体
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.white)
                        .stroke(.black, lineWidth: 0.5)
                    //                        .offset(x: -3, y: -0.05)
                }
            }
            .padding(.bottom, 5)
    }
}

extension View {
    func customBackground(cornerRadius: CGFloat = 18) -> some View {
        self.modifier(
            CustomBackground(cornerRadius: cornerRadius)
        )
    }
}

#Preview {
    let record = [UsualRecord(title: "バス", amount: 1290, typeRaw: TransactionType.expense.rawValue, memo: "メモめも", categoryName: "交通費", paymentMethodName: "Suica") ]
    UsualRecordCardSheet(records: record, onApply: { _ in }, onDelete: { _ in })
}
