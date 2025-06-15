import SwiftUI
import PhotosUI

struct EditExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkoutViewModel
    let group: WorkoutGroup
    let exercise: Exercise
    
    @State private var name: String
    @State private var sets: Int
    @State private var reps: Int
    @State private var weightText: String
    @State private var notes: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageURL: URL?
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    
    init(exercise: Exercise, group: WorkoutGroup, viewModel: WorkoutViewModel) {
        self.exercise = exercise
        self.group = group
        self.viewModel = viewModel
        
        _name = State(initialValue: exercise.name)
        _sets = State(initialValue: exercise.sets)
        _reps = State(initialValue: exercise.reps)
        _weightText = State(initialValue: exercise.weight.map { String(format: "%.1f", $0) } ?? "")
        _notes = State(initialValue: exercise.notes ?? "")
        _selectedImageURL = State(initialValue: exercise.imageURL)
    }
    
    var body: some View {
        NavigationView {
            Form {
                exerciseInfoSection
                notesSection
                imageSection
            }
            .navigationTitle("Editar Exercício")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .onChange(of: selectedItem) { oldValue, newItem in
                handleImageSelection(newItem)
            }
            .alert("Erro", isPresented: $isShowingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var exerciseInfoSection: some View {
        Section(header: Text("Informações do Exercício")) {
            TextField("Nome do Exercício", text: $name)
            
            HStack {
                Text("Séries")
                Spacer()
                Stepper("\(sets)", value: $sets, in: 1...10)
            }
            
            HStack {
                Text("Repetições")
                Spacer()
                Stepper("\(reps)", value: $reps, in: 1...100)
            }
            
            HStack {
                Text("Peso (kg)")
                Spacer()
                TextField("Opcional", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private var notesSection: some View {
        Section(header: Text("Observações")) {
            TextEditor(text: $notes)
                .frame(height: 100)
        }
    }
    
    private var imageSection: some View {
        Section(header: Text("Imagem")) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                if let imageURL = selectedImageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 200)
                } else {
                    Label("Selecionar Imagem", systemImage: "photo")
                }
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Salvar") {
                    Task {
                        await saveExercise()
                    }
                }
                .disabled(name.isEmpty)
            }
        }
    }
    
    private func handleImageSelection(_ item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let imageURL = try? await saveImage(image)
                selectedImageURL = imageURL
            }
        }
    }
    
    private func saveExercise() async {
        let weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
        let updatedExercise = Exercise(
            id: exercise.id,
            name: name,
            sets: sets,
            reps: reps,
            weight: weight,
            notes: notes.isEmpty ? nil : notes,
            imageURL: selectedImageURL
        )
        await viewModel.updateExercise(updatedExercise, in: group)
        dismiss()
    }
    
    private func saveImage(_ image: UIImage) async throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try data.write(to: fileURL)
            return fileURL
        }
        
        throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save image"])
    }
}

#Preview {
    EditExerciseView(
        exercise: Exercise(
            name: "Agachamento",
            sets: 3,
            reps: 12,
            weight: 60.0,
            notes: "Foco na execução"
        ),
        group: WorkoutGroup(name: "Treino de Peito"),
        viewModel: WorkoutViewModel()
    )
} 