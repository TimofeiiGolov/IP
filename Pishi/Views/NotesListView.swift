// File: Pishi/Views/NotesListView.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Главный экран: список/сетка заметок с поиском, сортировкой и фильтрами.
struct NotesListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: SettingsStore

    @State private var viewModel: NotesListViewModel?
    @State private var editingNote: Note?
    @State private var showSettings = false
    @State private var showImporter = false
    @State private var showDeleteConfirmation = false
    @State private var noteToDelete: Note?

    private var vm: NotesListViewModel? { viewModel }

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Constants.Strings.notesTitle)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(settings)
            }
            .sheet(item: $editingNote) { note in
                if let vm {
                    NoteEditorView(note: note, viewModel: NoteEditorViewModel(
                        note: note,
                        persistence: PersistenceController.shared,
                        autosaveInterval: settings.autosaveInterval.seconds
                    ))
                    .environmentObject(settings)
                    .onDisappear { vm.load() }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: ImportService.allowedContentTypes,
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .confirmationDialog(
                Constants.Strings.delete,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(Constants.Strings.delete, role: .destructive) {
                    if let note = noteToDelete, let vm {
                        vm.delete(note)
                    }
                }
                Button(Constants.Strings.cancel, role: .cancel) {}
            }
            .alert(
                Constants.Strings.saveError,
                isPresented: Binding(
                    get: { vm?.showImportError ?? false },
                    set: { vm?.showImportError = $0 }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm?.importError ?? "")
            }
        }
        .task {
            if viewModel == nil {
                let controller = PersistenceController.shared
                let created = NotesListViewModel(persistence: controller)
                created.applySettings(settings)
                viewModel = created
                created.load()
            }
        }
    }

    // MARK: - Контент

    @ViewBuilder
    private func content(vm: NotesListViewModel) -> some View {
        ZStack(alignment: .bottom) {
            if vm.isEmpty {
                if vm.isSearchEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: Constants.Strings.nothingFound,
                        subtitle: String(localized: "Попробуйте изменить запрос")
                    )
                } else {
                    EmptyStateView(
                        icon: "square.and.pencil",
                        title: Constants.Strings.emptyStateTitle,
                        subtitle: Constants.Strings.emptyStateSubtitle
                    )
                }
            } else if vm.displayMode == .grid {
                gridContent(vm: vm)
            } else {
                listContent(vm: vm)
            }

            if vm.showUndoBanner {
                undoBanner(vm: vm)
            }
        }
        .searchable(
            text: Binding(
                get: { vm.searchText },
                set: { newValue in
                    vm.searchText = newValue
                    vm.load()
                }
            ),
            prompt: Constants.Strings.searchPlaceholder
        )
        .onChange(of: vm.filter) { _, _ in vm.load() }
        .onChange(of: vm.sortOption) { _, _ in vm.load() }
    }

    private func listContent(vm: NotesListViewModel) -> some View {
        List {
            if !vm.pinnedNotes.isEmpty {
                Section(String(localized: "Закреплённые")) {
                    ForEach(vm.pinnedNotes) { note in
                        noteRow(note: note, vm: vm)
                    }
                }
            }
            if !vm.unpinnedNotes.isEmpty {
                Section {
                    ForEach(vm.unpinnedNotes) { note in
                        noteRow(note: note, vm: vm)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func gridContent(vm: NotesListViewModel) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: Constants.Layout.gridColumnsMinWidth), spacing: 12)],
                spacing: 12
            ) {
                ForEach(vm.notes) { note in
                    NoteGridItemView(
                        note: note,
                        showWordCount: settings.showWordCount,
                        showCharacterCount: settings.showCharacterCount,
                        showArchiveBadge: vm.filter == .archive
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { editingNote = note }
                    .contextMenu {
                        noteContextMenu(note: note, vm: vm)
                    }
                    .accessibilityIdentifier(Constants.Accessibility.noteRow)
                }
            }
            .padding()
        }
    }

    private func noteRow(note: Note, vm: NotesListViewModel) -> some View {
        NoteRowView(
            note: note,
            showWordCount: settings.showWordCount,
            showCharacterCount: settings.showCharacterCount,
            showArchiveBadge: vm.filter == .archive
        )
        .contentShape(Rectangle())
        .onTapGesture { editingNote = note }
        .accessibilityIdentifier(Constants.Accessibility.noteRow)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                vm.togglePin(note)
            } label: {
                Label(
                    note.isPinned ? String(localized: "Открепить") : String(localized: "Закрепить"),
                    systemImage: note.isPinned ? "pin.slash" : "pin"
                )
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                if settings.confirmDelete {
                    noteToDelete = note
                    showDeleteConfirmation = true
                } else {
                    vm.delete(note)
                }
            } label: {
                Label(Constants.Strings.delete, systemImage: "trash")
            }
            Button {
                if vm.filter == .archive {
                    vm.restore(note)
                } else {
                    vm.archive(note)
                }
            } label: {
                Label(
                    vm.filter == .archive ? String(localized: "Восстановить") : String(localized: "Архивировать"),
                    systemImage: vm.filter == .archive ? "arrow.uturn.backward" : "archivebox"
                )
            }
            .tint(.orange)
        }
        .contextMenu {
            noteContextMenu(note: note, vm: vm)
        }
    }

    @ViewBuilder
    private func noteContextMenu(note: Note, vm: NotesListViewModel) -> some View {
        Button {
            vm.togglePin(note)
        } label: {
            Label(
                note.isPinned ? String(localized: "Открепить") : String(localized: "Закрепить"),
                systemImage: note.isPinned ? "pin.slash" : "pin"
            )
        }
        Button {
            if vm.filter == .archive {
                vm.restore(note)
            } else {
                vm.archive(note)
            }
        } label: {
            Label(
                vm.filter == .archive ? String(localized: "Восстановить") : String(localized: "Архивировать"),
                systemImage: vm.filter == .archive ? "arrow.uturn.backward" : "archivebox"
            )
        }
        Button {
            _ = vm.duplicate(note)
        } label: {
            Label(String(localized: "Дублировать"), systemImage: "plus.square.on.square")
        }
        Button(role: .destructive) {
            if settings.confirmDelete {
                noteToDelete = note
                showDeleteConfirmation = true
            } else {
                vm.delete(note)
            }
        } label: {
            Label(Constants.Strings.delete, systemImage: "trash")
        }
    }

    private func undoBanner(vm: NotesListViewModel) -> some View {
        HStack {
            Text(Constants.Strings.undoDelete)
                .font(.subheadline)
            Spacer()
            Button(String(localized: "Отменить")) {
                vm.undoDelete()
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                if let vm {
                    Picker(String(localized: "Фильтр"), selection: Binding(
                        get: { vm.filter },
                        set: { vm.filter = $0 }
                    )) {
                        ForEach(NoteFilter.allCases) { option in
                            Label(option.localizedName, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                    SortMenuView(selection: Binding(
                        get: { vm.sortOption },
                        set: { vm.sortOption = $0 }
                    ))
                }
            } label: {
                Label(String(localized: "Фильтр и сортировка"), systemImage: "line.3.horizontal.decrease.circle")
                    .accessibilityIdentifier(Constants.Accessibility.filterMenu)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            if let vm {
                Button {
                    vm.displayMode = vm.displayMode.toggled
                    settings.displayMode = vm.displayMode
                } label: {
                    Label(
                        vm.displayMode.toggled.localizedName,
                        systemImage: vm.displayMode.toggled.systemImage
                    )
                }
                .accessibilityIdentifier(Constants.Accessibility.displayModeToggle)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showImporter = true
            } label: {
                Label(String(localized: "Импортировать файл"), systemImage: "square.and.arrow.down")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Label(Constants.Strings.settings, systemImage: "gearshape")
            }
            .accessibilityIdentifier(Constants.Accessibility.settingsButton)
        }
        ToolbarItem(placement: .bottomBar) {
            Button {
                if let vm {
                    editingNote = vm.createNote()
                }
            } label: {
                Label(Constants.Strings.newNote, systemImage: "square.and.pencil")
            }
            .accessibilityIdentifier(Constants.Accessibility.newNoteButton)
        }
    }

    // MARK: - Импорт

    private func handleImport(_ result: Result<[URL], Error>) {
        guard let vm else { return }
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            _ = vm.importFile(from: url)
        case .failure(let error):
            // Отмена выбора файла не является ошибкой для пользователя.
            if (error as NSError).code != NSUserCancelledError {
                vm.importError = error.localizedDescription
                vm.showImportError = true
            }
        }
    }
}

#Preview {
    NotesListView()
        .environmentObject(SettingsStore())
        .modelContainer(for: Note.self, inMemory: true)
}
