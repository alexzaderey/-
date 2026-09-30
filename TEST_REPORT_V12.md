# Zalex V12 Test Report

Date: 2026-09-10

## Result

**PASS — 66 tests passed.**

Command:

```bash
PYTHONPATH=. pytest -q zalex/tests
```

## V12-specific coverage

`zalex/tests/test_semantic_v12.py` verifies:

1. Franki emits a precise semantic fact request.
2. Competing numeric voltage candidates produce `AMBIGUOUS` instead of a guess.
3. Semantic operations and assertions execute deterministically.
4. Incompatible units are rejected.
5. The Orchestrator executes the new `semantic` action and returns a structured observation.

## Regression coverage

The existing V11 suite remains green, including:

- ingestion / OCR / structure detection
- chunking / manifests / watcher
- context builder and 3500-token ceiling
- Franki JSON planner contract
- ReAct controller
- Sandbox and Validation Gate
- Experience SQLite store
- deterministic tools and capability policy
- llama-server transport

## V12 architectural guarantees

- Franki does not select physical constants from raw retrieval results.
- Fact requests contain semantic search intent.
- Ambiguous facts fail closed.
- Runtime facts, Knowledge facts and Experience facts are typed and provenance-bearing.
- Deterministic operations replace Python for common comparisons/calculations.
- Assertion compilation is separate from operation execution.
- Semantic PASS can enter Experience only through the existing Validation Gate.
- Python/Sandbox remains available as a controlled fallback.
