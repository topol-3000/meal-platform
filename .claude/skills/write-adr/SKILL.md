---
name: write-adr
description: Write an Architecture Decision Record in docs/adr. Use when a decision is hard to reverse, affects several services, or the user asks "why did we choose X".
---

# Write an ADR

1. Find the next number: `ls docs/adr | sort | tail -1`.
2. Copy `docs/adr/0000-template.md` to `docs/adr/NNNN-<kebab-title>.md`.
3. Fill every section. Keep it under one page:
   - **Context**: the forces and constraints, including what is out of scope.
   - **Decision**: one active-voice sentence first ("We use X for Y"), then details.
   - **Alternatives**: at least two real options with the reason each lost.
   - **Consequences**: good and bad, plus what would make us revisit this.
4. Status is `Proposed` until the user agrees, then `Accepted` with the date.
5. Never edit the decision of an accepted ADR. To change it, write a new ADR and set the old
   one to `Superseded by NNNN`.
6. Add the ADR to the index in `docs/adr/README.md`.
