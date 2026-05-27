import Foundation

struct StringeePushPayload: Equatable {
    let callId: String
    let serial: Int
    let callerName: String
    let callerNumber: String
    let kind: CallKind

    init?(dictionary: [AnyHashable: Any]) {
        guard
            let rootData = dictionary["data"] as? [AnyHashable: Any],
            let rootMap = rootData["map"] as? [AnyHashable: Any],
            rootMap["type"] as? String == "CALL_EVENT",
            let data = rootMap["data"] as? [AnyHashable: Any],
            let map = data["map"] as? [AnyHashable: Any],
            map["callStatus"] as? String == "started",
            let callId = map["callId"] as? String,
            !callId.isEmpty
        else {
            return nil
        }

        self.callId = callId
        self.serial = map["serial"] as? Int ?? 0

        let from = (map["from"] as? [AnyHashable: Any])?["map"] as? [AnyHashable: Any]
        let alias = from?["alias"] as? String
        let number = from?["number"] as? String
        self.callerNumber = number?.isEmpty == false ? number! : callId
        self.callerName = alias?.isEmpty == false ? alias! : self.callerNumber

        let isVideo = (map["isVideoCall"] as? Bool)
            ?? (map["video"] as? Bool)
            ?? ((map["callType"] as? String)?.lowercased() == "video")
        self.kind = isVideo ? .video : .voice
    }
}

enum VoIPPushEnvironment {
    static var currentIsProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
}
