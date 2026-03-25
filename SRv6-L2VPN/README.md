# SRv6-L2VPN Lab

SRv6(Segment Routing over IPv6)を用いたL2VPNの構成検証用リポジトリです。
Cisco(XRD)およびJuniper(vJunos)を用いたトポロジーが含まれています。

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
