import Foundation
import Observation

@MainActor
@Observable
final class AppRouter {
    var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    /// Swaps the top screen for another, so Back skips the one replaced (Play → Summary: Back must
    /// not return to a finished session).
    func replaceLast(with route: AppRoute) {
        guard !path.isEmpty else { return push(route) }
        path[path.count - 1] = route
    }

    /// Goes back to the most recent `route` in the stack. If it is not there, the stack becomes just
    /// that route, so "back to the practice list" always ends on the practice list.
    func popTo(_ route: AppRoute) {
        if let index = path.lastIndex(of: route) {
            path.removeSubrange((index + 1)...)
        } else {
            path = [route]
        }
    }
}
