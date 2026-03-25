# Containerlab Operation Scripts

このディレクトリには、Containerlab の操作を効率化するためのユーティリティスクリプトが含まれています。

## セットアップ

リポジトリルートで一度 source することで、以降はどのディレクトリからでもスクリプト名だけで実行できます。

```bash
source scripts/clab-env-source
```

---

## スクリプト一覧

### 1. ラボ操作・一括実行

#### `clab-exec-all`
全ノード（または特定のノード）に対して一括でコマンドを実行します。
ノードの `kind` を自動判別し、エイリアス機能によって機種ごとのコマンド差異を吸収します。

```bash
# エイリアスを使って全ノードで BGP サマリーを表示
clab-exec-all bgp-summary

# kind ごとにコマンドを指定
clab-exec-all --kind linux="uptime" --kind cisco_xrd="show version"

# ノード名でフィルタ (正規表現)
clab-exec-all --filter "RT-L" bgp-summary

# リテラルコマンドをそのまま実行 (linux ノードのみ有効)
clab-exec-all "ping -c 1 10.1.254.1"
```

#### `clab-cli`
指定したノードにインタラクティブ接続します。
FRR ノードなら自動的に `vtysh` を起動し、それ以外は `bash` や SSH ログインを試みます。

```bash
# ノードに接続
clab-cli RT-L-X-01

# シェルを明示指定 (linux ノードのみ)
clab-cli RT-L-X-01 bash
```

---

### 2. 設定管理

#### `clab-save-startup-configs`
稼働中のノードから設定を取得し、clab.yml の `startup-config` に定義されたパスへ直接書き込みます。
次回の `containerlab deploy` 時にすぐ反映されます。

```bash
# カレントディレクトリの clab.yml を自動検出して実行
clab-save-startup-configs

# clab.yml を明示指定
clab-save-startup-configs --topo path/to/spec.clab.yml

# startup-config 未定義ノードのデフォルト保存先を変更 (デフォルト: startup-configs/)
clab-save-startup-configs --default-startup-dir config/
```

#### `clab-fetch-configs`
稼働中のノードから設定を取得し、`save/save-TIMESTAMP/` にスナップショットとして保存します。
履歴を残したい場合や差分確認に使います。

```bash
# カレントディレクトリの clab.yml を自動検出して実行
clab-fetch-configs

# clab.yml を明示指定
clab-fetch-configs --topo path/to/spec.clab.yml

# 保存先ディレクトリを変更 (デフォルト: save/)
clab-fetch-configs --save-dir backup/
```

#### `clab-generate-startup-configs`
`clab-fetch-configs` で保存したスナップショットを、clab.yml の `startup-config` パスへコピーします。
`startup-config` が未定義のノードは `startup-configs/` をデフォルトパスとして使用します。

```bash
# 最新のスナップショットを適用
clab-generate-startup-configs

# スナップショットを指定
clab-generate-startup-configs --snapshot 20250326153000

# startup-config 未定義ノードを clab.yml に自動追記
clab-generate-startup-configs --write-topo-yes
```

---

### 3. テスト・検証

#### `clab-test-run`
`test.yml` に定義されたテストケースを再帰的に検索して実行し、結果をレポートします。

```bash
# 指定ディレクトリ以下の test.yml を再帰的に実行
clab-test-run --root EVPNVXLAN/

# テストファイルを直接指定
clab-test-run --file EVPNVXLAN/test.yml

# タイムアウトとリトライ回数を変更
clab-test-run --root EVPNVXLAN/ --timeout 60 --retries 3

# 各テストの詳細出力 (stdout/stderr) を表示
clab-test-run --root EVPNVXLAN/ --detail
```

---

### 4. ネットワーク・環境

#### `pcap.sh`
指定したノードのインターフェースでパケットキャプチャを実行し、ローカルの Wireshark で表示します。

```bash
# 基本的な使い方
pcap.sh <containerlab-host> <container-name> <interface-name>

# 例
pcap.sh clab-host clab-EVPNVXLAN-RT-L-X-01 eth1

# 複数インターフェースをカンマ区切りで指定
pcap.sh clab-host clab-EVPNVXLAN-RT-L-X-01 eth1,eth2
```

#### `clab-env-source`
`scripts/` ディレクトリを PATH に追加し、`.env` ファイルから環境変数を読み込みます。

```bash
# デフォルト (.env を読み込む)
source scripts/clab-env-source

# 読み込むファイルを指定
source scripts/clab-env-source -f custom.env
```

---

## クイックリファレンス (clab-exec-all エイリアス)

以下のエイリアスは `clab-exec-all` で直接使用でき、機種ごとのコマンドに自動変換されます。

| エイリアス | linux (FRR) | Cisco XRD | Arista cEOS | Juniper vJunos |
| :--- | :--- | :--- | :--- | :--- |
| `bgp-summary` | `show ip bgp summary` | `show bgp summary` | `show ip bgp summary` | `show bgp summary` |
| `ip-route` | `ip route` | `show route` | `show ip route` | `show route` |
| `interfaces` | `ip addr` | `show interfaces description` | `show interfaces status` | `show interfaces terse` |

---

各スクリプトの全オプションは `--help` で確認できます。

```bash
clab-exec-all --help
clab-fetch-configs --help
clab-generate-startup-configs --help
clab-save-startup-configs --help
clab-test-run --help
```
