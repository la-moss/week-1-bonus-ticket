# Ticket: Azure DR refresher (Terraform)

## Situation
DR drill indicates the secondary region is not fully participating in failover, and connectivity differs between regions. CI guardrail currently fails.

## Tasks (investigation-first)
1. **Establish the intended DR architecture**
   - Confirm primary/secondary regions and the hub/spoke topology.
   - Identify which resources are expected to exist in both regions.

2. **Run local validation**
   - `terraform -chdir=senior/terraform init -backend=false`
   - `terraform -chdir=senior/terraform validate`

3. **Run the guardrail**
   - `python tools/guardrail/guardrail.py`
   - Capture output before changes.

4. **Prove the symptom with evidence**
   - Enumerate: Traffic Manager endpoints, cross-region peerings, and tag coverage.
   - Record what is missing/misaligned (avoid broad refactors).

5. **Implement the minimal change set**
   - Make DR failover path complete.
   - Ensure multi-region resources are represented consistently.
   - Ensure standard tags are applied.

6. **Document rollback**
   - Describe how you would revert if the change causes unexpected routing.

## Evidence checklist
- Guardrail output before/after
- Terraform validate output
- A brief RTO/RPO note explaining your routing and dependency choices
