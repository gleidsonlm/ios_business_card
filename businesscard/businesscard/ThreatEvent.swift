//
//  ThreatEvent.swift
//  businesscard
//
//  Created by Gleidson L Medeiros on 13/08/25.
//

import Foundation
import SwiftData

/// Represents an Appdome threat event detected by the security system
@Model
final class ThreatEvent {
    /// Unique identifier for the threat event
    var id: UUID
    
    /// Type of threat detected (e.g., "DebuggerThreatDetected", "DebuggableEntitlement", "AppIntegrityError")
    var threatType: String
    
    /// Human-readable title for the threat
    var title: String
    
    /// Detailed description of the threat
    var threatDescription: String
    
    /// Severity level of the threat (Critical, High, Medium, Low)
    var severity: String
    
    /// Timestamp when the threat was detected
    var detectedAt: Date
    
    /// Detection mode (always "In-App Detection" for this implementation)
    var detectionMode: String
    
    /// Additional metadata or context about the threat
    var metadata: String?
    
    /// Whether the threat is currently active
    var isActive: Bool
    
    init(
        threatType: String,
        title: String,
        description: String,
        severity: String,
        detectedAt: Date = Date(),
        detectionMode: String = "In-App Detection",
        metadata: String? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.threatType = threatType
        self.title = title
        self.threatDescription = description
        self.severity = severity
        self.detectedAt = detectedAt
        self.detectionMode = detectionMode
        self.metadata = metadata
        self.isActive = isActive
    }
}

// MARK: - Threat Event Factory
extension ThreatEvent {
    /// Creates a DebuggerThreatDetected event
    static func debuggerThreatDetected() -> ThreatEvent {
        return ThreatEvent(
            threatType: "DebuggerThreatDetected",
            title: "Debugger Detected",
            description: "A debugging tool has been detected attempting to attach to the application. This could indicate reverse engineering or malicious analysis attempts.",
            severity: "High",
            metadata: "Detection method: Runtime analysis, Process monitoring"
        )
    }
    
    /// Creates a DebuggableEntitlement event
    static func debuggableEntitlement() -> ThreatEvent {
        return ThreatEvent(
            threatType: "DebuggableEntitlement",
            title: "Debug Entitlement Detected",
            description: "The application has debug entitlements enabled, making it vulnerable to debugging and reverse engineering attacks.",
            severity: "Medium",
            metadata: "Entitlement: get-task-allow, com.apple.private.security.no-container"
        )
    }
    
    /// Creates an AppIntegrityError event
    static func appIntegrityError() -> ThreatEvent {
        return ThreatEvent(
            threatType: "AppIntegrityError",
            title: "App Integrity Violation",
            description: "The application's integrity has been compromised. This could indicate tampering, modification, or injection of malicious code.",
            severity: "Critical",
            metadata: "Integrity check: Binary signature verification, Code signing validation"
        )
    }
}