
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
            .alert("カテゴリーが必要です", isPresented: $showNoCategoryAlert) {
                Button {
                    isShowingAddCategory = true
                } label: {
                    Text("追加")
                }
            } message: {
                Text("カテゴリーを1つ以上追加してください。")
            }
        }
    }
    
    private func deleteSelectedCategories() {
        for category in selectedDeleteCategories {
            modelContext.delete(category)
        }
        
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
