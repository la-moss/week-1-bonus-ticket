# Azure DR Refresher (Terraform) — Senior Practice Ticket

## Context
The **payments** platform runs active/passive across **UK South (primary)** and **West Europe (secondary)**. The design is hub/spoke per region with global failover via Traffic Manager.

Recent DR drill results showed:
- Failover traffic does not consistently reach the secondary stack.
- Networking paths differ between regions (some spokes can reach shared services only in one region).
- CI guardrail is failing on DR readiness checks.

This repo is a hands-on refresher: inspect the Terraform, reproduce the guardrail findings, and harden the DR path without expanding blast radius.

## Scope
- Two regions via provider aliases (`primary`, `secondary`)
- Hub/spoke VNets per region
- Cross-region hub peering (for shared services + operator access patterns)
- Public entry points (per region) + Traffic Manager profile
- Minimal storage footprint to anchor DR patterns (account per region)

## Acceptance criteria
- Terraform formatting + validation are clean (CI syntax job).
- Guardrail passes:
  - Standard tags present on resources (incl. `owner`).
  - Secondary region is treated as a first-class deployment target.
  - DR connectivity primitives exist in both directions where required.
  - Failover routing includes the secondary entry point.

## Evidence to attach in your PR
- `terraform validate` output (local).
- Guardrail output before/after.
- A short note on the DR design trade-offs you chose (RTO/RPO implications).

## Notes
- CI runs Terraform with `-backend=false`.
- The guardrail is **static analysis** of configuration (no Azure credentials required).

