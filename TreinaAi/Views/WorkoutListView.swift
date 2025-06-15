import SwiftUI

struct WorkoutListView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var showingAddSheet = false
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: WorkoutGroup?
    @State private var showingEditSheet = false
    @State private var workoutToEdit: WorkoutGroup?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.workoutGroups) { group in
                    WorkoutGroupRow(group: group, viewModel: viewModel)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                workoutToDelete = group
                                showingDeleteAlert = true
                            } label: {
                                Label("Excluir", systemImage: "trash")
                            }
                            
                            Button {
                                workoutToEdit = group
                                showingEditSheet = true
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                workoutToEdit = group
                                showingEditSheet = true
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                workoutToDelete = group
                                showingDeleteAlert = true
                            } label: {
                                Label("Excluir", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("Treinos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWorkoutGroupView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingEditSheet) {
                if let group = workoutToEdit {
                    EditWorkoutGroupView(viewModel: viewModel, group: group)
                }
            }
            .alert("Excluir Treino", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Excluir", role: .destructive) {
                    if let group = workoutToDelete {
                        Task {
                            await viewModel.deleteWorkoutGroup(group)
                        }
                    }
                }
            } message: {
                Text("Tem certeza que deseja excluir este treino? Esta ação não pode ser desfeita.")
            }
        }
    }
}

struct WorkoutGroupRow: View {
    let group: WorkoutGroup
    let viewModel: WorkoutViewModel
    
    var body: some View {
        NavigationLink(destination: WorkoutGroupDetailView(group: group, viewModel: viewModel)) {
            HStack(spacing: 12) {
                // Miniaturas das imagens dos exercícios (até 4)
                HStack(spacing: -8) {
                    let imageExercises = group.exercises.compactMap { $0.imageURL }.prefix(4)
                    ForEach(Array(imageExercises.enumerated()), id: \ .offset) { idx, imageURL in
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "dumbbell.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white, lineWidth: 1))
                        .zIndex(Double(4 - idx))
                    }
                    if imageExercises.isEmpty {
                        Image(systemName: "dumbbell.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .frame(width: 80, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                    
                    if let day = group.suggestedDay {
                        Text(day)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(group.exercises.count) exercícios")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

struct EditWorkoutGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkoutViewModel
    let group: WorkoutGroup
    
    @State private var name: String
    @State private var selectedDay: String?
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    
    private let weekDays = [
        "Segunda-feira",
        "Terça-feira",
        "Quarta-feira",
        "Quinta-feira",
        "Sexta-feira",
        "Sábado",
        "Domingo"
    ]
    
    init(viewModel: WorkoutViewModel, group: WorkoutGroup) {
        self.viewModel = viewModel
        self.group = group
        _name = State(initialValue: group.name)
        _selectedDay = State(initialValue: group.suggestedDay)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informações do Grupo")) {
                    TextField("Nome do Grupo", text: $name)
                    
                    Picker("Dia Sugerido", selection: $selectedDay) {
                        Text("Nenhum").tag(nil as String?)
                        ForEach(weekDays, id: \.self) { day in
                            Text(day).tag(day as String?)
                        }
                    }
                }
            }
            .navigationTitle("Editar Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        Task {
                            await saveWorkoutGroup()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("Erro", isPresented: $isShowingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveWorkoutGroup() async {
        do {
            let updatedGroup = WorkoutGroup(
                id: group.id,
                name: name,
                suggestedDay: selectedDay,
                exercises: group.exercises
            )
            try await viewModel.updateWorkoutGroup(updatedGroup)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            isShowingAlert = true
        }
    }
}

#Preview {
    WorkoutListView()
} 