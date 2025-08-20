import Foundation

/// A simple worker class for ICFP contest tasks
public class ICFPWorker {
    
    public init() {}
    
    /// Processes a given input and returns a result
    /// - Parameter input: The input to process
    /// - Returns: A processed result string
    public func process(_ input: String) -> String {
        return "Processed: \(input)"
    }
    
    /// Calculates a simple mathematical operation
    /// - Parameters:
    ///   - a: First number
    ///   - b: Second number
    /// - Returns: The sum of a and b
    public func calculate(a: Int, b: Int) -> Int {
        return a + b
    }
    
    /// Validates input data
    /// - Parameter data: The data to validate
    /// - Returns: True if valid, false otherwise
    public func validate(_ data: String) -> Bool {
        return !data.isEmpty && data.count > 2
    }
}