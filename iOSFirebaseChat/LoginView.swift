//
//  ContentView.swift
//  iOSFirebaseChat
//
//  Created by Aditt on 20/07/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct LoginView: View {
    
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
    
    @State var shouldShowImagePicker = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView{
            ScrollView{
                VStack(spacing: 16){
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker
                                .toggle()
                        } label: {
                            
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(Color(.label))
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                .stroke(Color.black, lineWidth: 3))
                        }
                    }
                    
                    Group{
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                    .padding(12)
                    .background(Color.white)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(1.2, anchor: .center)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .foregroundColor(.white)
                                    
                                    Text(isLoginMode ? "Logging..." : "Creating Account...")
                                        .foregroundColor(.white)
                                        .padding(.horizontal)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .padding(.vertical,10)
                                
                            } else {
                                Text(isLoginMode ? "Log In" : "Create Account")
                                    .foregroundColor(.white)
                                    .padding(.vertical,10)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Spacer()
                        }.background(Color.blue)
                    }
                    .disabled(isLoading)
                    
//                    Text(self.loginStatusMessage)
//                        .foregroundColor(.red)
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    
    @State var image: UIImage?
    
    private func handleAction(){
        if isLoginMode {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    @State var loginStatusMessage = ""
    @EnvironmentObject var rm: RootModel
    
    private func loginUser() {
        self.isLoading = true
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                print("Failed to login user:", err)
                self.loginStatusMessage = "Failed to login user: \(err)"
                self.isLoading = false
                return
            }
            
            print("Succesfully logged in as user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Succesfully logged in as user: \(result?.user.uid ?? "")"
            self.isLoading = false
            DispatchQueue.main.async {
                self.rm.isUserCurrentlyLoggedOut = false
            }
        }
    }
    
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
            return
        }
        
        self.isLoading = true
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) {
            result, err in
            if let err = err {
                print("Failed to create user:", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                self.isLoading = false
                return
            }
            
            print("Succesfully created user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Succesfully created user: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage () {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) {
            metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err)"
                self.isLoading = false
                return
            }
            
            ref.downloadURL {
                url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                    self.isLoading = false
                    return
                }
                
                self.loginStatusMessage = "Succesfully stored image with url: \(url?.absoluteString ?? "")"
                print(url?.absoluteString as Any)
                
                guard let url = url else { return }
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    self.isLoading = false
                    return
                }
                
                print("Success")
                self.isLoading = false
                DispatchQueue.main.async {
                    self.rm.isUserCurrentlyLoggedOut = false
                }
            }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
