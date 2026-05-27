import Foundation

enum SampleLog {
    static func call(_ message: String) {
        print("[StringeeCallSample][Call] \(message)")
    }

    static func client(_ message: String) {
        print("[StringeeCallSample][Client] \(message)")
    }
}

extension CallKind {
    var logDescription: String {
        switch self {
        case .voice:
            return "voice"
        case .video:
            return "video"
        }
    }
}

extension CallDirection {
    var logDescription: String {
        switch self {
        case .incoming:
            return "incoming"
        case .outgoing:
            return "outgoing"
        }
    }
}

extension CallImplementationKind {
    var logDescription: String {
        switch self {
        case .stringeeCall:
            return "StringeeCall"
        case .stringeeCall2:
            return "StringeeCall2"
        case .fake:
            return "FakeStringee"
        }
    }
}

extension CallSessionState {
    var logDescription: String {
        switch self {
        case .calling:
            return "calling"
        case .ringing:
            return "ringing"
        case .answered:
            return "answered"
        case .mediaConnected:
            return "mediaConnected"
        case .mediaDisconnected:
            return "mediaDisconnected"
        case .ended(let reason):
            return "ended(reason: \(reason))"
        }
    }
}

extension CallSessionProtocol {
    var logDescription: String {
        "id=\(id) kind=\(kind.logDescription) direction=\(direction.logDescription) implementation=\(implementationKind.logDescription) remoteUserId=\(remoteUserId)"
    }
}
