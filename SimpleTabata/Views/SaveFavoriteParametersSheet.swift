//
//  SaveFavoriteParametersSheet.swift
//  SimpleTabata
//
//  Created by Denis Denisov on 21/3/26.
//

import SwiftUI

struct SaveFavoriteParametersSheet: View {
    @State private var name = ""
    @FocusState private var nameFocused: Bool
    
    let onCancel: () -> Void
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .minimumScaleFactor(0.6)
                        .focused($nameFocused)
                } footer: {
                    Text("This workout plan will appear in Favorite timers.")
                        .minimumScaleFactor(0.6)
                }
            }
            .navigationTitle("Save to favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticService.shared.impact()
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticService.shared.impact()
                        onSave(name)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                nameFocused = true
            }
        }
    }
}

#Preview {
    SaveFavoriteParametersSheet(onCancel: {}, onSave: { _ in })
}
