//
//  ContentView.swift
//  TreinaAi Watch Watch App
//
//  Created by Vitor Sorato on 15/06/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var syncManager = WorkoutSyncManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                if syncManager.workoutGroups.isEmpty {
                    Text("Nenhum treino disponível.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(syncManager.workoutGroups) { group in
                        NavigationLink(destination: ExerciseListView(group: group)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.name)
                                    .font(.headline)
                                Text("\(group.exercises.count) exercícios")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Treinos")
        }
    }
}

struct ExerciseListView: View {
    let group: WorkoutGroup
    
    var body: some View {
        if group.exercises.isEmpty {
            VStack {
                Text("Nenhum exercício neste grupo.")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            TabView {
                ForEach(group.exercises) { exercise in
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.thinMaterial)
                            .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 1)
                        VStack(alignment: .center, spacing: 12) {
                            if let imageURL = exercise.imageURL {
                                AsyncImage(url: imageURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 160)
                                        .clipped()
                                        .cornerRadius(16)
                                } placeholder: {
                                    Image(systemName: "dumbbell.fill")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                        .opacity(0.5)
                                        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 160)
                                        .background(Color.gray.opacity(0.08))
                                        .cornerRadius(16)
                                }
                            } else {
                                Image(systemName: "dumbbell.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                    .opacity(0.5)
                                    .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 160)
                                    .background(Color.gray.opacity(0.08))
                                    .cornerRadius(16)
                            }
                            VStack(alignment: .center, spacing: 4) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                HStack(spacing: 8) {
                                    Text("\(exercise.sets) × \(exercise.reps)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    if let weight = exercise.weight {
                                        Text(" \(String(format: "%.1f", weight)) kg")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                if let notes = exercise.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .tabViewStyle(.page)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(group.name)
        }
    }
}

#Preview {
    ContentView()
}
