import Foundation
import SwiftUI
import WatchConnectivity

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var workoutGroups: [WorkoutGroup] = []
    private let userDefaults = UserDefaults.standard
    private let workoutGroupsKey = "workoutGroups"
    private let imageCache = NSCache<NSString, NSData>()
    
    init() {
        loadLocalData()
        setupImageCache()
    }
    
    private func setupImageCache() {
        imageCache.countLimit = 100 // Limite de 100 imagens em cache
    }
    
    private func loadLocalData() {
        if let data = userDefaults.data(forKey: workoutGroupsKey),
           let decodedGroups = try? JSONDecoder().decode([WorkoutGroup].self, from: data) {
            workoutGroups = decodedGroups
        }
    }
    
    private func saveLocalData() {
        if let encodedData = try? JSONEncoder().encode(workoutGroups) {
            userDefaults.set(encodedData, forKey: workoutGroupsKey)
        }
        WorkoutSyncManager.shared.syncToWatch(workoutGroups)
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
    
    func saveImage(_ image: UIImage) async throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try data.write(to: fileURL)
            // Salva no cache
            imageCache.setObject(data as NSData, forKey: fileURL.absoluteString as NSString)
            // Sincroniza com o Apple Watch
            WorkoutSyncManager.shared.transferImage(data, fileName: fileName)
            return fileURL
        }
        
        throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save image"])
    }
    
    func addWorkoutGroup(name: String, suggestedDay: String? = nil) async {
        let newGroup = WorkoutGroup(name: name, suggestedDay: suggestedDay)
        workoutGroups.append(newGroup)
        saveLocalData()
    }
    
    func updateWorkoutGroup(_ group: WorkoutGroup) async {
        if let index = workoutGroups.firstIndex(where: { $0.id == group.id }) {
            workoutGroups[index] = group
            saveLocalData()
        }
    }
    
    func deleteWorkoutGroup(_ group: WorkoutGroup) async {
        workoutGroups.removeAll { $0.id == group.id }
        saveLocalData()
    }
    
    func addExercise(name: String, sets: Int, reps: Int, weight: Double? = nil, notes: String? = nil, imageURL: URL? = nil, to group: WorkoutGroup) async {
        let exercise = Exercise(name: name, sets: sets, reps: reps, weight: weight, notes: notes, imageURL: imageURL)
        if let index = workoutGroups.firstIndex(where: { $0.id == group.id }) {
            var updatedGroup = group
            updatedGroup.exercises.append(exercise)
            workoutGroups[index] = updatedGroup
            saveLocalData()
        }
    }
    
    func updateExercise(_ exercise: Exercise, in group: WorkoutGroup) async {
        if let groupIndex = workoutGroups.firstIndex(where: { $0.id == group.id }),
           let exerciseIndex = workoutGroups[groupIndex].exercises.firstIndex(where: { $0.id == exercise.id }) {
            var updatedGroup = group
            updatedGroup.exercises[exerciseIndex] = exercise
            workoutGroups[groupIndex] = updatedGroup
            saveLocalData()
        }
    }
    
    func deleteExercise(_ exercise: Exercise, from group: WorkoutGroup) async {
        if let groupIndex = workoutGroups.firstIndex(where: { $0.id == group.id }) {
            var updatedGroup = group
            updatedGroup.exercises.removeAll { $0.id == exercise.id }
            workoutGroups[groupIndex] = updatedGroup
            saveLocalData()
        }
    }
    
    func moveExercise(from source: IndexSet, to destination: Int, in group: WorkoutGroup) async {
        if let groupIndex = workoutGroups.firstIndex(where: { $0.id == group.id }) {
            var updatedGroup = group
            updatedGroup.exercises.move(fromOffsets: source, toOffset: destination)
            workoutGroups[groupIndex] = updatedGroup
            saveLocalData()
        }
    }
} 