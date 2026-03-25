# Juniper SRv6 L2VPN (E-LAN/EVPN)

Juniper vJunos Router を使用した SRv6 L2VPN (EVPN-ELAN) の検証用環境です。

## 構成

- PE: Juniper vJunos (pe1, pe2, pe3)
- P: Juniper vJunos (p1)
- CE: Arista cEOS (ce1, ce2)

## トポロジー図

PE 間の接続は SRv6 をベースに行われ、CE 間で L2 マルチポイント接続 (E-LAN) を実現します。

## 使用されているSRv6機能

- **SRv6 uSID (NEXT-C-SID)**: `micro-sid` を有効化。
- **Locator Behavior**: 
    - `micro-node-sid`: End 機能に相当。
- **Service Behavior**: 
    - `micro-dt2-sid`: EVPN (MAC-VRF) の終端に使用 (`End.DT2U` / `End.DT2M` に相当)。
- **Service**: EVPN-ELAN over SRv6.

## 確認用コマンド集

デプロイ後に以下のコマンドで状態を確認できます。（※これらのコマンドはAIによって生成されたため、実際の挙動と異なる可能性があります。内容の正確性は保証されません）

```bash
# SRv6 Locator の状態確認
show route table srv6.0

# ISIS による SID (uSID) の学習状況確認
show isis source-packet-routing srv6 locator

# EVPN MAC テーブルの確認
show evpn mac-table

# BGP EVPN ピアの状態確認
show bgp summary

# SRv6 サービス情報の確認 (End.DT2U/M など)
show route table elan200.evpn.0
```

## デプロイ


```bash
sudo containerlab deploy -t spec.clab.yml
```
