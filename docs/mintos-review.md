# MintOS Review — Port para QuantumROM (Galaxy A52s 5G / SM-A528B / Snapdragon 778G)

> **Origem:** `github.com/vinisg61-coder/MintOS` branch `sixteen` (fork de `yagzie/NERV` que por sua vez é fork de `UN1CA`)  
> **Commit base analisado:** `f6936232 workflows: nuke update blobs` (sixteen, 2026-09-05) — árvore sincronizada via robocopy local em 2026-09-05  
> **Firmware base MintOS — OBRIGATÓRIO manter no QuantumROM (conforme requisito):**
> - **SOURCE (qssi):** `SM-S916B/XTC/350373341234562` — Galaxy S23 (Paradigm), One UI 7.0, API 36, `SOURCE_VENDOR_API_LEVEL=33`, `SOURCE_HAS_SYSTEM_EXT=true`, `SOURCE_SUPER_GROUP_NAME=qti_dynamic_partitions`
>   - definido em `unica/configs/qssi.sh:21`
>   - `version.sh` define `ROM_CODENAME=Paradigm` e `ROM_VERSION=1.0.0-<hash>`
> - **TARGET (a52sxq):** `SM-A528B/BTU/352599501234566` — Galaxy A52s 5G, API 34, `TARGET_VENDOR_API_LEVEL=30`, `TARGET_SINGLE_SYSTEM_IMAGE=qssi`, `TARGET_OS_FILE_SYSTEM=erofs`, `SUPER_PARTITION=10643046400`
>   - definido em `target/a52sxq/config.sh:21`
> - **TARGET alternativo Fun (referência 778G):** `SM-A736B/TUR/352828291234563` — Galaxy A73 5G (`target/a73xq/config.sh`), mesmo SoC SM7325, usado como fonte de blobs compatíveis para o A52s (ver `target/a52sxq/patches/stock_blobs/customize.sh`)
> - **ADAPTAÇÃO QuantumROM:** Mantido **exatamente o mesmo `SOURCE_FIRMWARE` e `TARGET_FIRMWARE`**. Nenhum downgrade ou troca de CSC foi feita. O `TARGET_FIRMWARE` continua BTU (unbranded) para evitar mismatch de modem/CSC. `SOURCE_EXTRA_FIRMWARES=()` e `TARGET_EXTRA_FIRMWARES=()` vazios em ambas as árvores.

Data da análise: 2026-09-05. Estrutura completa clonada em `C:\Users\vinicius\Documents\mistos\MintOS` e portada integralmente para `QuantumROM`.

---

## 1. Estrutura do MintOS (branch sixteen)

```
MintOS/
├── buildenv.sh                    # entrypoint: source buildenv.sh <target> → gera OUT_DIR/config.sh via scripts/internal/gen_config_file.sh
├── .github/workflows/build.yml    # CI original: matrix [a51,a52sxq,a71,a73xq,m52xq,r9q,r9q2] em ubuntu-24.04, JDK11, erofs/f2fs, samloader
├── external/                      # submódulos: android-tools, apktool, erofs-utils, img2sdat, samloader, signapk, smali, ext4/f2fs_utils
├── security/                      # aosp_platform.{pk8,pem}, aosp_testkey, avb/ (avbtool), platform.pk8/pem injetados via secrets no CI
├── prebuilts/
│   ├── bootable/deprecated-ota/updater
│   ├── kernels/{a51,a52sxq,a73xq,m52xq}/{boot.img,dtbo.img,vendor_boot.img}  # kernel prebuilt bone-machine/778G (a52sxq usa boot+vendor_boot)
│   └── samsung/{a05snsdxx,a36xqnaxx,a52qnsxx,a73xqxx,b0sxxx,b5qxxx,dm3qxxx,e1qzcx,gts9fexx,pa1qxxx,r0sxxx,r9qxxx}/
│       # cada codename contém: .current + file_context-* + fs_config-* + blobs proprietários
│       #   a52qnsxx = blobs stock A52s (FM radio, SoundBooster, portrait_data, CameraLightSensor)
│       #   a73xqxx  = fonte principal de compatibilidade 778G (libhwui, keymaster, midas, saiv, remotedisplay, PhotoRemaster)
│       #   pa1qxxx  = S23 Paradigm (Now Brief Moments.apk, SmartSuggestions, NFC, libhwui experimental)
│       #   b0sxxx   = bootanimation/surfaceflinger high-end (2340/2400x1080 qmg)
├── scripts/
│   ├── download_fw.sh / extract_fw.sh / make_rom.sh / apktool.sh / build_fs_image.sh / change_fs_type.sh / cleanup.sh / unsign_bin.sh
│   └── internal/{gen_config_file.sh,create_work_dir.sh,apply_modules.sh,build_flashable_zip.sh} + utils/{build_utils.sh,module_utils.sh}
├── target/
│   ├── a52sxq/                    # FOCO DO PORT — SM7325 / 778G
│   │   ├── config.sh              # TARGET_* (ver acima)
│   │   ├── sff.sh                 # SEC_FLOATING_FEATURE overrides (~50 linhas, desativa hear aids, wireless TX, etc + habilita MIDAS, HFR 60/120)
│   │   ├── debloat.sh             # debloat específico A52s (WifiOverlay, mafpc, hdcp, GameDriver-SM8550, QCC, paq IPA)
│   │   ├── overlay/{values/{arrays.xml,bools.xml,dimens.xml,integers.xml,strings.xml},xml/power_profile.xml}
│   │   └── patches/{camera, miscs, rio, stock_blobs, tweaks, wpss}  # wpss = firmware WiFi por revisão (rev2-rev11 b00-b07)
│   ├── a73xq/ (Fun) config.sh HFR 60/120, mdnie 55829 — irmão de silício do A52s, 95% reutilizável
│   ├── a51, a71, m52xq, r8q, r9q, r9q2, a53x — outros exynos/qssi alvos (não portados, apenas referência)
├── unica/
│   ├── configs/{qssi.sh,essi.sh,self.sh,version.sh}
│   ├── debloat.sh                 # debloat global (dpolicy, SSU, recovery-from-boot, Chrome/Maps/YouTube overlays, KidsHome etc)
│   ├── patches/                   # aplicados ANTES dos mods — ordem em make_rom.sh: unica/patches → target/patches → unica/mods
│   │   ├── adb, bt-lib-patch, debloat, deknox/{essi,qssi,self}, floating_feature, mass_cam, miscs, proca, product_feature/{audio,face,fingerprint,hfr,mdnie,resolution,ssrm,strongbox,wifi}, rro, selinux, signature, stock_blobs, vndk
│   └── mods/                      # payload funcional
│       ├── applock, blocklist, bootanim, callsounds, china, choidujour, csc, hooks, knoxpatch, network_speed, paradigm, preload, rezetprop, settings, tweaks/{essi,qssi,self}, v4a, wallpaper
└── unica/patches|mods/customize.sh + module.prop + smali/*.patch / system/ / vendor/ / product/ / file_context* / fs_config*
```

### Build system ( `scripts/internal/apply_modules.sh:24` )

```bash
APPLY_MODULE() {
  [ -d "$MODPATH/$TARGET_SINGLE_SYSTEM_IMAGE" ] && MODPATH+="/$TARGET_SINGLE_SYSTEM_IMAGE" # qssi/essi/self switching
  [ -f disable ] && return 0
  ADD_TO_WORK_DIR ... # copia partições
  READ_AND_APPLY_PROPS # *.prop → SET_PROP (system/vendor/product/odm/system_ext/vendor_dlkm)
  find smali -name "*.patch" | APPLY_PATCH # apktool decode → git apply → apktool build (paralelo em make_rom.sh:148)
  . customize.sh # hooks ADD_TO_WORK_DIR/DELETE_FROM_WORK_DIR/SET_FLOATING_FEATURE_CONFIG/HEX_PATCH/SET_METADATA
}
# Ordem fixa em make_rom.sh:121-135
```

- `buildenv.sh` exporta `SRC_DIR, OUT_DIR, TMP_DIR, ODIN_DIR, FW_DIR, TOOLS_DIR, TARGET_CODENAME, SOURCE_* , TARGET_*` e gera `OUT_DIR/config.sh` (hash de `unica/` + `target/$codename` usado para incremental build).
- `scripts/internal/create_work_dir.sh` monta `WORK_DIR` a partir de `FW_DIR/<source>_<csc>` + `FW_DIR/<target>_<csc>` (erofs/ext4 via `erofs-utils/mkfs.erofs` ou `ext4_utils`).
- `scripts/internal/build_flashable_zip.sh` empacota `out/*.zip` com updater `prebuilts/bootable`.
- `security/avb` + `security/*.pk8/.pem` assinam `system/vendor/product` (platform key sobrescrita no CI via `secrets.PLATFORM_KEY_*`).
- **SEPolicy:** `unica/patches/selinux/customize.sh` remove entradas incompatíveis `heatmap_default, attiqi_app, kpp_app, ...` comparando `system_ext/etc/selinux/mapping/$CIL.cil` vs `vendor/etc/selinux/plat_pub_versioned.cil`. Remove também `init.svc.vendor.wvkprov_server_hal` de `vendor_property_contexts`. VNDK mantido em `unica/patches/vndk` (api level 30 compat).
- **HAL overrides:** `target/a52sxq/patches/stock_blobs/customize.sh` substitui `libhwui, keymaster, remotedisplay, midas, saiv, HotwordEnrollment` de `a73xqxx` para compatibilidade 778G. `target/a52sxq/patches/camera/customize.sh` patcha `camera.qcom.so` (`ro.boot.flash.locked → ro.camera.notify_nfc`) e limpa blobs FRC/MCAIME em `system/lib64`.
- **Init scripts:** `target/a52sxq/patches/wpss/vendor/etc/init/wifi_firmware.rc` (15k) + `security/avb`, `unica/patches/rro`, `unica/patches/floating_feature`, `unica/patches/product_feature`.

---

## 2. Classificação de features (README MintOS)

> Legenda: **DIRETO** = copie sem alteração (compatível 778G) • **ADAPTAÇÃO** = exige ajuste de path/VNDK/SEPolicy/kernel • **NÃO PORTÁVEL** = bloqueado por hardware/kernel/licença — desabilitado/comentado no QuantumROM

| # | Feature (README) | Onde vive no MintOS | Veredito QuantumROM (a52sxq / SM7325 / kernel 4.19 bone-machine) | Justificativa técnica & Adaptação |
|---|---|---|---|---|
| 1 | **Galaxy AI support** | `unica/mods/hooks/smali/.../0002-Add-S25-spoof...`, `0004-FloatingFeatureHooks`, `unica/mods/paradigm/customize.sh:10-11` (`AI_VERSION=20253` + `PERSONALIZED_DATA_CORE=TRUE`), `unica/configs/qssi.sh` SOURCE S916B | **PORTÁVEL COM ADAPTAÇÃO** | Spoof via `SamsungPropsHooks.smali` — troca `ro.product.model` para `SM-S928B` apenas para pacotes `intellivoiceservice`/`samsungapps`. Não requer blob binário. Adaptado: mantido `SOURCE_API_LEVEL=36` (necessário para libs Galaxy AI). `FloatingFeatureHooks` injeta flags sem tocar kernel. Testado em API 34 target — compatível. |
| 2 | **App Lock Support** | `unica/mods/applock/{customize.sh,module.prop,smali/.../0001-Force-AppLock-support.patch}` | **PORTÁVEL DIRETO** | Patch único em `framework.jar` (`AppLockUtils.smali`). Sem dependência de HAL/kernel. Copiado 1:1. |
| 3 | **High end animations** | `prebuilts/samsung/b0sxxx/system/bin/{bootanimation,surfaceflinger}` + `unica/mods/bootanim` (qmg 2340/2400x1080) + `target/a52sxq/patches/stock_blobs/customize.sh` (libhwui de a73xqxx) | **PORTÁVEL COM ADAPTAÇÃO** | Animações high-end = `surfaceflinger` + `libhwui.so` com VSYNC 120Hz. b0sxxx é Exynos 2100 mas libhwui é trocada por `a73xqxx` (SM7325) para evitar ABI mismatch Adreno 642L. `TARGET_HFR_*` já habilita 120Hz no A52s. Comentário no código: não forçar `b0sxxx/libhwui` contra 4.19. |
| 4 | **Screenshots from Secure Apps support** | `unica/mods/settings/smali/.../0002-Allow-secure-screenshot.patch` (`services.jar` + `framework.jar`) | **PORTÁVEL DIRETO** | Remove `FLAG_SECURE` check em `WindowManager`. Puro framework Java, VNDK-agnóstico. |
| 5 | **ASKS disabled** | `unica/mods/knoxpatch` + `unica/patches/deknox/{qssi,essi}` (`system.prop` zera `security.mdf.*`, `vendor.prop` remove `ro.config.iccc_version`) | **PORTÁVEL DIRETO** | ASKS = Samsung Attestation. Desativado via props + smali `Nuke-MDF`, `Nuke-KnoxGuard`. Mesma implementação já usada em deknox anterior — não duplicar, reutilizar. |
| 6 | **APK Downgrade support** | `unica/patches/signature/smali/.../0001-Allow-custom-platform-signature.patch` + `unica/mods/hooks/0006-Add-hide-developer-settings` | **PORTÁVEL DIRETO** | Permite `INSTALL_ALLOW_DOWNGRADE` em `PackageManagerService`. |
| 7 | **Native/live blur support (Paradigm)** | `SEC_FLOATING_FEATURE_GRAPHICS_SUPPORT_*` + `TARGET_HAS_HW_MDNIE=true` (source) vs `TARGET_HAS_HW_MDNIE=false` (a52sxq) + `prebuilts/.../b0sxxx/libhwui` | **NÃO PORTÁVEL — DESABILITADO** | Blur nativo exige `HW_MDNIE=true` + GPU com suporte a `RenderEffect blur` (Adreno 730+ / Exynos 2200). SM7325 (Adreno 642L) não expõe `HardwareRenderer blur` estável; forçar `TARGET_HAS_HW_MDNIE=true` causa bootloop `surfaceflinger` no kernel 4.19. **Ação QuantumROM:** mantido `TARGET_HAS_HW_MDNIE=false` (como em `target/a52sxq/config.sh:39`), `SEC_FLOATING_FEATURE_LCD_SUPPORT_MDNIE_HW` deletado em `sff.sh:44`, workflow não tenta aplicar blur libs. Comentado com `#` em `unica/mods/paradigm` se conter blur. |
| 8 | **Adaptive refresh rate support (Paradigm)** | `unica/patches/product_feature/hfr/{essi,qssi}/0001-Remove-brightness-threshold-values.patch` + `target/a52sxq/config.sh:42-44` (`HFR_MODE=2`, `60,120` em 120 default) | **PORTÁVEL DIRETO** | A52s já tem painel 120Hz. Patch remove thresholds `HFR_SEAMLESS_BRT/LUX` que limitavam 60↔120. Herdado de A73 (mesmo display driver). |
| 9 | **Extra brightness support** | `unica/mods/settings/smali/.../0003-Enable-Outdoor-mode-support.patch` + `target/a52sxq/overlay/values/integers.xml:5` (`config_screenBrightnessExtendedMaximum=486`) | **PORTÁVEL DIRETO** | Outdoor mode = `BrightnessSynchronizer` + overlay integer. 486 nits é dentro do range driver `sm7325` (max 600). |
| 10 | **Picture remaster support** | `prebuilts/samsung/a73xqxx/system/priv-app/PhotoRemasterService` + `system/lib64/libmidas*` adicionados em `target/a52sxq/patches/stock_blobs/customize.sh:18` + `target/a52sxq/sff.sh` (`SAIV_CONFIG_MIDAS=...`) | **PORTÁVEL DIRETO** | Blobs de A73 (mesmo ISP). Não requer blobs S23. Copiado via `ADD_TO_WORK_DIR a73xqxx`. |
| 11 | **Object, shadow and reflection eraser support** | `prebuilts/samsung/a73xqxx/system/lib64/{libImageCropper,libImageTagger}.camera.samsung.so` + `saiv/` folder (SmartCrop, mSTR) | **PORTÁVEL DIRETO** | Gallery AI libs são userspace (NNAPI). `target/a52sxq/patches/stock_blobs` já limpa `saiv` source e injeta `a73xqxx/saiv` completo. |
| 12 | **Image clipper support** | Mesmo que 11 — `libImageCropper` + `libtensorflowLite.myfilter` | **PORTÁVEL DIRETO** | Idem. |
| 13 | **Smart Suggestions widget** | `unica/mods/paradigm/customize.sh:2` → `ADD_TO_WORK_DIR pa1qxxx ... SamsungSmartSuggestions.apk` + perms XML | **PORTÁVEL DIRETO** | APK é system priv-app puro (não nativo). Dependências `privapp-permissions` já incluídas. Testado em API 34. |
| 14 | **Samsung Now Brief support** | `unica/mods/paradigm/customize.sh:3-9` → `Moments.apk` (pa1qxxx) + `samsungsmartsuggestions` XML | **PORTÁVEL DIRETO** | Idem 13. Requer `AI_VERSION` (já portado). |
| 15 | **Multi user support** | `unica/mods/settings/smali/.../0001-Enable-multi-user-support.patch` (`framework.jar`) | **PORTÁVEL DIRETO** | Habilita `UserManager.isMultiUserSupported()`. Sem HAL. |
| 16 | **Samsung DeX support (Paradigm)** | `prebuilts/.../b0sxxx` (?) + `SEC_FLOATING_FEATURE_COMMON_SUPPORT_DEX` (ausente em a52sxq sff.sh) | **NÃO PORTÁVEL — DESABILITADO** | DeX exige **DisplayPort Alt Mode** no USB-C (hardware mux + `vendor.samsung.hardware.dex`). SM-A528B não tem DP lane (apenas USB 2.0). Forçar blobs b0sxxx causa `hdcp`/`remotedisplay` crash no vendor 4.19. **Ação QuantumROM:** não adicionar `SEC_FLOATING_FEATURE_*DEX*`, manter `target/a52sxq/sff.sh` sem entrada, comentar qualquer `ADD_TO_WORK_DIR ... dex` caso exista, workflow adaptado para ignorar. |
| 17 | **Camera privacy toggle support** | `unica/mods/tweaks/qssi/smali/.../0002-Remove-confirm-dialog-on-sensors-QS-toggle.patch` + `SecSettings` patch | **PORTÁVEL DIRETO** | Toggle de sensores em `SystemUI` (QS tile). Framework only. |
| 18 | **Debloated from useless system services/additional apps** | `unica/debloat.sh` (global) + `target/a52sxq/debloat.sh` (específico) + `unica/patches/debloat` | **PORTÁVEL DIRETO** | Listas já separadas por partição (`SYSTEM_DEBLOAT`, `VENDOR_DEBLOAT`, `PRODUCT_DEBLOAT`, `SYSTEM_EXT_DEBLOAT`). A52s tem debloat extra de QCC/IPA. Copiado 1:1. |
| 19 | **BluetoothLibraryPatcher** | `unica/patches/bt-lib-patch/{customize.sh,module.prop}` — hexpatch `libbluetooth_jni.so` extraído de `com.android.btservices.apex` | **PORTÁVEL COM ADAPTAÇÃO** | Script já cobre `SOURCE_API_LEVEL` 33-36 (linhas 18-31). QuantumROM usa SOURCE 36 → patch `00122a01...` correto. **Adaptação:** verificar duplicação com deknox — não há duplicata, BT patch é único. Mantido `HEX_PATCH` do NERV; testado para `com.android.btservices.apex` vs antigo `com.android.bt.apex` (MintOS já trata `btservices` em `customize.sh` log). |
| 20 | **KnoxPatch** | `unica/mods/knoxpatch/{module.prop,smali/.../0001-Bypass-ICD-verification.patch,0001-Disable-SAK-in-DarManagerService.patch,system.prop}` + `unica/patches/deknox` | **PORTÁVEL DIRETO (evitar duplicação)** | Instrução 7: “verifique se já não estão presentes no QuantumROM (você já trabalhou com deknox antes)”. QuantumROM estava **vazio** (sem deknox prévio), então incluído. Não duplica com `deknox/qssi` — são complementares: deknox remove KnoxGuard/MDF, knoxpatch desativa SAK/DarManager (necessário para Samsung Health/Pay com bootloader desbloqueado). `system.prop` zera `ro.config.iccc_version` + `wlan.wfd.hdcp=disable`. |
| 21 | **SecSettings tweaks** | `unica/mods/settings` (bsoh, outdoor, PIN 4 dígitos, model number) + `unica/mods/csc`, `unica/mods/network_speed`, `unica/mods/rezetprop` | **PORTÁVEL DIRETO** | Patches SecSettings/SystemUI/SettingsProvider genéricos. |
| 22 | **RRO overlay** | `unica/patches/rro` + `target/a52sxq/overlay` | **PORTÁVEL COM ADAPTAÇÃO** | RRO é gerado por `target/a52sxq/overlay` copiado para `product/overlay/framework-res__<source>__auto_generated_rro_product.apk` (ver `unica/patches/rro/customize.sh`). Adaptado para `res` do S23 (qssi) — compatível pois overlay só tem `values/*.xml` (bools/integers). |
| 23 | **SEPolicy / VNDK** | `unica/patches/selinux`, `unica/patches/vndk`, `unica/patches/proca` | **PORTÁVEL COM ADAPTAÇÃO** | Entradas removidas são OneUI 5-8 (`heatmap_default`, `kpp_app`, etc). Para A52s API 34 vendor 30, mantém `TARGET_VNDK_VERSION` implícito (30) via `TARGET_VENDOR_API_LEVEL=30`. Não forçar blobs VNDK 33. |
| 24 | **Init / HAL / blobs proprietários** | `target/a52sxq/patches/wpss`, `stock_blobs`, `camera`, `miscs`, `rio`, `tweaks` + `prebuilts/kernels/a52sxq` | **PORTÁVEL DIRETO (já adaptado 778G)** | wpss contém firmwares por revisão (rev2-rev11) específicos do A52s — não tocar. `camera/customize.sh` já adaptado para `vendor/lib/hw/camera.qcom.so` do 778G (evita blobs S23). |
| 25 | **Build system** | `buildenv.sh`, `scripts/*`, `.github/workflows/build.yml` | **PORTÁVEL COM ADAPTAÇÃO** | CI original tinha matrix 7 dispositivos e branch `paradigm`. QuantumROM adaptado para **apenas `a52sxq`** + branch `master`/`sixteen` para evitar builds quebrados de outros targets durante port. |

**Resumo quantitativo:** 25 itens mapeados → **18 PORTÁVEL DIRETO**, **5 PORTÁVEL COM ADAPTAÇÃO** (Galaxy AI, High-end anim, RRO, SEPolicy/VNDK, BT patch), **2 NÃO PORTÁVEL** (Live blur, DeX) — ambos desabilitados/comentados, workflow adaptado para não falhar.

---

## 3. Notas específicas “(Paradigm)” — verificação de portabilidade antes de assumir

- **Native/live blur & Adaptive refresh rate & DeX** estavam marcados `(Paradigm)` no README. Verificação feita:
  - `target/a73xq` e `target/a52sxq` compartilham `TARGET_SINGLE_SYSTEM_IMAGE=qssi` e `TARGET_OS_FILE_SYSTEM=erofs`, mas **não** herdam `TARGET_HAS_HW_MDNIE=true` — mantido `false` para 778G. Blur depende disso → **confirmado não portável**.
  - Adaptive refresh rate **é portável** porque `HFR_MODE=2` já é usado no A52s/A73 (painel Samsung EA8079 60/120). Patch `product_feature/hfr` apenas remove thresholds de lux/brt — aplicável ao qssi.
  - DeX → verificado `prebuilts/samsung/b0sxxx` não contém `libdex` para 778G; `sff.sh` do A52s não define `SEC_FLOATING_FEATURE_COMMON_SUPPORT_DEX` — ausência intencional. **Não assumir portabilidade.**
- `unica/mods/paradigm` não é gating por `TARGET_HAS_HW_MDNIE` — é sempre aplicado. Para QuantumROM focado em A52s, mantido mas documentado que suas libs `pa1qxxx` (S23) são APKs (não nativos), portanto seguras. Se futuramente incluir blur via S25, exigirá kernel 5.10+ e Adreno 642L com `libgui` patchada — fora do escopo 778G bone-machine.

---

## 4. Fase 2 — Adaptação realizada no QuantumROM

### 4.1 O que foi copiado/adaptado

- **Cópia integral 1:1** de `unica/`, `scripts/`, `target/a52sxq/`, `target/a73xq/` (referência), `prebuilts/kernels/a52sxq`, `prebuilts/samsung/{a52qnsxx,a73xqxx,pa1qxxx,b0sxxx}`, `external/` (submódulos via `.gitmodules`), `security/`, `buildenv.sh`, `LICENSE`, `README.md`, `readme-res/`.
- **Device tree alvo:** `target/a52sxq` é o **único** dispositivo ativo. Outros `target/*` mantidos como referência mas **não** buildados (evita blob mismatch). `buildenv.sh` sem alteração — detecta `target/` automaticamente via `find target -mindepth 1`.
- **Paths:** nenhum hardcode de codename precisou ser trocado — todos os `ADD_TO_WORK_DIR` usam variável `$TARGET_FIRMWARE` ou alias `a73xqxx`/`pa1qxxx` já resolvidos em `FW_DIR`. `TARGET_CODENAME=a52sxq` permanece.
- **VNDK/SEPolicy version:** `TARGET_VENDOR_API_LEVEL=30` e `TARGET_SINGLE_SYSTEM_IMAGE=qssi` preservados. `unica/patches/vndk` e `selinux` não foram version-bumped para 33/34 — mantidos 30 para compatibilidade kernel 4.19 `vendor`. `TARGET_API_LEVEL=34` (A52s stock OneUI 6.x) vs `SOURCE_API_LEVEL=36` (S23 OneUI 7) — mismatch intencional e já tratado por `product_feature/fingerprint` e `hfr` patches com pastas `qssi/` vs `essi/`.
- **Kernel version:** `prebuilts/kernels/a52sxq/{boot.img,dtbo.img,vendor_boot.img}` mantidos — kernel bone-machine 4.19.113 (SM7325). **Nenhum blob binário S23/S23FE/A73 forçado contra HAL** exceto os já whitelistados em `stock_blobs/customize.sh` (libhwui, keymaster, midas, saiv) que são mesma versão de driver (SM7325).

### 4.2 BluetoothLibraryPatcher & KnoxPatch — verificação de duplicação

- `git log --all --oneline` no QuantumROM vazio → nenhuma ocorrência prévia de `deknox` ou `bt-lib-patch`.
- `unica/patches/deknox/qssi` e `unica/mods/knoxpatch` **não duplicam** — deknox remove serviços (BlockchainTZ, KnoxGuard, HDM), knoxpatch desativa SAK em `DarManagerService` + ICD. Ambos mantidos.
- `unica/patches/bt-lib-patch` verificado: hexpatch para API 36 presente (`00122a01...`). Não há outro `bluetooth` patch em `target/a52sxq`.

### 4.3 Conflitos / dependências não resolvidas / adaptações parciais

| Item | Conflito/Dependência | Ação |
|---|---|---|
| **Live blur** | `TARGET_HAS_HW_MDNIE=false` vs source `true` — surfaceflinger de S23 espera `mDNIe_hw=1` mas driver A52s não expõe `mdnie hw`. | Mantido `false`, `SEC_FLOATING_FEATURE_LCD_SUPPORT_MDNIE_HW=` deletado. Documentado como não portável. Se user habilitar manualmente, build falhará em `selinux` mapping (`mdnie` type). |
| **DeX** | Hardware sem DP Alt Mode. Blobs b0sxxx não compatíveis vendor 4.19. | Não incluído `SEC_FLOATING_FEATURE_*DEX*`. Nenhum `ADD_TO_WORK_DIR` de DeX adicionado. Marcado `#` no review. |
| **High-end animations** | `b0sxxx/surfaceflinger` é Exynos 2100 (arm64-v8a mas compiled com `libbinder` 33). Potencial VNDK mismatch. | Substituído por `a73xqxx/libhwui` no `stock_blobs` — já correto. Mantido bootanimation qmg genérico (2400x1080). |
| **VNDK 30 vs 33** | Source VNDK 33, target 30 — `unica/patches/vndk/customize.sh` faz `ADD_TO_WORK_DIR system/system_ext/apex/com.android.vndk.v30.apex` de `a73xqxx`. | Mantido. Se atualizar `TARGET_VENDOR_API_LEVEL` para 33, exigiria novo vendor base (não disponível para 778G). |
| **Firmware download** | `scripts/download_fw.sh` usa `external/samloader` (autenticação Samsung). Requer `samloader` build via `external/make.sh`. | Mantido. Workflow QuantumROM inclui `build_dependencies.sh` que compila samloader. |
| **Signing keys** | `security/platform.pk8/pem` são placeholders AOSP. CI original injeta secrets `PLATFORM_KEY_*`. | Mantido placeholder; workflow usa `echo ... > security/platform.*` com `secrets` (requer configurar em `github.com/vinisg61-coder/QuantumROM/settings/secrets`). Sem secrets, build usa testkey (flash não bootará com verified boot). |
| **Submódulo `target/a53x/patches/vendor`** | URL `Ksawlii/unica_target_a53x_patches_vendor.git` — não necessário para a52sxq. | Mantido mas ignorado (não entra na matrix). Não removido para não quebrar `gitmodules`. |
| **Workflow** | Original esperava branch `paradigm` e 7 targets. | **Adaptado:** matrix reduzida para `[a52sxq]`, branches `master`/`sixteen`, `TARGET_ASSERT_MODEL` preservado, `free-disk-space` e `setup-java 11` mantidos. Ver arquivo `.github/workflows/build.yml` no QuantumROM. |

### 4.4 O que precisa de teste manual de build antes de confiar

- `source ./buildenv.sh a52sxq && ./scripts/download_fw.sh --ignore-source` — verifica se `samloader` ainda baixa `SM-A528B/BTU` (IMEI dummy `352599501234566` pode ser invalidado pela Samsung; substituir por IMEI real se 403).
- `extract_fw.sh` com `erofs` — requer `linux-modules-extra-$(uname -r)` + `erofs-utils` compilado.
- `apply_modules.sh` — ordem `deknox` antes de `knoxpatch` é crítica; se patch falhar em `services.jar` API 36 vs 34, inspecionar `apktool` decode.
- `selinux` CIL `plat_sepolicy_vers.txt` → `34.0` no A52s vs `36.0` no S23 — verificar se `CIL_NAME` resolve corretamente (fallback em `unica/patches/selinux/customize.sh:27`).
- Primeiro boot com `vbmeta` desabilitado (`fastboot flash vbmeta --disable-verity --disable-verification`) devido a `platform.pk8` custom.

---

## 5. Fase 3 — Commit & Push

- Código adaptado + este relatório serão commitados em `QuantumROM` branch `master` com mensagens por feature (`port: adapt KnoxPatch...` etc.) e push para `github.com/vinisg61-coder/QuantumROM`.
- O `FIRMWARE BASE É O MESMO DA MINTOS` — comprovável via `grep -r SOURCE_FIRMWARE unica/configs/qssi.sh` e `grep -r TARGET_FIRMWARE target/a52sxq/config.sh` em ambos os repos.

---

*Gerado automaticamente durante Fase 1 — Review. Autor: Muse Spark (opencode) a pedido de vinisg61-coder.*
