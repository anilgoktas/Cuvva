import SwiftUI
import Combine

@main
struct CuvvaTechTestApp: App {
    
    /// Indicates that app should use live/production environment.
    private static let useLive = true
    
    /// Indicates that app is opened by unit testing. Check `Scheme < Test < Arguments`.
    private static var isUnitTesting: Bool { ProcessInfo.processInfo.arguments.contains("-UNITTEST") }
    
    private var appModel: AppViewModel = {
        guard useLive, !Self.isUnitTesting else {
            return .init(
                apiClient: .mockEmpty,
                policyModel: MockPolicyModel()
            )
        }
        
        return .init(
            apiClient: .live,
            policyModel: LivePolicyEventProcessor()
        )
    }()
    
    var body: some Scene {
        WindowGroup {
            HomeView(model: appModel)
               .environment(\.policyTermFormatter, LivePolicyTermFormatter())
               .environment(\.now, LiveTime())
        }
    }
}

// MARK: - App View Model

final class AppViewModel: ObservableObject {
    
    @Published private(set) var activePolicies = [Policy]()
    @Published private(set) var historicalVehicles = [Vehicle]()
    
    @Published var hasError = false
    @Published var isLoading = false
    
    private(set) var lastError: Error? {
        didSet {
            self.hasError = lastError != nil
        }
    }
    
    private var cancellationToken: AnyCancellable?
    
    // MARK: Dependencies
    
    private let apiClient: APIClient
    private let policyModel: PolicyEventProcessor
    
    // MARK: Public functions
    
    init(apiClient: APIClient, policyModel: PolicyEventProcessor) {
        self.apiClient = apiClient
        self.policyModel = policyModel
    }
    
    func reload(date: @escaping () -> Date) {
        isLoading = true
        
        cancellationToken = apiClient.events()
            .print("APIClient Reload")
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        self.lastError = error
                        fallthrough
                    case .finished:
                        self.isLoading = false
                    }
                },
            receiveValue: { response in
                self.policyModel.store(json: response)
                self.refreshData(for: date())
            }
        )
    }
    
    func refreshData(for date: Date) {
        let data = self.policyModel.retrieve(for: date)
        self.activePolicies = data.activePolicies
        self.historicalVehicles = data.historicVehicles
        self.objectWillChange.send()
    }
}
