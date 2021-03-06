import Foundation

class ValueFormatter {
    static let instance = ValueFormatter()

    static private let fractionDigits = 8

    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = ValueFormatter.fractionDigits
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = ValueFormatter.fractionDigits
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    private let twoDigitFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    private let parseFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    var decimalSeparator: String {
        return amountFormatter.decimalSeparator
    }

    func format(coinValue: CoinValue) -> String? {
        coinFormatter.minimumFractionDigits = coinValue.value == 0 ? 2 : 0

        guard let formattedValue = coinFormatter.string(from: abs(coinValue.value) as NSNumber) else {
            return nil
        }

        var result = "\(formattedValue) \(coinValue.coinCode)"

        if coinValue.value < 0 {
            result = "- \(result)"
        }

        return result
    }

    func format(currencyValue: CurrencyValue, shortFractionLimit: Decimal? = nil, roundingMode: NumberFormatter.RoundingMode = .halfEven) -> String? {
        let absoluteValue = abs(currencyValue.value)

        let formatter = currencyFormatter
        formatter.roundingMode = roundingMode
        formatter.currencyCode = currencyValue.currency.code
        formatter.currencySymbol = currencyValue.currency.symbol

        if let limit = shortFractionLimit {
            formatter.maximumFractionDigits = absoluteValue > limit ? 0 : 2
        } else {
            formatter.maximumFractionDigits = 2
        }

        guard var result = formatter.string(from: absoluteValue as NSNumber) else {
            return nil
        }

        if currencyValue.value < 0 {
            result = "- \(result)"
        }

        return result
    }

    func format(amount: Decimal) -> String? {
        return amountFormatter.string(from: amount as NSNumber)
    }

    func format(twoDigitValue: Decimal) -> String? {
        return twoDigitFormatter.string(from: twoDigitValue as NSNumber)
    }

    func parseAnyDecimal(from string: String?) -> Decimal? {
        if let string = string {
            for localeIdentifier in Locale.availableIdentifiers {
                parseFormatter.locale = Locale(identifier: localeIdentifier)
                if parseFormatter.number(from: "0\(string)") == nil {
                    continue
                }

                let string = string.replacingOccurrences(of: parseFormatter.decimalSeparator, with: ".")
                if let decimal = Decimal(string: string) {
                    return decimal
                }
            }
        }
        return nil
    }

    func format(number: Int) -> String? {//translator for numpad
        return amountFormatter.string(from: number as NSNumber)
    }

    func round(value: Decimal, scale: Int, roundingMode: NSDecimalNumber.RoundingMode) -> Decimal {
        let handler = NSDecimalNumberHandler(roundingMode: roundingMode, scale: Int16(truncatingIfNeeded: scale), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: value).rounding(accordingToBehavior: handler).decimalValue
    }

}
