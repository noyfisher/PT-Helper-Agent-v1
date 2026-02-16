import Foundation

import SwiftUI

struct NotesView: View {
    @StateObject private var viewModel = NotesViewModel()
    
    var body: some View {
        VStack {
            TextEditor(text: $viewModel.newNoteContent)
                .border(Color.gray, width: 1)
                .padding()
            
            Button(action: {
                viewModel.addNote()
            }) {
                Text("Save Note")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding([.leading, .trailing])
            
            List(viewModel.notes) { note in
                VStack(alignment: .leading) {
                    Text(note.content)
                    Text(note.dateCreated, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Recovery Notes")
    }
}
