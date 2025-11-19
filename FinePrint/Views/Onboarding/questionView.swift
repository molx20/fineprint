//
//  questionView.swift
//  Swift-Boilerplate
//
//  Created by Will Kusch on 5/31/25.
//

/*
 QUESTION VIEW - FILLER CONTENT IMPLEMENTATION
 
 This is a placeholder question view with filler content for collecting user preferences during onboarding.
 
 **For Novice Developers:**
 - This view shows the structure for collecting user preferences
 - Currently shows filler questions - replace with your actual questions
 - Integrates with the theme system for consistent styling
 - Saves responses to UserDefaults (you can extend to UserManager)
 
 **To Customize:**
 1. Replace filler questions with your actual onboarding questions
 2. Update question titles, descriptions, and answer options
 3. Add different question types (multiple choice, text input, sliders, etc.)
 4. Save responses to your preferred storage system
 5. Use responses to personalize the app experience
 6. Add analytics to track user preferences
 
 **Design Features:**
 - Uses theme colors and fonts for consistency
 - Smooth animations between questions
 - Progress indicator to show completion
 - Clear selection states and feedback
 - Accessible design with proper labeling
 */

import SwiftUI

struct QuestionView: View {
    
    // MARK: - Properties
    
    /// Callback when all questions are completed
    let onComplete: () -> Void
    
    /// Current question index (0-based)
    @State private var currentQuestionIndex = 0
    
    /// User's responses to questions
    @State private var responses: [String: String] = [:]
    
    /// Sample questions (replace with your actual questions)
    private let questions = OnboardingQuestion.sampleQuestions
    
    // MARK: - Computed Properties
    
    /// Current question being displayed
    private var currentQuestion: OnboardingQuestion {
        questions[currentQuestionIndex]
    }
    
    /// Progress percentage (0.0 to 1.0)
    private var progress: Double {
        Double(currentQuestionIndex + 1) / Double(questions.count)
    }
    
    /// Whether we're on the last question
    private var isLastQuestion: Bool {
        currentQuestionIndex == questions.count - 1
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Progress Bar
            VStack(spacing: 16) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.primaryMain))
                    .scaleEffect(y: 2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // MARK: - Question Content
            ScrollView {
                VStack(spacing: 32) {
                    
                    // Question Header
                    VStack(spacing: 16) {
                        // Question icon
                        Image(systemName: currentQuestion.icon)
                            .font(.system(size: 48))
                            .foregroundColor(Color.primaryMain)
                        
                        // Question title
                        Text(currentQuestion.title)
                            .font(.titleLarge)
                            .foregroundColor(Color.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        // Question description
                        if !currentQuestion.description.isEmpty {
                            Text(currentQuestion.description)
                                .font(.bodyMedium)
                                .foregroundColor(Color.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Answer Options
                    VStack(spacing: 12) {
                        ForEach(currentQuestion.options, id: \.self) { option in
                            AnswerOptionView(
                                text: option,
                                isSelected: responses[currentQuestion.id] == option,
                                onTap: {
                                    selectAnswer(option)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 100) // Space for button
                }
            }
            
            // MARK: - Navigation Button
            VStack(spacing: 16) {
                if let selectedAnswer = responses[currentQuestion.id], !selectedAnswer.isEmpty {
                    Button(action: handleContinue) {
                        Text(isLastQuestion ? "Complete Setup" : "Continue")
                    }
                    .buttonStyle(.primary)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.backgroundPrimary)
        .animation(.easeInOut(duration: 0.3), value: currentQuestionIndex)
        .animation(.easeInOut(duration: 0.3), value: responses[currentQuestion.id])
    }
    
    // MARK: - Methods
    
    /// Handles selecting an answer option
    private func selectAnswer(_ answer: String) {
        responses[currentQuestion.id] = answer
        
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Handles continuing to next question or completing
    private func handleContinue() {
        if isLastQuestion {
            completeQuestions()
        } else {
            moveToNextQuestion()
        }
    }
    
    /// Moves to the next question
    private func moveToNextQuestion() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentQuestionIndex += 1
        }
    }
    
    /// Completes all questions and saves responses
    private func completeQuestions() {
        // Save responses to UserDefaults (you can extend this to UserManager)
        saveResponses()
        
        // Add completion haptic feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        // Call completion callback
        onComplete()
    }
    
    /// Saves user responses to storage
    private func saveResponses() {
        for (questionId, response) in responses {
            UserDefaults.standard.set(response, forKey: "onboarding_\(questionId)")
        }
        
        // Optional: Save to UserManager for more advanced user management
        // UserManager.shared.updateUserData(["onboarding_responses": responses])
        
        print("🎯 Onboarding responses saved: \(responses)")
    }
}

// MARK: - Answer Option View

/// Individual answer option component
private struct AnswerOptionView: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .font(.bodyMedium)
                    .foregroundColor(isSelected ? .white : Color.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
                            .background(isSelected ? Color.primaryMain : Color.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primaryMain : Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Question Model

/// Model for onboarding questions
struct OnboardingQuestion {
    let id: String
    let title: String
    let description: String
    let icon: String
    let options: [String]
    
    /// Sample questions for placeholder implementation
    static let sampleQuestions: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: "sample_question_1",
            title: "This is sample question 1",
            description: "Replace this with your actual first question",
            icon: "1.circle.fill",
            options: [
                "Sample answer A",
                "Sample answer B",
                "Sample answer C",
                "Sample answer D"
            ]
        ),
        
        OnboardingQuestion(
            id: "sample_question_2",
            title: "This is sample question 2",
            description: "Replace this with your actual second question",
            icon: "2.circle.fill",
            options: [
                "Option 1",
                "Option 2",
                "Option 3",
                "Option 4"
            ]
        ),
        
        OnboardingQuestion(
            id: "sample_question_3",
            title: "This is sample question 3",
            description: "Replace this with your actual third question",
            icon: "3.circle.fill",
            options: [
                "Choice A",
                "Choice B",
                "Choice C",
                "Choice D"
            ]
        ),
        
        OnboardingQuestion(
            id: "sample_question_4",
            title: "This is the final sample question",
            description: "Replace this with your actual final question",
            icon: "4.circle.fill",
            options: [
                "Final option 1",
                "Final option 2",
                "Final option 3",
                "Final option 4"
            ]
        )
    ]
}

// MARK: - Preview

#Preview("Question View") {
    QuestionView {
        print("Questions completed!")
    }
}

#Preview("Dark Mode") {
    QuestionView {
        print("Questions completed!")
    }
    .preferredColorScheme(.dark)
}
