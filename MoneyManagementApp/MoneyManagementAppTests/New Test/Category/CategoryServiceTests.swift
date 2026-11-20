import Testing
import Foundation
import SwiftData

typealias Category = SchemaV1.Category
@testable import MoneyManagementApp  // ← Product Module Name に合わせる

@MainActor
struct CategoryServiceTests {
    
    // MARK: - Helper
    
    private func makeContext() throws -> ModelContext {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }
    
    private func fetchAll(_ context: ModelContext) throws -> [Category] {
        try context.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortIndex)]))
    }
    
    /// 指定した名前のカテゴリーを sortIndex 0,1,2... で作る
    @discardableResult
    private func seed(_ names: [String], in context: ModelContext) throws -> [Category] {
        try names.map {
            try CategoryService.add(name: $0, imageName: "tray", colorHex: "#4DABF7", in: context)
        }
    }
    
    // MARK: - 保存条件
    
    @Test("名前・アイコン・色がそろっていれば保存できる")
    func validWhenAllFilled() {
        #expect(CategoryService.isValid(name: "食費", imageName: "fork.knife", colorHex: "#FF6B6B"))
    }
    
    @Test("名前が空、または空白のみだと保存できない")
    func invalidWhenNameBlank() {
        #expect(!CategoryService.isValid(name: "", imageName: "fork.knife", colorHex: "#FF6B6B"))
        #expect(!CategoryService.isValid(name: "   ", imageName: "fork.knife", colorHex: "#FF6B6B"))
    }
    
    @Test("アイコン未選択だと保存できない")
    func invalidWhenNoIcon() {
        #expect(!CategoryService.isValid(name: "食費", imageName: nil, colorHex: "#FF6B6B"))
    }
    
    @Test("色未選択だと保存できない")
    func invalidWhenNoColor() {
        #expect(!CategoryService.isValid(name: "食費", imageName: "fork.knife", colorHex: nil))
    }
    
    // MARK: - 追加
    
    @Test("追加したカテゴリーに入力内容が保存される")
    func addStoresValues() throws {
        let context = try makeContext()
        
        try CategoryService.add(name: "食費", imageName: "fork.knife", colorHex: "#FF6B6B", in: context)
        
        let saved = try #require(try fetchAll(context).first)
        #expect(saved.name == "食費")
        #expect(saved.imageName == "fork.knife")
        #expect(saved.colorHex == "#FF6B6B")
    }
    
    @Test("最初のカテゴリーのsortIndexは0")
    func firstSortIndexIsZero() throws {
        let context = try makeContext()
        
        let first = try CategoryService.add(name: "食費", imageName: "fork.knife", colorHex: "#FF6B6B", in: context)
        
        #expect(first.sortIndex == 0)
    }
    
    @Test("追加するたびにsortIndexが末尾に増えていく")
    func sortIndexIncrements() throws {
        let context = try makeContext()
        
        let items = try seed(["A", "B", "C"], in: context)
        
        #expect(items.map(\.sortIndex) == [0, 1, 2])
    }
    
    @Test("sortIndexが飛んでいても、最大値+1で追加される")
    func addAfterGap() throws {
        let context = try makeContext()
        context.insert(Category(name: "A", imageName: "tray", colorHex: "#4DABF7", sortIndex: 0))
        context.insert(Category(name: "B", imageName: "tray", colorHex: "#4DABF7", sortIndex: 5))
        
        let added = try CategoryService.add(name: "C", imageName: "tray", colorHex: "#4DABF7", in: context)
        
        #expect(added.sortIndex == 6)
    }
    
    @Test("追加したカテゴリーのIDは一意")
    func addedIDsAreUnique() throws {
        let context = try makeContext()
        
        let items = try seed(["A", "B"], in: context)
        
        #expect(items[0].id != items[1].id)
    }
    
    // MARK: - 編集
    
    @Test("編集すると名前・アイコン・色が更新される")
    func updateChangesValues() throws {
        let context = try makeContext()
        let category = try CategoryService.add(name: "食費", imageName: "fork.knife", colorHex: "#FF6B6B", in: context)
        
        CategoryService.update(category, name: "外食", imageName: "mug", colorHex: "#4DABF7")
        
        let saved = try #require(try fetchAll(context).first)
        #expect(saved.name == "外食")
        #expect(saved.imageName == "mug")
        #expect(saved.colorHex == "#4DABF7")
    }
    
    @Test("編集してもIDとsortIndexは変わらない")
    func updateKeepsIDAndSortIndex() throws {
        let context = try makeContext()
        let items = try seed(["A", "B", "C"], in: context)
        let target = items[1]
        let originalID = target.id
        
        CategoryService.update(target, name: "B2", imageName: "mug", colorHex: "#FF6B6B")
        
        #expect(target.id == originalID)
        #expect(target.sortIndex == 1)
    }
    
    // MARK: - 削除
    
    @Test("1件削除すると、残りのsortIndexが詰まり順序は保たれる")
    func deleteOneReindexes() throws {
        let context = try makeContext()
        let items = try seed(["A", "B", "C", "D"], in: context)
        
        try CategoryService.delete(ids: [items[1].id], in: context)
        
        let remaining = try fetchAll(context)
        #expect(remaining.map(\.name) == ["A", "C", "D"])
        #expect(remaining.map(\.sortIndex) == [0, 1, 2])
    }
    
    @Test("複数件をまとめて削除できる")
    func deleteMultiple() throws {
        let context = try makeContext()
        let items = try seed(["A", "B", "C", "D", "E"], in: context)
        
        try CategoryService.delete(ids: [items[0].id, items[2].id, items[4].id], in: context)
        
        let remaining = try fetchAll(context)
        #expect(remaining.map(\.name) == ["B", "D"])
        #expect(remaining.map(\.sortIndex) == [0, 1])
    }
    
    @Test("sortIndexが飛んでいても、削除後は0から詰め直される")
    func deleteReindexesFromGaps() throws {
        let context = try makeContext()
        context.insert(Category(name: "A", imageName: "tray", colorHex: "#4DABF7", sortIndex: 0))
        let b = Category(name: "B", imageName: "tray", colorHex: "#4DABF7", sortIndex: 5)
        context.insert(b)
        context.insert(Category(name: "C", imageName: "tray", colorHex: "#4DABF7", sortIndex: 9))
        
        try CategoryService.delete(ids: [b.id], in: context)
        
        let remaining = try fetchAll(context)
        #expect(remaining.map(\.name) == ["A", "C"])
        #expect(remaining.map(\.sortIndex) == [0, 1])
    }
    
    @Test("全件削除して0件になっても削除できる")
    func deleteAll() throws {
        let context = try makeContext()
        let items = try seed(["A", "B"], in: context)
        
        try CategoryService.delete(ids: Set(items.map(\.id)), in: context)
        
        #expect(try fetchAll(context).isEmpty)
    }
    
    @Test("削除対象が空なら何も変わらない")
    func deleteNothing() throws {
        let context = try makeContext()
        try seed(["A", "B"], in: context)
        
        try CategoryService.delete(ids: [], in: context)
        
        let remaining = try fetchAll(context)
        #expect(remaining.map(\.name) == ["A", "B"])
        #expect(remaining.map(\.sortIndex) == [0, 1])
    }
    
    @Test("存在しないIDを指定しても、他のカテゴリーに影響しない")
    func deleteUnknownID() throws {
        let context = try makeContext()
        try seed(["A", "B"], in: context)
        
        try CategoryService.delete(ids: [UUID()], in: context)
        
        #expect(try fetchAll(context).count == 2)
    }
    
    @Test("削除後に追加すると、詰め直したsortIndexの末尾に入る")
    func addAfterDelete() throws {
        let context = try makeContext()
        let items = try seed(["A", "B", "C"], in: context)
        try CategoryService.delete(ids: [items[0].id], in: context)
        
        let added = try CategoryService.add(name: "D", imageName: "tray", colorHex: "#4DABF7", in: context)
        
        #expect(added.sortIndex == 2)
    }
    
    @Test("カテゴリーを削除しても、過去の収支記録のカテゴリー情報は残る")
    func deleteKeepsTransactionSnapshot() throws {
        let context = try makeContext()
        let category = try CategoryService.add(name: "食費", imageName: "fork.knife", colorHex: "#FF6B6B", in: context)
        let transaction = SchemaV2.Transaction(
            amount: 800,
            categoryID: category.id,
            categoryName: category.name,
            categoryImageName: category.imageName,
            categoryColorHex: category.colorHex
        )
        context.insert(transaction)
        
        try CategoryService.delete(ids: [category.id], in: context)
        
        let saved = try #require(try context.fetch(FetchDescriptor<SchemaV2.Transaction>()).first)
        #expect(saved.categoryName == "食費")
        #expect(saved.categoryImageName == "fork.knife")
        #expect(saved.categoryColorHex == "#FF6B6B")
    }
}
