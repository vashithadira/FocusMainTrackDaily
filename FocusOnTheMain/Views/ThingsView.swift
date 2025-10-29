import SwiftUI
import WebKit

struct ThingsView: View {
    let link: String
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            DisplayView(link: link, isLoading: $isLoading)
                .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            enableAllOrientations()
        }
    }
    
    private func enableAllOrientations() {
        AppDelegate.orientationLock = .allButUpsideDown
        
        DispatchQueue.main.async {
            if #available(iOS 16.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .allButUpsideDown))
                }
                
                let windows = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                
                windows.forEach { window in
                    window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            } else {
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
}

struct DisplayView: UIViewRepresentable {
    let link: String
    @Binding var isLoading: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let instance = WKWebView(frame: .zero, configuration: configuration)
        instance.navigationDelegate = context.coordinator
        instance.allowsBackForwardNavigationGestures = true
        instance.scrollView.contentInsetAdjustmentBehavior = .never
        
        if let endpoint = URL(string: link) {
            let request = URLRequest(url: endpoint)
            instance.load(request)
        }
        
        return instance
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: DisplayView
        
        init(_ parent: DisplayView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

