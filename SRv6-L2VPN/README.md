# SRv6-L2VPN Lab

SRv6(Segment Routing over IPv6)を用いたL2VPNの構成検証用リポジトリです。
Cisco(XRD)およびJuniper(vJunos)を用いたトポロジーが含まれています。

## L2VPN サービス種別

SRv6を用いたL2VPNには、主に以下の2つのサービス種別があります。

- **E-LINE (Ethernet Line)**: 
  - **VPWS (Virtual Private Wire Service)** とも呼ばれます。
  - 拠点間を1対1（Point-to-Point）で接続するL2VPNサービスです。
  - 仮想的な専用線のように動作します。
- **E-LAN (Ethernet LAN)**:
  - 複数拠点間を多対多（Multipoint-to-Multipoint）で接続するL2VPNサービスです。
  - **EVPN (Ethernet VPN)** を用いて実装されることが一般的です。
  - 仮想的なL2スイッチ（ブリッジ）のように動作し、MACアドレス学習が行われます。

## 構成

- **[Cisco/](./Cisco/)**: Cisco XRDを用いたSRv6 L2VPN (E-LINE/VPWS) の検証。
- **[Juniper/](./Juniper/)**: Juniper vJunosを用いたSRv6 L2VPN (E-LAN/EVPN) の検証。

## 実行方法

[Containerlab](https://containerlab.dev/)が必要です。

```bash
# Ciscoラボ
cd Cisco
sudo containerlab deploy -t spec.clab.yml

# Juniperラボ
cd Juniper
sudo containerlab deploy -t spec.clab.yml
```
