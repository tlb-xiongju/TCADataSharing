//
//  Confirmation.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/01.
//

import ComposableArchitecture
import Dependencies
import SwiftUI
import Sharing

@Reducer
struct Confirmation {
  @ObservableState
  struct State: Equatable {
    @Shared(.inMemory("noteValue")) var noteValue = ""
    
    @Shared(.fileStorage(.documentsDirectory.appending(component: "notes.json")))
    var notes: [Note] = []
  }
  
  enum Action: Sendable {
    case onAppear
    case setNoteValue(String)
    
    case saveNote(String)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .setNoteValue(value):
        state.$noteValue.withLock { $0 = value }
        return .none
        
      case let .saveNote(value):
        state.$notes.withLock {
          $0.append(Note(id: .init(), value: value, date: .now))
        }
        return .none
        
      default:
        return .none
      }
    }
  }
}

struct ConfirmationView: View {
  @Bindable var store: StoreOf<Confirmation>
  
  var body: some View {
    NavigationStack {
      List {
        Section {
          TextField("Note value", text: $store.noteValue.sending(\.setNoteValue))
        }
      }
      .navigationTitle("Confirmation")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") {
            store.send(.saveNote(store.noteValue))
          }
        }
      }
    }
  }
}


