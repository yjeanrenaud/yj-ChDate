function Set-ChDate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$DateString
    )

    function Parse-ChDate([string]$s) {
        $s2 = $s.Trim().ToLowerInvariant()
        switch -Regex ($s2) {
            '^now$' { return Get-Date }
            '^yesterday(?:\s+(?<time>.+))?$' {
                $base = (Get-Date).Date.AddDays(-1)
                if ($matches['time']) { $t = Get-Date $matches['time']; return $base.Date + $t.TimeOfDay }
                return $base
            }
            '^tomorrow(?:\s+(?<time>.+))?$' {
                $base = (Get-Date).Date.AddDays(1)
                if ($matches['time']) { $t = Get-Date $matches['time']; return $base.Date + $t.TimeOfDay }
                return $base
            }
            '^(?<sign>[+-])(?:(?<d>\d+)d)?(?:(?<h>\d+)h)?(?:(?<m>\d+)m)?(?:(?<sec>\d+)s)?$' {
                $mult = if ($matches['sign'] -eq '-') { -1 } else { 1 }
                $days=[int](0+($matches['d'])); $hours=[int](0+($matches['h'])); $mins=[int](0+($matches['m'])); $secs=[int](0+($matches['sec']))
                $span = New-TimeSpan -Days $days -Hours $hours -Minutes $mins -Seconds $secs
                return (Get-Date).Add($span * $mult)
            }
            default { return Get-Date $s }
        }
    }

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    $date = Parse-ChDate $DateString
    $item.CreationTime   = $date
    $item.LastWriteTime  = $date
    $item.LastAccessTime = $date
}

Set-Alias -Name chdate -Value Set-ChDate
Set-Alias -Name yj-chdate -Value Set-ChDate
Export-ModuleMember -Function Set-ChDate -Alias yj-chdate, chdate
