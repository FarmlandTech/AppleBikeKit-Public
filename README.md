# AppleBikeKit

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

