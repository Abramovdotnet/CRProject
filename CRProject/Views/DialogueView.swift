import SwiftUI

struct DialogueView: View {
    @ObservedObject var viewModel: DialogueViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .center, spacing: 8) {
                    Text("Blood: \(Int(viewModel.npc.bloodMeter.bloodPercentage))%")
                        .font(Theme.bodyFont)
                    ProgressBar(value: Double(viewModel.npc.bloodMeter.bloodPercentage / 100.0), color: Theme.bloodProgressColor)
                }.padding(.top, 10)
                HStack {
                    VStack(alignment: .leading) {
                        Text(viewModel.npc.name)
                            .font(Theme.headingFont)
                        Text("Age: \(viewModel.npc.age)")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textColor.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text(viewModel.npc.sex == .male ? "Male" : "Female")
                            .font(Theme.headingFont)
                        Text(viewModel.npc.profession.rawValue.capitalized)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textColor.opacity(0.7))
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.textColor.opacity(0.7))
                            .font(.title2)
                    }
     
                }
                .padding()
                .background(Theme.secondaryColor)
                
                // Dialogue Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Current Dialogue Text
                        if !viewModel.currentDialogueText.isEmpty {
                            Text(viewModel.currentDialogueText)
                                .font(Theme.bodyFont)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.primaryColor.opacity(0.5))
                                .cornerRadius(8)
                        }
                        
                        // Options
                        if !viewModel.options.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(viewModel.options) { option in
                                    DialogueOptionButton(option: option) {
                                        viewModel.selectOption(option)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // Action Result Overlay
            if viewModel.showActionResult {
                VStack {
                    Text(viewModel.actionResultMessage)
                        .font(Theme.headingFont)
                        .foregroundColor(viewModel.actionResultSuccess ? .green : .red)
                        .padding()
                        .background(Theme.secondaryColor)
                        .cornerRadius(8)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut, value: viewModel.showActionResult)
            }
        }
        .foregroundColor(Theme.textColor)
    }
}

private struct DialogueOptionButton: View {
    let option: DialogueOption
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.text)
                    .font(Theme.bodyFont)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if option.type != .normal {
                    Image(systemName: option.type == .intimidate ? "exclamationmark.triangle" : "heart")
                        .foregroundColor(option.type == .intimidate ? .red : .pink)
                }
            }
            .padding()
            .background(Theme.secondaryColor.opacity(0.5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
