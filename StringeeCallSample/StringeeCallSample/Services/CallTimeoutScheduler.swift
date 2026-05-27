import Foundation

protocol CallTimeoutScheduling: AnyObject {
    func schedule(after seconds: TimeInterval, _ block: @escaping () -> Void)
    func cancel()
}

final class CallTimeoutScheduler: CallTimeoutScheduling {
    private var timer: Timer?

    func schedule(after seconds: TimeInterval, _ block: @escaping () -> Void) {
        cancel()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            block()
        }
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}

final class ManualCallTimeoutScheduler: CallTimeoutScheduling {
    private var block: (() -> Void)?

    func schedule(after seconds: TimeInterval, _ block: @escaping () -> Void) {
        self.block = block
    }

    func cancel() {
        block = nil
    }

    func fire() {
        let block = block
        self.block = nil
        block?()
    }
}
