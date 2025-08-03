//
//  FamilyControl.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/03.
//

import Dependencies
import FamilyControls
import Foundation
import ManagedSettings

struct FamilyControl: Sendable {
  var status: @Sendable () async -> AuthorizationStatus
  var request: @Sendable (_ member: FamilyControlsMember) async throws -> Void
}

extension FamilyControl: DependencyKey {
  static let liveValue = FamilyControl(
    status: {
      _ = AuthorizationCenter.shared.authorizationStatus
      try? await Task.sleep(for: .seconds(0.1))
      let result = AuthorizationCenter.shared.authorizationStatus
      return result
    },
    request: { member in
      try await AuthorizationCenter.shared.requestAuthorization(for: member)
    }
  )
}

extension FamilyControl: TestDependencyKey {
  static let testValue = FamilyControl(
    status: { .approved },
    request: { _ in }
  )
}

extension DependencyValues {
  var familyControl: FamilyControl {
    get { self[FamilyControl.self] }
    set { self[FamilyControl.self] = newValue }
  }
}
