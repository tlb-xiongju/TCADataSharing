//
//  Item.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/02.
//

import Foundation
import SharingGRDBCore
import SharingGRDB

@Table
struct Item: Equatable, Identifiable {
  let id: Int
  var title = ""
  var notes = ""
}

struct Items: FetchKeyRequest {
  func fetch(_ db: Database) throws -> [Item] {
    try Item.all.fetchAll(db)
  }
}
