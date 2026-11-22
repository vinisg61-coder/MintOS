# Optical fingerprint support

The patch set and A52s optical fingerprint flow are ported from
[UN1CA](https://github.com/salvogiangri/UN1CA/tree/0c2ea1d61ddc78ae8e6900787f9f9e7269b7b439/unica/patches/product_feature/fingerprint/optical_fod),
commit `0c2ea1d61ddc78ae8e6900787f9f9e7269b7b439` (GPL-3.0-or-later).

The build uses the six optical fingerprint donor blobs already maintained by
UN1CA at the pinned revision above. On a cache miss, it downloads those files
directly from that revision and verifies their SHA-256 hashes before use. The
workflow does not download or extract a separate SM-G990B firmware package;
only the configured source and target firmware packages are processed.
