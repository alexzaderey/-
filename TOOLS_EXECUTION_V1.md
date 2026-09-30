# Zalex — Tools & Execution Layer v1.1

## Architectural rule

The Tools Tier is domain-neutral. It contains no inverter/BMS/solar/battery constants, physical limits, equipment-specific formulas, or model-specific facts.

All domain parameters must be supplied at runtime as explicitly resolved facts from Knowledge/Experience, carrying provenance. Tools do not access ChromaDB or Experience directly.

## Six implementation steps

1. **Contracts** — `ToolSpec`, `ToolCall`, `RuntimeFact`, `ToolContext`, `ToolResult`. Runtime facts require provenance and an origin of `knowledge` or `experience`.
2. **Registry** — explicit registration only; duplicate/invalid tools are rejected; no hidden tools.
3. **Execution boundary** — one `ToolExecutor` validates arguments, applies policy, executes the registered tool, normalizes failures, records call ID and execution time, and enforces argument/call limits.
4. **Generic tools** — calculator, restricted Python/Sandbox, and read-only allowlisted filesystem access. No domain constants are embedded. Knowledge/Experience facts take precedence over caller variables with the same key.
5. **Validation boundary** — generic result assertions (`equals`, `contains`, `numeric_range`) are evaluated separately from execution status. `SUCCESS` means execution succeeded, not physical correctness.
6. **Security/capabilities** — tool allowlist, capability allowlist, risk-level policy, per-step call limit, argument-size limit, restricted Python, and filesystem allowlist.

## Execution contract

1. Franki proposes an abstract tool call.
2. Zalex resolves required domain facts from Knowledge/Experience.
3. Zalex constructs `RuntimeFact` objects with provenance.
4. `ToolExecutor` validates capability and invokes the registered tool.
5. The tool returns a structured `ToolResult`.
6. Generic assertions may validate the returned data without changing execution status.
7. Assertions/Validation Gate decide whether a result is trusted or can enter Experience.

## Generic v1 tools

- `calculator` — deterministic arithmetic.
- `python` — restricted Python backed by the existing Sandbox.
- `filesystem.read` — read-only, explicit allowlist.

## Security

- explicit registry; no hidden tools
- tool and capability allowlists
- risk-level policy
- per-step call limit
- argument-size limit
- read-only filesystem tool
- Python remains behind the existing restricted Sandbox
- unknown tools are rejected

## Deliberate boundary

The current foundation provides the runtime-fact contract but does not pretend that arbitrary text in a Chroma chunk is already a trusted parameter. A dedicated `RuntimeFactResolver`/provenance layer remains the next integration point before domain-sensitive execution is considered production-complete.

## Verification

Each of the six steps was implemented incrementally and tested before continuing:

- Step 1: **52 passed**
- Step 2: **53 passed**
- Step 3: **54 passed**
- Step 4: **56 passed**
- Step 5: **58 passed**
- Step 6: **60 passed**
- Final integration regression after orchestrator/tool integration fix: **61 passed**
