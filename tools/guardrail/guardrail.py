import json
import os
import sys
from pathlib import Path

import hcl2

ROOT = Path(__file__).resolve().parents[2]
TF_ROOT = ROOT / "senior" / "terraform"

REQUIRED_TAGS = {"owner", "env", "project"}
REQUIRED_REGIONS = {"primary", "secondary"}

def load_hcl_files(tf_root: Path):
    docs = []
    for p in sorted(tf_root.rglob("*.tf")):
        with p.open("r", encoding="utf-8") as f:
            docs.append((p, hcl2.load(f)))
    return docs

def collect_providers(docs):
    aliases = set()
    for _, d in docs:
        for pb in d.get("provider", []):
            if "azurerm" in pb:
                az = pb["azurerm"]
                if isinstance(az, dict) and "alias" in az:
                    aliases.add(str(az["alias"]))
    return aliases

def iter_resources(docs):
    for _, d in docs:
        for rb in d.get("resource", []):
            # rb: { "type": { "name": { ... } } }
            for rtype, instances in rb.items():
                for name, body in instances.items():
                    yield rtype, name, body

def extract_tags(body):
    tags = body.get("tags")
    if isinstance(tags, dict):
        return set(tags.keys())
    return None

def fail(msg):
    print(msg)
    sys.exit(1)

def main():
    if not TF_ROOT.exists():
        fail("guardrail unmet: terraform root not found")

    docs = load_hcl_files(TF_ROOT)

    aliases = collect_providers(docs)
    if not REQUIRED_REGIONS.issubset(aliases):
        fail("guardrail unmet: multi-region providers incomplete")

    # Tag checks: require standard tags on all azurerm resources that expose tags blocks
    missing_tagged = []
    for rtype, name, body in iter_resources(docs):
        if not rtype.startswith("azurerm_"):
            continue
        if "tags" in body:
                present = extract_tags(body)
                if present is not None and (not REQUIRED_TAGS.issubset(present)):
                    missing_tagged.append(f"{rtype}.{name}")

    if missing_tagged:
        fail("guardrail unmet: standard tags missing")

    # DR path checks (static):
    # - Traffic Manager should have >= 2 Azure endpoints
    tm_endpoints = []
    peerings = []
    for rtype, name, body in iter_resources(docs):
        if rtype == "azurerm_traffic_manager_azure_endpoint":
            tm_endpoints.append(name)
        if rtype == "azurerm_virtual_network_peering":
            peerings.append(name)

    if len(tm_endpoints) < 2:
        fail("guardrail unmet: failover endpoints incomplete")

    # Cross-region hub peering should be bidirectional.
expected_cross_region = {"pri_hub_to_dr_hub", "dr_hub_to_pri_hub"}
found_cross_region = set()
for rtype, name, body in iter_resources(docs):
    if rtype == "azurerm_virtual_network_peering" and name in expected_cross_region:
        found_cross_region.add(name)

if found_cross_region != expected_cross_region:
    fail("guardrail unmet: cross-region peering incomplete")

    print("guardrail met")
    return 0

if __name__ == "__main__":
    main()
