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

// MARK: - Real Event Creation from Appdome Notifications
extension ThreatEvent {
    /// Creates a ThreatEvent from Appdome notification userInfo
    static func fromNotification(type: String, userInfo: [AnyHashable: Any]) -> ThreatEvent {
        let message = userInfo["message"] as? String ?? "Threat detected"
        let reasonData = userInfo["reasonData"]
        let reasonCode = userInfo["reasonCode"]
        let currentThreatEventScore = userInfo["currentThreatEventScore"]
        let threatEventsScore = userInfo["threatEventsScore"]
        
        var title: String
        var description: String
        var severity: String
        var metadata: String = ""
        
        // Build metadata from available information
        var metadataComponents: [String] = []
        if let reasonCode = reasonCode {
            metadataComponents.append("Reason Code: \(reasonCode)")
        }
        if let reasonData = reasonData {
            metadataComponents.append("Reason Data: \(reasonData)")
        }
        if let currentScore = currentThreatEventScore {
            metadataComponents.append("Current Threat Score: \(currentScore)")
        }
        if let totalScore = threatEventsScore {
            metadataComponents.append("Total Threat Score: \(totalScore)")
        }
        metadata = metadataComponents.joined(separator: ", ")
        
        switch type {
        case "DebuggerThreatDetected":
            title = "Debugger Detected"
            description = message.isEmpty ? "A debugging tool has been detected attempting to attach to the application." : message
            severity = "High"
            
        case "DebuggableEntitlement":
            title = "Debug Entitlement Detected"
            description = message.isEmpty ? "The application has debug entitlements enabled, making it vulnerable to debugging attacks." : message
            severity = "Medium"
            
        case "AppIntegrityError":
            title = "App Integrity Violation"
            description = message.isEmpty ? "The application's integrity has been compromised." : message
            severity = "Critical"
            
        default:
            title = "Unknown Threat"
            description = message.isEmpty ? "An unknown threat has been detected." : message
            severity = "Medium"
        }
        
        return ThreatEvent(
            threatType: type,
            title: title,
            description: description,
            severity: severity,
            metadata: metadata.isEmpty ? nil : metadata
        )
    }
}