# PTN Licensing Boundary

## Objective

Separate open-core repository usage from proprietary PTN legacy assets.

## License split

1. Open-core code, workflows, and public examples:
- `LICENSE` (MIT)

2. Proprietary PTN legacy assets and premium policy packs:
- `LICENSE-PTN` (all rights reserved unless approved in writing)

## Public repository rule

1. Keep `ptn/legacy/private` free of real proprietary `.ptn` assets.
2. Store only stubs/placeholder metadata in public.
3. Use private repositories, private package registries, or dedicated secure storage for real proprietary PTN legacy modules.

## CI enforcement

1. `tools/check_proprietary_ptn_boundary.py`
2. Included in:
- `.github/workflows/quality.yml`
- `scripts/run_local_quality_gate.ps1`
