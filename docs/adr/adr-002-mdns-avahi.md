# ADR 002: Use of mDNS (Avahi) for Local VM Discovery

**Status:** Accepted

**Date:** 2025-01-07

## Context

VMs need to be discoverable on the local network without requiring manual IP management or a dedicated DNS server.
mDNS provides a lightweight, automated mechanism for hostname resolution (`<hostname>.local`).

## Decision

* Install **Avahi Daemon** on each VM.

* Broadcasts hostnames over **Multicast DNS (mDNS, RFC 6762)**, using UDP port 5353.

* Supported by major OSes:

    * **Linux** via Avahi or systemd-resolved
    * **macOS** via Bonjour (built-in)
    * **Windows 10+** (with Bonjour/Apple software or native LLMNR/mDNS support)

* Example usage:

```sh
ssh ubuntu@docker-compose-server.local
```

## Consequences

* Simplifies connecting to VMs without knowing IP addresses.
* Reduces operational overhead in homelab environments.
* Works seamlessly across macOS, Linux, and Windows clients with mDNS support.
* Limited to local broadcast domains; not suitable for production, multi-subnet, or routed environments.
