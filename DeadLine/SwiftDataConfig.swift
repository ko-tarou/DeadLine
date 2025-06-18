//
//  SwiftDataConfig.swift
//  DeadLine
//
//  Created by kota on 2025/05/25.
//

import SwiftData
import Foundation

// MARK: - SwiftData Configuration

struct SwiftDataConfig {
    
    // App Groups の識別子
    static let appGroupIdentifier = "group.deadline.app.shared"
    
    // 共有データベースファイル名
    static let databaseFileName = "DeadlineDatabase.sqlite"
    
    // MARK: - Model Container Creation
    
    /// 共有 ModelContainer を作成（型を直接参照しない方法）
    static func createSharedModelContainer<T: PersistentModel>(_ modelType: T.Type) -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: modelType,
                configurations: ModelConfiguration(
                    url: sharedDatabaseURL,
                    cloudKitDatabase: .none
                )
            )
            
            print("✅ SwiftData shared container created successfully")
            print("📍 Database location: \(sharedDatabaseURL.path)")
            
            return container
        } catch {
            print("❌ Failed to create shared ModelContainer: \(error)")
            return createFallbackContainer(modelType)
        }
    }
    
    /// 標準的な ModelContainer を作成
    static func createStandardModelContainer<T: PersistentModel>(_ modelType: T.Type) -> ModelContainer {
        do {
            let container = try ModelContainer(for: modelType)
            print("✅ SwiftData standard container created successfully")
            return container
        } catch {
            print("❌ Failed to create standard ModelContainer: \(error)")
            fatalError("Failed to create standard ModelContainer: \(error)")
        }
    }
    
    /// フォールバック用のインメモリ ModelContainer を作成
    private static func createFallbackContainer<T: PersistentModel>(_ modelType: T.Type) -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: modelType,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            print("⚠️ Using fallback in-memory container")
            return container
        } catch {
            print("❌ Failed to create fallback ModelContainer: \(error)")
            fatalError("Failed to create fallback ModelContainer: \(error)")
        }
    }
    
    // MARK: - Shared Database URL
    
    /// 共有データベースの URL を取得
    static var sharedDatabaseURL: URL {
        guard let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            print("⚠️ App Group container not found, using standard location")
            return standardDatabaseURL
        }
        
        let databaseURL = appGroupURL.appendingPathComponent(databaseFileName)
        
        // ディレクトリが存在しない場合は作成
        do {
            try FileManager.default.createDirectory(
                at: appGroupURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("⚠️ Failed to create directory: \(error)")
        }
        
        return databaseURL
    }
    
    /// 標準データベースの URL を取得
    static var standardDatabaseURL: URL {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Could not find documents directory")
        }
        return documentsPath.appendingPathComponent(databaseFileName)
    }
    
    // MARK: - Debug Utilities
    
    /// データベースの情報を出力
    static func printDatabaseInfo() {
        print("=== SwiftData Configuration ===")
        print("App Group ID: \(appGroupIdentifier)")
        print("Database File: \(databaseFileName)")
        print("Shared DB URL: \(sharedDatabaseURL.path)")
        print("Standard DB URL: \(standardDatabaseURL.path)")
        print("==============================")
    }
}
