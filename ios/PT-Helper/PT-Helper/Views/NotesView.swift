import SwiftUI

struct NotesView: View {
    @StateObject private var viewModel = NotesViewModel()
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // New note input
                    CardSection(icon: "square.and.pencil", color: .blue, title: "New Note") {
                        VStack(spacing: AppSpacing.md) {
                            ZStack(alignment: .topLeading) {
                                if viewModel.newNoteContent.isEmpty {
                                    Text("How are you feeling today? Any progress or setbacks...")
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                }
                                TextEditor(text: $viewModel.newNoteContent)
                                    .focused($isEditorFocused)
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                                    .padding(AppSpacing.xs)
                            }
                            .background(AppColors.inputBackground)
                            .cornerRadius(AppCorners.medium)

                            Button(action: {
                                viewModel.addNote()
                                isEditorFocused = false
                            }) {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Save Note")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle(isDisabled: viewModel.newNoteContent.isEmpty))
                            .disabled(viewModel.newNoteContent.isEmpty)
                        }
                    }

                    // Notes list
                    if viewModel.notes.isEmpty {
                        EmptyStateView(
                            icon: "note.text",
                            title: "No Notes Yet",
                            subtitle: "Start tracking your recovery by adding your first note above"
                        )
                    } else {
                        SectionHeader(icon: "clock.arrow.circlepath", color: .purple, title: "Previous Notes")

                        ForEach(viewModel.notes.reversed()) { note in
                            noteCard(for: note)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Recovery Notes")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isEditorFocused = false
        }
    }

    private func noteCard(for note: Note) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: "note.text")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 28, height: 28)
                .background(Color.green.opacity(0.15))
                .cornerRadius(7)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(note.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(note.dateCreated, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .cardStyle()
    }
}
