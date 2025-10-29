import SwiftUI

struct LanguageSelectionView: View {
    @ObservedObject var languageManager = LanguageManager.shared
    @Binding var isPresented: Bool
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("welcome".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("choose_language".localized)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(languageManager.availableLanguages, id: \.code) { language in
                        Button(action: {
                            languageManager.currentLanguage = language.code
                        }) {
                            HStack {
                                Text(language.name)
                                    .font(.headline)
                                
                                Spacer()
                                
                                if languageManager.currentLanguage == language.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            
            Button(action: {
                languageManager.setLanguageChosen()
                isPresented = false
                onComplete()
            }) {
                Text("continue".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
}

