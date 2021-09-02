import Foundation

final class LivePolicyEventProcessor: PolicyEventProcessor {
    
    /// In-memory store in order to create `PolicyData` for the given date on `retrieve(:)`.
    private var vehicleHistories = [VehicleHistory]()

}

// MARK: - Retrieve

extension LivePolicyEventProcessor {
    
    func retrieve(for: Date) -> PolicyData {
        let currentDate = `for`
        var activePolicies = [Policy]()
        var historicVehicles = [Vehicle]()
        
        for vehicleHistory in vehicleHistories {
            autoreleasepool {
                let vehicle = vehicleHistory.vehicle
                let policyHistories = vehicleHistory.policyHistories.filter { $0.timestamp < currentDate }
                guard !policyHistories.isEmpty else { return }
                
                if let activePolicyHistory = policyHistories.first(where: { $0.isActive(on: currentDate) }) {
                    // Configure active policy.
                    let activePolicy = activePolicyHistory.makePolicy()
                    vehicle.activePolicy = activePolicy
                    activePolicies.append(activePolicy)
                    
                    let historicalPolicies = policyHistories
                        .filter({ $0.id != activePolicyHistory.id })
                        .map { $0.makePolicy() }
                    vehicle.historicalPolicies = historicalPolicies
                } else {
                    // There is not any active policy.
                    let historicalPolicies = policyHistories.map { $0.makePolicy() }
                    vehicle.historicalPolicies = historicalPolicies
                    historicVehicles.append(vehicle)
                }
            }
        }
        
        return .init(
            activePolicies: activePolicies,
            historicVehicles: historicVehicles
        )
    }
    
}

// MARK: - Store

extension LivePolicyEventProcessor {
    
    struct PolicyResponse {
        let event: JSONEvent.Event
        let timestamp: Date
        let id: String
        let originalId: String?
        let startDate: Date?
        let endDate: Date?
        let payloadVehicle: JSONEvent.Payload.Vehicle?
        let newEndDate: Date?
        
        init(jsonEvent: JSONEvent) {
            event = jsonEvent.type
            timestamp = jsonEvent.payload.timestamp
            id = jsonEvent.payload.policyId
            originalId = jsonEvent.payload.originalPolicyId
            startDate = jsonEvent.payload.startDate
            endDate = jsonEvent.payload.endDate
            payloadVehicle = jsonEvent.payload.vehicle
            newEndDate = jsonEvent.payload.newEndDate
        }
        
        func makeVehicleID() -> Vehicle.ID? {
            guard let payloadVehicle = payloadVehicle else { return nil }
            return payloadVehicle.prettyVrm.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        func makeVehicle() -> Vehicle? {
            guard let vehicleID = makeVehicleID(), let payloadVehicle = payloadVehicle else {
                return nil
            }
            return Vehicle(
                id: vehicleID,
                displayVRM: payloadVehicle.prettyVrm,
                makeModel: payloadVehicle.make + " " + payloadVehicle.model
            )
        }
    }
    
    final class PolicyHistory {
        private let original: PolicyResponse
        let vehicle: Vehicle
        private var extensions: [PolicyResponse]
        private var cancellation: PolicyResponse?
        
        var id: Policy.ID { original.id }
        
        var timestamp: Date { original.timestamp }
        
        var startDate: Date { original.startDate! }
        
        var endDate: Date {
            if let cancellation = cancellation {
                return cancellation.newEndDate ?? cancellation.timestamp
            }
            if let lastExtension = extensions.last {
                return lastExtension.endDate!
            }
            return original.endDate!
        }
        
        init?(
            original: PolicyResponse,
            vehicle: Vehicle,
            extensions: [PolicyResponse] = [],
            cancellation: PolicyResponse? = nil
        ) {
            self.original = original
            self.vehicle = vehicle
            self.extensions = extensions
            self.cancellation = cancellation
        }
        
        func appendExtension(_ policyResponse: PolicyResponse) {
            extensions.append(policyResponse)
            extensions.sort(by: { $0.timestamp < $1.timestamp })
        }
        
        func setCancellation(_ cancellation: PolicyResponse) {
            self.cancellation = cancellation
        }
        
        func containsPolicy(_ policyID: Policy.ID) -> Bool {
            if original.id == policyID { return true }
            if extensions.contains(where: { $0.id == policyID }) { return true }
            if cancellation?.id == policyID { return true }
            return false
        }
        
        private func makePolicyTerm() -> PolicyTerm {
            let duration = startDate.distance(to: endDate)
            return PolicyTerm(startDate: startDate, duration: duration)
        }
        
        func makePolicy() -> Policy {
            Policy(id: id, term: makePolicyTerm(), vehicle: vehicle)
        }
        
        /// Indicates the policy is active on the given date.
        func isActive(on date: Date) -> Bool {
            startDate < date && endDate < date
        }
    }
    
    final class VehicleHistory {
        let vehicle: Vehicle
        private(set) var policyHistories: [PolicyHistory]
        
        init(vehicle: Vehicle, policyHistories: [PolicyHistory] = []) {
            self.vehicle = vehicle
            self.policyHistories = policyHistories
        }
        
        func appendPolicyHistory(_ policyHistory: PolicyHistory) {
            policyHistories.append(policyHistory)
            policyHistories.sort(by: { $0.startDate < $1.startDate })
        }
    }
    
    func store(json: JSONResponse) {
        var createdPolicies = [PolicyResponse]()
        var extendedPolicies = [PolicyResponse]()
        var cancelledPolicies = [PolicyResponse]()
        var vehicleDict = [Vehicle.ID: Vehicle]()
        
        // Configure policy and vehicle caches.
        for jsonEvent in json {
            autoreleasepool {
                let policyResponse = PolicyResponse(jsonEvent: jsonEvent)
                
                switch policyResponse.event {
                case .policy_created:
                    guard let vehicleID = policyResponse.makeVehicleID() else {
                        #warning("Inform backend that we have a failure - `vehicle` must exist on policy_created")
                        return
                    }
                    createdPolicies.append(policyResponse)
                    
                    if !vehicleDict.keys.contains(vehicleID) {
                        // Append the new vehicle.
                        vehicleDict[vehicleID] = policyResponse.makeVehicle()
                    }
                case .policy_extension:
                    if jsonEvent.payload.originalPolicyId == nil {
                        #warning("Inform backend that we have a failure - `original_policy_id` must exist on policy_extension")
                    }
                    extendedPolicies.append(policyResponse)
                case .policy_cancelled:
                    cancelledPolicies.append(policyResponse)
                }
            }
        }
        
        // Configure policy histories.
        let policyHistories = createdPolicies.compactMap { createdPolicy -> PolicyHistory? in
            guard let vehicleID = createdPolicy.makeVehicleID(),
                  let vehicle = vehicleDict[vehicleID]
            else { return nil }
            return PolicyHistory(original: createdPolicy, vehicle: vehicle)
        }
        
        // Update related policy histories using extended policies.
        for extendedPolicy in extendedPolicies {
            guard
                let originalPolicyID = extendedPolicy.originalId,
                let policyHistory = policyHistories.first(where: { $0.containsPolicy(originalPolicyID) })
            else { return }
            
            policyHistory.appendExtension(extendedPolicy)
        }
        
        // Update related policy histories using cancelled policies.
        for cancelledPolicy in cancelledPolicies {
            if let policyHistory = policyHistories.first(where: { $0.containsPolicy(cancelledPolicy.id) }) {
                policyHistory.setCancellation(cancelledPolicy)
            }
        }
        
        // Configure vehicle histories by using a caching dict.
        var vehicleHistoryDict = [Vehicle.ID: VehicleHistory]()
        
        for policyHistory in policyHistories {
            if let vehicleHistory = vehicleHistoryDict[policyHistory.vehicle.id] {
                vehicleHistory.appendPolicyHistory(policyHistory)
            } else {
                guard let vehicle = vehicleDict[policyHistory.vehicle.id] else {
                    continue
                }
                let vehicleHistory = VehicleHistory(vehicle: vehicle, policyHistories: [policyHistory])
                vehicleHistoryDict[vehicle.id] = vehicleHistory
            }
        }
        
        // Store in-memory.
        self.vehicleHistories = Array(vehicleHistoryDict.values)
    }
    
}
