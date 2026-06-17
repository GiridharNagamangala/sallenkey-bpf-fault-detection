# Analog ML Family Classifier

This folder contains analog filter family-classification experiments.

## Version Summary

### V7: Maheshwari Component-Derived Baseline
Uses component-derived equations from Maheshwari & Anand, Analog Electronics, Active Filters chapter.  
VCVS and MFB filter equations are used to generate output-voltage response features.

### V8: Output-Only Diagnostic Dataset
Balanced dataset across four families and four response types:
- PASSIVE
- VCVS
- MFB
- ACTIVE_OTHER

Response types:
- LPF
- HPF
- BPF
- BSF

V8 uses only output magnitude/phase response. Accuracy drops, showing that output response alone is insufficient for reliable topology-family classification.

### V9: Current/Impedance Feature Prototype
Adds current/impedance-signature features to output-response features.  
Classification accuracy improves strongly, showing that circuit-level current information is important for topology-family classification.

Important limitation: V9 current features are MATLAB prototype signatures, not Cadence/Virtuoso-measured currents yet. The next validation step is to replace them with Cadence AC simulation currents such as input source current and op-amp supply current.

## Final Interpretation

Different analog filter topologies can realize very similar output transfer functions. Therefore, output-voltage response alone may be insufficient for topology-family classification. Current or impedance signatures provide additional circuit-level information and improve separability.
