// File: Pishi/Views/NoteEditorView.swift
import SwiftUI
import UniformTypeIdentifiers

/// Экран редактора заметки: заголовок, текст, автосохранение,
/// поиск внутри заметки, undo/redo, меню действий.
struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsStore

    let note: Note
    @State private var viewModel: NoteEditorViewModel
    @State private var textFocus = false
    @State private var showDeleteConfirmation = false
    @State private var showStatistics = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var deleted = false

    init(note: Note, viewModel: NoteEditorViewModel) {
        self.note = note
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            titleField
            Divider()
            if viewModel.isSearchVisible {
                SearchBar(
                    query: Binding(
                        get: { viewModel.inNoteSearchQuery },
                        set: { newValue in
                            viewModel.inNoteSearchQuery = newValue
                            viewModel.currentMatchIndex = 0
                        }
                    ),
                    matchCount: viewModel.matchCount,
                    currentMatchIndex: viewModel.currentMatchIndex,
                    onNext: { viewModel.nextMatch() },
                    onPrevious: { viewModel.previousMatch() },
                    onClose: { viewModel.closeSearch() }
                )
                Divider()
            }
            editorBody
            Divider()
            bottomBar
        }
        .navigationTitle(Text(note.displayTitle).lineLimit(1))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            if settings.autoFocus {
                textFocus = true
            }
        }
        .onDisappear {
            // Сохраняем при уходе с экрана и чистим пустую заметку.
            viewModel.cleanupEmptyNoteIfNeeded()
        }
        .confirmationDialog(
            Constants.Strings.delete,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(Constants.Strings.delete, role: .destructive) {
                deleted = true
                viewModel.deleteNote()
                dismiss()
            }
            Button(Constants.Strings.cancel, role: .cancel) {}
        } message: {
            Text(String(localized: "Заметка будет удалена безвозвратно."))
        }
        .sheet(isPresented: $showShareSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .sheet(isPresented: $showStatistics) {
            NoteStatisticsView(viewModel: viewModel)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Поля ввода

    private var titleField: some View {
        TextField(Constants.Strings.titleField, text: Binding(
            get: { viewModel.title },
            set: { newValue in
                viewModel.title = newValue
                viewModel.contentChanged()
            }
        ))
        .font(AppTheme.titleFont(settings: settings))
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(minHeight: Constants.Layout.minimumTouchTarget)
        .accessibilityIdentifier(Constants.Accessibility.titleField)
        .submitLabel(.next)
    }

    private var editorBody: some View {
        TextViewRepresentable(
            text: Binding(
                get: { viewModel.text },
                set: { newValue in
                    viewModel.text = newValue
                    viewModel.contentChanged()
                }
            ),
            isFirstResponder: Binding(
                get: { textFocus },
                set: { textFocus = $0 }
            ),
            font: AppTheme.editorUIFont(settings: settings),
            searchQuery: viewModel.isSearchVisible ? viewModel.inNoteSearchQuery : "",
            highlightedRange: viewModel.currentMatchRange.flatMap { range in
                let lower = viewModel.text.distance(from: viewModel.text.startIndex, to: range.lowerBound)
                let upper = viewModel.text.distance(from: viewModel.text.startIndex, to: range.upperBound)
                return NSRange(location: lower, length: upper - lower)
            },
            lineWrapping: settings.lineWrapping
        )
        .accessibilityIdentifier(Constants.Accessibility.bodyField)
        .accessibilityLabel(Constants.Strings.textField)
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            SaveStatusView(status: viewModel.saveStatus)
            Spacer()
            if settings.showStatistics {
                NoteStatisticsView(viewModel: viewModel, compact: true)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                viewModel.saveNow()
                textFocus = false
                dismiss()
            } label: {
                Label(String(localized: "Назад"), systemImage: "chevron.backward")
            }
            .accessibilityIdentifier(Constants.Accessibility.backButton)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                viewModel.undo()
            } label: {
                Label(String(localized: "Отменить"), systemImage: "arrow.uturn.backward")
            }
            .disabled(!viewModel.canUndo)

            Button {
                viewModel.redo()
            } label: {
                Label(String(localized: "Повторить"), systemImage: "arrow.uturn.forward")
            }
            .disabled(!viewModel.canRedo)

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    viewModel.isSearchVisible.toggle()
                }
            } label: {
                Label(String(localized: "Поиск в заметке"), systemImage: "doc.text.magnifyingglass")
            }

            Menu {
                editorMenuContent
            } label: {
                Label(String(localized: "Действия"), systemImage: "ellipsis.circle")
            }
            .accessibilityIdentifier(Constants.Accessibility.editorMenu)
        }
    }

    @ViewBuilder
    private var editorMenuContent: some View {
        Button {
            showStatistics = true
        } label: {
            Label(String(localized: "Статистика"), systemImage: "chart.bar")
        }

        ShareLink(
            item: viewModel.text,
            subject: Text(note.displayTitle),
            message: Text(String(localized: "Заметка из приложения «Пиши»"))
        ) {
            Label(String(localized: "Поделиться"), systemImage: "square.and.arrow.up")
        }

        Button {
            export(format: .txt)
        } label: {
            Label(String(localized: "Экспорт TXT"), systemImage: "doc.plaintext")
        }

        Button {
            export(format: .markdown)
        } label: {
            Label(String(localized: "Экспорт Markdown"), systemImage: "doc.richtext")
        }

        Divider()

        Button {
            viewModel.togglePin()
        } label: {
            Label(
                note.isPinned ? String(localized: "Открепить") : String(localized: "Закрепить"),
                systemImage: note.isPinned ? "pin.slash" : "pin"
            )
        }

        Button {
            viewModel.toggleArchive()
            viewModel.saveNow()
            dismiss()
        } label: {
            Label(
                note.isArchived ? String(localized: "Восстановить") : String(localized: "Архивировать"),
                systemImage: note.isArchived ? "arrow.uturn.backward" : "archivebox"
            )
        }

        Divider()

        Button(role: .destructive) {
            if settings.confirmDelete {
                showDeleteConfirmation = true
            } else {
                deleted = true
                viewModel.deleteNote()
                dismiss()
            }
        } label: {
            Label(Constants.Strings.delete, systemImage: "trash")
        }
    }

    // MARK: - Экспорт

    private func export(format: ExportService.ExportFormat) {
        do {
            exportURL = try viewModel.exportURL(format: format)
            showShareSheet = true
        } catch {
            exportURL = nil
        }
    }
}

/// Обёртка над UIActivityViewController для системного Share Sheet.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
