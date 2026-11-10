/// Read-only history capability; keeps the existing SessionRepository contract unchanged.
nonisolated protocol SessionHistoryChecking: Sendable {
    func hasSavedSessions() async throws -> Bool
}
