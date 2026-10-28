"""This machine's place on the network: its LAN address and subnet, which firewall is active, and
the one command that opens ports to the subnet. Shared by the phone support (`mobile.py`) and the
remote eyeball mode (`remote.py`)."""
from __future__ import annotations

import re
import subprocess

_IPV4_RE = re.compile(r"^\d{1,3}(?:\.\d{1,3}){3}$")

IP_COMMAND_TIMEOUT_SECONDS = 5
FIREWALL_CHECK_TIMEOUT_SECONDS = 5


def lan_ip() -> str | None:
    """This machine's LAN IPv4 address -- what a phone on the same network calls the dev backend
    on. `ip -4 -o addr show scope global` first (excludes loopback and link-local by construction,
    and is what most Linux dev machines have); `hostname -I` as a fallback for an environment
    without `ip`. `None` when neither yields an address (no network, or neither tool exists)."""
    return _lan_ip_via_ip_command() or _lan_ip_via_hostname()


def _first_ipv4(text: str) -> str | None:
    for token in text.replace("/", " ").split():
        if _IPV4_RE.match(token) and not token.startswith("127."):
            return token
    return None


def _lan_ip_via_ip_command() -> str | None:
    try:
        result = subprocess.run(["ip", "-4", "-o", "addr", "show", "scope", "global"], text=True,
                                 capture_output=True, timeout=IP_COMMAND_TIMEOUT_SECONDS)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    return _first_ipv4(result.stdout)


def _lan_ip_via_hostname() -> str | None:
    try:
        result = subprocess.run(["hostname", "-I"], text=True, capture_output=True,
                                 timeout=IP_COMMAND_TIMEOUT_SECONDS)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    return _first_ipv4(result.stdout)


def lan_subnet(ip: str) -> str:
    """192.168.1.42 -> 192.168.1.0/24, the /24 a ufw `allow from` rule names. Returns `ip`
    unchanged when it is not a plain IPv4 address (nothing sensible to derive a subnet from)."""
    parts = ip.split(".")
    if len(parts) != 4:
        return ip
    return ".".join(parts[:3]) + ".0/24"


def detect_active_firewall() -> str | None:
    """'ufw', 'firewalld', or None -- whichever of the two this machine's systemd reports active,
    checked in that order. Neither being present or `systemctl` itself being unavailable (a
    non-systemd machine) both read as None, the "no known firewall" case."""
    for name in ("ufw", "firewalld"):
        try:
            result = subprocess.run(["systemctl", "is-active", name], text=True, capture_output=True,
                                     timeout=FIREWALL_CHECK_TIMEOUT_SECONDS)
        except (OSError, subprocess.TimeoutExpired):
            continue
        if result.returncode == 0 and result.stdout.strip() == "active":
            return name
    return None


def firewall_remedy_for_ports(active_firewall: str | None, ports: list[int], subnet: str) -> str:
    """The one command (or, with neither firewall detected, a generic hint) that opens every port
    in `ports` to `subnet`, so a tester runs it once instead of once per port."""
    ordered = sorted(set(ports))
    if active_firewall == "ufw":
        return f"sudo ufw allow from {subnet} to any port {','.join(map(str, ordered))} proto tcp"
    if active_firewall == "firewalld":
        return "sudo firewall-cmd " + " ".join(f"--add-port={p}/tcp" for p in ordered)
    noun = "port" if len(ordered) == 1 else "ports"
    return f"Check this machine's firewall for a rule blocking {noun} {', '.join(map(str, ordered))}."


def firewall_remedy(active_firewall: str | None, port: int, subnet: str) -> str:
    """The exact command that unblocks one `port` for phones on `subnet` -- the command the tester
    hit today for ufw blocking 8080."""
    return firewall_remedy_for_ports(active_firewall, [port], subnet)
