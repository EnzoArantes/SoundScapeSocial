import SwiftUI
import FirebaseAuth

struct EmailAuthView: View {
  @State private var email = ""
  @State private var password = ""
  @State private var errorMessage: String?
  @State private var isSigningUp = false

  var body: some View {
    ZStack {
      Color.backgroundDark
        .ignoresSafeArea()

      VStack(spacing: 16) {
        Text("Welcome to SoundScape Social")
          .font(.title2)
          .bold()
          .foregroundColor(.primaryPurple)

        TextField("Email", text: $email)
          .textContentType(.emailAddress)
          .keyboardType(.emailAddress)
          .autocapitalization(.none)
          .padding()
          .background(Color.secondaryPurple)
          .foregroundColor(.textColor)
          .cornerRadius(8)

        SecureField("Password", text: $password)
          .textContentType(.newPassword)
          .padding()
          .background(Color.secondaryPurple)
          .foregroundColor(.textColor)
          .cornerRadius(8)

        if let err = errorMessage {
          Text(err)
            .foregroundColor(.red)
            .font(.caption)
        }

        Button(isSigningUp ? "Sign Up" : "Sign In") {
          errorMessage = nil
          if isSigningUp {
            signUp()
          } else {
            signIn()
          }
        }
        .padding()
        .background(Color.primaryPurple)
        .foregroundColor(.textColor)
        .cornerRadius(8)
        .disabled(email.isEmpty || password.count < 6)

        Button(isSigningUp ? "Have an account? Sign In" : "Create an account") {
          isSigningUp.toggle()
          errorMessage = nil
        }
        .font(.caption)
        .foregroundColor(.secondaryPurple)
        .padding(.top, 4)
      }
      .padding()
    }
  }

  private func signUp() {
    Auth.auth().createUser(withEmail: email, password: password) { result, error in
      if let error = error {
        errorMessage = error.localizedDescription
      }
    }
  }

  private func signIn() {
    Auth.auth().signIn(withEmail: email, password: password) { result, error in
      if let error = error {
        errorMessage = error.localizedDescription
      }
    }
  }
}

#Preview {
    EmailAuthView()
}
