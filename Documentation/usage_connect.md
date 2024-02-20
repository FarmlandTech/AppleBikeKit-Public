# 連線

- 在上面段落，取得掃描到的 BluetoothPeripheral 陣列後，須將欲連線的目標裝置緩存下來，用來作為連線的裝置實例；此外，斷線的操作，也會用到緩存的裝置實例。
- 連線與斷線的狀態，可藉由上面段落的 statePublisher 進行監聽，不再贅述。

## 操作

```
import CoreBLEService
import AppleBikeKit

var peripheral: BluetoothPeripheral?

// 連線
AppleBikeKit.shared.connect(peripheral!)

// 斷線
AppleBikeKit.shared.disconnect(peripheral!)
```

## 監聽

```
/// 藍牙連線狀態。
public enum PeripheralStatus {
    /// 未知。
    case unknown
    /// 未連線。
    case didConnect
    /// 已連線。
    case didDisconnect
    /// 已進入準備狀態。(可被操作)
    case prepared
}
```

連線狀態中， **didConnect** 階段代表已經與腳踏車進行連線了，但此時的特徵還沒取得，無法進行命令的操作(包括參數的存取)，待進入 **prepared** 的階段才算真正完成藍牙連線的流程。

```
import AppleBikeKit

var subscriptions: Set<AnyCancellable> = .init()

AppleBikeKit.shared.peripheralPublisher.sink(receiveValue: { status, peripheral in
    <#code#>
}).store(in: &self.subscriptions)
```