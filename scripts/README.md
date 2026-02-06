# Containerlab Operation Scripts

このディレクトリには、Containerlab の操作を効率化するためのユーティリティスクリプトが含まれています。

## スクリプト一覧

### 1. ラボ操作・一括実行
- **`clab-exec-all`**: 全ノード（または特定のノード）に対して一括でコマンドを実行します。
  - **特長**: ノードの `kind` (OS種別) を自動判別し、エイリアス機能によって機種ごとのコマンド差異を吸収します。
  - **例**: `./scripts/clab-exec-all bgp-summary` (全機種でBGPサマリー表示)
  - **例**: `./scripts/clab-exec-all --kind linux="uptime" --kind cisco_xrd="show version"`

- **`clab-cli`**: 指定したノードにクイックアクセスします。
  - **特長**: FRRノードなら自動的に `vtysh` を起動し、それ以外なら `bash` や SSH ログインを試みます。
  - **例**: `./scripts/clab-cli RT-L-X-01`

### 2. 設定管理
- **`clab-fetch-configs`**: 稼働中のノードから設定（running-config）を取得し、`save/` ディレクトリに保存します。
- **`clab-generate-startup-configs`**: 保存された設定を `startup-configs/` にコピーし、次回のラボ起動時に反映されるようにします。

### 3. テスト・検証
- **`clab-test-run`**: `test.yml` に定義されたテストケースを再帰的に実行し、結果をレポートします。
  - **例**: `./scripts/clab-test-run --root EVPNVXLAN/`

### 4. ネットワーク・環境
- **`pcap.sh`**: 指定したノードのインターフェースでパケットキャプチャを実行し、ローカルの Wireshark で表示します。
  - **使い方**: `./scripts/pcap.sh <ホスト名> <コンテナ名> <インターフェース名>`
  - **例**: `./scripts/pcap.sh clab-host RT-L-X-01 eth1`

- **`clab-bridge-create` / `delete`**: `clab.yml` に定義されたブリッジノードに対応する Linux ブリッジを OS 上に作成・削除します。
- **`clab-env-source`**: `.env` ファイルから環境変数を読み込みます。
  - **使い方**: `source scripts/clab-env-source`

## クイックリファレンス (clab-exec-all エイリアス)

以下のエイリアスは `clab-exec-all` で直接使用でき、機種ごとのコマンドに自動変換されます。

| エイリアス | 内容 |
| :--- | :--- |
| `bgp-summary` | BGP のネイバー状態を確認 |
| `ip-route` | ルーティングテーブルを表示 |
| `interfaces` | インターフェースの状態・IPアドレスを表示 |

---

各スクリプトの詳細なオプションについては、各スクリプトに `--help` を付けて実行して確認してください。
