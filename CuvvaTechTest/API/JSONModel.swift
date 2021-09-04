import Foundation

// MARK: JSONDecoder config

let apiJsonDecoder: JSONDecoder = {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
    return jsonDecoder
}()

// MARK: JSON Response Decodable

typealias JSONResponse = [JSONEvent]

struct JSONEvent: Decodable {
    
    #warning("EventType?")
    enum Event: String, Decodable, CaseIterable {
        case policy_created
        case policy_extension
        case policy_cancelled
    }
    
    struct Payload: Decodable {
        
        struct Vehicle: Decodable {
            let prettyVrm: String
            let make: String
            let model: String
            
            enum CodingKeys: String, CodingKey {
                case prettyVrm = "prettyVrm"
                case make
                case model
            }
        }
        
        let timestamp: Date
        let policyId: String
        let originalPolicyId: String?
        let startDate: Date?
        let endDate: Date?
        let vehicle: Vehicle?
        /// May exist when type is `policy_cancelled`
        let newEndDate: Date?
    }
    
    let type: Event
    let payload: Payload
}
