import Foundation
import WatchConnectivity

class WorkoutSyncManager: NSObject, WCSessionDelegate {
    static let shared = WorkoutSyncManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // Envie os treinos para o Watch
    func syncToWatch(_ groups: [WorkoutGroup]) {
        if WCSession.default.isPaired && WCSession.default.isWatchAppInstalled {
            if let data = try? JSONEncoder().encode(groups) {
                try? WCSession.default.updateApplicationContext(["workoutGroups": data])
            }
        }
    }

    // Delegate obrigatório (pode ficar vazio)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
} 