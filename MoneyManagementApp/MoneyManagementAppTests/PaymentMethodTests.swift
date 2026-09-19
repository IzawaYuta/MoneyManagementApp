import Testing
import SwiftData
import Foundation
@testable import MoneyManagementApp

struct PaymentMethodTests {
    
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
    func 正常系_支払方法を追加できる() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let paymentMethod = PaymentMethod(
            name: "現金",
            type: .cash,
            sortIndex: 0
        )
        
        context.insert(paymentMethod)
        
        let saved = try context.fetch(
            FetchDescriptor<PaymentMethod>()
        )
        
        #expect(saved.count == 1)
        #expect(saved.first?.name == "現金")
        #expect(saved.first?.type == .cash)
        #expect(saved.first?.sortIndex == 0)
        #expect(saved.first?.memo == nil)
    }
    
    @Test @MainActor
    func 正常系_支払方法にメモを設定して追加できる() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let paymentMethod = PaymentMethod(
            name: "クレジットカード",
            type: .creditCard,
            memo: "メインカード",
            sortIndex: 0
        )
        
        context.insert(paymentMethod)
        
        let saved = try context.fetch(
            FetchDescriptor<PaymentMethod>()
        )
        
        #expect(saved.count == 1)
        #expect(saved.first?.name == "クレジットカード")
        #expect(saved.first?.type == .creditCard)
        #expect(saved.first?.memo == "メインカード")
    }
    
    @Test @MainActor
    func 正常系_複数の支払方法を追加できる() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let paymentMethod1 = PaymentMethod(
            name: "現金",
            type: .cash,
            sortIndex: 0
        )
        
        let paymentMethod2 = PaymentMethod(
            name: "クレジットカード",
            type: .creditCard,
            sortIndex: 1
        )
        
        context.insert(paymentMethod1)
        context.insert(paymentMethod2)
        
        let saved = try context.fetch(
            FetchDescriptor<PaymentMethod>()
        )
        
        #expect(saved.count == 2)
        #expect(saved.contains { $0.name == "現金" })
        #expect(saved.contains { $0.name == "クレジットカード" })
    }
    
    // MARK: - 異常系
    
    @Test @MainActor
    func 異常系_支払方法名が空の場合は登録しない() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let name = ""
        
        // AddPaymentMethodView の .disabled(name.isEmpty) と同じ条件
        let canSave = !name.isEmpty
        
        #expect(canSave == false)
        
        // 登録処理を実行しない
        if canSave {
            let paymentMethod = PaymentMethod(
                name: name,
                type: .cash,
                sortIndex: 0
            )
            
            context.insert(paymentMethod)
        }
        
        let saved = try context.fetch(
            FetchDescriptor<PaymentMethod>()
        )
        
        #expect(saved.isEmpty)
    }
}
