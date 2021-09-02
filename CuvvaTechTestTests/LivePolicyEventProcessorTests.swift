//
//  LivePolicyEventProcessorTests.swift
//  LivePolicyEventProcessorTests
//
//  Created by Anil Goktas on 9/2/21.
//

import XCTest
@testable import CuvvaTechTest

final class LivePolicyEventProcessorTests: XCTestCase { }

// MARK: - Retrieve Tests

extension LivePolicyEventProcessorTests {
    
    func test_retrieve_emptyStore_shouldReturnEmpty() {
        // Given
        let subject = LivePolicyEventProcessor()
        
        // When
        subject.store(json: [])
        let policyData = subject.retrieve(for: Date())
        
        // Then
        XCTAssertTrue(policyData.activePolicies.isEmpty)
        XCTAssertTrue(policyData.historicVehicles.isEmpty)
    }
    
    func test_retrieve_activePolicy() {
        // Given
        let startDate = Date.makeDate(year: 2021, month: 8, day: 25)
        let endDate = Date.makeDate(year: 2021, month: 9, day: 2)
        let jsonEvent = makeSampleJSONEvent(startDate: startDate, endDate: endDate)
        let subject = LivePolicyEventProcessor()
        
        // When
        subject.store(json: [jsonEvent])
        let retrieveDate = Date.makeDate(year: 2021, month: 8, day: 28)
        let policyData = subject.retrieve(for: retrieveDate)
        
        // Then
        XCTAssertEqual(policyData.activePolicies.count, 1)
        XCTAssertTrue(policyData.historicVehicles.isEmpty)
    }
    
    func test_retrieve_historicVehicle() {
        // Given
        let startDate = Date.makeDate(year: 2021, month: 8, day: 25)
        let endDate = Date.makeDate(year: 2021, month: 9, day: 2)
        let jsonEvent = makeSampleJSONEvent(startDate: startDate, endDate: endDate)
        let subject = LivePolicyEventProcessor()
        
        // When
        subject.store(json: [jsonEvent])
        let retrieveDate = Date.makeDate(year: 2021, month: 9, day: 5)
        let policyData = subject.retrieve(for: retrieveDate)
        
        // Then
        XCTAssertTrue(policyData.activePolicies.isEmpty)
        XCTAssertEqual(policyData.historicVehicles.count, 1)
    }
    
}

// MARK: - Store Tests PolicyResponse

extension LivePolicyEventProcessorTests {
    
    func test_policyResponse_withoutVehicle() {
        // Given
        let date = Date()
        let jsonEvent = JSONEvent(
            type: .policy_extension,
            payload: .init(
                timestamp: date,
                policyId: "policy_id",
                originalPolicyId: "original_policy_id",
                startDate: date,
                endDate: date,
                vehicle: nil,
                newEndDate: nil
            )
        )
        let subject = LivePolicyEventProcessor.PolicyResponse(jsonEvent: jsonEvent)
        
        // When
        let vehicleID = subject.makeVehicleID()
        let vehicle = subject.makeVehicle()
        
        // Then
        XCTAssertNil(vehicleID)
        XCTAssertNil(vehicle)
    }
    
    func test_policyResponse_withVehicle() throws {
        // Given
        let date = Date()
        let vehiclePrettyVRM = "D1 PLO"
        let vehicleMake = "Mercedes-Benz"
        let vehicleModel = "C350"
        let jsonEvent = JSONEvent(
            type: .policy_extension,
            payload: .init(
                timestamp: date,
                policyId: "policy_id",
                originalPolicyId: "original_policy_id",
                startDate: date,
                endDate: date,
                vehicle: .init(
                    prettyVrm: vehiclePrettyVRM,
                    make: vehicleMake,
                    model: vehicleModel
                ),
                newEndDate: nil
            )
        )
        let subject = LivePolicyEventProcessor.PolicyResponse(jsonEvent: jsonEvent)
        
        // When
        let vehicleID = try XCTUnwrap(subject.makeVehicleID())
        let vehicle = try XCTUnwrap(subject.makeVehicle())
        
        // Then
        XCTAssertEqual(vehicleID, vehiclePrettyVRM.trimmingCharacters(in: .whitespacesAndNewlines))
        XCTAssertEqual(vehicle.id, vehicleID)
        XCTAssertEqual(vehicle.displayVRM, vehiclePrettyVRM)
        XCTAssertEqual(vehicle.makeModel, vehicleMake + " " + vehicleModel)
        XCTAssertNil(vehicle.activePolicy)
        XCTAssertTrue(vehicle.historicalPolicies.isEmpty)
    }
    
}

// MARK: - Store Tests PolicyHistory

extension LivePolicyEventProcessorTests {
    
    func test_policyHistory_initAndFactories() throws {
        // Given
        let startDate = Date.makeDate(year: 2021, month: 8, day: 25)
        let endDate = Date.makeDate(year: 2021, month: 9, day: 2)
        let jsonEvent = JSONEvent(
            type: .policy_created,
            payload: .init(
                timestamp: startDate,
                policyId: "policy_id",
                originalPolicyId: nil,
                startDate: startDate,
                endDate: endDate,
                vehicle: .init(
                    prettyVrm: "D1 PLO",
                    make: "Mercedes-Benz",
                    model: "C350"
                ),
                newEndDate: nil
            )
        )
        let policyResponse = LivePolicyEventProcessor.PolicyResponse(jsonEvent: jsonEvent)
        let vehicle = Vehicle(id: "D1PLO", displayVRM: "D1 PLO", makeModel: "Mercedes-Benz C350")
        let subject = try XCTUnwrap(
            LivePolicyEventProcessor.PolicyHistory(original: policyResponse, vehicle: vehicle)
        )
        
        // When & Then
        XCTAssertEqual(subject.id, policyResponse.id)
        XCTAssertEqual(subject.timestamp.timeIntervalSince1970, policyResponse.timestamp.timeIntervalSince1970)
        XCTAssertEqual(subject.startDate.timeIntervalSince1970, policyResponse.startDate?.timeIntervalSince1970)
        XCTAssertEqual(subject.endDate.timeIntervalSince1970, policyResponse.endDate?.timeIntervalSince1970)
        
        XCTAssertTrue(subject.containsPolicy("policy_id"))
        XCTAssertFalse(subject.containsPolicy("some_another_policy_id"))
        
        let expectedActiveDate = Date.makeDate(year: 2021, month: 8, day: 29)
        XCTAssertTrue(subject.isActive(on: expectedActiveDate))
        let expectedInactiveDate = Date.makeDate(year: 2021, month: 9, day: 15)
        XCTAssertFalse(subject.isActive(on: expectedInactiveDate))
        
        let policy = subject.makePolicy()
        XCTAssertEqual(policy.id, subject.id)
        XCTAssertEqual(policy.term.startDate.timeIntervalSince1970, subject.startDate.timeIntervalSince1970)
        XCTAssertEqual(policy.term.duration, subject.startDate.distance(to: subject.endDate))
        XCTAssertEqual(policy.vehicle.id, vehicle.id)
    }
    
    func test_policyHistory_extensionsAndCancellation() throws {
        // Given
        let startDate = Date.makeDate(year: 2021, month: 8, day: 25)
        let endDate = Date.makeDate(year: 2021, month: 9, day: 2)
        let jsonEvent = JSONEvent(
            type: .policy_created,
            payload: .init(
                timestamp: startDate,
                policyId: "policy_id",
                originalPolicyId: nil,
                startDate: startDate,
                endDate: endDate,
                vehicle: nil,
                newEndDate: nil
            )
        )
        let policyResponse = LivePolicyEventProcessor.PolicyResponse(jsonEvent: jsonEvent)
        let vehicle = Vehicle(id: "D1PLO", displayVRM: "D1 PLO", makeModel: "Mercedes-Benz C350")
        let subject = try XCTUnwrap(
            LivePolicyEventProcessor.PolicyHistory(original: policyResponse, vehicle: vehicle)
        )
        
        // When first extended
        let extensionStartDate = endDate
        let extensionEndDate = Date.makeDate(year: 2021, month: 9, day: 5)
        let extensionJSONEvent = JSONEvent(
            type: .policy_extension,
            payload: .init(
                timestamp: extensionStartDate,
                policyId: "extension_policy_id",
                originalPolicyId: "policy_id",
                startDate: extensionStartDate,
                endDate: extensionEndDate,
                vehicle: nil,
                newEndDate: nil
            )
        )
        let extendedPolicyResponse = LivePolicyEventProcessor.PolicyResponse(jsonEvent: extensionJSONEvent)
        subject.appendExtension(extendedPolicyResponse)
        
        XCTAssertTrue(subject.containsPolicy("extension_policy_id"))
        XCTAssertEqual(subject.endDate.timeIntervalSince1970, extensionEndDate.timeIntervalSince1970)
        let extensionActiveDate = Date.makeDate(year: 2021, month: 9, day: 4)
        XCTAssertTrue(subject.isActive(on: extensionActiveDate))
        let extensionInactiveDate = Date.makeDate(year: 2021, month: 9, day: 15)
        XCTAssertFalse(subject.isActive(on: extensionInactiveDate))
        
        // When second extended
        let extension2StartDate = endDate
        let extension2EndDate = Date.makeDate(year: 2021, month: 9, day: 8)
        let extension2JSONEvent = JSONEvent(
            type: .policy_extension,
            payload: .init(
                timestamp: extension2StartDate,
                policyId: "extension2_policy_id",
                originalPolicyId: "policy_id",
                startDate: extension2StartDate,
                endDate: extension2EndDate,
                vehicle: nil,
                newEndDate: nil
            )
        )
        let extended2PolicyResponse = LivePolicyEventProcessor.PolicyResponse(jsonEvent: extension2JSONEvent)
        subject.appendExtension(extended2PolicyResponse)
        
        XCTAssertTrue(subject.containsPolicy("extension2_policy_id"))
        XCTAssertEqual(subject.endDate.timeIntervalSince1970, extension2EndDate.timeIntervalSince1970)
        let extension2ActiveDate = Date.makeDate(year: 2021, month: 9, day: 6)
        XCTAssertTrue(subject.isActive(on: extension2ActiveDate))
        let extension2InactiveDate = Date.makeDate(year: 2021, month: 9, day: 15)
        XCTAssertFalse(subject.isActive(on: extension2InactiveDate))
        
        // When cancelled
        let cancelDate = Date.makeDate(year: 2021, month: 9, day: 7)
        let cancellationJSONEvent = JSONEvent(
            type: .policy_extension,
            payload: .init(
                timestamp: cancelDate,
                policyId: "extension2_policy_id",
                originalPolicyId: nil,
                startDate: nil,
                endDate: nil,
                vehicle: nil,
                newEndDate: nil
            )
        )
        let cancellationPolicyResponse = LivePolicyEventProcessor.PolicyResponse(jsonEvent: cancellationJSONEvent)
        subject.setCancellation(cancellationPolicyResponse)
        
        XCTAssertEqual(subject.endDate.timeIntervalSince1970, cancelDate.timeIntervalSince1970)
    }
    
}

// MARK: - Store Tests VehicleHistory

extension LivePolicyEventProcessorTests {
    
    func test_vehicleHistory() throws {
        // Given
        let vehicle = Vehicle(id: "D1PLO", displayVRM: "D1 PLO", makeModel: "Mercedes-Benz C350")
        let subject = LivePolicyEventProcessor.VehicleHistory(vehicle: vehicle)
        
        // Initial Then
        XCTAssertEqual(subject.vehicle.id, vehicle.id)
        XCTAssertTrue(subject.policyHistories.isEmpty)
        
        // When appending new policy history
        let newPolicyHistory = try makePolicyHistory(
            policyID: "second_policy_id",
            startDate: Date.makeDate(year: 2021, month: 9, day: 2),
            endDate: Date.makeDate(year: 2021, month: 9, day: 5),
            vehicle: vehicle
        )
        subject.appendPolicyHistory(newPolicyHistory)
        XCTAssertEqual(subject.policyHistories.count, 1)
        
        // When appending old policy history
        let oldPolicyHistory = try makePolicyHistory(
            policyID: "first_policy_id",
            startDate: Date.makeDate(year: 2021, month: 8, day: 25),
            endDate: Date.makeDate(year: 2021, month: 8, day: 28),
            vehicle: vehicle
        )
        subject.appendPolicyHistory(oldPolicyHistory)
        XCTAssertEqual(subject.policyHistories.count, 2)
        
        // Policy histories should be sorted by date
        let first = try XCTUnwrap(subject.policyHistories.first)
        let second = try XCTUnwrap(subject.policyHistories.last)
        
        XCTAssertEqual(first.id, oldPolicyHistory.id)
        XCTAssertEqual(second.id, newPolicyHistory.id)
    }
    
}

// MARK: - Store Tests

extension LivePolicyEventProcessorTests {
    
    func test_store_singleVehicle_singlePolicyHistory() throws {
        // Given
        let jsonEvent = makeSampleJSONEvent()
        let subject = LivePolicyEventProcessor()
        
        // When
        subject.store(json: [jsonEvent])
        
        // Then
        XCTAssertEqual(subject.vehicleHistories.count, 1)
        let vehicleHistory = try XCTUnwrap(subject.vehicleHistories.first)
        XCTAssertEqual(vehicleHistory.policyHistories.count, 1)
    }
    
    func test_store_singleVehicleWithExtension_singlePolicyHistory() throws {
        // Given
        let jsonEvent = makeSampleJSONEvent()
        let extensionJSONEvent = makeSampleJSONEvent(
            event: .policy_extension,
            policyID: "extension_policy_id",
            originalPolicyID: jsonEvent.payload.policyId
        )
        let subject = LivePolicyEventProcessor()
        
        // When
        subject.store(json: [jsonEvent, extensionJSONEvent])
        
        // Then
        XCTAssertEqual(subject.vehicleHistories.count, 1)
        let vehicleHistory = try XCTUnwrap(subject.vehicleHistories.first)
        XCTAssertEqual(vehicleHistory.policyHistories.count, 1)
    }
    
    func test_store_singleVehicle_multiplePolicyHistories() throws {
        // Given
        let creationJSONEvent = makeSampleJSONEvent()
        let anotherCreationJSONEvent = makeSampleJSONEvent(
            policyID: "another_policy_id"
        )
        let subject = LivePolicyEventProcessor()
        
        // When
        subject.store(json: [creationJSONEvent, anotherCreationJSONEvent])
        
        // Then
        XCTAssertEqual(subject.vehicleHistories.count, 1)
        let vehicleHistory = try XCTUnwrap(subject.vehicleHistories.first)
        XCTAssertEqual(vehicleHistory.vehicle.displayVRM, creationJSONEvent.payload.vehicle?.prettyVrm)
        XCTAssertEqual(vehicleHistory.policyHistories.count, 2)
    }
    
    func test_store_multipleVehicles() throws {
        // Given
        let jsonEvent = makeSampleJSONEvent()
        let anotherJSONEvent = makeSampleJSONEvent(
            policyID: "another_policy_id",
            vehiclePrettyVRM: "Unique Pretty VRM"
        )
        let subject = LivePolicyEventProcessor()
        
        // When
        subject.store(json: [jsonEvent, anotherJSONEvent])
        
        // Then
        XCTAssertEqual(subject.vehicleHistories.count, 2)
        XCTAssertTrue(
            subject.vehicleHistories.contains(where: {
                $0.vehicle.displayVRM == jsonEvent.payload.vehicle?.prettyVrm
            })
        )
        XCTAssertTrue(
            subject.vehicleHistories.contains(where: {
                $0.vehicle.displayVRM == anotherJSONEvent.payload.vehicle?.prettyVrm
            })
        )
    }
    
}

// MARK: - Helpers

extension LivePolicyEventProcessorTests {
    
    private func makePolicyHistory(
        policyID: Policy.ID = "policy_id",
        startDate: Date,
        endDate: Date,
        vehicle: Vehicle,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> LivePolicyEventProcessor.PolicyHistory {
        let jsonEvent = JSONEvent(
            type: .policy_created,
            payload: .init(
                timestamp: startDate,
                policyId: policyID,
                originalPolicyId: nil,
                startDate: startDate,
                endDate: endDate,
                vehicle: nil,
                newEndDate: nil
            )
        )
        let policyResponse = LivePolicyEventProcessor.PolicyResponse(jsonEvent: jsonEvent)
        return try XCTUnwrap(
            LivePolicyEventProcessor.PolicyHistory(original: policyResponse, vehicle: vehicle),
            file: file,
            line: line
        )
    }
    
    private func makeSampleJSONEvent(
        event: JSONEvent.Event = .policy_created,
        policyID: Policy.ID = "policy_id",
        originalPolicyID: Policy.ID? = nil,
        startDate: Date = .makeDate(year: 2021, month: 8, day: 25),
        endDate: Date = .makeDate(year: 2021, month: 9, day: 2),
        vehiclePrettyVRM: String = "D1 PLO",
        vehicleMake: String = "Mercedes-Benz",
        vehicleModel: String = "C350"
    ) -> JSONEvent {
        return JSONEvent(
            type: event,
            payload: .init(
                timestamp: startDate,
                policyId: policyID,
                originalPolicyId: originalPolicyID,
                startDate: startDate,
                endDate: endDate,
                vehicle: .init(
                    prettyVrm: vehiclePrettyVRM,
                    make: vehicleMake,
                    model: vehicleModel
                ),
                newEndDate: nil
            )
        )
    }
    
    
}

private extension Date {
    
    static func makeDate(year: Int, month: Int, day: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.timeZone = TimeZone.current
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        return Calendar.current.date(from: dateComponents)!
    }
    
}
