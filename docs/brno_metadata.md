# Brno DAS dataset: metadata (every [Check in data] item of the evaluation protocol)

Filled by Claude Code on 22-23 Nov 2026 from the dataset files themselves. Every line gives its source. Items not found are marked **NOT FOUND**. Protocol: `docs/Classifier_Evaluation_Protocol.pdf` (Yomna).

## 1. Dataset and licence

| Item | Value | Source |
| --- | --- | --- |
| Title / authors | Comprehensive Dataset for Event Classification Using Distributed Acoustic Sensing (DAS) Systems; Tomasov, Zaviska, Dejdar, Klicnik, Horvath, Munster | figshare record 27004732 (API `api.figshare.com/v2/articles/27004732`), paper https://doi.org/10.1038/s41597-025-05088-4 |
| Licence | CC BY | figshare API field `license` |
| Archive | `DAS-dataset.zip`, 47,120,418,495 bytes, MD5 77e990a08907c2a4b16997e95f31b55e | figshare API (computed_md5 = supplied_md5) |
| Content | 9 label folders, 16 recordings (`*.h5` raw data + `*.npy` bitmap + `*.json` annotated curves), and a `python/` loader (GPL-3.0, not used) | zip listing (`ai/zip_remote.py list`) |
| Setting | Buried single-mode fibre on a university campus, labelled and unlabelled measurements | figshare description |

## 2. Interrogator, stored quantity, sampling (protocol sections 1 and 5)

| Item | Value | Source |
| --- | --- | --- |
| Interrogator | OptaSense (dataset description: ODH-F); file vendor code `OptaSense IU Setup 1.8.6 c9c23ad2...` | figshare description; HDF5 attribute `Acquisition/VendorCode` |
| **Stored quantity** | **RAW data, int16, dimensions (time, locus)**. NOT stored as PSD: the dataset text says events are identified by PSD representations, but the files hold raw samples; the PSD (log10 of the FFT magnitude) is computed by the dataset's own loader. The team report that Brno is stored as PSD is therefore not correct for the files. | HDF5 dataset `Acquisition/Raw[0]/RawData` (dtype int16, dims attribute [time, locus]); `python/README.md` |
| Units | **NOT FOUND**: no unit attribute on RawData (raw interrogator counts, `RawDescription` = 'Single Pulse, SR: 1.5, OCP: 1'). Strain / strain-rate conversion is not given. Amplitude must be normalised per recording. | HDF5 attributes |
| Sampling rate (time) | 20,000 Hz (`OutputDataRate`, `PulseRate`); `MaximumFrequency` 10,000 Hz | HDF5 attributes |
| Pulse width | 20 ns, so the optical resolution is about c x tau / (2 n) = 2 m (our calculation, n = 1.468) | HDF5 `PulseWidth`; derived |
| Channel spacing | 1.0209523 m (`SpatialSamplingInterval`) | HDF5 attribute |
| Number of channels | 1,700 (April and November recordings), 1,663 (the three June recordings: bitmap shape 585 x 1663 / 506 x 1663) | HDF5 `NumberOfLoci`, json `shape` |
| **Gauge length** | **NOT FOUND** in any file attribute. To be taken from the paper (to check) | HDF5 attributes (searched) |
| Recording length | 21 to 104 s per recording (downloaded ones); one bitmap row = about 0.1 s (2,056 samples) | HDF5 length / bitmap rows |
| Our harmonisation | one channel, resampled 20 kHz -> 510 Hz (`fs_win_hz`), 1 or 2 s windows, see `ai/clf_common.py` | design |

## 3. Labels, events and how recordings group (protocol section 2)

* **Label list (9 folders):** car, construction, fence, longboard, manipulation, openclose, regular, running, walk. Mapping to system classes: `config/class_map.yaml`.
* **Event** = one annotated curve in the recording's json (x = channel, y = bitmap row; verified: 100 % of the sampled points of the fence recording fall on marked cells). The bitmap marks the cells of each curve.
* **Grouping available:** the recording file (name with timestamp). Date from the file name: 12 recordings on 2023-04-17, 3 on 2023-06-06 (car x2, construction), 2 on 2023-11-07 (fence plot, kopani_plot). **Location along the cable is NOT given**: only the marked channel range per recording (below); whether recordings share the same fibre section is not stated. **No person / vehicle identifiers** are given, so events of one session may share people or cars.
* **Consequence:** the group unit is the recording file; day-level grouping is not possible (most recordings are from one day); cable-zone grouping is not possible.

## 4. Recordings (role from `config/splits.json`, written once with seed 20261122)

| Class | Recording | Date | Annotated events | Windows 1 s / 2 s | Marked channels | Role |
| --- | --- | --- | --- | --- | --- | --- |
| background | regularshit_2023-04-17T130103+0100 | 2023-04-17 | 4 | 42193 / 21150 | 125-1510 | dev fold 0 |
| climbing | fence_2023-04-17T123117+0100 | 2023-04-17 | 12 | 98 / 5 | 40-173 | LOCKED TEST |
| climbing | kopani_plot_2023-11-07T150207Z | 2023-11-07 | 1 | 5354 / 2691 | 130-262 | dev fold 2 |
| climbing | plot_2023-11-07T150119Z | 2023-11-07 | 1 | 3261 / 1637 | 132-197 | dev fold 1 |
| digging | reconstruction1_2023-06-06T150714+0100 | 2023-06-06 | 2 | 10993 / 5496 | 233-1368 | dev fold 3 |
| other | longboard_2023-04-17T123543+0100 | 2023-04-17 | 3 | 1991 / 990 | 116-367 | LOCKED TEST |
| other | longboardroad_2023-04-17T123638+0100 | 2023-04-17 | 9 | 1142 / 569 | 117-346 | dev fold 4 |
| other | openingclosing_2023-04-17T122658+0100 | 2023-04-17 | 18 | 1537 / 279 | 137-228 | dev fold 0 |
| running | running_2023-04-17T122413+0100 | 2023-04-17 | 10 | 2824 / 1403 | 115-310 | dev fold 1 |
| tampering | manipulation_2023-04-17T122847+0100 | 2023-04-17 | 23 | 3701 / 1712 | 138-221 | dev fold 2 |
| vehicle | auto2_2023-04-17T124510+0100 | 2023-04-17 | 5 | 574 / 278 | 121-364 | dev fold 0 |
| vehicle | auto4_2023-06-06T144655+0100 | 2023-06-06 | 2 | 1601 / 792 | 197-1439 | LOCKED TEST |
| vehicle | auto4_2023-06-06T145055+0100 | 2023-06-06 | 6 | 7751 / 3857 | 219-1431 | dev fold 4 |
| vehicle | auto_2023-04-17T124152+0100 | 2023-04-17 | 5 | 2008 / 999 | 210-379 | dev fold 3 |
| walking | walking2_2023-04-17T122153+0100 | 2023-04-17 | 6 | 2987 / 1493 | 121-289 | dev fold 1 |
| walking | walking_2023-04-17T121933+0100 | 2023-04-17 | 5 | 908 / 450 | 123-275 | LOCKED TEST |

Window = one channel, T_clf_s long, marked in at least 50 % of the bitmap rows it covers, step half a window (`ai/brno_events.py`). Windows of one event overlap heavily and are NOT independent.

## 5. Per class: recordings, events, windows (1 s and 2 s)

| Class | Recordings | Days | Annotated events | Events with a 1 s window | Windows 1 s | Events with a 2 s window | Windows 2 s | Evaluable on Brno |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| background | 1 | 1 | 4 | 4 | 42193 | 4 | 21150 | **no (1 recording)** |
| climbing | 3 | 2 | 14 | 9 | 8713 | 3 | 4333 | yes |
| digging | 1 | 1 | 2 | 2 | 10993 | 2 | 5496 | **no (1 recording)** |
| other | 3 | 1 | 30 | 21 | 4670 | 14 | 1838 | yes |
| running | 1 | 1 | 10 | 8 | 2824 | 8 | 1403 | **no (1 recording)** |
| tampering | 1 | 1 | 23 | 14 | 3701 | 13 | 1712 | **no (1 recording)** |
| vehicle | 4 | 2 | 18 | 17 | 11934 | 17 | 5926 | yes |
| walking | 2 | 1 | 11 | 10 | 3895 | 10 | 1943 | yes |
| animal | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **no (absent: needs FEBUS data)** |

**Reading:** a claim such as AC0 = 98 % needs at least 149 error-free independent events per class (protocol section 4); the largest class has 21 events. Brno cannot support such a claim for any class.

