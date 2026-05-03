import SwiftUI

// MARK: - PrimaryButtonStyle
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline).foregroundStyle(.white)
            .padding(.vertical, 14).frame(maxWidth: .infinity)
            .background(isEnabled ? Color("AccentGreen") : Color(.systemGray4),
                        in: RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Light Input Fields (for forms on light background)
struct FFTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Color("AccentGreen")).frame(width: 20)
            TextField(placeholder, text: $text).foregroundStyle(.primary)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct FFSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock").foregroundStyle(Color("AccentGreen")).frame(width: 20)
            if showPassword { TextField(placeholder, text: $text) }
            else { SecureField(placeholder, text: $text) }
            Button { showPassword.toggle() } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye").foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - StatCard
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon).foregroundStyle(color).font(.title3)
                Spacer()
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Text(value).font(.title3.bold()).minimumScaleFactor(0.7).lineLimit(1)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - ErrorBanner
struct ErrorBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
            Text(message).font(.caption).foregroundStyle(.red).multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - LoadingOverlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.4).tint(.white)
                Text("Loading…").foregroundStyle(.white).font(.subheadline)
            }
            .padding(28).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Toast
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var isSuccess: Bool = true
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if let msg = message {
                HStack(spacing: 8) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    Text(msg).font(.subheadline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(isSuccess ? Color.green : Color.red, in: Capsule())
                .padding(.bottom, 20).shadow(radius: 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { message = nil } } }
            }
        }
        .animation(.spring(), value: message)
    }
}
extension View {
    func toast(message: Binding<String?>, isSuccess: Bool = true) -> some View {
        modifier(ToastModifier(message: message, isSuccess: isSuccess))
    }
}

// MARK: - DeleteConfirmation Alert Modifier
struct DeleteConfirmModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content.alert(title, isPresented: $isPresented) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(message)
        }
    }
}
extension View {
    func deleteConfirm(isPresented: Binding<Bool>, title: String = "Confirm Delete",
                       message: String, onDelete: @escaping () -> Void) -> some View {
        modifier(DeleteConfirmModifier(isPresented: isPresented, title: title, message: message, onDelete: onDelete))
    }
}

// MARK: - Helpers
func formatAmount(_ val: Double) -> String {
    if val >= 100_000 {
        let l = val / 100_000
        return l.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(l))L" : String(format: "%.1fL", l)
    }
    let n = NumberFormatter()
    n.numberStyle = .decimal; n.maximumFractionDigits = 0
    return n.string(from: NSNumber(value: val)) ?? "\(Int(val))"
}

func categoryColor(_ cat: String) -> Color {
    switch cat {
    case "Food":          return .orange
    case "Housing":       return .blue
    case "Transport":     return .purple
    case "Shopping":      return .pink
    case "Entertainment": return .cyan
    case "Utilities":     return .yellow
    case "Healthcare":    return .red
    case "Salary":        return .green
    case "Freelance":     return Color(red: 0.19, green: 0.69, blue: 0.78)
    case "Investment":    return Color(red: 0.35, green: 0.34, blue: 0.84)
    default:              return .gray
    }
}
