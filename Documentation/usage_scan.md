# 掃描

掃描可連線的腳踏車，會根據腳踏車廣播的名稱進行篩選，僅能取得符合命名規則的車輛列表。

## 操作

```
import AppleBikeKit

// 掃描開始
AppleBikeKit.shared.startScan()

// 掃描終止
AppleBikeKit.shared.stopScan()
```

## 監聽

```
import Combine
import AppleBikeKit

var subscriptions: Set<AnyCancellable> = .init()

AppleBikeKit.shared.scanningPublisher.sink(receiveValue: { isScanning in
    // 監聽掃描狀態。(正在掃描？或者終止掃描？)
}).store(in: &self.subscriptions)

AppleBikeKit.shared.foundDevicesPublisher.sink(receiveValue: { foundDevices in
    foundDevices.forEach { peripheral in
        peripheral.deviceName  // 掃描到的藍牙裝置名稱。
    }
}).store(in: &self.subscriptions)
```