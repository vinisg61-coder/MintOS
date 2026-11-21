# Atualizações MintOS pelo app Samsung

O FotaAgent original (`com.wssyncmldm`) fica instalado e mantém a tela **Configurações > Atualização de software**. Os caminhos de consulta, registro, push e relatórios da Samsung são bloqueados. O botão de busca e a verificação periódica leem o manifesto publicado em:

`https://github.com/vinisg61-coder/MintOS/releases/latest/download/ota-a52sxq.json`

O port usa como base o módulo [FotaAgent de At30c](https://github.com/At30c/ShitStockModOrSomething/tree/seventeen/unica/mods/fotaagent), feito para One UI 8.0. O source do MintOS também usa One UI 8.0 / Android 16. Os patches ainda precisam passar pela build para confirmar compatibilidade com o APK FotaAgent extraído da firmware S916B; o fluxo não foi testado no aparelho A52s.

## Publicação

- Um push para `a52sxq-mintos-adapted` que conclui uma build normal publica o ZIP e o manifesto como a última GitHub Release do repositório.
- Ao executar o workflow manualmente, marque `publish_ota` para publicar; builds em modo debug nunca são publicadas.
- A ação assina os ZIPs com a chave OTA usada pelo FotaAgent e `fota_release.py` cria os descritores, valida checksums e divide ROMs acima do limite de arquivo das Releases.
- O instalador grava `FAIL` ou `DONE` em `/cache/fota/fota.status`, para o app Samsung finalizar o job depois de voltar do recovery.
- O manifesto publica apenas o dispositivo `a52sxq`. O app compara `ro.unica.timestamp` e ignora builds de outros dispositivos.

A tela Samsung baixa a ROM, verifica a assinatura e entrega o ZIP ao TWRP por `openrecoveryscript`. Portanto, o TWRP precisa estar instalado e aceitar esse método de instalação.

## Assinatura

Em builds normais, o ZIP e o `otacerts.zip` usam `aosp_testkey`. Em builds oficiais, ambos usam `platform`. Isso permite que `RecoverySystem.verifyPackage()` reconheça o ZIP baixado pelo app. A chave de desenvolvimento é pública; builds oficiais devem usar a chave privada de plataforma mantida nos secrets do repositório.

## Base e licença

Os patches, o `UpdateChecker`, o proxy de downloads em partes e o publicador derivam do trabalho GPL-3.0-or-later de At30c. As alterações do port MintOS configuram A52s, o endpoint do próprio repositório e o pipeline de publicação.
