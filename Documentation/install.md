## 安裝

### 本地安裝

#### Xcode

* file -> add packages -> add local -> select project directory of AppleBikeKit
* target -> general -> frameworks, libraries, and embedded content -> add items -> select framework of AppleBikeKit

> 移除時，移除參考就好，否則本地端的 AppleBikeKit 專案會整個被刪除。

### 遠端安裝

#### GitHub

* settings -> developer settings -> tokens
    - note: 描述
    - expiration: 有效時間
    - select scopes: 勾選 repo (及其子項目)
* after 'generate token' -> copy it

#### Xcode

* settings -> account -> add github account
* project -> package dependencies -> add package dependency
* search or enter package url (by https scheme)
* select branch or some depandency rule to add package with token copied earlier

## 代碼中註解的名詞解釋

文中的幾個名詞，是具有嚴格且一致性地定義的，請參閱下列說明。

- 藍牙裝置：腳踏車的 HMI ，或者車錶、智慧手環等等。
- 行動裝置：手機或平板，甚至廣義來說，電腦也包含在內。
- 行動裝置的藍牙：手機或平板的藍牙裝置，此名詞常用於「藍牙是否授權」或「藍牙是否開啟」之類的情境。
