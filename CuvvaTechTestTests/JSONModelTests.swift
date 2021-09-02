//
//  JSONModelTests.swift
//  JSONModelTests
//
//  Created by Anil Goktas on 8/31/21.
//

import XCTest
@testable import CuvvaTechTest

final class JSONModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var dateFormatter: DateFormatter? {
        switch apiJsonDecoder.dateDecodingStrategy {
        case .formatted(let dateFormatter):
            return dateFormatter
        default:
            return nil
        }
    }
    
}

// MARK: - APIJSONDecoder Tests

extension JSONModelTests {
    
    func test_apiJsonDecoder_keyDecodingStrategy() throws {
        // Given
        struct TestStruct: Decodable, Identifiable {
            let id: String
            let snakeCaseString: String
        }
        let id = "some_id"
        let snakeCaseString = "PT2H44M"
        
        let jsonString = """
        {
            "id": "\(id)",
            "snake_case_string": "\(snakeCaseString)"
        }
        """
        let jsonData = Data(jsonString.utf8)
        
        // When
        let testStruct = try apiJsonDecoder.decode(TestStruct.self, from: jsonData)
        
        // Then
        XCTAssertEqual(testStruct.id, id)
        XCTAssertEqual(testStruct.snakeCaseString, snakeCaseString)
    }
    
    func test_apiJsonDecoder_dateDecodingStrategy() throws {
        // Given
        struct TestStruct: Decodable, Identifiable {
            let id: String
            let date: Date
        }
        let id = "some_id"
        let dateString = "2021-08-31T18:11:31.031Z"
        
        let jsonString = """
        {
            "id": "\(id)",
            "date": "\(dateString)",
        }
        """
        let jsonData = Data(jsonString.utf8)
        
        // When
        let testStruct = try apiJsonDecoder.decode(TestStruct.self, from: jsonData)
        
        // Then
        XCTAssertEqual(testStruct.id, id)
        
        // Check if the date formatter's format string is correct.
        let dateFormatter = try XCTUnwrap(dateFormatter)
        let expectedDate = try XCTUnwrap(dateFormatter.date(from: dateString))
        XCTAssertEqual(testStruct.date.timeIntervalSince1970, expectedDate.timeIntervalSince1970)
        XCTAssertEqual(dateFormatter.string(from: testStruct.date), dateString)
    }
    
}

// MARK: - JSONEvent Tests

extension JSONModelTests {
    
    /// Based on API response structure.
    private func makeJSONEventData(
        type: JSONEvent.Event = .policy_created,
        timestampString: String = "2021-08-31T18:11:31.031Z",
        policyId: String = "dev_pol_0000003",
        originalPolicyId: String? = nil,
        startDateString: String? = nil,
        endDateString: String? = nil,
        vehicle: JSONEvent.Payload.Vehicle? = nil,
        newEndDateString: String? = nil
    ) throws -> Data {
        var dict = [String: Any]()
        dict["type"] = type.rawValue
        
        var payloadDict = [String: Any]()
        payloadDict["timestamp"] = timestampString
        payloadDict["policy_id"] = policyId
        payloadDict["original_policy_id"] = originalPolicyId
        payloadDict["start_date"] = startDateString
        payloadDict["end_date"] = endDateString
        payloadDict["new_end_date"] = newEndDateString
        
        if let vehicle = vehicle {
            var vehicleDict = [String: Any]()
            vehicleDict["prettyVrm"] = vehicle.prettyVrm
            vehicleDict["make"] = vehicle.make
            vehicleDict["model"] = vehicle.model
            payloadDict["vehicle"] = vehicleDict
        }
        dict["payload"] = payloadDict
        
        return try JSONSerialization.data(withJSONObject: dict, options: [])
    }
    
    func test_jsonEvent_decoding_events() throws {
        for policyType in JSONEvent.Event.allCases {
            try autoreleasepool {
                // Given
                let jsonData = try makeJSONEventData(type: policyType)
                
                // When
                let jsonEvent = try apiJsonDecoder.decode(JSONEvent.self, from: jsonData)
                
                // Then
                XCTAssertEqual(jsonEvent.type, policyType)
            }
        }
    }
    
    func test_jsonEvent_decoding_payloadWithoutVehicle() throws {
        // Given
        let timestampString = "2021-08-31T18:11:31.031Z"
        let policyId = "dev_pol_0000003"
        let originalPolicyId = "dev_pol_0000002"
        let startDateString = "2021-08-31T18:11:31.031Z"
        let endDateString = "2021-08-31T19:11:31.031Z"
        let jsonData = try makeJSONEventData(
            timestampString: timestampString,
            policyId: policyId,
            originalPolicyId: originalPolicyId,
            startDateString: startDateString,
            endDateString: endDateString
        )
        
        // When
        let jsonEvent = try apiJsonDecoder.decode(JSONEvent.self, from: jsonData)
        
        // Then
        XCTAssertEqual(jsonEvent.payload.policyId, policyId)
        XCTAssertEqual(jsonEvent.payload.originalPolicyId, originalPolicyId)
        
        let dateFormatter = try XCTUnwrap(dateFormatter)
        let timestamp = try XCTUnwrap(jsonEvent.payload.timestamp)
        XCTAssertEqual(dateFormatter.string(from: timestamp), timestampString)
        let startDate = try XCTUnwrap(jsonEvent.payload.startDate)
        XCTAssertEqual(dateFormatter.string(from: startDate), startDateString)
        let endDate = try XCTUnwrap(jsonEvent.payload.endDate)
        XCTAssertEqual(dateFormatter.string(from: endDate), endDateString)
        
        XCTAssertNil(jsonEvent.payload.vehicle)
        XCTAssertNil(jsonEvent.payload.newEndDate)
    }
    
    func test_jsonEvent_decoding_payloadVehicle() throws {
        // Given
        let prettyVRM = "MA77 GRO"
        let maker = "Volkswagen"
        let model = "Polo"
        let vehicle = JSONEvent.Payload.Vehicle(
            prettyVrm: prettyVRM,
            make: maker,
            model: model
        )
        let jsonData = try makeJSONEventData(vehicle: vehicle)
        
        // When
        let jsonEvent = try apiJsonDecoder.decode(JSONEvent.self, from: jsonData)
        
        // Then
        let payloadVehicle = try XCTUnwrap(jsonEvent.payload.vehicle)
        XCTAssertEqual(payloadVehicle.prettyVrm, prettyVRM)
        XCTAssertEqual(payloadVehicle.make, maker)
        XCTAssertEqual(payloadVehicle.model, model)
    }
    
}
