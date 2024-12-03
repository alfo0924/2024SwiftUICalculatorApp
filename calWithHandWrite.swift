import SwiftUI
import Vision
import PencilKit

struct ContentView: View {
    @State private var displayText = "0"
    @State private var currentOperation: String? = nil
    @State private var firstNumber: Double? = nil
    @State private var newNumber = true
    @State private var canvasView = PKCanvasView()
    
    // 計算機按鈕配置
    private let buttons: [[CalcButton]] = [
        [.clear, .negative, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equal]
    ]
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                // 手寫區域
                CanvasView(canvasView: $canvasView)
                    .frame(height: 150)
                    .background(Color.white)
                    .cornerRadius(15)
                    .padding()
                
                Button(action: recognizeHandwriting) {
                    Text("辨識")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Spacer()
                
                // 顯示區
                HStack {
                    Spacer()
                    Text(displayText)
                        .bold()
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                        .padding()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                
                // 按鈕區域
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            CalculatorButton(button: button, action: { self.buttonTapped(button) })
                        }
                    }
                }
            }
            .padding(.bottom)
        }
    }
    
    private func buttonTapped(_ button: CalcButton) {
        switch button {
        case .clear:
            displayText = "0"
            currentOperation = nil
            firstNumber = nil
            newNumber = true
        case .negative:
            if let value = Double(displayText) {
                displayText = String(-value)
            }
        case .percent:
            if let value = Double(displayText) {
                displayText = String(value / 100)
            }
        case .equal:
            calculateResult()
        case .add, .subtract, .multiply, .divide:
            if let value = Double(displayText) {
                firstNumber = value
                currentOperation = button.rawValue
                newNumber = true
            }
        case .decimal:
            if !displayText.contains(".") {
                displayText = displayText + "."
            }
        default:
            if newNumber {
                displayText = button.rawValue
                newNumber = false
            } else {
                displayText = displayText == "0" ? button.rawValue : displayText + button.rawValue
            }
        }
    }
    
    private func calculateResult() {
        if let operation = currentOperation,
           let first = firstNumber,
           let second = Double(displayText) {
            
            let result: Double
            
            switch operation {
            case "+": result = first + second
            case "-": result = first - second
            case "×": result = first * second
            case "÷": result = first / second
            default: return
            }
            
            displayText = formatResult(result)
            currentOperation = nil
            firstNumber = nil
            newNumber = true
        }
    }
    
    private func formatResult(_ result: Double) -> String {
        if result.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", result)
        } else {
            return String(format: "%.2f", result)
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
                canvasView.drawing = PKDrawing()
            }
        }
        
        try? requestHandler.perform([request])
    }
    
    private func handleRecognizedText(_ text: String) {
        let operatorMap = [
            "+" : CalcButton.add,
            "-" : CalcButton.subtract,
            "×" : CalcButton.multiply,
            "÷" : CalcButton.divide,
            "=" : CalcButton.equal
        ]
        
        if let calcButton = operatorMap[text] {
            buttonTapped(calcButton)
        } else if let number = Double(text) {
            displayText = newNumber ? String(number) : displayText + String(number)
            newNumber = false
        }
    }
}

// 計算機按鈕樣式
struct CalculatorButton: View {
    let button: CalcButton
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(button.rawValue)
                .font(.system(size: 32))
                .frame(width: buttonWidth(), height: buttonHeight())
                .background(button.backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(buttonHeight()/2)
        }
    }
    
    private func buttonWidth() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 12 * 5
        let regularWidth = (screenWidth - spacing) / 4
        return button == .zero ? regularWidth * 2 + 12 : regularWidth
    }
    
    private func buttonHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - 12 * 5) / 4
    }
}

// 手寫畫布視圖
struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.backgroundColor = .white
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// 計算機按鈕列舉
enum CalcButton: String, Hashable {
    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case decimal = "."
    case equal = "=", add = "+", subtract = "-", multiply = "×", divide = "÷"
    case clear = "AC", negative = "±", percent = "%"
    
    var backgroundColor: Color {
        switch self {
        case .clear, .negative, .percent:
            return .gray
        case .add, .subtract, .multiply, .divide, .equal:
            return .orange
        default:
            return Color(.darkGray)
        }
    }
}
