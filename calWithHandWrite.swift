import SwiftUI
import Vision
import PencilKit

struct ContentView: View {
    @State private var displayText = "0"
    @State private var currentOperation: String? = nil
    @State private var firstNumber: Double? = nil
    @State private var newNumber = true
    @State private var canvasView = PKCanvasView()
    @State private var recognizedText = ""
    
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
                // 手寫區域
                CanvasView(canvasView: $canvasView)
                    .frame(height: 200)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding()
                
                Button("辨識") {
                    recognizeHandwriting()
                }
                .foregroundColor(.white)
                .padding()
                
                // 計算機顯示區
                HStack {
                    Spacer()
                    Text(displayText)
                        .foregroundColor(.white)
                        .font(.system(size: 64))
                        .padding()
                }
                
                // 按鈕區域
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
    }
    
    private func recognizeHandwriting() {
        let drawing = canvasView.drawing
        let image = drawing.image(from: drawing.bounds, scale: 1.0)
        
        guard let cgImage = image.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                if let firstString = recognizedStrings.first {
                    handleRecognizedText(firstString)
                }
            }
        }
        
        try? requestHandler.perform([request])
    }
    
    private func handleRecognizedText(_ text: String) {
        // 清除畫布
        canvasView.drawing = PKDrawing()
        
        // 處理運算符號
        if operators.contains(text) || text == "-" || text == "=" {
            buttonPressed(text)
        } else if let number = Double(text) {
            // 處理數字
            if newNumber {
                displayText = text
                newNumber = false
            } else {
                displayText = displayText == "0" ? text : displayText + text
            }
        }
    }
    
    // 其他原有方法保持不變...
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.backgroundColor = .white
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
