#!/usr/bin/env sh

# macvlan interface creation script.
# Copyright (C) 2019 Patrik Wyde <patrik@wyde.se>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Configure script variables.
test_host="1.1.1.1"

print_help() {
echo "
Description:
  Script for creating macvlan interfaces. Used for enabling network connect-
  ivity between host and KVM guest VMs, LXC/LXD and Docker containers.

Examples:
  ${0} --macvlan mynet --link eth0 --ip-address 192.168.1.20/24 --network 192.168.1.0/24

  ${0} --macvlan mynet --link eth0 --ip-address 192.168.1.64/32 --network 192.168.1.64/26

Options:
  -m, --macvlan     macvlan interface name. Will be named 'macvlan' if not
                    specified.

  -l, --link        Parent network link/device.

  -i, --ip-address  IPv4 address in CIDR notation for the macvlan interface.

  -n, --network     IPv4 CIDR network block (route) for the macvlan interface.
" >&2
}

# Print help if no argument is specified.
if [ "${#}" -le 0 ]; then
    print_help
    exit 1
fi

# Loop as long as there is at least one more argument.
while [ "${#}" -gt 0 ]; do
    arg="${1}"
    case "${arg}" in
        # This is an arg value type option. Will catch both '-m' or
        # '--macvlan' value.
        -m|--macvlan) shift; macvlan="${1}" ;;
        # This is an arg value type option. Will catch both '-l' or
        # '--link' value.
        -l|--link) shift; link="${1}" ;;
        # This is an arg value type option. Will catch both '-i' or
        # '--ip' value.
        -i|--ip-address) shift; ip="${1}" ;;
        # This is an arg value type option. Will catch both '-n' or
        # '--network' value.
        -n|--network) shift; network="${1}" ;;
        # This is an arg value type option. Will catch both '-h' or
        # '--help' value.
        -h|--help) print_help; exit ;;
        *) echo "Invalid option '${arg}'." >&2; print_help; exit 1 ;;
    esac
    # Shift after checking all the cases to get the next option.
    shift > /dev/null 2>&1;
done

print_msg() {
    echo "=>" "${@}" >&1
}

# Verify that all mandatory script options are specified.
validate_options() {
    # If not specified, set interface name to 'macvlan'.
    if [ -z "${macvlan}" ]; then
        macvlan="macvlan"
    fi
    if [ -z "${link}" ]; then
        echo "No parent link/device specified!" >&2
        print_help
        exit 1
    fi
    if [ -z "${ip}" ]; then
        echo "No IPv4 address specified for the macvlan interface!" >&2
        print_help
        exit 1
    fi
    if [ -z "${network}" ]; then
        echo "No IPv4 CIDR network block (route) specified for the macvlan interface!" >&2
        print_help
        exit 1
    fi
}

# Verify network connectivity. If not, wait 5 sec before next retry.
test_net_conn() {
    while ! ping -q -c 1 "${test_host}" > /dev/null; do
        print_msg "Unable to PING '$test_host'! Waiting 5 sec before next retry..."
        sleep 5
    done
}

create_macvlan() {
    if ip link add "${macvlan}" link "${link}" type macvlan mode bridge; then
        print_msg "Created macvlan interface '$macvlan'."
    else
        echo "Unable to create macvlan interface!" >&2
        exit 1
    fi
    if ip address add "${ip}" dev "${macvlan}"; then
        print_msg "Added IPv4 address '$ip' to nterface '$macvlan'."
    else
        echo "Unable to add IPv4 address to macvlan interface!" >&2
        exit 1
    fi
    if ip link set "${macvlan}" up; then
        print_msg "Interface '$macvlan' is set to UP."
    else
        echo "Unable to bring up macvlan interface!" >&2
    fi
    if ip route add "${network}" dev "${macvlan}"; then
        print_msg "Added route '$network' to interface '$macvlan'."
    else
        echo "Unable to add route to macvlan interface!" >&2
    fi
}

validate_options
test_net_conn
create_macvlan
