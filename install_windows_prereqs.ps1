$ErrorActionPreference = 'Stop'

$repoRoot = 'C:\Users\JEFFREY J. LEE\Desktop\bitcoin-master'
$qtSourceDir = 'C:\qt-source'
$qtInstallDir = 'C:\Qt_static'
$vcpkgDir = 'C:\vcpkg'

function Ensure-Dir([string]$Path) {
    if (!(Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

Ensure-Dir 'C:\dev'
Ensure-Dir $qtSourceDir
Ensure-Dir $qtInstallDir

if (!(Test-Path -LiteralPath (Join-Path $vcpkgDir 'vcpkg.exe'))) {
    if (!(Test-Path -LiteralPath $vcpkgDir)) { Ensure-Dir $vcpkgDir }
    & 'C:\Program Files\Git\cmd\git.exe' clone --depth 1 https://github.com/microsoft/vcpkg.git $vcpkgDir
}

& (Join-Path $vcpkgDir 'bootstrap-vcpkg.bat')
& (Join-Path $vcpkgDir 'vcpkg.exe') install --triplet x64-windows-static --x-manifest-root (Join-Path $repoRoot 'build_msvc') --x-install-root (Join-Path $repoRoot 'build_msvc\vcpkg_installed')

$qtZip = 'C:\qt-everywhere-opensource-src-5.15.5.zip'
$qtUrl = 'https://download.qt.io/official_releases/qt/5.15/5.15.5/single/qt-everywhere-opensource-src-5.15.5.zip'
$sourceRoot = 'C:\qt-everywhere-opensource-src-5.15.5'

if (!(Test-Path -LiteralPath (Join-Path $qtSourceDir 'configure')) -and !(Test-Path -LiteralPath (Join-Path $qtSourceDir 'build\config.summary'))) {
    if (!(Test-Path -LiteralPath $qtZip)) {
        & 'C:\Windows\System32\curl.exe' -L --fail --retry 3 --output $qtZip $qtUrl
    }

    if (!(Test-Path -LiteralPath $qtZip)) {
        throw "Qt source archive not found: $qtZip"
    }

    if (Test-Path -LiteralPath $sourceRoot) {
        Remove-Item -LiteralPath $sourceRoot -Recurse -Force
    }

    Expand-Archive -Path $qtZip -DestinationPath 'C:\' -Force

    if (Test-Path -LiteralPath $sourceRoot) {
        if (Test-Path -LiteralPath $qtSourceDir) {
            Remove-Item -LiteralPath $qtSourceDir -Recurse -Force
        }
        Rename-Item -Path $sourceRoot -NewName 'qt-source'
    }
}

if (!(Test-Path -LiteralPath (Join-Path $qtSourceDir 'build'))) {
    New-Item -ItemType Directory -Path (Join-Path $qtSourceDir 'build') -Force | Out-Null
}

$vsDevShell = 'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\Launch-VsDevShell.ps1'
if (!(Test-Path -LiteralPath $vsDevShell)) {
    throw "Visual Studio developer shell not found: $vsDevShell"
}

. $vsDevShell -Arch amd64 -HostArch amd64

Set-Location (Join-Path $qtSourceDir 'build')
if (!(Test-Path -LiteralPath (Join-Path $qtSourceDir 'build\config.summary'))) {
    & (Join-Path $qtSourceDir 'configure') -release -silent -opensource -confirm-license -opengl desktop -static -static-runtime -mp -qt-zlib -qt-pcre -qt-libpng -nomake examples -nomake tests -nomake tools -no-angle -no-dbus -no-gif -no-gtk -no-ico -no-icu -no-libjpeg -no-libudev -no-sql-sqlite -no-sql-odbc -no-sqlite -no-vulkan -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcharts -skip qtconnectivity -skip qtdatavis3d -skip qtdeclarative -skip doc -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtimageformats -skip qtlocation -skip qtlottie -skip qtmacextras -skip qtmultimedia -skip qtnetworkauth -skip qtpurchasing -skip qtquick3d -skip qtquickcontrols -skip qtquickcontrols2 -skip qtquicktimeline -skip qtremoteobjects -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtserialport -skip qtspeech -skip qtsvg -skip qtvirtualkeyboard -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebglplugin -skip qtwebsockets -skip qtwebview -skip qtx11extras -skip qtxmlpatterns -no-openssl -no-feature-bearermanagement -no-feature-printdialog -no-feature-printer -no-feature-printpreviewdialog -no-feature-printpreviewwidget -no-feature-sql -no-feature-sqlmodel -no-feature-textbrowser -no-feature-textmarkdownwriter -no-feature-textodfwriter -no-feature-xml -prefix $qtInstallDir
}

nmake
nmake install

Write-Host 'Qt static install completed.'
Write-Host 'Qt root: ' $qtInstallDir
