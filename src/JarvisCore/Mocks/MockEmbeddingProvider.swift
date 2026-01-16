import Foundation

/// Mock embedding provider for integration testing without OpenAI API
public actor MockEmbeddingProvider {
    private let embeddingDimension: Int

    public init(dimension: Int = 1536) {
        self.embeddingDimension = dimension
    }

    // MARK: - Mock Embedding Generation

    /// Generate a deterministic mock embedding based on text content
    /// Uses a simple hash-based approach for consistency
    public func generateEmbedding(for text: String) async -> [Float] {
        // Create a deterministic embedding based on text hash
        var embedding = [Float](repeating: 0, count: embeddingDimension)

        let words = text.lowercased().split(separator: " ")

        // Generate pseudo-random but deterministic values
        for (index, word) in words.enumerated() {
            let wordHash = word.hashValue
            let position = abs(wordHash) % embeddingDimension
            embedding[position] += Float(1.0 / Double(words.count))

            // Add some variation based on word position
            let secondPosition = abs(wordHash &+ index) % embeddingDimension
            embedding[secondPosition] += Float(0.5 / Double(words.count))
        }

        // Normalize the embedding
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }

        return embedding
    }

    /// Generate embeddings for multiple texts
    public func generateEmbeddings(for texts: [String]) async -> [[Float]] {
        var results: [[Float]] = []
        for text in texts {
            let embedding = await generateEmbedding(for: text)
            results.append(embedding)
        }
        return results
    }

    /// Calculate cosine similarity between two embeddings
    public func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var dotProduct: Float = 0
        var magnitudeA: Float = 0
        var magnitudeB: Float = 0

        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            magnitudeA += a[i] * a[i]
            magnitudeB += b[i] * b[i]
        }

        let magnitude = sqrt(magnitudeA) * sqrt(magnitudeB)
        return magnitude > 0 ? dotProduct / magnitude : 0
    }

    /// Find most similar texts to a query
    public func findSimilar(
        query: String,
        candidates: [(text: String, embedding: [Float])],
        topK: Int = 5
    ) async -> [(text: String, similarity: Float)] {
        let queryEmbedding = await generateEmbedding(for: query)

        var results: [(text: String, similarity: Float)] = []
        for candidate in candidates {
            let similarity = cosineSimilarity(queryEmbedding, candidate.embedding)
            results.append((candidate.text, similarity))
        }

        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(topK)
            .map { $0 }
    }
}
