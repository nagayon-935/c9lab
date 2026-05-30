# SRandEVPN Lab

EVPN VXLAN ドメイン（Arista cEOS + Juniper vJunos）と SRv6 ドメイン（Cisco XRd）を組み合わせたマルチベンダー・マルチテクノロジーのネットワークラボ。

---

## トポロジー概要

```
                         [EVPN VXLAN ドメイン]
                       Juniper vJunos (AS65320)
                    ┌────────────────────────┐
                    │  spine-01    spine-02   │
                    │  10.3.2.1    10.3.2.2   │
                    └──┬──┬──┬──┬──┬──┬──┬──┘
                       │  │  │  │  │  │  │  │
              leaf-01  │  │  │  │  │  │  │  │  leaf-02
              (AS65331)│  │  │  │  │  │  │  │  (AS65332)
              10.3.3.1─┘  │  │  │  │  │  └──┘─10.3.3.2
              leaf-03      │  │  │  │  │       leaf-04
              (AS65333)    │  │  │  │  │       (AS65334)
              10.3.3.3─────┘  │  │  └──┘───────10.3.3.4
                               │  │
                   [境界: eBGP VRF]
                               │  │
                    ┌──────────┘  └─────────┐
                    │         ce-01          │
                    │     3:3:3::1           │
                    │  fc00:0:5::/48         │
                    └──────────┬─────────────┘
                               │ Gi0/0/0/1
                               │
                    ┌──────────┴─────────────┐
                    │         pe-01          │
                    │     2:2:2::1           │  ← BGP Route Reflector (AS65000)
                    │  fc00:0:2::/48         │
                    └──────────┬─────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
         pe-02 Gi1        p-01 (core)       pe-03 Gi1
              │           2:2:2::x              │
         ┌────┴────┐    fc00:0:x::/48    ┌──────┴─────┐
         │  pe-02  │──── p-01 ────────── │   pe-03    │
         │2:2:2::2 │    1:1:1::1         │  2:2:2::3  │
         │fc00:0:3:│  fc00:0:1::/48      │ fc00:0:4:: │
         └────┬────┘                     └─────┬──────┘
              │ Gi0/0/0/2                       │ Gi0/0/0/2
              │                                 │
         ┌────┴────┐                     ┌──────┴──────┐
         │  ce-02  │                     │    ce-03    │
         │3:3:3::2 │                     │  3:3:3::3   │
         │fc00:0:6:│                     │ fc00:0:7::  │
         └────┬────┘                     └──────┬──────┘
              │ Gi0/0/0/2.1103 (dot1q)           │ Gi0/0/0/2.1203 (dot1q)
              │ VRF-TEAM01                       │ VRF-TEAM02
              │                                  │
           [sv-07]                            [sv-08]
        192.168.3.103/24                  192.168.3.203/24
        VLAN 1103 (Team-01 Prob-3)        VLAN 1203 (Team-02 Prob-3)

                    [SRv6 ドメイン: IS-IS Level-1 + iBGP AS65000]
```

---

## ノード一覧

### EVPN VXLAN ドメイン

#### Juniper vJunos Router（スパイン）

| ノード | 管理 IP | Loopback | AS | 役割 |
|--------|---------|----------|----|------|
| spine-01 | 172.20.20.10 | 10.3.2.1 | 65320 | EVPN RR / L3 GW (vrf-team01) |
| spine-02 | 172.20.20.12 | 10.3.2.2 | 65320 | EVPN RR / L3 GW (vrf-team02) |

#### Arista cEOS（リーフ）

| ノード | 管理 IP | Loopback | AS | VTEP | VLAN |
|--------|---------|----------|----|------|------|
| leaf-01 | 172.20.20.18 | 10.3.3.1 | 65331 | ✓ | 1100 (Team-01) |
| leaf-02 | 172.20.20.22 | 10.3.3.2 | 65332 | ✓ | 1200/1201/1202 (Team-02) |
| leaf-03 | 172.20.20.21 | 10.3.3.3 | 65333 | ✓ | 1101/1201 |
| leaf-04 | 172.20.20.19 | 10.3.3.4 | 65334 | ✓ | 1102/1202 |

### SRv6 ドメイン（Cisco IOS XRd 25.2.2）

| ノード | 管理 IP | Loopback | SRv6 Locator | 役割 |
|--------|---------|----------|--------------|------|
| p-01 | 172.20.20.15 | 1:1:1::1 | fc00:0:1::/48 | P（コア転送） |
| pe-01 | 172.20.20.8 | 2:2:2::1 | fc00:0:2::/48 | PE / BGP RR |
| pe-02 | 172.20.20.20 | 2:2:2::2 | fc00:0:3::/48 | PE（SRv6 transit） |
| pe-03 | 172.20.20.4 | 2:2:2::3 | fc00:0:4::/48 | PE（SRv6 transit） |
| ce-01 | 172.20.20.7 | 3:3:3::1 | fc00:0:5::/48 | CE / EVPN-SRv6 境界 |
| ce-02 | 172.20.20.16 | 3:3:3::2 | fc00:0:6::/48 | CE / sv-07 収容 |
| ce-03 | 172.20.20.2 | 3:3:3::3 | fc00:0:7::/48 | CE / sv-08 収容 |

### サーバー（Linux / netshoot）

| ノード | 管理 IP | IP アドレス | GW | 接続先 | VLAN | チーム |
|--------|---------|------------|-----|--------|------|--------|
| sv-01 | 172.20.20.9 | 192.168.0.128/24 | 192.168.0.254 | leaf-01:eth3 | 1100 | Team-01 |
| sv-02 | 172.20.20.3 | 192.168.0.128/24 | 192.168.0.254 | leaf-02:eth3 | 1200 | Team-02 |
| sv-03 | 172.20.20.13 | 192.168.1.101/24 | 192.168.1.254 | leaf-03:eth3 | 1101 | Team-01 Prob-1 |
| sv-04 | 172.20.20.17 | 192.168.2.102/24 | 192.168.2.254 | leaf-04:eth3 | 1102 | Team-01 Prob-2 |
| sv-05 | 172.20.20.14 | 192.168.1.201/24 | 192.168.1.254 | leaf-03:eth4 | 1201 | Team-02 Prob-1 |
| sv-06 | 172.20.20.6 | 192.168.2.202/24 | 192.168.2.254 | leaf-04:eth4 | 1202 | Team-02 Prob-2 |
| sv-07 | 172.20.20.11 | 192.168.3.103/24 | 192.168.3.254 | ce-02:Gi0/0/0/2.1103 | 1103 | Team-01 Prob-3 |
| sv-08 | 172.20.20.5 | 192.168.3.203/24 | 192.168.3.254 | ce-03:Gi0/0/0/2.1203 | 1203 | Team-02 Prob-3 |

---

## VLAN / VNI / VRF マッピング

| VLAN | VNI | サブネット | GW | VRF | 対応サーバー |
|------|-----|------------|-----|-----|------------|
| 1100 | 11100 | 192.168.0.0/24 | .254 | vrf-team01 / VRF-TEAM01 | sv-01 |
| 1101 | 11101 | 192.168.1.0/24 | .254 | vrf-team01 / VRF-TEAM01 | sv-03 |
| 1102 | 11102 | 192.168.2.0/24 | .254 | vrf-team01 / VRF-TEAM01 | sv-04 |
| 1103 | —    | 192.168.3.0/24 | .254 | VRF-TEAM01 (ce-02) | sv-07 |
| 1200 | 11200 | 192.168.0.0/24 | .254 | vrf-team02 / VRF-TEAM02 | sv-02 |
| 1201 | 11201 | 192.168.1.0/24 | .254 | vrf-team02 / VRF-TEAM02 | sv-05 |
| 1202 | 11202 | 192.168.2.0/24 | .254 | vrf-team02 / VRF-TEAM02 | sv-06 |
| 1203 | —    | 192.168.3.0/24 | .254 | VRF-TEAM02 (ce-03) | sv-08 |

VLAN 1103 / 1203 は EVPN VXLAN ファブリック上に存在せず、SRv6 側 CE（ce-02 / ce-03）の dot1q サブインターフェースとして収容される。

---

## プロトコル構成

### EVPN VXLAN ドメイン

```
┌─────────────────────────────────────────────────────┐
│  アンダーレイ: eBGP (IPv6 next-hop / unnumbered)     │
│   spine (AS65320) ↔ leaf-01~04 (AS65331~65334)       │
│   IPv6 ND ベースの自動ピアリング                      │
│                                                      │
│  オーバーレイ: eBGP EVPN (multihop)                  │
│   spine-01/02 ← EVPN RR → leaf-01~04                │
│   Type-2 (MAC/IP), Type-3 (IMET), Type-5 (Prefix)   │
│                                                      │
│  データプレーン: VXLAN (UDP 4789)                    │
│   VTEP: leaf loopback (10.3.3.x) ↔ spine loopback   │
└─────────────────────────────────────────────────────┘
```

**スパインの役割**：
- mac-vrf インスタンス（VLAN ベース）で L2 ドメインを終端
- IRB インターフェースで L3 ゲートウェイ（anycast virtual-gateway）
- vrf-team01 / vrf-team02 でチーム間を完全分離

### SRv6 ドメイン

```
┌─────────────────────────────────────────────────────┐
│  アンダーレイ: IS-IS Level-1 (IPv6 only)             │
│   全7ノード (p-01, pe-01~03, ce-01~03) が参加         │
│   SRv6 Locator (/48) を IS-IS LSP で配布             │
│                                                      │
│  SRv6 uSID (micro-SID, f3216 フォーマット)           │
│   Block: 32bit / Node: 16bit / Function: 16bit       │
│   uN SID: ノード自体のSID (例: fc00:0:5::)            │
│   uA SID: 隣接SID (例: fc00:0:5:e000::)              │
│   uDT4 SID: VRF IPv4テーブル参照 (例: fc00:0:5:e001::)│
│                                                      │
│  コントロールプレーン: iBGP VPNv4 (AS65000)           │
│   pe-01 が Route Reflector                           │
│   ce-01, ce-02, ce-03 が RR クライアント             │
│   VPN ルートに SRv6 SID TLV を付加して配布           │
│                                                      │
│  データプレーン: SRv6 H.Encaps.Red                   │
│   単一 SID → SRH 省略、outer IPv6 dst に直接格納     │
└─────────────────────────────────────────────────────┘
```

### ドメイン間連携（ce-01 ↔ spine-01/02）

```
VRF-TEAM01:  ce-01 (Gi0/0/0/2, 10.3.0.1/24) ↔ spine-01 (ge-0/0/0, 10.3.0.2/24)
VRF-TEAM02:  ce-01 (Gi0/0/0/3, 10.3.10.1/24) ↔ spine-02 (ge-0/0/0, 10.3.10.2/24)

eBGP (ce-01 AS65000 ↔ spine AS65320) で以下を交換:
  spine → ce-01: 192.168.0.0/24, 192.168.1.0/24, 192.168.2.0/24
  ce-01 → spine: 192.168.3.0/24 (sv-07/sv-08 のサブネット)
```

VRF の RT（Route Target）をスパインと XRd 側で統一することで自動インポート：
- vrf-team01 / VRF-TEAM01: `target:65320:1100`
- vrf-team02 / VRF-TEAM02: `target:65320:1200`

---

## IS-IS NET アドレス

| ノード | NET |
|--------|-----|
| p-01 | 49.0001.0001.0001.0001.00 |
| pe-01 | 49.0001.0002.0002.0001.00 |
| pe-02 | 49.0001.0002.0002.0002.00 |
| pe-03 | 49.0001.0002.0002.0003.00 |
| ce-01 | 49.0001.0003.0003.0001.00 |
| ce-02 | 49.0001.0003.0003.0002.00 |
| ce-03 | 49.0001.0003.0003.0003.00 |

---

## P2P リンク（SRv6 ドメイン）

| リンク | インターフェース | IPv6 アドレス |
|--------|----------------|--------------|
| p-01 ↔ pe-01 | p-01:Gi1 / pe-01:Gi1 | 11:11:11::1/64 / ::2/64 |
| p-01 ↔ pe-02 | p-01:Gi2 / pe-02:Gi1 | 12:12:12::1/64 / ::2/64 |
| p-01 ↔ pe-03 | p-01:Gi3 / pe-03:Gi1 | 13:13:13::1/64 / ::2/64 |
| pe-01 ↔ ce-01 | pe-01:Gi2 / ce-01:Gi1 | 23:23:23::1/64 / ::2/64 |
| pe-02 ↔ ce-02 | pe-02:Gi2 / ce-02:Gi1 | 22:22:22::1/64 / ::2/64 |
| pe-03 ↔ ce-03 | pe-03:Gi2 / ce-03:Gi1 | 33:33:33::1/64 / ::2/64 |

---

## ラボ起動・停止

```bash
# 起動
sudo containerlab deploy -t spec.clab.yml

# 停止
sudo containerlab destroy -t spec.clab.yml

# 状態確認
sudo containerlab inspect --name SRandEVPN
```

---

## 接続情報

| 種別 | ユーザー | パスワード |
|------|---------|-----------|
| Cisco XRd (SSH) | clab | clab@123 |
| Juniper vJunos (SSH) | admin | admin@123 |
| Arista cEOS (SSH) | admin | admin |
| Linux サーバー | — | `docker exec -it <node> bash` |

```bash
# 例: XRd への SSH
ssh clab@172.20.20.15          # p-01

# 例: Juniper への SSH
ssh admin@172.20.20.10         # spine-01

# 例: サーバーへのアクセス
docker exec -it sv-07 bash
```

---

## 動作確認コマンド集

### SRv6 確認（XRd）

```bash
# SRv6 ロケータ・SID 確認
show segment-routing srv6 locator MAIN
show segment-routing srv6 sid

# IS-IS 経路確認
show isis route ipv6

# IS-IS ネイバー確認
show isis neighbors
```

### BGP VPN 確認（XRd）

```bash
# VPNv4 テーブル確認 (pe-01 RR)
show bgp vpnv4 unicast

# VRF ルートテーブル確認
show bgp vrf VRF-TEAM01 ipv4 unicast
show route vrf VRF-TEAM01

# BGP セッション確認
show bgp vpnv4 unicast summary
```

### EVPN VXLAN 確認（Arista leaf）

```bash
# VXLAN VTEP 確認
show vxlan vtep

# EVPN BGP テーブル確認
show bgp evpn

# MAC テーブル確認
show vxlan address-table
```

### EVPN 確認（Juniper spine）

```bash
# EVPN ルート確認
show evpn database
show evpn mac-ip-table

# BGP EVPN セッション確認
show bgp summary instance vrf-team01

# VRF ルートテーブル確認
show route instance vrf-team01
```

### 疎通確認

```bash
# sv-07 から spine の GW へ ping
docker exec sv-07 ping 192.168.1.254

# sv-08 から spine の GW へ ping
docker exec sv-08 ping 192.168.2.254

# XRd VRF 内 ping
ping vrf VRF-TEAM01 10.3.0.2
```

---

## データプレーン パケット変化（sv-01 → sv-07）

```
[IPv4] (192.168.0.128 → 192.168.3.103)
  │
  │  leaf-01: VXLAN encap
  ▼
[Outer IPv4: 10.3.3.1→10.3.2.1][UDP:4789][VXLAN VNI:11100][Inner IPv4]
  │
  │  spine-01: VXLAN decap, L3 routing (VRF-TEAM01)
  ▼
[IPv4] (via eBGP route to ce-01)
  │
  │  ce-01: SRv6 H.Encaps.Red
  ▼
[Outer IPv6: 3:3:3::1 → fc00:0:6:e001::][IPv4]
       ↑ ce-02 の uDT4 SID (VRF-TEAM01)
  │
  │  pe-01/p-01/pe-02: IS-IS IPv6 転送（SID 処理なし）
  │
  │  ce-02: SRv6 decap, uDT4 処理, VRF-TEAM01 lookup
  ▼
[IPv4] → Gi0/0/0/2.1103 (dot1q VLAN 1103) → sv-07
```

---

## ファイル構成

```
SRandEVPN/
├── spec.clab.yml          # containerlab トポロジー定義
├── README.md              # 本ファイル
└── config/
    ├── p-01.cfg           # Cisco XRd: P コアノード
    ├── pe-01.cfg          # Cisco XRd: PE / BGP RR
    ├── pe-02.cfg          # Cisco XRd: PE
    ├── pe-03.cfg          # Cisco XRd: PE
    ├── ce-01.cfg          # Cisco XRd: CE / EVPN-SRv6 境界
    ├── ce-02.cfg          # Cisco XRd: CE / sv-07 収容 (VRF-TEAM01)
    ├── ce-03.cfg          # Cisco XRd: CE / sv-08 収容 (VRF-TEAM02)
    ├── spine-01.cfg       # Juniper vJunos: スパイン (vrf-team01 担当)
    ├── spine-02.cfg       # Juniper vJunos: スパイン (vrf-team02 担当)
    ├── leaf-01.cfg        # Arista cEOS: VLAN 1100
    ├── leaf-02.cfg        # Arista cEOS: VLAN 1200/1201/1202
    ├── leaf-03.cfg        # Arista cEOS: VLAN 1101/1201
    └── leaf-04.cfg        # Arista cEOS: VLAN 1102/1202
```
