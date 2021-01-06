# 掲示板ドキュメント

## 外部仕様
### 画面構成
- スレ一覧
- スレ詳細

### スレ一覧
- スレを作成することができる
  - スレ
    - 名前
    - 作成日

### スレ詳細
- チャットできる
  - チャット内容
    - 投稿者名
    - コメント

## 内部仕様
### URL構成
- /
  - スレ一覧
- /:id
  - スレ詳細

### データ構造

- データはjsonファイルで保持する
  
```[json]
{
  0: {
    name: 'ほげ',
    create_at: xxx,
    comments: [
      {
        creator_name: 'ほげ',
        comment: 'ほげ',
        create_at: xxx
      },
      {
        creator_name: 'ほげ',
        comment: 'ほげ',
        create_at: xxx
      },
      {
        creator_name: 'ほげ',
        comment: 'ほげ',
        create_at: xxx
      },
      {
        creator_name: 'ほげ',
        comment: 'ほげ',
        create_at: xxx
      },
    ]
  }
}
```
