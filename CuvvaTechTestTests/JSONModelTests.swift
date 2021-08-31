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
