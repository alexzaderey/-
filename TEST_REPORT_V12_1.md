# Zalex V12.1 — Regression Report

## Result

**PASS — 75 tests passed.**

Command:

```bash
PYTHONPATH=. pytest -q
```

Runtime: 15.23 s in the validation environment.

## Fixed

1. **Runtime/Knowledge boundary**
   - `FactRequest.source` now explicitly supports `runtime`, `knowledge`, and `auto`.
   - A `runtime` request is fail-closed: `NOT_FOUND` and `AMBIGUOUS` are never replaced by Knowledge.
   - An unconfigured runtime source returns `NOT_FOUND` rather than a documentation value.

2. **Semantic target/purpose enforcement**
   - `target` and `purpose` are now part of catalog facts/candidates.
   - Retrieval resolution requires target/purpose evidence in the same evidence region when requested.
   - A small morphology-tolerant token bridge handles common Ukrainian inflection without fuzzy numeric selection.

3. **Numeric-role ambiguity**
   - Retrieval operates on small sentence/line regions rather than treating every number in a chunk as equivalent evidence.
   - Competing equally relevant numeric candidates remain `AMBIGUOUS`.
   - Evidence text is preserved in provenance.

4. **Assertion DSL consistency**
   - Added `operation_pass`, `less_than`, `greater_than`, and `range_check` support to the assertion compiler.
   - Planner guidance prefers `operation_pass` for deterministic operation results.

5. **OCR performance**
   - OCR now uses one Tesseract `image_to_data` pass and reconstructs readable lines from its result.
   - The page-3 OCR integration test now passes in 18.97 s instead of requiring two OCR passes.

6. **Test/packaging reliability**
   - Added `pytest.ini` with project `pythonpath` and test discovery.
   - OCR test import now uses the package namespace.
   - Production archive excludes `.env`, `__pycache__`, and `.pytest_cache`.

## Explicit non-fix / integration boundary

The production API still intentionally has no invented Home Assistant adapter. `RuntimeFactResolver(())` is empty until a deterministic telemetry provider is wired in. This is required for correctness: live values must come from a real runtime source, not from the PDF Knowledge layer.
