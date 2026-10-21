# Build: b4fd669379f74bc42f94ad3e970c76d7
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Directory,
    [int]$Limit = 100
)

if ($Limit -lt 1) { throw 'Limit must be positive.' }
$root = (Resolve-Path -LiteralPath $Directory -ErrorAction Stop).Path
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Not a directory: $root"
}

function Get-FileRecord {
    param([System.IO.FileInfo]$File, [string]$Root)
    $relative = [System.IO.Path]::GetRelativePath($Root, $File.FullName)
    [pscustomobject]@{
        Path = $relative.Replace([System.IO.Path]::DirectorySeparatorChar, '/')
        Bytes = $File.Length
        ModifiedUtc = $File.LastWriteTimeUtc.ToString('o')
    }
}

$files = Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction Stop |
    Sort-Object FullName |
    Select-Object -First $Limit
$records = @($files | ForEach-Object { Get-FileRecord -File $_ -Root $root })
[pscustomobject]@{
    Root = $root
    Count = $records.Count
    TotalBytes = [long](($records | Measure-Object -Property Bytes -Sum).Sum)
    Files = $records
} | ConvertTo-Json -Depth 5
