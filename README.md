# @hortemo/expo-storekit

Lightweight wrapper for StoreKit 2.

## Installation

```sh
npm install @hortemo/expo-storekit
```

## API Reference

- `requestProducts(productIds: string[]): Promise<Product[]>`
- `purchase(productId: string, purchaseOptions?: PurchaseOptions): Promise<ProductPurchaseResult>`
- `finishTransaction(transactionId: string): Promise<void>`
- `requestCurrentEntitlements(): Promise<TransactionVerificationResult[]>`
- `sync(): Promise<void>`
- `addListener(eventName: "transactionUpdated", listener: (result: TransactionVerificationResult) => void): EventSubscription`
