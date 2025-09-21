//
//  SafeCalculations.swift
//  Brrow
//
//  Safe calculation utilities to prevent NaN and infinity values in UI
//

import Foundation
import CoreGraphics

extension Double {
    /// Returns a safe double value, converting NaN and infinity to the fallback value
    /// - Parameter fallback: Value to return if this double is NaN or infinite (default: 0)
    /// - Returns: Safe double value
    func safe(_ fallback: Double = 0.0) -> Double {
        return self.isNaN || self.isInfinite ? fallback : self
    }

    /// Safe division that prevents NaN
    /// - Parameters:
    ///   - divisor: Value to divide by
    ///   - fallback: Value to return if divisor is zero (default: 0)
    /// - Returns: Safe division result
    func safeDivided(by divisor: Double, fallback: Double = 0.0) -> Double {
        guard divisor != 0 else { return fallback }
        let result = self / divisor
        return result.safe(fallback)
    }
}

extension CGFloat {
    /// Returns a safe CGFloat value, converting NaN and infinity to the fallback value
    /// - Parameter fallback: Value to return if this CGFloat is NaN or infinite (default: 0)
    /// - Returns: Safe CGFloat value
    func safe(_ fallback: CGFloat = 0.0) -> CGFloat {
        return self.isNaN || self.isInfinite ? fallback : self
    }

    /// Safe division that prevents NaN
    /// - Parameters:
    ///   - divisor: Value to divide by
    ///   - fallback: Value to return if divisor is zero (default: 0)
    /// - Returns: Safe division result
    func safeDivided(by divisor: CGFloat, fallback: CGFloat = 0.0) -> CGFloat {
        guard divisor != 0 else { return fallback }
        let result = self / divisor
        return result.safe(fallback)
    }
}

extension CGSize {
    /// Returns a safe CGSize with valid width and height values
    /// - Parameter fallback: Size to return if any dimension is invalid
    /// - Returns: Safe CGSize
    func safe(_ fallback: CGSize = .zero) -> CGSize {
        guard width.isFinite && height.isFinite && width >= 0 && height >= 0 else {
            return fallback
        }
        return self
    }

    /// Creates a safe aspect ratio calculation
    var safeAspectRatio: CGFloat {
        return height > 0 ? width.safeDivided(by: height, fallback: 1.0) : 1.0
    }
}

extension CGRect {
    /// Returns a safe CGRect with valid dimensions
    /// - Parameter fallback: Rect to return if any dimension is invalid
    /// - Returns: Safe CGRect
    func safe(_ fallback: CGRect = .zero) -> CGRect {
        guard origin.x.isFinite && origin.y.isFinite &&
              size.width.isFinite && size.height.isFinite &&
              size.width >= 0 && size.height >= 0 else {
            return fallback
        }
        return self
    }
}

// MARK: - Safe Rating Calculations
extension Collection where Element: Numeric {
    /// Calculate safe average from a collection of numeric values
    /// - Parameter fallback: Value to return if collection is empty or average is invalid
    /// - Returns: Safe average value
    func safeAverage<T: BinaryFloatingPoint>(as type: T.Type = T.self, fallback: T = 0) -> T {
        guard !isEmpty else { return fallback }

        let sum = reduce(T(0)) { result, element in
            if let value = element as? T {
                return result + value
            } else if let intValue = element as? Int {
                return result + T(intValue)
            } else if let doubleValue = element as? Double {
                return result + T(doubleValue)
            }
            return result
        }

        let average = sum / T(count)
        return average.isNaN || average.isInfinite ? fallback : average
    }
}

// MARK: - Safe UI Progress Calculations
struct SafeProgress {
    /// Calculate safe progress percentage
    /// - Parameters:
    ///   - current: Current value
    ///   - total: Total value
    ///   - fallback: Fallback percentage (default: 0)
    /// - Returns: Safe progress percentage between 0 and 100
    static func percentage(current: Double, total: Double, fallback: Double = 0.0) -> Double {
        guard total > 0 else { return fallback }
        let progress = (current / total) * 100
        return max(0, min(100, progress.safe(fallback)))
    }

    /// Calculate safe progress ratio
    /// - Parameters:
    ///   - current: Current value
    ///   - total: Total value
    ///   - fallback: Fallback ratio (default: 0)
    /// - Returns: Safe progress ratio between 0 and 1
    static func ratio(current: Double, total: Double, fallback: Double = 0.0) -> Double {
        guard total > 0 else { return fallback }
        let progress = current / total
        return max(0, min(1, progress.safe(fallback)))
    }
}