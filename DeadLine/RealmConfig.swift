//
//  RealmConfig.swift
//  DeadLine
//
//  Created by kota on 2025/05/25.
//

import RealmSwift
import Foundation

func configureRealm() {
    var config = Realm.Configuration(
        schemaVersion: 2,
        migrationBlock: { _, _ in })

    if let url = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.deadline.shared")?
        .appendingPathComponent("db.realm") {
        config.fileURL = url
    }

    Realm.Configuration.defaultConfiguration = config
}
