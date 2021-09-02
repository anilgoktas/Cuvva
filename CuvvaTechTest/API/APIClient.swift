import Foundation
import Combine

struct APIClient {
  private(set) var events: () -> AnyPublisher<JSONResponse, Error>

  public init(
    events: @escaping () -> AnyPublisher<JSONResponse, Error>
  ) {
    self.events = events
  }
}

// MARK: Live API

extension APIClient {
  static let live = Self(
    events: {
      URLSession.shared.dataTaskPublisher(for: URL(string: "https://cuvva.herokuapp.com/08-10-2020")!)
        .map { data, _ in data }
        .decode(type: JSONResponse.self, decoder: apiJsonDecoder)
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
  })
}

// MARK: Mock API

extension APIClient {
  static let mockEmpty = Self(
    events: {
        Just(JSONResponse())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
  })
}
