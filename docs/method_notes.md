# Method Notes

## Primary configuration

The final repository uses:

```text
TDDR-style attenuation + 0.20 Hz low-pass filtering
```

This was selected because the synthetic waveform preservation test showed substantially lower distortion than the 0.05 Hz and 0.10 Hz alternatives.

## Interpretation rule

The analysis should not be summarized as "3-back produced higher activation." The correct interpretation is:

```text
The enhanced exploratory analysis did not show a statistically reliable global HbO increase from 1-back to 3-back.
```

## Raw data policy

The repository includes the anonymized raw recordings under `data/raw/`. The numeric subject identifiers are dataset labels only and do not identify participants. No personal identifiers, demographic variables, behavioral scores, or identifiable acquisition metadata are included.

Keep this limitation explicit: anonymization reduces privacy risk, but the repository should still avoid adding any external metadata that could re-identify participants.
