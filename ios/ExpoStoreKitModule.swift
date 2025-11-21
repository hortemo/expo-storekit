import ExpoModulesCore
import StoreKit
import Foundation

public enum ExpoStoreKitError: Error {
  case notFound(String)
  case unknown(String)
  case invalid(String)
}

public class ExpoStoreKitModule: Module {
  private var updatesTask: Task<Void, Never>? = nil
  
  public func definition() -> ModuleDefinition {
    Name("ExpoStoreKit")
    
    Events("transactionUpdated")
    
    AsyncFunction("requestProducts") { (productIds: [String]) async throws -> [[String: Any]] in
      let products = try await Product.products(for: productIds)
      return await products.asyncMap { await $0.toJS() }
    }
    
    AsyncFunction("purchase") { (productId: String, optionsJS: [String: Any]?) async throws -> [String: Any] in
      let product = try await Product.fromJS(productId)
      let options = try Set<Product.PurchaseOption>.fromJS(optionsJS)
      let result = try await product.purchase(options: options)
      return try result.toJS()
    }
    
    AsyncFunction("finishTransaction") { (transactionId: String) async throws -> Void in
      let transaction = try await Transaction.fromJS(transactionId)
      await transaction.finish()
    }
    
    AsyncFunction("sync") { () async throws -> Void in
      try await AppStore.sync()
    }
    
    AsyncFunction("requestCurrentEntitlements") { () async throws -> [[String: Any]] in
      return await Transaction.currentEntitlements
        .map { $0.toJS() }
        .collect()
    }
    
    OnStartObserving {
      print("OnStartObserving")
      self.updatesTask?.cancel()
      self.updatesTask = Task { [weak self] in
        for await result in Transaction.updates {
          print("TRANSACTION_UPDATES!")
          guard let self else {
            return
          }
          print("SEND_EVENT!")
          self.sendEvent("transactionUpdated", result.toJS())
        }
      }
    }
    
    OnStopObserving {
      self.updatesTask?.cancel()
      self.updatesTask = nil
    }
  }
}

fileprivate extension Product {
  static func fromJS(_ id: String) async throws -> Product {
    guard let product = try await Product.products(for: [id]).first else {
      throw ExpoStoreKitError.notFound("Product \(id) not found")
    }
    return product
  }

  func toJS() async -> [String: Any] {
    return removeNilValues([
      "id": id,
      "displayName": displayName,
      "description": description,
      "displayPrice": displayPrice,
      "price": price,
      "priceFormatStyle": priceFormatStyle.toJS(),
      "type": type.toJS(),
      "isFamilyShareable": isFamilyShareable,
      "subscription": await subscription.asyncMap { await $0.toJS() }
    ])
  }
}

fileprivate extension Product.SubscriptionInfo {
  func toJS() async -> [String: Any] {
    return await removeNilValues([
      "subscriptionGroupId": subscriptionGroupID,
      "subscriptionPeriod": subscriptionPeriod.toJS(),
      "isEligibleForIntroOffer": isEligibleForIntroOffer,
      "introductoryOffer": introductoryOffer.map { $0.toJS() },
      "promotionalOffers": promotionalOffers.map { $0.toJS() }
    ])
  }
}

fileprivate extension Product.SubscriptionOffer {
  func toJS() -> [String: Any] {
    return removeNilValues([
      "id": id,
      "displayPrice": displayPrice,
      "price": price,
      "period": period.toJS(),
      "periodCount": periodCount,
      "paymentMode": paymentMode.toJS(),
      "type": type.toJS()
    ])
  }
}

fileprivate extension Product.SubscriptionPeriod {
  func toJS() -> [String: Any] {
    return [
      "value": value,
      "unit": unit.toJS()
    ]
  }
}

fileprivate extension Transaction {
  static func fromJS(_ idJS: String) async throws -> Transaction {
    guard let id = UInt64(idJS) else {
      throw ExpoStoreKitError.notFound("Invalid transaction ID \(idJS)")
    }
    
    for await result in Transaction.all {
      let transaction = result.transaction
      if transaction.id == id {
        return transaction
      }
    }
    throw ExpoStoreKitError.notFound("Transaction \(id) not found")
  }

  func toJS() -> [String: Any] {
    return removeNilValues([
      "id": String(id),
      "productID": productID,
      "purchaseDate": purchaseDate.toJS(),
      "originalID": String(originalID),
      "originalPurchaseDate": originalPurchaseDate.toJS(),
      "ownershipType": ownershipType.toJS(),
      "appAccountToken": appAccountToken?.uuidString,
      "offerID": offerID,
      "offerType": offerType?.toJS(),
      "revocationReason": revocationReason?.toJS(),
      "expirationDate": expirationDate?.toJS(),
      "revocationDate": revocationDate?.toJS()
    ])
  }
}

fileprivate extension Product.PurchaseResult {
  func toJS() throws -> [String: Any] {
    switch self {
    case .success(let verificationResult):
      return [
        "type": "success",
        "verificationResult": verificationResult.toJS()
      ]
    case .pending:
      return [
        "type": "pending"
      ]
    case .userCancelled:
      return [
        "type": "userCancelled"
      ]
    @unknown default:
      throw ExpoStoreKitError.unknown("Unknown purchase result")
    }
  }
}

fileprivate extension VerificationResult<Transaction> {
  var transaction: Transaction {
    switch self {
    case .verified(let transaction):
      return transaction
    case .unverified(let transaction, _):
      return transaction
    }
  }
  
  func toJS() -> [String: Any] {
    switch self {
    case .verified(let transaction):
      return [
        "type": "verified",
        "transaction": transaction.toJS()
      ]
    case .unverified(let transaction, let verificationError):
      return [
        "type": "unverified",
        "transaction": transaction.toJS(),
        "verificationError": verificationError.localizedDescription
      ]
    }
  }
}

fileprivate extension Product.SubscriptionPeriod.Unit {
  func toJS() -> String {
    switch self {
    case .day:
      return "day"
    case .week:
      return "week"
    case .month:
      return "month"
    case .year:
      return "year"
    default:
      return "unknown"
    }
  }
}

fileprivate extension Product.SubscriptionOffer.PaymentMode {
  func toJS() -> String {
    switch self {
    case .payAsYouGo:
      return "payAsYouGo"
    case .payUpFront:
      return "payUpFront"
    case .freeTrial:
      return "freeTrial"
    default:
      return "unknown"
    }
  }
}

fileprivate extension Product.SubscriptionOffer.OfferType {
  func toJS() -> String {
    switch self {
    case .introductory:
      return "introductory"
    case .promotional:
      return "promotional"
    default:
      return "unknown"
    }
  }
}

fileprivate extension Product.ProductType {
  func toJS() -> String {
    switch self {
    case .consumable:
      return "consumable"
    case .nonConsumable:
      return "nonConsumable"
    case .autoRenewable:
      return "autoRenewable"
    case .nonRenewable:
      return "nonRenewable"
    default:
      return "unknown"
    }
  }
}

fileprivate extension Transaction.OfferType {
  func toJS() -> String {
    switch self {
    case .introductory:
      return "introductory"
    case .promotional:
      return "promotional"
    case .code:
      return "code"
    default:
      return "unknown"
    }
  }
}

fileprivate extension Transaction.OwnershipType {
  func toJS() -> String {
    switch self {
    case .purchased:
      return "purchased"
    case .familyShared:
      return "familyShared"
    default:
      return "unknown"
    }
  }
}

fileprivate extension Transaction.RevocationReason {
  func toJS() -> String {
    switch self {
    case .developerIssue:
      return "developerIssue"
    case .other:
      return "other"
    default:
      return "unknown"
    }
  }
}

fileprivate extension Set where Element == Product.PurchaseOption {
  static func fromJS(_ options: [String: Any]?) throws -> Set<Product.PurchaseOption> {
    guard let options else {
      return []
    }

    var purchaseOptions: [Product.PurchaseOption] = []

    if let appAccountTokenJS = options["appAccountToken"] as? String {
      guard let appAccountToken = UUID(uuidString: appAccountTokenJS) else {
        throw ExpoStoreKitError.invalid("Invalid appAccountToken")
      }

      purchaseOptions.append(.appAccountToken(appAccountToken))
    }

    if let promotionalOfferJS = options["promotionalOffer"] as? [String: Any] {
      guard let offerID = promotionalOfferJS["offerID"] as? String else {
        throw ExpoStoreKitError.invalid("Invalid offerID")
      }
      
      guard let compactJWS = promotionalOfferJS["compactJWS"] as? String else {
        throw ExpoStoreKitError.invalid("Invalid compactJWS")
      }
      
      purchaseOptions.append(contentsOf: Product.PurchaseOption.promotionalOffer(offerID, compactJWS: compactJWS))
    }

    if let quantity = intValue(from: options["quantity"]) {
      purchaseOptions.append(.quantity(quantity))
    }

    if let simulatesAskToBuyInSandbox = boolValue(from: options["simulatesAskToBuyInSandbox"]) {
      purchaseOptions.append(.simulatesAskToBuyInSandbox(simulatesAskToBuyInSandbox))
    }

    if let continuePurchaseIfStorefrontChanges = boolValue(from: options["continuePurchaseIfStorefrontChanges"]) {
      purchaseOptions.append(.onStorefrontChange { _ in continuePurchaseIfStorefrontChanges })
    }

    if let introductoryOfferEligibility = options["introductoryOfferEligibility"] as? [String: Any] {
      guard let compactJWS = introductoryOfferEligibility["compactJWS"] as? String else {
        throw ExpoStoreKitError.invalid("introductoryOfferEligibility.compactJWS is required")
      }
      
      purchaseOptions.append(.introductoryOfferEligibility(compactJWS: compactJWS))
    }

    return Set(purchaseOptions)
  }
}

fileprivate extension Dictionary where Key == String, Value == Any {
  func toPromotionalOfferOptions() throws -> [Product.PurchaseOption] {
    guard let offerID = self["offerID"] as? String else {
      throw ExpoStoreKitError.invalid("promotionalOffer.offerID is required")
    }

    guard let compactJWS = self["compactJWS"] as? String else {
      throw ExpoStoreKitError.invalid("promotionalOffer.compactJWS is required")
    }

    return Product.PurchaseOption.promotionalOffer(offerID, compactJWS: compactJWS)
  }
}

fileprivate func removeNilValues(_ dictionary: [String: Any?]) -> [String: Any] {
  return dictionary.compactMapValues { $0 }
}

fileprivate func boolValue(from value: Any?) -> Bool? {
  switch value {
  case .some(let bool as Bool):
    return bool
  case .some(let number as NSNumber):
    return number.boolValue
  default:
    return nil
  }
}

fileprivate func intValue(from value: Any?) -> Int? {
  switch value {
  case .some(let int as Int):
    return int
  case .some(let number as NSNumber):
    return number.intValue
  default:
    return nil
  }
}

fileprivate extension Array {
  func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
    var result = [T]()
    result.reserveCapacity(self.count)
    for element in self {
      result.append(try await transform(element))
    }
    return result
  }
}

fileprivate extension Optional {
  func asyncMap<T>(_ transform: (Wrapped) async throws -> T) async rethrows -> T? {
    switch self {
    case .some(let wrapped):
      return try await transform(wrapped)
    case .none:
      return nil
    }
  }
}

fileprivate extension AsyncSequence {
  func collect() async rethrows -> [Element] {
    var result: [Element] = []
    for try await element in self {
      result.append(element)
    }
    return result
  }
}

fileprivate extension Decimal.FormatStyle.Currency {
  func toJS() -> [String: Any] {
    return [
      "currencyCode": currencyCode
    ]
  }
}

fileprivate extension Date {
  func toJS() -> String {
    return ISO8601Format()
  }
}
