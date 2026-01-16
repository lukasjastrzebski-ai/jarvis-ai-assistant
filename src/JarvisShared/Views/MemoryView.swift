import SwiftUI
import JarvisCore

/// Memory system view for viewing and managing memories
public struct MemoryView: View {
    @StateObject private var viewModel: MemoryViewModel
    @State private var newMemoryContent = ""
    @State private var newMemoryType: MemoryType = .fact
    @State private var newMemoryCategory: MemoryCategory = .general

    /// Initialize with dependencies
    public init(memoryService: MemoryService, userId: UUID) {
        _viewModel = StateObject(wrappedValue: MemoryViewModel(
            memoryService: memoryService,
            userId: userId
        ))
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Memory")
                .toolbar {
                    toolbarContent
                }
                .searchable(text: $viewModel.searchQuery, prompt: "Search memories...")
                .onChange(of: viewModel.searchQuery) { _, _ in
                    Task {
                        await viewModel.search()
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .sheet(isPresented: $viewModel.showMemoryDetail) {
                    if let memory = viewModel.selectedMemory {
                        MemoryDetailView(memory: memory, viewModel: viewModel)
                    }
                }
                .sheet(isPresented: $viewModel.showAddMemory) {
                    addMemorySheet
                }
        }
        .task {
            await viewModel.loadMemories()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.memories.isEmpty {
            loadingView
        } else if viewModel.memories.isEmpty {
            emptyView
        } else if !viewModel.searchQuery.isEmpty {
            searchResultsView
        } else {
            memoriesList
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading memories...")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Memories Yet")
                .font(.headline)

            Text("Jarvis will learn and remember information as you interact")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                viewModel.showAddMemory = true
            } label: {
                Label("Add Memory", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var searchResultsView: some View {
        List {
            if viewModel.isSearching {
                HStack {
                    ProgressView()
                    Text("Searching...")
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.searchResults.isEmpty {
                Text("No results found")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.searchResults, id: \.memory.id) { result in
                    MemoryRow(memory: result.memory, similarity: Float(result.relevanceScore))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectMemory(result.memory)
                        }
                }
            }
        }
    }

    private var memoriesList: some View {
        List {
            // Error message
            if let error = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.yellow)
                        Text(error)
                            .font(.caption)
                    }
                }
            }

            // Filter chips
            Section {
                filterChips
            }

            // Stats
            Section {
                HStack {
                    Label("\(viewModel.totalCount) memories", systemImage: "brain.head.profile")
                    Spacer()
                    if viewModel.filterCategory != nil || viewModel.filterType != nil {
                        Button("Clear Filters") {
                            viewModel.clearFilters()
                        }
                        .font(.caption)
                    }
                }
            }

            // Grouped memories by category
            ForEach(MemoryCategory.allCases) { category in
                let categoryMemories = viewModel.groupedMemories[category] ?? []
                if !categoryMemories.isEmpty {
                    Section {
                        ForEach(categoryMemories) { memory in
                            MemoryRow(memory: memory)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectMemory(memory)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deactivate(memory)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        categoryHeader(for: category, count: categoryMemories.count)
                    }
                }
            }
        }
    }

    private func categoryHeader(for category: MemoryCategory, count: Int) -> some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundStyle(category.color)
            Text(category.rawValue)
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category filters
                ForEach(MemoryCategory.allCases) { category in
                    filterChip(
                        label: category.rawValue,
                        icon: category.icon,
                        isSelected: viewModel.filterCategory == category
                    ) {
                        viewModel.filterCategory = viewModel.filterCategory == category ? nil : category
                    }
                }

                Divider()
                    .frame(height: 20)

                // Type filters
                ForEach(MemoryType.allCases) { type in
                    filterChip(
                        label: type.rawValue,
                        icon: type.icon,
                        isSelected: viewModel.filterType == type
                    ) {
                        viewModel.filterType = viewModel.filterType == type ? nil : type
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func filterChip(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.showAddMemory = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Add Memory Sheet

    private var addMemorySheet: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextEditor(text: $newMemoryContent)
                        .frame(minHeight: 100)
                }

                Section("Type") {
                    Picker("Memory Type", selection: $newMemoryType) {
                        ForEach(MemoryType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $newMemoryCategory) {
                        ForEach(MemoryCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Add Memory")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetAddMemoryForm()
                        viewModel.showAddMemory = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.createMemory(
                                content: newMemoryContent,
                                type: newMemoryType,
                                category: newMemoryCategory
                            )
                            resetAddMemoryForm()
                            viewModel.showAddMemory = false
                        }
                    }
                    .disabled(newMemoryContent.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func resetAddMemoryForm() {
        newMemoryContent = ""
        newMemoryType = .fact
        newMemoryCategory = .general
    }
}

/// Row view for a memory
public struct MemoryRow: View {
    let memory: Memory
    var similarity: Float?

    public init(memory: Memory, similarity: Float? = nil) {
        self.memory = memory
        self.similarity = similarity
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: memory.memoryType.icon)
                .font(.title3)
                .foregroundStyle(memory.memoryType.color)
                .frame(width: 32, height: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.content)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    // Type badge
                    Text(memory.memoryType.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(memory.memoryType.color.opacity(0.1))
                        .foregroundStyle(memory.memoryType.color)
                        .cornerRadius(4)

                    // Confidence
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("\(Int(memory.confidence * 100))%")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)

                    // Access count
                    if memory.accessCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "eye")
                                .font(.caption2)
                            Text("\(memory.accessCount)")
                                .font(.caption2)
                        }
                        .foregroundStyle(.tertiary)
                    }

                    // Similarity (for search results)
                    if let similarity = similarity {
                        Spacer()
                        Text("\(Int(similarity * 100))% match")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Detail view for a memory
public struct MemoryDetailView: View {
    let memory: Memory
    @ObservedObject var viewModel: MemoryViewModel
    @State private var editedConfidence: Double

    init(memory: Memory, viewModel: MemoryViewModel) {
        self.memory = memory
        self.viewModel = viewModel
        _editedConfidence = State(initialValue: memory.confidence)
    }

    public var body: some View {
        NavigationStack {
            List {
                // Content
                Section("Content") {
                    Text(memory.content)
                }

                // Type and Category
                Section("Classification") {
                    LabeledContent("Type", value: memory.memoryType.rawValue.capitalized)
                    LabeledContent("Category", value: memory.category.rawValue.capitalized)
                }

                // Confidence
                Section("Confidence") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Confidence Level")
                            Spacer()
                            Text("\(Int(editedConfidence * 100))%")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $editedConfidence, in: 0...1, step: 0.1)

                        Button("Update Confidence") {
                            Task {
                                await viewModel.updateConfidence(memory, confidence: editedConfidence)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(editedConfidence == memory.confidence)
                    }
                }

                // Stats
                Section("Statistics") {
                    LabeledContent("Access Count", value: "\(memory.accessCount)")
                    if let lastAccessed = memory.lastAccessedAt {
                        LabeledContent("Last Accessed", value: formatDate(lastAccessed))
                    }
                    LabeledContent("Created", value: formatDate(memory.createdAt))
                    LabeledContent("Updated", value: formatDate(memory.updatedAt))
                }

                // Source
                Section("Source") {
                    Text(memory.source.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Actions
                Section {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deactivate(memory)
                            viewModel.clearSelection()
                        }
                    } label: {
                        Label("Delete Memory", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Memory Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.clearSelection()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Extensions for UI

extension MemoryCategory: Identifiable {
    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .general: return "doc.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .travel: return "airplane"
        case .social: return "person.2.fill"
        case .learning: return "book.fill"
        }
    }

    public var color: Color {
        switch self {
        case .general: return .gray
        case .work: return .blue
        case .personal: return .green
        case .health: return .red
        case .finance: return .purple
        case .travel: return .orange
        case .social: return .pink
        case .learning: return .teal
        }
    }
}

extension MemoryType: Identifiable {
    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .fact: return "doc.text.fill"
        case .preference: return "heart.fill"
        case .context: return "info.circle.fill"
        case .routine: return "clock.fill"
        case .relationship: return "person.2.fill"
        }
    }

    public var color: Color {
        switch self {
        case .fact: return .blue
        case .preference: return .pink
        case .context: return .orange
        case .routine: return .purple
        case .relationship: return .teal
        }
    }
}

#Preview {
    let storage = InMemoryMemoryStorage()
    let service = MemoryService(storage: storage)

    return MemoryView(memoryService: service, userId: UUID())
}
