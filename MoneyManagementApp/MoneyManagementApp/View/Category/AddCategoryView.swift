
import SwiftUI
import SwiftData

struct AddCategoryView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    
    @State private var categoryName = ""
    @State private var selectedIcon: String? = nil
    @State private var selectedColor: String? = nil
    
    // オンボーディング用: 追加後にdismiss()の代わりにこちらを呼ぶ
    var onSave: (() -> Void)? = nil
    // オンボーディング用: キャンセルボタンを非表示にする
    var hideCancelButton: Bool = false
    
    // 編集対象(nilなら新規追加)
    let editingCategory: Category?
    
    private var isEditing: Bool { editingCategory != nil }
    
    init(
        editingCategory: Category? = nil,
        onSave: (() -> Void)? = nil,
        hideCancelButton: Bool = false
    ) {
        self.editingCategory = editingCategory
        self.onSave = onSave
        self.hideCancelButton = hideCancelButton
        // 編集時は既存の値を初期値にする
        _categoryName = State(initialValue: editingCategory?.name ?? "")
        _selectedIcon = State(initialValue: editingCategory?.imageName)
        _selectedColor = State(initialValue: editingCategory?.colorHex)
    }
    
    // 家計簿カテゴリー向けによく使うSF Symbolを厳選
    // (CategoryIconPickerView と同じ一覧を共有)
    private let allIcons: [(symbol: String, keywords: [String])] = [
        // 食べ物・飲み物
        ("fork.knife", ["レストラン", "ランチ", "ディナー"]),
        ("mug", ["コーヒー", "マグカップ", "カフェ"]),
        ("carrot", ["野菜", "食材", "自炊"]),
        ("fish", ["魚", "食材", "水族館"]),
        
        // 買い物・お店
        ("barcode", ["バーコード", "コンビニ", "買い物"]),
        ("qrcode", ["QR決済", "スマホ決済", "支払い"]),
        ("scalemass", ["量り売り", "計量", "食材"]),
        
        // 交通
        ("car.2", ["車", "カーシェア", "レンタカー"]),
        ("bolt.car", ["電気自動車", "充電", "車"]),
        ("sailboat", ["ヨット", "船", "マリン"]),
        ("airplane.arrival", ["到着", "飛行機", "海外旅行"]),
        ("mappin.and.ellipse", ["場所", "お出かけ", "観光"]),
        
        // 住まい・家電
        ("refrigerator", ["冷蔵庫", "家電", "キッチン"]),
        ("fan", ["扇風機", "家電", "夏"]),
        ("powerplug", ["電源", "コンセント", "電気"]),
        ("thermometer", ["体温", "気温", "暖房"]),
        ("snowflake", ["エアコン", "冷房", "冬"]),
        
        // 医療・健康
        ("cross.vial", ["検査", "採血", "医療"]),
        ("waveform.path.ecg", ["心電図", "健康診断", "健康"]),
        ("medical.thermometer", ["風邪", "発熱", "医療"]),
        ("lungs", ["呼吸", "健康", "医療"]),
        ("brain.head.profile", ["メンタル", "心療", "カウンセリング"]),
        ("heart.text.square", ["健康診断", "保険証", "医療"]),
        ("ear", ["耳", "耳鼻科", "補聴器"]),
        
        // 娯楽・趣味
        ("dice", ["ボードゲーム", "ギャンブル", "娯楽"]),
        ("puzzlepiece", ["パズル", "趣味", "おもちゃ"]),
        ("mic", ["カラオケ", "歌", "録音"]),
        ("radio", ["ラジオ", "音楽", "娯楽"]),
        ("pianokeys", ["ピアノ", "楽器", "習い事"]),
        ("book.closed", ["小説", "読書", "本"]),
        ("balloon", ["風船", "お祝い", "イベント"]),
        
        // 運動
        ("basketball", ["バスケ", "スポーツ", "運動"]),
        ("baseball", ["野球", "スポーツ", "運動"]),
        ("football", ["アメフト", "ラグビー", "スポーツ"]),
        ("figure.pool.swim", ["水泳", "プール", "スポーツ"]),
        ("figure.hiking", ["ハイキング", "登山", "アウトドア"]),
        ("figure.golf", ["ゴルフ", "スポーツ", "趣味"]),
        
        // 仕事・学校
        ("pencil.and.ruler", ["製図", "文房具", "勉強"]),
        ("paperclip", ["文房具", "書類", "事務用品"]),
        ("folder", ["ファイル", "書類", "仕事"]),
        ("tray.full", ["書類", "郵便", "整理"]),
        ("calendar", ["予定", "日程", "月額"]),
        ("clock", ["時間", "時計", "待ち合わせ"]),
        ("studentdesk", ["塾", "習い事", "勉強"]),
        ("megaphone", ["広告", "宣伝", "仕事"]),
        
        // 連絡
        ("envelope", ["郵便", "メール", "手紙"]),
        ("message", ["メッセージ", "連絡", "チャット"]),
        ("paperplane", ["送付", "メール", "発送"]),
        
        // 家族・子ども
        ("person.3", ["家族", "友人", "グループ"]),
        ("figure.and.child.holdinghands", ["子ども", "育児", "家族"]),
        ("figure.2.and.child.holdinghands", ["家族", "子ども", "レジャー"]),
        
        // ペット・生き物
        ("hare", ["うさぎ", "ペット", "動物"]),
        ("tortoise", ["亀", "ペット", "動物"]),
        ("bird", ["鳥", "ペット", "動物"]),
        ("ladybug", ["虫", "昆虫", "駆除"]),
        
        // 美容
        ("hands.sparkles", ["手洗い", "衛生", "ハンドケア"]),
        ("mouth", ["歯医者", "歯", "口"]),
        ("eye", ["コンタクト", "眼科", "視力"]),
        ("comb", ["美容院", "ヘアケア", "髪"]),
        
        // お金
        ("chart.bar", ["売上", "集計", "投資"]),
        ("chart.pie", ["配分", "資産", "家計"]),
        ("coloncurrencysign.circle", ["通貨", "両替", "海外"]),
        ("eurosign.circle", ["ユーロ", "海外", "旅行"]),
        ("bitcoinsign.circle", ["仮想通貨", "ビットコイン", "投資"]),
        ("arrow.left.arrow.right", ["振替", "送金", "両替"]),
        ("lock.shield", ["セキュリティ", "保険", "保護"]),
        
        // 旅行・自然・天気
        ("globe", ["海外", "世界", "旅行"]),
        ("binoculars", ["観光", "バードウォッチング", "旅行"]),
        ("water.waves", ["海", "川", "マリン"]),
        ("sunrise", ["朝", "初日の出", "旅行"]),
        ("moon", ["夜", "夜景", "睡眠"]),
        ("cloud.rain", ["雨", "天気", "傘"]),
        ("wind", ["風", "天気", "台風"]),
        
        // その他
        ("hand.thumbsup", ["いいね", "応援", "推し活"]),
        ("hands.clap", ["お祝い", "拍手", "寄付"]),
        ("gearshape", ["設定", "メンテナンス", "管理"]),
        ("medal", ["メダル", "表彰", "記念"]),
        ("rosette", ["賞", "表彰", "お祝い"]),
        ("bookmark", ["ブックマーク", "保存", "お気に入り"]),
        ("alarm", ["アラーム", "起床", "リマインド"]),
        
        ("ellipsis.circle", ["その他"])
    ]
    
    // 選択できるカテゴリーカラー(色相順に5色ずつ並べる)
    private let categoryColors: [(name: String, hex: String)] = [
        // 赤・ピンク系
        ("ピンク", "#F783AC"),
        ("レッド", "#FF6B6B"),
        ("クリムゾン", "#E03131"),
        ("ローズ", "#C2255C"),
        ("ワイン", "#8C1D40"),
        // オレンジ・黄系
        ("ピーチ", "#FFC9A8"),
        ("イエロー", "#FFD43B"),
        ("オレンジ", "#FFA94D"),
        ("ゴールド", "#E0A800"),
        ("ディープオレンジ", "#F76707"),
        // 緑系
        ("ライム", "#A9E34B"),
        ("グリーン", "#69DB7C"),
        ("ミント", "#63E6BE"),
        ("ティール", "#38B2AC"),
        ("フォレスト", "#2F9E44"),
        // 青系
        ("シアン", "#3BC9DB"),
        ("ブルー", "#4DABF7"),
        ("ダークブルー", "#1971C2"),
        ("インディゴ", "#5C7CFA"),
        ("バイオレット", "#7048E8"),
        // 紫・アース系
        ("ラベンダー", "#D0BFFF"),
        ("パープル", "#B197FC"),
        ("ベージュ", "#D4B48C"),
        ("ブラウン", "#A5673F"),
        ("グレー", "#868E96"),
    ]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
    
    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリー名") {
                    TextField("食費、日用品、教育費...", text: $categoryName)
                }
                
                Section("アイコン") {
                    ScrollView(.vertical) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(allIcons, id: \.symbol) { icon in
                                Button {
                                    if selectedIcon == icon.symbol {
                                        selectedIcon = nil
                                    } else {
                                        selectedIcon = icon.symbol
                                    }
                                } label: {
                                    Image(systemName: icon.symbol)
                                        .font(.system(size: 24))
                                        .foregroundStyle(selectedColor.map { colorFromHex($0) } ?? .black)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .stroke(
                                                    selectedIcon == icon.symbol
                                                    ? Color.black
                                                    : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(height: 300)
                }
                
                Section("カラー") {
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: 12),
                            count: 5
                        ),
                        spacing: 16
                    ) {
                        ForEach(categoryColors, id: \.hex) { color in
                            Button {
                                selectedColor = color.hex
                            } label: {
                                Circle()
                                    .fill(colorFromHex(color.hex))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if selectedColor == color.hex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .overlay {
                                        Circle()
                                            .stroke(
                                                selectedColor == color.hex
                                                ? Color.primary
                                                : Color.clear,
                                                lineWidth: 2
                                            )
                                            .padding(-4)
                                    }
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(color.name)
                            .accessibilityAddTraits(
                                selectedColor == color.hex ? .isSelected : []
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(isEditing ? "カテゴリーを編集" : "カテゴリーを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        if let category = editingCategory {
                            updateCategory(category)
                        } else {
                            addCategory()
                        }

                    }) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(canSave ? Color.black : Color.gray.opacity(0.4))
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !categoryName.trimmingCharacters(in: .whitespaces).isEmpty
        && selectedIcon != nil
        && selectedColor != nil
    }
    
    private func colorFromHex(_ hex: String) -> Color {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let number = UInt64(value, radix: 16) ?? 0
        
        return Color(
            .sRGB,
            red: Double((number >> 16) & 0xFF) / 255,
            green: Double((number >> 8) & 0xFF) / 255,
            blue: Double(number & 0xFF) / 255,
            opacity: 1
        )
    }
    
    private func updateCategory(_ category: Category) {
        guard let colorHex = selectedColor else { return }
        category.name = categoryName
        category.imageName = selectedIcon ?? "ellipsis.circle"
        category.colorHex = colorHex
        dismiss()
    }
    
    private func addCategory() {
        guard let colorHex = selectedColor else { return }
        // 📋 追加前の一覧
        print("========== 📋 追加前のカテゴリー一覧 ==========")
        
        for category in categories.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            print("📌 \(category.name) | sortIndex: \(category.sortIndex)")
        }
        
        // ➕ 追加するカテゴリーの情報
        let iconName = selectedIcon ?? "ellipsis.circle"
        let newSortIndex = (categories.map(\.sortIndex).max() ?? -1) + 1
        
        print("========== ➕ 追加するカテゴリー ==========")
        print("📌 カテゴリー名: \(categoryName)")
        print("🖼️ アイコン: \(iconName)")
        print("🔢 sortIndex: \(newSortIndex)")
        
        // ➕ Categoryを作成
        let newCategory = Category(
            name: categoryName,
            imageName: iconName,
            colorHex: colorHex,
            sortIndex: newSortIndex
        )
        
        // 💾 SwiftDataに追加
        modelContext.insert(newCategory)
        
        // 📋 追加後の一覧
        print("========== 📋 追加後のカテゴリー一覧 ==========")
        
        let updatedCategories = categories
            .sorted { $0.sortIndex < $1.sortIndex }
        
        for category in updatedCategories {
            print("""
        📌 カテゴリー名: \(category.name)
        🖼️ アイコン: \(category.imageName)
        🔢 sortIndex: \(category.sortIndex)
        """)
        }
        
        print("==============================================")
        
        dismiss()
    }
}

#Preview {
    AddCategoryView()
}

