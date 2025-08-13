//
//  ThreatEventsView.swift
//  businesscard
//
//  Created by Gleidson L Medeiros on 13/08/25.
//

import SwiftUI
import SwiftData

/// View displaying Appdome Threat Events in a card-based layout
struct ThreatEventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var threatEvents: [ThreatEvent]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if threatEvents.isEmpty {
                        EmptyStateView()
                    } else {
                        ForEach(threatEvents.sorted(by: { $0.detectedAt > $1.detectedAt })) { event in
                            ThreatEventCard(event: event)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Threat Events")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Sample", action: addSampleEvents)
                }
            }
        }
    }
    
    /// Adds sample threat events for demonstration
    private func addSampleEvents() {
        withAnimation {
            let events = [
                ThreatEvent.debuggerThreatDetected(),
                ThreatEvent.debuggableEntitlement(),
                ThreatEvent.appIntegrityError()
            ]
            
            for event in events {
                modelContext.insert(event)
            }
        }
    }
}

/// Card view for displaying individual threat events
struct ThreatEventCard: View {
    let event: ThreatEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and severity
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(event.threatType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                SeverityBadge(severity: event.severity)
            }
            
            // Description
            Text(event.threatDescription)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Detection details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Detection Mode", systemImage: "shield.checkered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(event.detectionMode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Detected", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(event.detectedAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let metadata = event.metadata {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Details", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(metadata)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }
                }
            }
            
            // Status indicator
            HStack {
                Circle()
                    .fill(event.isActive ? Color.red : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(event.isActive ? "Active" : "Resolved")
                    .font(.caption2)
                    .foregroundColor(event.isActive ? .red : .secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor(for: event.severity).opacity(0.3), lineWidth: 1)
        )
    }
    
    /// Returns the appropriate color for the threat severity
    private func severityColor(for severity: String) -> Color {
        switch severity.lowercased() {
        case "critical":
            return .red
        case "high":
            return .orange
        case "medium":
            return .yellow
        case "low":
            return .green
        default:
            return .gray
        }
    }
}

/// Badge view for displaying threat severity
struct SeverityBadge: View {
    let severity: String
    
    var body: some View {
        Text(severity.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severityColor.opacity(0.2))
            .foregroundColor(severityColor)
            .cornerRadius(8)
    }
    
    private var severityColor: Color {
        switch severity.lowercased() {
        case "critical":
            return .red
        case "high":
            return .orange
        case "medium":
            return .yellow
        case "low":
            return .green
        default:
            return .gray
        }
    }
}

/// Empty state view when no threat events are present
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Threat Events")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Appdome threat detection is active.\nTap 'Add Sample' to see example events.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ThreatEventsView()
        .modelContainer(for: ThreatEvent.self, inMemory: true)
}