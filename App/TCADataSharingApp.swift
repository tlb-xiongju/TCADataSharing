//
//  TCADataSharingApp.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/01.
//

import ComposableArchitecture
import Dependencies
import SwiftUI
import SharingGRDB

@main
struct TCADataSharingApp: App {
  static let store = Store(initialState: Introduce.State()) {
    Introduce()
      ._printChanges()
  }
  
  init() {
    prepareDependencies {
      $0.defaultDatabase = try! appDatabase()
    }
  }
  
  var body: some Scene {
    WindowGroup {
      IntroduceView(store: Self.store)
    }
  }
}

func appDatabase() throws -> any DatabaseWriter {
  var configuration = Configuration()
  configuration.foreignKeysEnabled = true
  
  let path = URL.documentsDirectory.appending(component: "db.sqlite").path()
  let database = try DatabasePool(path: path, configuration: configuration)
  
  var migrator = DatabaseMigrator()
  migrator.registerMigration("create Book table") { db in
    try db.create(table: "authors") { table in
      table.column("id", .text).primaryKey()
      table.column("name", .text)
    }
    try db.create(table: "books") { table in
      table.column("id", .text).primaryKey()
      table.column("title", .text)
      table.column("authorID", .text)
        .references("authors", onDelete: .cascade)
    }
  }
  try migrator.migrate(database)
  
  return database
}
