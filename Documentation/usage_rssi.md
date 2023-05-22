# 取得訊號強度

## 操作

要主動呼叫 readRSSI() 方法，才可一次性地取得訊號強度，單位為 dBm 。

```
AppleBikeKit.shared.readRSSI()
```

## 監聽

可透過 rssiPublisher 取得訊號強度。

```
AppleBikeKit.shared.rssiPublisher.sink(receiveValue: { rssi in
    /// 取得訊號強度。
}).store(in: &self.subscriptions)
```