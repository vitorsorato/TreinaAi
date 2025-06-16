import Foundation
import WatchConnectivity

class WorkoutSyncManager: NSObject, ObservableObject {
    static let shared = WorkoutSyncManager()
    private let session: WCSession
    
    override init() {
        self.session = WCSession.default
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func syncToWatch(_ workoutGroups: [WorkoutGroup]) {
        guard session.activationState == .activated else { return }
        
        do {
            let data = try JSONEncoder().encode(workoutGroups)
            let message: [String: Any] = ["workoutGroups": data]
            
            if session.isReachable {
                session.sendMessage(message, replyHandler: nil)
            } else {
                try session.updateApplicationContext(message)
            }
        } catch {
            print("Error syncing workout groups: \(error)")
        }
    }
    
    func transferImage(_ imageData: Data, fileName: String) {
        guard session.activationState == .activated else { return }
        
        let message: [String: Any] = ["imageData": imageData, "fileName": fileName]
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil)
        } else {
            do {
                try session.updateApplicationContext(message)
            } catch {
                print("Error transferring image: \(error)")
            }
        }
    }
}

extension WorkoutSyncManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Session activation failed: \(error)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session deactivated")
        session.activate()
    }
    
    #if os(iOS)
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("Watch state changed: \(session.activationState.rawValue)")
    }
    #endif
} 