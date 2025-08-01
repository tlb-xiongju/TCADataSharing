//
//  APIClientKey.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/01.
//

import Foundation
import Sharing
import Synchronization

final class APIClientKey {
  let id = UUID()
  let number: Int?
  let loadTask = Mutex<Task<Void, Never>?>(nil)
  
  init(number: Int?) {
    self.number = number
  }
}

extension APIClientKey: SharedReaderKey {
  func load(context: LoadContext<String?>, continuation: LoadContinuation<String?>) {
    guard let number else {
      continuation.resume(returning: nil)
      return
    }
    
    loadTask.withLock { task in
      task?.cancel()
      task = Task {
        do {
          let (data, _) = try await URLSession.shared.data(from: .init(string: "http://numbersapi.com/\(number)")!)
          continuation.resume(returning: String(decoding: data, as: UTF8.self))
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  func subscribe(context: LoadContext<String?>, subscriber: SharedSubscriber<String?>) -> SharedSubscription {
    .init {}
  }
}

extension SharedReaderKey where Self == APIClientKey {
  static func api(_ number: Int?) -> Self {
    Self(number: number)
  }
}
