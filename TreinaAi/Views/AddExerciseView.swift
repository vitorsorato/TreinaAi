import SwiftUI
import PhotosUI

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkoutViewModel
    let group: WorkoutGroup
    
    @State private var name = ""
    @State private var sets = 3
    @State private var reps = 12
    @State private var weightText = ""
    @State private var notes = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageURL: URL?
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
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
                
                Section(header: Text("Observações")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
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
            .navigationTitle("Novo Exercício")
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
                            await saveExercise()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onChange(of: selectedItem) { oldValue, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        let imageURL = try? await saveImage(image)
                        selectedImageURL = imageURL
                    }
                }
            }
            .alert("Erro", isPresented: $isShowingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveExercise() async {
        let weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
        await viewModel.addExercise(
            name: name,
            sets: sets,
            reps: reps,
            weight: weight,
            notes: notes.isEmpty ? nil : notes,
            imageURL: selectedImageURL,
            to: group
        )
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
    AddExerciseView(viewModel: WorkoutViewModel(), group: WorkoutGroup(id: UUID(), name: "Treino"))
} 