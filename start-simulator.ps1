$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$sdk = Join-Path $root '.build-tools\sdk'
$jdk = Get-ChildItem -LiteralPath (Join-Path $root '.build-tools\jdk') -Directory | Select-Object -First 1
$emulator = Join-Path $sdk 'emulator\emulator.exe'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$avdManager = Join-Path $sdk 'cmdline-tools\latest\bin\avdmanager.bat'
$avdHome = Join-Path $root '.avd'
$userHome = Join-Path $root '.android-user'
$avdConfig = Join-Path $avdHome 'Pocketwise_Pixel.ini'

if (-not $jdk) { throw 'Project-local Java is missing. Rebuild/setup Pocketwise first.' }
if (-not (Test-Path -LiteralPath $emulator)) { throw 'Android emulator is missing under .build-tools\sdk.' }
if (-not (Test-Path -LiteralPath (Join-Path $root 'Pocketwise.apk'))) { throw 'Pocketwise.apk is missing. Build it with .\build-apk.ps1 first.' }

New-Item -ItemType Directory -Force -Path $avdHome, $userHome | Out-Null
$env:JAVA_HOME = $jdk.FullName
$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk
$env:ANDROID_AVD_HOME = $avdHome
$env:ANDROID_USER_HOME = $userHome
$env:Path = "$($jdk.FullName)\bin;$env:Path"

if (-not (Test-Path -LiteralPath $avdConfig)) {
    $image = Join-Path $sdk 'system-images\android-35\google_apis\x86_64\system.img'
    if (-not (Test-Path -LiteralPath $image)) { throw 'Android 35 Google APIs x86_64 image is missing under .build-tools\sdk.' }
    $creationOutput = 'no' | & $avdManager create avd -n Pocketwise_Pixel -k 'system-images;android-35;google_apis;x86_64' -d pixel_8 2>&1
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $avdConfig)) { throw 'Could not create the Pocketwise Pixel emulator.' }
}

$device = (& $adb devices) | Select-String '^emulator-\d+\s+device' | Select-Object -First 1
$visibleEmulator = Get-Process -Name 'qemu-system-x86_64', 'emulator' -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if ($visibleEmulator) {
    $shell = New-Object -ComObject WScript.Shell
    [void]$shell.AppActivate([int]$visibleEmulator.Id)
}
else {
    if ($device) {
        $serial = (($device -split '\s+')[0])
        & $adb -s $serial emu kill | Out-Null
        for ($attempt = 0; $attempt -lt 15; $attempt++) {
            Start-Sleep -Seconds 1
            if (-not (Get-Process -Name 'qemu-system-x86_64' -ErrorAction SilentlyContinue)) { break }
        }
    }
    Start-Process -FilePath $emulator -ArgumentList @('-avd', 'Pocketwise_Pixel', '-no-snapshot-load') -WorkingDirectory $root | Out-Null
    & $adb start-server | Out-Null
    $device = $null
    $ready = $false
    for ($attempt = 0; $attempt -lt 90; $attempt++) {
        Start-Sleep -Seconds 2
        $device = (& $adb devices) | Select-String '^emulator-\d+\s+device'
        if ($device) { $ready = $true; break }
    }
    if (-not $ready) { throw 'The emulator did not start. Check that hardware virtualization is enabled.' }
}

$serial = (($device -split '\s+')[0])
$booted = $false
for ($attempt = 0; $attempt -lt 90; $attempt++) {
    $bootState = & $adb -s $serial shell getprop sys.boot_completed 2>$null
    if ($bootState -match '1') { $booted = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $booted) { throw 'The Android emulator started but did not finish booting.' }

& $adb -s $serial install -r (Join-Path $root 'Pocketwise.apk')
if ($LASTEXITCODE -ne 0) { throw 'Could not install Pocketwise.apk in the emulator.' }
& $adb -s $serial shell monkey -p ph.pocketwise.money 1 | Out-Null
Write-Host 'Pocketwise is open in the Pixel 8 simulator. Close this PowerShell window when you are done.'
