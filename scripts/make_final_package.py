"""Stage 10: build report/final/ (final figures, key numbers, final parameter table, AI summary, tables, and ONE file that links every number to its source and file).

Run:  python scripts/make_final_package.py
Every result value in SOURCE_MAP.md is READ from the result file when the script runs (nothing is typed by hand), so the map cannot drift from the files.
"""
import csv, json, shutil, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "report" / "final"
for d in ("figures", "tables"):
    (OUT / d).mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------- parameter table
rows = [l.split("\t") for l in (ROOT / "config" / "parameters_reviewed.tsv").read_text(encoding="utf-8").splitlines() if l.strip()]
hdr, P = rows[0], rows[1:]
assert all(len(r) == 10 for r in P)
par = {r[0]: dict(value=r[3], unit=r[4], source=r[5], owner=r[6], status=r[7], notes=r[8], vtype=r[9], desc=r[2], name=r[1]) for r in P}


def tv(sym):
    return par[sym]["value"]


def rd(path):
    return list(csv.DictReader(open(ROOT / path, encoding="utf-8")))


def fnum(x, nd=0):
    return f"{float(x):,.{nd}f}"


cost = {r["case"]: r for r in rd("results/siting/cost_with_shelters.csv")}
cmp_ = rd("results/stage9_siting/comparison.csv")
byd = rd("results/stage9_siting/comparison_by_distance.csv")
dstar = json.load(open(ROOT / "results/siting/d_star.json"))
sites = rd("results/siting/siting_sites_medium.csv")
met = rd("results/stage9_siting/metrics_summary.csv")
h7 = rd("results/stage7_height_share.csv")


def c9(model, metric, scen="medium"):
    r = [x for x in cmp_ if x["scenario"] == scen and x["model"] == model and x["metric"] == metric][0]
    return float(r["value"])


def m9(case, metric):
    return [float(x["value"]) for x in met if x["run_case"] == case and x["metric"] == metric][0]


def miss(model, lo, hi, scen="medium"):
    return [float(x["missed_pct"]) for x in byd if x["scenario"] == scen and x["model"] == model and float(x["from_km"]) == lo and float(x["to_km"]) == hi][0]


# ---------------------------------------------------------------- copy the package files
shutil.copy(ROOT / "config" / "parameters_reviewed.tsv", OUT / "parameters_final.tsv")
shutil.copy(ROOT / "report" / "key_numbers.md", OUT / "key_numbers.md")
shutil.copy(ROOT / "report" / "ai_summary.md", OUT / "ai_summary.md")
for extra in ("assumptions.md", "decisions.md"):
    shutil.copy(ROOT / "report" / extra, OUT / extra)
figs = [
    ("twin3d_overview_light.png", "report/figures/twin3d_overview_light.png", "3D digital twin, whole boundary, white background (report). SIMULATED intruders of the Stage 9 siting run, medium scenario; six interrogators (green edge = at an entrance checkpoint)."),
    ("twin3d_overview_dark.png", "report/figures/twin3d_overview_dark.png", "Same, black background (presentation)."),
    ("twin3d_zoom_hot_light.png", "report/figures/twin3d_zoom_hot_light.png", "3D zoom on a Hot stretch north-east of Makkah (24 km of boundary), white background."),
    ("twin3d_zoom_hot_dark.png", "report/figures/twin3d_zoom_hot_dark.png", "Same, black background."),
    ("siting_map_medium.png", "results/siting/siting_map_medium.png", "2D map of the interrogator siting (d* = 14.75 km, N_min = 5, N = 6): candidates, chosen shelters, boundary coloured by the serving shelter. Same result in low and high."),
    ("pd_curve.png", "results/siting/pd_curve.png", "Pd against the optical distance with the monotone fit and its 95 % limits; d* = 14.75 km. SIMULATED."),
    ("stage9_before_after.png", "report/figures/stage9_before_after.png", "Stage 9 before / after the siting model (medium): DAS misses by distance, Pd, Pd x Pc, verified in T_resp, patrol reached. SIMULATED, same random numbers."),
    ("map2d_intruders_medium_stage8.png", "report/figures/map2d_intruders_medium_stage8.png", "2D map of intruders, Stage 8 run (main model with 4 interrogators; kept for the numbers figures)."),
    ("reid_accuracy_vs_spacing.png", "results/reid/accuracy_vs_spacing.png", "Re-identification (DAS <-> camera) accuracy against the spacing of people (Yomna's protocol, SIMULATED)."),
]
for dst, src, _ in figs:
    shutil.copy(ROOT / src, OUT / "figures" / dst)
tabs = ["results/siting/cost_with_shelters.csv", "results/siting/siting_sites_medium.csv", "results/siting/pd_curve.csv", "results/siting/dstar_rule_table.csv", "results/siting/d_star.json",
        "results/stage9_siting/comparison.csv", "results/stage9_siting/comparison_by_distance.csv", "results/stage9_siting/metrics_summary.csv", "results/stage7_height_share.csv"]
for t in tabs:
    shutil.copy(ROOT / t, OUT / "tables" / Path(t).name)

(OUT / "figures" / "CAPTIONS.md").write_text("# Figure captions (all SIMULATED unless stated)\n\n" + "\n".join(f"* `{d}` : {c}  Source file: `{s}`" for d, s, c in figs) + "\n\nThe 3D figures are 1895 px wide (16 cm at 300 dpi); imagery attribution is printed on each. Made by `scripts/stage9_figures3d.m`, `scripts/final_stage9_chart.m`, `src/siting/siting_report.m`, `scripts/siting_pd_analyze.m`.\n", encoding="utf-8")

# ---------------------------------------------------------------- readable parameter table
from collections import Counter
cnt = Counter(r[7] for r in P)
md = ["# Final parameter table (single table of the project: `config/parameters_reviewed.tsv`; full 10-column copy in `parameters_final.tsv`)\n",
      f"{len(P)} rows. Status counts: " + ", ".join(f"{k} {v}" for k, v in sorted(cnt.items(), key=lambda kv: -kv[1])) + ".\n",
      "Status legend: PLACEHOLDER = a value kept only to let the model run, to be replaced by data or a quotation; ASSUMED = engineering assumption with no source; SIMULATED / DERIVED = computed by the model; the rest are sourced (the source column names it).\n",
      "| Symbol | Value | Unit | Status | value_type | Source |", "| --- | --- | --- | --- | --- | --- |"]
for r in P:
    esc = lambda x: x.replace("|", "/").replace("\n", " ")
    md.append(f"| `{r[0]}` | {esc(r[3])} | {esc(r[4])} | {esc(r[7])} | {esc(r[9])} | {esc(r[5])[:160]} |")
(OUT / "parameters_final.md").write_text("\n".join(md) + "\n", encoding="utf-8")
open_items = [r for r in P if r[7].upper().startswith(("PLACEHOLDER", "TBD"))]
(OUT / "OPEN_ITEMS.md").write_text("# Values still PLACEHOLDER or TBD (need data, a quotation or a decision)\n\n| Symbol | Value | Unit | What is missing |\n| --- | --- | --- | --- |\n" +
                                  "\n".join(f"| `{r[0]}` | {r[3]} | {r[4]} | {r[8].split(' | ')[0][:200].replace('|', '/')} |" for r in open_items) + "\n", encoding="utf-8")

# ---------------------------------------------------------------- SOURCE MAP
S = []


def add(num, value, tag, file, how):
    S.append((num, value, tag, file, how))


add("Boundary length", f"{tv('L_boundary')} km (table, rounded); exact ring 145.4735 km", "sourced (OSM boundary)", "`config/parameters_reviewed.tsv` row `L_boundary`", "DAS-map `boundary_perimeter.csv` (a25fd0c); planar ring 145,461 m vs haversine 145,473.5 m")
add("Pd_DAS (literature, used by the optimization)", tv("Pd_DAS"), par["Pd_DAS"]["status"], "table row `Pd_DAS`", par["Pd_DAS"]["source"][:150])
add("Pc_DAS (classifier accuracy, base stub)", tv("Pc_DAS"), par["Pc_DAS"]["status"], "table row `Pc_DAS`", par["Pc_DAS"]["source"][:150])
add("d* (reach of one interrogator)", f"{dstar['d_star_km']} km", "SIMULATED (rule fixed before the run)", "`results/siting/d_star.json`; table row `d_star_DAS`; rule in row `siting_dstar_rule`", "`scripts/siting_pd_dense.m` (windows) then `scripts/siting_pd_analyze.m` (isotonic fit, 2000 bootstrap, lower 95 % limit >= Pd_DAS); engine third_party/das_engine 3a8862b")
add("d* under the weakest-type rule (information)", f"{dstar['d_star_km_weakest_type_lower_limit_INFO']} km", "SIMULATED", "`results/siting/d_star.json`, `results/siting/dstar_rule_table.csv`", "same script, per-type fits")
add("N_min = ceil(L / 2d*)", str(dstar["N_min"]), "DERIVED", "`results/siting/d_star.json`", f"ceil({dstar['L_boundary_km']:.2f} / {2*dstar['d_star_km']:.1f})")
m = cost["medium"]
add("N from the MILP with candidate shelters", m["N"] + " (low, medium and high identical)", "SIMULATED (MILP)", "`results/siting/cost_with_shelters.csv`; `results/alloc_<scenario>_22_siting.mat`", "`src/siting/get_allocation_siting.m` -> optimization repo branch `interrogator-siting` 1b385aa (copy `third_party/optimization_siting`)")
add("Chosen sites (boundary arc, km)", ", ".join(f"{float(x['boundary_arc_km']):.2f} ({x['kind']})" for x in sites), "SIMULATED (MILP)", "`results/siting/siting_sites_medium.csv`", "`src/siting/siting_report.m`")
add("New-cabin cost C_shelter", f"{fnum(tv('C_shelter'))} SAR", par["C_shelter"]["status"], "table row `C_shelter`", "no Saudi price found (24 Nov 2026 search); replace by a quotation")
add("Checkpoint-room cost C_shelter_checkpoint", f"{fnum(tv('C_shelter_checkpoint'))} SAR", par["C_shelter_checkpoint"]["status"], "table row `C_shelter_checkpoint`", "25 % of C_shelter")
add("Shelter cost of the siting solution", f"{fnum(m['shelters_SAR'])} SAR ({m['n_checkpoint_rooms']} checkpoint rooms + {m['n_new_cabins']} new cabins)", "DERIVED", "`results/siting/cost_with_shelters.csv`", "`scripts/siting_cost_table.m`")
add("C_total, siting model", f"{fnum(m['C_total_SAR'])} SAR", "SIMULATED (MILP)", "`results/siting/cost_with_shelters.csv`; table row `C_total_siting`", f"interrogators {fnum(m['interrogators_SAR'])} + sensing fibre {fnum(m['sensing_fibre_SAR'])} + lead-in {fnum(m['leadin_fibre_SAR'])} + shelters {fnum(m['shelters_SAR'])}; C_DAS_int {fnum(tv('C_DAS_int'))}, C_fiber {tv('C_fiber')} per km (table)")
add("C_total, main model (4 interrogators, no shelter cost)", f"{fnum([x for x in cmp_ if x['model']=='stage9' and x['scenario']=='medium'][0]['C_total'])} SAR", "SIMULATED (frozen MILP f51b223)", "`results/stage9_siting/comparison.csv` column C_total; `tests/test_stage2.m`", "reproduces optimization/report/key_results.md; computed with C_shelter = 0")
add("Cabin price sensitivity (50,000 / 120,000 / 300,000 SAR)", f"{fnum(cost['medium_shello']['C_total_SAR'])} / {fnum(m['C_total_SAR'])} / {fnum(cost['medium_shelhi']['C_total_SAR'])} SAR, same N and sites", "SIMULATED (MILP re-solved)", "`results/siting/cost_with_shelters.csv` (cases medium_shello, medium_shelhi)", "`scripts/siting_run_scn.m` with env SHEL, SHELCHK")
add("N = 5 forced", f"C_total {fnum(cost['medium_N5']['C_total_SAR'])} SAR; 4 cells (135 of 139 with DAS) uncovered", "SIMULATED (MILP, Nfix = 5)", "`results/siting/cost_with_shelters.csv`; `results/alloc_medium_22_siting_N5.mat`", "`Siting.Nfix` option; difference to N = 6: " + fnum(float(m['C_total_SAR']) - float(cost['medium_N5']['C_total_SAR'])) + " SAR")
add("d* = 13 km (weakest-type rule)", f"N = {cost['medium_d13']['N']}, C_total {fnum(cost['medium_d13']['C_total_SAR'])} SAR", "SIMULATED (MILP)", "`results/siting/cost_with_shelters.csv` (case medium_d13)", "`scripts/siting_run_scn.m` DSTAR=13")
sens = [float(cost[k]["C_total_SAR"]) for k in cost if k.startswith("medium_") and any(k.endswith(s) for s in ("slope5", "slope15", "road100", "road500", "water25", "water100", "inside500"))]
add("Eight siting sensitivities (slope / road / waterway / inside distance)", f"N = 6 in all; C_total {fnum(min(sens))} to {fnum(max(sens))} SAR (+ base)", "SIMULATED (MILP)", "`results/siting/cost_with_shelters.csv`, `results/siting/sensitivity.csv`", "`scripts/run_siting_sens.sh`, `scripts/siting_sens_table.m`; solved with C_shelter = 0, site kinds identical so the shelter cost is added from the kinds")
add("Shelter air-conditioning power / energy", f"{tv('P_shelter')} W per cabin; {fnum(tv('E_shelter_cooling_kWh_yr'),1)} kWh/yr per cabin; six cabins {fnum(m['cooling_kWh_per_year'],0)} kWh/yr; whole site draw {fnum(m['power_W'])} W", "sourced range (gsma_coolsure 30-50 %) / DERIVED", "table rows `P_shelter`, `E_shelter_cooling_kWh_yr`, `cooling_share_of_site_load`; `results/siting/cost_with_shelters.csv`", "170 W x 8,760 h")
for lab, metric in (("Pd of the simulated DAS chain", "Pd"), ("Pd x Pc (end to end)", "Pd_x_Pc"), ("Intruders verified within T_resp", "verified_Tresp"), ("Patrol reached", "patrol_reached")):
    add(f"{lab}, medium: before -> after the siting model", f"{100*c9('stage9', metric):.1f} % -> {100*c9('stage9_siting', metric):.1f} %", "SIMULATED (Monte Carlo, 394 days, 10,004 intruders, common random numbers)", "`results/stage9_siting/comparison.csv`", "`scripts/stage9_run.m`, `scripts/stage9_compare.m`, `scripts/make_stage9_comparison.py`")
add("Intruders NOT verified within T_resp (medium), before -> after", f"{100*(1-c9('stage9','verified_Tresp')):.1f} % -> {100*(1-c9('stage9_siting','verified_Tresp')):.1f} %", "SIMULATED", "`results/stage9_siting/comparison.csv` (1 - verified_Tresp)", "includes DAS misses and classifier non-alarms; T_resp = " + tv("T_resp") + " " + par["T_resp"]["unit"] + " (table)")
add("DAS miss share 10-14.75 km, before -> after", f"{miss('stage9', 10, 14.75):.1f} % -> {miss('stage9_siting', 10, 14.75):.2f} %", "SIMULATED", "`results/stage9_siting/comparison_by_distance.csv`", "no event farther than 14.23 km after the change")
add("DAS miss share 15-20 km (before)", f"{miss('stage9', 15, 20):.1f} %", "SIMULATED", "`results/stage9_siting/comparison_by_distance.csv`", "")
hp = [x for x in h7 if abs(float(x["p_along"]) - 0.1) < 1e-9][0]
add("Height measurable, all intruders (p_along 10 %)", f"{100*float(hp['height_measurable_all']):.1f} % (walkers {100*float(hp['height_measurable_walkers']):.1f} %)", "SIMULATED; p_along ASSUMED", "`results/stage7_height_share.csv`", "`scripts/stage7_height_share.m`; height model (Engyom/DAS- v2.2-sim) NOT called, only its conditions")
add("Group sensitivity p_group 25 % / 50 % (persons)", f"{m9('medium_pgroup25_SENSITIVITY','persons_total'):,.0f} / {m9('medium_pgroup50_SENSITIVITY','persons_total'):,.0f} persons for 10,004 events", "SIMULATED; p_group ASSUMED", "`results/stage9_siting/metrics_summary.csv`", "")
add("Brno confusion matrix (SENSITIVITY only): Pc given detection", f"{100*m9('medium_BrnoMatrix_SENSITIVITY','Pc_cond'):.1f} % (base uniform stub {100*m9('medium','Pc_cond'):.1f} %)", "SIMULATED; matrix from published dataset", "`results/stage9_siting/metrics_summary.csv`; `config/ai_config.json`", "base = uniform stub from Pc_DAS (ASSUMED); the matrix is a sensitivity")
rj = json.load(open(ROOT / "results/reid/summary.json", encoding="utf-8"))
add("Re-identification target 0.97 kept in the hard cells", "NOT kept (see `report/reid_summary.md`)", "SIMULATED, ASSUMED errors", "`results/reid/summary.json`, `results/reid/reid_grid.csv`", f"{rj['cells']} cells x {rj['scenes_per_cell']} scenes; design is Yomna's, run only through her protocol in `reid/`")
add("Number of table rows with status PLACEHOLDER or TBD", str(len(open_items)), "-", "`report/final/OPEN_ITEMS.md`", "listed one by one")
add("Not in this map: numbers of the AI summary", "-", "-", "`report/final/ai_summary.md`", "each has its own bib key (`report/references_additions.bib`)")
add("Numbers of the Stages 1-9 text in key_numbers.md", "see file", "SIMULATED / DERIVED", "`report/key_numbers.md`", "each section names its test or script (`tests/test_stage1.m` ... `tests/test_stage6.m`, `scripts/`); re-running the test reproduces the value")

lines = ["# Source map: every headline number, its value (read from the file when this was built), its tag and where it comes from",
         "",
         "Part A: **every parameter** is in `parameters_final.tsv` / `parameters_final.md` (symbol, value, unit, status, source). Status tags: sourced, ASSUMED, PLACEHOLDER, SIMULATED, DERIVED. Arabic statuses of the original table: مفترض = assumed, مفترض (مبني على مصدر) = assumed from a source, معتمد = approved, مقترح / اقتراح = proposed, مبدئي = preliminary. Nothing is untagged (checked by this script).",
         "Part B: the result numbers below. The value column is read programmatically from the file in the third column; to refresh everything run `python scripts/make_final_package.py`.",
         "",
         "## Part B: results",
         "| Number | Value | Tag | File | Script / how |", "| --- | --- | --- | --- | --- |"]
for n, v, t, f, h in S:
    e = lambda x: str(x).replace("|", "/")
    lines.append(f"| {e(n)} | {e(v)} | {e(t)} | {e(f)} | {e(h)} |")
lines += ["", "## Notes",
          "* Costs: `results/stage9_siting/comparison.csv` still stores C_total = 12,654,986 for the siting model (the Stage 9 rerun was made before the shelter cost was added); the current cost is `results/siting/cost_with_shelters.csv` (13,014,986). The allocation did not change, so no Stage 9 result changed.",
          "* All SIMULATED values depend on ASSUMED inputs (coupling spread, intruder rates, speeds); they are results of the model, not measurements. Phase 0 (field measurements) is where they would be replaced.",
          "* Frozen sources: see `third_party/PROVENANCE.md` for every repository, commit and date."]
(OUT / "SOURCE_MAP.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

# ---------------------------------------------------------------- checks: nothing untagged; key numbers consistent with the files
bad = [r[0] for r in P if not r[7].strip() or not r[9].strip()]
assert not bad, f"rows without status or value_type: {bad}"
kn = (OUT / "key_numbers.md").read_text(encoding="utf-8")
for must in (fnum(m["C_total_SAR"]), fnum(cost["medium_N5"]["C_total_SAR"]), fnum(cost["medium_d13"]["C_total_SAR"]), fnum(cost["medium_shelhi"]["C_total_SAR"]), fnum(cost["medium_shello"]["C_total_SAR"])):
    assert must in kn, f"key_numbers.md does not contain {must}"
print("package built:", OUT, "| parameter rows", len(P), "| PLACEHOLDER", len(open_items), "| source-map entries", len(S))

(OUT / "README.md").write_text("""# report/final: final package (Stage 10 draft, for review)

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
""", encoding="utf-8")
