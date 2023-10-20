# 取得裝置資訊

可透過 deviceInfo 取得當前的腳踏車裝置資訊。

```
// 已電池剩餘電量為例。
AppleBikeKit.shared.deviceInfo?.battery_rsoc
```

也可透過 deviceInfoPublisher 對裝置資訊進行實時的監聽。

```
import AppleBikeKit
import CoreSDKSourceCode

var subscriptions: Set<AnyCancellable> = .init()
    
AppleBikeKit.shared.deviceInfoPublisher.sink(receiveValue: { deviceInfo in
    // 取得裝置資訊。
}).store(in: &self.subscriptions)
```
