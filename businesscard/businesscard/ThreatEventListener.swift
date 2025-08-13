//
//  ThreatEventListener.swift
//  businesscard
//
//  Created by Gleidson L Medeiros on 13/08/25.
//

import Foundation
import SwiftData

/// Service responsible for listening to Appdome threat events via NotificationCenter
@Observable
class ThreatEventListener {
    private let modelContext: ModelContext
    private var observers: [NSObjectProtocol] = []
    
    /// Appdome threat event notification names
    private let threatEventNames = [
        "DebuggerThreatDetected",
        "DebuggableEntitlement", 
        "AppIntegrityError"
    ]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupThreatEventListeners()
    }
    
    deinit {
        removeAllObservers()
    }
    
    /// Sets up NotificationCenter observers for all Appdome threat events
    private func setupThreatEventListeners() {
        let center = NotificationCenter.default
        
        for eventName in threatEventNames {
            let observer = center.addObserver(
                forName: Notification.Name(eventName),
                object: nil,
                queue: OperationQueue.main
            ) { [weak self] notification in
                self?.handleThreatEvent(eventName: eventName, notification: notification)
            }
            observers.append(observer)
        }
    }
    
    /// Handles incoming threat event notifications from Appdome
    private func handleThreatEvent(eventName: String, notification: Notification) {
        guard let userInfo = notification.userInfo else {
            print("⚠️ Threat event \(eventName) received without userInfo")
            return
        }
        
        print("🚨 Appdome threat event detected: \(eventName)")
        print("📊 Event data: \(userInfo)")
        
        // Create ThreatEvent from the notification data
        let threatEvent = ThreatEvent.fromNotification(type: eventName, userInfo: userInfo)
        
        // Save to SwiftData
        do {
            modelContext.insert(threatEvent)
            try modelContext.save()
            print("✅ Threat event saved successfully")
        } catch {
            print("❌ Failed to save threat event: \(error)")
        }
    }
    
    /// Removes all NotificationCenter observers to prevent memory leaks
    private func removeAllObservers() {
        let center = NotificationCenter.default
        for observer in observers {
            center.removeObserver(observer)
        }
        observers.removeAll()
    }
    
    /// Manually triggers a test notification for debugging purposes
    /// This method is for testing only and should not be used in production
    func triggerTestEvent(type: String) {
        let testUserInfo: [String: Any] = [
            "message": "Test \(type) event for debugging",
            "reasonCode": "TEST_001",
            "reasonData": "Test data payload",
            "currentThreatEventScore": 75,
            "threatEventsScore": 100
        ]
        
        NotificationCenter.default.post(
            name: Notification.Name(type),
            object: nil,
            userInfo: testUserInfo
        )
    }
}