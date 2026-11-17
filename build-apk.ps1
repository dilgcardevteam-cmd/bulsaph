$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$javaCandidates = @($env:JAVA_HOME)
$localJdkRoot = Join-Path $root '.build-tools\jdk'
if (Test-Path -LiteralPath $localJdkRoot) {
    $javaCandidates += Get-ChildItem -LiteralPath $localJdkRoot -Directory | ForEach-Object FullName
}
$adoptiumRoot = Join-Path $env:ProgramFiles 'Eclipse Adoptium'
if (Test-Path -LiteralPath $adoptiumRoot) {
    $javaCandidates += Get-ChildItem -LiteralPath $adoptiumRoot -Directory | Sort-Object Name -Descending | ForEach-Object FullName
}
$javaCandidates += Join-Path $env:ProgramFiles 'Android\Android Studio\jbr'
$javaHome = $null
foreach ($candidate in ($javaCandidates | Select-Object -Unique)) {
    $javaExe = Join-Path $candidate 'bin\java.exe'
    if (-not (Test-Path -LiteralPath $javaExe)) { continue }
    $versionOutput = (& $javaExe -version 2>&1 | Out-String)
    if ($versionOutput -match 'version "21(?:\.|\")') {
        $javaHome = $candidate
        break
    }
}
if (-not $javaHome) {
    throw 'JDK 21 was not found. Install JDK 21 or set JAVA_HOME to its folder, then run this script again.'
}

$localSdk = Join-Path $root '.build-tools\sdk'
$sdkCandidates = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, (Join-Path $env:LOCALAPPDATA 'Android\Sdk'), $localSdk) | Where-Object { $_ }
$androidSdk = $sdkCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $androidSdk) {
    throw 'Android SDK was not found. Install Android SDK Platform 35 with Android Studio, then set ANDROID_HOME to the SDK folder.'
}

$env:JAVA_HOME = $javaHome
$env:ANDROID_HOME = $androidSdk
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:Path = "$(Join-Path $javaHome 'bin');$env:Path"

if (-not (Test-Path -LiteralPath (Join-Path $root 'node_modules\.bin\esbuild.cmd')) -or -not (Test-Path -LiteralPath (Join-Path $root 'node_modules\.bin\cap.cmd'))) {
    throw 'Node dependencies are missing. Run npm ci from the project folder, then retry.'
}

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

    $cordovaLibDirs = @(
        (Join-Path $root 'android\capacitor-cordova-android-plugins\src\main\libs'),
        (Join-Path $root 'android\capacitor-cordova-android-plugins\libs')
    )
    $hasLocalAars = $cordovaLibDirs | Where-Object {
        (Test-Path -LiteralPath $_) -and (Get-ChildItem -LiteralPath $_ -Filter '*.aar' -File -ErrorAction SilentlyContinue | Select-Object -First 1)
    } | Select-Object -First 1
    if (-not $hasLocalAars) {
        $cordovaGradle = Join-Path $root 'android\capacitor-cordova-android-plugins\build.gradle'
        if (Test-Path -LiteralPath $cordovaGradle) {
            $gradleText = [System.IO.File]::ReadAllText($cordovaGradle)
            $withoutFlatDir = [regex]::Replace($gradleText, "(?m)^[\t ]*flatDir[\t ]*\{\r?\n[\t ]*dirs 'src/main/libs', 'libs'\r?\n[\t ]*\}\r?\n?", '')
            if ($withoutFlatDir -ne $gradleText) {
                [System.IO.File]::WriteAllText($cordovaGradle, $withoutFlatDir)
            }
        }
    }

    & (Join-Path $root 'android\gradlew.bat') -p android assembleDebug
    if ($LASTEXITCODE -ne 0) { throw 'Android APK build failed.' }
    Copy-Item -LiteralPath (Join-Path $root 'android\app\build\outputs\apk\debug\app-debug.apk') -Destination (Join-Path $root 'BulsaPH.apk') -Force
    Write-Host "APK ready: $(Join-Path $root 'BulsaPH.apk')"
}
finally { Pop-Location }
