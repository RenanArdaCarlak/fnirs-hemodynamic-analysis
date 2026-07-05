# Data directory

This repository includes the anonymized raw fNIRS recordings used by the analysis.

The files are stored in:

```text
data/raw/
```

The subject identifiers are anonymized dataset labels:

```text
Subjects: 3, 4, 5, 6, 8
```

They do not encode participant identity. No names, demographic variables, behavioral scores, or identifiable acquisition metadata are included.

## File naming pattern

```text
Subject_<subject>_lightgraph<subject>.ref.Block<block>_DATA,<condition>.txt
```

Example:

```text
Subject_3_lightgraph3.ref.Block4_DATA,ONE.txt
```

## Experimental layout

```text
1-back: Blocks 4, 5, 6
2-back: Blocks 7, 8, 9
3-back: Blocks 10, 11, 12
```

## File format

Each recording is a tab-delimited text file with 48 numeric columns after the two header rows:

```text
48 columns = 16 measurement channels x [730 nm, ambient, 850 nm]
```

The V4 analysis checks file count, sample count, column count, channel count, non-finite values, and non-positive intensity values before processing. The corresponding manifest is stored in:

```text
results/csv/input_data_manifest.csv
```
