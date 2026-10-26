import Foundation

enum SessionRepositoryError: Error, Equatable {
    /// The beat events could not be turned into data, so nothing was saved.
    case encodingFailed

    /// A stored record holds beat events that can no longer be read.
    case decodingFailed(recordID: UUID)
}
