
import SwiftUI

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
            
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .focused(focus, equals: .price)
                .foregroundColor(.clear)
                .tint(.clear)
                .opacity(0.01)
                .allowsHitTesting(false)
        }
        .frame(height: 90)
        .padding(.top, 1)
        .padding(.horizontal, 10)
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
            }
        }
        .padding(.top, 10)
        .padding(.horizontal, 20)
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
                HStack {
                    Spacer()
                    
                    Text(value)
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
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
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 15)
        .frame(height: 50)
        .customBackground(cornerRadius: 30)
    }
}

// MARK: - 確定・クリアボタン
struct InputActionButtons: View {
    
    let accentColor: Color
    let onConfirm: () -> Void
    let onClear: () -> Void
    
    @State private var isShowingCheck = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                guard !isShowingCheck else { return }
                
                onConfirm()
                
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
            
            Button(action: onClear) {
                Text("クリア")
                    .font(.system(size: 16))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 35)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(CustomButtonStyle(accentColor: accentColor))
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
