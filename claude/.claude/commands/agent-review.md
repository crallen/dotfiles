---
description: Review agents, skills, and commands for correctness, consistency, and best practices
disable-model-invocation: true
---

Use the `@agent-reviewer` subagent to review the existing agents, skills, and slash commands for correctness, consistency, and adherence to conventions. Check structural correctness, cross-references, permission models, and quality.

If specific artifacts are named, focus the review there. Otherwise, audit the full suite.

Current agents:
!`ls ~/.claude/agents/ 2>/dev/null || echo "(none)"`

Current skills:
!`ls ~/.claude/skills/ 2>/dev/null || echo "(none)"`

Current commands:
!`ls ~/.claude/commands/ 2>/dev/null || echo "(none)"`

$ARGUMENTS
