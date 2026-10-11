# Emerald - LibVLC Import Library Generator for Windows MSVC
param (
    [string]$VlcPath = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$extDir = Join-Path $projectRoot "ext\libvlc"

if (-not (Test-Path $extDir)) {
    New-Item -ItemType Directory -Path $extDir -Force | Out-Null
}

if (-not $VlcPath) {
    $candidates = @(
        "C:\Program Files\VideoLAN\VLC",
        "C:\Program Files (x86)\VideoLAN\VLC"
    )
    if ($env:VLC_PATH) {
        $candidates += $env:VLC_PATH
    }

    foreach ($cand in $candidates) {
        if (Test-Path (Join-Path $cand "libvlc.dll")) {
            $VlcPath = $cand
            break
        }
    }

    if (-not $VlcPath) {
        Write-Error "Could not find VLC installation containing libvlc.dll. Please provide -VlcPath or install VLC."
        exit 1
    }
}

$vlcDll = Join-Path $VlcPath "libvlc.dll"
Write-Host "Found LibVLC at: $vlcDll"

# Extract exported symbols using llvm-objdump
$exports = llvm-objdump -p $vlcDll | Select-String "^\s+\d+\s+0x[0-9a-fA-F]+\s+(\S+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }

if ($exports.Count -eq 0) {
    Write-Error "Failed to extract exported symbols from $vlcDll"
    exit 1
}

Write-Host "Extracted $($exports.Count) exports from libvlc.dll"

$defPath = Join-Path $extDir "libvlc.def"
$libPath = Join-Path $extDir "libvlc.lib"

$defContent = "LIBRARY libvlc.dll`nEXPORTS`n" + ($exports -join "`n")
Set-Content -Path $defPath -Value $defContent -Encoding Ascii

# Compile import library using llvm-dlltool
llvm-dlltool -d $defPath -l $libPath -m i386:x86-64

if (Test-Path $libPath) {
    Write-Host "Successfully generated import library: $libPath ($((Get-Item $libPath).Length) bytes)"
} else {
    Write-Error "Failed to generate $libPath"
    exit 1
}
