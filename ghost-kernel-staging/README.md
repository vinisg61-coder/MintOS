# Ghost Kernel Staging — A52s (SM-A528B / 778G)

> Pasta criada a pedido do vinisg61-coder para deletar depois. Não afeta o build atual da MintOS (`a52sxq` continua usando `prebuilts/kernels/a52sxq` bone-machine). Só quando você falar `pode buildar` eu integro de verdade.

## O que é
- Kernel `vinisg61-coder/a52sxq-ghost-kernel-full-build` (`42f01f2` `main`) — universal `One UI 4.1 / 5.1 / 6.0 / 6.1 / 7 / 8 / 8.5` com `KernelSU-Next` + `custom-patches` + `lahaina/gki`.
- Já clonado em `C:\Users\vinicius\AppData\Local\Temp\ghost-kernel` (checkout falhou no Windows por `aux.c` NTFS, normal — build precisa WSL).

## Como integrar quando você liberar
1. Buildar Ghost no WSL (ou PowerShell com toolchain):
   ```bash
   cd /tmp/ghost-kernel
   ./build_reproducible.sh  # ou ./build_kernel_zip.sh
   # gera out/arch/arm64/boot/Image + dtbo + vendor_boot
   ```
2. Copiar para MintOS (esse script já deixado pronto):
   ```bash
   cp out/arch/arm64/boot/Image* prebuilts/kernels/a52sxq/boot.img
   cp out/arch/arm64/boot/dtbo.img prebuilts/kernels/a52sxq/dtbo.img
   cp out/arch/arm64/boot/vendor_boot.img prebuilts/kernels/a52sxq/vendor_boot.img
   # ou use ghost-kernel-staging/swap-ghost.sh
   ```
3. Re-build MintOS `a52sxq` — vai usar Ghost em vez do bone-machine.

## Arquivos desta pasta
- `README.md` — este
- `swap-ghost.sh` — script para trocar kernels quando liberar
- `boot.img` / `dtbo.img` / `vendor_boot.img` — placeholders (vazios) para você ver onde vai

## Para deletar
`rm -rf ghost-kernel-staging` na raiz da MintOS. Não quebra nada, é só staging.

## Status atual
- MintOS `sixteen` continua bootável com kernel stock `prebuilts/kernels/a52sxq` (One UI 8).
- Ghost fica em standby até seu `pode buildar` após testar boot da MintOS.
