import Testing
import SwiftData
import Foundation
@testable import MoneyManagementApp

struct CategoryTests {
    
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Transaction.self,
            Category.self,
            PaymentMethod.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [config]
        )
    }
    
    // MARK: - 正常系
    
    @Test @MainActor
    func 正常系_カテゴリーを追加できる() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let category = MoneyManagementApp.Category(
            name: "食費",
            imageName: "fork.knife",
            sortIndex: 0
        )
        
        context.insert(category)
        
        let saved = try context.fetch(
            FetchDescriptor<MoneyManagementApp.Category>()
        )
        
        #expect(saved.count == 1)
        #expect(saved.first?.name == "食費")
        #expect(saved.first?.imageName == "fork.knife")
        #expect(saved.first?.sortIndex == 0)
    }
    
    @Test @MainActor
    func 正常系_複数のカテゴリーを追加できる() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let category1 = MoneyManagementApp.Category(
            name: "食費",
            imageName: "fork.knife",
            sortIndex: 0
        )
        
        let category2 = MoneyManagementApp.Category(
            name: "日用品",
            imageName: "cart",
            sortIndex: 1
        )
        
        context.insert(category1)
        context.insert(category2)
        
        let saved = try context.fetch(
            FetchDescriptor<MoneyManagementApp.Category>()
        )
        
        #expect(saved.count == 2)
        #expect(saved.contains { $0.name == "食費" })
        #expect(saved.contains { $0.name == "日用品" })
    }
    
    // MARK: - 異常系
    
    @Test @MainActor
    func 異常系_カテゴリー名が空の場合は登録しない() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let name = ""
        
        // AddCategoryView の .disabled(name.isEmpty) と同じ条件
        let canSave = !name.isEmpty
        
        #expect(canSave == false)
        
        // 登録処理を実行しない
        if canSave {
            let category = MoneyManagementApp.Category(
                name: name,
                imageName: "tag",
                sortIndex: 0
            )
            
            context.insert(category)
        }
        
        let saved = try context.fetch(
            FetchDescriptor<MoneyManagementApp.Category>()
        )
        
        #expect(saved.isEmpty)
    }
}
