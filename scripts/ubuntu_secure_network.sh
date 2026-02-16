#!/usr/bin/env bash

function_network_hardening() { # {{{
  # ==============================================================================
  # 🛡️ Ubuntu / Debian Linux Network Hardening Script (Deep Defense Mode)
  # ------------------------------------------------------------------------------
  # ⚠️  Run as root: sudo ./secure_network.sh
  # ==============================================================================

  if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Please run as root (sudo)."
    exit 1
  fi

  # ==============================================================================
  # [Step 0] OS Detection
  # ==============================================================================
  echo "ℹ️ [0/3] Detecting Operating System..."

  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=${ID}
    OS_LIKE=${ID_LIKE}
  else
    echo "❌ Error: Cannot detect OS distribution."
    exit 1
  fi

  if [[ "${ID}" == "ubuntu" || "${ID}" == "debian" || "${ID_LIKE}" =~ "debian" ]]; then
    # ----------------------------------------------------------------
    # Ubuntu / Debian (APT)
    # ----------------------------------------------------------------
    echo "💡 Detected Debian/Ubuntu system."

    # ==============================================================================
    # [Step 1] Update Package Lists
    # ==============================================================================
    echo "ℹ️ [1/3] Updating package repository cache..."
    apt-get update -qq

    # ==============================================================================
    # [Step 2] Install Required Packages
    # ==============================================================================
    # The main hardening script relies on:
    # 1. ufw: For firewall rules (Step 4)
    # 2. network-manager: For MAC randomization (Step 3)
    # 3. systemd-resolved: For DNS over TLS/DNSSEC (Step 1)
    echo "ℹ️ [2/3] Installing core security dependencies..."

    DEBIAN_FRONTEND=noninteractive apt-get install --fix-missing --ignore-missing -y \
      ufw \
      network-manager \
      systemd \
      iptables

    # Validation tools
    DEBIAN_FRONTEND=noninteractive apt-get install --fix-missing --ignore-missing -y \
      dnsutils \
      tcpdump

    # ==============================================================================
    # [Step 3] Service Verification & Activation
    # ==============================================================================
    echo "ℹ️ [3/3] Verifying and enabling essential services..."

    # Ensure systemd-resolved is enabled (Required for DoT/DNSSEC hardening)
    if ! systemctl is-active --quiet systemd-resolved; then
      echo "💡 Enabling systemd-resolved..."
      systemctl unmask systemd-resolved
      systemctl enable --now systemd-resolved
    else
      echo "✅ systemd-resolved is already active."
    fi

    # Ensure NetworkManager is enabled (Required for MAC Randomization)
    if ! systemctl is-active --quiet NetworkManager; then
      echo "💡 Enabling NetworkManager..."
      systemctl unmask NetworkManager
      systemctl enable --now NetworkManager
    else
      echo "✅ NetworkManager is already active."
    fi

    # Ensure UFW is installed but NOT enabled yet (The main script enables it)
    if command -v ufw >/dev/null 2>&1; then
      echo "✅ UFW (Uncomplicated Firewall) is ready."
    else
      echo "❌ Error: UFW installation failed."
      exit 1
    fi

  else
    echo "❌ Error: Unsupported OS (${ID})."
    exit 1
  fi

  echo "--------------------------------------------------------"
  echo "✅ DEPENDENCIES INSTALLED SUCCESSFULLY."
  echo "   You can now proceed to run 'ubuntu_secure_network.sh'."
  echo "--------------------------------------------------------"

  echo ""
  echo ""
  echo ""
  echo "🔒 Starting Deep Defense Network Hardening..."

  # ==============================================================================
  # [Step 1] DNS Hardening (DoT + DNSSEC + No-Log)
  # ==============================================================================
  echo "ℹ️ [1/4] Configuring Secure DNS (DoT & DNSSEC)..."
  mkdir -p /etc/systemd/resolved.conf.d

  cat <<EOF >/etc/systemd/resolved.conf.d/99-secure-dns.conf
[Resolve]
# Primary: Cloudflare (Privacy & Speed)
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
# Fallback: Google (Availability Backup)
FallbackDNS=8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844
# Security Enforcements
DNSOverTLS=yes
DNSSEC=yes
Domains=~.
# Privacy: Disable Local Discovery (Prevents mDNS leakage)
MulticastDNS=no
LLMNR=no
Cache=yes
EOF

  # Force Symlink & Restart
  echo "ℹ️ Linking /etc/resolv.conf to systemd-resolved stub..."

  # 🚀 Ubuntu: Force symlink to ensure it points to the correct stub path
  # Some environments may have static files; -f ensures overwrite.
  ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

  # 🚀 Restart service to apply new DNS configurations
  systemctl restart systemd-resolved

  # ==============================================================================
  # [Step 2] Kernel Network Stack Hardening (Sysctl)
  # ==============================================================================
  echo "ℹ️ [2/4] Hardening Kernel Network Stack..."

  cat <<EOF >/etc/sysctl.d/99-security-hardening.conf
# ⚠️ IP Spoofing Protection (Strict)
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
# ⚠️ Prevent MITM (Disable ICMP Redirects)
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
# ⚠️ Ignore ICMP Broadcasts (Smurf Attack)
net.ipv4.icmp_echo_ignore_broadcasts = 1
# ⚠️ Log Suspicious Packets (Martians)
net.ipv4.conf.all.log_martians = 1
# ⚠️ TCP SYN Cookies (DoS Protection)
net.ipv4.tcp_syncookies = 1
# ⚠️ IPv6 Privacy Extensions
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2
EOF

  sysctl --system >/dev/null

  # ==============================================================================
  # [Step 3] Identity Obfuscation (MAC Randomization)
  # ==============================================================================
  echo "ℹ️ [3/4] Configuring MAC Address Randomization..."

  cat <<EOF >/etc/NetworkManager/conf.d/99-privacy.conf
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
ipv6.ip6-privacy=2
EOF

  systemctl reload NetworkManager

  # ==============================================================================
  # [Step 4] Firewall Rules (UFW - Deep Defense)
  # ==============================================================================
  echo "ℹ️ [4/4] Applying Strict Firewall Rules..."

  # Reset & Default Policies
  ufw --force reset >/dev/null
  ufw default deny incoming
  ufw default allow outgoing

  # ⚠️ Block Legacy/Insecure Protocols Explicitly
  ufw deny out 53/udp   # Block Plaintext DNS
  ufw deny out 53/tcp   # Block Plaintext DNS
  ufw deny out 5353/udp # Block mDNS (Multicast)

  # ℹ️ Allow Essential Secure Protocols
  ufw allow out 853/tcp # Allow DNS over TLS
  ufw allow out 443/tcp # Allow HTTPS
  ufw allow out 123/udp # Allow NTP (Time Sync)

  # Enable Firewall
  echo "y" | ufw enable

  echo "--------------------------------------------------------"
  echo "✅ DEEP DEFENSE APPLIED SUCCESSFULLY."
  echo "   - DNS: DoT/DNSSEC Enforced"
  echo "   - Kernel: Anti-Spoofing/Redirects Active"
  echo "   - ID: MAC Randomization Active"
  echo "   - Firewall: Ingress Denied / Legacy DNS Blocked"
  echo "--------------------------------------------------------"
  echo "⚠️  REBOOT RECOMMENDED to flush kernel/network states."
  echo "--------------------------------------------------------"
} # }}}

function_validation() { # {{{
  echo "🕵️ Deep Defense Validation"

  echo ""
  echo ""
  echo "[Step 1] Verify DNS Security (DoT & DNSSEC)"
  echo "------------------------------------------------------------------------------"

  echo "1. Check Protocol Status"
  resolvectl status
  echo "    [Check] Look for \"+DNSOverTLS\" and \"DNSSEC=yes/supported\"."

  echo ""
  echo "2. Check Query Encryption"
  resolvectl query google.com
  echo "    [Check] Output must say \"Data was acquired via local or encrypted transport: yes\"."
  echo "    [Check] Ensure the DNS server listed is 1.1.1.1 (Cloudflare) or 8.8.8.8 (Google)."

  echo ""
  echo "3. Packet Inspection (Deep Check)"
  sudo tcpdump -ni any port 53 or port 853
  echo "    [Check] Open a browser and visit a website."
  echo "          - Port 53 (UDP/TCP) should show NO traffic (or only blocked attempts)."
  echo "          - Port 853 (TCP) should show active encrypted traffic."

  echo ""
  echo ""
  echo "[Step 2] Verify Kernel Hardening (Sysctl)"
  echo "------------------------------------------------------------------------------"

  echo "1. Check Anti-Spoofing & Redirects"
  sysctl net.ipv4.conf.all.rp_filter net.ipv4.conf.all.accept_redirects
  echo "    [Check] net.ipv4.conf.all.rp_filter = 1 (Spoofing Protection ON)"
  echo "    [Check] net.ipv4.conf.all.accept_redirects = 0 (Redirects OFF)"

  echo ""
  echo "2. Check SYN Flood Protection"
  sysctl net.ipv4.tcp_syncookies
  echo "    [Check] net.ipv4.tcp_syncookies = 1 (Active)"

  echo ""
  echo ""
  echo "[Step 3] Verify MAC Address Randomization"
  echo "------------------------------------------------------------------------------"

  echo "1. Check Interface Address"
  ip link show
  echo "    [Check] Compare 'link/ether' (Current Address) vs 'permaddr' (Real Hardware)."
  echo "            They MUST BE DIFFERENT."

  echo ""
  echo "2. Check NetworkManager Logs"
  journalctl -u NetworkManager | grep -i "MAC"
  echo "    [Check] Look for logs saying \"set-cloned MAC address to ... (random)\"."

  echo ""
  echo ""
  echo "[Step 4] Verify Firewall (UFW) & Leak Protection"
  echo "------------------------------------------------------------------------------"

  echo "1. Check Firewall Rules"
  sudo ufw status verbose
  echo "    [Check] 53/udp & 53/tcp should be 'DENY OUT'."
  echo "    [Check] 853/tcp should be 'ALLOW OUT'."

  echo ""
  echo "2. Penetration Test (Force Plaintext DNS)"
  dig @8.8.8.8 google.com -p 53
  echo "[Check] Result MUST be \";; connection timed out\" or \";; communications error\"."
  echo "        If it returns an IP address, the firewall is NOT working correctly."

  echo ""
  echo ""
  echo "=============================================================================="
  echo "🚀 QUICK CHECK ONE-LINER (Copy & Paste to Terminal)"
  echo "=============================================================================="
  echo "--- [DNS] ---" && resolvectl status | grep -E "DNSOverTLS|DNSSEC"
  echo "--- [Kernel] ---" && sysctl net.ipv4.conf.all.rp_filter net.ipv4.tcp_syncookies
  echo "--- [Firewall] ---" && sudo ufw status | grep "53"
  echo "--- [MAC] ---" && nmcli device show | grep "GENERAL.HWADDR"
  echo "=============================================================================="
} # }}}

# ==============================================================================
# 🚀 Main Menu Selection
# ==============================================================================
echo "========================================================"
echo "    🛡️  Ubuntu / Debian Linux Network Hardening System"
echo "========================================================"
echo "  1) [Hardening] Apply security settings"
echo "  2) [Validation] Test current security status"
echo "  3) [Exit] Quit script"
echo "--------------------------------------------------------"
read -p "Select an option [1-3]: " menu_choice

case $menu_choice in
1)
  echo "🚀 Starting hardening process..."
  function_network_hardening
  echo ""
  read -p "Do you want to run validation now? (y/n): " val_choice
  if [[ "$val_choice" =~ ^[Yy]$ ]]; then
    function_validation
  fi
  ;;
2)
  echo "🕵️ Starting validation process..."
  function_validation
  ;;
3)
  echo "Bye! ✅"
  exit 0
  ;;
*)
  echo "❌ Invalid option. Please run the script again and select 1, 2, or 3."
  exit 1
  ;;
esac

# Manual
# ------
# ROLLBACK & RECOVERY STRATEGIES {{{
# ==============================================================================
# 🆘 ROLLBACK & RECOVERY STRATEGIES (Copy & Paste as needed)
# ==============================================================================
#
# [SCENARIO A] 🚑 Emergency: Captive Portal (Starbucks/Hotel Wi-Fi)
# Problem: Login page won't load because it needs HTTP redirects & Plain DNS.
# Solution: Temporarily disable firewall.
#
#   sudo ufw disable
#   # (Login to Wi-Fi...)
#   sudo ufw enable
#
#
# [SCENARIO B] 🏠 Home Use: Printer/Chromecast/NAS Not Found
# Problem: mDNS/LLMNR blocked by BOTH OS settings and Firewall.
# Solution: You must enable mDNS at the OS level AND open the firewall port.
#
# 1. 🔓 UNLOCK (Temporarily Enable Discovery):
#    # (1) Enable MulticastDNS in resolved.conf (No -> Yes)
#    sudo sed -i 's/MulticastDNS=no/MulticastDNS=yes/' /etc/systemd/resolved.conf.d/99-secure-dns.conf
#    sudo systemctl restart systemd-resolved
#    # (2) Allow mDNS in Firewall
#    sudo ufw allow out 5353/udp
#
# 2. 🔒 RELOCK (Restore Deep Defense):
#    # (1) Disable MulticastDNS (Yes -> No)
#    sudo sed -i 's/MulticastDNS=yes/MulticastDNS=no/' /etc/systemd/resolved.conf.d/99-secure-dns.conf
#    sudo systemctl restart systemd-resolved
#    # (2) Remove Firewall Rule
#    sudo ufw delete allow out 5353/udp
#    sudo ufw reload
#
#
# [SCENARIO C] 💥 Hard Reset: Internet is Broken / Uninstall Everything
# Problem: Something is wrong, or you want to return to stock Ubuntu.
# Solution: Delete all configs and reset services.
#
#   # 1. Remove DNS Config
#   sudo rm -f /etc/systemd/resolved.conf.d/99-secure-dns.conf
#   sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
#   sudo systemctl restart systemd-resolved
#
#   # 2. Remove Kernel Hardening (Requires Reboot to fully clear)
#   sudo rm -f /etc/sysctl.d/99-security-hardening.conf
#
#   # 3. Remove MAC Randomization
#   sudo rm -f /etc/NetworkManager/conf.d/99-privacy.conf
#   sudo systemctl reload NetworkManager
#
#   # 4. Reset Firewall
#   sudo ufw --force reset
#   sudo ufw disable
#
#   echo "✅ System restored to factory defaults. Please REBOOT."
# ==============================================================================
# }}}

# VERIFICATION MANUAL {{{
# ==============================================================================
# 🕵️ VERIFICATION MANUAL (Deep Defense Validation)
# ==============================================================================
# Run the following commands to verify that hardening is active.
#
# [Step 1] Verify DNS Security (DoT & DNSSEC)
# ------------------------------------------------------------------------------
# 1. Check Protocol Status
#    $ resolvectl status
#    [Check] Look for "+DNSOverTLS" and "DNSSEC=yes/supported".
#
# 2. Check Query Encryption
#    $ resolvectl query google.com
#    [Check] Output must say "Data was acquired via local or encrypted transport: yes".
#    [Check] Ensure the DNS server listed is 1.1.1.1 (Cloudflare) or 8.8.8.8 (Google).
#
# 3. Packet Inspection (Deep Check)
#    $ sudo tcpdump -ni any port 53 or port 853
#    [Check] Open a browser and visit a website.
#            - Port 53 (UDP/TCP) should show NO traffic (or only blocked attempts).
#            - Port 853 (TCP) should show active encrypted traffic.
#
# [Step 2] Verify Kernel Hardening (Sysctl)
# ------------------------------------------------------------------------------
# 1. Check Anti-Spoofing & Redirects
#    $ sysctl net.ipv4.conf.all.rp_filter net.ipv4.conf.all.accept_redirects
#    [Check] net.ipv4.conf.all.rp_filter = 1 (Spoofing Protection ON)
#    [Check] net.ipv4.conf.all.accept_redirects = 0 (Redirects OFF)
#
# 2. Check SYN Flood Protection
#    $ sysctl net.ipv4.tcp_syncookies
#    [Check] net.ipv4.tcp_syncookies = 1 (Active)
#
# [Step 3] Verify MAC Address Randomization
# ------------------------------------------------------------------------------
# 1. Check Interface Address
#    $ ip link show
#    [Check] Compare 'link/ether' (Current Address) vs 'permaddr' (Real Hardware).
#            They MUST BE DIFFERENT.
#
# 2. Check NetworkManager Logs
#    $ journalctl -u NetworkManager | grep -i "MAC"
#    [Check] Look for logs saying "set-cloned MAC address to ... (random)".
#
# [Step 4] Verify Firewall (UFW) & Leak Protection
# ------------------------------------------------------------------------------
# 1. Check Firewall Rules
#    $ sudo ufw status verbose
#    [Check] 53/udp & 53/tcp should be 'DENY OUT'.
#    [Check] 853/tcp should be 'ALLOW OUT'.
#
# 2. Penetration Test (Force Plaintext DNS)
#    $ dig @8.8.8.8 google.com -p 53
#    [Check] Result MUST be ";; connection timed out" or ";; communications error".
#            If it returns an IP address, the firewall is NOT working correctly.
#
# ==============================================================================
# 🚀 QUICK CHECK ONE-LINER (Copy & Paste to Terminal)
# ==============================================================================
# echo "--- [DNS] ---" && resolvectl status | grep -E "DNSOverTLS|DNSSEC"
# echo "--- [Kernel] ---" && sysctl net.ipv4.conf.all.rp_filter net.ipv4.tcp_syncookies
# echo "--- [Firewall] ---" && sudo ufw status | grep "53"
# echo "--- [MAC] ---" && nmcli device show | grep "GENERAL.HWADDR"
# ==============================================================================
# }}}
# ------
