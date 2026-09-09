
import SwiftUI
import SwiftData

struct AddCategoryView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    
    @State private var categoryName = ""
    @State private var selectedIcon: String? = nil
    @State private var searchText = ""
    
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
        
        ("ellipsis.circle", ["その他"])
    ]
    
    private var filteredIcons: [(symbol: String, keywords: [String])] {
        guard !searchText.isEmpty else { return allIcons }
        
        return allIcons.filter { icon in
            icon.symbol.localizedCaseInsensitiveContains(searchText)
            || icon.keywords.contains {
                $0.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
    
    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリー名") {
                    TextField("食費、日用品、教育費...", text: $categoryName)
                }
                
                Section("アイコン") {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredIcons, id: \.symbol) { icon in
                            Button {
                                if selectedIcon == icon.symbol {
                                    selectedIcon = nil
                                } else {
                                    selectedIcon = icon.symbol
                                }
                            } label: {
                                Image(systemName: icon.symbol)
                                    .font(.system(size: 24))
                                    .foregroundStyle(.black)
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
            }
            .navigationTitle("カテゴリーを追加")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "アイコンを検索")
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

