// File: Pishi/Views/ArchiveView.swift
import SwiftUI
import SwiftData

/// Экран архива: заметки с isArchived == true, с восстановлением и удалением.
struct ArchiveView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var viewModel: NotesListViewModel?
    @State private var editingNote: Note?
    @State private var showDeleteConfirmation = false
    @State private var noteToDelete: Note?

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "Архив"))
        .sheet(item: $editingNote) { note in
            NoteEditorView(
                note: note,
                viewModel: NoteEditorViewModel(
                    note: note,
                    persistence: PersistenceController.shared,
                    autosaveInterval: settings.autosaveInterval.seconds
                )
            )
            .environmentObject(settings)
            .onDisappear { viewModel?.load() }
        }
        .confirmationDialog(
            Constants.Strings.delete,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(Constants.Strings.delete, role: .destructive) {
                if let note = noteToDelete {
                    viewModel?.delete(note)
                }
            }
            Button(Constants.Strings.cancel, role: .cancel) {}
        }
        .task {
            if viewModel == nil {
                let vm = NotesListViewModel(persistence: PersistenceController.shared)
                vm.filter = .archive
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(vm: NotesListViewModel) -> some View {
        if vm.notes.isEmpty {
            EmptyStateView(
                icon: "archivebox",
                title: String(localized: "Архив пуст"),
                subtitle: String(localized: "Здесь появятся архивированные заметки")
            )
        } else {
            List {
                ForEach(vm.notes) { note in
                    NoteRowView(
                        note: note,
                        showWordCount: settings.showWordCount,
                        showCharacterCount: settings.showCharacterCount,
                        showArchiveBadge: true
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { editingNote = note }
                    .accessibilityIdentifier(Constants.Accessibility.noteRow)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            vm.restore(note)
                        } label: {
                            Label(String(localized: "Восстановить"), systemImage: "arrow.uturn.backward")
                        }
                        .tint(.green)
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
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    NavigationStack {
        ArchiveView()
            .environmentObject(SettingsStore())
            .modelContainer(for: Note.self, inMemory: true)
    }
}
