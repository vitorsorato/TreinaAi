import SwiftUI

struct AddWorkoutGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkoutViewModel
    
    @State private var name = ""
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
            .navigationTitle("Novo Grupo")
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
        await viewModel.addWorkoutGroup(name: name, suggestedDay: selectedDay)
        dismiss()
    }
}

#Preview {
    AddWorkoutGroupView(viewModel: WorkoutViewModel())
} 