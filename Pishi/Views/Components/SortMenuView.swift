// File: Pishi/Views/Components/SortMenuView.swift
import SwiftUI

/// Меню выбора сортировки заметок.
struct SortMenuView: View {
    @Binding var selection: SortOption

    var body: some View {
        Picker(String(localized: "Сортировка"), selection: $selection) {
            ForEach(SortOption.allCases) { option in
                Label(option.localizedName, systemImage: option.systemImage)
                    .tag(option)
            }
        }
        .accessibilityIdentifier(Constants.Accessibility.sortMenu)
    }
}

#Preview {
    SortMenuView(selection: .constant(.pinnedFirst))
}
