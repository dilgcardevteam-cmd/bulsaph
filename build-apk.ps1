$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$jdk = Get-ChildItem -LiteralPath (Join-Path $root '.build-tools\jdk') -Directory | Select-Object -First 1
if (-not $jdk) { throw 'Project-local JDK not found under .build-tools\jdk.' }
$env:JAVA_HOME = $jdk.FullName
$env:ANDROID_HOME = Join-Path $root '.build-tools\sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:Path = "$($jdk.FullName)\bin;$env:Path"

Push-Location $root
try {
    Copy-Item -LiteralPath (Join-Path $root 'index.html') -Destination (Join-Path $root 'www\index.html') -Force
    Copy-Item -LiteralPath (Join-Path $root 'app.js') -Destination (Join-Path $root 'www\app.js') -Force
    & (Join-Path $root 'node_modules\.bin\esbuild.cmd') (Join-Path $root 'app-entry.js') --bundle --platform=browser --format=iife --target=es2020 "--outfile=$(Join-Path $root 'app.bundle.js')"
    if ($LASTEXITCODE -ne 0) { throw 'Web app bundle failed.' }
    Copy-Item -LiteralPath (Join-Path $root 'app.bundle.js') -Destination (Join-Path $root 'www\app.bundle.js') -Force
    Copy-Item -LiteralPath (Join-Path $root 'styles.css') -Destination (Join-Path $root 'www\styles.css') -Force
    Copy-Item -LiteralPath (Join-Path $root 'manifest.webmanifest') -Destination (Join-Path $root 'www\manifest.webmanifest') -Force
    Copy-Item -LiteralPath (Join-Path $root 'icon.svg') -Destination (Join-Path $root 'www\icon.svg') -Force
    Copy-Item -LiteralPath (Join-Path $root 'app-icon.svg') -Destination (Join-Path $root 'www\app-icon.svg') -Force
    Copy-Item -LiteralPath (Join-Path $root 'brand-logo.svg') -Destination (Join-Path $root 'www\brand-logo.svg') -Force
    Copy-Item -LiteralPath (Join-Path $root 'app-icon.png') -Destination (Join-Path $root 'www\app-icon.png') -Force
    Copy-Item -LiteralPath (Join-Path $root 'loading-screen.png') -Destination (Join-Path $root 'www\loading-screen.png') -Force
    Copy-Item -LiteralPath (Join-Path $root 'sw.js') -Destination (Join-Path $root 'www\sw.js') -Force
    & (Join-Path $root 'node_modules\.bin\cap.cmd') sync android
    if ($LASTEXITCODE -ne 0) { throw 'Capacitor asset sync failed.' }
    & (Join-Path $root 'android\gradlew.bat') -p android assembleDebug
    if ($LASTEXITCODE -ne 0) { throw 'Android APK build failed.' }
    Copy-Item -LiteralPath (Join-Path $root 'android\app\build\outputs\apk\debug\app-debug.apk') -Destination (Join-Path $root 'Pocketwise.apk') -Force
    Write-Host "APK ready: $(Join-Path $root 'Pocketwise.apk')"
}
finally { Pop-Location }
