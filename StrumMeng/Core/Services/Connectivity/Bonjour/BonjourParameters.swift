import CryptoKit
import Foundation
import Network

/// Network settings shared by both ends of the Bonjour link.
nonisolated enum BonjourParameters {
    /// Must match NSBonjourServices in Info.plist.
    static let serviceType = "_strummeng._udp"

    private static let pskIdentity = Data("StrumMeng".utf8)

    /// UDP secured with DTLS, using a pre-shared key derived from the pair code (the approach of
    /// Apple's TicTacToe peer-to-peer sample). A device with a different code cannot finish the
    /// handshake, so a stranger's iPhone cannot control this iPad.
    static func make(pairCode: PairCode) -> NWParameters {
        let tls = NWProtocolTLS.Options()
        let key = SymmetricKey(data: Data(pairCode.value.utf8))
        let psk = Data(HMAC<SHA256>.authenticationCode(for: pskIdentity, using: key))
        sec_protocol_options_add_pre_shared_key(
            tls.securityProtocolOptions,
            dispatchData(psk) as __DispatchData,
            dispatchData(pskIdentity) as __DispatchData)
        if let suite = tls_ciphersuite_t(rawValue: UInt16(TLS_PSK_WITH_AES_128_GCM_SHA256)) {
            sec_protocol_options_append_tls_ciphersuite(tls.securityProtocolOptions, suite)
        }
        let parameters = NWParameters(dtls: tls, udp: NWProtocolUDP.Options())
        // AWDL: iPhone and iPad can talk directly even without a shared router.
        parameters.includePeerToPeer = true
        parameters.serviceClass = .interactiveVoice
        return parameters
    }

    /// Browsing needs no encryption; only the connection itself is secured.
    static func browsing() -> NWParameters {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        return parameters
    }

    private static func dispatchData(_ data: Data) -> DispatchData {
        data.withUnsafeBytes { DispatchData(bytes: $0) }
    }
}
