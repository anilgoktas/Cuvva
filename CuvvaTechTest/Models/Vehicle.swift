import Foundation

final class Vehicle: ObservableObject, Identifiable {
    
    let id: String
    /// Vehicle registration mark.
    let displayVRM: String
    let makeModel: String
    
    @Published var activePolicy: Policy?
    @Published var historicalPolicies: [Policy]
    
    init(id: String,
         displayVRM: String,
         makeModel: String,
         activePolicy: Policy? = nil,
         historicalPolicies: [Policy] = []
    ) {
        self.id = id
        self.displayVRM = displayVRM
        self.makeModel = makeModel
        self._activePolicy = .init(initialValue: activePolicy)
        self._historicalPolicies = .init(wrappedValue: historicalPolicies)
    }
    
}
