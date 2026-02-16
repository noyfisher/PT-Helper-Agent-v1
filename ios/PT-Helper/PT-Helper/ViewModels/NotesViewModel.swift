import SwiftUI

import Foundation
import Combine

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var newNoteContent: String = ""
    
    func addNote() {
        guard !newNoteContent.isEmpty else { return }
        let newNote = Note(content: newNoteContent)
        notes.append(newNote)
        newNoteContent = ""
    }
}
