@objc class FramesetWaiterSpy : NSObject, RMQFramesetWaiter {
    var lastWaitedOnClass: AnyClass?
    var lastFulfilledFrameset: AMQFrameset?
    var error: NSError?

    func waitOn(methodClass: AnyClass!) -> RMQFramesetWaitResult! {
        lastWaitedOnClass = methodClass
        if let e = error {
            return RMQFramesetWaitResult(frameset: nil, error: e)
        } else {
            return RMQFramesetWaitResult(frameset: lastFulfilledFrameset, error: nil)
        }
    }

    func fulfill(frameset: AMQFrameset!) {
        lastFulfilledFrameset = frameset
    }

    func err(msg: String) {
        error = NSError(domain: RMQErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
    }
}