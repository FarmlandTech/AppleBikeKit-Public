# 讀取部件

每個部件的各個參數，已定義為 **ParameterData** 參數型別，無論讀取或寫入，皆可透過此物件實例進行開發。

## 操作

```
import CoreSDKService
import AppleBikeKit

AppleBikeKit.shared.readParameter(name: <#T##ParameterData.Name#>)
```

## 監聽

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

> 或者針對特定的部件參數，進行一次性的讀取，特別要注意的是：仍要執行上述的 readParameter() 方法。

```
import Combine
import CoreSDKService
import AppleBikeKit

// 不管成功與否，皆會取得"當下"最後一次的監聽到的值，也就是說取值失敗的話，可能會取得無效的數值。
AppleBikeKit.shared.parameterDataRepository.findParameterData(name: <#T##ParameterData.Name#>).subject.value

// 如果改用這種寫法，也可取得"當下"最後一次監聽到的值，但如果取值失敗的話，則不會指派給此參數。
AppleBikeKit.shared.parameterDataRepository.findParameterData(name: <#T##ParameterData.Name#>).value
```