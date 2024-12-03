import SwiftUI
import VisionKit

struct ContentView: View {
    @State private var displayText = "0"
    @State private var currentOperation: String? = nil
    @State private var firstNumber: Double? = nil
    @State private var newNumber = true
    @State private var isShowingScanner = false
    
    let buttons: [[String]] = [
        ["AC", "±", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
        ["0", ".", "="]
    ]
    
    let operators = ["÷", "+", "×", "%"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isShowingScanner = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Text(displayText)
                        .foregroundColor(.white)
                        .font(.system(size: 64))
                        .padding()
                }
                
                ForEach(buttons, id: \.self) { row in
                    HStack {
                        ForEach(row, id: \.self) { button in
                            Button(action: {
                                self.buttonPressed(button)
                            }) {
                                Text(button)
                                    .font(.system(size: 32))
                                    .frame(width: self.buttonWidth(button),
                                           height: self.buttonHeight())
                                    .background(self.buttonColor(button))
                                    .foregroundColor(.white)
                                    .cornerRadius(40)
                            }
                        }
                    }
                }
            }
            .padding(.bottom)
        }
        .sheet(isPresented: $isShowingScanner) {
            ScannerView(recognizedText: $displayText)
        }
    }
    
    // 原有的其他函數保持不變
    // buttonWidth, buttonHeight, buttonColor, buttonPressed, calculateResult
}

struct ScannerView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedText: $recognizedText, parent: self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let recognizedText: Binding<String>
        let parent: ScannerView
        
        init(recognizedText: Binding<String>, parent: ScannerView) {
            self.recognizedText = recognizedText
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let image = scan.imageOfPage(at: 0)
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                let text = observations.compactMap({ $0.topCandidates(1).first?.string }).joined()
                if let number = Double(text) {
                    DispatchQueue.main.async {
                        self.recognizedText.wrappedValue = String(number)
                        self.parent.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            
            try? VNImageRequestHandler(cgImage: image.cgImage!, options: [:]).perform([request])
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
