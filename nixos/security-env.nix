# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Security & Pentesting — On-demand nix-shell                               ║
# ║                                                                            ║
# ║  Usage:                                                                    ║
# ║    nix-shell security-env.nix                    ← full security toolkit   ║
# ║    nix-shell security-env.nix -A recon           ← reconnaissance only     ║
# ║    nix-shell security-env.nix -A exploit         ← exploitation tools      ║
# ║    nix-shell security-env.nix -A reversing       ← reverse engineering     ║
# ║    nix-shell security-env.nix -A wifi            ← wireless security       ║
# ║    nix-shell security-env.nix -A web             ← web application testing ║
# ║    nix-shell security-env.nix -A network         ← network analysis        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
let
  nixpkgs = import <nixpkgs> {};
in
{
  # ── Full Security Environment ────────────────────────────────
  default = nixpkgs.mkShell {
    name = "security-env";
    buildInputs = with nixpkgs; [
      # Reconnaissance & Scanning
      nmap
      nikto
      gobuster
      nuclei
      wapiti
      octoscan
      osv-scanner
      http-scanner
      secretscanner
      netscanner
      mdns-scanner
      vulnix             # Nix-specific vulnerability scanner
      lynis              # System security audit

      # Web Application Testing
      sqlmap
      sqlmc
      laudanum
      zap                # OWASP ZAP proxy
      burpsuite          # Web security testing GUI

      # Network Analysis
      wireshark
      tshark
      termshark
      ettercap           # Network sniffer/MITM
      cifs-utils

      # Exploitation
      metasploit
      thc-hydra          # Login cracker
      hashcat            # Password recovery
      checkmate

      # Wireless Security
      aircrack-ng
      hcxtools           # WiFi capture tools

      # Reverse Engineering
      radare2            # Binary analysis
      ghidra-bin         # RE suite (GUI)
      cutter             # RE GUI (Rizin-based)
      iaito              # Radare2 GUI
      degate             # IC reverse engineering
      apktool            # Android APK RE

      # Container Security
      dockle             # Container security linter
      tracee             # Runtime security (eBPF)
      checkov            # IaC security scanner

      # Password Cracking (GUI)
      johnny             # John the Ripper GUI

      # Runtime/Misc
      sssd
    ];
    shellHook = ''
      echo "🛡️  Security & Pentesting environment loaded"
      echo "   Tools: nmap, metasploit, burpsuite, wireshark, ghidra, ..."
      echo ""
    '';
  };

  # ── Reconnaissance Only ──────────────────────────────────────
  recon = nixpkgs.mkShell {
    name = "security-recon";
    buildInputs = with nixpkgs; [
      nmap nikto gobuster nuclei wapiti
      osv-scanner vulnix lynis
      netscanner mdns-scanner http-scanner
      octoscan secretscanner
    ];
    shellHook = ''
      echo "🔍 Reconnaissance environment loaded"
    '';
  };

  # ── Exploitation ─────────────────────────────────────────────
  exploit = nixpkgs.mkShell {
    name = "security-exploit";
    buildInputs = with nixpkgs; [
      metasploit thc-hydra hashcat
      sqlmap sqlmc laudanum checkmate
    ];
    shellHook = ''
      echo "💥 Exploitation environment loaded"
    '';
  };

  # ── Reverse Engineering ──────────────────────────────────────
  reversing = nixpkgs.mkShell {
    name = "security-reversing";
    buildInputs = with nixpkgs; [
      radare2 ghidra-bin cutter iaito
      degate apktool
    ];
    shellHook = ''
      echo "🔬 Reverse engineering environment loaded"
    '';
  };

  # ── Wireless Security ───────────────────────────────────────
  wifi = nixpkgs.mkShell {
    name = "security-wifi";
    buildInputs = with nixpkgs; [
      aircrack-ng hcxtools
    ];
    shellHook = ''
      echo "📡 Wireless security environment loaded"
    '';
  };

  # ── Web Application Testing ─────────────────────────────────
  web = nixpkgs.mkShell {
    name = "security-web";
    buildInputs = with nixpkgs; [
      sqlmap sqlmc nikto gobuster wapiti
      zap burpsuite nuclei
    ];
    shellHook = ''
      echo "🌐 Web application testing environment loaded"
    '';
  };

  # ── Network Analysis ────────────────────────────────────────
  network = nixpkgs.mkShell {
    name = "security-network";
    buildInputs = with nixpkgs; [
      wireshark tshark termshark
      ettercap cifs-utils
    ];
    shellHook = ''
      echo "🔌 Network analysis environment loaded"
    '';
  };
}
