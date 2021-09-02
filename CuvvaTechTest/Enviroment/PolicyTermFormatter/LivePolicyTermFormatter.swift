import Foundation

#warning("Write unit tests after deciding what to do on error cases.")

struct LivePolicyTermFormatter: PolicyTermFormatter {
    
    private let policyDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .full
        return dateFormatter
    }()
    
    func durationString(for duration: TimeInterval) -> String {
        let minute: TimeInterval = 60.0
        let hour: TimeInterval = 60.0 * minute
        let day: TimeInterval = 24 * hour
        
        let numberOfDays = Int(duration / day)
        if numberOfDays > 0 { return "\(numberOfDays) Day Policy" }
        
        let numberOfHours = Int(duration / hour)
        if numberOfHours > 0 { return "\(numberOfHours) Hour Policy" }
        #warning("Error case")
        return "Unknown Policy"
    }
    
    func durationRemainingString(for term: PolicyTerm, relativeTo date: Date) -> String {
        let endDate = term.startDate.addingTimeInterval(term.duration)
        let distance = date.distance(to: endDate)
        
        if distance <= 0 { return "Expired" }
        
        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropAll
        
        #warning("Error case")
        return formatter.string(from: distance) ?? "Unknown"
    }
    
    func durationRemainingPercent(for term: PolicyTerm, relativeTo date: Date) -> Double {
        let endDate = term.startDate.addingTimeInterval(term.duration)
        let distance = date.distance(to: endDate)
        let distancePercent = distance / term.duration
        
        if distancePercent <= 0 { return 0 }
        if distancePercent >= 1 { return 1 }
        
        return distancePercent
    }
    
    func policyDateString(for date: Date) -> String {
        #warning("Mock format requires `NumberFormatter` for ordinal day format.")
        return policyDateFormatter.string(from: date)
    }
}

