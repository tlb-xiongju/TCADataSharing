//
//  Introduce.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/01.
//

import ComposableArchitecture
import Dependencies
import SwiftUI
import Sharing

import SharingGRDBCore
import SharingGRDB

@Reducer
struct Introduce {
  @ObservableState
  struct State: Equatable {
    @Shared(.appStorage("isIntroduced")) var isIntroduced = false
    @Shared(.inMemory("noteValue")) var noteValue = ""
    @Shared(.fileStorage(.documentsDirectory.appending(component: "notes.json"))) var notes: [Note] = []
    
    @SharedReader(.api(nil)) var numberDescription: String?
    @Shared(.appStorage("count")) var count = 0
    
    @SharedReader(.fetch(Items())) var items
    
    @Presents var confirmation: Confirmation.State?
  }
  
  @Dependency(\.defaultDatabase) var database
  
  enum Action: Sendable {
    case onAppear
    case goForward
    
    case setIsIntroduced(Bool)
    case setNoteValue(String)
    
    case setCount(Int)
    
    case confirmButtonTapped
    case confirmation(PresentationAction<Confirmation.Action>)
    
    case addBook
    case addAuthor
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
        
      case let .setIsIntroduced(flg):
        state.$isIntroduced.withLock { $0 = flg }
        return .none
        
      case let .setNoteValue(value):
        state.$noteValue.withLock { $0 = value }
        return .none
        
      case .confirmButtonTapped:
        state.confirmation = .init()
        return .none
        
      case .addBook:
        let bookid = (Int.random(in: 1...999))
        try? database.write({ db in
          try? Book.insert {
            Book(
              id: "\(bookid)",
              title: "Book \(bookid)",
              authorID: "\(Int.random(in: 1...3))"
            )
          }
          .execute(db)
        })
        return .none
        
      case .addAuthor:
        let id = (Int.random(in: 1...3))
        try? database.write { db in
          try? Author.insert {
            Author(id: "\(id)", name: "Name \(id)")
          }
          .execute(db)
        }
        return .none
        
      case let .setCount(number):
        state.$count.withLock { $0 = number }
        state.$numberDescription = SharedReader(.api(number))
        return .none
        
      case .confirmation(.presented(.saveNote)):
        state.confirmation = nil
        return .none
        
      default:
        return .none
      }
    }
    .ifLet(\.$confirmation, action: \.confirmation) { Confirmation() }
  }
}

struct IntroduceView: View {
  @Bindable var store: StoreOf<Introduce>
  
  var body: some View {
    NavigationStack {
      VStack {
        List {
          Section("In Memory") {
            TextField("Note value", text: $store.noteValue.sending(\.setNoteValue))
              .deleteDisabled(store.noteValue.isEmpty)
          }
          
          Section("API") {
            Stepper("\(store.count)", value: $store.count.sending(\.setCount))
            if store.$numberDescription.isLoading {
              ProgressView()
            }
            store.$numberDescription.loadError.map {
              Text($0.localizedDescription)
            }
            store.numberDescription.map { Text($0) }
          }
          
          Section("AppStorage") {
            Toggle("isIntroduced", isOn: $store.isIntroduced.sending(\.setIsIntroduced))
          }
          
          Section("FileStorage") {
            ForEach(store.notes.sorted(by: { $0.date > $1.date })) { NoteCell(note: $0) }
          }
          
          Section("SharingGRDB") {
            ForEach(store.items) { item in
              VStack(alignment: .leading) {
                Text("Author: \(item.author.name)").font(.body).foregroundStyle(.primary)
                Text("Books: \(item.books.map(\.title).joined(separator: ", "))").font(.footnote).foregroundStyle(.secondary)
              }
            }
          }
        }
        
        HStack {
          Button("Confirm") { store.send(.confirmButtonTapped) }
            .buttonStyle(.bordered)
          
          Spacer()
          
          Button("+ Book") { store.send(.addBook) }
            .buttonStyle(.bordered)
          Button("+ Author") { store.send(.addAuthor) }
            .buttonStyle(.bordered)
        }
      }
      .navigationTitle("Sharing")
      .navigationBarTitleDisplayMode(.inline)
    }
    .sheet(item: $store.scope(state: \.confirmation, action: \.confirmation)) { store in
      ConfirmationView(store: store)
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }
  }
}

struct NoteCell: View {
  let note: Note
  var body: some View {
    VStack(alignment: .leading) {
      Text(note.value).font(.body).foregroundStyle(.primary)
      Text(note.date.description).font(.footnote).foregroundStyle(.secondary)
    }
  }
}

