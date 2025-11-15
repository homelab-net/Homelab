HOMELAB v3 – MASTER DOCUMENT
Source of Truth for Architecture, History, Wins & Losses, and Node 1 (KAMRUI) Design
------------------------------------------------------------------------------------

Author: Cameron Zobrist
Date: 2025
Project Scope: Homelab v3 rebuild on KAMRUI Essenx E2 mini-PC with future Proxmox cluster expansion.

====================================================================================
1. EXECUTIVE SUMMARY
====================================================================================

Homelab v3 is a full reboot of Cameron's homelab environment following the loss of the
previous gaming PC Proxmox host. The new foundation begins with a small KAMRUI Essenx E2
(Intel N150, 4-core, 16GB RAM) as Cluster Node 1.

Node 1 is now positioned at:
    Proxmox Host IP: 192.168.8.20

The v3 design emphasizes:
✔ Minimalism
✔ Reliability
✔ Cluster readiness
✔ Git-backed configuration
✔ Low hardware overhead
✔ Clean separation of responsibilities

This document serves as the authoritative source for all future contributors and
cluster nodes. All information here supersedes v1 and v2.x-era documents unless those
documents are referenced for historical context or lessons learned.

====================================================================================
2. PROJECT HISTORY: V1 → V2.x → V3
====================================================================================

------------------------------------------
V1: "The Chaotic Lab" (Retired)
------------------------------------------
Source: Old (v1) homelab config.docx

Wins:
- First successful Proxmox deployment
- First Pi-hole and DNS customization
- First GPU passthrough success
- Started documentation culture

Fails:
- Poor role separation (mono-VM design)
- Pi-hole IPv6 leak issues (could not override ISP IPv6 DNS)
- No observability or backups
- GPU passthrough inconsistent
- Configuration drift and no Git discipline
- Hardware was modest and unstable

Outcome:
V1 became unmaintainable → restart to v2.x.

------------------------------------------
V2.x: "The Architected Era"
------------------------------------------
Sources:
- Homelab Roadmap v2.1/v2.2/v2.3
- Hardware Inventory v2
- Migration Checklist v2.1

Major Wins:
- Mature architecture with full role separation
- dns-1 / dns-2 with Technitium
- WireGuard (wg-1) as remote access lifeline
- Full observability stack (Prometheus, Grafana, Loki)
- GPU handoff between AI VM and gaming VM (elite design)
- Open WebUI with vLLM, llama.cpp, voice satellites
- PBS nightly backups with 7/4/3 retention
- Hardened security baseline

Major Fails / Limitations:
- Depended on a large gaming PC (4060 GPU, 96GB RAM)
  → Once lost, the entire homelab collapsed.
- Overly complex for realistic daily sustainability
- GPU passthrough was brittle across reboots and updates
- Dual-boot Proxmox + Windows proved unstable
- Too many heavy services (DB-1, media-1, AI-1, infra-1)
- Not hardware-agnostic

Outcome:
Architecture was strong—but too heavyweight.
A reset was required.

------------------------------------------
V3: "Rebirth on Minimal Hardware"
------------------------------------------
Hardware: KAMRUI Essenx E2 (N150, 16GB RAM)

Guiding Principles:
✔ Start small
✔ Keep essential services only
✔ Use cluster-ready architecture
✔ Use lightweight observability and containers
✔ Avoid every past point of fragility
✔ Prepare for multi-node expansion

Node 1 now focuses ONLY on:
- dns-1
- dns-2
- wg-1
- infra-1

Stretch goals (run one at a time):
- ai-1 (CPU only)
- media-1 (CPU only)

All past complexity (GPU handoff, vLLM, Postgres DB-1, heavy media stack)
is deferred to future cluster nodes.

====================================================================================
3. ACTIVE NETWORK DESIGN (v3)
====================================================================================

Router: Flint 2
Router IP: 192.168.8.1
LAN: 192.168.8.0/24
Gateway for everything: 192.168.8.1

Authoritative Node 1 IP:
    Proxmox Host = 192.168.8.20

VM Address Plan (v3 Final):
    dns-1      → 192.168.8.81
    dns-2      → 192.168.8.82
    wg-1       → 192.168.8.21
    infra-1    → 192.168.8.60
    ai-1       → 192.168.8.70  (stretch)
    media-1    → 192.168.8.40  (stretch)

Reserved future cluster nodes:
    Node2 → 192.168.8.10
    Node3 → 192.168.8.11
    Node4 → 192.168.8.12

====================================================================================
4. ACTIVE ARCHITECTURE (v3)
====================================================================================

------------------------------------------
Core Always-On Services
------------------------------------------
1. dns-1
   - Technitium DNS
   - 1.5GB RAM / 1 vCPU
   - Upstream → Cloudflare / Quad9
   - No IPv6 RA until Flint2 configuration is validated

2. dns-2
   - Secondary Technitium
   - Mirrors dns-1 zones

3. wg-1
   - WireGuard VPN access
   - 1GB RAM / 1 vCPU
   - Generates peer QR codes
   - AllowedIPs includes LAN + DNS

4. infra-1
   - Light container infrastructure
   - Contains:
        - Traefik reverse proxy
        - VictoriaMetrics (replaces Prometheus)
        - Grafana Lite (dashboard only)
        - Promtail (log collection)
   - 4-6GB RAM / 2 vCPU

------------------------------------------
Stretch Services
------------------------------------------
ai-1:
- CPU-only llama.cpp
- 7B or 8B Q4_K_M model only
- No vLLM (GPU-required)
- Only run when infra load is low

media-1:
- CPU-only Jellyfin
- Suitable for very light direct-play workloads
- Not for transcoding-heavy environments

------------------------------------------
Not Allowed on Node 1 (Due to Hardware Limits)
------------------------------------------
- vLLM backend
- 32B/72B models
- GPU passthrough
- DB-1 Postgres
- Full media server stack
- Voice satellite backend services
- Loki (too RAM-heavy)
- Heavy Docker swarms

====================================================================================
5. WINS & FAILURES ACROSS GENERATIONS (CONDENSED)
====================================================================================

------------------------------------------
Top Wins (All Generations)
------------------------------------------
✓ Excellent documentation habits
✓ Role-separated services
✓ WireGuard remote access success
✓ Technitium DNS mastery
✓ Observability-first mindset
✓ GPU passthrough architecture (v2.x)
✓ Voice + AI stack (v2.3)
✓ Backup hygiene through PBS

------------------------------------------
Top Failures / Lessons Learned
------------------------------------------
✗ Over-dependence on a single machine
✗ Too many VMs for available hardware
✗ GPU passthrough fragility
✗ IPv6 DNS leak problems
✗ Heavy observability workloads
✗ Database services on insufficient RAM
✗ Unstable dual-boot Proxmox/Windows
✗ No hardware abstraction in v2.x

------------------------------------------
Core Lessons Carried into v3
------------------------------------------
✔ Minimalism is more stable
✔ Cluster-first design prevents collapse
✔ Observability must be lightweight
✔ GPU workflows belong on dedicated nodes
✔ DNS + VPN are the heart of the lab
✔ Git-backed configs prevent drift

====================================================================================
6. FINAL v3 SYSTEM DESIGN SUMMARY
====================================================================================

Node1 (KAMRUI) Summary:
-------------------------------------------------
Host: 192.168.8.20
RAM: 16GB
Cores: 4
Primary Role: Networking + Infra Core

Always-On VMs:
-------------------------------------------------
dns-1: 192.168.8.81
dns-2: 192.168.8.82
wg-1:  192.168.8.21
infra-1: 192.168.8.60

Stretch (One At a Time):
-------------------------------------------------
ai-1: 192.168.8.70
media-1: 192.168.8.40

Cluster Growth Plan:
-------------------------------------------------
Node 2 → AI workloads (CPU/GPU)
Node 3 → Media + storage
Node 4 → Database + redundancy
Eventually: Ceph or ZFS replication

====================================================================================
7. CONTRIBUTOR GUIDANCE
====================================================================================

For anyone contributing to the v3 homelab:

1. This document is the source of truth.
2. Do not reintroduce v2.x components unless hardware allows it.
3. All IPs must follow the v3 addressing convention.
4. All new services must:
   - run in containers where possible
   - integrate with infra-1 observability
   - be documented in Git before deployment
5. Avoid:
   - GPU passthrough complexity on lightweight nodes
   - heavy databases without dedicated hardware
   - running stretch services concurrently on Node 1

====================================================================================
8. FUTURE DIRECTIONS
====================================================================================

Short-Term:
- Add Node2 (N100 or Ryzen mini-PC)
- Migrate ai-1 or media-1 off Node1
- Begin cluster formation

Mid-Term:
- Introduce PBS node for backups
- Add STT/TTS stack (Wyoming)
- Add Qdrant as RAG backend

Long-Term:
- Add GPU node (4090 or similar)
- Distribute services across nodes
- Implement HA, Traefik failover
- Migrate DNS/infra to dual-node redundancy

====================================================================================
END OF DOCUMENT
====================================================================================
