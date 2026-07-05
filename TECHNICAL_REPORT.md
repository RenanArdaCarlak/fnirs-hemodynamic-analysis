# Technical Report: Multi-Channel fNIRS Hemodynamic Analysis in MATLAB

## 1. Objective

This project implements a reproducible MATLAB workflow for processing multi-channel fNIRS optical-intensity recordings collected during an n-back working-memory task.

The technical objective is to convert raw 730 nm and 850 nm intensity measurements into scaled hemoglobin-response estimates, evaluate signal quality, attenuate candidate motion artifacts, and perform exploratory within-subject comparisons across 1-back, 2-back, and 3-back conditions.

The analysis is not framed as a validated neuroimaging study. Its primary value is the engineering workflow: data ingestion, preprocessing, model-based transformation, quality control, sensitivity analysis, and transparent statistical reporting.

## 2. Dataset structure

The dataset contains five participants:

```text
Subjects: 3, 4, 5, 6, 8
```

Each participant has nine recordings:

```text
1-back: Blocks 4, 5, 6
2-back: Blocks 7, 8, 9
3-back: Blocks 10, 11, 12
```

Across the full dataset:

| Quantity | Value |
|---|---:|
| Participants | 5 |
| Conditions | 3 |
| Blocks per condition | 3 |
| Total recordings | 45 |
| Measurement channels | 16 |
| Columns per recording | 48 |
| Sample counts per recording | 128 or 129 |
| Sampling frequency | 2 Hz |

Each channel contains three columns:

```text
730 nm intensity, ambient intensity, 850 nm intensity
```

The anonymized raw recordings are included in `data/raw/`. Subject numbers are dataset labels only; they do not identify participants. No personal identifiers, demographic metadata, behavioral scores, or acquisition records that identify individuals are included.

The enhanced script performs an input manifest check before the analysis. All 45 recordings had 48 columns and 16 measurement channels in the V4 output.

## 3. Legacy code preservation

The original MATLAB implementation is preserved under:

```text
legacy/RenanArdaCarlak_fNIRS_original.m
```

The enhanced implementation is stored under:

```text
src/RenanArdaCarlak_fNIRS_Enhanced_v4.m
```

The script resolves input files from the working directory, the script directory, `data/`, or `data/raw/`, so the repository can be run with the included anonymized raw data without copying files into the MATLAB working directory.

The enhanced implementation retains the original subject/block/condition structure and dynamic field organization, while adding additional quality-control, preprocessing, sensitivity-analysis, and statistical layers.

The legacy workflow included:

- dynamic file loading,
- raw signal plotting,
- FFT inspection,
- Butterworth low-pass filtering,
- moving coefficient-of-variation motion diagnostics,
- MBLL-based HbO/HbR estimation,
- condition-level averaging,
- group bar plots.

The enhanced workflow does not remove the original computational intent. It adds additional checks and makes the conclusions more conservative.

## 4. Enhanced processing pipeline

The V4 pipeline is:

```text
raw intensity
-> input validation
-> optical-density conversion
-> TDDR-style temporal-derivative artifact attenuation
-> 0.20 Hz zero-phase low-pass filtering
-> baseline re-centering
-> MBLL-based scaled HbO/HbR estimation
-> block-level summaries
-> participant-level summaries
-> group-level summaries
-> sensitivity and influence analyses
```

## 5. Input validation and quality control

The script checks:

- number of available files,
- number of columns per file,
- number of optodes/channels,
- non-finite values,
- non-positive intensity values,
- baseline coefficient of variation,
- ambient-to-signal ratio,
- ambient-signal correlations,
- fraction of samples exceeding the legacy CV motion threshold.

In the V4 output:

- all 720 channel-block combinations were mathematically valid,
- no non-finite samples were detected,
- no non-positive intensity samples were detected,
- motion-candidate fractions were sparse and concentrated in specific subject/channel cases.

The motion-diagnostic heatmap showed elevated candidate fractions in the previously selected representative examples, especially Subject 4 Block 10 Optode 14 and Subject 3 Block 8 Optode 14.

## 6. Optical-density conversion

For each wavelength, optical-density change was computed relative to a baseline segment:

```text
ΔODλ(t) = log10( Iλ,baseline / Iλ(t) )
```

where \(I_{\lambda,baseline}\) is the mean intensity over the baseline frames.

The enhanced version uses a common post-baseline analysis window of 118 samples, corresponding to 59 seconds at 2 Hz. This avoids mixing 118-sample and 119-sample post-baseline windows in summary metrics.

## 7. Motion-artifact attenuation

The original code used a moving coefficient of variation as a motion-artifact indicator. This diagnostic was retained.

The enhanced code additionally applies TDDR-style temporal-derivative artifact attenuation to optical-density signals. The correction is applied before low-pass filtering and before MBLL conversion.

The representative artifact figure shows:

1. raw 730 nm and 850 nm intensity,
2. optical density before TDDR,
3. optical density after TDDR,
4. legacy moving coefficient of variation.

The method is interpreted as artifact attenuation, not ground-truth validated motion correction, because no independent motion recording is available.

## 8. Filtering and filter-sensitivity analysis

The legacy analysis used a 0.05 Hz low-pass filter. V4 uses 0.20 Hz low-pass as the primary configuration.

The tested processing configurations were:

- TDDR only,
- TDDR + 0.05 Hz low-pass,
- TDDR + 0.10 Hz low-pass,
- TDDR + 0.20 Hz low-pass.

A synthetic hemodynamic-like waveform preservation test was used to evaluate low-pass distortion.

| Configuration | Correlation | Peak retention | RMSE |
|---|---:|---:|---:|
| TDDR only | 1.000000 | 1.000000 | 0.000000 |
| TDDR + 0.05 Hz | 0.990541 | 1.078260 | 0.824600 |
| TDDR + 0.10 Hz | 0.999567 | 1.037788 | 0.172369 |
| TDDR + 0.20 Hz | 0.999998 | 1.004565 | 0.012987 |

The 0.20 Hz low-pass configuration produced the smallest waveform distortion among the tested low-pass settings and was selected as the primary engineering configuration.

## 9. Baseline re-centering after preprocessing

After TDDR and low-pass filtering, optical-density signals are re-centered over the baseline window before MBLL conversion.

This step prevents filter-induced DC offsets from propagating into mean HbO, AUC, peak, and condition-difference metrics.

## 10. MBLL-based scaled HbO/HbR estimation

The code preserves the legacy MBLL parameter convention:

| Parameter | Value | Status |
|---|---:|---|
| E_HbR_730nm | 1.10220 | source/unit confirmation required |
| E_HbR_850nm | 0.69132 | source/unit confirmation required |
| E_HbO_730nm | 0.39000 | source/unit confirmation required |
| E_HbO_850nm | 1.05800 | source/unit confirmation required |
| Source-detector distance | 2.5 cm | source confirmation required |
| DPF | 0.015 | source/unit confirmation required |

The enhanced implementation uses matrix division rather than explicitly computing a matrix inverse:

```matlab
DeltaConcentration = constants \ DeltaOpticalDensity;
```

Because the parameter sources and unit chain are not fully documented, results are reported as:

```text
scaled HbO/HbR under the legacy MBLL parameter convention
```

Absolute concentration units are not claimed.

## 11. Summary metrics

The enhanced analysis computes:

- mean HbO across the common analysis window,
- median HbO across blocks,
- HbO area under the curve,
- maximum HbO,
- robust 95th-percentile HbO peak,
- channel-level and global channel-average values.

The global channel-average HbO response is used as the main exploratory summary. This is not interpreted as anatomical localization because channel coordinates are not available.

## 12. Statistical analysis

The primary contrast is:

```text
ΔHbO(3-back) − ΔHbO(1-back)
```

at the participant level, using global channel-average HbO.

The main statistical analyses are:

- exact paired sign-flip permutation test for 3-back minus 1-back,
- Cohen's \(d_z\) for paired differences,
- bootstrap confidence interval for the mean paired difference,
- exact repeated-measures omnibus permutation across 1-back, 2-back, and 3-back,
- exploratory channel-wise tests with FDR correction,
- leave-one-participant-out influence analysis,
- mean-vs-median block aggregation sensitivity.

With five participants, exact paired sign-flip testing has limited p-value resolution. The minimum attainable two-sided p-value is 0.0625.

## 13. Main group-level results

The primary V4 global result is:

| Metric | Value |
|---|---:|
| Mean 3-back minus 1-back | 0.019881 |
| Cohen's dz | 0.193862 |
| 95% CI lower | -0.049124 |
| 95% CI upper | 0.107927 |
| Exact paired sign-flip p | 0.812500 |
| Repeated-measures omnibus p | 0.451389 |
| Valid subject count | 5 |

Condition-level group summaries were:

| Condition | Mean HbO | SEM HbO | Median HbO |
|---|---:|---:|---:|
| 1-back | -0.003765 | 0.006965 | -0.008146 |
| 2-back | -0.049492 | 0.020859 | -0.052101 |
| 3-back | 0.016116 | 0.045554 | -0.019432 |

The exploratory analysis therefore does not support a statistically reliable global HbO increase from 1-back to 3-back.

## 14. Channel-level exploratory results

All 16 channels were tested exploratorily for the 3-back minus 1-back contrast and repeated-measures omnibus effect.

No channel survived FDR correction:

```text
FDR-significant paired channels: 0 / 16
FDR-significant omnibus channels: 0 / 16
```

The largest positive channel-level mean differences were observed at channels 2 and 12, but these effects were not statistically reliable after correction.

## 15. Participant influence

The full-sample mean 3-back minus 1-back difference was:

```text
+0.019881
```

Leave-one-participant-out analysis showed that the direction changed when Subject 8 was omitted:

| Analysis set | Mean 3-back minus 1-back | Direction |
|---|---:|---|
| Full sample | 0.019881 | positive |
| Leave out Subject 3 | 0.045910 | positive |
| Leave out Subject 4 | 0.015984 | positive |
| Leave out Subject 5 | 0.027339 | positive |
| Leave out Subject 6 | 0.031949 | positive |
| Leave out Subject 8 | -0.021776 | negative |

This indicates that the apparent positive global trend is sensitive to Subject 8 and should not be interpreted as a robust group effect.

## 16. Block-level consistency

The block-level analysis revealed substantial within-participant variability.

Mean and median aggregation across the three repeated blocks led to the same paired sign-flip p-value for the primary contrast:

| Aggregation | Mean difference 3-back minus 1-back | Cohen's dz | p-value |
|---|---:|---:|---:|
| Mean across blocks | 0.019881 | 0.193862 | 0.8125 |
| Median across blocks | 0.027561 | 0.239947 | 0.8125 |

Thus, the conclusion is not simply caused by using arithmetic means rather than medians across repeated blocks.

## 17. Legacy vs enhanced result

The legacy and enhanced global HbO outputs differed substantially in several subject-condition pairs.

This is expected because the enhanced workflow differs from the original in several important ways:

- optical-density domain artifact attenuation,
- baseline re-centering after preprocessing,
- common analysis window,
- less aggressive low-pass cutoff,
- additional block-level consistency checks.

The enhanced pipeline does not preserve the original stronger-looking 3-back trend. The final interpretation is therefore more conservative.

## 18. Interpretation

The initial expectation for n-back tasks is that higher working-memory load may increase prefrontal hemodynamic response. However, this specific dataset and enhanced analysis do not provide reliable support for a monotonic global HbO increase.

The main reasons are:

- small sample size,
- high participant-level variability,
- high block-level variability in some subjects,
- strong influence of Subject 8 on the group-level 3-back mean,
- absence of FDR-significant channel-level effects.

The final conclusion is:

```text
This dataset does not show a statistically reliable global HbO increase from 1-back to 3-back under the enhanced processing pipeline. The analysis is best interpreted as an exploratory fNIRS signal-processing case study rather than as evidence for a robust neurophysiological workload effect.
```

## 19. Limitations

The main limitations are:

1. The sample size is only five participants.
2. No short-separation channels are available for systemic physiology regression.
3. No anatomical channel coordinates are available.
4. No accelerometer or independent motion ground truth is available.
5. Behavioral performance data are not included.
6. MBLL parameter sources and unit consistency remain to be documented.
7. Absolute HbO/HbR concentration units are not claimed.
8. The analysis is exploratory and should not be treated as a validated fNIRS inference pipeline.

## 20. Engineering value

Despite the scientific limitations, the project demonstrates several relevant engineering capabilities:

- structured multi-file data ingestion,
- multi-channel signal preprocessing,
- optical-density conversion,
- artifact detection and attenuation,
- model-based transformation using MBLL,
- reproducible generation of CSV and figure outputs,
- sensitivity analysis,
- participant influence analysis,
- transparent reporting of non-significant results.

These elements make the project suitable as a portfolio case study in scientific computing, biomedical signal processing, MATLAB-based data analysis, and reproducible research engineering.
