import React, { JSX, useCallback, useState } from "react";
import { Button, SafeAreaView, ScrollView, Text, View } from "react-native";
import { z } from "zod";
import StoreKit from "@hortemo/expo-storekit";

const PRODUCTS = {
  "expo.storekit.product1": {
    productSchema: z.object({
      id: z.literal("expo.storekit.product1"),
      displayName: z.literal(""),
      description: z.literal(""),
      displayPrice: z.literal("$0.99"),
      price: z.literal(0.99),
      priceFormatStyle: z.object({
        currencyCode: z.string(),
      }),
      type: z.literal("nonConsumable"),
      isFamilyShareable: z.literal(false),
    }),
    transactionSchema: z.object({
      id: z.string(),
      productID: z.literal("expo.storekit.product1"),
      originalID: z.string(),
      purchaseDate: z.string(),
      expirationDate: z.string().optional(),
      originalPurchaseDate: z.string(),
      ownershipType: z.literal("purchased"),
    }),
  },
  "expo.storekit.subscription1": {
    productSchema: z.object({
      id: z.literal("expo.storekit.subscription1"),
      displayName: z.literal(""),
      description: z.literal(""),
      displayPrice: z.literal("$0.99"),
      price: z.literal(0.99),
      priceFormatStyle: z.object({
        currencyCode: z.string(),
      }),
      type: z.literal("autoRenewable"),
      isFamilyShareable: z.literal(false),
      subscription: z.object({
        subscriptionGroupId: z.literal("71A49BF4"),
        subscriptionPeriod: z.object({
          value: z.literal(1),
          unit: z.literal("week"),
        }),
        isEligibleForIntroOffer: z.boolean(),
      }),
    }),
    transactionSchema: z.object({
      id: z.string(),
      productID: z.literal("expo.storekit.subscription1"),
      originalID: z.string(),
      purchaseDate: z.string(),
      expirationDate: z.string(),
      originalPurchaseDate: z.string(),
      ownershipType: z.literal("purchased"),
    }),
  },
} as const;

const PRODUCT_IDS = Object.keys(PRODUCTS) as (keyof typeof PRODUCTS)[];

const verifiedTransactionSchema = (transactionSchema: z.ZodTypeAny) =>
  z.object({
    type: z.literal("verified"),
    transaction: transactionSchema,
  });

const successfulPurchaseSchema = (transactionSchema: z.ZodTypeAny) =>
  z.object({
    type: z.literal("success"),
    verificationResult: z.object({
      type: z.literal("verified"),
      transaction: transactionSchema,
    }),
  });

function App(): JSX.Element {
  const [status, setStatus] = useState({
    state: "idle" as "idle" | "running" | "success" | "error",
    error: null as string | null,
    progress: [] as string[],
  });

  const logProgress = useCallback((message: string) => {
    console.log(message);
    setStatus((prev) => ({
      ...prev,
      progress: [...prev.progress, message],
    }));
  }, []);

  const runTests = useCallback(async () => {
    setStatus({ state: "running", error: null, progress: [] });

    try {
      logProgress("Requesting products...");
      const products = await StoreKit.requestProducts(PRODUCT_IDS);
      for (const productId of PRODUCT_IDS) {
        const product = products.find((p) => p.id === productId);
        const productSchema = PRODUCTS[productId].productSchema;
        productSchema.parse(product);
      }

      for (const productId of PRODUCT_IDS) {
        logProgress(`Purchasing ${productId}...`);
        const purchaseResult = await StoreKit.purchase(productId);
        const transactionSchema = PRODUCTS[productId].transactionSchema;
        const validatedPurchaseResult =
          successfulPurchaseSchema(transactionSchema).parse(purchaseResult);

        const transactionId =
          validatedPurchaseResult.verificationResult.transaction.id;
        logProgress(`Finishing transaction ${transactionId}...`);
        await StoreKit.finishTransaction(transactionId);

        logProgress(`Ensuring entitlement for ${productId}...`);
        const currentEntitlements = await StoreKit.requestCurrentEntitlements();
        const entitlement = currentEntitlements.find(
          (e) => e.transaction.productID === productId
        );
        verifiedTransactionSchema(transactionSchema).parse(entitlement);
      }

      logProgress("Ensuring all entitlements are present...");
      const currentEntitlements = await StoreKit.requestCurrentEntitlements();
      for (const productId of PRODUCT_IDS) {
        const entitlement = currentEntitlements.find(
          (e) => e.transaction.productID === productId
        );
        const transactionSchema = PRODUCTS[productId].transactionSchema;
        verifiedTransactionSchema(transactionSchema).parse(entitlement);
      }

      logProgress("Waiting for subscription updates...");
      const subscription1Id = "expo.storekit.subscription1";
      const subscription1Update = await new Promise((resolve, reject) => {
        const subscription = StoreKit.addListener(
          "transactionUpdated",
          (result) => {
            if (result.transaction.productID === subscription1Id) {
              resolve(result);
              subscription.remove();
            }
          }
        );

        setTimeout(() => {
          reject("Did not receive transaction update in time");
          subscription.remove();
        }, 60_000);
      });

      verifiedTransactionSchema(
        PRODUCTS[subscription1Id].transactionSchema
      ).parse(subscription1Update);

      logProgress("Syncing with the App Store...");
      await StoreKit.sync();

      setStatus((prev) => ({ ...prev, state: "success", error: null }));
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logProgress(`Error: ${errorMessage}`);
      setStatus((prev) => ({
        ...prev,
        state: "error",
        error: errorMessage,
      }));
      console.log(errorMessage);
    }
  }, [logProgress]);

  const isRunning = status.state === "running";

  return (
    <SafeAreaView style={{ flex: 1 }}>
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        contentContainerStyle={{ padding: 16, gap: 16 }}
      >
        <View>
          <Text
            testID="test-status"
            style={{ fontSize: 18, fontWeight: "600" }}
          >
            Status: {status.state}
          </Text>
          {status.error ? (
            <Text testID="test-error">Error: {status.error}</Text>
          ) : null}
          <View style={{ marginTop: 8, gap: 4 }}>
            {status.progress.map((message, index) => (
              <Text key={index} testID={`test-progress-${index}`}>
                {message}
              </Text>
            ))}
          </View>
        </View>

        <Button
          title={isRunning ? "Running..." : "Run tests"}
          onPress={runTests}
          disabled={isRunning}
          testID="run-tests"
        />
      </ScrollView>
    </SafeAreaView>
  );
}

export default App;
