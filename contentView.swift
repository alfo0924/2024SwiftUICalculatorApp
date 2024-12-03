import SwiftUI

struct ContentView: View {
    @State private var displayText = "0"
    @State private var currentOperation: String? = nil
    @State private var firstNumber: Double? = nil
    @State private var newNumber = true
    
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
    }
    
    private func buttonWidth(_ button: String) -> CGFloat {
        if button == "0" {
            return ((UIScreen.main.bounds.width - 5 * 12) / 4) * 2
        }
        return (UIScreen.main.bounds.width - 5 * 12) / 4
    }
    
    private func buttonHeight() -> CGFloat {
        return (UIScreen.main.bounds.width - 5 * 12) / 4
    }
    
    private func buttonColor(_ button: String) -> Color {
        if button == "AC" || button == "±" {
            return .red
        }
        
        if button == "-" || operators.contains(button) {
            return .orange
        }
        
        if button == "=" {
            return .orange
        }
        
        return .gray
    }
    
    private func buttonPressed(_ button: String) {
        switch button {
        case "AC":
            displayText = "0"
            currentOperation = nil
            firstNumber = nil
            newNumber = true
        case "±":
            if let value = Double(displayText) {
                displayText = String(-value)
            }
        case "%":
            if let value = Double(displayText) {
                displayText = String(value / 100)
            }
        case "=":
            calculateResult()
        case "+", "-", "×", "÷":
            if let value = Double(displayText) {
                firstNumber = value
                currentOperation = button
                newNumber = true
            }
        case ".":
            if !displayText.contains(".") {
                displayText = displayText + "."
            }
        default:
            if newNumber {
                displayText = button
                newNumber = false
            } else {
                displayText = displayText == "0" ? button : displayText + button
            }
        }
    }
    
    private func calculateResult() {
        if let operation = currentOperation,
           let first = firstNumber,
           let second = Double(displayText) {
            
            let result: Double
            
            switch operation {
            case "+":
                result = first + second
            case "-":
                result = first - second
            case "×":
                result = first * second
            case "÷":
                result = first / second
            default:
                return
            }
            
            displayText = String(result)
            currentOperation = nil
            firstNumber = nil
            newNumber = true
        }
    }
}
