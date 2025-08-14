//
//  businesscardTests.swift
//  businesscardTests
//
//  Created by Gleidson L Medeiros on 13/08/25.
//

import Testing
@testable import businesscard

struct businesscardTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func threatEventCreation() async throws {
        // Test ThreatEvent initialization
        let event = ThreatEvent(
            threatType: "TestThreat",
            title: "Test Title",
            description: "Test Description",
            severity: "High"
        )
        
        #expect(event.threatType == "TestThreat")
        #expect(event.title == "Test Title")
        #expect(event.threatDescription == "Test Description")
        #expect(event.severity == "High")
        #expect(event.detectionMode == "In-App Detection")
        #expect(event.isActive == true)
    }
    
    @Test func threatEventFactoryMethods() async throws {
        // Test factory methods for threat events
        let debuggerEvent = ThreatEvent.debuggerThreatDetected()
        #expect(debuggerEvent.threatType == "DebuggerThreatDetected")
        #expect(debuggerEvent.title == "Debugger Detected")
        #expect(debuggerEvent.severity == "High")
        
        let debuggableEvent = ThreatEvent.debuggableEntitlement()
        #expect(debuggableEvent.threatType == "DebuggableEntitlement")
        #expect(debuggableEvent.title == "Debug Entitlement Detected")
        #expect(debuggableEvent.severity == "Medium")
        
        let integrityEvent = ThreatEvent.appIntegrityError()
        #expect(integrityEvent.threatType == "AppIntegrityError")
        #expect(integrityEvent.title == "App Integrity Violation")
        #expect(integrityEvent.severity == "Critical")
    }

}
