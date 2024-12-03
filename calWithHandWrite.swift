import SwiftUI
import Vision
import VisionKit
import PencilKit

struct ContentView: View {
    @State private var displayText = "0"
    @State private var currentOperation: String? = nil
    @State private var firstNumber: Double? = nil
    @State private var newNumber = true
    @State private var isShowingScanner = false
    @State private var isShowingDrawing = false
    @State private var canvasView = PKCanvasView()
    
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
                    Button(action: {
                        isShowingDrawing = true
                    }) {
                        Image(systemName: "pencil.tip")
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
        .sheet(isPresented: $isShowingDrawing) {
            DrawingView(recognizedText: $displayText, isPresented: $isShowingDrawing)
        }
    }
    
    // 原有的其他函數保持不變...
}

struct DrawingView: View {
    @Binding var recognizedText: String
    @Binding var isPresented: Bool
    @State private var canvasView = PKCanvasView()
    @State private var drawingImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack {
                CanvasView(canvasView: $canvasView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                HStack {
                    Button("清除") {
                        canvasView.drawing = PKDrawing()
                    }
                    .padding()
                    
                    Button("辨識") {
                        recognizeDrawing()
                    }
                    .padding()
                }
            }
            .navigationBarItems(trailing: Button("完成") {
                isPresented = false
            })
        }
    }
    
    private func recognizeDrawing() {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        
        guard let cgImage = image.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                processRecognizedText(recognizedStrings.joined())
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "zh-Hant", "zh-Hans"]
        request.usesLanguageCorrection = true
        
        try? requestHandler.perform([request])
    }
    
    private func processRecognizedText(_ text: String) {
        // 處理數學運算符號
        var processedText = text
            .replacingOccurrences(of: "x", with: "×")
            .replacingOccurrences(of: "X", with: "×")
            .replacingOccurrences(of: "÷", with: "÷")
            .replacingOccurrences(of: "/", with: "÷")
            .replacingOccurrences(of: "+", with: "+")
            .replacingOccurrences(of: "-", with: "-")
            .replacingOccurrences(of: "%", with: "%")
        
        // 移除空白字符
        processedText = processedText.filter { !$0.isWhitespace }
        
        // 如果是純數字，直接更新顯示
        if let _ = Double(processedText) {
            recognizedText = processedText
            isPresented = false
            return
        }
        
        // 處理數學表達式
        if let result = evaluateExpression(processedText) {
            recognizedText = String(result)
            isPresented = false
        }
    }
    
    private func evaluateExpression(_ expression: String) -> Double? {
        // 這裡可以添加更複雜的數學表達式求值邏輯
        // 目前僅支援基本運算
        let expr = NSExpression(format: expression)
        return expr.expressionValue(with: nil, context: nil) as? Double
    }
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
