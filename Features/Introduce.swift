//
//  Introduce.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/01.
//

import ComposableArchitecture
import Dependencies
import FamilyControls
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
    
    @SharedReader(.lockItem()) var lockItems: [LockItem] = []
    
    @Presents var confirmation: Confirmation.State?
    
    var appPickerFlag = false
    var selection = FamilyActivitySelection(includeEntireCategory: false)
  }
  
  @Dependency(\.defaultDatabase) var database
  @Dependency(\.swiftDataClient) var swiftDataClient
  @Dependency(\.familyControl) var familyControl
  
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
    case onDelete(IndexSet)
    
    case showAppPicker(Bool)
    case setSelection(FamilyActivitySelection)
    case clearSwiftData
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          switch await familyControl.status() {
          case .approved: break
          case .notDetermined, .denied:
            do {
              try await familyControl.request(.individual)
            } catch {
              return
            }
          @unknown default:
            break
          }
        }
        
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
        
      case let .onDelete(idxSet):
        let items = idxSet.map { state.items[$0] }
        try? database.write { db in
          for item in items {
            try? Author.delete(item.author).execute(db)
          }
        }
        return .none
        
      case let .setCount(number):
        state.$count.withLock { $0 = number }
        state.$numberDescription = SharedReader(.api(number))
        return .none
        
      case .confirmation(.presented(.saveNote)):
        state.confirmation = nil
        return .none
        
      case let .showAppPicker(flg):
        state.appPickerFlag = flg
        return .none
        
      case let .setSelection(selection):
        guard state.selection != selection else { return .none }
        print("setSelection: \(selection.applicationTokens)")
        state.selection = selection
        let items = selection.applicationTokens.compactMap { token -> LockItem? in
          if state.lockItems.map(\.token).contains(token) { return nil }
          return LockItem(id: .init(), token: token)
        }
        
        return .run { [items] send in
          do {
            try await swiftDataClient.add(items)
          } catch {
            print("setSelection error: \(error)")
          }
        }
        
      case .clearSwiftData:
        return .run { send in
          try? await swiftDataClient.clear()
        }
        
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
            .onDelete(perform: { store.send(.onDelete($0)) })
          }
          
          Section("SwiftData") {
            ForEach(store.lockItems) {
              Label($0.token).labelStyle(.titleAndIcon)
            }
          }
        }
        
        VStack {
          HStack {
            Button("Select App") { store.send(.showAppPicker(true)) }
              .familyActivityPicker(
                isPresented: $store.appPickerFlag.sending(\.showAppPicker),
                selection: $store.selection.sending(\.setSelection)
              )
            Button("Clear") { store.send(.clearSwiftData) }
          }
          
          HStack {
            Button("Confirm") { store.send(.confirmButtonTapped) }
              .buttonStyle(.bordered)
            
            Spacer()
            
            Button("+ Book") { store.send(.addBook) }
              .buttonStyle(.bordered)
            Divider().frame(height: 12)
            Button("+ Author") { store.send(.addAuthor) }
              .buttonStyle(.bordered)
          }
        }
        .padding(.horizontal)
      }
      .navigationTitle("Sharing")
      .navigationBarTitleDisplayMode(.inline)
    }
    .onAppear(perform: { store.send(.onAppear) })
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

