# 寫入參數

## 操作

可透過 writeParameter() 方法進行參數的寫入，其中的 name 可對帳參數表查詢名稱，而 value 則為欲寫入的值，型別亦可參閱參數表。

```
AppleBikeKit.shared.writeParameter(name: <#T##ParameterData.Name#>, value: <#T##Any#>)
```

# 監聽

可透過 writingParameterStatePublisher 監聽命令執行的結果。

```
import AppleBikeKit

var subscriptions: Set<AnyCancellable> = .init()

AppleBikeKit.shared.writingParameterStatePublisher.sink(receiveValue: { state in
    // 取得命令執行結果。(true代表成功。)
}).store(in: &self.subscriptions)
```