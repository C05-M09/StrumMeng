enum PairingIntroductionState: Equatable {
    case idle, waiting, welcoming, finished

    var blocksHome: Bool { self == .waiting || self == .welcoming }
}
