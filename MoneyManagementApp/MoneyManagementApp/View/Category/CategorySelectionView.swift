
import SwiftUI
import SwiftData

struct CategorySelectionView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var isShowingAddCategory = false
    @State private var isDeleteMode = false
    @State private var showDeleteCategoryAlert: Bool = false
    @State private var selectedDeleteCategories: Set<UUID> = []
    
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    
    // CategorySelectionView側
    @Binding var selectedCategoryID: UUID?
    
    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundStyle(.gray)
                        
                        Text("カテゴリーがありません")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.black)
                        
                        Button(action: {
                            isShowingAddCategory.toggle()
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("追加")
                            }
                            .padding(13)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.1))
                        )
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                } else {
                    
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 12
                        ) {
                            ForEach(categories, id: \.id) { category in
                                categoryButton(category)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .background(
                Color(uiColor: .systemGray6)
                    .opacity(0.5)
            )
            .onAppear {
                print("===== Category一覧 =====")
                for category in categories {
                    print(
                        "id: \(category.id), name: \(category.name), imageName: \(category.imageName), sortIndex: \(category.sortIndex)"
                    )
                }
                print("========================")
            }
            .navigationTitle("カテゴリー")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: .systemGray6).opacity(0.5))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isDeleteMode {
                        Button("削除", role: .destructive) {
                            showDeleteCategoryAlert.toggle()
                        }
                        .disabled(selectedDeleteCategories.isEmpty)
                    } else {
                        Menu {
                            Button {
                                isShowingAddCategory = true
                            } label: {
                                Text("追加")
                            }
                            
                            Button {
                                isDeleteMode = true
                                selectedDeleteCategories.removeAll()
                            } label: {
                                Text("削除")
                            }
                            .disabled(categories.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if !isDeleteMode {
                        Button("閉じる") {
                            dismiss()
                        }
                    } else {
                        Button("キャンセル") {
                            isDeleteMode = false
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingAddCategory) {
                AddCategoryView()
            }
            .alert("削除確認", isPresented: $showDeleteCategoryAlert) {
                Button("削除", role: .destructive) {
                    deleteSelectedCategories()
                }
                
                Button("キャンセル", role: .cancel) {
                }
            } message: {
                Text("選択したカテゴリーを削除しますか？")
            }
        }
    }
    
    // MARK: カテゴリーのセル
    
    private func categoryButton(_ category: Category) -> some View {
        let isChecked: Bool = selectedDeleteCategories.contains(category.id)
        let dimmed: Bool = isDeleteMode && !isChecked
        let contentColor: Color = (isDeleteMode && !isChecked) ? .gray : .black
        let categoryColor: Color = colorFromHex(category.colorHex)
        
        // 背景
        let backgroundColor: Color = {
            if isChecked { return Color.red.opacity(0.05) }      // 削除対象: 赤
            if isDeleteMode { return Color.gray.opacity(0.1) }   // 削除モードの未チェック: グレー
            return categoryColor.opacity(0.2)                    // 通常: カテゴリーの色
        }()
        
        // 枠線
        let borderColor: Color = {
            if isChecked { return .red }
            if isDeleteMode { return .gray }
            return categoryColor
        }()
        
        return Button {
            didTap(category)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: category.imageName)
                    .font(.system(size: 30))
                    .foregroundStyle(contentColor)
                
                Text(category.name)
                    .font(.system(size: 15))
                    .foregroundStyle(contentColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func didTap(_ category: Category) {
        if isDeleteMode {
            if selectedDeleteCategories.contains(category.id) {
                selectedDeleteCategories.remove(category.id)
            } else {
                selectedDeleteCategories.insert(category.id)
            }
        } else {
            selectedCategoryID = category.id
            dismiss()
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
    
    private func deleteSelectedCategories() {
        
        // 削除前
        print("========== 📋 削除前のカテゴリー一覧 ==========")
        
        for category in categories.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            print("📌 \(category.name) | sortIndex: \(category.sortIndex)")
        }
        
        // 選択中のカテゴリーが削除対象に含まれていたら、参照が消える前にリセットする
        if let currentSelectedID = selectedCategoryID,
           selectedDeleteCategories.contains(currentSelectedID) {
            
            selectedCategoryID = nil
        }
        
        // IDの集合から、実際に削除するCategoryオブジェクトを取得
        let categoriesToDelete = categories.filter {
            selectedDeleteCategories.contains($0.id)
        }
        

        // 削除するもの
        print("========== ➖ 削除するカテゴリー ==========")
        for category in categoriesToDelete {
            print("📌 カテゴリー名: \(category.name)")
            print("🖼️ アイコン: \(category.imageName)")
            print("🔢 sortIndex: \(category.sortIndex)")
        }
        
        // 削除
        for category in categoriesToDelete {
            modelContext.delete(category)
        }
        
        // 削除後に残るカテゴリー
        let remainingCategories = categories
            .filter { !selectedDeleteCategories.contains($0.id) }
            .sorted { $0.sortIndex < $1.sortIndex }
        
        // sortIndexを詰め直す
        for (index, category) in remainingCategories.enumerated() {
            category.sortIndex = index
        }
        
        // 📋 追加後の一覧
        print("========== 📋 削除後のカテゴリー一覧 ==========")
        
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

        selectedDeleteCategories.removeAll()
        isDeleteMode = false
    }
}

#Preview("ダミー") {
    let container = PreviewContainer.make()
    let samples: [(String, String, String)] = [
        ("家賃", "house", "#4DABF7"),
        ("食費", "fork.knife", "#FF6B6B"),
        ("日用品", "basket", "#69DB7C"),
        ("交通費", "car", "#FFD43B"),
        ("医療費", "cross.case", "#B197FC")
    ]
    for (index, s) in samples.enumerated() {
        container.mainContext.insert(
            Category(name: s.0, imageName: s.1, colorHex: s.2, sortIndex: index)
        )
    }
    return CategorySelectionView(selectedCategoryID: .constant(nil))
        .modelContainer(container)
}

#Preview("カテゴリーなし") {
    let container = PreviewContainer.make()
    return CategorySelectionView(selectedCategoryID: .constant(nil))
        .modelContainer(container)
}
