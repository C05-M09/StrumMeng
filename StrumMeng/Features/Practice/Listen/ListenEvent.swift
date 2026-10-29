enum ListenEvent {
    case next, pause, resume, restart, ready, back
    case progress(step: Int, completed: Bool)
    case failed(String)
}
