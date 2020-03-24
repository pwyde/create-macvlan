# create-macvlan

## Description
Script for creating **macvlan** interfaces. Used for enabling network connectivity between host and KVM guest VMs, LXC/LXD and Docker containers.

## Options
| **Option** | **Description** |
| --- | --- |
| `-m`, `--macvlan`    | macvlan interface name. Will be named `macvlan` if not specified. |
| `-l`, `--link`       | Parent network link/device.                                       |
| `-i`, `--ip-address` | IPv4 address in CIDR notation for the macvlan interface.          |
| `-n`, `--network`    | IPv4 CIDR network block (route) for the macvlan interface.        |

## Examples
Create a macvlan interface named `macvlan0` with `eth0` as the parent link/device. Assign IPv4 address `192.168.1.20/24` and add route to `192.168.1.0/24` network on the new interface.

```
# sh create-macvlan --macvlan macvlan0 --link eth0 --ip-address 192.168.1.20/24 --network 192.168.1.0/24
```

Create a macvlan interface named `lxd-subnet` with `bond0`as the parent link/device. Assign IPv4 address `192.168.1.64/32` and add route to `192.168.1.64/26` subnet on the new interface.

```
# sh create-macvlan --macvlan lxd-subnet --link bond0 --ip-address 192.168.1.64/32 --network 192.168.1.64/26
```

## Execute as a systemd service unit
The script can also be executed as a **systemd service unit** which will always create the macvlan interface during boot. Copy the provided `create-macvlan.service` service unit [file](etc/systemd/system/create-macvlan.service) to `/etc/systemd/system`. Edit the unit file with command below and change script parameters accordingly.

```
# systemctl edit create-macvlan.service
```

Enable and start the service unit with command below.

```
# systemctl enable create-macvlan.service --now
```

The host will now always create specified macvlan interface during boot and enable inter-connectivity between host and i.e. Docker containers.

## License
This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more information.
