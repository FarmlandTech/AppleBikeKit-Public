# 行動裝置藍牙狀態

取得當前的藍牙狀態(CBManagerState )，譬如行動裝置型號不支援藍牙、用戶未授權藍牙的使用，或者行動裝置的藍牙是否啟動等等。

```
import Combine
import AppleBikeKit

var subscriptions: Set<AnyCancellable> = .init()

AppleBikeKit.shared.statePublisher.sink(receiveValue: { state in
    // 監聽行動裝置藍牙狀態。
}).store(in: &self.subscriptions)
```