Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SiteRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$script:NavDailyHref = 'https://ximxesabortion.github.io/daily-market-journal/posts/'
$script:NavMacroHref = 'https://ximxesabortion.github.io/daily-market-journal/macro/'
$script:NavSnapshotHref = 'https://ximxesabortion.github.io/daily-market-journal/snapshots/'

function Html($Value) {
  return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Decode-HtmlText($Value) {
  $stripped = [regex]::Replace([string]$Value, '<[^>]+>', '')
  return [System.Net.WebUtility]::HtmlDecode($stripped).Trim()
}

function Date-FromName($Name) {
  $match = [regex]::Match($Name, '^(\d{4}-\d{2}-\d{2})')
  if (-not $match.Success) { return $null }
  return $match.Groups[1].Value
}

function Parse-Date($Date) {
  return [datetime]::ParseExact($Date, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
}

function Month-Key($Date) {
  return (Parse-Date $Date).ToString('yyyy-MM', [Globalization.CultureInfo]::InvariantCulture)
}

function Month-Name($Date) {
  return (Parse-Date $Date).ToString('MMMM yyyy', [Globalization.CultureInfo]::InvariantCulture)
}

function Short-Date($Date) {
  return (Parse-Date $Date).ToString('MMM d', [Globalization.CultureInfo]::InvariantCulture)
}

function Weekday($Date) {
  return (Parse-Date $Date).ToString('dddd', [Globalization.CultureInfo]::InvariantCulture)
}

function Write-Text($RelativePath, $Content) {
  $path = Join-Path $SiteRoot $RelativePath
  $dir = Split-Path -Parent $path
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  $normalized = (($Content.TrimEnd() -split "\r?\n") | ForEach-Object { $_.TrimEnd() }) -join "`r`n"
  [System.IO.File]::WriteAllText($path, $normalized + "`r`n", $Utf8NoBom)
}

function Get-PageTitle($Path, $Fallback) {
  if (-not (Test-Path -LiteralPath $Path)) { return $Fallback }
  $html = [System.IO.File]::ReadAllText($Path)
  $h1 = [regex]::Match($html, '(?is)<h1[^>]*>(.*?)</h1>')
  if ($h1.Success) {
    $title = Decode-HtmlText $h1.Groups[1].Value
    if ($title) { return $title }
  }
  $titleMatch = [regex]::Match($html, '(?is)<title[^>]*>(.*?)</title>')
  if ($titleMatch.Success) {
    $title = Decode-HtmlText $titleMatch.Groups[1].Value
    if ($title) {
      return ($title -replace '\s+-\s+Composite Operator: Macro Lensing$', '')
    }
  }
  return $Fallback
}

function Read-TitleManifest($RelativePath) {
  $titleByHref = @{}
  $titleByDate = @{}
  $path = Join-Path $SiteRoot $RelativePath
  if (Test-Path -LiteralPath $path) {
    $items = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    foreach ($item in @($items)) {
      if ($item.href -and $item.title) {
        $href = [string]$item.href
        $titleByHref[$href] = [string]$item.title
        $titleByHref[$href.Replace('\', '/')] = [string]$item.title
      }
      if ($item.date -and $item.title -and -not $titleByDate.ContainsKey([string]$item.date)) {
        $titleByDate[[string]$item.date] = [string]$item.title
      }
    }
  }
  return [pscustomobject]@{ ByHref = $titleByHref; ByDate = $titleByDate }
}

function Get-DatedFiles($Folder, $Kind, $DefaultTitle, $ManifestPath = $null, $ManifestPrefix = $null) {
  $path = Join-Path $SiteRoot $Folder
  if (-not (Test-Path -LiteralPath $path)) { return @() }
  $manifest = if ($ManifestPath) { Read-TitleManifest $ManifestPath } else { [pscustomobject]@{ ByHref = @{}; ByDate = @{} } }
  return @(Get-ChildItem -LiteralPath $path -Filter '*.html' |
    Where-Object { $_.Name -ne 'index.html' } |
    ForEach-Object {
      $date = Date-FromName $_.Name
      if ($date) {
        $href = "$Folder/$($_.Name)"
        $manifestHref = if ($ManifestPrefix) { "$ManifestPrefix/$($_.Name)" } else { $href }
        $title = $DefaultTitle
        if ($manifest.ByHref.ContainsKey($manifestHref)) {
          $title = $manifest.ByHref[$manifestHref]
        } elseif ($manifest.ByHref.ContainsKey($href)) {
          $title = $manifest.ByHref[$href]
        } elseif ($manifest.ByDate.ContainsKey($date)) {
          $title = $manifest.ByDate[$date]
        } else {
          $title = Get-PageTitle $_.FullName $DefaultTitle
        }
        [pscustomobject]@{
          Date = $date
          File = $_.Name
          Folder = $Folder
          Href = $href
          Kind = $Kind
          Title = $title
        }
      }
    } |
    Sort-Object Date)
}

function Site-Nav($Prefix, $Current) {
  $items = @(
    @{ Key = 'operator'; Label = 'Homepage'; Href = 'https://ximxesabortion.github.io/' },
    @{ Key = 'posts'; Label = 'Daily Journal'; Href = $script:NavDailyHref },
    @{ Key = 'macro'; Label = 'Macro Lens'; Href = $script:NavMacroHref },
    @{ Key = 'snapshots'; Label = 'Snapshots'; Href = $script:NavSnapshotHref },
    @{ Key = 'archive'; Label = 'Archive'; Href = 'https://ximxesabortion.github.io/daily-market-journal/archive/' },
    @{ Key = 'library'; Label = 'Pamphlets'; Href = 'https://ximxesabortion.github.io/daily-market-journal/library/' }
  )
  $links = $items | ForEach-Object {
    $currentAttr = if ($_.Key -eq $Current) { ' aria-current="page"' } else { '' }
    "<a href=""$($_.Href)""$currentAttr>$($_.Label)</a>"
  }
  return @"
  <nav class="site-nav" aria-label="Site sections">
    <strong>Market Desk</strong>
    <div>
      $($links -join "`r`n      ")
    </div>
  </nav>
"@
}

function Page-Head($Title, $Prefix) {
  return @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$(Html $Title)</title>
  <link rel="stylesheet" href="${Prefix}assets/style.css?v=21">
  <script src="${Prefix}assets/table-sort.js?v=1" defer></script>
</head>
"@
}

function Link-OrMissing($Entry, $Prefix, $Label, $Class) {
  if ($Entry) {
    return "<a class=""archive-link $Class"" href=""$Prefix$($Entry.Href)"">$Label</a>"
  }
  return "<span class=""archive-link missing"">$Label</span>"
}

function Build-MonthGroups($Dates, $Prefix, $Collections, $OpenCount = 0) {
  $months = $Dates | Group-Object { Month-Key $_ } | Sort-Object Name -Descending
  $monthIndex = 0
  $html = foreach ($month in $months) {
    $monthIndex++
    $monthDates = @($month.Group | Sort-Object -Descending)
    $materialCount = 0
    foreach ($date in $monthDates) {
      foreach ($lane in @('Posts', 'Macro', 'Snapshots', 'Private')) {
        if ($Collections.$lane[$date]) { $materialCount++ }
      }
    }
    $rows = foreach ($date in $monthDates) {
      $post = $Collections.Posts[$date]
      $macro = $Collections.Macro[$date]
      $snapshot = $Collections.Snapshots[$date]
      $private = $Collections.Private[$date]
      $title = if ($post) { $post.Title } elseif ($macro) { $macro.Title } else { 'Archive Packet' }
      @"
        <div class="month-entry">
          <div class="entry-main">
            <span class="entry-date">$(Short-Date $date)</span>
            <span>$(Weekday $date)</span>
            <em>$(Html $title)</em>
          </div>
          <div class="entry-actions">
            $(Link-OrMissing $post $Prefix 'Daily Journal' 'public')
            $(Link-OrMissing $macro $Prefix 'Macro Lens' 'macro')
            $(Link-OrMissing $snapshot $Prefix 'Snapshot' 'snapshot')
            $(if ($private) { Link-OrMissing $private $Prefix 'Legacy Private' 'private' })
          </div>
        </div>
"@
    }
    $openAttr = if ($OpenCount -gt 0 -and $monthIndex -le $OpenCount) { ' open' } else { '' }
    @"
      <details class="month-box"$openAttr>
        <summary>
          <span>$(Month-Name $monthDates[0])</span>
          <small>$($monthDates.Count) dates / $materialCount materials</small>
        </summary>
        <div class="month-body">
          $($rows -join "`r`n")
        </div>
      </details>
"@
  }
  return ($html -join "`r`n")
}

function Build-CollectionMonthBoxes($Entries, $LinkPrefix, $OpenCount = 0) {
  $months = $Entries | Group-Object { Month-Key $_.Date } | Sort-Object Name -Descending
  $monthIndex = 0
  $html = foreach ($month in $months) {
    $monthIndex++
    $monthEntries = @($month.Group | Sort-Object Date -Descending)
    $rows = foreach ($entry in $monthEntries) {
      @"
        <div class="month-entry collection-entry">
          <div class="entry-main">
            <span class="entry-date">$(Short-Date $entry.Date)</span>
            <span>$(Weekday $entry.Date)</span>
            <em>$(Html $entry.Title)</em>
          </div>
          <div class="entry-actions">
            <a class="archive-link" href="$LinkPrefix$($entry.File)">Open</a>
          </div>
        </div>
"@
    }
    $openAttr = if ($OpenCount -gt 0 -and $monthIndex -le $OpenCount) { ' open' } else { '' }
    @"
      <details class="month-box"$openAttr>
        <summary>
          <span>$(Month-Name $monthEntries[0].Date)</span>
          <small>$($monthEntries.Count) entries</small>
        </summary>
        <div class="month-body">
          $($rows -join "`r`n")
        </div>
      </details>
"@
  }
  return ($html -join "`r`n")
}

function Build-CollectionPage($RelativePath, $Title, $Dek, $Current, $Entries, $LinkPrefix, $Eyebrow = 'Archive Collection') {
  $prefix = '../'
  $latest = @($Entries | Sort-Object Date)[-1]
  $body = @"
$(Page-Head $Title $prefix)
<body>
$(Site-Nav $prefix $Current)
  <div class="topline">
    <header>
      <p class="eyebrow">$(Html $Eyebrow)</p>
      <h1>$(Html $Title)</h1>
      <p class="dek">$(Html $Dek)</p>
    </header>
  </div>
  <main>
    <section>
      <h2>Current Scope</h2>
      <div class="metric-strip">
        <div class="metric"><span class="metric-value">$($Entries.Count)</span><span class="metric-label">Entries</span></div>
        <div class="metric metric-open"><span class="metric-value">$($latest.Date)</span><span class="metric-label">Latest</span></div>
        <div class="metric metric-review"><span class="metric-value">$(Month-Name $latest.Date)</span><span class="metric-label">Newest Month</span></div>
      </div>
    </section>
    <div class="archive-shell">
      $(Build-CollectionMonthBoxes $Entries $LinkPrefix 3)
    </div>
  </main>
  <footer>Static archive. Not financial advice.</footer>
</body>
</html>
"@
  Write-Text $RelativePath $body
}

function Build-VaultRedirectPage($RelativePath) {
  $prefix = '../'
  $body = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="refresh" content="0; url=../archive/">
  <link rel="canonical" href="../archive/">
  <title>Complete Month History</title>
  <link rel="stylesheet" href="../assets/style.css?v=15">
</head>
<body>
$(Site-Nav $prefix 'archive')
  <div class="topline">
    <header>
      <p class="eyebrow">Legacy Address</p>
      <h1>Complete Month History</h1>
      <p class="dek">This old address now points to the complete month history.</p>
    </header>
  </div>
  <main>
    <section>
      <h2>Moved</h2>
      <p class="resource-note">The daily-entry mirror was redundant with Daily Journal, so the archive now uses History as the single month-box view.</p>
      <div class="link-strip">
        <a class="box-link" href="../archive/">Standalone History Page</a>
      </div>
    </section>
  </main>
  <footer>Static archive. Not financial advice.</footer>
</body>
</html>
"@
  Write-Text $RelativePath $body
}

function Build-LibraryPage($RelativePath) {
  $prefix = '../'
  $body = @"
$(Page-Head 'Pamphlet Library' $prefix)
<body>
$(Site-Nav $prefix 'library')
  <div class="topline">
    <header>
      <p class="eyebrow">Published Materials</p>
      <h1>Pamphlet Library</h1>
      <p class="dek">The published educational shelf: the macro process manual and the private-credit risk pamphlet.</p>
    </header>
  </div>
  <main>
    <div class="library-grid">
      <article class="library-card">
        <img class="library-cover" src="assets/figures/macro_regime_operating_manual_title_page.png" alt="The Macro Regime Operating Manual title artwork">
        <p class="clicker-label">Macro Process</p>
        <h2>The Macro Regime Operating Manual</h2>
        <p>An AI-native macro process for regime, liquidity, risk, and capital allocation. Built for reading rates, inflation, credit, volatility, dollar pressure, and cross-asset behavior as one operating map.</p>
        <div class="link-strip">
          <a class="box-link" href="capitalflows_textbook.html">Read HTML</a>
          <a class="box-link" href="macro-regime-operating-manual.pdf">Open PDF</a>
        </div>
      </article>
      <article class="library-card private-credit">
        <div class="library-cover private-credit-title-thumb" role="img" aria-label="The Floating-Rate Fault Line title page">
          <img src="assets/figures/private_credit_risk_curve/floating_rate_fault_line_art_v2.png" alt="">
          <div class="private-credit-title-copy" aria-hidden="true">
            <p class="mini-cover-imprint">Composite Operator Research Desk</p>
            <p class="mini-cover-the">The</p>
            <p class="mini-cover-title">Floating-Rate<br>Fault Line</p>
            <p class="mini-cover-subtitle">SOFR, Private Credit, BDCs, and the Risk Curve</p>
          </div>
        </div>
        <p class="clicker-label">Credit Risk</p>
        <h2>The Floating-Rate Fault Line</h2>
        <p>Private credit risk educational material focused on SOFR, floating-rate debt, BDCs, credit spreads, and the risk curve from funding pressure to public-market repricing. Current version includes the July 2026 progress check; the original v1 is preserved.</p>
        <div class="link-strip">
          <a class="box-link" href="private_credit_risk_curve_pamphlet.html">Read HTML</a>
          <a class="box-link" href="private_credit_risk_curve_pamphlet.pdf">Open PDF</a>
          <a class="box-link" href="private_credit_risk_curve_pamphlet_v1.html">Original v1</a>
          <a class="box-link" href="private_credit_risk_curve_pamphlet_v1.pdf">v1 PDF</a>
        </div>
      </article>
    </div>
  </main>
  <footer>Educational material. Not financial advice.</footer>
</body>
</html>
"@
  Write-Text $RelativePath $body
}

function Replace-Nav($Path, $Nav) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $html = [System.IO.File]::ReadAllText($Path)
  $updated = [regex]::Replace($html, '<nav class="top-nav">.*?</nav>', $Nav, 1)
  [System.IO.File]::WriteAllText($Path, $updated.TrimEnd() + "`r`n", $Utf8NoBom)
}

function Update-SnapshotCallout($Path, $SnapshotEntry) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $html = [System.IO.File]::ReadAllText($Path)
  $block = ''
  if ($SnapshotEntry) {
    $block = @"
    <!-- snapshot-link:start -->
    <section class="snapshot-callout">
      <h2>Tracking Snapshot</h2>
      <p>A cleaned static snapshot of watched and committed ideas is available for this date.</p>
      <p><a href="../snapshots/$($SnapshotEntry.File)">Open tracking snapshot</a></p>
    </section>
    <!-- snapshot-link:end -->
"@
  }
  $pattern = '(?s)\s*<!-- snapshot-link:start -->.*?<!-- snapshot-link:end -->'
  if ([regex]::IsMatch($html, $pattern)) {
    $replacement = if ($block) { "`r`n$block" } else { '' }
    $html = [regex]::Replace($html, $pattern, $replacement, 1)
  } elseif ($block -and $html.Contains('</main>')) {
    $html = $html.Replace('</main>', "$block`r`n  </main>")
  }
  [System.IO.File]::WriteAllText($Path, $html.TrimEnd() + "`r`n", $Utf8NoBom)
}

function Repair-LegacyLinks($Path, $Folder) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $html = [System.IO.File]::ReadAllText($Path)
  $html = $html -replace 'href="\.\./\.\./"', 'href="../index.html"'
  $html = $html -replace '<a href="https://ximxesabortion\.github\.io/">Main Home</a>', '<a href="../archive/">History</a>'
  $html = $html -replace '>Site Home</a>', '>Homepage</a>'
  if ($Folder -eq 'vault') {
    $html = $html -replace '>Journal Index</a>', '>Vault Index</a>'
  }
  if ($Folder -eq 'private') {
    $html = $html -replace 'href="\.\./">Private Index</a>', 'href="index.html">Private Index</a>'
  }
  [System.IO.File]::WriteAllText($Path, $html.TrimEnd() + "`r`n", $Utf8NoBom)
}

function Repair-LibraryLinks() {
  foreach ($relative in @('library/capitalflows_textbook.html', 'library/private_credit_risk_curve_pamphlet.html', 'library/private_credit_risk_curve_pamphlet_v1.html', 'library/educational_materials.html')) {
    $path = Join-Path $SiteRoot $relative
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $html = [System.IO.File]::ReadAllText($path)
    $html = $html -replace 'href="educational_materials.html"', 'href="index.html"'
    [System.IO.File]::WriteAllText($path, $html.TrimEnd() + "`r`n", $Utf8NoBom)
  }
}

$posts = Get-DatedFiles 'posts' 'post' 'Daily Market Journal' 'posts.json' 'posts'
$macro = Get-DatedFiles 'macro/posts' 'macro' 'Macro Lens' 'macro/posts.json' 'posts'
$vault = Get-DatedFiles 'vault' 'vault' 'Encrypted Vault Entry'
$snapshots = Get-DatedFiles 'snapshots' 'snapshot' 'Tracking Snapshot'
$private = Get-DatedFiles 'private' 'private' 'Legacy Private Entry'

$collections = [pscustomobject]@{
  Posts = @{}
  Macro = @{}
  Vault = @{}
  Snapshots = @{}
  Private = @{}
}
foreach ($entry in $posts) { $collections.Posts[$entry.Date] = $entry }
foreach ($entry in $macro) { $collections.Macro[$entry.Date] = $entry }
foreach ($entry in $vault) { $collections.Vault[$entry.Date] = $entry }
foreach ($entry in $snapshots) { $collections.Snapshots[$entry.Date] = $entry }
foreach ($entry in $private) { $collections.Private[$entry.Date] = $entry }

$allDates = @($posts.Date + $macro.Date + $snapshots.Date + $private.Date | Sort-Object -Unique)
$latestDate = @($allDates | Sort-Object)[-1]
$oldestDate = @($allDates | Sort-Object)[0]
$latestPost = $collections.Posts[$latestDate]
$latestMacro = $collections.Macro[$latestDate]
$latestSnapshot = $collections.Snapshots[$latestDate]
if ($latestPost) { $script:NavDailyHref = "https://ximxesabortion.github.io/daily-market-journal/$($latestPost.Href)" }
if ($latestMacro) { $script:NavMacroHref = "https://ximxesabortion.github.io/daily-market-journal/$($latestMacro.Href)" }
if ($latestSnapshot) { $script:NavSnapshotHref = "https://ximxesabortion.github.io/daily-market-journal/$($latestSnapshot.Href)" }

$latestLinks = @()
if ($latestPost) { $latestLinks += "<a class=""box-link"" href=""$($latestPost.Href)"">Daily Journal</a>" }
if ($latestMacro) { $latestLinks += "<a class=""box-link"" href=""$($latestMacro.Href)"">Macro Lens</a>" }
if ($latestSnapshot) { $latestLinks += "<a class=""box-link"" href=""$($latestSnapshot.Href)"">Snapshot</a>" }

$rootPage = @"
$(Page-Head 'Daily Market Journal | Market Desk' '')
<body>
$(Site-Nav '' '')
  <main>
    <div class="hub-hero">
      <div class="hero-panel">
        <p class="eyebrow">Composite Operator / Market Desk</p>
        <h1 class="hub-title">Daily Market Journal</h1>
        <p class="hub-dek">The market-desk archive inside Composite Operator: private daily journals, public Macro Lens synthesis, board snapshots, and published research.</p>
      </div>
      <aside class="latest-panel" aria-label="Latest archive packet">
        <p class="eyebrow">Latest Market Packet</p>
        <span class="date">$latestDate</span>
        <div class="link-strip">
          $($latestLinks -join "`r`n          ")
        </div>
      </aside>
    </div>

    <div class="quick-grid" aria-label="Archive sections">
      <a class="clicker-card public" href="posts/">
        <span class="clicker-label">Private Desk Notes</span>
        <span class="clicker-value">Daily Journal</span>
        <span class="clicker-meta">$($posts.Count) dated journal entries</span>
      </a>
      <a class="clicker-card macro" href="macro/">
        <span class="clicker-label">Public-Safe Synthesis</span>
        <span class="clicker-value">Macro Lens</span>
        <span class="clicker-meta">$($macro.Count) macro entries back to $(Short-Date $oldestDate)</span>
      </a>
      <a class="clicker-card library" href="library/">
        <span class="clicker-label">Published Material</span>
        <span class="clicker-value">Pamphlet Library</span>
        <span class="clicker-meta">2 published educational pieces</span>
      </a>
      <a class="clicker-card snapshot" href="snapshots/">
        <span class="clicker-label">Board State</span>
        <span class="clicker-value">Snapshots</span>
        <span class="clicker-meta">$($snapshots.Count) tracking pages</span>
      </a>
      <a class="clicker-card archive" href="archive/">
        <span class="clicker-label">Nested History</span>
        <span class="clicker-value">Month Boxes</span>
        <span class="clicker-meta">$(Short-Date $oldestDate) through $(Short-Date $latestDate)</span>
      </a>
      <a class="clicker-card macro" href="https://substack.com/@compositeoperator" target="_blank" rel="noopener">
        <span class="clicker-label">Research Dispatch</span>
        <span class="clicker-value">Composite Operator on Substack</span>
        <span class="clicker-meta">Essays and publication updates</span>
      </a>
    </div>

    <section>
      <h2>Market Desk History By Month</h2>
      <p class="resource-note">Open a month to reveal the entries inside it. Each date shows whichever lanes exist for that session.</p>
    </section>
    <div class="archive-shell">
      $(Build-MonthGroups $allDates '' $collections 0)
    </div>
  </main>
  <footer>Static archive. Not financial advice.</footer>
</body>
</html>
"@
Write-Text 'index.html' $rootPage

$archive = @"
$(Page-Head 'Complete Month History' '../')
<body>
$(Site-Nav '../' 'archive')
  <div class="topline">
    <header>
      <p class="eyebrow">Nested History</p>
      <h1>Complete Month History</h1>
      <p class="dek">Month boxes for every dated item currently in the site: Daily Journal, Macro Lens, snapshots, and legacy private entries.</p>
    </header>
  </div>
  <main>
    <section>
      <h2>Coverage</h2>
      <div class="metric-strip">
        <div class="metric"><span class="metric-value">$($allDates.Count)</span><span class="metric-label">Dated Sessions</span></div>
        <div class="metric metric-open"><span class="metric-value">$($posts.Count)</span><span class="metric-label">Daily Journal</span></div>
        <div class="metric metric-review"><span class="metric-value">$($macro.Count)</span><span class="metric-label">Macro Lens</span></div>
        <div class="metric metric-buybox"><span class="metric-value">$($snapshots.Count)</span><span class="metric-label">Snapshots</span></div>
      </div>
    </section>
    <div class="archive-shell">
      $(Build-MonthGroups $allDates '../' $collections 0)
    </div>
  </main>
  <footer>Static archive. Not financial advice.</footer>
</body>
</html>
"@
Write-Text 'archive/index.html' $archive

Build-CollectionPage 'posts/index.html' 'Daily Journal' 'Private desk journal entries, grouped by month.' 'posts' $posts '' 'Daily Lane'
Build-CollectionPage 'macro/index.html' 'Macro Lens' 'Public-safe macro-flow synthesis entries, grouped by month from the full historical backlog.' 'macro' $macro 'posts/' 'Macro Lane'
Build-CollectionPage 'snapshots/index.html' 'Tracking Snapshots' 'Cleaned static board snapshots generated from the tracking sheet, grouped by month.' 'snapshots' $snapshots '' 'Snapshot Lane'
Build-VaultRedirectPage 'vault/index.html'
if ($private.Count -gt 0) {
  Build-CollectionPage 'private/index.html' 'Legacy Private Archive' 'Older encrypted private entries retained for continuity.' 'archive' $private '' 'Legacy Lane'
}
Build-LibraryPage 'library/index.html'
Build-LibraryPage 'library/educational_materials.html'

$jsonItems = $posts | ForEach-Object {
  [pscustomobject]@{
    date = $_.Date
    href = $_.Href
    title = $_.Title
  }
}
Write-Text 'posts.json' ($jsonItems | ConvertTo-Json -Depth 4)

$macroJsonItems = $macro | ForEach-Object {
  [pscustomobject]@{
    date = $_.Date
    href = "posts/$($_.File)"
    title = $_.Title
  }
}
Write-Text 'macro/posts.json' ($macroJsonItems | ConvertTo-Json -Depth 4)

$sortedPosts = @($posts | Sort-Object Date)
for ($i = 0; $i -lt $sortedPosts.Count; $i++) {
  $entry = $sortedPosts[$i]
  $links = @(
    '<a href="../index.html">Homepage</a>',
    '<a href="../posts/">Daily Journal</a>'
  )
  if ($i -gt 0) { $links += "<a href=""../posts/$($sortedPosts[$i - 1].File)"">Previous: $($sortedPosts[$i - 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Previous</span>' }
  if ($i -lt $sortedPosts.Count - 1) { $links += "<a href=""../posts/$($sortedPosts[$i + 1].File)"">Next: $($sortedPosts[$i + 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Next</span>' }
  if ($collections.Macro[$entry.Date]) { $links += "<a href=""../macro/posts/$($collections.Macro[$entry.Date].File)"">Macro Lens</a>" }
  if ($collections.Snapshots[$entry.Date]) { $links += "<a href=""../snapshots/$($collections.Snapshots[$entry.Date].File)"">Snapshot</a>" }
  Replace-Nav (Join-Path $SiteRoot $entry.Href) ('<nav class="top-nav">' + ($links -join '') + '</nav>')
  Update-SnapshotCallout (Join-Path $SiteRoot $entry.Href) $collections.Snapshots[$entry.Date]
}

$sortedMacro = @($macro | Sort-Object Date)
for ($i = 0; $i -lt $sortedMacro.Count; $i++) {
  $entry = $sortedMacro[$i]
  $links = @(
    '<a href="../../index.html">Homepage</a>',
    '<a href="../">Macro Lens</a>',
    '<a href="../research-rules.html">Research Rules</a>'
  )
  if ($i -gt 0) { $links += "<a href=""../posts/$($sortedMacro[$i - 1].File)"">Previous: $($sortedMacro[$i - 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Previous</span>' }
  if ($i -lt $sortedMacro.Count - 1) { $links += "<a href=""../posts/$($sortedMacro[$i + 1].File)"">Next: $($sortedMacro[$i + 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Next</span>' }
  if ($collections.Posts[$entry.Date]) { $links += "<a href=""../../posts/$($collections.Posts[$entry.Date].File)"">Daily Journal</a>" }
  if ($collections.Snapshots[$entry.Date]) { $links += "<a href=""../../snapshots/$($collections.Snapshots[$entry.Date].File)"">Snapshot</a>" }
  Replace-Nav (Join-Path $SiteRoot $entry.Href) ('<nav class="top-nav">' + ($links -join '') + '</nav>')
}

$macroRulesPath = Join-Path $SiteRoot 'macro/research-rules.html'
if (Test-Path -LiteralPath $macroRulesPath) {
  $rulesNav = '<nav class="top-nav"><span class="brand-mark">Composite Operator</span><a href="../index.html">Homepage</a><a href="index.html">Macro Lens</a><a href="research-rules.html">Research Rules</a><a href="../library/">Pamphlets</a></nav>'
  Replace-Nav $macroRulesPath $rulesNav
}

$sortedVault = @($vault | Sort-Object Date)
for ($i = 0; $i -lt $sortedVault.Count; $i++) {
  $entry = $sortedVault[$i]
  $links = @(
    '<a href="../index.html">Homepage</a>',
    '<a href="../vault/">Vault</a>'
  )
  if ($i -gt 0) { $links += "<a href=""../vault/$($sortedVault[$i - 1].File)"">Previous: $($sortedVault[$i - 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Previous</span>' }
  if ($i -lt $sortedVault.Count - 1) { $links += "<a href=""../vault/$($sortedVault[$i + 1].File)"">Next: $($sortedVault[$i + 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Next</span>' }
  if ($collections.Posts[$entry.Date]) { $links += "<a href=""../posts/$($collections.Posts[$entry.Date].File)"">Daily Journal</a>" }
  if ($collections.Macro[$entry.Date]) { $links += "<a href=""../macro/posts/$($collections.Macro[$entry.Date].File)"">Macro Lens</a>" }
  if ($collections.Snapshots[$entry.Date]) { $links += "<a href=""../snapshots/$($collections.Snapshots[$entry.Date].File)"">Snapshot</a>" }
  Replace-Nav (Join-Path $SiteRoot $entry.Href) ('<nav class="top-nav">' + ($links -join '') + '</nav>')
}

$sortedSnapshots = @($snapshots | Sort-Object Date)
for ($i = 0; $i -lt $sortedSnapshots.Count; $i++) {
  $entry = $sortedSnapshots[$i]
  $links = @(
    '<a href="../index.html">Homepage</a>',
    '<a href="../snapshots/">Snapshots</a>'
  )
  if ($i -gt 0) { $links += "<a href=""../snapshots/$($sortedSnapshots[$i - 1].File)"">Previous: $($sortedSnapshots[$i - 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Previous</span>' }
  if ($i -lt $sortedSnapshots.Count - 1) { $links += "<a href=""../snapshots/$($sortedSnapshots[$i + 1].File)"">Next: $($sortedSnapshots[$i + 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Next</span>' }
  if ($collections.Posts[$entry.Date]) { $links += "<a href=""../posts/$($collections.Posts[$entry.Date].File)"">Daily Journal</a>" }
  if ($collections.Macro[$entry.Date]) { $links += "<a href=""../macro/posts/$($collections.Macro[$entry.Date].File)"">Macro Lens</a>" }
  Replace-Nav (Join-Path $SiteRoot $entry.Href) ('<nav class="top-nav">' + ($links -join '') + '</nav>')
}

foreach ($entry in $vault) {
  Repair-LegacyLinks (Join-Path $SiteRoot $entry.Href) 'vault'
}

foreach ($entry in $private) {
  Repair-LegacyLinks (Join-Path $SiteRoot $entry.Href) 'private'
}

Repair-LibraryLinks

Write-Host "Built market desk site: $($allDates.Count) dates, $($posts.Count) daily journals, $($macro.Count) macro lens entries, $($snapshots.Count) snapshots, $($vault.Count) vault entries."
