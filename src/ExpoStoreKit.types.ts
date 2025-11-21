export interface ProductSubscriptionPeriod {
  value: number;
  unit: "day" | "week" | "month" | "year" | "unknown";
}

export type ProductType =
  | "consumable"
  | "nonConsumable"
  | "autoRenewable"
  | "nonRenewable"
  | "unknown";

export type SubscriptionOfferPaymentMode =
  | "payAsYouGo"
  | "payUpFront"
  | "freeTrial"
  | "unknown";

export type SubscriptionOfferType = "introductory" | "promotional" | "unknown";

export interface ProductSubscriptionOffer {
  id?: string;
  displayPrice: string;
  price: number;
  period: ProductSubscriptionPeriod;
  periodCount: number;
  paymentMode: SubscriptionOfferPaymentMode;
  type: SubscriptionOfferType;
}

export type TransactionOwnershipType = "purchased" | "familyShared" | "unknown";

export type TransactionOfferType =
  | "introductory"
  | "promotional"
  | "code"
  | "unknown";

export type TransactionRevocationReason =
  | "developerIssue"
  | "other"
  | "unknown";

export interface ProductSubscriptionInfo {
  subscriptionGroupId?: string;
  subscriptionPeriod: ProductSubscriptionPeriod;
  isEligibleForIntroOffer: boolean;
  introductoryOffer?: ProductSubscriptionOffer;
  promotionalOffers: ProductSubscriptionOffer[];
}

export interface Product {
  id: string;
  displayName: string;
  description: string;
  displayPrice: string;
  price: number;
  priceFormatStyle: {
    currencyCode: string;
  };
  type: ProductType;
  isFamilyShareable: boolean;
  subscription?: ProductSubscriptionInfo;
}

export interface Transaction {
  id: string;
  productID: string;
  originalID: string;
  purchaseDate: string;
  originalPurchaseDate: string;
  expirationDate?: string;
  revocationDate?: string;
  revocationReason?: TransactionRevocationReason;
  ownershipType: TransactionOwnershipType;
  appAccountToken?: string;
  offerID?: string;
  offerType?: TransactionOfferType;
}

export type TransactionVerificationResult =
  | {
      type: "verified";
      transaction: Transaction;
    }
  | {
      type: "unverified";
      transaction: Transaction;
      verificationError: string;
    };

export interface PurchaseOptions {
  appAccountToken?: string;
  promotionalOffer?: {
    offerID: string;
    compactJWS: string;
  };
  quantity?: number;
  simulatesAskToBuyInSandbox?: boolean;
  continuePurchaseIfStorefrontChanges?: boolean;
  introductoryOfferEligibility?: {
    compactJWS: string;
  };
}

export type ProductPurchaseResult =
  | {
      type: "success";
      verificationResult: TransactionVerificationResult;
    }
  | {
      type: "pending";
    }
  | {
      type: "userCancelled";
    };
