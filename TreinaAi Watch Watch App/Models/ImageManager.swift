import Foundation
import WatchConnectivity

class ImageManager: NSObject, ObservableObject {
    static let shared = ImageManager()
    private let session: WCSession
    private let imageCache = NSCache<NSString, NSData>()
    
    override init() {
        self.session = WCSession.default
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        
        setupImageCache()
    }
    
    private func setupImageCache() {
        imageCache.countLimit = 50 // Limite de 50 imagens em cache no Watch
    }
    
    func getImageData(for url: URL) -> Data? {
        // Primeiro, tenta buscar do cache
        if let cachedData = imageCache.object(forKey: url.absoluteString as NSString) {
            return cachedData as Data
        }
        
        // Se não estiver em cache, tenta ler do disco
        if let data = try? Data(contentsOf: url) {
            // Salva no cache para uso futuro
            imageCache.setObject(data as NSData, forKey: url.absoluteString as NSString)
            return data
        }
        
        return nil
    }
    
    private func saveImageData(_ data: Data, fileName: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            imageCache.setObject(data as NSData, forKey: fileURL.absoluteString as NSString)
        } catch {
            print("Error saving image: \(error)")
        }
    }
}

extension ImageManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Session activation failed: \(error)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleReceivedMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleReceivedMessage(applicationContext)
    }
    
    private func handleReceivedMessage(_ message: [String: Any]) {
        if let imageData = message["imageData"] as? Data,
           let fileName = message["fileName"] as? String {
            saveImageData(imageData, fileName: fileName)
        }
    }
} 