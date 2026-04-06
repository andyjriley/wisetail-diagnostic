//
//  DiagnosticAIService.swift
//  wisetail-dashboard
//
//  Manages the LanguageModelSession for the diagnostic AI assistant,
//  including streaming responses and conversation state.
//

import Foundation
import FoundationModels
import Observation

@Observable
@MainActor
class DiagnosticAIService {

    // MARK: - State

    var messages: [ChatMessage] = []
    var isResponding = false
    var currentStreamText = ""
    var errorMessage: String?

    private var session: LanguageModelSession?
    private weak var dataProvider: (any DiagnosticDataProvider)?

    // MARK: - Availability

    var modelAvailability: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }

    var isAvailable: Bool {
        if case .available = modelAvailability { return true }
        return false
    }

    var unavailableReason: String? {
        switch modelAvailability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence is not enabled. Please enable it in System Settings > Apple Intelligence & Siri."
            case .modelNotReady:
                return "The on-device model is not ready yet. It may still be downloading. Please try again later."
            case .deviceNotEligible:
                return "This device does not support Apple Intelligence."
            @unknown default:
                return "Apple Intelligence is not available on this device."
            }
        @unknown default:
            return "Apple Intelligence is not available."
        }
    }

    // MARK: - Setup

    /// Creates a new session configured for the given diagnostic bundle.
    func setupSession(bundle: DiagnosticBundle, viewModel: DashboardViewModel) {
        dataProvider = viewModel

        let context = BundleContextBuilder.buildContext(from: bundle, viewModel: viewModel)

        let instructions = """
        You are a diagnostic support assistant for the WiseLync mobile app.
        You have access to a diagnostic bundle from a user's device.
        Your job is to analyze the data to help customer support identify issues, errors, and sync problems.
        Be concise and actionable in your responses. When referencing data, cite specific values.
        If data has not been loaded yet, mention that the user may need to visit the relevant tab first to load it.

        You have tools available to search logs, get recent errors, view sync states, and check API errors.
        Use these tools when you need specific data to answer a question.

        DEVICE CONTEXT:
        \(context)
        """

        let searchLogs = SearchLogsTool(dataProvider: viewModel)
        let getErrors = GetRecentErrorsTool(dataProvider: viewModel)
        let getSyncStates = GetSyncStatesTool(dataProvider: viewModel)
        let getAPIErrors = GetAPIErrorsTool(dataProvider: viewModel)

        session = LanguageModelSession(
            tools: [searchLogs, getErrors, getSyncStates, getAPIErrors],
            instructions: instructions
        )

        messages = []
        errorMessage = nil
        currentStreamText = ""
    }

    // MARK: - Send Message

    /// Sends a user message and streams the AI response.
    func send(_ prompt: String) async {
        guard let session else {
            errorMessage = "AI session not initialized. Please load a diagnostic bundle first."
            return
        }

        // Append user message
        messages.append(ChatMessage(role: .user, content: prompt))
        isResponding = true
        currentStreamText = ""
        errorMessage = nil

        do {
            let stream = session.streamResponse(to: prompt)
            for try await partial in stream {
                currentStreamText = partial.content
            }

            // Finalize
            let finalText = currentStreamText
            messages.append(ChatMessage(role: .assistant, content: finalText))
            currentStreamText = ""
        } catch {
            errorMessage = "AI error: \(error.localizedDescription)"
            if !currentStreamText.isEmpty {
                messages.append(ChatMessage(role: .assistant, content: currentStreamText))
                currentStreamText = ""
            }
        }

        isResponding = false
    }

    // MARK: - Reset

    func reset() {
        session = nil
        messages = []
        currentStreamText = ""
        errorMessage = nil
        isResponding = false
    }
}
