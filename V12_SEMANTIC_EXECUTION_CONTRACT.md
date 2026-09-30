# Zalex V12 — Semantic Execution Contract

V12 fixes three architectural failures identified in V11:

1. **Orchestrator blindness** — deterministic Zalex no longer chooses a physical parameter merely because a vector result is nearby. Franki emits a precise semantic `fact_request` query; the Fact Resolver returns a typed fact or `AMBIGUOUS`/`NOT_FOUND`.
2. **Validation paradox** — Franki emits semantic assertions, not Python variable names. The Assertion Compiler deterministically evaluates the assertion DSL after facts and operations are resolved.
3. **Universal-tools trap** — common energy checks use deterministic operations (`less_or_equal`, `greater_or_equal`, `equals`, `range_check`, `calculate`). Python/Sandbox remains a fallback rather than the default.

## Runtime boundary

```text
User query
   |
   v
Franki semantic planner
   |
   | Task DSL
   | fact_requests: WHAT fact is needed + precise search query
   | operations: WHAT deterministic operation
   | assertions: WHAT must be true
   v
Zalex Semantic Engine
   |
   +--> Runtime Fact Resolver
   |
   +--> Knowledge Fact Resolver
   |       |
   |       +--> structured catalog when available
   |       +--> conservative retrieval bridge
   |           (never silently picks close competing values)
   |
   +--> Typed Runtime Context
   |
   +--> Deterministic Operation Engine
   |
   +--> Assertion Compiler
   v
EXECUTED + PASS/FAIL/INCONCLUSIVE
   |
   +--> PASS -> Validation Gate -> Experience
   +--> failure/ambiguity -> observation -> Franki replans
```

## Fact request example

```json
{
  "fact_id": "max_charge_voltage",
  "query": "максимальна напруга заряду JK BMS 24V",
  "unit": "V",
  "target": "battery",
  "purpose": "charge",
  "source": "knowledge"
}
```

The query is deliberately semantic and specific. `solar input voltage`, `maximum charge voltage`, `discharge cutoff`, and `BMS disconnect voltage` are different facts and must not collapse into one generic `voltage` key. `source` is `knowledge` for documentation/specification facts and `runtime` for live telemetry. A runtime `NOT_FOUND` or `AMBIGUOUS` result is fail-closed and is never replaced by Knowledge.

## Typed fact

A resolved fact carries value, unit and provenance. Provenance is mandatory. Runtime facts are marked `origin=runtime`; Knowledge/Experience remain `origin=knowledge`/`experience`.

## Ambiguity rule

The resolver is **fail-closed**. If two numeric candidates are close in relevance, the result is `AMBIGUOUS`. The controller does not guess. Franki receives the observation and must narrow the query or ask for clarification.

## Operation DSL

Supported V12 primitives:

- `less_or_equal`
- `greater_or_equal`
- `less_than`
- `greater_than`
- `equals`
- `range_check`
- `calculate`

Unit compatibility is checked before comparison. Voltage cannot silently be compared with current, power, etc.

Example:

```json
{
  "operation_id": "check_charge_limit",
  "type": "less_or_equal",
  "actual": {"fact": "battery_voltage"},
  "reference": {"fact": "max_charge_voltage"}
}
```

## Assertion DSL

```json
{
  "assertion_id": "a1",
  "type": "true",
  "actual": {"operation": "check_charge_limit"}
}
```

`operation_pass` is the preferred assertion for an operation result; comparison and range assertion forms are also supported for deterministic compatibility.

Franki never has to know the Python variable name that will be used at runtime. The compiler resolves `fact` and `operation` references and produces a deterministic PASS/FAIL/INCONCLUSIVE result.

## Experience boundary

Both Sandbox and Semantic Execution can enter Experience only through the Validation Gate. The required condition remains:

`EXECUTION == EXECUTED` **AND** `ASSERTIONS == PASS`

Franki has no Experience write path.

## Important deployment note

V12.1 defines the runtime/Knowledge semantic boundary, but it does not invent a live Home Assistant data source. A production deployment still needs an explicit Runtime Fact Provider (for example, a deterministic HA-state adapter) to populate facts such as `battery_voltage`. Until such a provider is configured, unresolved runtime facts must remain `NOT_FOUND`, not guessed.

The existing deterministic hash embedding remains explicitly non-semantic. A production semantic Knowledge retrieval path should use a real embedding-capable model/server or a structured fact catalog.
