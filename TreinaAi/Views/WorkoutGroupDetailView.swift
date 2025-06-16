import SwiftUI
import PhotosUI

struct WorkoutGroupDetailView: View {
    let group: WorkoutGroup
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var showingAddSheet = false
    @State private var showingDeleteAlert = false
    @State private var exerciseToDelete: Exercise?
    
    var body: some View {
        List {
            Section {
                if let day = group.suggestedDay {
                    LabeledContent("Dia sugerido", value: day)
                }
            }
            
            Section("Exercícios") {
                ForEach(group.exercises) { exercise in
                    NavigationLink {
                        EditExerciseView(
                            exercise: exercise,
                            group: group,
                            viewModel: viewModel
                        )
                    } label: {
                        ExerciseRow(exercise: exercise)
                    }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        exerciseToDelete = group.exercises[index]
                        showingDeleteAlert = true
                    }
                }
                .onMove { source, destination in
                    Task {
                        await viewModel.moveExercise(from: source, to: destination, in: group)
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddExerciseView(viewModel: viewModel, group: group)
        }
        .alert("Excluir Exercício", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive) {
                if let exercise = exerciseToDelete {
                    Task {
                        await viewModel.deleteExercise(exercise, from: group)
                    }
                }
            }
        } message: {
            Text("Tem certeza que deseja excluir este exercício?")
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let imageURL = exercise.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "dumbbell.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .opacity(0.5)
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "dumbbell.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .opacity(0.5)
                    .frame(width: 48, height: 48)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text("\(exercise.sets) × \(exercise.reps)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let weight = exercise.weight {
                        Text("\(String(format: "%.1f", weight)) kg")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        WorkoutGroupDetailView(
            group: WorkoutGroup(
                name: "Treino A",
                suggestedDay: "Segunda-feira",
                exercises: [
                    Exercise(name: "Agachamento", sets: 3, reps: 12, weight: 60.0, notes: "Foco na execução"),
                    Exercise(name: "Supino", sets: 4, reps: 10, weight: 40.0)
                ]
            ),
            viewModel: WorkoutViewModel()
        )
    }
} 
