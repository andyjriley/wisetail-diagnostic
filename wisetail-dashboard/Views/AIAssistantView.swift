//
//  AIAssistantView.swift
//  wisetail-dashboard
//
//  AI-powered diagnostic assistant with chat interface, quick actions,
//  and streaming responses using the Foundation Models framework.
//

import SwiftUI
import FoundationModels

struct AIAssistantView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @State private var aiService = DiagnosticAIService()
    @State private var inputText = ""
    @State private var scrollProxy: ScrollViewProxy?

    // Quick action prompts for customer support
    private let quickActions: [(label: String, icon: String, prompt: String)] = [
        ("Device Health", "heart.text.clipboard", "Summarize this device's overall health and highlight any concerns."),
        ("Recent Errors", "exclamationmark.triangle", "What errors occurred recently? List the most important ones and suggest causes."),
        ("Sync Issues", "arrow.triangle.2.circlepath", "Why might sync be failing? Analyze the sync states and failure reasons."),
        ("API Problems", "network", "Are there any API connectivity issues? Check for error patterns in API calls."),
        ("Crash Indicators", "bolt.trianglebadge.exclamationmark", "Check for any crash indicators or critical failures in the logs."),
        ("Device Config", "gearshape", "What is the device and app configuration? Summarize the key settings."),
    ]

    var body: some View {
        Group {
            if !aiService.isAvailable {
                unavailableView
            } else {
                chatView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            initializeSession()
        }
        .onChange(of: viewModel.bundle?.sourceURL) { _, _ in
            initializeSession()
        }
    }

    // MARK: - Unavailable View

    private var unavailableView: some View {
        ContentUnavailableView {
            Label("Apple Intelligence Required", systemImage: "brain")
        } description: {
            Text(aiService.unavailableReason ?? "Apple Intelligence is not available on this device.")
        }
    }

    // MARK: - Chat View

    private var chatView: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Quick Actions (shown when no messages yet)
                        if aiService.messages.isEmpty && !aiService.isResponding {
                            quickActionsSection
                        }

                        // Messages
                        ForEach(aiService.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }

                        // Streaming response
                        if aiService.isResponding && !aiService.currentStreamText.isEmpty {
                            ChatBubbleView(message: ChatMessage(
                                role: .assistant,
                                content: aiService.currentStreamText
                            ))
                            .opacity(0.85)
                            .id("streaming")
                        }

                        // Typing indicator
                        if aiService.isResponding && aiService.currentStreamText.isEmpty {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("typing")
                        }

                        // Error
                        if let error = aiService.errorMessage {
                            HStack {
                                Label(error, systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .padding(8)
                                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .onAppear { scrollProxy = proxy }
                .onChange(of: aiService.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: aiService.currentStreamText) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            Divider()

            // Input bar
            inputBar
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Welcome header
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "brain")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("AI Diagnostic Assistant")
                        .font(.title2.weight(.semibold))
                }
                Text("Ask questions about this diagnostic bundle or select a quick action below.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Quick action chips
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                ForEach(quickActions, id: \.label) { action in
                    Button {
                        sendMessage(action.prompt)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.body)
                                .frame(width: 24)
                            Text(action.label)
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            // Divider label
            HStack {
                VStack { Divider() }
                Text("or type a question below")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                VStack { Divider() }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask about this diagnostic bundle...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(10)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                .onSubmit {
                    if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                        sendMessage(inputText)
                    }
                }
                .disabled(aiService.isResponding)

            Button {
                sendMessage(inputText)
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundColor(canSend ? Color.accentColor : Color.gray)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .keyboardShortcut(.return, modifiers: .command)

            if !aiService.messages.isEmpty {
                Button {
                    aiService.reset()
                    initializeSession()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Reset conversation")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !aiService.isResponding
    }

    private func sendMessage(_ text: String) {
        let prompt = text.trimmingCharacters(in: .whitespaces)
        guard !prompt.isEmpty else { return }
        inputText = ""

        Task {
            await aiService.send(prompt)
        }
    }

    private func initializeSession() {
        guard let bundle = viewModel.bundle else { return }
        aiService.setupSession(bundle: bundle, viewModel: viewModel)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if aiService.isResponding {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let last = aiService.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Chat Bubble View

private struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            if message.role == .assistant {
                Image(systemName: "brain")
                    .font(.title3)
                    .foregroundStyle(.purple)
                    .frame(width: 28, height: 28)
                    .background(.purple.opacity(0.1), in: Circle())
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(message.role == .assistant ? .body : .body)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.role == .user
                            ? Color.accentColor.opacity(0.15)
                            : Color.primary.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 12)
                    )

                Text(Self.timeFormatter.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }

            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.horizontal)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain")
                .font(.caption)
                .foregroundStyle(.purple)

            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(dotOpacity(for: index))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                phase = 1.0
            }
        }
    }

    private func dotOpacity(for index: Int) -> Double {
        let offset = Double(index) * 0.3
        return 0.3 + 0.7 * max(0, sin(.pi * (phase - offset)))
    }
}
