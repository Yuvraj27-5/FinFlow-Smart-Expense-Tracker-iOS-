import SwiftUI

// MARK: - Color Hex Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Dark Input Fields
struct DarkTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("AccentGreen")).frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundStyle(.white).tint(Color("AccentGreen"))
                .keyboardType(keyboardType).autocapitalization(.none)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.18), lineWidth: 1))
    }
}

struct DarkSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundStyle(Color("AccentGreen")).frame(width: 20)
            if showPassword {
                TextField(placeholder, text: $text).foregroundStyle(.white).tint(Color("AccentGreen"))
            } else {
                SecureField(placeholder, text: $text).foregroundStyle(.white).tint(Color("AccentGreen"))
            }
            Button { showPassword.toggle() } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye").foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - LoginView
struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var goRegister = false
    @State private var goForgot = false
    @State private var logoScale: CGFloat = 0.7
    @State private var cardOffset: CGFloat = 50
    @State private var cardOpacity: Double = 0
    @State private var f1: CGFloat = 0
    @State private var f2: CGFloat = 0
    @State private var f3: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(colors: [Color(hex: "#0B1120"), Color(hex: "#0D1B2A"), Color(hex: "#0B1120")],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                // Decorative circles
                Circle().stroke(Color("AccentGreen").opacity(0.07), lineWidth: 1)
                    .frame(width: 240).offset(x: -110, y: -300)
                Circle().stroke(Color.white.opacity(0.04), lineWidth: 1)
                    .frame(width: 180).offset(x: 150, y: 200)
                // Floating symbols
                Group {
                    Text("₹").font(.system(size: 44)).foregroundStyle(Color("AccentGreen").opacity(0.10))
                        .offset(x: -145, y: -130 + f1)
                    Text("%").font(.system(size: 30)).foregroundStyle(.white.opacity(0.07))
                        .offset(x: 140, y: -70 + f2)
                    Text("+").font(.system(size: 26)).foregroundStyle(Color("AccentGreen").opacity(0.09))
                        .offset(x: 10, y: -160 + f3)
                    Text("₹").font(.system(size: 55)).foregroundStyle(.white.opacity(0.04))
                        .offset(x: 130, y: 90 + f1)
                    Text("$").font(.system(size: 22)).foregroundStyle(.white.opacity(0.06))
                        .offset(x: -130, y: 110 + f2)
                }
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Logo
                        VStack(spacing: 10) {
                            Text("💸").font(.system(size: 64))
                                .scaleEffect(logoScale)
                                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: logoScale)
                            Text("FinFlow")
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Personal Finance Tracker")
                                .font(.subheadline).foregroundStyle(.white.opacity(0.45))
                        }
                        .padding(.top, 60).padding(.bottom, 36)

                        // Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Welcome Back").font(.title2.bold()).foregroundStyle(.white)
                            DarkTextField(icon: "envelope", placeholder: "Email address", text: $email, keyboardType: .emailAddress)
                            DarkSecureField(placeholder: "Password", text: $password, showPassword: $showPassword)
                            if let err = authVM.errorMessage { ErrorBanner(message: err) }
                            Button(action: { Task { await authVM.login(email: email, password: password) } }) {
                                if authVM.isLoading { ProgressView().tint(.white).frame(maxWidth: .infinity) }
                                else { Text("Sign In").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity) }
                            }
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color("AccentGreen"), Color(hex: "#7B77F0")],
                                               startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 14))
                            .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)
                            .opacity(email.isEmpty || password.isEmpty ? 0.55 : 1)
                            Button("Forgot Password?") { goForgot = true }
                                .font(.subheadline).foregroundStyle(.white.opacity(0.45)).frame(maxWidth: .infinity)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.07))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.13), lineWidth: 1))
                        )
                        .padding(.horizontal, 20)
                        .offset(y: cardOffset).opacity(cardOpacity)

                        HStack(spacing: 4) {
                            Text("Don't have an account?").foregroundStyle(.white.opacity(0.45))
                            Button("Sign Up") { goRegister = true }.fontWeight(.bold).foregroundStyle(Color("AccentGreen"))
                        }
                        .font(.subheadline).padding(.top, 28).padding(.bottom, 40)
                    }
                }
            }
            .navigationDestination(isPresented: $goRegister) { RegisterView() }
            .navigationDestination(isPresented: $goForgot)   { ForgotPasswordView() }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { logoScale = 1 }
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) { cardOffset = 0; cardOpacity = 1 }
                withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { f1 = -22 }
                withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true).delay(0.7)) { f2 = -28 }
                withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true).delay(1.2)) { f3 = -16 }
            }
        }
    }
}

// MARK: - RegisterView
struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0B1120"), Color(hex: "#0D1B2A")],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 10) {
                        Text("💸").font(.system(size: 54))
                        Text("Create Account").font(.system(size: 28, weight: .heavy)).foregroundStyle(.white)
                        Text("Start tracking your finances today").font(.subheadline).foregroundStyle(.white.opacity(0.45))
                    }.padding(.top, 40).padding(.bottom, 32)

                    VStack(alignment: .leading, spacing: 18) {
                        DarkTextField(icon: "person", placeholder: "Full Name", text: $name)
                        DarkTextField(icon: "envelope", placeholder: "Email address", text: $email, keyboardType: .emailAddress)
                        DarkSecureField(placeholder: "Password (min 6 chars)", text: $password, showPassword: $showPassword)
                        if let err = authVM.errorMessage { ErrorBanner(message: err) }
                        Button(action: { Task { await authVM.register(name: name, email: email, password: password) } }) {
                            if authVM.isLoading { ProgressView().tint(.white).frame(maxWidth: .infinity) }
                            else { Text("Create Account").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity) }
                        }
                        .padding(.vertical, 14)
                        .background(Color("AccentGreen"), in: RoundedRectangle(cornerRadius: 14))
                        .disabled(name.isEmpty || email.isEmpty || password.count < 6 || authVM.isLoading)
                        .opacity(name.isEmpty || email.isEmpty || password.count < 6 ? 0.55 : 1)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.07))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.13), lineWidth: 1))
                    )
                    .padding(.horizontal, 20)
                    Button("Already have an account? Sign In") { dismiss() }
                        .font(.subheadline).foregroundStyle(.white.opacity(0.45)).padding(.top, 24).padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Sign Up").navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - ForgotPasswordView
struct ForgotPasswordView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var sent = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#0B1120"), Color(hex: "#0D1B2A")],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text("🔐").font(.system(size: 54))
                        Text("Reset Password").font(.system(size: 26, weight: .heavy)).foregroundStyle(.white)
                        Text("Enter your email and we'll send a reset link.")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.45)).multilineTextAlignment(.center)
                    }.padding(.top, 60)
                    if sent {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundStyle(Color("AccentGreen"))
                            Text("Email Sent!").font(.title2.bold()).foregroundStyle(.white)
                            Text(authVM.successMessage ?? "Check your inbox.").multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.6))
                            Button("Back to Sign In") { dismiss() }.font(.headline).foregroundStyle(.white)
                                .padding(.vertical, 14).frame(maxWidth: .infinity)
                                .background(Color("AccentGreen"), in: RoundedRectangle(cornerRadius: 14))
                        }.padding()
                    } else {
                        VStack(spacing: 18) {
                            DarkTextField(icon: "envelope", placeholder: "Email address", text: $email, keyboardType: .emailAddress)
                            if let err = authVM.errorMessage { ErrorBanner(message: err) }
                            Button(action: { Task { let ok = await authVM.forgotPassword(email: email); if ok { sent = true } } }) {
                                if authVM.isLoading { ProgressView().tint(.white).frame(maxWidth: .infinity) }
                                else { Text("Send Reset Link").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity) }
                            }
                            .padding(.vertical, 14).background(Color("AccentGreen"), in: RoundedRectangle(cornerRadius: 14))
                            .disabled(email.isEmpty || authVM.isLoading)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.07))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.13), lineWidth: 1))
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .navigationTitle("Forgot Password").navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}