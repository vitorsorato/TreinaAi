import Foundation
import SwiftUI

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var workoutGroups: [WorkoutGroup] = []
    private let userDefaults = UserDefaults.standard
    private let workoutGroupsKey = "workoutGroups"
    
    init() {
        loadLocalData()
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