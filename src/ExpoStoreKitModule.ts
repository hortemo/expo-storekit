import { NativeModule, requireNativeModule } from "expo-modules-core";
import {
  Product,
  ProductPurchaseResult,
  PurchaseOptions,
  TransactionVerificationResult,
} from "./ExpoStoreKit.types";

export type StoreKitModuleEvents = {
  transactionUpdated(result: TransactionVerificationResult): void;
};

export declare class ExpoStoreKitModule extends NativeModule<StoreKitModuleEvents> {
  requestProducts(productIds: string[]): Promise<Product[]>;
  purchase(
    productId: string,
    purchaseOptions?: PurchaseOptions
  ): Promise<ProductPurchaseResult>;
  finishTransaction(transactionId: string): Promise<void>;
  sync(): Promise<void>;
  requestCurrentEntitlements(): Promise<TransactionVerificationResult[]>;
}

export default requireNativeModule<ExpoStoreKitModule>("ExpoStoreKit");
