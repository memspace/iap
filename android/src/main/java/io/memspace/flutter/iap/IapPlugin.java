package io.memspace.flutter.iap;

import android.annotation.SuppressLint;
import android.support.annotation.Nullable;
import com.android.billingclient.api.*;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** IapPlugin */
public class IapPlugin implements MethodCallHandler {
  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter.memspace.io/iap");
    IapPlugin plugin = new IapPlugin(registrar, channel);
    channel.setMethodCallHandler(plugin);
  }

  private IapPlugin(Registrar registrar, MethodChannel channel) {
    this.registar = registrar;
    this.channel = channel;
  }

  private  Registrar registar;
  private  MethodChannel channel;
  @SuppressLint("UseSparseArrays")
  private Map<Integer, BillingClient> clients = new HashMap<>();
  @SuppressLint("UseSparseArrays")
  private  Map<Integer,BillingObserver> observers = new HashMap<>();

  private class BillingObserver implements  PurchasesUpdatedListener {
    private  int handle;
    private MethodChannel channel;

    @SuppressLint("UseSparseArrays")
    private Map<Integer, SkuDetails> skuDetailsMap = new HashMap<>();
    private int nextSkuDetailsHandle = 0;

    BillingObserver(int handle, MethodChannel channel) {
      this.handle = handle;
      this.channel = channel;
    }

    SkuDetails getSkuDetails(Integer detailsHandle) {
      return skuDetailsMap.get(detailsHandle);
    }

    List<Map<String, Object>> registerSkuDetails(List<SkuDetails> skuDetailsList) {
      List<Map<String, Object>> encodedDetails = null;

      if (skuDetailsList != null) {
        encodedDetails = new ArrayList<>();
        for (SkuDetails detail: skuDetailsList) {
          Integer handle = nextSkuDetailsHandle++;
          skuDetailsMap.put(handle, detail);
          encodedDetails.add(encodeSkuDetails(handle, detail));
        }
      }
      return encodedDetails;
    }

    void notifyDisconnected() {
      channel.invokeMethod("BillingClient#disconnected", handle);
    }

    @Override
    public void onPurchasesUpdated(int responseCode, @Nullable List<Purchase> purchases) {
      List<Map<String, Object>> encodedPurchases = null;
      if (purchases != null) {
        encodedPurchases = new ArrayList<>();
        for (Purchase purchase: purchases) {
          encodedPurchases.add(encodePurchase(purchase));
        }
      }

      Map<String, Object> args = new HashMap<>();
      args.put("handle", handle);
      args.put("responseCode", responseCode);
      args.put("purchases", encodedPurchases);

      channel.invokeMethod("BillingClient#purchasesUpdated", args);
    }
  }

  private BillingClient getClient(Integer handle) {
    if (clients.containsKey(handle)) return clients.get(handle);
    return null;
  }

  @Override
  public void onMethodCall(MethodCall call, final Result result) {
    switch (call.method) {
      case "BillingClient#consume":
      {
        final Integer handle = call.argument("handle");
        final String purchaseToken = call.argument("purchaseToken");
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          client.consumeAsync(purchaseToken, new ConsumeResponseListener() {
            @Override
            public void onConsumeResponse(int responseCode, String purchaseToken) {
              result.success(responseCode);
            }
          });
        }

        break;
      }
      case "BillingClient#endConnection":
      {
        final Integer handle = call.arguments();
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          client.endConnection();
          clients.remove(handle);
          observers.remove(handle);
          result.success(null);
        }

        break;
      }
      case "BillingClient#isFeatureSupported":
      {
        final Integer handle = call.argument("handle");
        final String feature = call.argument("feature");
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          result.success(client.isFeatureSupported(feature));
        }
        break;
      }
      case "BillingClient#isReady":
      {
        final Integer handle = call.arguments();
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          result.success(client.isReady());
        }
        break;
      }
      case "BillingClient#launchBillingFlow":
      {
        final Integer handle = call.argument("handle");
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          final Map<String, Object> data = call.argument("params");
          assert data != null;
          BillingFlowParams params = createBillingFlowParams(handle, data);
          result.success(client.launchBillingFlow(registar.activity(), params));
        }
        break;
      }
      case "BillingClient#launchPriceChangeConfirmationFlow":
      {
        Integer handle = call.argument("handle");
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          BillingObserver observer = observers.get(handle);
          Integer detailsHandle = call.argument("skuDetails");
          SkuDetails details = observer.getSkuDetails(detailsHandle);
          PriceChangeFlowParams params = PriceChangeFlowParams.newBuilder().setSkuDetails(details).build();
          client.launchPriceChangeConfirmationFlow(registar.activity(), params, new PriceChangeConfirmationListener() {
            @Override
            public void onPriceChangeConfirmationResult(int responseCode) {
              result.success(responseCode);
            }
          });
        }
        break;
      }
      case "BillingClient#loadRewardedSku":
      {
        Integer handle = call.argument("handle");
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          BillingObserver observer = observers.get(handle);
          Integer detailsHandle = call.argument("skuDetails");
          SkuDetails details = observer.getSkuDetails(detailsHandle);
          RewardLoadParams params = RewardLoadParams.newBuilder().setSkuDetails(details).build();
          client.loadRewardedSku(params, new RewardResponseListener() {
            @Override
            public void onRewardResponse(int responseCode) {
              result.success(responseCode);
            }
          });
        }
        break;
      }
      case "BillingClient#queryPurchaseHistory":
      {
        Integer handle = call.argument("handle");
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          String skuType = call.argument("skuType");
          client.queryPurchaseHistoryAsync(skuType, new PurchaseHistoryResponseListener() {
            @Override
            public void onPurchaseHistoryResponse(int responseCode, List<Purchase> purchasesList) {
              List<Map<String, Object>> encodedPurchases = null;
              if (purchasesList != null) {
                encodedPurchases = new ArrayList<>();
                for (Purchase purchase: purchasesList) {
                  encodedPurchases.add(encodePurchase(purchase));
                }
              }

              Map<String, Object> data = new HashMap<>();
              data.put("responseCode", responseCode);
              data.put("purchases", encodedPurchases);

              result.success(data);
            }
          });
        }
        break;
      }
      case "BillingClient#queryPurchases":
      {
        Integer handle = call.argument("handle");
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          String skuType = call.argument("skuType");
          Purchase.PurchasesResult response =  client.queryPurchases(skuType);
          List<Map<String, Object>> encodedPurchases = null;
          if (response.getPurchasesList() != null) {
            encodedPurchases = new ArrayList<>();
            for (Purchase purchase: response.getPurchasesList()) {
              encodedPurchases.add(encodePurchase(purchase));
            }
          }

          Map<String, Object> data = new HashMap<>();
          data.put("responseCode", response.getResponseCode());
          data.put("purchases", encodedPurchases);

          result.success(data);
        }

        break;
      }
      case "BillingClient#querySkuDetails":
      {
        final Integer handle = call.argument("handle");
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          String skuType = call.argument("skuType");
          List<String> skus = call.argument("skus");

          SkuDetailsParams.Builder builder = SkuDetailsParams.newBuilder();
          if (skuType != null) builder.setType(skuType);
          if (skus != null) builder.setSkusList(skus);

          SkuDetailsParams params = builder.build();
          client.querySkuDetailsAsync(params, new SkuDetailsResponseListener() {
            @Override
            public void onSkuDetailsResponse(int responseCode, List<SkuDetails> skuDetailsList) {
              BillingObserver observer = observers.get(handle);
              List<Map<String, Object>> encodedDetails = observer.registerSkuDetails(skuDetailsList);

              Map<String, Object> data = new HashMap<>();
              data.put("responseCode", responseCode);
              data.put("skuDetails", encodedDetails);

              result.success(data);
            }
          });
        }
        break;
      }
      case "BillingClient#setChildDirected":
      {
        final Integer handle = call.argument("handle");
        final BillingClient client = getClient(handle);
        if (client == null) {
          result.error("IAP_BILLING_CLIENT_NOT_FOUND", "Must initialize BillingClient with a call to startConnection().", null);
        } else {
          final Integer value = call.argument("childDirected");
          assert value != null;
          client.setChildDirected(value);
          result.success(null);
          break;
        }
      }
      case "BillingClient#startConnection":
      {
        final Integer handle = call.arguments();
        BillingClient client = getClient(handle);
        if (client == null) {
          final BillingObserver observer = new BillingObserver(handle, channel);
          client = BillingClient.newBuilder(registar.context()).setListener(observer).build();
          clients.put(handle, client);
          observers.put(handle, observer);
        }
        client.startConnection(new BillingClientStateListener() {
          @Override
          public void onBillingSetupFinished(int responseCode) {
            result.success(responseCode);
          }

          @Override
          public void onBillingServiceDisconnected() {
            observers.get(handle).notifyDisconnected();
          }
        });
        break;
      }
      default:
      {
        result.notImplemented();
        break;
      }
    }
  }

  private BillingFlowParams createBillingFlowParams(Integer handle, Map<String, Object> data) {
    BillingObserver observer = observers.get(handle);
    BillingFlowParams.Builder builder = BillingFlowParams.newBuilder();
    if (data.containsKey("skuDetails")) {
      Integer detailsHandle = (Integer) data.get("skuDetails");
      SkuDetails details = observer.getSkuDetails(detailsHandle);
      builder.setSkuDetails(details);
    }
    return builder.build();
  }

  private Map<String, Object> encodeSkuDetails(Integer handle, SkuDetails details) {
    Map<String, Object> data = new HashMap<>();
    data.put("_handle", handle);
    data.put("description", details.getDescription());
    data.put("freeTrialPeriod", details.getFreeTrialPeriod());
    data.put("introductoryPrice", details.getIntroductoryPrice());
    data.put("introductoryPriceAmountMicros", details.getIntroductoryPriceAmountMicros());
    data.put("introductoryPriceCycles", details.getIntroductoryPriceCycles());
    data.put("introductoryPricePeriod", details.getIntroductoryPricePeriod());
    data.put("price", details.getPrice());
    data.put("priceAmountMicros", details.getPriceAmountMicros());
    data.put("priceCurrencyCode", details.getPriceCurrencyCode());
    data.put("sku", details.getSku());
    data.put("subscriptionPeriod", details.getSubscriptionPeriod());
    data.put("title", details.getTitle());
    data.put("type", details.getType());
    data.put("isRewarded", details.isRewarded());
    return data;
  }

  private Map<String, Object> encodePurchase(Purchase purchase) {
    Map<String, Object> data = new HashMap<>();
    data.put("orderId", purchase.getOrderId());
    data.put("originalJson", purchase.getOriginalJson());
    data.put("packageName", purchase.getPackageName());
    data.put("purchaseTime", purchase.getPurchaseTime());
    data.put("purchaseToken", purchase.getPurchaseToken());
    data.put("signature", purchase.getSignature());
    data.put("sku", purchase.getSku());
    data.put("isAutoRenewing", purchase.isAutoRenewing());
    return data;
  }
}
