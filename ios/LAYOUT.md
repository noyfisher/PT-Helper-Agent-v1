# SwiftUI Module Layout (proposal)

PTApp/
  PTAppApp.swift
  Shared/
    AppCore/        # DI, routing, services
    DesignSystem/   # Buttons, Cards, Colors, Typography
    Models/         # Codable models for DSL and data
    Persistence/    # Local store + sync queue
    Services/       # API clients (Firebase/Supabase abstractions)
  Features/
    Auth/
    RegionSelect/
    Assessment/
    Results/
    Plan/
    Messaging/
    Profile/
  Tests/
    Unit/
    UITests/
    Snapshots/
