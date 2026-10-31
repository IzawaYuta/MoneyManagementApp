
import Foundation
import SwiftData

// ============================================================
// V1: 最初のリリースのデータモデル
// models には、既存のモデルファイルのクラスをそのまま指定する。
// ============================================================
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Category.self, PaymentMethod.self, Transaction.self]
    }
}

// ============================================================
// マイグレーションプラン
// バージョンが1つだけなので、移行ステージは無し。
// ============================================================
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
}
