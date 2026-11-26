
import Foundation
import SwiftData

// ============================================================
// マイグレーションプラン
// バージョンが1つだけなので、移行ステージは無し。
// ============================================================
typealias Category = SchemaV1.Category          // V2で未変更なのでV1を参照
typealias PaymentMethod = SchemaV1.PaymentMethod
typealias Transaction = SchemaV2.Transaction
typealias Budget = SchemaV2.Budget
typealias UsualRecord = SchemaV2.UsualRecord
typealias FixedCost = SchemaV2.FixedCost

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)]
    }
}
