#
# Copyright (C) 2025 Salvo Giangreco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Debloat list for Galaxy A52s 5G (a52sxq)
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Overlays
SYSTEM_DEBLOAT+="
system/app/WifiRROverlayAppQC
system/app/WifiRROverlayAppWifiLock
"
PRODUCT_DEBLOAT+="
overlay/SoftapOverlay6GHz
overlay/SoftapOverlayDualAp
overlay/SoftapOverlayOWE
"

# mAFPC
SYSTEM_DEBLOAT+="
system/bin/mafpc_write
"

# HDCP
SYSTEM_DEBLOAT+="
system/bin/dhkprov
system/bin/qchdcpkprov
system/etc/init/dhkprov.rc
system/lib64/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0.so
"

# GameDriver
SYSTEM_DEBLOAT+="
system/priv-app/GameDriver-SM8550
"

# Camera SDK
SYSTEM_DEBLOAT+="
system/etc/default-permissions/default-permissions-com.samsung.android.globalpostprocmgr.xml
system/etc/default-permissions/default-permissions-com.samsung.petservice.xml
system/etc/default-permissions/default-permissions-com.samsung.videoscan.xml
system/etc/permissions/cameraservice.xml
system/etc/permissions/privapp-permissions-com.samsung.android.globalpostprocmgr.xml
system/etc/permissions/privapp-permissions-com.samsung.petservice.xml
system/etc/permissions/privapp-permissions-com.samsung.videoscan.xml
system/framework/scamera_sep.jar
system/priv-app/GlobalPostProcMgr
system/priv-app/PetService
system/priv-app/SCameraSDKService
system/priv-app/VideoScan
"

# system_ext clean-up
SYSTEM_DEBLOAT+="
system/etc/permissions/org.carconnectivity.android.digitalkey.rangingintent.xml
system/etc/permissions/org.carconnectivity.android.digitalkey.secureelement.xml
"
SYSTEM_EXT_DEBLOAT+="
app/QCC
bin/qccsyshal@1.2-service
etc/init/vendor.qti.hardware.qccsyshal@1.2-service.rc
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
framework/com.qti.location.sdk.jar
framework/org.carconnectivity.android.digitalkey.rangingintent.jar
framework/org.carconnectivity.android.digitalkey.secureelement.jar
lib/libqcc.so
lib/libqcc_file_agent_sys.so
lib/libqccdme.so
lib/libqccfileservice.so
lib/vendor.qti.hardware.qccsyshal@1.0.so
lib/vendor.qti.hardware.qccsyshal@1.1.so
lib/vendor.qti.hardware.qccsyshal@1.2.so
lib/vendor.qti.hardware.qccvndhal@1.0.so
lib/vendor.qti.qccvndhal_aidl-V1-ndk.so
lib64/libqcc.so
lib64/libqcc_file_agent_sys.so
lib64/libqccdme.so
lib64/libqccfileservice.so
lib64/vendor.qti.hardware.qccsyshal@1.0.so
lib64/vendor.qti.hardware.qccsyshal@1.1.so
lib64/vendor.qti.hardware.qccsyshal@1.2-halimpl.so
lib64/vendor.qti.hardware.qccsyshal@1.2.so
lib64/vendor.qti.hardware.qccvndhal@1.0.so
lib64/vendor.qti.qccvndhal_aidl-V1-ndk.so
priv-app/com.qualcomm.location
"

# Qualcomm IPA firmware blobs
VENDOR_DEBLOAT+="
firmware/ipa_fws.b00
firmware/ipa_fws.b01
firmware/ipa_fws.b02
firmware/ipa_fws.b03
firmware/ipa_fws.b04
firmware/ipa_fws.elf
firmware/ipa_fws.mdt
firmware/yupik_ipa_fws.b00
firmware/yupik_ipa_fws.b01
firmware/yupik_ipa_fws.b02
firmware/yupik_ipa_fws.b03
firmware/yupik_ipa_fws.b04
firmware/yupik_ipa_fws.elf
firmware/yupik_ipa_fws.mdt
"

# Extreme debloat - Claro / ZTA / carrier + Samsung bloat (778G extreme)
# Claro carrier apps (BR ZTA) - remove todos overlays e apps de operadora
SYSTEM_DEBLOAT+="
system/app/ZTA
system/app/ClaroRecarga
system/app/ClaroMusica
system/app/MinhaClaro
system/app/ClaroVideo
system/app/ClaroIdeias
system/app/ClaroSync
system/priv-app/OMCAgent5
system/priv-app/OMCAgent6
system/priv-app/ClaroService
system/etc/permissions/privapp-permissions-com.claro.*.xml
system/etc/permissions/privapp-permissions-com.samsung.android.app.omcagent.xml
system/app/com.samsung.android.app.omcagent
"
PRODUCT_DEBLOAT+="
app/ClaroApps
app/ZTAStub
app/ClaroDrive
app/ClaroProtege
priv-app/OMCAgent
priv-app/ZTAService
overlay/ClaroResOverlay
overlay/ZTAOverlay
"
VENDOR_DEBLOAT+="
etc/init/init.zta.rc
bin/zta_daemon
lib/libzta.so
lib64/libzta.so
"
SYSTEM_EXT_DEBLOAT+="
priv-app/ZTACarrierService
app/QCC-ZTA
"

# Samsung bloat extreme - manter apenas essencial para One UI 8 funcionar
SYSTEM_DEBLOAT+="
system/app/BBCAgent
system/app/BooksStub
system/app/CarModeStub
system/app/ChromeCustomizations
system/app/FacebookStub
system/app/FilesStub
system/app/GameHome
system/app/GameOptimizingService
system/app/LinkedInStub
system/app/MSStub_GalaxyStore
system/app/Netflix_Activation
system/app/Netflix_Stub
system/app/SamsungCalendar_Stub
system/app/SamsungMembers_Stub
system/app/SamsungNotes_Stub
system/app/OneDrive_Samsung_v3_Stub
system/app/Spotify_Stub
system/app/StoryVideo
system/app/Stk
system/app/Stk2
system/app/SimAppDialog
system/app/SGCMediaProvider
system/app/SmartSwitchAgent
system/app/WebManual
system/app/YouTube_Stub
system/priv-app/CNNPanel
system/priv-app/FBInstaller_NS
system/priv-app/FBServices
system/priv-app/MirrorLink
system/priv-app/SamsungBilling
system/priv-app/SecureFolderStub
system/priv-app/SecureWiFi
system/priv-app/SetupWizard_FB
system/priv-app/SKMSAgentService
system/priv-app/SmartReminder
system/priv-app/SVoiceLang
system/priv-app/Upday
system/priv-app/FlipboardBriefing
"
PRODUCT_DEBLOAT+="
app/FactoryCameraFB
app/FBAppManager_NS
app/NSDSWebAppStub
app/MusicShareStub
app/ContinuityServiceStub
app/SmartThingsStub
app/SwearDroidStub
app/AREmojiStub
app/AREmojiEditor
app/AvatarEmojiSticker
priv-app/HiyaService
priv-app/DeviceQualityAgent
"
VENDOR_DEBLOAT+="
app/CarrierConfigClaro
etc/permissions/com.claro.rcs.xml
"
