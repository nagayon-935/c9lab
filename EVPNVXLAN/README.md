# EVPN/VXLAN
EVPN/VXLANの学習のために一足いや5足ぐらい飛んでいるが「Multi Site」構成で組んでみた

## 構成
![EVPN/VXLAN Multisite](./images/EVPNVXLAN.svg "EVPN/VXLAN Multisite figure")

- DCI Router 3台
  - DCI-01
  - DCI-02
  - DCI-03

- Data Center
  - Border GW Router 1台
  - Spine 2台
  - Leaf 4台
  - Host 4台

以上のような構成で行う。Data Centerは X Site と Y Site を用意し、それぞれわかるように命名をしている。

# EVPN/VXLAN トポロジ情報

本構成は、マルチサイト対応のEVPN/VXLANネットワークであり、各Leafに一意のASNを割り当て、Route Server経由でEVPNルートを交換します。BGWにはVTEPが設定され、VXLANトンネルを通じてサイト間L2/L3通信を可能にしています。

---

## Site-A 構成

| デバイス名 | 役割    | IPアドレス              | Loopback IP     | ASN    | 備考             |
|------------|---------|--------------------------|------------------|--------|------------------|
| Leaf-A1    | Leaf    | eth: 10.1.1.1            | lo: 10.255.1.1   | 65101  | VTEPなし         |
| Leaf-A2    | Leaf    | eth: 10.1.1.2            | lo: 10.255.1.2   | 65102  | VTEPなし         |
| Leaf-A3    | Leaf    | eth: 10.1.1.3            | lo: 10.255.1.3   | 65103  | VTEPなし         |
| Leaf-A4    | Leaf    | eth: 10.1.1.4            | lo: 10.255.1.4   | 65104  | VTEPなし         |
| Spine-A1   | Spine   | eth: 10.1.0.1            | lo: 10.255.0.1   | 65001  | 同一ASN（iBGP）  |
| Spine-A2   | Spine   | eth: 10.1.0.2            | lo: 10.255.0.2   | 65001  | 同一ASN（iBGP）  |
| BGW-A      | BGW/VTEP| eth: 10.1.254.1          | lo: 10.255.254.1 | 65200  | VTEPあり         |

---

## Site-B 構成

| デバイス名 | 役割    | IPアドレス              | Loopback IP     | ASN    | 備考             |
|------------|---------|--------------------------|------------------|--------|------------------|
| Leaf-B1    | Leaf    | eth: 10.2.1.1            | lo: 10.255.2.1   | 65201  | VTEPなし         |
| Leaf-B2    | Leaf    | eth: 10.2.1.2            | lo: 10.255.2.2   | 65202  | VTEPなし         |
| Leaf-B3    | Leaf    | eth: 10.2.1.3            | lo: 10.255.2.3   | 65203  | VTEPなし         |
| Leaf-B4    | Leaf    | eth: 10.2.1.4            | lo: 10.255.2.4   | 65204  | VTEPなし         |
| Spine-B1   | Spine   | eth: 10.2.0.1            | lo: 10.255.0.3   | 65002  | 同一ASN（iBGP）  |
| Spine-B2   | Spine   | eth: 10.2.0.2            | lo: 10.255.0.4   | 65002  | 同一ASN（iBGP）  |
| BGW-B      | BGW/VTEP| eth: 10.2.254.1          | lo: 10.255.254.2 | 65210  | VTEPあり         |

---

## 共通構成

| デバイス名 | 役割         | IPアドレス       | Loopback IP     | ASN    | 備考                    |
|------------|--------------|------------------|------------------|--------|-------------------------|
| RouteSrv-1 | Route Server | eth: 192.0.2.1    | lo: 10.255.255.1 | 65000  | EVPN用 eBGP Route Server|

---

## 備考

- **Spineは同一ASNで構成され、Leaf–Spine間は eBGP**。
- **BGWとLeaf、BGWとRS間ではMP-BGP EVPNセッションを確立**。
- **Route TargetやVNIは別資料（またはFRR conf）に記載**。