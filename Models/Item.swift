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
struct Book: Equatable, Identifiable {
  let id: String
  let title: String
  let authorID: String
}

@Table
struct Author: Equatable, Identifiable {
  let id: String
  var name: String
}

struct Item: Equatable, Identifiable {
  var id: String { author.id }
  let author: Author
  let books: [Book]
}

struct Items: FetchKeyRequest {
  func fetch(_ db: Database) throws -> [Item] {
    let authors = try Author.all.fetchAll(db)
    let books = try Book.all.fetchAll(db)
    let grouped = Dictionary(grouping: books, by: \.authorID)
    return authors.map { author in
      Item(author: author, books: grouped[author.id] ?? [])
    }
  }
}
