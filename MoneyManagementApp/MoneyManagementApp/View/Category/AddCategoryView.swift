
import SwiftUI
import SwiftData

struct AddCategoryView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    
    @State private var categoryName = ""
    @State private var selectedIcon: String? = nil
    @State private var selectedColor = "#FF6B6B"
    
    // オンボーディング用: 追加後にdismiss()の代わりにこちらを呼ぶ
    var onSave: (() -> Void)? = nil
    // オンボーディング用: キャンセルボタンを非表示にする
    var hideCancelButton: Bool = false

    
    // 家計簿カテゴリー向けによく使うSF Symbolを厳選
    // (CategoryIconPickerView と同じ一覧を共有)
    private let allIcons: [(symbol: String, keywords: [String])] = [
        ("fork.knife", ["食事", "食べ物", "食費", "料理"]),
        ("cup.and.saucer", ["飲み物", "コーヒー", "お茶", "カフェ"]),
        ("cart", ["買い物", "ショッピング", "スーパー"]),
        ("bag", ["買い物", "バッグ"]),
        ("basket", ["買い物", "日用品"]),
        ("takeoutbag.and.cup.and.straw", ["外食", "テイクアウト", "食事"]),
        
        ("car", ["車", "自動車", "交通"]),
        ("fuelpump", ["ガソリン", "給油", "車"]),
        ("bus", ["バス", "交通"]),
        ("tram", ["電車", "交通"]),
        ("airplane", ["飛行機", "旅行"]),
        ("bicycle", ["自転車", "交通"]),
        
        ("house", ["家", "住宅", "住居", "家賃"]),
        ("bolt", ["電気", "電気代", "電力"]),
        ("drop", ["水道", "水", "水道代"]),
        ("flame", ["ガス", "ガス代"]),
        ("wifi", ["通信", "インターネット", "Wi-Fi"]),
        
        ("cross.case", ["病院", "医療", "病気"]),
        ("pills", ["薬", "薬代", "医療"]),
        ("stethoscope", ["病院", "医者", "医療"]),
        ("heart", ["健康", "医療"]),
        
        ("gamecontroller", ["ゲーム", "娯楽"]),
        ("film", ["映画", "娯楽"]),
        ("music.note", ["音楽", "娯楽"]),
        ("sportscourt", ["スポーツ", "運動"]),
        
        ("book", ["本", "読書"]),
        ("graduationcap", ["学校", "教育", "学費"]),
        ("pencil", ["文房具", "勉強", "学校"]),
        
        ("tshirt", ["服", "衣類", "洋服"]),
        ("shoe", ["靴", "衣類"]),
        ("scissors", ["美容", "理容", "散髪"]),
        ("sparkles", ["美容", "化粧"]),
        
        ("gift", ["プレゼント", "贈り物", "ギフト"]),
        ("birthday.cake", ["誕生日", "ケーキ"]),
        ("pawprint", ["ペット", "動物", "犬", "猫"]),
        
        ("banknote", ["お金", "現金", "銀行"]),
        ("creditcard", ["クレジットカード", "カード"]),
        ("wallet.pass", ["財布", "お金"]),
        
        ("briefcase", ["仕事", "ビジネス"]),
        ("building.2", ["会社", "仕事", "ビル"]),
        ("phone", ["電話", "スマホ", "携帯"]),
        ("laptopcomputer", ["パソコン", "PC", "仕事"]),
        
        ("airplane.departure", ["旅行", "出発", "飛行機"]),
        ("bed.double", ["ホテル", "宿泊", "睡眠"]),
        ("beach.umbrella", ["旅行", "海", "レジャー"]),
        
        ("wrench.and.screwdriver", ["修理", "工具", "メンテナンス"]),
        ("hammer", ["工具", "工事", "修理"]),
        ("leaf", ["自然", "植物", "環境"]),
        
        // 飲み物・お酒
        ("wineglass", ["お酒", "ワイン", "飲み会", "外食"]),
        
        // 買い物・お店
        ("storefront", ["店", "買い物", "コンビニ"]),
        ("tag", ["セール", "値札", "買い物"]),
        ("shippingbox", ["宅配", "荷物", "通販"]),
        ("handbag", ["バッグ", "ファッション", "買い物"]),
        ("giftcard", ["ギフトカード", "商品券"]),
        
        // 交通
        ("parkingsign", ["駐車場", "車"]),
        ("scooter", ["バイク", "スクーター"]),
        ("ferry", ["フェリー", "船", "旅行"]),
        ("figure.walk", ["散歩", "徒歩", "ウォーキング"]),
        ("key", ["鍵", "不動産", "車"]),
        
        // 住まい
        ("lightbulb", ["電球", "電気", "光熱費"]),
        ("sofa", ["家具", "インテリア"]),
        ("washer", ["洗濯", "家電"]),
        ("shower", ["お風呂", "シャワー"]),
        ("trash", ["ゴミ", "処分"]),
        ("paintbrush", ["リフォーム", "塗装", "DIY"]),
        
        // 医療
        ("bandage", ["けが", "絆創膏", "医療"]),
        ("syringe", ["注射", "予防接種", "医療"]),
        ("eyeglasses", ["メガネ", "眼科"]),
        
        // 娯楽・趣味
        ("tv", ["テレビ", "動画", "娯楽"]),
        ("play.rectangle", ["動画", "サブスク", "配信"]),
        ("headphones", ["音楽", "イヤホン"]),
        ("theatermasks", ["舞台", "演劇", "娯楽"]),
        ("ticket", ["チケット", "ライブ", "イベント"]),
        ("camera", ["写真", "カメラ", "趣味"]),
        ("paintpalette", ["絵", "趣味", "アート"]),
        ("guitars", ["楽器", "音楽", "趣味"]),
        ("party.popper", ["パーティー", "お祝い", "イベント"]),
        
        // 運動
        ("figure.run", ["ランニング", "運動", "ジム"]),
        ("dumbbell", ["筋トレ", "ジム", "運動"]),
        ("soccerball", ["サッカー", "スポーツ"]),
        ("tennis.racket", ["テニス", "スポーツ"]),
        
        // 教育
        ("books.vertical", ["本", "参考書", "勉強"]),
        ("newspaper", ["新聞", "ニュース"]),
        ("backpack", ["学校", "通学", "ランドセル"]),
        
        // 家族・ペット
        ("person.2", ["家族", "夫婦", "友人"]),
        ("dog", ["犬", "ペット"]),
        ("cat", ["猫", "ペット"]),
        
        // お金・保険・税金
        ("yensign.circle", ["円", "お金", "給与"]),
        ("dollarsign.circle", ["ドル", "お金", "海外"]),
        ("chart.line.uptrend.xyaxis", ["投資", "株", "資産"]),
        ("building.columns", ["銀行", "税金", "役所"]),
        ("percent", ["利息", "税", "手数料"]),
        ("shield", ["保険", "安心"]),
        ("umbrella", ["保険", "雨"]),
        ("doc.text", ["書類", "契約", "請求書"]),
        
        // 通信・デバイス
        ("iphone", ["スマホ", "携帯", "通信"]),
        ("desktopcomputer", ["パソコン", "PC"]),
        ("printer", ["プリンター", "印刷"]),
        ("icloud", ["クラウド", "サブスク"]),
        ("antenna.radiowaves.left.and.right", ["通信", "電波", "携帯"]),
        
        // 旅行・自然
        ("suitcase", ["旅行", "出張", "荷物"]),
        ("map", ["地図", "旅行", "観光"]),
        ("tent", ["キャンプ", "アウトドア"]),
        ("mountain.2", ["登山", "山", "アウトドア"]),
        ("sun.max", ["夏", "天気", "レジャー"]),
        ("tree", ["木", "自然", "公園"]),
        
        // その他
        ("star", ["お気に入り", "特別"]),
        ("flag", ["目標", "記念日"]),
        ("bell", ["通知", "リマインド"]),
        ("trophy", ["賞", "景品", "成果"]),
        ("face.smiling", ["お小遣い", "楽しみ"]),
        
        ("ellipsis.circle", ["その他"])
    ]
    
    // 選択できるカテゴリーカラー(色相順に5色ずつ並べる)
    private let categoryColors: [(name: String, hex: String)] = [
        // 赤・オレンジ系
        ("レッド", "#FF6B6B"),
        ("クリムゾン", "#E03131"),
        ("ピーチ", "#FFC9A8"),
        ("オレンジ", "#FFA94D"),
        ("ディープオレンジ", "#F76707"),
        // 黄・緑系
        ("イエロー", "#FFD43B"),
        ("ゴールド", "#E0A800"),
        ("ライム", "#A9E34B"),
        ("グリーン", "#69DB7C"),
        ("フォレスト", "#2F9E44"),
        // 青緑・青系
        ("ミント", "#63E6BE"),
        ("ティール", "#38B2AC"),
        ("シアン", "#3BC9DB"),
        ("ブルー", "#4DABF7"),
        ("ダークブルー", "#1971C2"),
        // 紫・ピンク系
        ("インディゴ", "#5C7CFA"),
        ("バイオレット", "#7048E8"),
        ("パープル", "#B197FC"),
        ("ラベンダー", "#D0BFFF"),
        ("ピンク", "#F783AC"),
        // その他
        ("ローズ", "#C2255C"),
        ("ブラウン", "#A5673F"),
        ("ベージュ", "#D4B48C"),
        ("グレー", "#868E96"),
        ("ブラック", "#343A40")
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
                                        .foregroundStyle(colorFromHex(selectedColor))
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
            .navigationTitle("カテゴリーを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        addCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
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
    
    private func addCategory() {
        
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

