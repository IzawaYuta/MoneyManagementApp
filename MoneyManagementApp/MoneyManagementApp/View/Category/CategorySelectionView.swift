
import SwiftUI
import SwiftData

struct CategorySelectionView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var isShowingAddCategory = false
    @State private var isDeleteMode = false
    @State private var showDeleteCategoryAlert: Bool = false
    @State private var selectedDeleteCategories: Set<Category> = []
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Category.sortIndex)
    private var categories: [Category]
    
    @Binding var selectedCategory: Category?
    
    @State private var showNoCategoryAlert = false
    
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
                        
                        Text("右上のメニューから\nカテゴリーを追加してください")
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
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
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    if isDeleteMode {
                                        if selectedDeleteCategories.contains(category) {
                                            selectedDeleteCategories.remove(category)
                                        } else {
                                            selectedDeleteCategories.insert(category)
                                        }
                                    } else {
                                        selectedCategory = category
                                        dismiss()
                                    }
                                } label: {
                                    VStack(spacing: 10) {
                                        Image(systemName: category.imageName)
                                            .font(.system(size: 24))
                                            .foregroundStyle(
                                                isDeleteMode
                                                ? (selectedDeleteCategories.contains(category)
                                                   ? Color.black : Color.gray)
                                                : Color.black
                                            )
                                        
                                        Text(category.name)
                                            .font(.system(size: 14))
                                            .foregroundStyle(
                                                isDeleteMode
                                                ? (selectedDeleteCategories.contains(category)
                                                   ? Color.black : Color.gray)
                                                : Color.black
                                            )
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 100)
                                    .background(
                                        isDeleteMode
                                        ? (selectedDeleteCategories.contains(category)
                                           ? Color.red.opacity(0.05)
                                           : Color.white)
                                        : Color.white
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                isDeleteMode ? (selectedDeleteCategories.contains(category) ? Color.red : Color.gray) : Color.black, lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
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
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if !isDeleteMode {
                        Button("閉じる") {
                            if categories.isEmpty {
                                showNoCategoryAlert = true
                            } else {
                                dismiss()
                            }
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
            .alert("カテゴリーが1つ以上必要です", isPresented: $showNoCategoryAlert) {
                Button {
                    isShowingAddCategory = true
                } label: {
                    Text("追加する")
                }
            } message: {
                Text("追加画面が表示されます。")
            }
        }
    }
    
    private func deleteSelectedCategories() {
        // 選択中のカテゴリーが削除対象に含まれていたら、参照が消える前にリセットする
        if let currentSelected = selectedCategory,
           selectedDeleteCategories.contains(currentSelected) {
            selectedCategory = nil
        }
        
        // 📋 削除前の一覧
        print("========== 📋 削除前のカテゴリー一覧 ==========")
        for category in categories.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            print("📌 \(category.name) | sortIndex: \(category.sortIndex)")
        }
        
        // 🗑️ 削除しようとしているもの
        print("========== 🗑️ 削除対象 ==========")
        for category in selectedDeleteCategories {
            print("""
        🗑️ カテゴリー名: \(category.name)
        🆔 ID: \(category.id)
        🖼️ アイコン: \(category.imageName)
        🔢 sortIndex: \(category.sortIndex)
        """)
        }
        
        // 💥 削除
        for category in selectedDeleteCategories {
            print("💥 削除実行: \(category.name)")
            modelContext.delete(category)
        }
        
        // 📋 削除後に残るカテゴリー
        let remainingCategories = categories
            .filter { !selectedDeleteCategories.contains($0) }
            .sorted { $0.sortIndex < $1.sortIndex }
        
        // 🔢 sortIndexを詰め直す
        for (index, category) in remainingCategories.enumerated() {
            category.sortIndex = index
        }
        
        // ✅ 削除したものの詳細
        print("========== ✅ 削除したカテゴリー ==========")
        for category in selectedDeleteCategories {
            print("""
        ✅ カテゴリー名: \(category.name)
        🆔 ID: \(category.id)
        🖼️ アイコン: \(category.imageName)
        🔢 削除前sortIndex: \(category.sortIndex)
        """)
        }
        
        // 📋 削除後の一覧
        print("========== 📋 削除後のカテゴリー一覧 ==========")
        for category in remainingCategories {
            print("📌 \(category.name) | sortIndex: \(category.sortIndex)")
        }
        
        print("==============================================")
        
        selectedDeleteCategories.removeAll()
        isDeleteMode = false
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Category.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let context = container.mainContext
    
    context.insert(
        Category(
            name: "家賃",
            imageName: "house",
            sortIndex: 0
        )
    )
    
    context.insert(
        Category(
            name: "食費",
            imageName: "fork.knife",
            sortIndex: 1
        )
    )
    
    context.insert(
        Category(
            name: "日用品",
            imageName: "basket",
            sortIndex: 2
        )
    )
    
    context.insert(
        Category(
            name: "交通費",
            imageName: "car",
            sortIndex: 3
        )
    )
    
    context.insert(
        Category(
            name: "医療費",
            imageName: "cross.case",
            sortIndex: 4
        )
    )
    
    return CategorySelectionView(
        selectedCategory: .constant(
            Category(
                name: "家賃",
                imageName: "house",
                sortIndex: 0
            )
        )
    )
    .modelContainer(container)
}
