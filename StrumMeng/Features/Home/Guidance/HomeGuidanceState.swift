enum HomeGuidanceState: Hashable {
    case dormant, option, guidebook, finished
    var isShowing: Bool { self == .option || self == .guidebook }
}
