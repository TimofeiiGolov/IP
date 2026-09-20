// File: Pishi/Views/Components/SaveStatusView.swift
import SwiftUI

/// Индикатор статуса сохранения: «Сохранено», «Сохранение…», ошибка.
struct SaveStatusView: View {
    let status: SaveStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(status.displayText)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .accessibilityIdentifier(Constants.Accessibility.saveStatus)
        .accessibilityLabel(Text("Статус сохранения: \(status.displayText)"))
    }

    private var iconName: String {
        switch status {
        case .saved: return "checkmark.circle.fill"
        case .saving: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch status {
        case .saved: return .secondary
        case .saving: return .orange
        case .error: return .red
        }
    }
}

#Preview {
    VStack {
        SaveStatusView(status: .saved(.now))
        SaveStatusView(status: .saving)
        SaveStatusView(status: .error("Ошибка"))
    }
}
