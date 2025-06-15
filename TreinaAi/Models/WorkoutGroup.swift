import Foundation

struct WorkoutGroup: Identifiable, Codable {
    var id: UUID
    var name: String
    var suggestedDay: String?
    var exercises: [Exercise]
    
    init(id: UUID = UUID(), name: String, suggestedDay: String? = nil, exercises: [Exercise] = []) {
        self.id = id
        self.name = name
        self.suggestedDay = suggestedDay
        self.exercises = exercises
    }
}

struct Exercise: Identifiable, Codable {
    var id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double?
    var notes: String?
    var imageURL: URL?
    
    init(id: UUID = UUID(), name: String, sets: Int, reps: Int, weight: Double? = nil, notes: String? = nil, imageURL: URL? = nil) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.notes = notes
        self.imageURL = imageURL
    }
} 