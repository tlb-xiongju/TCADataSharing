//
//  SwiftDataKey.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/01.
//

import Combine
import Foundation
import Sharing
import SwiftData

final class LockItemKey {
  let id = UUID()
  
  private let client: SwiftDataClient
  
  init(client: SwiftDataClient) {
    self.client = client
  }
  
  convenience init() {
    self.init(client: .init(modelContainer: try! ModelContainer(for: LockModel.self)))
  }
}

extension LockItemKey: SharedReaderKey {
  func load(context: LoadContext<[LockItem]>, continuation: LoadContinuation<[LockItem]>) {
    Task {
      await continuation.resume(with: Result { try await client.items() } )
    }
  }
  
  func subscribe(context: LoadContext<[LockItem]>, subscriber: SharedSubscriber<[LockItem]>) -> SharedSubscription {
    let contextDidSave = NotificationCenter.default.addObserver(
      forName: ModelContext.didSave,
      object: nil,
      queue: nil) { [unowned self] _ in
        Task {
          await subscriber.yield(with: Result { try await client.items() })
        }
      }
    return .init {
      NotificationCenter.default.removeObserver(contextDidSave)
    }
  }
}

extension SharedReaderKey {
  static func lockItem() -> Self where Self == LockItemKey {
    return LockItemKey()
  }
}
