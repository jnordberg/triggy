// RationalNumber.swift
//
// A basic implementation of Rational numbers in Swift 3.0.
// (c) 2016 Hooman Mehr. Licensed under Apache License v2.0 with Runtime Library Exception



/// A data type to model rational numbers in Swift.
///
/// It always uses fully-reduced representation for simplicity and clarity of comparisons and uses LCM
/// (lowest common multiple) for addition & subtraction to reduce the chance of overflow in the middle
/// of computations. The disadvantage of these design choices are: It is not guaranteed to keep the numerator
/// and denominator as specified during construction, and GCD / LCM computations reduce its performance.
/// The performance trade-off is not huge and is usually acceptable for typical rational number use cases.
/// Preserving denominator can be addressed with a number formatter for rational numbers that I will
/// add later.
///
/// Basic comparision and math operators are defined, along with initializers and additional
/// operator overloads to ease mixing rational number calculations with integer (Int) and
/// floating point (Double) numbers.
///
/// A new ± operator is defined to help create rational numbers from floating point numbers by specifying a
/// conversion tolerace, e.g.: 0.109±0.0005 gives ⁵⁄₄₆.

public struct Rational {

    /// The numerator of the fraction.
    ///
    /// Also carries the sign of the Rational number.
    public let numerator: Int

    /// The denominator of the fraction.
    ///
    /// - Precondition: `denominator > 0`
    public let denominator : Int


    /// Main initilizer to make a rational from the given numerator and denominator.
    ///
    /// - Precondition: `denominator != 0`

    public init(_ numerator: Int, over denominator: Int) {

        precondition(denominator != 0, "Denominator can't be zero.")

        let divisor = gcd(Swift.abs(numerator), Swift.abs(denominator))

        let num = (denominator > 0 ? numerator : -numerator) / divisor
        let denom = Swift.abs(denominator) / divisor

        self.init(numerator: num, denominator: denom)
    }


    /// Returns a rational that is the inverse of `self`.
    ///
    /// More efficient than computing `1/self`.
    ///
    /// - Precondition: `self != 0`

    public func inverted() -> Rational {

        precondition(numerator != 0, "Zero can't be inverted.")

        return Rational(numerator: numerator < 0 ? -denominator: denominator,
                        denominator: Swift.abs(numerator))
    }

    /// Returns a rational that has the smallest possible denominator that does not exceed the specified tolerance.
    ///
    /// Note that tolerance is a value, not a ratio.

    public func rounded(withTolerance tolerance: Double) -> Rational {

        precondition(tolerance >= 0 && tolerance < 1, "Tolerance value should be less than one and greater than or equal to zero.")

        return Rational(Double(numerator)/Double(denominator), tolerance: tolerance)
    }



    /// Returns a rational that has the smallest possible denominator that does not exceed the specified tolerance.
    ///
    /// Note that tolerance is a relative percentage.

    public func rounded(withTolerance tolerance: Percentage) -> Rational {

        return rounded(withTolerance: self*tolerance)
    }


    /// Returns a rational rounded to the specified denominator.
    ///
    /// The resulting denominator may be smaller than the specified denominator, as any rational is always
    /// kept in fully reduced form.
    ///
    /// - Precondition: `self != 0`

    public func rounded(toDenominator newDenominator: Int) -> Rational {

        precondition(newDenominator > 0, "Denominator can't be negative or zero.")

        return Rational(Int((Double(numerator)/Double(denominator) * Double(newDenominator)).rounded()), over: newDenominator)
    }



    /// Internal memberwise initializer without validation.
    /// Only use with pre-validated parameter values.
    ///
    /// - Precondition: `denominator > 0 && gcd(numerator,denominator) == 1`

    internal init(numerator: Int, denominator: Int) {

        // Assertion of design assumptions:
        assert(denominator != 0, "Can create Rational with denominator of zero.")
        assert(denominator >  0, "Can create Rational: Sign should be carried by numerator.")
        assert(gcd(Swift.abs(numerator),denominator) == 1, "Can create Rational: Greatest common divisor of numerator & denominator should be 1.")

        self.numerator = numerator
        self.denominator = denominator
    }
}



// MARK: Hashable

extension Rational: Hashable {

    public var hashValue : Int {

        return numerator.hashValue ^ denominator.hashValue
    }
}



//MARK: AbsoluteValuable

extension Rational: AbsoluteValuable {


    public static func abs(_ x: Rational) -> Rational {

        return Rational(numerator: Swift.abs(x.numerator), denominator: x.denominator)
    }

    // AbsoluteValuable implies: ExpressibleByIntegerLiteral, Equatable, Comparable, SignedNumber


    //MARK: ExpressibleByIntegerLiteral

    public init(integerLiteral value: Int) {

        self.init(value)
    }


    //MARK: Equatable

    public static func ==(lhs: Rational, rhs: Rational) -> Bool {

        return lhs.numerator == rhs.numerator && lhs.denominator == rhs.denominator
    }


    //MARK: Comparable

    public static func <(lhs: Rational, rhs: Rational) -> Bool {

        return lhs.numerator * rhs.denominator < rhs.numerator * lhs.denominator
    }


    //MARK: SignedNumber

    public prefix static func -(x: Rational) -> Rational {

        return Rational(numerator: -x.numerator, denominator: x.denominator)
    }

    public static func -(lhs: Rational, rhs: Rational) -> Rational {

        let (lnum, rnum, denom) = numsWithCommonDenom(lhs, rhs)

        return Rational(lnum - rnum, over: denom)
    }
}





extension Rational: Strideable {

    public func advanced(by n: Rational) -> Rational {

        return self + n
    }

    public func distance(to other: Rational) -> Rational {

        return other - self
    }
}




extension Rational: CustomStringConvertible {


    public var description: String {

        let superscriptDigits: [Character:Character]
            = ["-":"⁻", "0":"⁰", "1":"¹", "2":"²", "3":"³", "4":"⁴", "5":"⁵", "6":"⁶", "7":"⁷", "8":"⁸", "9":"⁹"]
        let subscriptDigits: [Character:Character]
            = ["-":"⁻", "0":"₀", "1":"₁", "2":"₂", "3":"₃", "4":"₄", "5":"₅", "6":"₆", "7":"₇", "8":"₈", "9":"₉"]


        let absnum = Swift.abs(numerator)
        let num = String(absnum % denominator)
        let denom = String(denominator)

        let sign  = numerator>=0       ? "" : "-"
        let whole = absnum<denominator ? "" : String(absnum/denominator)
        let frac  = denominator==1     ? "" : "\(num.mapped(with: superscriptDigits))⁄\(denom.mapped(with: subscriptDigits))"

        return "\(sign)\(whole)\(frac)" }
}




extension Rational {


    /// Convert from an Int.

    public init(_ value: Int) {

        self.init(value, over: 1)
    }


    /// Convert from a Double.
    ///
    /// By default, creates a rational with the smallest denominator that satisfies the tolerance.
    /// The default tolerance is 0.00005. If you pass a tolerance of zero, an exact conversion
    /// of the binary floating point representation will be performed, which may not be what you want.
    ///
    /// You may pass a list of preferred denominators to try first before falling back to smallest
    /// denominator algorithm.
    ///
    /// - Parameter x: A Double value to convert to rational.
    ///
    /// - Parameter tolerance: The maximum acceptable amount of error of the conversion. Defaults to
    ///   0.00005. A tolerance of 0.0 causes an exact conversion of binary floting point which
    ///   may itself be in error as a result of a previous convertion of a rational (such as decimal
    ///   fraction) to binary floating point.
    ///
    /// - Parameter preferredDenominators: An array of denominators to use for the rational in the
    ///   order of preference. The first denominator that produces a result within the tolerance
    ///   will be selected. Defaults to empty array [].
    ///
    /// - Precondition: 0.0 <= tolerance < 1.0

    public init(_ x: Double, tolerance: Double = 0.00005, preferredDenominators: [Int] = [] ) {

        precondition(tolerance >= 0 && tolerance < 1, "Tolerance value should be less than one and greater than or equal to zero.")

        if tolerance == 0.0 {

            if x.isZero {

                self.init(numerator: 0, denominator: 1)

            } else {

                guard x.isNormal else { fatalError("Floating point number can't be represented as Rational.") }

                // `x.significandBitPattern == 0` is a workaround for bug SR-2868
                let width = x.significandBitPattern == 0 ? 0 : x.significandWidth

                var num = 1 << width
                num += Int(x.significandBitPattern >> UInt64(Double.significandBitCount - width))
                if x.sign == .minus { num = -num }

                let denom = width > x.exponent ? 1 << (width - x.exponent) : 1

                self.init(numerator: num, denominator: denom)

                //FIXME: Detect and throw a fatal error message for overflow to aid in debugging.
            }

        } else {

            for denom in preferredDenominators {

                let num = denom.scaled(by: x)

                if Swift.abs(Double(num)/Double(denom) - x) <= tolerance {

                    self.init(num, over: denom)

                    return
                }
            }

            var num   = (1, 0)
            var denom = (0, 1)

            var fractional = x
            var integral: Int

            repeat {

                integral = Int(fractional.rounded(.down))

                num   = (integral * num.0   + num.1,   num.0)
                denom = (integral * denom.0 + denom.1, denom.0)

                fractional = 1.0/(fractional-Double(integral))

            } while Swift.abs(x-Double(num.0)/Double(denom.0)) > tolerance

            self.init(num.0, over: denom.0)
        }
    }



    /// Convert from a Double.
    ///

    public init(_ x: Double, tolerance: Percentage = 0.01%, preferredDenominators: [Int] = [] ) {

        self.init(x, tolerance: x*tolerance, preferredDenominators: preferredDenominators)
    }


    public static func +(lhs: Rational, rhs: Rational) -> Rational {

        let (lnum, rnum, denom) = numsWithCommonDenom(lhs, rhs)

        return Rational(lnum + rnum, over: denom)
    }

    public static func *(lhs: Rational, rhs: Rational) -> Rational {

        return Rational(lhs.numerator * rhs.numerator,
                        over: lhs.denominator * rhs.denominator)
    }

    public static func /(lhs: Rational, rhs: Rational) -> Rational {

        return Rational(lhs.numerator * rhs.denominator,
                        over: lhs.denominator * rhs.numerator)
    }
}


public extension Double {

    init(_ r: Rational) {

        self = Double(r.numerator)/Double(r.denominator)
    }
}



//MARK: Convenience Extras


/// Tolerance infix operator
infix operator ± : BitwiseShiftPrecedence

public func ±(x: Double, tolerance: Double) -> Rational { return Rational(x, tolerance: tolerance) }
public func ±(x: Rational, tolerance: Double) -> Rational { return x.rounded(withTolerance: tolerance) }
public func ±(x: Rational, tolerance: Rational) -> Rational { return x.rounded(withTolerance: Double(tolerance)) }

/// Percentage postfix operator
postfix operator %


/// A representation of a ratio (percentage).
///
/// It is used to distinguish absolute vs relative tolerance.

public struct Percentage {

    let value: Double

    internal init(_ value: Double) {

        precondition(value >= 0.0, "Negative percentage is undefined.")

        self.value = value / 100.0
    }
}

public postfix func %(lhs: Double) -> Percentage { return Percentage(lhs) }

public func *(lhs: Double, rhs: Percentage) -> Double { return lhs * rhs.value }
public func *(lhs: Rational, rhs: Percentage) -> Double { return lhs * rhs.value }

public func ±(x: Double, tolerance: Percentage) -> Rational { return Rational(x, tolerance: tolerance) }
public func ±(x: Rational, tolerance: Percentage) -> Rational { return x.rounded(withTolerance: tolerance) }


public func +(lhs: Rational, rhs: Int) -> Rational { return lhs + Rational(rhs) }
public func -(lhs: Rational, rhs: Int) -> Rational { return lhs - Rational(rhs) }
public func *(lhs: Rational, rhs: Int) -> Rational { return lhs * Rational(rhs) }
public func /(lhs: Rational, rhs: Int) -> Rational { return lhs / Rational(rhs) }

public func +(lhs: Int, rhs: Rational) -> Rational { return Rational(lhs) + rhs }
public func -(lhs: Int, rhs: Rational) -> Rational { return Rational(lhs) - rhs }
public func *(lhs: Int, rhs: Rational) -> Rational { return Rational(lhs) * rhs }
public func /(lhs: Int, rhs: Rational) -> Rational { return Rational(lhs) / rhs }

public func +(lhs: Rational, rhs: Double) -> Double { return Double(lhs) + rhs }
public func -(lhs: Rational, rhs: Double) -> Double { return Double(lhs) - rhs }
public func *(lhs: Rational, rhs: Double) -> Double { return Double(lhs) * rhs }
public func /(lhs: Rational, rhs: Double) -> Double { return Double(lhs) / rhs }

public func +(lhs: Double, rhs: Rational) -> Double { return lhs + Double(rhs) }
public func -(lhs: Double, rhs: Rational) -> Double { return lhs - Double(rhs) }
public func *(lhs: Double, rhs: Rational) -> Double { return lhs * Double(rhs) }
public func /(lhs: Double, rhs: Rational) -> Double { return lhs / Double(rhs) }




//MARK: Internal Utilities


/// Returns the Greatest Common Divisor (GCD) of two non-negative integers
///
/// For convenience, assumes gcd(0,0) == 0
/// Implemented using "binary GCD algorithm" (aka Stein's algorithm)
///
/// - Precondition: `a >= 0 && b >= 0`

internal func gcd(_ a: Int, _ b: Int) -> Int {

    assert(a >= 0 && b >= 0)

    // Assuming gcd(0,0)=0:
    guard a != 0 else { return b }
    guard b != 0 else { return a }

    var a = a, b = b, n = Int()

    //FIXME: Shift loops are slow and should be opimized.

    // Remove the largest 2ⁿ from them:
    while (a | b) & 1 == 0 { a >>= 1; b >>= 1; n += 1 }

    // Reduce `a` to odd value:
    while a & 1 == 0 { a >>= 1 }

    repeat {

        // Reduce `b` to odd value
        while b & 1 == 0 { b >>= 1 }

        // Both `a` & `b` are odd here (or zero maybe?)

        // Make sure `b` is greater
        if a > b { swap(&a, &b) }

        // Subtract smaller odd `a` from the bigger odd `b`,
        // which always gives a positive even number (or zero)
        b -= a

        // keep repeating this, until `b` reaches zero
    } while b != 0

    return a << n // 2ⁿ×a
}


/// Given two rational numbers (left & right), returns a tuple containing scaled
/// left & right numerators and their common denominator.
///
/// The common denominator is the least common multiple (LCM) of the two denominators.

internal func numsWithCommonDenom(_ left: Rational, _ right: Rational) -> (lnum: Int, rnum: Int, denom: Int) {

    let leftNumerator: Int
    let rightNumerator: Int
    let commonDenominator: Int

    if left.denominator == right.denominator {

        leftNumerator     = left.numerator
        rightNumerator    = right.numerator
        commonDenominator = left.denominator

    } else {

        let commonDivisor   = gcd(left.denominator, right.denominator)

        let leftMultiplier  = right.denominator / commonDivisor
        let rightMultiplier = left.denominator  / commonDivisor

        leftNumerator     = left.numerator   * leftMultiplier
        rightNumerator    = right.numerator  * rightMultiplier
        commonDenominator = left.denominator * leftMultiplier
    }

    return (lnum: leftNumerator, rnum: rightNumerator, denom: commonDenominator)
}


extension String {

    func mapped(with lookupTable: [Character:Character]) -> String {

        return String(self.characters.map{ lookupTable[$0] ?? $0 })
    }
}



/// Utility protocol to help write more readable code.
///
/// One alternative is overloading multiplication / division operators, but it would
/// pollute operator space and lead to ambiguity.

internal protocol Scalable {

    associatedtype ScaleFactor

    /// Returns a new item by scaling the current item.

    func scaled(by factor: ScaleFactor) -> Self
}

extension Int: Scalable {

    typealias ScaleFactor = Double

    func scaled(by factor: Double) -> Int {

        return Int((Double(self) * factor).rounded())
    }
}

extension Rational: Scalable {

    typealias ScaleFactor = Double

    func scaled(by factor: Double) -> Rational {

        // To improve accuracy, always scale up:

        if factor > 1.0 {

            return Rational(numerator.scaled(by: factor), over: denominator)

        } else {

            return Rational(numerator, over: denominator.scaled(by: 1.0/factor))
        }
    }
}
