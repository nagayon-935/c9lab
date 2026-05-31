# SRv6 TI-LFA + Flex-Algo ラボ

Cisco XRd を使用した **SRv6 uSID**、**TI-LFA (Topology Independent Loop-Free Alternates)**、**Flex-Algo 128 (遅延ベースルーティング)** のデモンストレーションラボ。

## トポロジー

```
                  [上パス: IGP metric=10/link, delay=20ms/link]
                   RT-02 ─────────────── RT-03
                  /                            \
CE-01 (CUST-A) ──┤                              ├── CE-02 (CUST-A)
CE-03 (CUST-B) ──RT-01                        RT-06── CE-04 (CUST-B)
                  \                            /
                   RT-04 ─────────────── RT-05
                  [下パス: IGP metric=20/link, delay=1ms/link]
```

### パス比較

| アルゴリズム | 経路 | 選択理由 | 総コスト |
|---|---|---|---|
| Default (Algo 0) | RT-01 → RT-02 → RT-03 → RT-06 | IGP metric 最小 | 30 |
| Flex-Algo 128 | RT-01 → RT-04 → RT-05 → RT-06 | delay 最小 | 3,000 µs |

TI-LFA は上パス障害時に下パスへ瞬時切替 (FIB にバックアップ経路を事前インストール)。

## ノード構成

| ノード | 役割 | ループバック | SRv6 Locator (Algo 0) | SRv6 Locator (Algo 128) |
|---|---|---|---|---|
| RT-01 | PE | 1:1:1::1/128 | cafe:0:1::/48 | cafe:80:1::/48 |
| RT-02 | P  | 2:2:2::2/128 | cafe:0:2::/48 | cafe:80:2::/48 |
| RT-03 | P  | 3:3:3::3/128 | cafe:0:3::/48 | cafe:80:3::/48 |
| RT-04 | P  | 4:4:4::4/128 | cafe:0:4::/48 | cafe:80:4::/48 |
| RT-05 | P  | 5:5:5::5/128 | cafe:0:5::/48 | cafe:80:5::/48 |
| RT-06 | PE | 6:6:6::6/128 | cafe:0:6::/48 | cafe:80:6::/48 |
| CE-01 | CE (CUST-A) | — | 100.0.1.1/24 | — |
| CE-02 | CE (CUST-A) | — | 100.0.6.1/24 | — |
| CE-03 | CE (CUST-B) | — | 100.0.11.1/24 | — |
| CE-04 | CE (CUST-B) | — | 100.0.16.1/24 | — |

## リンク・メトリック設計

| リンク | IGP metric | delay (advertise) | パス |
|---|---|---|---|
| RT-01 — RT-02 | 10 | 20,000 µs | 上パス |
| RT-02 — RT-03 | 10 | 20,000 µs | 上パス |
| RT-03 — RT-06 | 10 | 20,000 µs | 上パス |
| RT-01 — RT-04 | 20 | 1,000 µs | 下パス |
| RT-04 — RT-05 | 20 | 1,000 µs | 下パス |
| RT-05 — RT-06 | 20 | 1,000 µs | 下パス |

## 使用機能

### SRv6 uSID
- Behavior: `uNode psp-usd` (全ルーター)
- VPN Behavior: `uDT4` (PE: End.DT4 per-vrf)
- ロケータ名: `ALGO0` (Algo 0)、`ALGO128` (Algo 128)
- uSID フォーマット: `cafe:<algo-hex>:<node>::/48`

### Flex-Algo 128
- `metric-type delay` — delay メトリック (performance-measurement で広告)
- 全ルーターで `advertise-definition` を設定
- 遅延広告: `performance-measurement interface <intf> delay-measurement advertise-delay <usec>`

### TI-LFA
- IS-IS インターフェースレベルで設定: `fast-reroute per-prefix ti-lfa`
- バックアップ経路は FIB に事前インストール → 障害検知と同時に即時切替
- SRv6 SID (uN) を P-node として使用したループフリー保護

### L3VPN
- BGP AS: 65100
- PE間: iBGP VPNv4 直接ピア (RT-01 ↔ RT-06)
- SID 割当: `alloc mode per-vrf`

| VRF | locator | Algo | CE | プレフィックス | パス |
|---|---|---|---|---|---|
| CUST-A | ALGO0 | 0 | CE-01 ↔ CE-02 | 100.0.1.0/24 ↔ 100.0.6.0/24 | 上パス（IGP最短） |
| CUST-B | ALGO128 | 128 | CE-03 ↔ CE-04 | 100.0.11.0/24 ↔ 100.0.16.0/24 | 下パス（Delay最小） |

## 実験結果

### 1. IS-IS 隣接確立

```
RT-01# show isis neighbors
IS-IS 1 neighbors:
System Id      Interface   SNPA    State Holdtime Type IETF-NSF
RT-02          Gi0/0/0/1   *PtoP*  Up    28       L2   Capable
RT-04          Gi0/0/0/2   *PtoP*  Up    21       L2   Capable
```

### 2. Flex-Algo 128 定義

```
RT-01# show isis flex-algo 128
  Definition Metric Type: Delay
  Definition Equal to Local: Yes
  Disabled: No
  Data Plane Segment Routing: Yes
```

### 3. Delay 広告確認

```
RT-01# show performance-measurement interfaces detail
Interface: GigabitEthernet0/0/0/1  (to RT-02, 上パス)
  Advertised delays (uSec): avg: 20000, min: 20000, max: 20000, variance: 0

Interface: GigabitEthernet0/0/0/2  (to RT-04, 下パス)
  Advertised delays (uSec): avg: 1000, min: 1000, max: 1000, variance: 0
```

### 4. ルーティング比較 (RT-01 → RT-06)

**Default Algo (0) — 上パス (IGP metric 最小)**
```
RT-01# show isis route ipv6 6:6:6::6/128
L2 6:6:6::6/128 [30/115]
     via fe80::..., GigabitEthernet0/0/0/1, RT-02   ← 上パス
```

**Flex-Algo 128 — 下パス (delay 最小)**
```
RT-01# show isis route ipv6 flex-algo 128
L2 cafe:80:6::/48 [3001/115]
     via fe80::..., GigabitEthernet0/0/0/2, RT-04   ← 下パス (delay 3ms)
```

### 5. TI-LFA バックアップ確認

```
RT-01# show isis fast-reroute ipv6 detail

L2 6:6:6::6/128 [30/115]  Primary: Gi0/0/0/1 (RT-02)
  Backup path: LFA, via Gi0/0/0/2 (RT-04), Metric: 60  [Node-Protecting]

L2 2:2:2::2/128 [10/115]  Primary: Gi0/0/0/1 (RT-02)
  Backup path: TI-LFA (link), via Gi0/0/0/2 (RT-04)
    P node: RT-06.00 [6:6:6::6], SRv6 SID: cafe:0:6:: uN (PSP/USD)
```

RT-02 プレフィックスへのバックアップは純粋な TI-LFA: RT-06 の uN SID を P-node として使ってループフリー修復パスを構成。

### 6. SRv6 SID 割当

```
RT-01# show segment-routing srv6 sid

Locator: 'ALGO0'
cafe:0:1::          uN (PSP/USD)   'default':1          sidmgr
cafe:0:1:e000::     uA (PSP/USD)   [Gi0/0/0/1]:0:P      isis-1   (protected adjacency)
cafe:0:1:e001::     uA (PSP/USD)   [Gi0/0/0/1]:0        isis-1
cafe:0:1:e002::     uA (PSP/USD)   [Gi0/0/0/2]:0:P      isis-1   (protected adjacency)
cafe:0:1:e003::     uA (PSP/USD)   [Gi0/0/0/2]:0        isis-1
cafe:0:1:e004::     uDT4           'CUST-A'              bgp-65100

Locator: 'ALGO128'
cafe:80:1::         uN (PSP/USD)   'default':1          sidmgr
cafe:80:1:e000::    uA (PSP/USD)   [Gi0/0/0/2]:128:P    isis-1
cafe:80:1:e001::    uA (PSP/USD)   [Gi0/0/0/2]:128      isis-1
cafe:80:1:e002::    uA (PSP/USD)   [Gi0/0/0/1]:128:P    isis-1
cafe:80:1:e003::    uA (PSP/USD)   [Gi0/0/0/1]:128      isis-1
cafe:80:1:e004::    uDT4           'CUST-B'              bgp-65100
```

CUST-A の uDT4 SID は ALGO0 ロケータ、CUST-B の uDT4 SID は ALGO128 ロケータから割り当てられる。

### 7. L3VPN SRv6 CEF

**CUST-A (Algo 0 — 上パス)**
```
RT-01# show cef vrf CUST-A 100.0.6.0/24 detail
  SRv6 H.Encaps.Red SID-list {cafe:0:6:e004::}   ← RT-06 の ALGO0 uDT4 SID
  via GigabitEthernet0/0/0/1, fe80::...(RT-02)   ← 上パス経由
```

**CUST-B (Algo 128 — 下パス)**
```
RT-01# show cef vrf CUST-B 100.0.16.0/24 detail
  SRv6 H.Encaps.Red SID-list {cafe:80:6:e004::}  ← RT-06 の ALGO128 uDT4 SID
  via GigabitEthernet0/0/0/2, fe80::...(RT-04)   ← 下パス経由
```

### 8. VRF 分離確認

CUST-A と CUST-B の間にルートリークがないことを確認。

```
# CE-01 (CUST-A) から CE-04 (CUST-B) へ — 到達不可
CE-01# ping 100.0.16.1
From 100.0.1.254: Destination Net Unreachable

# CE-03 (CUST-B) から CE-02 (CUST-A) へ — 到達不可
CE-03# ping 100.0.6.1
From 100.0.11.254: Destination Net Unreachable
```

PE ルーターが即座に `Destination Net Unreachable` を返し、VRF 間でのルートリークがないことを確認。

### 9. TI-LFA フェイルオーバーテスト

RT-03 の Gi0/0/0/1 (RT-02 方向) をシャットダウンし、CE 間 ping (0.1秒間隔) を継続。

```
CE-01# ping -c 150 -i 0.1 100.0.6.1
150 packets transmitted, 149 received, 0.67% packet loss
```

**損失 1 パケットのみ** (icmp_seq=127)。LFA バックアップが FIB に事前インストール済みのため、IS-IS 収束を待たずに即時切替が完了。

障害後の IS-IS ルート確認:
```
L2 6:6:6::6/128 [60/115] via Gi0/0/0/2, RT-04   ← 下パスに切替済み
```

インターフェース復元後:
```
L2 6:6:6::6/128 [30/115] via Gi0/0/0/1, RT-02   ← 上パスに自動復帰
```

## 確認コマンド一覧

### IS-IS / Flex-Algo

```bash
# IS-IS 隣接
show isis neighbors

# Algo 0 ルーティングテーブル
show isis route ipv6

# Flex-Algo 128 ルーティングテーブル
show isis route ipv6 flex-algo 128

# Flex-Algo 定義確認
show isis flex-algo 128

# TI-LFA バックアップ詳細
show isis fast-reroute ipv6 detail
```

### Performance Measurement (delay)

```bash
# delay 広告値の確認
show performance-measurement interfaces detail

# PM サマリー
show performance-measurement summary
```

### SRv6

```bash
# SRv6 ロケータ確認
show segment-routing srv6 locator

# SRv6 SID 一覧
show segment-routing srv6 sid

# SRv6 転送エントリ
show cef ipv6 6:6:6::6/128 detail
```

### BGP / L3VPN

```bash
# BGP VPNv4 隣接
show bgp vpnv4 unicast summary

# VRF ルーティングテーブル (CUST-A: Algo 0)
show bgp vrf CUST-A ipv4 unicast
show route vrf CUST-A

# VRF ルーティングテーブル (CUST-B: Algo 128)
show bgp vrf CUST-B ipv4 unicast
show route vrf CUST-B

# CEF (SRv6 エンキャプ確認)
show cef vrf CUST-A 100.0.6.0/24 detail   # ALGO0 SID を使用
show cef vrf CUST-B 100.0.16.0/24 detail  # ALGO128 SID を使用
```

### TI-LFA 障害テスト

```bash
# RT-03 で上パスリンクをシャットダウン
conf t
 interface GigabitEthernet0/0/0/1
  shutdown
commit

# CE-01 で連続 ping
docker exec -it CE-01 ping -i 0.1 100.0.6.1

# IS-IS ルートが下パスに切替わったことを RT-01 で確認
show isis route ipv6 6:6:6::6/128
# → [60/115] via RT-04 に変化

# 復元
conf t
 interface GigabitEthernet0/0/0/1
  no shutdown
commit
```

## 使用方法

```bash
# デプロイ
cd SRv6-TI-LFA-FlexAlgo
sudo containerlab deploy -t spec.clab.yml

# ログイン (全ルーター共通)
ssh clab@RT-01   # password: clab@123

# 削除
sudo containerlab destroy -t spec.clab.yml
```

## 注意事項

- TI-LFA のフェイルオーバーテストは CUST-A (Algo 0) を対象としている。CUST-B (Algo 128) の下パスが障害した場合の FRR 動作も同様に確認できる。
