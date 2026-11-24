# report/final: final package (Stage 10 draft, for review)

| File | What it is |
| --- | --- |
| `SOURCE_MAP.md` | ONE file that links every headline number to its source, its file and the script that made it (values read from the files). Every parameter is in the parameter table below. |
| `key_numbers.md` | final key numbers of all stages (each section names its test or script) |
| `parameters_final.tsv` / `parameters_final.md` | the single parameter table (full 10 columns / readable summary with status and source) |
| `OPEN_ITEMS.md` | the rows that are still PLACEHOLDER or TBD |
| `ai_summary.md` | summary of the AI part (classifier, re-identification, height) with its literature |
| `assumptions.md`, `decisions.md` | why each assumption / design decision was taken |
| `figures/` | final figures with `CAPTIONS.md` (3D light and dark, overview and zoom; siting map; Pd(d) curve; Stage 9 before / after; re-identification; 2D intruder map) |
| `tables/` | the CSV / JSON files behind the numbers (cost with shelters, sites, Pd curve, d* rule, Stage 9 comparison) |

Rebuild with `python scripts/make_final_package.py`. Everything is SIMULATED unless a row says it is sourced; frozen sources and commits are in `third_party/PROVENANCE.md`.
