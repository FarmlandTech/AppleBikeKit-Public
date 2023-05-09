##  使用

### 行動裝置藍牙狀態

```
import Combine
import AppleBikeKit

var subscriptions: Set<AnyCancellable> = .init()

AppleBikeKit.shared.statePublisher.sink(receiveValue: { state in
    // 監聽行動裝置藍牙狀態。
}).store(in: &self.subscriptions)
```

### 掃描

```
import AppleBikeKit

// 掃描開始
AppleBikeKit.shared.startScan()

// 掃描終止
AppleBikeKit.shared.stopScan()
```

```
import Combine
import AppleBikeKit

AppleBikeKit.shared.scanningPublisher.sink(receiveValue: { isScanning in
    // 監聽掃描狀態。(正在掃描？或者終止掃描？)
}).store(in: &self.subscriptions)

AppleBikeKit.shared.foundDevicesPublisher.sink(receiveValue: { foundDevices in
    foundDevices.forEach { peripheral in
        peripheral.deviceName  // 掃描到的藍牙裝置名稱。
    }
}).store(in: &self.subscriptions)
```

### 連線

- 在上面段落，取得掃描到的 BluetoothPeripheral 陣列後，須將欲連線的目標裝置緩存下來，用來作為連線的標的。
- 連線與斷線的狀態，可藉由上面段落的 statePublisher 進行監聽，不再贅述。

```
import CoreBLEService
import AppleBikeKit

var peripheral: BluetoothPeripheral?

// 連線
AppleBikeKit.shared.connect(peripheral!)

// 斷線
AppleBikeKit.shared.disconnect(peripheral!)
```

### 讀取部件

```
import CoreSDKService
import AppleBikeKit

AppleBikeKit.shared.readParameter(name: <#T##ParameterData.Name#>)
```

> 可以無差別對所有讀取到的部件參數，進行監聽。

```
import Combine
import CoreSDKService
import AppleBikeKit

var subscriptions: Set<AnyCancellable> = .init()

AppleBikeKit.shared.parameterDataPubisher.sink(receiveCompletion: { competion in
    guard case let .failure(repositoryError) = competion else { return }
    guard let error: ParameterDataRepository.Error = repositoryError as? ParameterDataRepository.Error else { return }
    guard case let .parameterDataNotFoundByArguments(type, bank, address, length) = error else { return }
    // 發生錯誤，捕獲例外。
}, receiveValue: { output in
    // 取得部件參數。  
}).store(in: &self.subscriptions)
```

> 也可以針對特定的部件參數，進行監聽。

```
import Combine
import CoreSDKService
import AppleBikeKit

var subscriptions: Set<AnyCancellable> = .init()

AppleBikeKit.shared.parameterDataRepository.findParameterData(name: <#T##ParameterData.Name#>).subject.sink(receiveValue: { parameterData in
    <#code#>
}).store(in: &self.subscriptions)
```

> 或者針對特定的部件參數，進行一次性的讀取。(仍要執行上述的 readParameter 方法，不管成功與否，皆會取得當下最後一次的監聽到的值)

```
import Combine
import CoreSDKService
import AppleBikeKit

AppleBikeKit.shared.parameterDataRepository.findParameterData(name: <#T##ParameterData.Name#>).subject.value
```
