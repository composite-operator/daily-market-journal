param(
  [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SiteRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$SnapshotDir = Join-Path $SiteRoot 'snapshots'
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Html($Value) {
  return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Symbol-ForUrl([string]$Ticker) {
  return [uri]::EscapeDataString($Ticker)
}

function Get-BoardTickers([string]$HtmlText) {
  $pattern = '(?is)<a\b(?=[^>]*\bclass="[^"]*\bticker-link\b[^"]*")[^>]*>(?<ticker>[^<]+)</a>'
  $matches = [regex]::Matches($HtmlText, $pattern)
  return @(
    $matches |
      ForEach-Object { [System.Net.WebUtility]::HtmlDecode($_.Groups['ticker'].Value).Trim().ToUpperInvariant() } |
      Where-Object { $_ } |
      Sort-Object -Unique
  )
}

function New-DeltaEntry([string[]]$Tickers, [string]$Kind, [string]$CurrentDate, [string]$PreviousDate) {
  if ($Tickers.Count -eq 0) {
    return '          <p class="delta-empty">None.</p>'
  }

  $className = if ($Kind -eq 'added') { 'delta-added' } else { 'delta-removed' }
  $title = if ($Kind -eq 'added') {
    "Absent from $PreviousDate; present on $CurrentDate"
  } else {
    "Present on $PreviousDate; absent from $CurrentDate"
  }
  $encodedTitle = Html $title

  $chips = @(
    $Tickers | ForEach-Object {
      $text = Html $_
      $symbol = Symbol-ForUrl $_
      "<a class=""delta-chip $className"" href=""https://www.tradingview.com/chart/?symbol=$symbol"" title=""$encodedTitle"" target=""_blank"" rel=""noopener noreferrer"">$text</a>"
    }
  ) -join ''

  return "          <div class=""delta-list"">$chips</div>"
}

function New-DeltaBlock(
  [string]$CurrentDate,
  [string]$PreviousDate,
  [string[]]$Added,
  [string[]]$Removed,
  [string]$Newline
) {
  if ([string]::IsNullOrEmpty($PreviousDate)) {
    return (@(
      '    <!-- snapshot-delta:start -->',
      "    <section class=""snapshot-delta"" data-snapshot-date=""$CurrentDate"">",
      '      <h2>Session Board Changes</h2>',
      '      <p class="note">Baseline snapshot. No earlier dated tracking snapshot is available for an added/removed comparison.</p>',
      '    </section>',
      '    <!-- snapshot-delta:end -->'
    ) -join $Newline)
  }

  $addedHtml = New-DeltaEntry $Added 'added' $CurrentDate $PreviousDate
  $removedHtml = New-DeltaEntry $Removed 'removed' $CurrentDate $PreviousDate

  return (@(
    '    <!-- snapshot-delta:start -->',
    "    <section class=""snapshot-delta"" data-snapshot-date=""$CurrentDate"">",
    '      <h2>Session Board Changes</h2>',
    "      <p class=""note"">Compared with full board tickers from $PreviousDate.</p>",
    '      <div class="delta-grid">',
    '        <div class="delta-panel">',
    '          <h3>Added</h3>',
    $addedHtml,
    '        </div>',
    '        <div class="delta-panel">',
    '          <h3>Removed</h3>',
    $removedHtml,
    '        </div>',
    '      </div>',
    '    </section>',
    '    <!-- snapshot-delta:end -->'
  ) -join $Newline)
}

$files = Get-ChildItem -LiteralPath $SnapshotDir -Filter '*.html' |
  Where-Object { $_.BaseName -match '^\d{4}-\d{2}-\d{2}$' } |
  Sort-Object Name

$previousMap = $null
$previousDate = $null
$changedCount = 0
$summary = @()

foreach ($file in $files) {
  $html = [System.IO.File]::ReadAllText($file.FullName)
  $newline = if ($html.Contains("`r`n")) { "`r`n" } else { "`n" }
  $current = @(Get-BoardTickers $html)
  $currentMap = @{}
  foreach ($ticker in $current) {
    $currentMap[$ticker] = $true
  }

  if ($null -eq $previousMap) {
    $added = @()
    $removed = @()
  } else {
    $added = @($current | Where-Object { -not $previousMap.ContainsKey($_) } | Sort-Object)
    $removed = @($previousMap.Keys | Where-Object { -not $currentMap.ContainsKey($_) } | Sort-Object)
  }

  $block = New-DeltaBlock $file.BaseName $previousDate $added $removed $newline
  $pattern = '(?s)    <!-- snapshot-delta:start -->.*?    <!-- snapshot-delta:end -->'
  $matches = [regex]::Matches($html, $pattern)
  if ($matches.Count -ne 1) {
    throw "Expected one snapshot delta block in $($file.FullName), found $($matches.Count)."
  }

  $updated = [regex]::Replace(
    $html,
    $pattern,
    [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $block },
    1
  )
  $changed = $updated -ne $html
  if ($changed) {
    $changedCount += 1
    if (-not $Check) {
      [System.IO.File]::WriteAllText($file.FullName, $updated, $Utf8NoBom)
    }
  }

  $summary += [pscustomobject]@{
    Date = $file.BaseName
    BoardTickers = $current.Count
    Added = $added.Count
    Removed = $removed.Count
    Changed = $changed
  }

  $previousMap = $currentMap
  $previousDate = $file.BaseName
}

$summary | Format-Table Date, BoardTickers, Added, Removed, Changed -AutoSize

if ($Check -and $changedCount -gt 0) {
  throw "$changedCount snapshot delta block(s) are out of date. Run tools/Update-SnapshotDeltas.ps1 to refresh them."
}
