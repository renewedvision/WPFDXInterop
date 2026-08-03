param(
    [Parameter(Mandatory = $true)]
    [string] $PackagePath
)

$frameworks = @("net472", "net8.0", "net9.0", "net10.0")
$runtimeIdentifiers = @("win-x86", "win-x64")
$expectedEntries = [System.Collections.Generic.List[string]]::new()

foreach ($framework in $frameworks) {
    $expectedEntries.Add("lib/$framework/RenewedVision.Wpf.Interop.DirectX.dll")

    foreach ($runtimeIdentifier in $runtimeIdentifiers) {
        $runtimeDirectory = "runtimes/$runtimeIdentifier/lib/$framework"
        $expectedEntries.Add("$runtimeDirectory/RenewedVision.Wpf.Interop.DirectX.dll")
        $expectedEntries.Add("$runtimeDirectory/RenewedVision.Wpf.Interop.DirectX.pdb")
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$resolvedPackagePath = (Resolve-Path -LiteralPath $PackagePath).Path
$archive = [System.IO.Compression.ZipFile]::OpenRead($resolvedPackagePath)

try {
    $actualEntries = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)

    foreach ($entry in $archive.Entries) {
        [void] $actualEntries.Add($entry.FullName)
    }

    $missingEntries = @($expectedEntries | Where-Object { -not $actualEntries.Contains($_) })
    if ($missingEntries.Count -gt 0) {
        throw "NuGet package is missing required assets:`n$($missingEntries -join "`n")"
    }
}
finally {
    $archive.Dispose()
}

Write-Host "Validated $($expectedEntries.Count) framework and runtime assets in $resolvedPackagePath"
