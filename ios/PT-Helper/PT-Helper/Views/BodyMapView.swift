import SwiftUI

struct BodyMapView: View {
    @StateObject private var viewModel = BodyMapViewModel()
    @State private var navigateToPainDetail = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                VStack(spacing: 6) {
                    Text("Where does it hurt?")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                    Text("Tap all areas where you feel pain or discomfort")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Body map
                GeometryReader { geometry in
                    ZStack {
                        // Body outline
                        Image(systemName: "figure.stand")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width * 0.5)
                            .foregroundColor(.gray.opacity(0.3))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Tappable region hotspots
                        ForEach(viewModel.regions) { region in
                            let position = CGPoint(
                                x: region.relativePosition.x * geometry.size.width,
                                y: region.relativePosition.y * geometry.size.height
                            )

                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    viewModel.toggleSelection(for: region)
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Circle()
                                        .fill(region.isSelected ? Color.blue : Color.blue.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.blue, lineWidth: region.isSelected ? 0 : 1.5)
                                        )
                                        .overlay(
                                            Image(systemName: region.isSelected ? "checkmark" : "plus")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(region.isSelected ? .white : .blue)
                                        )
                                        .scaleEffect(region.isSelected ? 1.1 : 1.0)

                                    Text(region.name)
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(region.isSelected ? .blue : .secondary)
                                        .lineLimit(1)
                                }
                            }
                            .position(position)
                            .accessibilityLabel(region.name)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .padding(.horizontal, 20)

                // Summary bar and actions
                VStack(spacing: 12) {
                    HStack {
                        Text("\(viewModel.selectedRegions.count) area(s) selected")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        Spacer()
                        if !viewModel.selectedRegions.isEmpty {
                            Button(action: { viewModel.clearAll() }) {
                                Text("Clear All")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    NavigationLink(
                        destination: PainDetailView(
                            viewModel: InjuryAnalysisViewModel(
                                userProfile: viewModel.userProfile,
                                selectedRegions: viewModel.selectedRegions
                            )
                        ),
                        isActive: $navigateToPainDetail
                    ) {
                        EmptyView()
                    }

                    Button(action: { navigateToPainDetail = true }) {
                        Text("Continue")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(viewModel.selectedRegions.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(14)
                    }
                    .disabled(viewModel.selectedRegions.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Body Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}
