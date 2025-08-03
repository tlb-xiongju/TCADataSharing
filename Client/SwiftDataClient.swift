//
//  SwiftDataClient.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/03.
//

import Foundation
import SwiftData
import Dependencies
@preconcurrency import ManagedSettings

@Model
final class LockModel: Identifiable, Sendable {
  @Attribute(.unique)
  var id: UUID
  var token: ApplicationToken
  
  init(id: UUID, token: ApplicationToken) {
    self.id = id
    self.token = token
  }
}

extension LockModel {
  func toItem() -> LockItem { .init(id: id, token: token) }
}

struct LockItem: Equatable, Identifiable, Sendable {
  let id: UUID
  let token: ApplicationToken
}

@ModelActor
actor SwiftDataClient {
  func add(_ item: LockItem) throws {
    let model = LockModel(id: item.id, token: item.token)
    modelContext.insert(model)
    try save()
  }
  
  func add(_ items: [LockItem]) throws {
    for item in items {
      let model = LockModel(id: item.id, token: item.token)
      modelContext.insert(model)
    }
    try save()
  }
  
  func delete(_ item: LockItem) throws {
    let modelID = item.id
    let descriptor = FetchDescriptor<LockModel>(
      predicate: #Predicate { $0.id == modelID },
      sortBy: []
    )
    guard let model = try modelContext.fetch(descriptor).first else { return }
    modelContext.delete(model)
    try save()
  }
  
  func update(_ item: LockItem, modifier: (LockModel) -> Void) throws {
    let modelID = item.id
    let descriptor = FetchDescriptor<LockModel>(
      predicate: #Predicate { $0.id == modelID },
      sortBy: []
    )
    guard let model = try modelContext.fetch(descriptor).first else { return }
    modifier(model)
    try save()
  }
  
  func items() throws -> [LockItem] {
    let descriptor = FetchDescriptor<LockModel>(sortBy: [])
    let models = try modelContext.fetch(descriptor)
    return models.map { $0.toItem() }
  }
  
  func clear() throws {
    let descriptor = FetchDescriptor<LockModel>(sortBy: [])
    let models = try modelContext.fetch(descriptor)
    for model in models {
      modelContext.delete(model)
    }
    try save()
  }
  
  private func save() throws {
    if modelContext.hasChanges {
      try modelContext.save()
    }
  }
}

// MARK: -

extension SwiftDataClient: DependencyKey {
  static let liveValue = SwiftDataClient(modelContainer: try! ModelContainer(for: LockModel.self))
}

extension DependencyValues {
  var swiftDataClient: SwiftDataClient {
    get { self[SwiftDataClient.self] }
    set { self[SwiftDataClient.self] = newValue }
  }
}
