# Optical fingerprint support

The patch set and A52s optical fingerprint flow are ported from
[UN1CA](https://github.com/salvogiangri/UN1CA/tree/0c2ea1d61ddc78ae8e6900787f9f9e7269b7b439/unica/patches/product_feature/fingerprint/optical_fod),
commit `0c2ea1d61ddc78ae8e6900787f9f9e7269b7b439` (GPL-3.0-or-later).

The build downloads the required SM-G990B donor files once, then caches only
the six system files used by this patch flow.
