import Foundation

final class Policy: ObservableObject, Identifiable {
    
    let id: String
    let term: PolicyTerm
    #warning("Retain cycle, weak?")
    let vehicle: Vehicle
    
    init(id: String, term: PolicyTerm, vehicle: Vehicle) {
        self.id = id
        self.term = term
        self.vehicle = vehicle
    }
}

struct PolicyTerm {
    var startDate: Date
    var duration: TimeInterval
}
