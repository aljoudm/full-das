# Classifier results (Brno; FEBUS not yet tested)
`T1s/` = window 1 s (base, ASSUMED), `T2s/` = window 2 s (sensitivity). Files: metrics.json, confusion_matrix.csv (event-level COUNTS of the locked test, 4 test recordings), reliability.png, model_card.md, split_counts.json.
**The confusion matrix is a SENSITIVITY input only, labelled "Brno, 4 test recordings, SENSITIVITY"**: the base of the unified simulation is the uniform stub (Pc from the literature). Classes missing from the matrix (running, digging, tampering, background, animal) fall back to that stub.
