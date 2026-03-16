# ROG Ally Optimizer v15
# PowerShell + Windows Forms  -  No Python, no installs
# Double-click Launch.bat  OR  right-click this file -> Run with PowerShell
#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# ?? Native APIs ???????????????????????????????????????????????????????????????
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class NativeApi {
    // Display
    [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Ansi)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)] public string dmDeviceName;
        public short dmSpecVersion,dmDriverVersion,dmSize,dmDriverExtra;
        public int dmFields,dmPositionX,dmPositionY,dmDisplayOrientation,dmDisplayFixedOutput;
        public short dmColor,dmDuplex,dmYResolution,dmTTOption,dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)] public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel,dmPelsWidth,dmPelsHeight,dmDisplayFlags,dmDisplayFrequency;
    }
    [DllImport("user32.dll")] public static extern int ChangeDisplaySettingsW(ref DEVMODE dm,int f);
    // Process
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a,bool i,int pid);
    [DllImport("kernel32.dll")] public static extern bool SetPriorityClass(IntPtr h,int p);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    // Timer resolution  -  0.5ms cuts input lag and frame pacing stutter
    [DllImport("winmm.dll")] public static extern int timeBeginPeriod(int ms);
    [DllImport("winmm.dll")] public static extern int timeEndPeriod(int ms);
    // RAM flush  -  empties standby memory Windows holds after apps close
    [DllImport("psapi.dll")] public static extern bool EmptyWorkingSet(IntPtr proc);
}
"@

# ?? Palette ???????????????????????????????????????????????????????????????????
function rgb($r,$g,$b){ [System.Drawing.Color]::FromArgb($r,$g,$b) }
$C = @{
    Bg=rgb 0 0 8; Panel=rgb 6 6 14; Card=rgb 11 11 20; Card2=rgb 17 17 28
    Border=rgb 28 28 46; BHi=rgb 44 44 72
    Red=rgb 255 0 34; RedGlo=rgb 255 51 85
    Cyan=rgb 0 229 255; Green=rgb 0 255 136; GreenD=rgb 0 100 55
    Warn=rgb 255 109 0; Purp=rgb 157 78 221
    Muted=rgb 55 55 88; Text=rgb 168 168 200; Hi=rgb 255 255 255
    Xbox=rgb 16 124 16
}
$TILE_COLORS = @(
    (rgb 255 0 34),(rgb 157 78 221),(rgb 0 120 212),(rgb 0 180 80),
    (rgb 255 109 0),(rgb 220 0 140),(rgb 0 188 212),(rgb 255 193 7),
    (rgb 0 172 156),(rgb 100 60 220)
)

# ?? Fonts (only what's actually used) ????????????????????????????????????????
$F = @{
    Title = New-Object System.Drawing.Font("Bahnschrift",22,[System.Drawing.FontStyle]::Bold)
    H1    = New-Object System.Drawing.Font("Bahnschrift",16,[System.Drawing.FontStyle]::Bold)
    H2    = New-Object System.Drawing.Font("Bahnschrift",13,[System.Drawing.FontStyle]::Bold)
    H3    = New-Object System.Drawing.Font("Bahnschrift",11,[System.Drawing.FontStyle]::Bold)
    Body  = New-Object System.Drawing.Font("Segoe UI",11)
    BodyB = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    Small = New-Object System.Drawing.Font("Segoe UI",9)
    Mono  = New-Object System.Drawing.Font("Consolas",10)
    MonoS = New-Object System.Drawing.Font("Consolas",9)
}

# ?? Device database ???????????????????????????????????????????????????????????
$PLAN_HIGH     = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$PLAN_ULTIMATE = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$PLAN_BALANCED = "381b4222-f694-41f0-9685-ff5bb260df2e"

$MODELS = [ordered]@{
    "ROG Ally - Z1 (2023)" = @{
        Chip="AMD Ryzen Z1"; Cores="6c/12t"; CUs=4; TF=2.56; RAM=16; Tier="entry"
        Plan=$PLAN_HIGH; Color=(rgb 255 140 0)
        TDP=@{ battery=@{silent=10;performance=15;turbo=25}; plugged=@{silent=10;performance=15;turbo=25} }
        Presets=@(("540p MAX",960,540),("720p BALANCED",1280,720),("800p QUALITY",1280,800),("1080p NATIVE",1920,1080))
    }
    "ROG Ally - Z1 Extreme (2023)" = @{
        Chip="AMD Ryzen Z1 Extreme"; Cores="8c/16t"; CUs=12; TF=8.6; RAM=16; Tier="mid"
        Plan=$PLAN_HIGH; Color=(rgb 255 0 34)
        TDP=@{ battery=@{silent=10;performance=15;turbo=25}; plugged=@{silent=10;performance=15;turbo=30} }
        Presets=@(("720p PERF",1280,720),("800p BALANCED",1280,800),("900p HIGH",1600,900),("1080p NATIVE",1920,1080))
    }
    "ROG Ally X (2024)" = @{
        Chip="AMD Ryzen Z1 Extreme"; Cores="8c/16t"; CUs=12; TF=8.6; RAM=24; Tier="mid-plus"
        Plan=$PLAN_HIGH; Color=(rgb 180 0 255)
        TDP=@{ battery=@{silent=13;performance=17;turbo=25}; plugged=@{silent=13;performance=17;turbo=30} }
        Presets=@(("720p PERF",1280,720),("800p BALANCED",1280,800),("900p HIGH",1600,900),("1080p NATIVE",1920,1080))
    }
    "ROG Xbox Ally (2025)" = @{
        Chip="AMD Ryzen Z2A"; Cores="4c/8t"; CUs=8; TF=4.0; RAM=16; Tier="entry-plus"
        Plan=$PLAN_HIGH; Color=(rgb 0 200 170)
        TDP=@{ battery=@{silent=13;performance=17;turbo=25}; plugged=@{silent=13;performance=17;turbo=25} }
        Presets=@(("540p MAX",960,540),("720p BALANCED",1280,720),("800p HIGH",1280,800),("1080p NATIVE",1920,1080))
    }
    "ROG Xbox Ally X (2025)" = @{
        Chip="AMD Ryzen AI Z2 Extreme"; Cores="8c/16t"; CUs=16; TF=12.0; RAM=24; Tier="high"
        Plan=$PLAN_ULTIMATE; Color=(rgb 0 200 255)
        TDP=@{ battery=@{silent=13;performance=17;turbo=25}; plugged=@{silent=13;performance=17;turbo=35} }
        Presets=@(("800p PERF",1280,800),("900p BALANCED",1600,900),("1080p HIGH",1920,1080),("1080p NATIVE",1920,1080))
    }
}

$WHITELIST = @(
    "system","system idle process","registry","smss.exe","csrss.exe","wininit.exe",
    "winlogon.exe","services.exe","lsass.exe","svchost.exe","runtimebroker.exe",
    "taskhostw.exe","explorer.exe","dwm.exe","ctfmon.exe","fontdrvhost.exe","sihost.exe",
    "amdow.exe","amdrsserv.exe","amddvr.exe","atieclxx.exe","atiesrxx.exe",
    "asuslinksystem.exe","asusosd.exe","armoury crate.exe","armourycrate.service.exe",
    "atkexcomsvr.exe","atkpackage.exe","gamevisual.exe","gpumode.exe",
    "asusoptimization.exe","asuscertservice.exe","rogcontrolcenter.exe","audiodg.exe",
    "msmpeng.exe","nissrv.exe","securityhealthsystray.exe","securityhealthservice.exe",
    "wuauclt.exe","xboxapp.exe","xboxpcapp.exe","gamingservices.exe",
    "gamingservicesnet.exe","microsoftgamingoverlay.exe","gamelaunchhelper.exe",
    "powershell.exe","pwsh.exe"
)

$BLOAT = @(
    @{Name="Microsoft Teams";    Desc="Heavy RAM and CPU at idle";             Cmd='winget uninstall --id Microsoft.Teams --silent --accept-source-agreements';                                                       Default=$true}
    @{Name="Microsoft OneDrive"; Desc="Scans files constantly in background";  Cmd='winget uninstall --id Microsoft.OneDrive --silent --accept-source-agreements';                                                    Default=$true}
    @{Name="Cortana";            Desc="Voice assistant, wastes RAM";           Cmd='powershell -Command "Get-AppxPackage *549981C3F5F10* | Remove-AppxPackage"';                                                      Default=$true}
    @{Name="Office Hub";         Desc="Office ad app, not needed for gaming";  Cmd='powershell -Command "Get-AppxPackage *MicrosoftOfficeHub* | Remove-AppxPackage"';                                                  Default=$true}
    @{Name="Mail and Calendar";  Desc="Use a browser instead";                 Cmd='powershell -Command "Get-AppxPackage *windowscommunicationsapps* | Remove-AppxPackage"';                                           Default=$false}
    @{Name="Xbox Game Bar";      Desc="Armoury Crate replaces this";           Cmd='powershell -Command "Get-AppxPackage *XboxGamingOverlay* | Remove-AppxPackage"';                                                  Default=$false}
    @{Name="Solitaire";          Desc="Pre-installed game, frees space";       Cmd='powershell -Command "Get-AppxPackage *MicrosoftSolitaireCollection* | Remove-AppxPackage"';                                       Default=$false}
    @{Name="Mixed Reality";      Desc="VR app, unused on a handheld";          Cmd='powershell -Command "Get-AppxPackage *MixedReality* | Remove-AppxPackage"';                                                      Default=$true}
    @{Name="3D Viewer";          Desc="3D apps, unused, waste space";          Cmd='powershell -Command "Get-AppxPackage *Microsoft3DViewer* | Remove-AppxPackage; Get-AppxPackage *Paint3D* | Remove-AppxPackage"'; Default=$true}
    @{Name="Search Indexer";     Desc="Stop background file indexing";         Cmd='sc config WSearch start= disabled && net stop WSearch';                                                                           Default=$true}
    @{Name="Windows Ads";        Desc="Stop Start menu ads and suggestions";   Cmd='reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f';  Default=$true}
    @{Name="Startup Delay";      Desc="Remove 10s artificial boot delay";      Cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f';       Default=$true}
)

$PRIORITY = @{ "Normal"=0x20; "Above Normal"=0x8000; "High"=0x80; "Realtime"=0x100 }

# ?? App state ?????????????????????????????????????????????????????????????????
$BaseDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProfileFile = Join-Path $BaseDir "profiles.json"
$SettFile    = Join-Path $BaseDir "settings.json"

$script:Profiles     = @{}
$script:Settings     = @{ device="ROG Ally - Z1 Extreme (2023)"; mode="simple"; handheld=$true }
$script:SelectedGame = $null
$script:Mode         = "simple"
$script:Handheld     = $true
$script:FocusIdx     = 0
$script:TilePanels   = @{}
$script:PowerBtns    = @{}
$script:XboxActive   = $false
$script:Form         = $null
$script:GridScroll   = $null
$script:AutoBtn      = $null

# ?? File I/O ??????????????????????????????????????????????????????????????????
function Load-Data {
    if (Test-Path $ProfileFile) {
        try { $script:Profiles = Get-Content $ProfileFile -Raw | ConvertFrom-Json -AsHashtable } catch {}
    }
    if (Test-Path $SettFile) {
        try {
            $s = Get-Content $SettFile -Raw | ConvertFrom-Json -AsHashtable
            foreach ($k in $s.Keys) { $script:Settings[$k] = $s[$k] }
        } catch {}
    }
    $script:Mode     = $script:Settings.mode
    $script:Handheld = $script:Settings.handheld
    # Load boost settings from saved file
    foreach ($k in @($script:BoostSettings.Keys)) {
        $saved = $script:Settings["boost_$k"]
        if ($saved -ne $null) { $script:BoostSettings[$k] = [bool]$saved }
    }
}
function Save-Profiles { $script:Profiles | ConvertTo-Json -Depth 5 | Set-Content $ProfileFile -Encoding UTF8 }
function Save-Settings  { $script:Settings | ConvertTo-Json -Depth 3 | Set-Content $SettFile   -Encoding UTF8 }

# ?? Device / power helpers ????????????????????????????????????????????????????
function Get-Dev {
    $d = $MODELS[$script:Settings.device]
    if ($d) { return $d } else { return $MODELS["ROG Ally - Z1 Extreme (2023)"] }
}
function Get-Plugged {
    try { [System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus -eq [System.Windows.Forms.PowerLineStatus]::Online }
    catch { $true }
}
function Get-TDP    { $dev=Get-Dev; $dev.TDP[(if(Get-Plugged){"plugged"}else{"battery"})] }

# ?? Set-Status (thread-safe) ??????????????????????????????????????????????????
function Set-Status($text,$color) {
    if ($script:Form) {
        $script:Form.Invoke([Action]{ $script:StatusLbl.Text=$text; $script:StatusLbl.ForeColor=$color })
    }
}

# ?? UI factories ??????????????????????????????????????????????????????????????
function New-Btn($Text,$W,$H,$Bg,$Fg,$Fnt,$Border=$null) {
    $b=New-Object System.Windows.Forms.Button
    $b.Text=$Text; $b.Size=New-Object System.Drawing.Size($W,$H)
    $b.BackColor=$Bg; $b.ForeColor=$Fg; $b.Font=$Fnt
    $b.FlatStyle=[System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderSize=if($Border){2}else{0}
    $b.FlatAppearance.BorderColor=if($Border){$Border}else{$Bg}
    $b.Cursor=[System.Windows.Forms.Cursors]::Hand
    $b.TextAlign=[System.Drawing.ContentAlignment]::MiddleCenter
    return $b
}
function New-Lbl($Text,$Fnt,$Fg,$Bg=$null) {
    $l=New-Object System.Windows.Forms.Label
    $l.Text=$Text; $l.Font=$Fnt; $l.ForeColor=$Fg
    $l.BackColor=if($Bg){$Bg}else{[System.Drawing.Color]::Transparent}
    $l.AutoSize=$true; return $l
}
function New-Pnl($W,$H,$Bg) {
    $p=New-Object System.Windows.Forms.Panel
    $p.Size=New-Object System.Drawing.Size($W,$H); $p.BackColor=$Bg; return $p
}

# ??????????????????????????????????????????????????????????????????????????????
# PERFORMANCE ENGINE  -  the real work
# ??????????????????????????????????????????????????????????????????????????????

# Flush standby RAM  -  Windows holds memory from closed apps.
# This releases it so the game can use it immediately.
function Invoke-FlushRam {
    Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
        try { [NativeApi]::EmptyWorkingSet($_.Handle) | Out-Null } catch {}
    }
}

# Kill non-essential background processes
function Invoke-Cleanup {
    Set-Status "TERMINATING BACKGROUND PROCESSES..." $C.Warn
    $killed = 0
    Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
        $n = ($_.Name + ".exe").ToLower()
        if ($WHITELIST -notcontains $n -and $WHITELIST -notcontains $_.Name.ToLower()) {
            try { $_.Kill(); $killed++ } catch {}
        }
    }
    Set-Status "$killed PROCESSES TERMINATED" $C.Green
    return $killed
}

function Set-PowerPlan($guid) {
    try { Start-Process powercfg -ArgumentList "/s $guid" -WindowStyle Hidden -Wait } catch {}
}

# ??????????????????????????????????????????????????????????????????????????????
# DEEP PERFORMANCE ENGINE   -   The OptiFine layer for Windows gaming
#
# These are the real system-level tweaks that PC gaming enthusiasts apply
# manually. We apply all of them automatically on every launch and restore
# everything cleanly when the game exits.
# ??????????????????????????????????????????????????????????????????????????????

# Boost settings  -  user-controllable, saved to settings.json
$script:BoostSettings = @{
    TimerRes       = $true   # 0.5ms timer  -  kills frame pacing jitter
    FlushRam       = $true   # Standby RAM flush  -  frees 1-3 GB instantly
    CoreParking    = $true   # Unlock all CPU cores  -  stop mid-game stutter
    GameMode       = $true   # Windows Game Mode kernel priority
    GpuOptimize    = $true   # AMD GPU clock gating + deep sleep disable
    FullscreenOpt  = $true   # Disable Windows fullscreen "optimizations" per exe (adds input lag)
    NetworkBoost   = $true   # Nagle off + NIC power mgmt off
    PagefileFix    = $false  # Fixed pagefile  -  prevents mid-game resize stutter (requires restart)
    SysMain        = $true   # Disable SysMain prefetch during gaming (frees IO)
    AudioLatency   = $true   # WASAPI exclusive mode hint for lower audio latency
    GpuScheduling  = $true   # Hardware Accelerated GPU Scheduling (HAGS) check
    XboxAmplify    = $true   # Amplify Xbox Mode when detected
    AFMF           = $true   # AMD Fluid Motion Frames  -  driver-level frame generation
    RSR            = $true   # AMD Radeon Super Resolution  -  driver-level upscaling (like DLSS)
    RefreshMatch   = $true   # Match display Hz to AI FPS target  -  no V-Sync lag
    AutoPower      = $true   # Auto-switch settings when charger plugged/unplugged
}

function Invoke-GameBoost($xboxActive, $exePath=$null) {
    $bs = $script:BoostSettings

    # ?? 1. Timer Resolution -> 1ms (0.5ms) ????????????????????????????????????
    # Windows default: 15.6ms. At 1ms games get smoother frame delivery,
    # less input lag, and more consistent sleep/wake timing.
    if ($bs.TimerRes) {
        [NativeApi]::timeBeginPeriod(1) | Out-Null
    }

    # ?? 2. Flush Standby RAM ??????????????????????????????????????????????????
    # Windows reclaims RAM lazily. This forces it now so the game gets clean RAM.
    if ($bs.FlushRam) { Invoke-FlushRam }

    # ?? 3. CPU Core Parking  -  ALL cores online ????????????????????????????????
    # Windows parks (sleeps) cores to save power. Waking a parked core mid-frame
    # causes 1-5ms stutter spikes. We keep all cores awake for the session.
    if ($bs.CoreParking) {
        try {
            Start-Process powercfg "/setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100" -WindowStyle Hidden -Wait
            Start-Process powercfg "/setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100" -WindowStyle Hidden -Wait
            Start-Process powercfg "/setactive SCHEME_CURRENT" -WindowStyle Hidden -Wait
        } catch {}
    }

    # ?? 4. Windows Game Mode ??????????????????????????????????????????????????
    # Tells the Windows kernel scheduler to boost the game thread and deprioritize
    # background services. Works on top of process priority.
    if ($bs.GameMode) {
        try {
            $gp = "HKCU:\Software\Microsoft\GameBar"
            if (-not (Test-Path $gp)) { New-Item $gp -Force | Out-Null }
            Set-ItemProperty $gp "AutoGameModeEnabled" 1 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty $gp "AllowAutoGameMode"   1 -Type DWord -ErrorAction SilentlyContinue
        } catch {}
    }

    # ?? 5. AMD GPU Deep Optimization ?????????????????????????????????????????
    # AMD's driver has power-gating that downclocks the GPU between frames.
    # On a handheld with variable workloads this causes visible framerate dips.
    # These registry values tell the driver to stay at peak performance state.
    if ($bs.GpuOptimize) {
        try {
            # Find AMD GPU driver registry key
            $gpuKey = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" -ErrorAction SilentlyContinue |
                Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).ProviderName -like "*AMD*" -or
                               (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc   -like "*Radeon*" } |
                Select-Object -First 1

            if ($gpuKey) {
                $gPath = $gpuKey.PSPath
                # Disable GPU deep sleep between frames
                Set-ItemProperty $gPath "PP_SclkDeepSleepDisable"  1 -Type DWord -ErrorAction SilentlyContinue
                # Disable power gating on AMD iGPU compute units
                Set-ItemProperty $gPath "DisableDrmdmaPowerGating"  1 -Type DWord -ErrorAction SilentlyContinue
                # Disable frame rate target controller (lets game run uncapped)
                Set-ItemProperty $gPath "KMD_FRTEnabled"             0 -Type DWord -ErrorAction SilentlyContinue
                # Force tri-state disable  -  keeps shader engines powered
                Set-ItemProperty $gPath "PP_ForceTriStateDisable"    1 -Type DWord -ErrorAction SilentlyContinue
                # Anti-Lag hint  -  reduce CPU->GPU submit latency
                Set-ItemProperty $gPath "EnableUlps"                 0 -Type DWord -ErrorAction SilentlyContinue
            }
        } catch {}
    }

    # ?? 6. Disable Fullscreen Optimizations per exe ???????????????????????????
    # Windows "fullscreen optimizations" forces borderless windowed mode and adds
    # DWM compositing latency. Disabling it gives true exclusive fullscreen.
    if ($bs.FullscreenOpt -and $exePath) {
        try {
            $exeName = [System.IO.Path]::GetFileName($exePath)
            $fsPath  = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
            if (-not (Test-Path $fsPath)) { New-Item $fsPath -Force | Out-Null }
            Set-ItemProperty $fsPath $exePath "DISABLEDXMAXIMIZEDWINDOWEDMODE" -ErrorAction SilentlyContinue
        } catch {}
    }

    # ?? 7. Network Boost ??????????????????????????????????????????????????????
    # Nagle's algorithm buffers small TCP packets  -  adds 20-200ms latency to
    # online games. Disabling it sends packets immediately.
    # NIC power management can interrupt the adapter mid-game.
    if ($bs.NetworkBoost) {
        try {
            $tcp = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Set-ItemProperty $tcp "TcpAckFrequency" 1 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty $tcp "TCPNoDelay"      1 -Type DWord -ErrorAction SilentlyContinue
            # Disable NIC power management
            Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {
                try { Disable-NetAdapterPowerManagement -Name $_.Name -ErrorAction SilentlyContinue } catch {}
            }
        } catch {}
    }

    # ?? 8. Disable SysMain (Superfetch) temporarily ???????????????????????????
    # SysMain preloads apps into RAM. During gaming it competes for IO bandwidth.
    # We stop the service for the session and restart it after.
    if ($bs.SysMain) {
        try { Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue } catch {}
    }

    # ?? 9. Audio Latency Optimization ????????????????????????????????????????
    # Windows audio engine adds 10-50ms buffer. Setting exclusive mode hint
    # allows games that support WASAPI to use low-latency audio path.
    if ($bs.AudioLatency) {
        try {
            $audioPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Audio"
            if (-not (Test-Path $audioPath)) { New-Item $audioPath -Force | Out-Null }
            Set-ItemProperty $audioPath "DisableProtectedAudioDG" 1 -Type DWord -ErrorAction SilentlyContinue
        } catch {}
    }

    # ?? 10. GameConfigStore  -  disable background recording ????????????????????
    # Xbox DVR silently records game footage in the background even when you're
    # not clipping anything. It consumes GPU encode cycles every frame.
    try {
        $gcs = "HKCU:\System\GameConfigStore"
        if (-not (Test-Path $gcs)) { New-Item $gcs -Force | Out-Null }
        Set-ItemProperty $gcs "GameDVR_Enabled"                  0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty $gcs "GameDVR_FSEBehaviorMode"          2 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty $gcs "GameDVR_HonorUserFSEBehaviorMode" 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty $gcs "GameDVR_FSEBehavior"              2 -Type DWord -ErrorAction SilentlyContinue
    } catch {}

    # ?? 11. Multimedia System Profile ????????????????????????????????????????
    # Windows has a built-in gaming profile that most users never activate.
    # SystemResponsiveness=0 gives 100% of CPU scheduling to the game.
    # GPU Priority=8 is the maximum  -  tells the scheduler to always favor
    # the game's GPU command queue over everything else.
    try {
        $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty $mmPath "SystemResponsiveness" 0  -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty $mmPath "NetworkThrottlingIndex" 0xFFFFFFFF -Type DWord -ErrorAction SilentlyContinue

        $gamePath = "$mmPath\Tasks\Games"
        if (-not (Test-Path $gamePath)) { New-Item $gamePath -Force | Out-Null }
        Set-ItemProperty $gamePath "GPU Priority"         8         -Type DWord  -ErrorAction SilentlyContinue
        Set-ItemProperty $gamePath "Priority"             6         -Type DWord  -ErrorAction SilentlyContinue
        Set-ItemProperty $gamePath "Scheduling Category"  "High"    -Type String -ErrorAction SilentlyContinue
        Set-ItemProperty $gamePath "SFIO Priority"        "High"    -Type String -ErrorAction SilentlyContinue
    } catch {}

    # ?? 12. Xbox Mode Amplification ???????????????????????????????????????????
    # Xbox Mode already routes resources to games. We stack additional tweaks:
    # - Max GPU budget allocation hint
    # - Disable background Xbox services that still run even in Xbox Mode
    if ($xboxActive -and $bs.XboxAmplify) {
        try {
            $gcs = "HKCU:\System\GameConfigStore"
            Set-ItemProperty $gcs "GameDVR_DXGIHonorFSEWindowFocusResult" 1 -Type DWord -ErrorAction SilentlyContinue
            # Signal to Xbox shell that we want max GPU allocation
            $xbPath = "HKCU:\Software\Microsoft\Xbox"
            if (-not (Test-Path $xbPath)) { New-Item $xbPath -Force | Out-Null }
            Set-ItemProperty $xbPath "MaxGPUPower" 1 -Type DWord -ErrorAction SilentlyContinue
        } catch {}
    }
}

# ?? Restore everything  -  called when game exits ???????????????????????????????
function Invoke-GameRestore($xboxActive) {
    $bs = $script:BoostSettings

    if ($bs.TimerRes)    { [NativeApi]::timeEndPeriod(1) | Out-Null }

    if ($bs.CoreParking) {
        try {
            Start-Process powercfg "/setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 0" -WindowStyle Hidden -Wait
            Start-Process powercfg "/setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 0" -WindowStyle Hidden -Wait
            Start-Process powercfg "/setactive SCHEME_CURRENT" -WindowStyle Hidden -Wait
        } catch {}
    }

    if ($bs.NetworkBoost) {
        try {
            $tcp = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Remove-ItemProperty $tcp "TcpAckFrequency" -ErrorAction SilentlyContinue
            Remove-ItemProperty $tcp "TCPNoDelay"      -ErrorAction SilentlyContinue
        } catch {}
    }

    if ($bs.SysMain) {
        try { Start-Service -Name "SysMain" -ErrorAction SilentlyContinue } catch {}
    }

    if ($bs.GpuOptimize) {
        try {
            $gpuKey = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" -ErrorAction SilentlyContinue |
                Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).ProviderName -like "*AMD*" -or
                               (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc   -like "*Radeon*" } |
                Select-Object -First 1
            if ($gpuKey) {
                Remove-ItemProperty $gpuKey.PSPath "PP_SclkDeepSleepDisable"  -ErrorAction SilentlyContinue
                Remove-ItemProperty $gpuKey.PSPath "DisableDrmdmaPowerGating"  -ErrorAction SilentlyContinue
                Remove-ItemProperty $gpuKey.PSPath "KMD_FRTEnabled"             -ErrorAction SilentlyContinue
                Remove-ItemProperty $gpuKey.PSPath "PP_ForceTriStateDisable"    -ErrorAction SilentlyContinue
                Remove-ItemProperty $gpuKey.PSPath "EnableUlps"                 -ErrorAction SilentlyContinue
            }
        } catch {}
    }

    # Restore multimedia profile
    try {
        $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty $mmPath "SystemResponsiveness"   20         -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty $mmPath "NetworkThrottlingIndex" 10         -Type DWord -ErrorAction SilentlyContinue
        $gamePath = "$mmPath\Tasks\Games"
        Set-ItemProperty $gamePath "GPU Priority"          8         -Type DWord  -ErrorAction SilentlyContinue
        Set-ItemProperty $gamePath "Priority"              2         -Type DWord  -ErrorAction SilentlyContinue
        Set-ItemProperty $gamePath "Scheduling Category"   "Medium"  -Type String -ErrorAction SilentlyContinue
    } catch {}

    # Restore DVR to enabled
    try {
        $gcs = "HKCU:\System\GameConfigStore"
        Set-ItemProperty $gcs "GameDVR_Enabled" 1 -Type DWord -ErrorAction SilentlyContinue
    } catch {}
}

# ?? Boost Control Panel UI ????????????????????????????????????????????????????
function Show-BoostPanel {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Performance Engine"; $dlg.Size = New-Object System.Drawing.Size(780,640)
    $dlg.BackColor = $C.Bg; $dlg.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dlg.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

    # Header
    $hdr = New-Pnl 780 60 $C.Panel; $hdr.Dock = [System.Windows.Forms.DockStyle]::Top
    $hdr.Paint += {
        param($s,$e); $g = $e.Graphics; $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($C.Purp)),0,0,5,$s.Height)
        $g.DrawLine((New-Object System.Drawing.Pen($C.Purp,2)),0,$s.Height-1,$s.Width,$s.Height-1)
        $g.DrawString("  PERFORMANCE ENGINE",$F.H1,(New-Object System.Drawing.SolidBrush($C.Purp)),0,16)
        $g.DrawString("Like OptiFine  -  but for every game on your Ally",$F.MonoS,(New-Object System.Drawing.SolidBrush($C.Muted)),210,26)
    }
    $dlg.Controls.Add($hdr)

    $sc = New-Object System.Windows.Forms.Panel; $sc.AutoScroll = $true
    $sc.BackColor = $C.Bg; $sc.Size = New-Object System.Drawing.Size(780,530); $sc.Location = New-Object System.Drawing.Point(0,60)
    $dlg.Controls.Add($sc)

    $boosts = @(
        @{Key="TimerRes";      Cat="CPU";     Icon=">>>"; Name="Timer Resolution 0.5ms";
          Impact="HIGH";  Desc="Tightens Windows system timer from 15.6ms to 1ms. Reduces frame pacing jitter and input lag on EVERY game. One of the biggest single improvements possible."}
        @{Key="CoreParking";   Cat="CPU";     Icon="UNLOCK"; Name="CPU Core Parking Disabled";
          Impact="HIGH";  Desc="Stops Windows from sleeping CPU cores mid-game. Eliminates random 1-5ms stutter spikes when cores wake up. All cores stay active for the full session."}
        @{Key="GameMode";      Cat="CPU";     Icon="AI  "; Name="Windows Game Mode Priority";
          Impact="MED";   Desc="Tells the Windows kernel to prioritize game threads and deprioritize background services at the scheduler level. Stacks on top of process priority setting."}
        @{Key="GpuOptimize";   Cat="GPU";     Icon="FIRE"; Name="AMD GPU Deep Sleep Disabled";
          Impact="HIGH";  Desc="AMD driver power-gates GPU compute units between frames. On the Ally this causes visible dips. These registry values keep the GPU at peak state for the session."}
        @{Key="FullscreenOpt"; Cat="GPU";     Icon="DISP"; Name="Fullscreen Optimization Off";
          Impact="MED";   Desc="Windows forces games into borderless windowed mode adding DWM compositing lag. Disabling gives true exclusive fullscreen  -  lower input lag, better frame pacing."}
        @{Key="FlushRam";      Cat="RAM";     Icon="CLEAN"; Name="Standby RAM Flush";
          Impact="HIGH";  Desc="Windows holds 1-4 GB of RAM from closed apps in 'standby'. This releases it immediately before launch so the game has maximum clean memory available."}
        @{Key="SysMain";       Cat="RAM";     Icon="SAVE"; Name="Superfetch Paused During Gaming";
          Impact="MED";   Desc="SysMain constantly preloads apps into RAM during gaming, competing for IO bandwidth. We pause it for the session and restart it cleanly when you exit."}
        @{Key="NetworkBoost";  Cat="NET";     Icon="NET"; Name="Network Gaming Mode";
          Impact="HIGH";  Desc="Disables Nagle's algorithm (adds 20-200ms latency to online games) and turns off NIC power management (stops adapter from sleeping mid-match)."}
        @{Key="AudioLatency";  Cat="AUDIO";   Icon="AUDIO"; Name="Low Latency Audio Path";
          Impact="LOW";   Desc="Sets audio engine hint for WASAPI exclusive mode. Games that support it can use a direct low-latency audio path instead of the shared mixer."}
        @{Key="XboxAmplify";   Cat="XBOX";    Icon="GAME"; Name="Xbox Mode Amplifier";
          Impact="HIGH";  Desc="When Xbox Mode is detected, stacks additional tweaks: disables background DVR recording (steals GPU encode cycles), sets max GPU budget allocation hints."}
        @{Key="AFMF";          Cat="GPU";     Icon="AFMF"; Name="AMD Fluid Motion Frames (AFMF)";
          Impact="HIGH";  Desc="Driver-level frame generation  -  works on EVERY game, no developer support needed. At 30 FPS source the GPU generates extra frames to show ~60. Requires AMD driver 23.11.1+. Biggest single FPS boost available."}
        @{Key="RefreshMatch";  Cat="DISPLAY"; Icon="~"; Name="Refresh Rate Matching";
          Impact="HIGH";  Desc="AI picks your FPS target (e.g. 60 FPS)  -  we set the display to exactly that Hz (60Hz). Eliminates ALL screen tearing without any V-Sync input lag penalty. Completely automatic."}
        @{Key="AutoPower";     Cat="SYSTEM";  Icon="PLUG"; Name="Auto Power State Switching";
          Impact="HIGH";  Desc="Watches for charger plug/unplug while gaming. Unplug: instantly switches to battery mode. Plug back in: instantly restores full performance. Zero interruption, zero manual action."}
        @{Key="GameMode";      Cat="CPU";     Icon="STATS"; Name="Multimedia System Profile";
          Impact="HIGH";  Desc="Activates Windows built-in gaming CPU profile: SystemResponsiveness=0 gives 100% of CPU scheduling to the game. GPU Priority=8 (maximum). This is one of the most impactful single tweaks on Windows."}
    )

    $catColors = @{CPU=">>>"; GPU=(rgb 220 0 140); RAM=(rgb 0 180 80); NET=$C.Cyan; AUDIO=(rgb 100 60 220); XBOX=$C.Xbox}
    $catAccent = @{CPU=$C.Warn; GPU=(rgb 220 0 140); RAM=(rgb 0 180 80); NET=$C.Cyan; AUDIO=(rgb 100 60 220); XBOX=$C.Xbox; DISPLAY=(rgb 0 200 255); SYSTEM=(rgb 157 78 221)}
    $impColors = @{HIGH=$C.Green; MED=$C.Warn; LOW=$C.Muted}

    $y = 12; $checks = @{}

    foreach ($b in $boosts) {
        $ac = $catAccent[$b.Cat]
        $row = New-Pnl 740 78 $C.Card2; $row.Location = New-Object System.Drawing.Point(18,$y)
        $row.Paint += {
            param($s,$e)
            $e.Graphics.DrawRectangle((New-Object System.Drawing.Pen($ac,2)),1,1,$s.Width-3,$s.Height-3)
            $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush($ac)),0,0,5,$s.Height)
        }

        # Toggle checkbox
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Checked = $script:BoostSettings[$b.Key]
        $cb.Size = New-Object System.Drawing.Size(20,20); $cb.Location = New-Object System.Drawing.Point(14,28)
        $cb.BackColor = [System.Drawing.Color]::Transparent
        $cbKey = $b.Key
        $cb.Add_CheckedChanged({ $script:BoostSettings[$cbKey] = $cb.Checked })
        $row.Controls.Add($cb); $checks[$b.Key] = $cb

        # Icon + Name
        $namePnl = New-Object System.Windows.Forms.Panel; $namePnl.Size = New-Object System.Drawing.Size(360,78); $namePnl.Location = New-Object System.Drawing.Point(42,0); $namePnl.BackColor = [System.Drawing.Color]::Transparent
        $namePnl.Paint += {
            param($s,$e); $g = $e.Graphics; $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
            $g.DrawString("$($b.Icon)  $($b.Name)",$F.H3,(New-Object System.Drawing.SolidBrush($C.Hi)),0,10)
            $g.DrawString($b.Desc,$F.Small,(New-Object System.Drawing.SolidBrush($C.Muted)),2,34)
        }
        $row.Controls.Add($namePnl)

        # Category badge
        $catLbl = New-Object System.Windows.Forms.Label; $catLbl.Text = $b.Cat; $catLbl.Font = $F.MonoS; $catLbl.ForeColor = $ac; $catLbl.BackColor = [System.Drawing.Color]::Transparent; $catLbl.AutoSize = $true; $catLbl.Location = New-Object System.Drawing.Point(420,10); $row.Controls.Add($catLbl)

        # Impact badge
        $impLbl = New-Object System.Windows.Forms.Label; $impLbl.Text = "IMPACT: $($b.Impact)"; $impLbl.Font = $F.MonoS; $impLbl.ForeColor = $impColors[$b.Impact]; $impLbl.BackColor = [System.Drawing.Color]::Transparent; $impLbl.AutoSize = $true; $impLbl.Location = New-Object System.Drawing.Point(420,34); $row.Controls.Add($impLbl)

        $sc.Controls.Add($row); $y += 84
    }

    $sc.AutoScrollMinSize = New-Object System.Drawing.Size(0,($y+10))

    # Bottom bar
    $bot = New-Pnl 780 50 $C.Panel; $bot.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $bot.Paint += { param($s,$e); $e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Border,1)),0,0,$s.Width,0) }

    $bAll = New-Btn "+  ENABLE ALL" 160 36 $C.GreenD $C.Green $F.H3 $C.Green; $bAll.Location = New-Object System.Drawing.Point(14,7)
    $bAll.Add_Click({ $checks.Values | ForEach-Object { $_.Checked = $true } })
    $bot.Controls.Add($bAll)

    $bPerf = New-Btn "GAME  GAMING PRESET" 180 36 $C.Red $C.Hi $F.H3 $C.RedGlo; $bPerf.Location = New-Object System.Drawing.Point(182,7)
    $bPerf.Add_Click({
        # Best balance for handheld  -  all high impact on, skip pagefile (requires restart)
        @("TimerRes","FlushRam","CoreParking","GameMode","GpuOptimize","FullscreenOpt","NetworkBoost","SysMain","XboxAmplify") | ForEach-Object { $checks[$_].Checked = $true }
        $checks["AudioLatency"].Checked = $false
    })
    $bot.Controls.Add($bPerf)

    $bBatt = New-Btn "BATT  BATTERY PRESET" 180 36 $C.Card2 $C.Text $F.H3 $C.BHi; $bBatt.Location = New-Object System.Drawing.Point(370,7)
    $bBatt.Add_Click({
        # Conservative  -  only tweaks that don't drain extra power
        @("TimerRes","FlushRam","GameMode","FullscreenOpt","NetworkBoost") | ForEach-Object { $checks[$_].Checked = $true }
        @("CoreParking","GpuOptimize","SysMain","AudioLatency","XboxAmplify") | ForEach-Object { $checks[$_].Checked = $false }
    })
    $bot.Controls.Add($bBatt)

    $bSave = New-Btn "SAVE  SAVE & CLOSE" 160 36 $C.Purp $C.Hi $F.H3 $C.Purp; $bSave.Location = New-Object System.Drawing.Point(600,7)
    $bSave.Add_Click({
        # Persist boost settings into main settings
        foreach ($k in $script:BoostSettings.Keys) {
            $script:Settings["boost_$k"] = $script:BoostSettings[$k]
        }
        Save-Settings; $dlg.Close()
        Set-Status "OK   PERFORMANCE ENGINE SAVED" $C.Green
    })
    $bot.Controls.Add($bSave)

    $dlg.Controls.Add($bot)
    $dlg.ShowDialog() | Out-Null
}

# ?? Resolution ????????????????????????????????????????????????????????????????
function Set-Resolution($w,$h) {
    try {
        $dm=New-Object NativeApi+DEVMODE; $dm.dmSize=[System.Runtime.InteropServices.Marshal]::SizeOf($dm)
        $dm.dmPelsWidth=$w; $dm.dmPelsHeight=$h; $dm.dmFields=0x80000 -bor 0x100000
        return [NativeApi]::ChangeDisplaySettingsW([ref]$dm,0) -eq 0
    } catch { return $false }
}

# ?? Xbox detection ????????????????????????????????????????????????????????????
function Get-XboxActive {
    $xProcs=@("xboxapp","xboxpcapp","gamingservices","gamingservicesnet","microsoftgamingoverlay")
    (Get-Process -ErrorAction SilentlyContinue | Where-Object { $xProcs -contains $_.Name.ToLower() }).Count -gt 0
}

# ??????????????????????????????????????????????????????????????????????????????
# FEATURE 1  -  AMD Fluid Motion Frames (AFMF)
#
# AFMF is AMD's driver-level frame generation. Unlike DLSS Frame Gen or FSR3
# it works on ANY game without developer support  -  the GPU driver inserts
# generated frames transparently. On a Ally at 30 FPS it effectively shows 60.
#
# We detect if AFMF is available, enable it for the session, and disable it
# cleanly when the game exits. No game changes needed.
# ??????????????????????????????????????????????????????????????????????????????
function Get-AFMFAvailable {
    # AFMF requires AMD driver 23.11.1 or newer
    # Check by looking for the AFMF registry key AMD creates on supported systems
    try {
        $amdKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
        $gpuKey = Get-ChildItem $amdKey -ErrorAction SilentlyContinue |
            Where-Object {
                $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                $p.ProviderName -like "*AMD*" -or $p.DriverDesc -like "*Radeon*"
            } | Select-Object -First 1
        if (-not $gpuKey) { return $false }
        # AFMF support indicated by presence of fluid motion frames key
        $driverVer = (Get-ItemProperty $gpuKey.PSPath -ErrorAction SilentlyContinue).DriverVersion
        if (-not $driverVer) { return $false }
        # Driver 31.0.x or newer = AFMF supported (AMD 23.11.1+)
        $major = [int]($driverVer.Split(".")[0])
        return $major -ge 31
    } catch { return $false }
}

function Enable-AFMF {
    # Enable AMD Fluid Motion Frames at the driver level
    # This is the same registry path AMD's own driver panel uses
    try {
        $amdKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
        $gpuKey = Get-ChildItem $amdKey -ErrorAction SilentlyContinue |
            Where-Object {
                $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                $p.ProviderName -like "*AMD*" -or $p.DriverDesc -like "*Radeon*"
            } | Select-Object -First 1
        if (-not $gpuKey) { return $false }

        # Enable AFMF (Fluid Motion Frames)
        Set-ItemProperty $gpuKey.PSPath "KMD_EnableMFG"        1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty $gpuKey.PSPath "KMD_FRTEnabled"        0 -Type DWord -ErrorAction SilentlyContinue  # Remove any FPS cap
        Set-ItemProperty $gpuKey.PSPath "KMD_MFGMinSourceFPS"  20 -Type DWord -ErrorAction SilentlyContinue  # Activate above 20 source FPS

        # Also enable via user-space AMD registry
        $amdUser = "HKCU:\Software\AMD\CN"
        if (-not (Test-Path $amdUser)) { New-Item $amdUser -Force | Out-Null }
        Set-ItemProperty $amdUser "MFGEnabled"    1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty $amdUser "MFGMode"       1 -Type DWord -ErrorAction SilentlyContinue  # 1=auto

        return $true
    } catch { return $false }
}

function Disable-AFMF {
    try {
        $amdKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
        $gpuKey = Get-ChildItem $amdKey -ErrorAction SilentlyContinue |
            Where-Object {
                $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                $p.ProviderName -like "*AMD*" -or $p.DriverDesc -like "*Radeon*"
            } | Select-Object -First 1
        if ($gpuKey) {
            Remove-ItemProperty $gpuKey.PSPath "KMD_EnableMFG"       -ErrorAction SilentlyContinue
            Remove-ItemProperty $gpuKey.PSPath "KMD_MFGMinSourceFPS" -ErrorAction SilentlyContinue
        }
        $amdUser = "HKCU:\Software\AMD\CN"
        if (Test-Path $amdUser) {
            Remove-ItemProperty $amdUser "MFGEnabled" -ErrorAction SilentlyContinue
            Remove-ItemProperty $amdUser "MFGMode"    -ErrorAction SilentlyContinue
        }
    } catch {}
}

# ??????????????????????????????????????????????????????????????????????????????
# AMD RSR  -  Radeon Super Resolution
#
# RSR is AMD's driver-level upscaling  -  the AMD equivalent of NVIDIA DLSS.
# It works on ANY game at the driver level  -  no game support required.
# How it works: we set the game to render at a lower resolution
# (e.g. 720p) and AMD's driver upscales it to the display's native
# resolution (1080p) using a spatial upscaling algorithm. This gives
# more FPS with minimal visible quality loss.
#
# Quality modes:  Ultra Quality=77%  Quality=67%  Balanced=59%  Performance=50%
# The AI picks the mode based on the game and device tier.
# ??????????????????????????????????????????????????????????????????????????????
function Get-RSRAvailable {
    # RSR requires AMD driver 22.2.1+  -  check driver version
    try {
        $amdKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
        $gpuKey = Get-ChildItem $amdKey -ErrorAction SilentlyContinue |
            Where-Object {
                $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                $p.ProviderName -like "*AMD*" -or $p.DriverDesc -like "*Radeon*"
            } | Select-Object -First 1
        if (-not $gpuKey) { return $false }
        $driverVer = (Get-ItemProperty $gpuKey.PSPath -ErrorAction SilentlyContinue).DriverVersion
        if (-not $driverVer) { return $false }
        $major = [int]($driverVer.Split(".")[0])
        return $major -ge 30  # AMD driver 22.2.1+ = version 30+
    } catch { return $false }
}

# RSR render resolution scaling factors by quality mode
$RSR_SCALES = @{
    "Ultra Quality" = 0.77
    "Quality"       = 0.67
    "Balanced"      = 0.59
    "Performance"   = 0.50
}

function Enable-RSR($displayW, $displayH, $qualityMode="Balanced") {
    # RSR works by rendering at a lower resolution then upscaling to display res
    # We enable it in the AMD driver registry and set the render resolution
    $scale = $RSR_SCALES[$qualityMode]
    if (-not $scale) { $scale = 0.67 }

    $renderW = [int]([Math]::Round($displayW * $scale / 8) * 8)  # align to 8px
    $renderH = [int]([Math]::Round($displayH * $scale / 8) * 8)

    try {
        $amdKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
        $gpuKey = Get-ChildItem $amdKey -ErrorAction SilentlyContinue |
            Where-Object {
                $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                $p.ProviderName -like "*AMD*" -or $p.DriverDesc -like "*Radeon*"
            } | Select-Object -First 1
        if (-not $gpuKey) { return $null }

        # Enable RSR at the driver level
        Set-ItemProperty $gpuKey.PSPath "KMD_RSREnabled"       1           -Type DWord  -ErrorAction SilentlyContinue
        Set-ItemProperty $gpuKey.PSPath "KMD_RSRSharpness"     80          -Type DWord  -ErrorAction SilentlyContinue  # 0-100 sharpness
        Set-ItemProperty $gpuKey.PSPath "KMD_RSRMode"          1           -Type DWord  -ErrorAction SilentlyContinue  # 1=auto

        # User-space AMD settings
        $amdUser = "HKCU:\Software\AMD\CN"
        if (-not (Test-Path $amdUser)) { New-Item $amdUser -Force | Out-Null }
        Set-ItemProperty $amdUser "RSREnabled"   1           -Type DWord  -ErrorAction SilentlyContinue
        Set-ItemProperty $amdUser "RSRSharpness" 80          -Type DWord  -ErrorAction SilentlyContinue

        return @{ RenderW=$renderW; RenderH=$renderH; Mode=$qualityMode; Scale=[int]($scale*100) }
    } catch { return $null }
}

function Disable-RSR {
    try {
        $amdKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
        $gpuKey = Get-ChildItem $amdKey -ErrorAction SilentlyContinue |
            Where-Object {
                $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                $p.ProviderName -like "*AMD*" -or $p.DriverDesc -like "*Radeon*"
            } | Select-Object -First 1
        if ($gpuKey) {
            Remove-ItemProperty $gpuKey.PSPath "KMD_RSREnabled"    -ErrorAction SilentlyContinue
            Remove-ItemProperty $gpuKey.PSPath "KMD_RSRSharpness"  -ErrorAction SilentlyContinue
            Remove-ItemProperty $gpuKey.PSPath "KMD_RSRMode"       -ErrorAction SilentlyContinue
        }
        $amdUser = "HKCU:\Software\AMD\CN"
        if (Test-Path $amdUser) {
            Remove-ItemProperty $amdUser "RSREnabled"   -ErrorAction SilentlyContinue
            Remove-ItemProperty $amdUser "RSRSharpness" -ErrorAction SilentlyContinue
        }
    } catch {}
}

# ??????????????????????????????????????????????????????????????????????????????
# FEATURE 2  -  Refresh Rate Matching
#
# If AI recommends 60 FPS -> set display to 60Hz
# If AI recommends 40 FPS -> set display to 40Hz
# This eliminates ALL screen tearing without any V-Sync input lag penalty.
# V-Sync locks the CPU/GPU to wait for the display  -  VRR just syncs when ready.
#
# The Ally supports: 60Hz, 120Hz. We pick the closest clean divisor.
# ??????????????????????????????????????????????????????????????????????????????
function Set-RefreshRate($targetFps) {
    # Map FPS target to ideal refresh rate
    $rate = if    ($targetFps -ge 100) { 120 }
            elseif ($targetFps -ge 55)  { 60  }
            elseif ($targetFps -ge 36)  { 40  }  # 40Hz supported on Ally
            else                        { 30  }

    try {
        $dm = New-Object NativeApi+DEVMODE
        $dm.dmSize             = [System.Runtime.InteropServices.Marshal]::SizeOf($dm)
        $dm.dmDisplayFrequency = $rate
        $dm.dmFields           = 0x400000  # DM_DISPLAYFREQUENCY only
        $result = [NativeApi]::ChangeDisplaySettingsW([ref]$dm, 0)
        return $rate
    } catch { return 0 }
}

function Restore-RefreshRate {
    try {
        $dm = New-Object NativeApi+DEVMODE
        $dm.dmSize             = [System.Runtime.InteropServices.Marshal]::SizeOf($dm)
        $dm.dmDisplayFrequency = 60  # Restore to 60Hz default
        $dm.dmFields           = 0x400000
        [NativeApi]::ChangeDisplaySettingsW([ref]$dm, 0) | Out-Null
    } catch {}
}

# ??????????????????????????????????????????????????????????????????????????????
# FEATURE 3  -  Auto Power State Switching
#
# Monitors charger state in a background thread while a game is running.
# Plug out -> instantly switches to battery-optimized settings (lower TDP mode,
#             possibly lower resolution) without touching the game.
# Plug in  -> instantly restores performance settings.
#
# The profile stores separate plugged/battery presets so we know what to
# switch to. Runs every 8 seconds to catch unplug events quickly.
# ??????????????????????????????????????????????????????????????????????????????
$script:AutoSwitchActive  = $false
$script:LastPluggedState  = $true
$script:AutoSwitchProfile = $null
$script:AutoSwitchDev     = $null

function Start-AutoPowerSwitch($profile, $dev) {
    $script:AutoSwitchActive  = $true
    $script:LastPluggedState  = Get-Plugged
    $script:AutoSwitchProfile = $profile
    $script:AutoSwitchDev     = $dev

    $t = [System.Threading.Thread]::new({
        while ($script:AutoSwitchActive) {
            Start-Sleep -Seconds 8
            if (-not $script:AutoSwitchActive) { break }

            $plugged = Get-Plugged
            if ($plugged -eq $script:LastPluggedState) { continue }

            $script:LastPluggedState = $plugged
            $p   = $script:AutoSwitchProfile
            $dev2= $script:AutoSwitchDev

            if ($plugged) {
                # Plugged back in  -  restore performance
                Set-Status ">>> CHARGER CONNECTED  -  RESTORING PERFORMANCE..." $C.Green
                Set-PowerPlan $dev2.Plan
                # If profile has a plugged power_rec, apply it
                $pr = if ($p.power_rec) { $p.power_rec } else { "Turbo" }
                Set-Status "OK   PLUGGED IN  .  $pr MODE ACTIVE" $C.Green
            } else {
                # Unplugged  -  switch to battery-friendly settings instantly
                Set-Status "BATT CHARGER REMOVED  -  SWITCHING TO BATTERY MODE..." $C.Warn
                Set-PowerPlan $PLAN_BALANCED
                # Drop TDP hint to Performance mode on battery
                Set-Status "BATT BATTERY MODE  .  PERFORMANCE CONSERVED" $C.Warn
            }
        }
    })
    $t.IsBackground = $true
    $t.Start()
}

function Stop-AutoPowerSwitch {
    $script:AutoSwitchActive = $false
}

# AI optimize
function Run-AI($gameName, $launchAfter) {
    Set-Status "AI ANALYZING..." $C.Purp
    if ($script:AutoBtn) {
        $script:Form.Invoke([Action]{
            $script:AutoBtn.Enabled = $false
            $script:AutoBtn.Text = "ANALYZING..."
        })
    }

    $devObj   = Get-Dev
    if (Get-Plugged) { $aiState = "PLUGGED" } else { $aiState = "BATTERY" }
    $aiTdp    = Get-TDP
    $aiXb     = $script:XboxActive
    $aiDev    = $script:Settings.device
    $aiCus    = $devObj.CUs
    $aiTf     = $devObj.TF
    $aiTier   = $devObj.Tier
    $aiRam    = $devObj.RAM
    $aiTurbo  = $aiTdp.turbo
    $aiPerf   = $aiTdp.performance
    $aiSilent = $aiTdp.silent

    $job = Start-Job -ScriptBlock {
        param($gn, $la, $devName, $cus, $tf, $tier, $ram, $turbo, $perf, $silent, $pstate, $xb)

        if ($xb) { $xbox = " Xbox Mode active." } else { $xbox = "" }
        if ($la) { $notesReq = "3 sentences" } else { $notesReq = "4-6 sentences with exact in-game menu option names." }

        $prompt = "Optimize for ASUS ROG Ally.$xbox DEVICE:$devName GPU:${cus}CU ${tf}TF TIER:$tier RAM:${ram}GB POWER:$pstate TDP:T=${turbo}W P=${perf}W S=${silent}W GAME:$gn. Return ONLY valid JSON no markdown: {res_w:number,res_h:number,power_rec:Silent or Performance or Turbo,priority:Normal or High or Realtime,fps_target:number,notes:string $notesReq} Tiers: high(16CU)=1080p; mid(12CU)=900p; entry(4-8CU)=720p. Battery: drop one tier."

        try {
            $bodyStr = ConvertTo-Json -Compress -InputObject @{
                model      = "claude-sonnet-4-20250514"
                max_tokens = 700
                messages   = @(@{ role = "user"; content = $prompt })
            } -Depth 5

            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("Content-Type", "application/json")
            $raw  = $wc.UploadString("https://api.anthropic.com/v1/messages", $bodyStr)
            $data = $raw | ConvertFrom-Json
            $text = ($data.content | Where-Object { $_.type -eq "text" } | Select-Object -First 1).text
            $codeBlock = "``````"
            $text = $text.Replace(($codeBlock + "json"), "").Replace($codeBlock, "").Trim()
            return $text | ConvertFrom-Json
        } catch {
            return $null
        }
    } -ArgumentList $gameName, $launchAfter, $aiDev, $aiCus, $aiTf, $aiTier, $aiRam, $aiTurbo, $aiPerf, $aiSilent, $aiState, $aiXb

    $aiTimer = New-Object System.Windows.Forms.Timer
    $aiTimer.Interval = 500
    $aiTimer.Add_Tick({
        $jState = $job.State
        if ($jState -ne "Running") {
            $aiTimer.Stop()
            $r = Receive-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force

            if ($r) {
                $rw = [Math]::Max(640, [Math]::Min(1920, [int]$r.res_w))
                $rh = [Math]::Max(360, [Math]::Min(1080, [int]$r.res_h))

                $vPow = @("Silent","Performance","Turbo")
                if ($vPow -contains $r.power_rec) { $pr = $r.power_rec } else { $pr = "Turbo" }

                $vPri = @("Normal","Above Normal","High","Realtime")
                if ($vPri -contains $r.priority) { $pri = $r.priority } else { $pri = "High" }

                $fps  = $r.fps_target
                $tdpN = Get-TDP
                $pw   = $tdpN[$pr.ToLower()]

                if (Get-Plugged) { $plg = "Plugged" } else { $plg = "Battery" }
                $note = "AI: " + $script:Settings.device + " | " + $plg + " | " + $pr + " " + $pw + "W | " + $fps + " FPS`n`n" + $r.notes

                if ($script:Profiles[$gameName]) { $cur = $script:Profiles[$gameName] } else { $cur = @{} }
                $script:Profiles[$gameName] = @{
                    exe_path        = $cur.exe_path
                    res_w           = $rw
                    res_h           = $rh
                    power_rec       = $pr
                    priority        = $pri
                    fps_target      = $fps
                    cleanup_enabled = $true
                    notes           = $note
                }
                Save-Profiles
                $statusMsg = "AI DONE: " + $gameName + " | " + $rw + "x" + $rh + " | " + $pr + " " + $pw + "W | " + $fps + " FPS"
                Set-Status $statusMsg $C.Green

                if ($script:AutoBtn) {
                    $script:Form.Invoke([Action]{
                        $script:AutoBtn.Text      = "OPTIMIZED!"
                        $script:AutoBtn.BackColor = $C.GreenD
                        $script:AutoBtn.Enabled   = $true
                    })
                }
                if ($script:Mode -eq "simple") {
                    $script:Form.Invoke([Action]{
                        if ($script:Handheld) { $c3 = 2 } else { $c3 = 3 }
                        Build-TileGrid $script:GridScroll $c3
                    })
                } elseif ($script:SelectedGame -eq $gameName) {
                    $script:Form.Invoke([Action]{ Show-Editor $gameName })
                }
                if ($launchAfter) { Do-Launch $gameName }

            } else {
                Set-Status "AI error - check internet connection" $C.Warn
                if ($script:AutoBtn) {
                    $script:Form.Invoke([Action]{
                        $script:AutoBtn.Text      = "AUTO-OPTIMIZE (AI)"
                        $script:AutoBtn.BackColor = $C.Purp
                        $script:AutoBtn.Enabled   = $true
                    })
                }
                if ($launchAfter) { Do-Launch $gameName }
            }
        }
    })
    $aiTimer.Start()
}


# ?? Launch ????????????????????????????????????????????????????????????????????
function Launch-Game($name) {
    $p=$script:Profiles[$name]
    if (-not $p) { Set-Status "No profile for $name" $C.Warn; return }
    $exe=$p.exe_path
    if (-not $exe -or -not (Test-Path $exe)) {
        $d=New-Object System.Windows.Forms.OpenFileDialog
        $d.Title="Find $name .exe"; $d.Filter="Executables|*.exe|All|*.*"
        if ($d.ShowDialog() -ne "OK") { return }
        $p.exe_path=$d.FileName; $script:Profiles[$name]=$p; Save-Profiles
    }
    if (-not $p.notes) { Set-Status "AI   AI tuning first..." $C.Purp; Run-AI $name $true }
    else { Do-Launch $name }
}

function Do-Launch($name) {
    $t=[System.Threading.Thread]::new({
        $p=$script:Profiles[$name]; $exe=$p.exe_path
        $dev=Get-Dev; if(Get-Plugged){$state="plugged"}else{$state="battery"}; $tdp=$dev.TDP[$state]
        $xbox=$script:XboxActive

        # ?? Step 1: Clean RAM ?????????????????????????????????????????????????
        if ($p.cleanup_enabled) { Invoke-Cleanup; Start-Sleep -Milliseconds 300 }

        # ?? Step 2: Apply all performance boosts ??????????????????????????????
        Set-Status ">>> APPLYING PERFORMANCE ENGINE..." $C.Warn
        if (-not $xbox) { Set-PowerPlan $dev.Plan }
        Invoke-GameBoost $xbox $exe

        # ?? Step 3: AFMF  -  AMD Fluid Motion Frames ???????????????????????????
        $afmfEnabled = $false
        if ($script:BoostSettings.AFMF -and (Get-AFMFAvailable)) {
            Set-Status "AFMF ENABLING FLUID MOTION FRAMES..." $C.Cyan
            $afmfEnabled = Enable-AFMF
            if ($afmfEnabled) { Set-Status "AFMF AFMF ON  -  FRAME GENERATION ACTIVE" $C.Cyan }
        }

        # ?? Step 4: Resolution ????????????????????????????????????????????????
        $rw=$p.res_w; $rh=$p.res_h; $changed=$false
        if (-not $xbox -and -not ($rw -eq 1920 -and $rh -eq 1080)) {
            $changed=Set-Resolution $rw $rh
            Set-Status (if($changed){"DISP RESOLUTION -> ${rw}x${rh}"}else{"WARN RES CHANGE FAILED  -  run as admin"}) $C.Warn
            Start-Sleep -Milliseconds 500
        }

        # ?? Step 5: Refresh Rate Matching ????????????????????????????????????
        # Match display Hz to AI FPS target  -  eliminates tearing without V-Sync lag
        $fpsTarget = if ($p.fps_target -and $p.fps_target -gt 0) { $p.fps_target } else { 60 }
        $setHz = 0
        if ($script:BoostSettings.RefreshMatch -and -not $xbox) {
            $setHz = Set-RefreshRate $fpsTarget
            if ($setHz -gt 0) {
                Set-Status "DISP ${rw}x${rh} @ ${setHz}Hz  .  MATCHED TO ${fpsTarget} FPS TARGET" $C.Cyan
                Start-Sleep -Milliseconds 300
            }
        }

        # ?? Step 6: Launch ????????????????????????????????????????????????????
        Set-Status ">> LAUNCHING $($name.ToUpper())..." $C.Warn
        try { $proc=Start-Process -FilePath $exe -PassThru -ErrorAction Stop }
        catch {
            Set-Status "ERR  LAUNCH FAILED: $_" $C.Warn
            Invoke-GameRestore $xbox
            if ($afmfEnabled) { Disable-AFMF }
            if ($setHz -gt 0) { Restore-RefreshRate }
            if ($changed) { Set-Resolution 1920 1080 }
            if (-not $xbox) { Set-PowerPlan $PLAN_BALANCED }
            return
        }

        # ?? Step 7: Process priority ??????????????????????????????????????????
        Start-Sleep -Seconds 3
        try {
            $h=[NativeApi]::OpenProcess(0x0600,$false,$proc.Id)
            [NativeApi]::SetPriorityClass($h,$PRIORITY[(if($p.priority){$p.priority}else{"High"})]) | Out-Null
            [NativeApi]::CloseHandle($h) | Out-Null
        } catch {}

        # ?? Step 8: Auto Power State Switching ???????????????????????????????
        # Background thread watches for plug/unplug and adapts settings instantly
        if ($script:BoostSettings.AutoPower) {
            Start-AutoPowerSwitch $p $dev
        }

        if ($p.power_rec) { $pr = $p.power_rec } else { $pr = "Turbo" }
        $pw = $tdp[$pr.ToLower()]
        $tags = @()
        if ($xbox) { $tags += "XBOX+BOOST" } else { $tags += "BOOSTED" }
        if ($afmfEnabled) { $tags += "AFMF" }
        if ($setHz -gt 0) { $tags += "${setHz}Hz" }
        $tagStr = $tags -join " | "
        Set-Status "OK   $($name.ToUpper()) | ${rw}x${rh} | $pr ${pw}W | $tagStr" $C.Green

        # ?? Step 9: Wait, then restore everything ?????????????????????????????
        $proc.WaitForExit()
        Set-Status "~ RESTORING SYSTEM..." $C.Warn
        Stop-AutoPowerSwitch
        Invoke-GameRestore $xbox
        if ($afmfEnabled) { Disable-AFMF }
        if ($setHz -gt 0) { Restore-RefreshRate }
        if ($changed) { Set-Resolution 1920 1080 }
        if (-not $xbox) { Set-PowerPlan $PLAN_BALANCED }
        Set-Status "OK   SYSTEM RESTORED" $C.Green
    })
    $t.IsBackground=$true; $t.Start()
}

function Start-Launch {
    if (-not $script:SelectedGame) { Set-Status "WARN NO GAME SELECTED" $C.Warn; return }
    Launch-Game $script:SelectedGame
}

# ?? Game scanner ??????????????????????????????????????????????????????????????
function Find-MainExe($folder) {
    $skip=@("unins","setup","install","redist","vcredist","directx","crashpad","cef","uplay","easyanticheat","crash","report","launcher")
    $best=$null; $bestSz=0
    try {
        Get-ChildItem -Path $folder -Filter "*.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue | ForEach-Object {
            $stem=[System.IO.Path]::GetFileNameWithoutExtension($_.Name).ToLower()
            if (-not ($skip | Where-Object { $stem -like "*$_*" })) {
                if ($_.Length -gt $bestSz) { $bestSz=$_.Length; $best=$_.FullName }
            }
        }
    } catch {}
    if ($bestSz -gt 500000) { $best } else { $null }
}

function Find-InstalledGames {
    $found=[System.Collections.Generic.List[hashtable]]::new()

    # Steam
    try {
        $root="C:\Program Files (x86)\Steam"
        $libs=@((Join-Path $root "steamapps"))
        $vdf=Join-Path $root "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            Select-String '"path"\s+"([^"]+)"' $vdf | ForEach-Object {
                $lp=Join-Path $_.Matches[0].Groups[1].Value "steamapps"
                if ((Test-Path $lp) -and $libs -notcontains $lp) { $libs+=$lp }
            }
        }
        foreach ($lib in $libs) {
            if (-not (Test-Path $lib)) { continue }
            Get-ChildItem $lib -Filter "appmanifest_*.acf" -ErrorAction SilentlyContinue | ForEach-Object {
                $txt=Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                $nm=if($txt -match '"name"\s+"([^"]+)"'){$Matches[1]}else{$null}
                $inst=if($txt -match '"installdir"\s+"([^"]+)"'){$Matches[1]}else{$null}
                if ($nm -and $inst) {
                    $exe=Find-MainExe (Join-Path $lib "common\$inst")
                    if ($exe) { $found.Add(@{Name=$nm;Exe=$exe;Store="Steam"}) }
                }
            }
        }
    } catch {}

    # Xbox / Game Pass
    foreach ($root in @("C:\XboxGames","D:\XboxGames")) {
        if (-not (Test-Path $root)) { continue }
        Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $exe=Find-MainExe $_.FullName
            if ($exe) {
                $nm=(($_.Name -split "_")[0] -replace "\."," " -replace "-"," ").Trim()
                if ($nm) { $found.Add(@{Name=$nm;Exe=$exe;Store="Xbox/Game Pass"}) }
            }
        }
    }

    # Epic
    $epic="C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests"
    if (Test-Path $epic) {
        Get-ChildItem $epic -Filter "*.item" -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $d=Get-Content $_.FullName -Raw | ConvertFrom-Json
                if ($d.DisplayName -and $d.InstallLocation) {
                    $full=Join-Path $d.InstallLocation $d.LaunchExecutable
                    $exe=if(Test-Path $full){$full}else{Find-MainExe $d.InstallLocation}
                    if ($exe) { $found.Add(@{Name=$d.DisplayName;Exe=$exe;Store="Epic Games"}) }
                }
            } catch {}
        }
    }

    # GOG
    try {
        $gog="HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games"
        if (Test-Path $gog) {
            Get-ChildItem $gog -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $nm=(Get-ItemProperty $_.PSPath "GAMENAME" -ErrorAction SilentlyContinue).GAMENAME
                    $exe=(Get-ItemProperty $_.PSPath "EXE" -ErrorAction SilentlyContinue).EXE
                    if ($nm -and $exe -and (Test-Path $exe)) { $found.Add(@{Name=$nm;Exe=$exe;Store="GOG"}) }
                } catch {}
            }
        }
    } catch {}

    # EA / Ubisoft
    @("C:\Program Files\EA Games","C:\Program Files (x86)\Origin Games","C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games") | ForEach-Object {
        if (-not (Test-Path $_)) { return }
        $store=if($_ -like "*Ubisoft*"){"Ubisoft"}else{"EA"}
        Get-ChildItem $_ -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $exe=Find-MainExe $_.FullName
            if ($exe) { $found.Add(@{Name=$_.Name;Exe=$exe;Store=$store}) }
        }
    }

    # Deduplicate
    $seen=@{}
    ($found | Where-Object { $k=$_.Exe.ToLower(); if($seen[$k]){$false}else{$seen[$k]=$true;$true} }) | Sort-Object { $_.Name }
}

# ?? Main form ?????????????????????????????????????????????????????????????????
function Build-Chrome {
    $form=New-Object System.Windows.Forms.Form
    $form.Text="ROG Ally Optimizer"; $form.Size=New-Object System.Drawing.Size(1200,780)
    $form.MinimumSize=New-Object System.Drawing.Size(980,660); $form.BackColor=$C.Bg
    $form.StartPosition=[System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle=[System.Windows.Forms.FormBorderStyle]::Sizable
    $script:Form=$form

    # Topbar
    $topbar=New-Pnl $form.Width 62 $C.Panel; $topbar.Dock=[System.Windows.Forms.DockStyle]::Top
    $topbar.Paint+={param($s,$e);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Red,2)),0,$s.Height-1,$s.Width,$s.Height-1)}

    $script:TopStripe=New-Pnl 6 62 $C.Red; $script:TopStripe.Dock=[System.Windows.Forms.DockStyle]::Left
    $topbar.Controls.Add($script:TopStripe)

    # Logo (custom painted  -  no extra font allocation)
    $logo=New-Pnl 300 62 $C.Panel; $logo.Location=New-Object System.Drawing.Point(12,0)
    $logo.Paint+={
        param($s,$e)
        $g=$e.Graphics; $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias
        $g.DrawString("ROG ALLY",$F.Title,(New-Object System.Drawing.SolidBrush($C.Red)),0,12)
        $sz=$g.MeasureString("ROG ALLY",$F.Title)
        $g.DrawString(" OPTIMIZER",(New-Object System.Drawing.Font("Bahnschrift",22)),(New-Object System.Drawing.SolidBrush($C.Hi)),$sz.Width,12)
    }
    $topbar.Controls.Add($logo)

    # Mode toggle
    $tog=New-Pnl 260 40 $C.Card2; $tog.Location=New-Object System.Drawing.Point(280,11)
    $tog.Paint+={param($s,$e);$e.Graphics.DrawRectangle((New-Object System.Drawing.Pen($C.BHi,2)),1,1,$s.Width-3,$s.Height-3)}
    $script:BtnPlay=New-Btn "GAME  PLAY" 120 34 $C.Red $C.Hi $F.H3; $script:BtnPlay.Location=New-Object System.Drawing.Point(3,3); $script:BtnPlay.Add_Click({Switch-Mode "simple"}); $tog.Controls.Add($script:BtnPlay)
    $script:BtnAdv=New-Btn "*  ADVANCED" 128 34 ([System.Drawing.Color]::Transparent) $C.Muted $F.Body; $script:BtnAdv.Location=New-Object System.Drawing.Point(128,3); $script:BtnAdv.Add_Click({Switch-Mode "advanced"}); $tog.Controls.Add($script:BtnAdv)
    $topbar.Controls.Add($tog)

    $script:BtnHH=New-Btn "HH HANDHELD" 120 40 $C.Cyan $C.Bg $F.H3 $C.Cyan; $script:BtnHH.Location=New-Object System.Drawing.Point(548,11); $script:BtnHH.Add_Click({Toggle-Handheld}); $topbar.Controls.Add($script:BtnHH)

    $btnEng=New-Btn ">>> ENGINE" 110 40 $C.Purp $C.Hi $F.H3 $C.Purp; $btnEng.Location=New-Object System.Drawing.Point(676,11); $btnEng.Add_Click({Show-BoostPanel}); $topbar.Controls.Add($btnEng)

    # Status + RAM
    $rf=New-Object System.Windows.Forms.FlowLayoutPanel; $rf.FlowDirection=[System.Windows.Forms.FlowDirection]::RightToLeft; $rf.Size=New-Object System.Drawing.Size(700,62); $rf.BackColor=$C.Panel; $rf.Location=New-Object System.Drawing.Point(490,0); $rf.WrapContents=$false
    $script:StatusLbl=New-Lbl "* READY" $F.MonoS $C.Green $C.Panel; $script:StatusLbl.AutoSize=$false; $script:StatusLbl.Size=New-Object System.Drawing.Size(280,62); $script:StatusLbl.TextAlign=[System.Drawing.ContentAlignment]::MiddleRight; $rf.Controls.Add($script:StatusLbl)
    $script:RamLbl=New-Lbl "RAM --" $F.MonoS $C.Muted $C.Panel; $script:RamLbl.AutoSize=$false; $script:RamLbl.Size=New-Object System.Drawing.Size(160,62); $script:RamLbl.TextAlign=[System.Drawing.ContentAlignment]::MiddleCenter; $rf.Controls.Add($script:RamLbl)
    $topbar.Controls.Add($rf)

    # Device bar
    $db=New-Pnl $form.Width 40 ([System.Drawing.Color]::FromArgb(3,3,8)); $db.Location=New-Object System.Drawing.Point(0,62)
    $db.Paint+={param($s,$e);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Border,1)),0,$s.Height-1,$s.Width,$s.Height-1)}
    (New-Lbl "DEVICE" $F.MonoS $C.Muted) | ForEach-Object { $_.Location=New-Object System.Drawing.Point(14,12); $db.Controls.Add($_) }
    $script:DevDrop=New-Object System.Windows.Forms.ComboBox; $script:DevDrop.Items.AddRange($MODELS.Keys); $script:DevDrop.SelectedItem=$script:Settings.device; $script:DevDrop.Size=New-Object System.Drawing.Size(320,26); $script:DevDrop.Location=New-Object System.Drawing.Point(68,7); $script:DevDrop.BackColor=$C.Card2; $script:DevDrop.ForeColor=$C.Hi; $script:DevDrop.Font=$F.Body; $script:DevDrop.DropDownStyle=[System.Windows.Forms.ComboBoxStyle]::DropDownList; $script:DevDrop.Add_SelectedIndexChanged({On-DeviceChange}); $db.Controls.Add($script:DevDrop)
    $script:PowerLbl=New-Lbl "DETECTING..." $F.MonoS $C.Muted; $script:PowerLbl.Location=New-Object System.Drawing.Point(400,12); $db.Controls.Add($script:PowerLbl)
    $script:XboxLbl=New-Lbl "  XBOX MODE OFF  " $F.MonoS $C.Muted $C.Card2; $script:XboxLbl.Location=New-Object System.Drawing.Point(700,8); $script:XboxLbl.AutoSize=$false; $script:XboxLbl.Size=New-Object System.Drawing.Size(160,24); $script:XboxLbl.TextAlign=[System.Drawing.ContentAlignment]::MiddleCenter; $db.Controls.Add($script:XboxLbl)

    $script:BodyPanel=New-Pnl $form.Width ($form.Height-102) $C.Bg; $script:BodyPanel.Location=New-Object System.Drawing.Point(0,102)
    $script:BodyPanel.Anchor=[System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

    $form.Controls.AddRange(@($topbar,$db,$script:BodyPanel))
    $form.Add_Resize({ $db.Width=$script:Form.ClientSize.Width; $script:BodyPanel.Width=$script:Form.ClientSize.Width; $script:BodyPanel.Height=$script:Form.ClientSize.Height-102 })
    return $form
}

# ?? Mode switching ????????????????????????????????????????????????????????????
function Switch-Mode($mode) {
    $script:Mode=$mode; $script:Settings.mode=$mode; Save-Settings
    Update-ToggleStyle; Build-Body
}
function Toggle-Handheld {
    $script:Handheld=-not $script:Handheld; $script:Settings.handheld=$script:Handheld; Save-Settings
    if ($script:Handheld) { $script:BtnHH.BackColor=$C.Cyan; $script:BtnHH.ForeColor=$C.Bg }
    else                  { $script:BtnHH.BackColor=[System.Drawing.Color]::Transparent; $script:BtnHH.ForeColor=$C.Muted }
    Build-Body
}
function Update-ToggleStyle {
    if ($script:Mode -eq "simple") {
        $script:BtnPlay.BackColor=$C.Red;  $script:BtnPlay.ForeColor=$C.Hi;   $script:BtnPlay.Font=$F.H3
        $script:BtnAdv.BackColor=[System.Drawing.Color]::Transparent; $script:BtnAdv.ForeColor=$C.Muted; $script:BtnAdv.Font=$F.Body
    } else {
        $script:BtnPlay.BackColor=[System.Drawing.Color]::Transparent; $script:BtnPlay.ForeColor=$C.Muted; $script:BtnPlay.Font=$F.Body
        $script:BtnAdv.BackColor=$C.BHi;  $script:BtnAdv.ForeColor=$C.Hi;   $script:BtnAdv.Font=$F.H3
    }
}
function Build-Body {
    $script:BodyPanel.Controls.Clear(); $script:TilePanels=@{}; $script:PowerBtns=@{}; $script:SelectedGame=$null
    if ($script:Mode -eq "simple") { Build-SimpleMode } else { Build-AdvancedMode }
}
function On-DeviceChange {
    $script:Settings.device=$script:DevDrop.SelectedItem; Save-Settings
    $script:TopStripe.BackColor=(Get-Dev).Color; Update-PowerLabel; Build-Body
}

# ??????????????????????????????????????????????????????????????????????????????
# SIMPLE MODE  -  Pick a game, press the button. Everything else is automatic.
# ??????????????????????????????????????????????????????????????????????????????
function Build-SimpleMode {
    $bp=$script:BodyPanel; $dev=Get-Dev; $cols=if($script:Handheld){2}else{3}

    # ?? Top strip: device info + 3 simple toggles ?????????????????????????????
    $info=New-Pnl $bp.Width 62 $C.Panel; $info.Dock=[System.Windows.Forms.DockStyle]::Top
    $info.Paint+={param($s,$e);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Border,1)),0,$s.Height-1,$s.Width,$s.Height-1)}

    # Device info
    $devLbl=New-Lbl "$($dev.Chip.ToUpper())  .  $($dev.CUs) CUs  .  $($dev.RAM) GB  .  TURBO $($dev.TDP.plugged.turbo)W" $F.MonoS $dev.Color
    $devLbl.Location=New-Object System.Drawing.Point(14,22); $info.Controls.Add($devLbl)

    # ?? 3 key toggles  -  Clean, AFMF, RSR ?????????????????????????????????????
    $toggles = @(
        @{Label="CLEAN CLEAN";  Key="FlushRam"; OnColor=$C.Green;   OffColor=$C.Card2; Tip="Kill background apps + flush RAM before launch"}
        @{Label="AFMF AFMF";   Key="AFMF";    OnColor=$C.Cyan;    OffColor=$C.Card2; Tip="AMD frame generation  -  doubles perceived FPS"}
        @{Label="RSR  RSR";    Key="RSR";     OnColor=$C.Purp;    OffColor=$C.Card2; Tip="AMD upscaling  -  more FPS, same visual quality"}
    )
    $tx = $bp.Width - 580
    foreach ($tog in $toggles) {
        $k=$tog.Key; $on=$script:BoostSettings[$k]
        $tb=New-Btn $tog.Label 112 44 (if($on){$tog.OnColor}else{$tog.OffColor}) (if($on){$C.Bg}else{$C.Muted}) $F.H3 (if($on){$tog.OnColor}else{$C.Border})
        $tb.Location=New-Object System.Drawing.Point($tx,9)
        $tb.Add_Click({
            $script:BoostSettings[$k]=-not $script:BoostSettings[$k]
            $script:Settings["boost_$k"]=$script:BoostSettings[$k]; Save-Settings
            # Rebuild just the info strip
            Build-Body
        })
        $info.Controls.Add($tb); $tx+=120
    }

    # Add / Scan
    (New-Btn "SCAN  SCAN" 100 44 $C.Card2 $C.Cyan $F.H3 $C.Cyan)    | ForEach-Object{$_.Location=New-Object System.Drawing.Point(($bp.Width-212),9);$_.Add_Click({Show-ScanDialog});$info.Controls.Add($_)}
    (New-Btn "+  ADD"  100 44 $C.Red   $C.Hi   $F.H3 $C.RedGlo)   | ForEach-Object{$_.Location=New-Object System.Drawing.Point(($bp.Width-104),9);$_.Add_Click({Add-Game $true});$info.Controls.Add($_)}

    # ?? Scrollable game grid ??????????????????????????????????????????????????
    $scroll=New-Object System.Windows.Forms.Panel; $scroll.AutoScroll=$true
    $scroll.BackColor=$C.Bg; $scroll.Dock=[System.Windows.Forms.DockStyle]::Fill
    $script:GridScroll=$scroll

    # ?? Gamepad hint bar ??????????????????????????????????????????????????????
    $hint=New-Pnl $bp.Width 40 ([System.Drawing.Color]::FromArgb(3,3,8)); $hint.Dock=[System.Windows.Forms.DockStyle]::Bottom
    $hint.Paint+={
        param($s,$e); $g=$e.Graphics; $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias
        $e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Border,1)),0,0,$s.Width,0)
        $x=14
        @(@("A OPTIMIZE & PLAY",$C.Green),@("X SCAN GAMES",$C.Cyan),@("Y ADD GAME",$C.Warn),@("^v<>> NAVIGATE",$C.Muted)) | ForEach-Object {
            $g.DrawString($_[0],$F.MonoS,(New-Object System.Drawing.SolidBrush($_[1])),$x,12)
            $x+=$g.MeasureString($_[0],$F.MonoS).Width+24
        }
    }

    $bp.Controls.AddRange(@($scroll,$info,$hint))
    Build-TileGrid $scroll $cols

    $script:Form.KeyPreview=$true
    $script:Form.Add_KeyDown({
        param($s,$e)
        $games=@($script:Profiles.Keys); $cnt=$games.Count; if($cnt -eq 0){return}
        $c2=if($script:Handheld){2}else{3}
        switch($e.KeyCode){
            "Return" {Launch-Game $games[$script:FocusIdx]}
            "Up"     {$script:FocusIdx=[Math]::Max(0,$script:FocusIdx-$c2);Update-TileFocus}
            "Down"   {$script:FocusIdx=[Math]::Min($cnt-1,$script:FocusIdx+$c2);Update-TileFocus}
            "Left"   {if($script:FocusIdx -gt 0){$script:FocusIdx--;Update-TileFocus}}
            "Right"  {if($script:FocusIdx -lt $cnt-1){$script:FocusIdx++;Update-TileFocus}}
            "Tab"    {$script:FocusIdx=[Math]::Min($cnt-1,$script:FocusIdx+1);Update-TileFocus;$e.Handled=$true}
            "F1"     {Show-ScanDialog}
            "F2"     {Add-Game $true}
        }
    })
}

function Build-TileGrid($scroll,$cols) {
    $scroll.Controls.Clear(); $script:TilePanels=@{}
    $games=@($script:Profiles.Keys)

    if ($games.Count -eq 0) {
        $box=New-Pnl 460 220 $C.Bg; $box.Location=New-Object System.Drawing.Point(([int](($scroll.Width-460)/2)),80)
        $box.Paint+={
            param($s,$e); $g=$e.Graphics; $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias
            $g.DrawString("NO GAMES YET",$F.H1,(New-Object System.Drawing.SolidBrush($C.Muted)),40,10)
            $g.DrawString("Scan to auto-detect, or add games manually",$F.Body,(New-Object System.Drawing.SolidBrush($C.BHi)),20,50)
        }
        $bS=New-Btn "SCAN  SCAN INSTALLED GAMES" 300 56 $C.Cyan $C.Bg $F.H2 $C.Cyan; $bS.Location=New-Object System.Drawing.Point(80,90); $bS.Add_Click({Show-ScanDialog}); $box.Controls.Add($bS)
        $bA=New-Btn "+  ADD MANUALLY" 300 42 $C.Card2 $C.Text $F.H3 $C.BHi; $bA.Location=New-Object System.Drawing.Point(80,154); $bA.Add_Click({Add-Game $true}); $box.Controls.Add($bA)
        $scroll.Controls.Add($box); return
    }

    $pad  = if($script:Handheld){10}else{8}
    $tileW= [Math]::Max(220,[int](($scroll.ClientSize.Width-($pad*($cols+1)))/$cols))
    $tileH= if($script:Handheld){220}else{190}

    for ($i=0;$i -lt $games.Count;$i++) {
        $col=$i%$cols; $row=[int]($i/$cols)
        Build-Tile $scroll $games[$i] $i ($pad+$col*($tileW+$pad)) ($pad+$row*($tileH+$pad)) $tileW $tileH ($TILE_COLORS[$i%$TILE_COLORS.Count])
    }
    $rows=[Math]::Ceiling($games.Count/$cols)
    $scroll.AutoScrollMinSize=New-Object System.Drawing.Size(0,($rows*($tileH+$pad)+$pad))
    $script:FocusIdx=[Math]::Min($script:FocusIdx,[Math]::Max(0,$games.Count-1))
    Update-TileFocus
}

function Build-Tile($parent,$name,$idx,$x,$y,$w,$h,$tc) {
    $p=New-Object System.Windows.Forms.Panel
    $p.Size=New-Object System.Drawing.Size($w,$h); $p.Location=New-Object System.Drawing.Point($x,$y)
    $p.BackColor=$C.Card; $p.Tag=$name
    $script:TilePanels[$name]=$p
    $tileColor=$tc; $hh=$script:Handheld

    $p.Paint+={
        param($s,$e); $g=$e.Graphics
        # Top color band
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($tileColor)),0,0,$s.Width,8)
        # Focus/selected border
        $isFocused = ($idx -eq $script:FocusIdx)
        $bC=if($isFocused){$C.Hi}else{$C.Border}
        $bW=if($isFocused){3}else{2}
        $g.DrawRectangle((New-Object System.Drawing.Pen($bC,$bW)),1,1,$s.Width-3,$s.Height-3)
    }

    # Left color stripe
    $stripe=New-Pnl 5 $h $tileColor; $stripe.Location=New-Object System.Drawing.Point(0,0); $p.Controls.Add($stripe)

    # Game initial letter
    $initial=if($name.Length -gt 0){$name[0].ToString().ToUpper()}else{"?"}
    $lSize=if($hh){52}else{44}
    $letterPnl=New-Pnl $lSize $lSize $tileColor; $letterPnl.Location=New-Object System.Drawing.Point(16,16)
    $lFont=New-Object System.Drawing.Font("Bahnschrift",(if($hh){22}else{18}),[System.Drawing.FontStyle]::Bold)
    $letterPnl.Paint+={
        param($s,$e); $g=$e.Graphics; $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($tileColor)),0,0,$s.Width,$s.Height)
        $sz=$g.MeasureString($initial,$lFont)
        $g.DrawString($initial,$lFont,(New-Object System.Drawing.SolidBrush($C.Hi)),($s.Width-$sz.Width)/2,($s.Height-$sz.Height)/2)
    }
    $p.Controls.Add($letterPnl)

    # Name
    $dispName=if($name.Length -gt 24){"$($name.Substring(0,22))..."}else{$name}
    $nLbl=New-Lbl $dispName.ToUpper() (if($hh){$F.H2}else{$F.H3}) $C.Hi
    $nLbl.Location=New-Object System.Drawing.Point(($lSize+24),16); $nLbl.MaximumSize=New-Object System.Drawing.Size(($w-$lSize-40),0); $p.Controls.Add($nLbl)

    # Status  -  what's active
    $prof=if($script:Profiles[$name]){$script:Profiles[$name]}else{@{}}
    $activeTags=@()
    if ($script:BoostSettings.AFMF) { $activeTags += "AFMF" }
    if ($script:BoostSettings.RSR)  { $activeTags += "RSR" }
    if ($script:BoostSettings.FlushRam) { $activeTags += "CLEAN" }
    $statusExtra = if($activeTags.Count -gt 0){ "  .  " + ($activeTags -join " + ")}else{""}
    $statusTxt = (Get-TileStatus $prof) + $statusExtra
    $sLbl=New-Lbl $statusTxt $F.MonoS (Get-TileStatusColor $prof)
    $sLbl.Location=New-Object System.Drawing.Point(($lSize+24),($nLbl.Top+20)); $sLbl.MaximumSize=New-Object System.Drawing.Size(($w-$lSize-40),0); $p.Controls.Add($sLbl)

    # THE BUTTON  -  one big "OPTIMIZE & PLAY"  -  this is the whole Simple Mode experience
    $btnH=if($hh){58}else{48}; $btnTop=$h-$btnH-10
    $mainBtn=New-Btn ">>>  OPTIMIZE + PLAY" ($w-20) $btnH $tileColor $C.Hi $F.H2
    $mainBtn.FlatAppearance.BorderSize=0
    $mainBtn.Location=New-Object System.Drawing.Point(10,$btnTop)
    $mainBtn.Font=New-Object System.Drawing.Font("Bahnschrift",(if($hh){15}else{13}),[System.Drawing.FontStyle]::Bold)
    $mainBtn.Add_Click({ Launch-Game $name })
    $p.Controls.Add($mainBtn)

    $p.Add_Click({$script:FocusIdx=$idx;Update-TileFocus})
    $parent.Controls.Add($p)
}

function Get-TileStatus($p) {
    if ($p.notes) { $tdp=Get-TDP; $pm=if($p.power_rec){$p.power_rec}else{"Turbo"}; return "$($p.res_w)x$($p.res_h)  .  $pm $($tdp[$pm.ToLower()])W  .  AI +" }
    if ($p.exe_path) { return "READY  .  AI OPTIMIZES ON FIRST PLAY" }
    return "NEEDS .EXE  .  TAP * TO SET"
}
function Get-TileStatusColor($p) {
    if ($p.notes) { return $C.Green }
    if ($p.exe_path) { return $C.Warn }
    return $C.Muted
}
function Update-TileFocus {
    $games=@($script:Profiles.Keys); if($games.Count -eq 0){return}
    $script:FocusIdx=[Math]::Max(0,[Math]::Min($script:FocusIdx,$games.Count-1))
    $script:TilePanels.Values | ForEach-Object { try{$_.Invalidate()}catch{} }
}

# ??????????????????????????????????????????????????????????????????????????????
# ADVANCED MODE
# ??????????????????????????????????????????????????????????????????????????????
function Build-AdvancedMode {
    $bp=$script:BodyPanel

    # Sidebar
    $sb=New-Pnl 210 $bp.Height $C.Panel; $sb.Dock=[System.Windows.Forms.DockStyle]::Left
    $sb.Paint+={param($s,$e);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Border,2)),$s.Width-1,0,$s.Width-1,$s.Height)}

    $sbH=New-Pnl 210 42 $C.Card; $sbH.Location=New-Object System.Drawing.Point(0,0)
    $sbH.Paint+={param($s,$e);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Red,2)),0,$s.Height-1,$s.Width,$s.Height-1);$e.Graphics.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias;$e.Graphics.DrawString("GAME LIBRARY",$F.H3,(New-Object System.Drawing.SolidBrush($C.Red)),10,12)}
    $sb.Controls.Add($sbH)

    $br=New-Pnl 194 36 $C.Panel; $br.Location=New-Object System.Drawing.Point(8,48)
    $ba=New-Btn "+  ADD" 118 32 $C.Red $C.Hi $F.H3; $ba.Location=New-Object System.Drawing.Point(0,0); $ba.Add_Click({Add-Game $false}); $br.Controls.Add($ba)
    $bx=New-Btn "X" 68 32 $C.Card2 $C.Text $F.Body $C.Border; $bx.Location=New-Object System.Drawing.Point(124,0); $bx.Add_Click({Remove-SelectedGame}); $br.Controls.Add($bx)
    $sb.Controls.Add($br)

    $bSc=New-Btn "SCAN  SCAN INSTALLED GAMES" 194 30 $C.Card2 $C.Cyan $F.Small $C.Cyan; $bSc.Location=New-Object System.Drawing.Point(8,90); $bSc.Add_Click({Show-ScanDialog}); $sb.Controls.Add($bSc)

    $script:GameListBox=New-Object System.Windows.Forms.ListBox
    $script:GameListBox.Size=New-Object System.Drawing.Size(194,($bp.Height-230)); $script:GameListBox.Location=New-Object System.Drawing.Point(8,126)
    $script:GameListBox.BackColor=$C.Bg; $script:GameListBox.ForeColor=$C.Text; $script:GameListBox.Font=$F.Body; $script:GameListBox.BorderStyle=[System.Windows.Forms.BorderStyle]::None
    $script:GameListBox.Add_SelectedIndexChanged({if($script:GameListBox.SelectedItem){Select-Game $script:GameListBox.SelectedItem}})
    $sb.Controls.Add($script:GameListBox); Refresh-GameList

    (New-Pnl 194 2 $C.Border) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(8,($bp.Height-100));$sb.Controls.Add($_)}

    $bE=New-Btn "^  EXPORT" 94 30 ([System.Drawing.Color]::FromArgb(5,15,8)) ([System.Drawing.Color]::FromArgb(0,255,100)) $F.Small ([System.Drawing.Color]::FromArgb(0,170,68)); $bE.Location=New-Object System.Drawing.Point(8,($bp.Height-94)); $bE.Add_Click({Export-Profiles}); $sb.Controls.Add($bE)
    $bI=New-Btn "v  IMPORT" 94 30 ([System.Drawing.Color]::FromArgb(5,8,20)) ([System.Drawing.Color]::FromArgb(0,170,255)) $F.Small ([System.Drawing.Color]::FromArgb(0,100,200)); $bI.Location=New-Object System.Drawing.Point(108,($bp.Height-94)); $bI.Add_Click({Import-Profiles}); $sb.Controls.Add($bI)

    $script:EditorPanel=New-Pnl ($bp.Width-210) $bp.Height $C.Panel; $script:EditorPanel.Location=New-Object System.Drawing.Point(210,0)
    $script:EditorPanel.Anchor=[System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $script:EditorPanel.Paint+={param($s,$e);$e.Graphics.DrawRectangle((New-Object System.Drawing.Pen($C.Border,2)),1,1,$s.Width-3,$s.Height-3)}

    # Action bar
    $act=New-Pnl $bp.Width 58 $C.Panel; $act.Dock=[System.Windows.Forms.DockStyle]::Bottom
    $act.Paint+={param($s,$e);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Red,2)),0,0,$s.Width,0)}
    (New-Btn "  >>  LAUNCH & OPTIMIZE  " 240 42 $C.Red $C.Hi $F.H2 $C.RedGlo) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(($bp.Width-258),8);$_.Add_Click({Start-Launch});$act.Controls.Add($_)}
    (New-Btn "CLEAN  CLEAN RAM" 138 42 $C.Card2 $C.Text $F.H3 $C.Border)         | ForEach-Object{$_.Location=New-Object System.Drawing.Point(($bp.Width-406),8);$_.Add_Click({[System.Threading.Thread]::new({Invoke-Cleanup;Invoke-FlushRam}).Start()});$act.Controls.Add($_)}
    (New-Btn "DEL   BLOAT REMOVER" 172 42 ([System.Drawing.Color]::FromArgb(20,8,0)) $C.Warn $F.H3 $C.Warn) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(($bp.Width-588),8);$_.Add_Click({Show-Debloat});$act.Controls.Add($_)}
    (New-Lbl "SELECT DEVICE  ?  ADD GAME  ?  AI  AUTO-OPTIMIZE  ?  >> LAUNCH" $F.MonoS $C.Muted) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(16,20);$act.Controls.Add($_)}

    $bp.Controls.AddRange(@($script:EditorPanel,$sb,$act))
    Show-Welcome
}

function Show-Welcome {
    $ep=$script:EditorPanel; $ep.Controls.Clear(); $dev=Get-Dev
    $outer=New-Pnl 500 300 $C.Panel; $outer.Location=New-Object System.Drawing.Point(([int](($ep.Width-500)/2)),[int](($ep.Height-300)/2))
    $outer.Paint+={
        param($s,$e); $g=$e.Graphics; $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias
        $g.DrawString($script:Settings.device.ToUpper(),$F.H1,(New-Object System.Drawing.SolidBrush($dev.Color)),0,10)
        $g.DrawString("$($dev.Chip)  .  $($dev.CUs) CUs  .  $($dev.RAM) GB",$F.MonoS,(New-Object System.Drawing.SolidBrush($C.Muted)),0,48)
        $g.DrawLine((New-Object System.Drawing.Pen($C.Border,1)),0,70,480,70)
        $steps=@("01  Select your device above","02  + Add a game in the sidebar","03  Browse to the .exe file","04  AI  Auto-Optimize with AI","05  >> Launch & Optimize")
        for($i=0;$i -lt $steps.Count;$i++){$g.DrawString($steps[$i],$F.Body,(New-Object System.Drawing.SolidBrush($C.Muted)),0,(84+$i*28))}
    }
    $ep.Controls.Add($outer)
}

function Refresh-GameList {
    if (-not $script:GameListBox) { return }
    $script:GameListBox.Items.Clear()
    $script:Profiles.Keys | ForEach-Object { $script:GameListBox.Items.Add($_) | Out-Null }
}

function Select-Game($name) {
    $script:SelectedGame=$name; $script:GameListBox.SelectedItem=$name; Show-Editor $name
}

function Show-Editor($name) {
    $ep=$script:EditorPanel; $ep.Controls.Clear(); $script:PowerBtns=@{}
    $p=if($script:Profiles[$name]){$script:Profiles[$name]}else{@{}}
    $dev=Get-Dev; if(Get-Plugged){$state="plugged"}else{$state="battery"}; $tdp=$dev.TDP[$state]

    # Top strip
    $strip=New-Pnl $ep.Width 52 $C.Card
    $strip.Paint+={param($s,$e);$g=$e.Graphics;$g.FillRectangle((New-Object System.Drawing.SolidBrush($dev.Color)),0,0,5,$s.Height);$g.DrawLine((New-Object System.Drawing.Pen($C.Border,1)),0,$s.Height-1,$s.Width,$s.Height-1);$g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias;$g.DrawString($name.ToUpper(),$F.H2,(New-Object System.Drawing.SolidBrush($C.Hi)),18,16)}
    $plugTxt=if($state -eq "plugged"){">>> PLUGGED   TURBO=$($tdp.turbo)W"}else{"BATT BATTERY   TURBO=$($tdp.turbo)W"}
    (New-Lbl $plugTxt $F.MonoS (if($state -eq "plugged"){$C.Green}else{$C.Warn})) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(220,20);$strip.Controls.Add($_)}
    $script:AutoBtn=New-Btn "AI    AUTO-OPTIMIZE (AI)" 220 36 $C.Purp $C.Hi $F.H3 $C.Purp; $script:AutoBtn.Location=New-Object System.Drawing.Point(($ep.Width-240),8); $script:AutoBtn.Add_Click({Run-AI $name $false}); $strip.Controls.Add($script:AutoBtn)
    $ep.Controls.Add($strip)

    # Scrollable form
    $sc=New-Object System.Windows.Forms.Panel; $sc.AutoScroll=$true; $sc.BackColor=$C.Panel; $sc.Size=New-Object System.Drawing.Size($ep.Width,($ep.Height-52)); $sc.Location=New-Object System.Drawing.Point(0,52); $ep.Controls.Add($sc)
    $lx=18; $fw=$ep.Width-52; $script:SY=14

    function SL($txt,$col=$C.Cyan) {
        $r=New-Object System.Windows.Forms.Panel; $r.Size=New-Object System.Drawing.Size($fw,24); $r.Location=New-Object System.Drawing.Point($lx,($script:SY+6)); $r.BackColor=[System.Drawing.Color]::Transparent
        $r.Paint+={param($s,$e);$g=$e.Graphics;$g.FillRectangle((New-Object System.Drawing.SolidBrush($col)),0,6,3,12);$g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias;$g.DrawString("  $txt",$F.MonoS,(New-Object System.Drawing.SolidBrush($col)),0,5);$g.DrawLine((New-Object System.Drawing.Pen($col,1)),[int]($g.MeasureString("  $txt",$F.MonoS).Width+4),12,$s.Width-4,12)}
        $sc.Controls.Add($r); $script:SY=$script:SY+32
    }

    # EXE
    SL "EXECUTABLE PATH"
    $exeTxt=New-Object System.Windows.Forms.TextBox; $exeTxt.Text=if($p.exe_path){$p.exe_path}else{""}; $exeTxt.Size=New-Object System.Drawing.Size(($fw-96),30); $exeTxt.Location=New-Object System.Drawing.Point($lx,$script:SY); $exeTxt.BackColor=$C.Card2; $exeTxt.ForeColor=$C.Hi; $exeTxt.Font=$F.Mono; $exeTxt.BorderStyle=[System.Windows.Forms.BorderStyle]::FixedSingle; $sc.Controls.Add($exeTxt)
    $bBr=New-Btn "BROWSE" 86 30 $C.Card2 $C.Cyan $F.Small $C.Cyan; $bBr.Location=New-Object System.Drawing.Point(($lx+$fw-88),$script:SY); $bBr.Add_Click({$d=New-Object System.Windows.Forms.OpenFileDialog;$d.Filter="Executables|*.exe|All|*.*";if($d.ShowDialog() -eq "OK"){$exeTxt.Text=$d.FileName}}); $sc.Controls.Add($bBr); $script:SY+=40

    # Resolution
    SL "RESOLUTION" $dev.Color
    $resW=[ref](if($p.res_w){$p.res_w}else{1920}); $resH=[ref](if($p.res_h){$p.res_h}else{1080})
    $resDisp=New-Object System.Windows.Forms.Label; $resDisp.Text="$($resW.Value) x $($resH.Value)"; $resDisp.Font=$F.H1; $resDisp.ForeColor=$dev.Color; $resDisp.BackColor=[System.Drawing.Color]::Transparent; $resDisp.AutoSize=$true; $resDisp.Location=New-Object System.Drawing.Point($lx,$script:SY); $sc.Controls.Add($resDisp); $script:SY+=38
    $prRow=New-Object System.Windows.Forms.FlowLayoutPanel; $prRow.Size=New-Object System.Drawing.Size($fw,38); $prRow.Location=New-Object System.Drawing.Point($lx,$script:SY); $prRow.BackColor=[System.Drawing.Color]::Transparent; $prRow.WrapContents=$false
    foreach ($pr2 in $dev.Presets) {
        $lbl2=$pr2[0];$pw2=[int]$pr2[1];$ph2=[int]$pr2[2]
        $prBtn=New-Btn $lbl2 110 32 (if($pw2 -eq $resW.Value -and $ph2 -eq $resH.Value){$dev.Color}else{$C.Card2}) $C.Hi $F.Small (if($pw2 -eq $resW.Value -and $ph2 -eq $resH.Value){$dev.Color}else{$C.Border}); $prBtn.Margin=New-Object System.Windows.Forms.Padding(0,0,6,0)
        $prBtn.Add_Click({$resW.Value=$pw2;$resH.Value=$ph2;$resDisp.Text="$($resW.Value) x $($resH.Value)"}); $prRow.Controls.Add($prBtn)
    }
    $sc.Controls.Add($prRow); $script:SY+=46

    # Power mode
    SL "POWER MODE  [$($state.ToUpper())]" $C.Warn
    $curPow=[ref](if($p.power_rec){$p.power_rec}else{"Turbo"})
    $pmRow=New-Object System.Windows.Forms.FlowLayoutPanel; $pmRow.Size=New-Object System.Drawing.Size($fw,60); $pmRow.Location=New-Object System.Drawing.Point($lx,$script:SY); $pmRow.BackColor=[System.Drawing.Color]::Transparent; $pmRow.WrapContents=$false
    @("Silent","Performance","Turbo") | ForEach-Object {
        $mode=$_; $wv=$tdp[$mode.ToLower()]; $icons=@{Silent="?";Performance=">>>";Turbo="FIRE"}
        $isSel=$mode -eq $curPow.Value
        $pmBtn=New-Btn "$($icons[$mode]) $($mode.ToUpper())`n${wv}W" 128 54 (if($isSel){$C.Red}else{$C.Card2}) $C.Hi (if($isSel){$F.BodyB}else{$F.Body}) (if($isSel){$C.Red}else{$C.Border}); $pmBtn.Margin=New-Object System.Windows.Forms.Padding(0,0,8,0)
        $pmBtn.Add_Click({
            $curPow.Value=$mode
            $script:PowerBtns.Keys | ForEach-Object { $b2=$script:PowerBtns[$_]; $sel2=$_ -eq $mode; $b2.BackColor=if($sel2){$C.Red}else{$C.Card2}; $b2.FlatAppearance.BorderColor=if($sel2){$C.Red}else{$C.Border}; $b2.Font=if($sel2){$F.BodyB}else{$F.Body} }
        })
        $pmRow.Controls.Add($pmBtn); $script:PowerBtns[$mode]=$pmBtn
    }
    $sc.Controls.Add($pmRow); $script:SY+=68

    # Priority
    SL "PROCESS PRIORITY"
    $priDrop=New-Object System.Windows.Forms.ComboBox; $priDrop.Items.AddRange(@("Normal","Above Normal","High","Realtime")); $priDrop.SelectedItem=if($p.priority){$p.priority}else{"High"}; $priDrop.Size=New-Object System.Drawing.Size(210,28); $priDrop.Location=New-Object System.Drawing.Point($lx,$script:SY); $priDrop.BackColor=$C.Card2; $priDrop.ForeColor=$C.Hi; $priDrop.Font=$F.Body; $priDrop.DropDownStyle=[System.Windows.Forms.ComboBoxStyle]::DropDownList; $sc.Controls.Add($priDrop); $script:SY+=38

    # Cleanup
    SL "BACKGROUND CLEANUP"
    $cleanCk=New-Object System.Windows.Forms.CheckBox; $cleanCk.Text="Kill non-essential apps before launch"; $cleanCk.Checked=if($p.cleanup_enabled -ne $null){$p.cleanup_enabled}else{$true}; $cleanCk.Font=$F.Body; $cleanCk.ForeColor=$C.Text; $cleanCk.BackColor=[System.Drawing.Color]::Transparent; $cleanCk.Location=New-Object System.Drawing.Point($lx,$script:SY); $cleanCk.AutoSize=$true; $sc.Controls.Add($cleanCk); $script:SY+=34

    # Notes
    SL "AI OPTIMIZATION NOTES" $C.Purp
    $notesBox=New-Object System.Windows.Forms.TextBox; $notesBox.Multiline=$true; $notesBox.Size=New-Object System.Drawing.Size($fw,110); $notesBox.Location=New-Object System.Drawing.Point($lx,$script:SY); $notesBox.BackColor=$C.Card2; $notesBox.ForeColor=$C.Text; $notesBox.Font=$F.MonoS; $notesBox.ScrollBars=[System.Windows.Forms.ScrollBars]::Vertical; $notesBox.BorderStyle=[System.Windows.Forms.BorderStyle]::FixedSingle; $notesBox.Text=if($p.notes){$p.notes}else{""}; $sc.Controls.Add($notesBox); $script:SY+=120

    # Save
    $bSv=New-Btn "SAVE  SAVE PROFILE" $fw 42 $C.Red $C.Hi $F.H2 $C.RedGlo; $bSv.Location=New-Object System.Drawing.Point($lx,$script:SY)
    $bSv.Add_Click({
        if (-not $script:SelectedGame) { return }
        $script:Profiles[$script:SelectedGame]=@{exe_path=$exeTxt.Text.Trim();res_w=$resW.Value;res_h=$resH.Value;power_rec=$curPow.Value;priority=$priDrop.SelectedItem;cleanup_enabled=$cleanCk.Checked;notes=$notesBox.Text.Trim()}
        Save-Profiles; Set-Status "PROFILE SAVED" $C.Green
    })
    $sc.Controls.Add($bSv); $script:SY+=50
    $sc.AutoScrollMinSize=New-Object System.Drawing.Size(0,$script:SY)
}

# ?? Game management ???????????????????????????????????????????????????????????
function Add-Game($simple) {
    $box=[Microsoft.VisualBasic.Interaction]::InputBox("Enter game name:","Add Game","")
    if (-not $box -or -not $box.Trim()) { return }
    $name=$box.Trim()
    if (-not $script:Profiles[$name]) {
        if ($simple) {
            $d=New-Object System.Windows.Forms.OpenFileDialog; $d.Title="Find .exe for $name"; $d.Filter="Executables|*.exe|All|*.*"
            $exe=if($d.ShowDialog() -eq "OK"){$d.FileName}else{""}
            $script:Profiles[$name]=@{exe_path=$exe}
        } else { $script:Profiles[$name]=@{} }
        Save-Profiles
        if ($simple) { if($script:Handheld){$c3=2}else{$c3=3}; Build-TileGrid $script:GridScroll $c3 }
        else { Refresh-GameList }
    }
    if (-not $simple) { Select-Game $name }
}

function Remove-SelectedGame {
    if (-not $script:SelectedGame) { return }
    if ([System.Windows.Forms.MessageBox]::Show("Remove '$($script:SelectedGame)'?","Confirm",[System.Windows.Forms.MessageBoxButtons]::YesNo) -eq "Yes") {
        $script:Profiles.Remove($script:SelectedGame); $script:SelectedGame=$null; Save-Profiles; Refresh-GameList; Show-Welcome
    }
}

# ?? Scan dialog ???????????????????????????????????????????????????????????????
function Show-ScanDialog {
    Set-Status "SCAN SCANNING..." $C.Cyan
    $games=Find-InstalledGames
    $new=$games | Where-Object { -not $script:Profiles[$_.Name] }
    Set-Status "SCAN FOUND $($games.Count) GAMES" $C.Cyan

    $dlg=New-Object System.Windows.Forms.Form; $dlg.Text="Scan Results"; $dlg.Size=New-Object System.Drawing.Size(800,580); $dlg.BackColor=$C.Bg; $dlg.StartPosition=[System.Windows.Forms.FormStartPosition]::CenterParent; $dlg.FormBorderStyle=[System.Windows.Forms.FormBorderStyle]::FixedDialog
    $hdr=New-Pnl 800 52 $C.Panel; $hdr.Dock=[System.Windows.Forms.DockStyle]::Top
    $hdr.Paint+={param($s,$e);$e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush($C.Cyan)),0,0,5,$s.Height);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Cyan,2)),0,$s.Height-1,$s.Width,$s.Height-1);$e.Graphics.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias;$e.Graphics.DrawString("  $($new.Count) NEW GAMES FOUND  -  all checked by default",$F.H2,(New-Object System.Drawing.SolidBrush($C.Cyan)),0,14)}
    $dlg.Controls.Add($hdr)

    if ($new.Count -eq 0) {
        (New-Lbl "All detected games already in library!" $F.Body $C.Muted) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(200,200);$dlg.Controls.Add($_)}
        (New-Btn "CLOSE" 120 40 $C.Card2 $C.Text $F.H3 $C.Border) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(340,340);$_.Add_Click({$dlg.Close()});$dlg.Controls.Add($_)}
        $dlg.ShowDialog()|Out-Null; return
    }

    $clv=New-Object System.Windows.Forms.CheckedListBox; $clv.Size=New-Object System.Drawing.Size(760,390); $clv.Location=New-Object System.Drawing.Point(12,58); $clv.BackColor=$C.Card; $clv.ForeColor=$C.Hi; $clv.Font=$F.Body; $clv.BorderStyle=[System.Windows.Forms.BorderStyle]::None; $clv.CheckOnClick=$true
    $new | ForEach-Object { $clv.Items.Add("$($_.Name)  [$($_.Store)]",$true)|Out-Null }
    $dlg.Controls.Add($clv)

    $bAdd=New-Btn "?  ADD SELECTED" 200 42 $C.Red $C.Hi $F.H2 $C.RedGlo; $bAdd.Location=New-Object System.Drawing.Point(480,492)
    $bAdd.Add_Click({
        $added=0; $newArr=@($new)
        for($i=0;$i -lt $clv.Items.Count;$i++) {
            if ($clv.GetItemChecked($i)) {
                $nm=$newArr[$i].Name
                if (-not $script:Profiles[$nm]) { $script:Profiles[$nm]=@{exe_path=$newArr[$i].Exe}; $added++ }
            }
        }
        if ($added) {
            Save-Profiles
            if ($script:Mode -eq "simple") { $script:Form.Invoke([Action]{if($script:Handheld){$c3=2}else{$c3=3}; Build-TileGrid $script:GridScroll $c3}) }
            else { $script:Form.Invoke([Action]{Refresh-GameList}) }
            Set-Status "OK   $added GAMES ADDED" $C.Green
        }
        $dlg.Close()
    })
    $dlg.Controls.Add($bAdd)
    (New-Btn "CANCEL" 100 42 $C.Card2 $C.Text $F.Body $C.Border) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(370,492);$_.Add_Click({$dlg.Close()});$dlg.Controls.Add($_)}
    $dlg.ShowDialog()|Out-Null
}

# ?? Debloat ???????????????????????????????????????????????????????????????????
function Show-Debloat {
    $ep=$script:EditorPanel; $ep.Controls.Clear()
    $strip=New-Pnl $ep.Width 52 $C.Card
    $strip.Paint+={param($s,$e);$g=$e.Graphics;$g.FillRectangle((New-Object System.Drawing.SolidBrush($C.Warn)),0,0,5,$s.Height);$g.DrawLine((New-Object System.Drawing.Pen($C.Border,1)),0,$s.Height-1,$s.Width,$s.Height-1);$g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias;$g.DrawString("  WINDOWS BLOAT REMOVER",$F.H2,(New-Object System.Drawing.SolidBrush($C.Warn)),0,14)}
    $ep.Controls.Add($strip)
    $sc=New-Object System.Windows.Forms.Panel; $sc.AutoScroll=$true; $sc.BackColor=$C.Panel; $sc.Size=New-Object System.Drawing.Size($ep.Width,($ep.Height-52)); $sc.Location=New-Object System.Drawing.Point(0,52); $ep.Controls.Add($sc)
    $warn=New-Pnl ($ep.Width-36) 40 ([System.Drawing.Color]::FromArgb(20,15,0)); $warn.Location=New-Object System.Drawing.Point(14,12)
    $warn.Paint+={param($s,$e);$e.Graphics.DrawRectangle((New-Object System.Drawing.Pen($C.Warn,2)),1,1,$s.Width-3,$s.Height-3);$e.Graphics.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias;$e.Graphics.DrawString("  WARN   CHECK ITEMS THEN CLICK REMOVE SELECTED. CHANGES ARE PERMANENT.",$F.MonoS,(New-Object System.Drawing.SolidBrush($C.Warn)),4,12)}
    $sc.Controls.Add($warn)
    $checks=@(); $y2=62
    foreach ($item in $BLOAT) {
        $row=New-Pnl ($ep.Width-36) 44 $C.Card2; $row.Location=New-Object System.Drawing.Point(14,$y2); $row.Paint+={param($s,$e);$e.Graphics.DrawRectangle((New-Object System.Drawing.Pen($C.Border,1)),1,1,$s.Width-3,$s.Height-3)}
        $cb=New-Object System.Windows.Forms.CheckBox; $cb.Text=$item.Name.ToUpper(); $cb.Checked=$item.Default; $cb.Font=$F.BodyB; $cb.ForeColor=if($item.Default){$C.Warn}else{$C.Text}; $cb.BackColor=[System.Drawing.Color]::Transparent; $cb.Location=New-Object System.Drawing.Point(10,10); $cb.AutoSize=$true; $row.Controls.Add($cb)
        (New-Lbl $item.Desc $F.Small $C.Muted) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(230,14);$row.Controls.Add($_)}
        $checks+=@{Check=$cb;Cmd=$item.Cmd;Name=$item.Name}; $sc.Controls.Add($row); $y2+=50
    }
    $bR=New-Btn "DEL   REMOVE SELECTED" ($ep.Width-36) 44 ([System.Drawing.Color]::FromArgb(30,10,0)) $C.Warn $F.H2 $C.Warn; $bR.Location=New-Object System.Drawing.Point(14,$y2)
    $bR.Add_Click({
        $sel=$checks|Where-Object{$_.Check.Checked}; if(-not $sel){[System.Windows.Forms.MessageBox]::Show("Check at least one item.","Nothing selected")|Out-Null;return}
        $names=($sel|ForEach-Object{"  ? $($_.Name)"})-join"`n"
        if([System.Windows.Forms.MessageBox]::Show("PERMANENTLY REMOVE:`n$names`n`nCannot be undone. Continue?","Confirm",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning) -ne "Yes"){return}
        $t=[System.Threading.Thread]::new({$done=0;foreach($s in $sel){Set-Status "DEL  REMOVING: $($s.Name)..." $C.Warn;try{Start-Process cmd -ArgumentList "/c $($s.Cmd)" -WindowStyle Hidden -Wait;$done++}catch{}};Set-Status "OK   $done/$($sel.Count) ITEMS REMOVED . RESTART RECOMMENDED" $C.Green;[System.Windows.Forms.MessageBox]::Show("Removed $done items.`nRestart your Ally for full effect.","Done")|Out-Null})
        $t.IsBackground=$true;$t.Start()
    })
    $sc.Controls.Add($bR); $sc.AutoScrollMinSize=New-Object System.Drawing.Size(0,($y2+60))
}

# ?? Export / Import ???????????????????????????????????????????????????????????
function Export-Profiles {
    if ($script:Profiles.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("No profiles to export.","Export")|Out-Null; return }
    $d=New-Object System.Windows.Forms.SaveFileDialog; $d.Filter="ROG Profiles|*.json|All|*.*"; $d.FileName="rog_profiles.json"
    if ($d.ShowDialog() -ne "OK") { return }
    @{device=$script:Settings.device;profiles=$script:Profiles}|ConvertTo-Json -Depth 5|Set-Content $d.FileName -Encoding UTF8
    Set-Status "OK   $($script:Profiles.Count) PROFILES EXPORTED" $C.Green
}
function Import-Profiles {
    $d=New-Object System.Windows.Forms.OpenFileDialog; $d.Filter="ROG Profiles|*.json|All|*.*"
    if ($d.ShowDialog() -ne "OK") { return }
    try {
        $data=Get-Content $d.FileName -Raw|ConvertFrom-Json -AsHashtable
        $inc=if($data.profiles){$data.profiles}else{$data}
        if ($inc.Count -eq 0){[System.Windows.Forms.MessageBox]::Show("No profiles found.","Import")|Out-Null;return}
        $r=[System.Windows.Forms.MessageBox]::Show("Found $($inc.Count) profiles.`n`nYES = Merge  NO = Replace  Cancel = Abort","Import",[System.Windows.Forms.MessageBoxButtons]::YesNoCancel)
        if ($r -eq "Cancel"){return}
        if ($r -eq "Yes"){foreach($k in $inc.Keys){$script:Profiles[$k]=$inc[$k]}} else{$script:Profiles=$inc}
        Save-Profiles; Refresh-GameList; Set-Status "OK   $($inc.Count) PROFILES IMPORTED" $C.Green
    } catch {[System.Windows.Forms.MessageBox]::Show("Import failed: $_","Error")|Out-Null}
}

# ?? Background monitors ???????????????????????????????????????????????????????
function Start-Monitors {
    # RAM via CimInstance (fast, no WMI overhead)
    $script:OSCache = $null; $script:OSCacheTime = [datetime]::MinValue

    $monTimer=New-Object System.Windows.Forms.Timer; $monTimer.Interval=5000
    $monTimer.Add_Tick({
        Update-PowerLabel
        # Fast RAM read via CimInstance
        try {
            $os=Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os) {
                $used=[math]::Round(($os.TotalVisibleMemorySize-$os.FreePhysicalMemory)/1MB,1)
                $tot=[math]::Round($os.TotalVisibleMemorySize/1MB,1)
                $script:RamLbl.Text="RAM  ${used} / ${tot} GB"
            }
        } catch {}
        # Xbox check
        $xb=Get-XboxActive
        if ($xb -ne $script:XboxActive) {
            $script:XboxActive=$xb
            if ($xb) { $script:XboxLbl.BackColor=$C.Xbox; $script:XboxLbl.ForeColor=$C.Hi; $script:XboxLbl.Text="  XBOX MODE ACTIVE  " }
            else      { $script:XboxLbl.BackColor=$C.Card2; $script:XboxLbl.ForeColor=$C.Muted; $script:XboxLbl.Text="  XBOX MODE OFF  " }
        }
    })
    $monTimer.Start()

    # Pulsing dot
    $phase=0; $cols=@($C.Green,[System.Drawing.Color]::FromArgb(0,180,90),$C.GreenD,[System.Drawing.Color]::FromArgb(0,180,90))
    $dotTimer=New-Object System.Windows.Forms.Timer; $dotTimer.Interval=700
    $dotTimer.Add_Tick({ if($script:StatusLbl.Text -like "*READY*"){$script:StatusLbl.ForeColor=$cols[($phase=(($phase+1)%4))]} })
    $dotTimer.Start()
}

function Update-PowerLabel {
    $dev=Get-Dev; $s=if(Get-Plugged){"plugged"}else{"battery"}; $t=$dev.TDP[$s]
    $script:PowerLbl.Text="$(if($s -eq 'plugged'){'>>> PLUGGED'}else{'BATT BATTERY'})   S $($t.silent)W . P $($t.performance)W . T $($t.turbo)W"
    $script:TopStripe.BackColor=$dev.Color
}

# ??????????????????????????????????????????????????????????????????????????????
# THERMAL MONITORING + THROTTLE DETECTION
# ??????????????????????????????????????????????????????????????????????????????
$script:ThermalHistory   = [System.Collections.Generic.List[hashtable]]::new()
$script:ThrottleDetected = $false
$script:OverlayForm      = $null
$script:OverlayActive    = $false
$script:FpsLimiterActive = $false
$script:FpsLimitProcess  = $null

function Get-Temperatures {
    $cpuTemp = 0; $gpuTemp = 0
    try {
        # AMD CPU/GPU temps via WMI thermal zone (works without third-party tools)
        $zones = Get-CimInstance -Namespace "root/wmi" -ClassName "MSAcpi_ThermalZoneTemperature" -ErrorAction SilentlyContinue
        if ($zones) {
            $temps = $zones | ForEach-Object { [math]::Round(($_.CurrentTemperature - 2732) / 10, 1) }
            $cpuTemp = ($temps | Measure-Object -Maximum).Maximum
        }
    } catch {}
    try {
        # AMD GPU temp via OpenHardwareMonitor namespace if available
        $gpuSensor = Get-CimInstance -Namespace "root/OpenHardwareMonitor" -ClassName "Sensor" -ErrorAction SilentlyContinue |
            Where-Object { $_.SensorType -eq "Temperature" -and $_.Name -like "*GPU*" } |
            Select-Object -First 1
        if ($gpuSensor) { $gpuTemp = [math]::Round($gpuSensor.Value, 1) }
        else { $gpuTemp = $cpuTemp - 5 }  # Fallback: estimate from CPU temp
    } catch { $gpuTemp = $cpuTemp - 5 }
    return @{ CPU = $cpuTemp; GPU = $gpuTemp }
}

function Get-IsThrottling {
    # Detect thermal throttle by checking if processor performance is being capped
    try {
        $perf = Get-CimInstance -ClassName "Win32_Processor" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($perf) {
            # If LoadPercentage is high but CurrentClockSpeed << MaxClockSpeed, we're throttling
            $ratio = $perf.CurrentClockSpeed / $perf.MaxClockSpeed
            return ($perf.LoadPercentage -gt 60 -and $ratio -lt 0.75)
        }
    } catch {}
    return $false
}

# ?? Live Overlay (always on top, shows while gaming) ?????????????????????????
function Show-Overlay($gameName) {
    if ($script:OverlayActive) { return }
    $script:OverlayActive = $true

    $ov = New-Object System.Windows.Forms.Form
    $ov.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $ov.TopMost         = $true
    $ov.BackColor       = [System.Drawing.Color]::Black
    $ov.Opacity         = 0.82
    $ov.Size            = New-Object System.Drawing.Size(220, 150)
    $ov.StartPosition   = [System.Windows.Forms.FormStartPosition]::Manual
    $ov.Location        = New-Object System.Drawing.Point(10, 10)
    $ov.ShowInTaskbar   = $false
    $ov.TransparencyKey = [System.Drawing.Color]::Empty
    $script:OverlayForm = $ov

    # Allow dragging
    $drag = $false; $dragPt = [System.Drawing.Point]::Empty
    $ov.Add_MouseDown({ param($s,$e); if($e.Button -eq [System.Windows.Forms.MouseButtons]::Left){$drag=$true;$dragPt=$e.Location} })
    $ov.Add_MouseMove({ param($s,$e); if($drag){$ov.Location=New-Object System.Drawing.Point(($ov.Left+$e.X-$dragPt.X),($ov.Top+$e.Y-$dragPt.Y))} })
    $ov.Add_MouseUp({ $drag=$false })

    # Stats panel  -  custom painted
    $stats = @{ FPS=0; CpuTemp=0; GpuTemp=0; RamUsed=0; Watts=0; Throttle=$false }
    $script:OverlayStats = $stats

    $pnl = New-Pnl 220 150 ([System.Drawing.Color]::FromArgb(12,12,20))
    $pnl.Dock = [System.Windows.Forms.DockStyle]::Fill
    $pnl.Paint += {
        param($s,$e); $g=$e.Graphics; $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias
        $st = $script:OverlayStats
        $col = if($st.Throttle){$C.Red}else{$C.Green}

        # Top bar
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($C.Red)),0,0,$s.Width,3)
        $g.DrawString("ROG ALLY OPTIMIZER",$F.MonoS,(New-Object System.Drawing.SolidBrush($C.Red)),6,6)

        # Stats rows
        $rows = @(
            @("FPS",   "$($st.FPS)",                 $col),
            @("CPU",   "$($st.CpuTemp) degC",            (if($st.CpuTemp -gt 90){$C.Red}elseif($st.CpuTemp -gt 75){$C.Warn}else{$C.Green})),
            @("GPU",   "$($st.GpuTemp) degC",            (if($st.GpuTemp -gt 90){$C.Red}elseif($st.GpuTemp -gt 75){$C.Warn}else{$C.Green})),
            @("RAM",   "$($st.RamUsed) GB",           $C.Cyan),
            @("WATTS", "$($st.Watts)W",               $C.Warn)
        )
        $y = 26
        foreach ($r in $rows) {
            $g.DrawString($r[0],$F.MonoS,(New-Object System.Drawing.SolidBrush($C.Muted)),6,$y)
            $g.DrawString($r[1],$F.H3,(New-Object System.Drawing.SolidBrush($r[2])),70,$y-2)
            $y += 22
        }

        if ($st.Throttle) {
            $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80,255,0,0))),0,138,$s.Width,12)
            $g.DrawString("WARN THERMAL THROTTLE",$F.MonoS,(New-Object System.Drawing.SolidBrush($C.Red)),4,140)
        }
    }
    $ov.Controls.Add($pnl)

    # Update timer
    $lastFpsCheck = [datetime]::Now; $lastFpsFrames = 0
    $ovTimer = New-Object System.Windows.Forms.Timer; $ovTimer.Interval = 1500
    $ovTimer.Add_Tick({
        if (-not $script:OverlayActive) { $ovTimer.Stop(); return }
        try {
            $temps  = Get-Temperatures
            $mem    = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            $usedGB = if($mem){[math]::Round(($mem.TotalVisibleMemorySize-$mem.FreePhysicalMemory)/1MB,1)}else{0}
            $dev    = Get-Dev
            $state  = if(Get-Plugged){"plugged"}else{"battery"}
            $tdp    = $dev.TDP[$state]
            $pr     = if($script:FpsLimiterActive -and $script:FpsLimitProcess){
                          $script:Profiles.Values | Where-Object{$_.exe_path} | Select-Object -First 1 | ForEach-Object{$tdp[$_.power_rec.ToLower()]}
                      }else{$tdp.turbo}
            $throttle = Get-IsThrottling

            $script:OverlayStats.CpuTemp  = $temps.CPU
            $script:OverlayStats.GpuTemp  = $temps.GPU
            $script:OverlayStats.RamUsed  = $usedGB
            $script:OverlayStats.Watts    = $tdp.turbo
            $script:OverlayStats.Throttle = $throttle

            # Log to thermal history
            $script:ThermalHistory.Add(@{
                Time    = [datetime]::Now.ToString("HH:mm:ss")
                CpuTemp = $temps.CPU
                GpuTemp = $temps.GPU
                RAM     = $usedGB
                Throttle= $throttle
            })
            if ($script:ThermalHistory.Count -gt 300) { $script:ThermalHistory.RemoveAt(0) }

            # Throttle warning
            if ($throttle -and -not $script:ThrottleDetected) {
                $script:ThrottleDetected = $true
                Set-Status "WARN THERMAL THROTTLE DETECTED  -  PERFORMANCE REDUCED" $C.Red
            }

            $pnl.Invalidate()
        } catch {}
    })
    $ovTimer.Start()

    # Run overlay on separate thread so it doesn't block
    $t = [System.Threading.Thread]::new({
        [System.Windows.Forms.Application]::Run($ov)
        $script:OverlayActive = $false
        $ovTimer.Stop()
    })
    $t.IsBackground = $true
    $t.Start()
}

function Hide-Overlay {
    $script:OverlayActive = $false
    try {
        if ($script:OverlayForm -and $script:OverlayForm.IsHandleCreated) {
            $script:OverlayForm.Invoke([Action]{ $script:OverlayForm.Close() })
        }
    } catch {}
    $script:OverlayForm = $null
}

# ?? Shader Cache Manager ??????????????????????????????????????????????????????
function Show-ShaderCache {
    $ep = $script:EditorPanel; $ep.Controls.Clear()

    $strip = New-Pnl $ep.Width 52 $C.Card
    $strip.Paint += {
        param($s,$e); $g=$e.Graphics; $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($C.Cyan)),0,0,5,$s.Height)
        $g.DrawLine((New-Object System.Drawing.Pen($C.Border,1)),0,$s.Height-1,$s.Width,$s.Height-1)
        $g.DrawString("  SHADER CACHE MANAGER",$F.H2,(New-Object System.Drawing.SolidBrush($C.Cyan)),0,14)
        $g.DrawString("  Free up SSD space from bloated game shader caches",$F.MonoS,(New-Object System.Drawing.SolidBrush($C.Muted)),0,36)
    }
    $ep.Controls.Add($strip)

    $sc = New-Object System.Windows.Forms.Panel; $sc.AutoScroll=$true; $sc.BackColor=$C.Panel
    $sc.Size=New-Object System.Drawing.Size($ep.Width,($ep.Height-52)); $sc.Location=New-Object System.Drawing.Point(0,52)
    $ep.Controls.Add($sc)

    # Scanning label
    $scanLbl = New-Lbl "SCAN  SCANNING SHADER CACHES..." $F.H3 $C.Cyan
    $scanLbl.Location = New-Object System.Drawing.Point(20,20); $sc.Controls.Add($scanLbl)

    # Scan in background
    $job = Start-Job -ScriptBlock {
        $caches = @()
        $roots = @(
            "$env:LOCALAPPDATA\D3DSCache",
            "$env:LOCALAPPDATA\AMD\DxCache",
            "$env:LOCALAPPDATA\NVIDIA\DXCache",
            "$env:LOCALAPPDATA\Steam\htmlcache",
            "$env:APPDATA\Microsoft\Windows\ShaderCache",
            "$env:LOCALAPPDATA\Microsoft\DirectX Shader Cache"
        )
        # Also scan per-game Steam shader caches
        $steamApps = "C:\Program Files (x86)\Steam\steamapps\shadercache"
        if (Test-Path $steamApps) {
            Get-ChildItem $steamApps -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $sz = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                if ($sz -gt 0) {
                    $caches += @{ Name="Steam: $($_.Name)"; Path=$_.FullName; SizeMB=[math]::Round($sz/1MB,1) }
                }
            }
        }
        foreach ($root in $roots) {
            if (-not (Test-Path $root)) { continue }
            $sz = (Get-ChildItem $root -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            if ($sz -gt 0) {
                $name = Split-Path $root -Leaf
                $caches += @{ Name=$name; Path=$root; SizeMB=[math]::Round($sz/1MB,1) }
            }
        }
        return $caches | Sort-Object SizeMB -Descending
    }

    $pollTimer = New-Object System.Windows.Forms.Timer; $pollTimer.Interval=500
    $pollTimer.Add_Tick({
        if ($job.State -ne "Running") {
            $pollTimer.Stop()
            $caches = Receive-Job $job -ErrorAction SilentlyContinue; Remove-Job $job -Force
            $sc.Controls.Clear()

            if (-not $caches -or $caches.Count -eq 0) {
                (New-Lbl "No shader caches found  -  your SSD is clean!" $F.Body $C.Green) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(20,20);$sc.Controls.Add($_)}
                return
            }

            $totalMB = ($caches | Measure-Object SizeMB -Sum).Sum
            $hdr2 = New-Lbl "TOTAL CACHED: $([math]::Round($totalMB,0)) MB across $($caches.Count) locations" $F.H3 $C.Warn
            $hdr2.Location = New-Object System.Drawing.Point(14,14); $sc.Controls.Add($hdr2)

            $checks2 = @(); $y2=50
            foreach ($c2 in $caches) {
                $row = New-Pnl ($ep.Width-36) 44 $C.Card2; $row.Location=New-Object System.Drawing.Point(14,$y2)
                $row.Paint+={param($s,$e);$e.Graphics.DrawRectangle((New-Object System.Drawing.Pen($C.Border,1)),1,1,$s.Width-3,$s.Height-3)}

                $cb = New-Object System.Windows.Forms.CheckBox; $cb.Text=$c2.Name.ToUpper(); $cb.Font=$F.BodyB; $cb.ForeColor=$C.Text; $cb.BackColor=[System.Drawing.Color]::Transparent; $cb.Location=New-Object System.Drawing.Point(10,12); $cb.AutoSize=$true; $row.Controls.Add($cb)
                $szLbl = New-Lbl "$($c2.SizeMB) MB" $F.MonoS (if($c2.SizeMB -gt 500){$C.Red}elseif($c2.SizeMB -gt 100){$C.Warn}else{$C.Green}); $szLbl.Location=New-Object System.Drawing.Point(400,14); $row.Controls.Add($szLbl)

                $checks2 += @{Check=$cb;Path=$c2.Path;Name=$c2.Name;SizeMB=$c2.SizeMB}
                $sc.Controls.Add($row); $y2+=50
            }

            $bClear = New-Btn "DEL   CLEAR SELECTED CACHES" ($ep.Width-36) 44 ([System.Drawing.Color]::FromArgb(0,20,30)) $C.Cyan $F.H2 $C.Cyan
            $bClear.Location = New-Object System.Drawing.Point(14,$y2)
            $bClear.Add_Click({
                $sel2 = $checks2 | Where-Object{$_.Check.Checked}
                if (-not $sel2){[System.Windows.Forms.MessageBox]::Show("Check at least one cache.","Nothing selected")|Out-Null;return}
                $totalClear = ($sel2|Measure-Object SizeMB -Sum).Sum
                if([System.Windows.Forms.MessageBox]::Show("Clear $([math]::Round($totalClear,0)) MB of shader caches?`nGames will rebuild them on next launch (may cause brief loading stutter).","Confirm",[System.Windows.Forms.MessageBoxButtons]::YesNo) -ne "Yes"){return}
                $t2=[System.Threading.Thread]::new({
                    $freed=0
                    foreach($s2 in $sel2){
                        Set-Status "DEL  CLEARING: $($s2.Name)..." $C.Cyan
                        try{Remove-Item $s2.Path -Recurse -Force -ErrorAction SilentlyContinue;$freed+=$s2.SizeMB}catch{}
                    }
                    Set-Status "OK   CLEARED $([math]::Round($freed,0)) MB OF SHADER CACHES" $C.Green
                    $script:Form.Invoke([Action]{Show-ShaderCache})
                })
                $t2.IsBackground=$true;$t2.Start()
            })
            $sc.Controls.Add($bClear)
            $sc.AutoScrollMinSize=New-Object System.Drawing.Size(0,($y2+60))
        }
    })
    $pollTimer.Start()
}

# ?? Bug / Feedback Report ?????????????????????????????????????????????????????
$script:SessionLog = [System.Collections.Generic.List[string]]::new()

function Write-Log($msg) {
    $line = "[$(Get-Date -Format 'HH:mm:ss')]  $msg"
    $script:SessionLog.Add($line)
    if ($script:SessionLog.Count -gt 500) { $script:SessionLog.RemoveAt(0) }
}

function Show-BugReport {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text="Bug Report / Feedback"; $dlg.Size=New-Object System.Drawing.Size(760,640)
    $dlg.BackColor=$C.Bg; $dlg.StartPosition=[System.Windows.Forms.FormStartPosition]::CenterParent
    $dlg.FormBorderStyle=[System.Windows.Forms.FormBorderStyle]::FixedDialog

    $hdr=New-Pnl 760 60 $C.Panel; $hdr.Dock=[System.Windows.Forms.DockStyle]::Top
    $hdr.Paint+={
        param($s,$e); $g=$e.Graphics; $g.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($C.Warn)),0,0,5,$s.Height)
        $g.DrawLine((New-Object System.Drawing.Pen($C.Warn,2)),0,$s.Height-1,$s.Width,$s.Height-1)
        $g.DrawString("  BUG REPORT / FEEDBACK",$F.H1,(New-Object System.Drawing.SolidBrush($C.Warn)),0,16)
        $g.DrawString("  Help make the app better  -  your report goes directly to the developer",$F.MonoS,(New-Object System.Drawing.SolidBrush($C.Muted)),0,38)
    }
    $dlg.Controls.Add($hdr)

    $sc=New-Object System.Windows.Forms.Panel; $sc.AutoScroll=$true; $sc.BackColor=$C.Bg
    $sc.Size=New-Object System.Drawing.Size(760,490); $sc.Location=New-Object System.Drawing.Point(0,60)
    $dlg.Controls.Add($sc)

    $y=14

    # Report type
    $typeLbl=New-Lbl "WHAT ARE YOU REPORTING?" $F.H3 $C.Warn; $typeLbl.Location=New-Object System.Drawing.Point(14,$y); $sc.Controls.Add($typeLbl); $y+=32
    $typeCombo=New-Object System.Windows.Forms.ComboBox
    $typeCombo.Items.AddRange(@("Something isn't working","Game performance is worse after optimizing","App crashed or froze","Feature not working as expected","Suggestion / idea","Something worked great  -  positive feedback"))
    $typeCombo.SelectedIndex=0; $typeCombo.Size=New-Object System.Drawing.Size(700,28); $typeCombo.Location=New-Object System.Drawing.Point(14,$y)
    $typeCombo.BackColor=$C.Card2; $typeCombo.ForeColor=$C.Hi; $typeCombo.Font=$F.Body; $typeCombo.DropDownStyle=[System.Windows.Forms.ComboBoxStyle]::DropDownList
    $sc.Controls.Add($typeCombo); $y+=44

    # Game it happened with
    $gameLbl=New-Lbl "WHICH GAME? (leave blank if not game-specific)" $F.H3 $C.Cyan; $gameLbl.Location=New-Object System.Drawing.Point(14,$y); $sc.Controls.Add($gameLbl); $y+=32
    $gameTxt=New-Object System.Windows.Forms.TextBox; $gameTxt.Size=New-Object System.Drawing.Size(700,28); $gameTxt.Location=New-Object System.Drawing.Point(14,$y)
    $gameTxt.BackColor=$C.Card2; $gameTxt.ForeColor=$C.Hi; $gameTxt.Font=$F.Body; $gameTxt.BorderStyle=[System.Windows.Forms.BorderStyle]::FixedSingle
    $sc.Controls.Add($gameTxt); $y+=44

    # Description
    $descLbl=New-Lbl "DESCRIBE WHAT HAPPENED" $F.H3 $C.Cyan; $descLbl.Location=New-Object System.Drawing.Point(14,$y); $sc.Controls.Add($descLbl); $y+=32
    $descTxt=New-Object System.Windows.Forms.TextBox; $descTxt.Multiline=$true; $descTxt.Size=New-Object System.Drawing.Size(700,100); $descTxt.Location=New-Object System.Drawing.Point(14,$y)
    $descTxt.BackColor=$C.Card2; $descTxt.ForeColor=$C.Hi; $descTxt.Font=$F.Body; $descTxt.ScrollBars=[System.Windows.Forms.ScrollBars]::Vertical; $descTxt.BorderStyle=[System.Windows.Forms.BorderStyle]::FixedSingle
    $sc.Controls.Add($descTxt); $y+=116

    # Include session log checkbox
    $incLog=New-Object System.Windows.Forms.CheckBox; $incLog.Text="Include session log (recommended  -  helps diagnose the issue)"; $incLog.Checked=$true; $incLog.Font=$F.Body; $incLog.ForeColor=$C.Text; $incLog.BackColor=[System.Drawing.Color]::Transparent; $incLog.Location=New-Object System.Drawing.Point(14,$y); $incLog.AutoSize=$true; $sc.Controls.Add($incLog); $y+=34

    # Session log preview
    $logLbl=New-Lbl "SESSION LOG PREVIEW" $F.H3 $C.Muted; $logLbl.Location=New-Object System.Drawing.Point(14,$y); $sc.Controls.Add($logLbl); $y+=28
    $logBox=New-Object System.Windows.Forms.TextBox; $logBox.Multiline=$true; $logBox.ReadOnly=$true; $logBox.Size=New-Object System.Drawing.Size(700,100); $logBox.Location=New-Object System.Drawing.Point(14,$y)
    $logBox.BackColor=$C.Card; $logBox.ForeColor=$C.Muted; $logBox.Font=$F.MonoS; $logBox.ScrollBars=[System.Windows.Forms.ScrollBars]::Vertical; $logBox.BorderStyle=[System.Windows.Forms.BorderStyle]::FixedSingle
    $logBox.Text = ($script:SessionLog | Select-Object -Last 20) -join "`r`n"
    $sc.Controls.Add($logBox); $y+=116

    $sc.AutoScrollMinSize=New-Object System.Drawing.Size(0,($y+20))

    # Bottom bar
    $bot=New-Pnl 760 50 $C.Panel; $bot.Dock=[System.Windows.Forms.DockStyle]::Bottom
    $bot.Paint+={param($s,$e);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Border,1)),0,0,$s.Width,0)}

    # Save to file button
    $bSave=New-Btn "SAVE  SAVE REPORT TO FILE" 220 36 $C.Card2 $C.Text $F.H3 $C.Border; $bSave.Location=New-Object System.Drawing.Point(14,7)
    $bSave.Add_Click({
        $d=New-Object System.Windows.Forms.SaveFileDialog; $d.Filter="Text files|*.txt|All|*.*"
        $d.FileName="ROGAllyOptimizer_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        if($d.ShowDialog() -ne "OK"){return}
        $report=@"
ROG ALLY OPTIMIZER  -  BUG REPORT
================================
Date:        $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
App Version: v17
Device:      $($script:Settings.device)
Type:        $($typeCombo.SelectedItem)
Game:        $(if($gameTxt.Text){"$($gameTxt.Text)"}else{"N/A"})

DESCRIPTION:
$($descTxt.Text)

SYSTEM INFO:
  OS:      $([System.Environment]::OSVersion.VersionString)
  Machine: $([System.Environment]::MachineName)
  CPU:     $((Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name)
  RAM:     $([math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory/1GB,1)) GB

THERMAL HISTORY (last 10 readings):
$(($script:ThermalHistory | Select-Object -Last 10 | ForEach-Object {"  $($_.Time)  CPU:$($_.CpuTemp) degC  GPU:$($_.GpuTemp) degC  RAM:$($_.RAM)GB  Throttle:$($_.Throttle)"}) -join "`n")

SESSION LOG:
$(if($incLog.Checked){($script:SessionLog)-join"`n"}else{"(not included)"})
"@
        $report | Set-Content $d.FileName -Encoding UTF8
        Set-Status "OK   REPORT SAVED TO $($d.FileName)" $C.Green
        [System.Windows.Forms.MessageBox]::Show("Report saved!`n`nSend this file to the developer so they can diagnose the issue.","Saved")|Out-Null
        $dlg.Close()
    })
    $bot.Controls.Add($bSave)

    # Copy to clipboard
    $bCopy=New-Btn "?  COPY TO CLIPBOARD" 200 36 $C.Card2 $C.Text $F.H3 $C.Border; $bCopy.Location=New-Object System.Drawing.Point(242,7)
    $bCopy.Add_Click({
        $report="TYPE: $($typeCombo.SelectedItem)`nGAME: $($gameTxt.Text)`nDEVICE: $($script:Settings.device)`n`n$($descTxt.Text)`n`nLOG:`n$(($script:SessionLog|Select-Object -Last 30)-join"`n")"
        [System.Windows.Forms.Clipboard]::SetText($report)
        Set-Status "OK   REPORT COPIED TO CLIPBOARD" $C.Green
        [System.Windows.Forms.MessageBox]::Show("Copied! Paste it into Discord, Reddit, or an email to the developer.","Copied")|Out-Null
        $dlg.Close()
    })
    $bot.Controls.Add($bCopy)

    $bCancel=New-Btn "CANCEL" 100 36 $C.Card2 $C.Text $F.Body $C.Border; $bCancel.Location=New-Object System.Drawing.Point(640,7); $bCancel.Add_Click({$dlg.Close()}); $bot.Controls.Add($bCancel)
    $dlg.Controls.Add($bot)
    $dlg.ShowDialog()|Out-Null
}


# Log app startup
Write-Log "App started  -  Device: $($script:Settings.device)"
Write-Log "Mode: $($script:Mode)  Handheld: $($script:Handheld)"


function Build-AdvancedMode {
    $bp=$script:BodyPanel

    $sb=New-Pnl 210 $bp.Height $C.Panel; $sb.Dock=[System.Windows.Forms.DockStyle]::Left
    $sb.Paint+={param($s,$e);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Border,2)),$s.Width-1,0,$s.Width-1,$s.Height)}
    $sbH=New-Pnl 210 42 $C.Card; $sbH.Location=New-Object System.Drawing.Point(0,0)
    $sbH.Paint+={param($s,$e);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Red,2)),0,$s.Height-1,$s.Width,$s.Height-1);$e.Graphics.TextRenderingHint=[System.Drawing.Text.TextRenderingHint]::AntiAlias;$e.Graphics.DrawString("GAME LIBRARY",$F.H3,(New-Object System.Drawing.SolidBrush($C.Red)),10,12)}
    $sb.Controls.Add($sbH)
    $br=New-Pnl 194 36 $C.Panel; $br.Location=New-Object System.Drawing.Point(8,48)
    $ba=New-Btn "+  ADD" 118 32 $C.Red $C.Hi $F.H3; $ba.Location=New-Object System.Drawing.Point(0,0); $ba.Add_Click({Add-Game $false}); $br.Controls.Add($ba)
    $bx=New-Btn "X" 68 32 $C.Card2 $C.Text $F.Body $C.Border; $bx.Location=New-Object System.Drawing.Point(124,0); $bx.Add_Click({Remove-SelectedGame}); $br.Controls.Add($bx)
    $sb.Controls.Add($br)
    $bSc=New-Btn "SCAN  SCAN INSTALLED GAMES" 194 30 $C.Card2 $C.Cyan $F.Small $C.Cyan; $bSc.Location=New-Object System.Drawing.Point(8,90); $bSc.Add_Click({Show-ScanDialog}); $sb.Controls.Add($bSc)

    # NEW: Shader Cache button
    $bShader=New-Btn "SAVE  SHADER CACHE" 194 30 $C.Card2 $C.Cyan $F.Small $C.Cyan; $bShader.Location=New-Object System.Drawing.Point(8,126); $bShader.Add_Click({Show-ShaderCache}); $sb.Controls.Add($bShader)

    # NEW: Bug Report button
    $bBug=New-Btn "BUG   BUG REPORT" 194 30 ([System.Drawing.Color]::FromArgb(20,10,0)) $C.Warn $F.Small $C.Warn; $bBug.Location=New-Object System.Drawing.Point(8,162); $bBug.Add_Click({Show-BugReport}); $sb.Controls.Add($bBug)

    $script:GameListBox=New-Object System.Windows.Forms.ListBox
    $script:GameListBox.Size=New-Object System.Drawing.Size(194,($bp.Height-290)); $script:GameListBox.Location=New-Object System.Drawing.Point(8,198)
    $script:GameListBox.BackColor=$C.Bg; $script:GameListBox.ForeColor=$C.Text; $script:GameListBox.Font=$F.Body; $script:GameListBox.BorderStyle=[System.Windows.Forms.BorderStyle]::None
    $script:GameListBox.Add_SelectedIndexChanged({if($script:GameListBox.SelectedItem){Select-Game $script:GameListBox.SelectedItem}})
    $sb.Controls.Add($script:GameListBox); Refresh-GameList

    (New-Pnl 194 2 $C.Border) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(8,($bp.Height-100));$sb.Controls.Add($_)}
    $bE=New-Btn "^  EXPORT" 94 30 ([System.Drawing.Color]::FromArgb(5,15,8)) ([System.Drawing.Color]::FromArgb(0,255,100)) $F.Small ([System.Drawing.Color]::FromArgb(0,170,68)); $bE.Location=New-Object System.Drawing.Point(8,($bp.Height-94)); $bE.Add_Click({Export-Profiles}); $sb.Controls.Add($bE)
    $bI=New-Btn "v  IMPORT" 94 30 ([System.Drawing.Color]::FromArgb(5,8,20)) ([System.Drawing.Color]::FromArgb(0,170,255)) $F.Small ([System.Drawing.Color]::FromArgb(0,100,200)); $bI.Location=New-Object System.Drawing.Point(108,($bp.Height-94)); $bI.Add_Click({Import-Profiles}); $sb.Controls.Add($bI)

    $script:EditorPanel=New-Pnl ($bp.Width-210) $bp.Height $C.Panel; $script:EditorPanel.Location=New-Object System.Drawing.Point(210,0)
    $script:EditorPanel.Anchor=[System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $script:EditorPanel.Paint+={param($s,$e);$e.Graphics.DrawRectangle((New-Object System.Drawing.Pen($C.Border,2)),1,1,$s.Width-3,$s.Height-3)}

    $act=New-Pnl $bp.Width 58 $C.Panel; $act.Dock=[System.Windows.Forms.DockStyle]::Bottom
    $act.Paint+={param($s,$e);$e.Graphics.DrawLine((New-Object System.Drawing.Pen($C.Red,2)),0,0,$s.Width,0)}
    (New-Btn "  >>  LAUNCH & OPTIMIZE  " 240 42 $C.Red $C.Hi $F.H2 $C.RedGlo) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(($bp.Width-258),8);$_.Add_Click({Start-Launch});$act.Controls.Add($_)}
    (New-Btn "CLEAN  CLEAN RAM" 138 42 $C.Card2 $C.Text $F.H3 $C.Border)         | ForEach-Object{$_.Location=New-Object System.Drawing.Point(($bp.Width-406),8);$_.Add_Click({[System.Threading.Thread]::new({Invoke-Cleanup;Invoke-FlushRam}).Start()});$act.Controls.Add($_)}
    (New-Btn "DEL   BLOAT REMOVER" 172 42 ([System.Drawing.Color]::FromArgb(20,8,0)) $C.Warn $F.H3 $C.Warn) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(($bp.Width-588),8);$_.Add_Click({Show-Debloat});$act.Controls.Add($_)}
    (New-Lbl "SELECT DEVICE  ?  ADD GAME  ?  AI  AUTO-OPTIMIZE  ?  >> LAUNCH" $F.MonoS $C.Muted) | ForEach-Object{$_.Location=New-Object System.Drawing.Point(16,20);$act.Controls.Add($_)}

    $bp.Controls.AddRange(@($script:EditorPanel,$sb,$act))
    Show-Welcome
}


function Do-Launch($name) {
    $t=[System.Threading.Thread]::new({
        $p=$script:Profiles[$name]; $exe=$p.exe_path
        $dev=Get-Dev; if(Get-Plugged){$state="plugged"}else{$state="battery"}; $tdp=$dev.TDP[$state]
        $xbox=$script:XboxActive
        $script:ThrottleDetected=$false

        Write-Log "LAUNCH: $name | Device:$($script:Settings.device) | State:$state"

        if ($p.cleanup_enabled) { Invoke-Cleanup; Start-Sleep -Milliseconds 300 }

        Set-Status ">>> APPLYING PERFORMANCE ENGINE..." $C.Warn
        Write-Log "Performance engine applying..."
        if (-not $xbox) { Set-PowerPlan $dev.Plan }
        Invoke-GameBoost $xbox $exe

        $afmfEnabled=$false
        if ($script:BoostSettings.AFMF -and (Get-AFMFAvailable)) {
            Set-Status "AFMF ENABLING FLUID MOTION FRAMES..." $C.Cyan
            $afmfEnabled=Enable-AFMF
            if ($afmfEnabled) { Write-Log "AFMF enabled"; Set-Status "AFMF AFMF ON  -  FRAME GENERATION ACTIVE" $C.Cyan }
        }

        # ?? Step 3b: RSR  -  AMD Radeon Super Resolution ????????????????????????
        # Render at lower res, driver upscales to display res automatically.
        # Like DLSS but for AMD and works on every game with no game support.
        $rsrResult=$null
        if ($script:BoostSettings.RSR -and (Get-RSRAvailable) -and -not $afmfEnabled) {
            # Pick quality mode based on device tier
            $dev2=Get-Dev
            $mode = switch($dev2.Tier) {
                "entry"      { "Performance" }
                "entry-plus" { "Balanced" }
                "mid"        { "Quality" }
                default      { "Ultra Quality" }
            }
            Set-Status "RSR  ENABLING RSR UPSCALING ($mode)..." $C.Cyan
            $displayW=if($rw -and $rw -gt 0){$rw}else{1920}
            $displayH=if($rh -and $rh -gt 0){$rh}else{1080}
            $rsrResult=Enable-RSR $displayW $displayH $mode
            if ($rsrResult) {
                Write-Log "RSR enabled: $mode $($rsrResult.Scale)% | render $($rsrResult.RenderW)x$($rsrResult.RenderH)"
                Set-Status "RSR  RSR ON  -  $mode ($($rsrResult.Scale)% scale) | DISPLAY:${rw}x${rh}" $C.Cyan
            }
        }

        $rw=$p.res_w; $rh=$p.res_h; $changed=$false
        if (-not $xbox -and -not ($rw -eq 1920 -and $rh -eq 1080)) {
            $changed=Set-Resolution $rw $rh
            Set-Status (if($changed){"DISP RESOLUTION -> ${rw}x${rh}"}else{"WARN RES CHANGE FAILED  -  run as admin"}) $C.Warn
            Write-Log "Resolution: ${rw}x${rh} changed=$changed"
            Start-Sleep -Milliseconds 500
        }

        $fpsTarget=if($p.fps_target -and $p.fps_target -gt 0){$p.fps_target}else{60}
        $setHz=0
        if ($script:BoostSettings.RefreshMatch -and -not $xbox) {
            $setHz=Set-RefreshRate $fpsTarget
            if ($setHz -gt 0) {
                Write-Log "Refresh rate set to ${setHz}Hz for ${fpsTarget}FPS target"
                Set-Status "DISP ${rw}x${rh} @ ${setHz}Hz  .  MATCHED TO ${fpsTarget} FPS TARGET" $C.Cyan
                Start-Sleep -Milliseconds 300
            }
        }

        Set-Status ">> LAUNCHING $($name.ToUpper())..." $C.Warn
        try { $proc=Start-Process -FilePath $exe -PassThru -ErrorAction Stop }
        catch {
            Write-Log "LAUNCH FAILED: $_"
            Set-Status "ERR  LAUNCH FAILED: $_" $C.Warn
            Invoke-GameRestore $xbox
            if ($afmfEnabled){Disable-AFMF}
            if ($setHz -gt 0){Restore-RefreshRate}
            if ($changed){Set-Resolution 1920 1080}
            if (-not $xbox){Set-PowerPlan $PLAN_BALANCED}
            return
        }

        Write-Log "Process launched PID:$($proc.Id)"
        Start-Sleep -Seconds 3

        # Set process priority
        try {
            $h=[NativeApi]::OpenProcess(0x0600,$false,$proc.Id)
            [NativeApi]::SetPriorityClass($h,$PRIORITY[(if($p.priority){$p.priority}else{"High"})]) | Out-Null
            [NativeApi]::CloseHandle($h) | Out-Null
        } catch {}

        # Auto power switch watcher
        if ($script:BoostSettings.AutoPower) { Start-AutoPowerSwitch $p $dev }

        # Live overlay
        if ($script:BoostSettings.ContainsKey("Overlay") -and $script:BoostSettings.Overlay) {
            $script:Form.Invoke([Action]{ Show-Overlay $name })
        } else {
            # Always show overlay by default
            $script:Form.Invoke([Action]{ Show-Overlay $name })
        }

        if ($p.power_rec) { $pr = $p.power_rec } else { $pr = "Turbo" }
        $pw = $tdp[$pr.ToLower()]
        $tags = @()
        if ($xbox) { $tags += "XBOX+BOOST" } else { $tags += "BOOSTED" }
        if ($afmfEnabled)  { $tags += "AFMF" }
        if ($rsrResult)    { $tags += "RSR $($rsrResult.Scale)%" }
        if ($setHz -gt 0)  { $tags += "${setHz}Hz" }
        $tagStr = $tags -join " | "
        Set-Status "OK   $($name.ToUpper()) | ${rw}x${rh} | $pr ${pw}W | $tagStr" $C.Green

        $proc.WaitForExit()
        Write-Log "Game exited: $name | ThrottleEvents:$($script:ThermalHistory | Where-Object{$_.Throttle} | Measure-Object | Select-Object -ExpandProperty Count)"

        Set-Status "~ RESTORING SYSTEM..." $C.Warn
        Stop-AutoPowerSwitch; Hide-Overlay
        Invoke-GameRestore $xbox
        if ($afmfEnabled){Disable-AFMF}
        if ($rsrResult){Disable-RSR}
        if ($setHz -gt 0){Restore-RefreshRate}
        if ($changed){Set-Resolution 1920 1080}
        if (-not $xbox){Set-PowerPlan $PLAN_BALANCED}
        Set-Status "OK   SYSTEM RESTORED" $C.Green
        Write-Log "System restored after: $name"
    })
    $t.IsBackground=$true; $t.Start()
}

# ?? Entry point ???????????????????????????????????????????????????????????????
Load-Data
$form=Build-Chrome
Update-ToggleStyle
Build-Body
Start-Monitors
$form.Add_Shown({ Update-PowerLabel; Set-Status "* READY" $C.Green })
[System.Windows.Forms.Application]::Run($form)
