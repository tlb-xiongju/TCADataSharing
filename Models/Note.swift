//
//  Note.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/01.
//

import Foundation

struct Note: Codable, Identifiable, Equatable {
  let id: UUID
  let value: String
  let date: Date
}
