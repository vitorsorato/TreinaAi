import Foundation
import WatchConnectivity

class WorkoutSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WorkoutSyncManager()
    @Published var workoutGroups: [WorkoutGroup] = []

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // Recebe dados do iPhone via updateApplicationContext
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let data = applicationContext["workoutGroups"] as? Data,
           let groups = try? JSONDecoder().decode([WorkoutGroup].self, from: data) {
            DispatchQueue.main.async {
                self.workoutGroups = groups
            }
        } else {
            print("Application context data is nil")
        }
    }

    // Recebe dados do iPhone via sendMessage (opcional)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let data = message["workoutGroups"] as? Data,
           let groups = try? JSONDecoder().decode([WorkoutGroup].self, from: data) {
            DispatchQueue.main.async {
                self.workoutGroups = groups
            }
        }
    }

    // Delegate obrigatório (pode ficar vazio)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
} 