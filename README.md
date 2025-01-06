## Why Install mDNS (Avahi) on Your Server?

Installing mDNS (Multicast DNS), facilitated by the Avahi Daemon, allows your server to broadcast its hostname and
services seamlessly across your local network without requiring a central DNS server or manual IP address configuration.
This makes it incredibly easy for devices like macOS, Windows, and Linux machines to discover and connect to your server
using a simple hostname (your-hostname.local) instead of remembering complex IP addresses. With mDNS, services such as
SSH, HTTP, Samba, and printer sharing become instantly accessible to other devices on the same network. Whether you're
running a home server, a development environment, or a lightweight local cloud setup, mDNS significantly simplifies
connectivity, reduces configuration overhead, and improves usability across diverse devices.

This is automatically set in cloud-int. Manual creation would be as follows:

```bash
# Check Hostname Correct
hostnamectl

# Manual Start
sudo apt install avahi-daemon
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

# Test
ping <HOSTNAME>.local
```

## References:

* https://proxmox-wiki-loganmancuso-public-5aec8159d06cd8a0455f1afdcb1945.gitlab.io/#author-mentions