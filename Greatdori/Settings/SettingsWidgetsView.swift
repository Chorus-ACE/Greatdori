//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsWidgetsView.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import Combine
import DoriKit
import MarkdownUI
import SwiftUI
import WidgetKit
@_spi(Advanced) import SwiftUIIntrospect

struct SettingsWidgetsView: View {
    @State var allCollections = CardCollectionManager.shared.allCollections
    var body: some View {
#if os(iOS)
        Section("Settings.widgets") {
            NavigationLink(destination: {
                List {
                    SettingsWidgetsCollectionView()
                }
                .navigationTitle("Settings.widgets.collections")
            }, label: {
                HStack {
                    Text("Settings.widgets.collections")
                    Spacer()
                    if !allCollections.isEmpty {
                        Text("\(allCollections.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            })
        }
        .onAppear {
            // Refresh every time the view appears.
            allCollections = CardCollectionManager.shared.allCollections
        }
#else
        SettingsWidgetsCollectionView()
            .navigationTitle("Settings.widgets")
#endif
    }
}


struct SettingsWidgetsCollectionView: View {
    @AppStorage("hideCollectionNameWhileSharing") var hideCollectionNameWhileSharing = false
    @StateObject var collectionManager = CardCollectionManager.shared
    @State var destinationCollection: CardCollectionManager.Collection? = nil
    @State var showDestination = false
    @State var newCollectionSheetIsDisplaying = false // macOS only
    @State var newCollectionInput = ""
    @State var newCollectionIsImporting = false
    #if os(iOS)
    @State var currentViewController: UIViewController!
    @State private var cardPreload: PreloadDescriptor<[PreviewCard]>?
    #endif
    @State var aboutCollectionCode: String = ""
    var body: some View {
        Group {
            Section(content: {
                if !collectionManager.userCollections.isEmpty {
                    ForEach(collectionManager.userCollections, id: \.self) { item in
                        Button(action: {
                            destinationCollection = item
                            showDestination = true
                        }, label: {
                            HStack {
                                Text(item.name)
                                Spacer()
                                if item.cards.count > 0 {
                                    Text("\(item.cards.count)")
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.forward")
                                    .foregroundStyle(.tertiary)
                                    .font(.footnote)
                                    .bold()
                            }
                            .contentShape(Rectangle())
                        })
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive, action: {
                                collectionManager.remove(at: collectionManager.userCollections.firstIndex{ $0.name == item.name }!)
                            }, label: {
                                Label("Settings.widgets.collections.user.delete", systemImage: "trash")
                            })
                            if let duplicationName = collectionManager.duplicationName(item.name) {
                                Button(action: {
                                    collectionManager.insert(CardCollectionManager.Collection(name: duplicationName, cards: item.cards), at: collectionManager.userCollections.firstIndex{ $0.name == item.name }!+1)
                                }, label: {
                                    Label("Settings.widgets.collections.user.duplicate", systemImage: "plus.square.on.square")
                                })
                            }
                        }
                        .wrapIf(isMACOS, in: { content in
                            content.contextMenu {
                                if let duplicationName = CardCollectionManager.shared.duplicationName(item.name) {
                                    Button(action: {
                                        collectionManager.insert(CardCollectionManager.Collection(name: duplicationName, cards: item.cards), at: collectionManager.userCollections.count)
                                    }, label: {
                                        Label("Settings.widgets.collections.user.duplicate", systemImage: "plus.square.on.square")
                                    })
                                }
                                Button(role: .destructive, action: {
                                    collectionManager.remove(at: collectionManager.userCollections.firstIndex{ $0.name == item.name }!)
                                }, label: {
                                    Label("Settings.widgets.collections.user.delete", systemImage: "trash")
                                        .foregroundStyle(.red)
                                })
                            }
                        })
                    }
                    .onMove { from, to in
                        collectionManager.move(fromOffsets: from, toOffset: to)
                    }
                } else {
                    Text("Settings.widgets.collections.user.empty")
                    //                        .bold()
                        .foregroundStyle(.secondary)
                }
                if !newCollectionIsImporting {
#if os(iOS)
                    Button(action: {
                        // We use `UIAlertController` for iOS to workaround
                        // some bugs about the alert presented by SwiftUI
                        let controller = UIAlertController(
                            title: .init(localized: "Settings.widgets.collections.user.add.alert.title"),
                            message: .init(localized: "Settings.widgets.collections.user.add.alert.message"),
                            preferredStyle: .alert
                        )
                        var alertTextField: UITextField!
                        controller.addTextField { textField in
                            alertTextField = textField
                            textField.placeholder = .init(localized: "Settings.widgets.collections.user.add.alert.prompt")
                        }
                        controller.addAction(.init(title: .init(localized: "Settings.widgets.collections.user.add.alert.cancel"), style: .cancel))
                        let confirmAction = UIAlertAction(
                            title: .init(localized: "Settings.widgets.collections.user.add.alert.create"),
                            style: .default) { _ in
                                guard let newTitle = alertTextField.text else { return }
                                if let decodeResult = decodeCollection(newTitle) {
                                    Task {
                                        await withPreloaded(cardPreload) {
                                            newCollectionIsImporting = true
                                            collectionManager.append(await decodeResult.toCollectionManagerStructure())
                                            newCollectionIsImporting = false
                                        }
                                    }
                                } else if collectionManager.nameIsAvailable(newTitle) {
                                    collectionManager.append(CardCollectionManager.Collection(name: newTitle, cards: []))
                                }
                            }
                        controller.addAction(confirmAction)
                        controller.preferredAction = confirmAction
                        NotificationCenter.default.addObserver(
                            forName: UITextField.textDidChangeNotification,
                            object: alertTextField,
                            queue: .main
                        ) { notifiction in
                            DispatchQueue.main.async {
                                guard let newTitle = alertTextField.text else { return }
                                confirmAction.isEnabled = CardCollectionManager.shared.nameIsAvailable(newTitle) || decodeCollection(newTitle) != nil
                                if decodeCollection(newTitle) != nil {
                                    confirmAction.setValue(String(localized: "Settings.widgets.collections.user.add.alert.import"), forKey: "title")
                                    if cardPreload == nil {
                                        cardPreload = preload {
                                            await PreviewCard.all()
                                        }
                                    }
                                } else {
                                    confirmAction.setValue(String(localized: "Settings.widgets.collections.user.add.alert.create"), forKey: "title")
                                }
                            }
                        }
                        currentViewController.present(controller, animated: true) {
                            // confirm action must be disabled after the alert
                            // loads, or it won't be tinted
                            confirmAction.isEnabled = false
                        }
                    }, label: {
                        Label("Settings.widgets.collections.user.add", systemImage: "plus")
                    })
#endif
                } else {
                    HStack {
                        //                        ProgressView()
                        Text("Settings.widgets.collections.user.importing")
                            .foregroundStyle(.secondary)
                    }
                }
            }, header: {
                Text("Settings.widgets.collections.user")
            })
            
            Section("Settings.widgets.collections.built-in") {
                ForEach(collectionManager.builtinCollections, id: \.self) { item in
                    Button(action: {
                        destinationCollection = item
                        showDestination = true
                    }, label: {
                        HStack {
                            Text(item.name)
                            Spacer()
                            if item.cards.count > 0 {
                                Text("\(item.cards.count)")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.forward")
                                .foregroundStyle(.tertiary)
                                .font(.footnote)
                                .bold()
                        }
                        .contentShape(Rectangle())
                    })
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if let duplicationName = CardCollectionManager.shared.duplicationName(item.name) {
                            Button(action: {
                                collectionManager.insert(CardCollectionManager.Collection(name: duplicationName, cards: item.cards), at: collectionManager.userCollections.count)
                            }, label: {
                                Label("Settings.widgets.collections.user.duplicate", systemImage: "plus.square.on.square")
                            })
                        }
                    }
                    .wrapIf(isMACOS, in: { content in
                        content.contextMenu {
                            if let duplicationName = CardCollectionManager.shared.duplicationName(item.name) {
                                Button(action: {
                                    collectionManager.insert(CardCollectionManager.Collection(name: duplicationName, cards: item.cards), at: collectionManager.userCollections.count)
                                }, label: {
                                    Label("Settings.widgets.collections.user.duplicate", systemImage: "plus.square.on.square")
                                })
                            }
                        }
                    })
                }
            }
            
            Section(content: {
                Toggle(isOn: $hideCollectionNameWhileSharing, label: {
                    VStack(alignment: .leading) {
                        Text("Settings.widgets.collections.share-without-name")
                        Text("Settings.widgets.collections.share-without-name.description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                })
            }, footer: {
                SettingsDocumentButton(document: "CollectionCode") {
                    Text("Settings.widgets.collections.learn-more")
                }
                .font(isMACOS ? .body : .caption)
                .toolbar {
                    if isMACOS {
                        ToolbarItem {
                            Button(action: {
                                newCollectionInput = ""
                                newCollectionSheetIsDisplaying = true
                            }, label: {
                                Label("Settings.widgets.collections.user.add", systemImage: "plus")
                            })
                            .disabled(newCollectionIsImporting)
                        }
                    }
                }
            })
        }
        .navigationDestination(isPresented: $showDestination, destination: {
            if let destinationCollection {
                SettingsWidgetsCollectionDetailsView(collectionGivenName: destinationCollection.name, isPresented: $showDestination)
            }
        })
        .alert("Settings.widgets.collections.user.add.alert.title", isPresented: $newCollectionSheetIsDisplaying, actions: {
            CollectionAddingActions(newCollectionTitle: $newCollectionInput, newCollectionIsAdding: $newCollectionIsImporting)
        }, message: {
            Text("Settings.widgets.collections.user.add.alert.message")
        })
        #if os(iOS)
        .introspect(.viewController, on: .iOS(.v17...)) { viewController in
            currentViewController = viewController
        }
        #endif
    }
    
    struct CollectionAddingActions: View {
        @Binding var newCollectionTitle: String
        @Binding var newCollectionIsAdding: Bool
        @State private var cardPreload: PreloadDescriptor<[PreviewCard]>?
        var body: some View {
            TextField("Settings.widgets.collections.user.add.alert.prompt", text: $newCollectionTitle)
            Button(action: {
                if let decodeResult = decodeCollection(newCollectionTitle) {
                    Task {
                        await withPreloaded(cardPreload) {
                            newCollectionIsAdding = true
                            CardCollectionManager.shared.append(await decodeResult.toCollectionManagerStructure())
                            newCollectionIsAdding = false
                        }
                    }
                } else if CardCollectionManager.shared.nameIsAvailable(newCollectionTitle) {
                    CardCollectionManager.shared.append(CardCollectionManager.Collection(name: newCollectionTitle, cards: []))
                    //                    userCollections = CardCollectionManager.shared.userCollections
                    //                    userIsAddingNewCollection = false
                }
            }, label: {
                if newCollectionIsAdding {
                    ProgressView()
                } else {
                    if decodeCollection(newCollectionTitle) != nil {
                        Text("Settings.widgets.collections.user.add.alert.import")
                            .onAppear {
                                if cardPreload == nil {
                                    cardPreload = preload {
                                        await PreviewCard.all()
                                    }
                                }
                            }
                    } else {
                        Text("Settings.widgets.collections.user.add.alert.create")
                    }
                }
            })
            .disabled(!CardCollectionManager.shared.nameIsAvailable(newCollectionTitle) && decodeCollection(newCollectionTitle) == nil)
            .disabled(newCollectionIsAdding)
            .keyboardShortcut(.defaultAction)
            Button(role: .cancel, action: {}, label: {
                Text("Settings.widgets.collections.user.add.alert.cancel")
            })
        }
    }
}

struct SettingsWidgetsCollectionDetailsView: View {
    @AppStorage("hideCollectionNameWhileSharing") var hideCollectionNameWhileSharing = false
    var collectionGivenName: String
    @StateObject var collectionManager = CardCollectionManager.shared
    @Binding var isPresented: Bool
    @State var collectionName: String = ""
    @State var showCollectionDeleteAlert = false
    @State var cards: [Int: Card] = [:]
    @State var layoutType: Int = 1
    @State var collectionCode: String = ""
    @State var showCollectionCodeDialog = false
    @State var showExportCheckmark = false
    @State var showCollectionEditorSheet = false
    @State var isCodeShareSheetPresented = false
    var body: some View {
        if let collection = collectionManager.allCollections.first(where: { $0.name == collectionGivenName }) {
            ScrollView {
                HStack {
                    Spacer(minLength: 0)
                    LazyVStack {
                        CustomGroupBox(cornerRadius: isMACOS ? 15 : 25) {
                            LazyVStack {
                                Group {
                                    HStack {
                                        Text("Settings.widgets.collections.name")
                                            .bold()
                                        Spacer()
                                        if !collection.isBuiltIn {
                                            TextField("Settings.widgets.collections.name", text: $collectionName)
                                                .multilineTextAlignment(.trailing)
                                                .onSubmit {
                                                    if collectionManager.nameIsAvailable(collectionName) {
                                                        collectionManager.userCollections[collectionManager.userCollections.firstIndex{$0.name == collection.name}!].name = collectionName
                                                        collectionManager.updateStorage()
                                                    } else {
                                                        collectionName = collection.name
                                                    }
                                                }
                                                .textFieldStyle(.plain)
                                        } else {
                                            Text(collectionName)
                                                .textSelection(.enabled)
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                if !collection.isBuiltIn {
                                    Group {
                                        Button(role: .destructive, action: {
                                            showCollectionDeleteAlert = true
                                        }, label: {
                                            HStack {
                                                Label("Settings.widgets.collections.delete", systemImage: "trash")
                                                    .bold()
                                                    .foregroundStyle(.red)
                                                Spacer()
                                            }
                                            .contentShape(Rectangle())
                                        })
                                        .buttonStyle(.plain)
                                        .wrapIf(!isMACOS, in: { content in
                                            content
                                                .padding(.top, 3)
                                        })
                                    }
                                    .alert("Settings.widgets.collections.delete.alert.title.\(collection.name)", isPresented: $showCollectionDeleteAlert, actions: {
                                        Button(role: .destructive, action: {
                                            collectionManager.remove(at: collectionManager.userCollections.firstIndex{$0.name == collectionName}!)
                                            isPresented = false
                                        }, label: {
                                            Text("Settings.widgets.collections.delete.alert.delete")
                                        })
                                        Button(role: .cancel, action: {}, label: {
                                            Text("Settings.widgets.collections.delete.alert.cancel")
                                        })
                                    }, message: {
                                        Text("Settings.widgets.collections.delete.alert.message")
                                    })
                                } else {
                                    Group {
                                        HStack {
                                            Text("Settings.widgets.collections.is-built-in")
                                                .bold()
                                            Spacer()
                                            Text("Settings.widgets.collections.is-built-in.yes")
                                                .textSelection(.enabled)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: infoContentMaxWidth)
                        
                        DetailSectionsSpacer()
                        if !collection.isBuiltIn && !isMACOS {
                            CustomGroupBox {
                                Button(action: {
                                    showCollectionEditorSheet = true
                                }, label: {
                                    HStack {
                                        Spacer()
                                        Label("Settings.widgets.collections.edit", systemImage: "square.and.pencil")
                                            .bold()
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                })
                            }
                        }
                        ForEach(collection.cards, id: \.self) { card in
                            SettingsWidgetsCollectionsItemView(
                                collectionIndex: collectionManager.userCollections.firstIndex(where: { $0.name == collectionGivenName }) ?? 0,
                                collectionCard: card,
                                collectionIsEditable: !collection.isBuiltIn,
                                layoutType: $layoutType
                            )
                        }
                        if collection.cards.isEmpty {
                            CustomGroupBox {
                                HStack {
                                    Spacer()
                                    Text("Settings.widgets.collections.no-card")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                    .padding()
                    Spacer(minLength: 0)
                }
            }
            .withSystemBackground()
            .navigationTitle(collectionName)
            .wrapIf(true, in: { content in
                if #available(iOS 26.0, macOS 26.0, *) {
                    content
                        .navigationSubtitle("Settings.widgets.collections.count.\(collection.cards.count)")
                }
            })
            .onAppear {
                collectionName = collection.name
                if !collection.isBuiltIn {
                    collectionManager.userCollections[collectionManager.userCollections.firstIndex{ $0.name == collectionName }!].cards = collection.cards.sorted{ $0.id < $1.id }
                }
            }
            .toolbar {
                if !collection.cards.isEmpty {
                    ToolbarItem {
                        LayoutPicker(selection: $layoutType, options: [("Filter.view.list", "list.bullet", 1), ("Filter.view.gallery", "text.below.rectangle", 3)])
                    }
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer()
                    }
                }
                if isMACOS {
                    ToolbarItem {
                        Button(action: {
                            showCollectionEditorSheet = true
                        }, label: {
                            Label("Settings.widgets.collections.edit", systemImage: "square.and.pencil")
                        })
                    }
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer()
                    }
                }
                if !collection.cards.isEmpty {
                    ToolbarItem(placement: .primaryAction, content: {
                        Button(action: {
                            collectionCode = encodeCollection(collection.toCollectionCodeStructure(hideName: hideCollectionNameWhileSharing))
                            showCollectionCodeDialog = true
                        }, label: {
                            if showExportCheckmark {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        })
                    })
                }
            }
            .wrapIf(isMACOS, in: { content in
                #if os(macOS)
                content
                    .window(isPresented: $showCollectionEditorSheet, content: {
                        CollectionEditorView(collection: collection)
                            .introspect(.window, on: .macOS(.v14...)) { window in
                                window.standardWindowButton(.zoomButton)?.isEnabled = false
                                window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
                                window.level = .floating
                            }
                    })
                #endif
            }, else: { content in
                content
                    .sheet(isPresented: $showCollectionEditorSheet) {
                        CollectionEditorView(collection: collection)
                    }
            })
            .alert("Settings.widgets.collections.code.dialog.title", isPresented: $showCollectionCodeDialog, actions: {
                Button(action: {
                    copyStringToClipboard(collectionCode)
                    withAnimation {
                        showExportCheckmark = true
                    }
                    showCollectionCodeDialog = false
                }, label: {
                    Label("Settings.widgets.collections.code.dialog.copy", systemImage: "document.on.document")
                })
                .keyboardShortcut(.defaultAction)
                #if os(iOS)
                // ShareLink in `alert` doesn't work on iOS,
                // we have to use a button to present it with UIKit
                Button("Settings.widgets.collections.code.dialog.share", systemImage: "square.and.arrow.up") {
                    isCodeShareSheetPresented = true
                }
                #else
                ShareLink(item: collectionCode)
                #endif
                Button(role: .cancel, action: {}, label: {
                    Text("Settings.widgets.collections.code.dialog.cancel")
                })
            }, message: {
                Text("Settings.widgets.collections.code.dialog.message")
            })
            #if os(iOS)
            .sheet(isPresented: $isCodeShareSheetPresented) {
                CollectionCodeShareSheet(for: collectionCode)
            }
            #endif
            .onChange(of: showExportCheckmark) {
                if showExportCheckmark {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showExportCheckmark = false
                        }
                    }
                }
            }
        } else {
            ProgressView()
        }
    }
    
    #if os(iOS)
    struct CollectionCodeShareSheet: UIViewControllerRepresentable {
        let code: String
        
        init(for code: String) {
            self.code = code
        }
        
        func makeUIViewController(context: Context) -> some UIViewController {
            UIActivityViewController(activityItems: [code], applicationActivities: nil)
        }
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    }
    #endif
}


struct SettingsWidgetsCollectionsItemView: View {
    var collectionIndex: Int
    var collectionCard: CardCollectionManager.Card
    var collectionIsEditable: Bool
    @Binding var layoutType: Int
    @State var doriCard: Card?
    @State var characterName: LocalizedData<String>? = nil
    
    let titlePlaceholder = LocalizedData(jp: "Lorem Ipsum Dolor")
    var body: some View {
        CustomGroupBox {
            CustomStack(axis: layoutType == 1 ? .horizontal : .vertical) {
                if layoutType != 3 {
                    HStack(spacing: 5) {
                        if let doriCard {
                            if collectionCard.isTrained {
                                CardPreviewImage(doriCard, showTrainedVersion: true)
                                // FIXME: Some cards have normal version but have no corresponding thumbnail view.
                            } else {
                                CardPreviewImage(doriCard)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(getPlaceholderColor())
                                .aspectRatio(1, contentMode: .fit)
                                .frame(width: 67, height: 67)
                        }
                    }
                } else {
                    if let doriCard {
                        CardCoverImage(doriCard, band: DoriCache.preCache.categorizedCharacters.first(where: { $0.value.contains(where: { $0.id == doriCard.characterID }) })?.key, displayType: collectionCard.isTrained ? .trainedOnly : .normalOnly)
#if !os(macOS)
                            .allowsHitTesting(false)
#endif
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(getPlaceholderColor())
                            .aspectRatio(480/320, contentMode: .fit)
                    }
                }
                
                if layoutType != 1 {
                    Spacer()
                } else {
                    Spacer()
                        .frame(maxWidth: 15)
                }
                
                
                HStack {
                    if layoutType == 3 {
                        Spacer(minLength: 0)
                    }
                    
                    Group {
                        VStack(alignment: layoutType == 1 ? .leading : .center) {
                            if let doriCard {
                                HighlightableText(doriCard.prefix.forPreferredLocale() ?? "")
                                    .bold()
                                    .layoutPriority(1)
                                Group {
                                    if layoutType == 1 {
                                        Text(characterName?.forPreferredLocale() ?? "nil") + Text("Typography.bold-dot-seperater").bold() + Text("#\(String(doriCard.id))").fontDesign(.monospaced)
                                        Text(collectionCard.isTrained ? "Settings.widgets.collections.card.trained" : "Settings.widgets.collections.card.normal")
                                    } else {
                                        Text(characterName?.forPreferredLocale() ?? "nil") + Text("Typography.bold-dot-seperater").bold() + Text("#\(String(doriCard.id))").fontDesign(.monospaced) + Text("Typography.bold-dot-seperater").bold() +  Text(collectionCard.isTrained ? "Settings.widgets.collections.card.trained" : "Settings.widgets.collections.card.normal")
                                    }
                                }
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            } else {
                                Text(verbatim: "Lorem Ipsum Dolor")
                                    .bold()
                                Group {
                                    if layoutType == 1 {
                                        Text(verbatim: "Lorem Ipsum Dolor")
                                            .redacted(reason: .placeholder)
                                        Text(verbatim: "Lorem")
                                            .redacted(reason: .placeholder)
                                    } else {
                                        Text(verbatim: "Lorem Ipsum Dolor Sit Amet")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(.caption)
                            }
                        }
                    }
                    //                .wrapIf(layoutType == 3, in: { content z
                    //
                    //                })
                    
//                    if layoutType == 1 {
                        Spacer(minLength: 0)
//                    }
                    
                    if collectionIsEditable {
                        SettingsWidgetsCollectionsItemActionMenuView(collectionIndex: collectionIndex, collectionCard: collectionCard)
                    }
                }
            }
            .wrapIf(layoutType != 1) { content in
                HStack {
                    Spacer(minLength: 0)
                    content
                    Spacer(minLength: 0)
                }
            }
        }
        .onAppear {
            Task {
                doriCard = await Card(id: collectionCard.id)
                characterName = DoriCache.preCache.characterDetails[doriCard?.characterID ?? -1]?.characterName
            }
        }
        .wrapIf(doriCard == nil, in: { content in
            content
                .redacted(reason: .placeholder)
        })
    }
}

struct SettingsWidgetsCollectionsItemActionMenuView: View {
    var collectionIndex: Int
    var collectionCard: CardCollectionManager.Card
    @State var cardTrainingStatusIsSwitchable = false
    var body: some View {
        Menu(content: {
            Group {
                Button(action: {
                    if cardTrainingStatusIsSwitchable {
                        let cardIndex = CardCollectionManager.shared.userCollections[collectionIndex].cards.firstIndex(where: { $0.id == collectionCard.id && $0.isTrained == collectionCard.isTrained })!
                        CardCollectionManager.shared.userCollections[collectionIndex].cards[cardIndex] = .init(id: collectionCard.id, isTrained: !collectionCard.isTrained, localizedName: collectionCard.localizedName, file: collectionCard.file)
                        
                        CardCollectionManager.shared.updateStorage()
                    }
                }, label: {
                    Label(collectionCard.isTrained ? "Settings.widgets.collections.actions.change.normal" : "Settings.widgets.collections.actions.change.trained", systemImage: "rectangle.2.swap")
                })
                .disabled(!cardTrainingStatusIsSwitchable)
                Button(role: .destructive, action: {
                    let cardIndex = CardCollectionManager.shared.userCollections[collectionIndex].cards.firstIndex(where: { $0.id == collectionCard.id && $0.isTrained == collectionCard.isTrained })!
                    CardCollectionManager.shared.userCollections[collectionIndex].cards.remove(at: cardIndex)
                    
                    CardCollectionManager.shared.updateStorage()
                }, label: {
                    Label("Settings.widgets.collections.actions.remove", systemImage: "minus.circle")
                })
            }
            .onAppear {
                if !CardCollectionManager.shared.userCollections[collectionIndex].cards.contains(where: { $0.id == collectionCard.id && $0.isTrained != collectionCard.isTrained }) {
                    Task {
                        let doriCard = await Card(id: collectionCard.id)
                        if let doriCard {
                            if collectionCard.isTrained {
                                cardTrainingStatusIsSwitchable = await DoriURLValidator.reachability(of: doriCard.coverNormalImageURL)
                            } else {
                                cardTrainingStatusIsSwitchable = doriCard.coverAfterTrainingImageURL != nil
                            }
                        }
                    }
                } else {
                    cardTrainingStatusIsSwitchable = false
                }
            }
        }, label: {
            Image(systemName: "ellipsis.circle")
                .font(isMACOS ? .body : .title3)
        })
    }
}
