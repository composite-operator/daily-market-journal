Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SiteRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Html($Value) {
  return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Date-FromName($Name) {
  $match = [regex]::Match($Name, '^(\d{4}-\d{2}-\d{2})')
  if (-not $match.Success) { return $null }
  return $match.Groups[1].Value
}

function Parse-Date($Date) {
  return [datetime]::ParseExact($Date, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
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

function Get-DatedFiles($Folder, $Kind, $Title) {
  $path = Join-Path $SiteRoot $Folder
  if (-not (Test-Path -LiteralPath $path)) { return @() }
  return @(Get-ChildItem -LiteralPath $path -Filter '*.html' |
    Where-Object { $_.Name -ne 'index.html' } |
    ForEach-Object {
      $date = Date-FromName $_.Name
      if ($date) {
        [pscustomobject]@{
          Date = $date
          File = $_.Name
          Folder = $Folder
          Href = "$Folder/$($_.Name)"
          Kind = $Kind
          Title = $Title
        }
      }
    } |
    Sort-Object Date)
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

function Site-Nav($Prefix, $Current) {
  $items = @(
    @{ Key = 'home'; Label = 'Hub'; Href = "${Prefix}index.html" },
    @{ Key = 'archive'; Label = 'All History'; Href = "${Prefix}archive/" },
    @{ Key = 'vault'; Label = 'Vault'; Href = "${Prefix}vault/" },
    @{ Key = 'posts'; Label = 'Journal'; Href = "${Prefix}posts/" },
    @{ Key = 'snapshots'; Label = 'Snapshots'; Href = "${Prefix}snapshots/" }
  )
  $links = $items | ForEach-Object {
    $currentAttr = if ($_.Key -eq $Current) { ' aria-current="page"' } else { '' }
    "<a href=""$($_.Href)""$currentAttr>$($_.Label)</a>"
  }
  return @"
  <nav class="site-nav" aria-label="Site sections">
    <strong>Daily Market Journal</strong>
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
  <link rel="stylesheet" href="${Prefix}assets/style.css?v=12">
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

function Build-ArchiveRows($Dates, $Collections, $Prefix) {
  $months = $Dates | Group-Object { (Parse-Date $_).ToString('yyyy-MM') } | Sort-Object Name -Descending
  $html = foreach ($month in $months) {
    $monthDates = @($month.Group | Sort-Object -Descending)
    $rows = foreach ($date in $monthDates) {
      $post = $Collections.Posts[$date]
      $vault = $Collections.Vault[$date]
      $snapshot = $Collections.Snapshots[$date]
      $private = $Collections.Private[$date]
      @"
        <div class="archive-row">
          <div class="date-block">
            <strong>$(Short-Date $date)</strong>
            <span>$(Weekday $date)</span>
          </div>
          <div class="archive-actions">
            $(Link-OrMissing $vault $Prefix 'Vault' '')
            $(Link-OrMissing $post $Prefix 'Journal' 'public')
            $(Link-OrMissing $snapshot $Prefix 'Snapshot' 'snapshot')
            $(if ($private) { Link-OrMissing $private $Prefix 'Legacy Private' 'private' })
          </div>
        </div>
"@
    }
    @"
      <section class="archive-month">
        <h3>$(Month-Name $monthDates[0])</h3>
        $($rows -join "`r`n")
      </section>
"@
  }
  return ($html -join "`r`n")
}

function Build-CollectionList($Entries, $PagePrefix, $LinkPrefix) {
  $months = $Entries | Group-Object { (Parse-Date $_.Date).ToString('yyyy-MM') } | Sort-Object Name -Descending
  $html = foreach ($month in $months) {
    $items = @($month.Group | Sort-Object Date -Descending) | ForEach-Object {
      @"
        <li class="collection-item">
          <a href="$LinkPrefix$($_.File)">$(Html $_.Date)</a>
          <span class="resource-note">$($_.Title)</span>
        </li>
"@
    }
    @"
      <section class="archive-month">
        <h3>$(Month-Name $month.Group[0].Date)</h3>
        <ul class="collection-list">
          $($items -join "`r`n")
        </ul>
      </section>
"@
  }
  return ($html -join "`r`n")
}

function Build-CollectionPage($RelativePath, $Title, $Dek, $Current, $Entries, $CollectionRoot) {
  $prefix = '../'
  $latest = @($Entries | Sort-Object Date)[-1]
  $body = @"
$(Page-Head $Title $prefix)
<body>
$(Site-Nav $prefix $Current)
  <div class="topline">
    <header>
      <p class="eyebrow">Archive Collection</p>
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
      $(Build-CollectionList $Entries $prefix '')
    </div>
  </main>
  <footer>Static archive. Not financial advice.</footer>
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
  if ($Folder -eq 'private') {
    $html = $html -replace 'href="\.\./">Private Index</a>', 'href="index.html">Private Index</a>'
  }
  [System.IO.File]::WriteAllText($Path, $html.TrimEnd() + "`r`n", $Utf8NoBom)
}

$posts = Get-DatedFiles 'posts' 'post' 'Daily Market Journal'
$vault = Get-DatedFiles 'vault' 'vault' 'Encrypted Vault Entry'
$snapshots = Get-DatedFiles 'snapshots' 'snapshot' 'Tracking Snapshot'
$private = Get-DatedFiles 'private' 'private' 'Legacy Private Entry'

$collections = [pscustomobject]@{
  Posts = @{}
  Vault = @{}
  Snapshots = @{}
  Private = @{}
}
foreach ($entry in $posts) { $collections.Posts[$entry.Date] = $entry }
foreach ($entry in $vault) { $collections.Vault[$entry.Date] = $entry }
foreach ($entry in $snapshots) { $collections.Snapshots[$entry.Date] = $entry }
foreach ($entry in $private) { $collections.Private[$entry.Date] = $entry }

$allDates = @($posts.Date + $vault.Date + $snapshots.Date + $private.Date | Sort-Object -Unique)
$latestDate = @($allDates | Sort-Object)[-1]
$oldestDate = @($allDates | Sort-Object)[0]
$latestPost = $collections.Posts[$latestDate]
$latestVault = $collections.Vault[$latestDate]
$latestSnapshot = $collections.Snapshots[$latestDate]

$latestLinks = @()
if ($latestVault) { $latestLinks += "<a class=""box-link"" href=""$($latestVault.Href)"">Open Vault</a>" }
if ($latestPost) { $latestLinks += "<a class=""box-link"" href=""$($latestPost.Href)"">Open Journal</a>" }
if ($latestSnapshot) { $latestLinks += "<a class=""box-link"" href=""$($latestSnapshot.Href)"">Open Snapshot</a>" }

$rootPage = @"
$(Page-Head 'Daily Market Journal Archive' '')
<body>
$(Site-Nav '' 'home')
  <main>
    <div class="hub-hero">
      <div class="hero-panel">
        <p class="eyebrow">Market Notes Archive</p>
        <h1 class="hub-title">Daily Market Journal Archive</h1>
        <p class="hub-dek">A single access point for the finished journal entries, encrypted vault copies, tracking snapshots, and older private archive material.</p>
      </div>
      <aside class="latest-panel" aria-label="Latest archive packet">
        <p class="eyebrow">Latest Packet</p>
        <span class="date">$latestDate</span>
        <div class="link-strip">
          $($latestLinks -join "`r`n          ")
        </div>
      </aside>
    </div>

    <div class="quick-grid" aria-label="Archive sections">
      <a class="clicker-card" href="vault/">
        <span class="clicker-label">Encrypted</span>
        <span class="clicker-value">Private Market Vault</span>
        <span class="clicker-meta">$($vault.Count) vault entries</span>
      </a>
      <a class="clicker-card public" href="posts/">
        <span class="clicker-label">Readable Notes</span>
        <span class="clicker-value">Daily Journal</span>
        <span class="clicker-meta">$($posts.Count) public summaries</span>
      </a>
      <a class="clicker-card snapshot" href="snapshots/">
        <span class="clicker-label">Board State</span>
        <span class="clicker-value">Tracking Snapshots</span>
        <span class="clicker-meta">$($snapshots.Count) snapshot pages</span>
      </a>
      <a class="clicker-card archive" href="archive/">
        <span class="clicker-label">All Materials</span>
        <span class="clicker-value">Month Archive</span>
        <span class="clicker-meta">$(Short-Date $oldestDate) through $(Short-Date $latestDate)</span>
      </a>
    </div>

    <section>
      <h2>Complete Month History</h2>
      <p class="resource-note">Each row shows the material available for that date.</p>
    </section>
    <div class="archive-shell">
      $(Build-ArchiveRows $allDates $collections '')
    </div>
  </main>
  <footer>Static archive. Not financial advice.</footer>
</body>
</html>
"@
Write-Text 'index.html' $rootPage

$archive = @"
$(Page-Head 'Complete Month Archive' '../')
<body>
$(Site-Nav '../' 'archive')
  <div class="topline">
    <header>
      <p class="eyebrow">All Materials</p>
      <h1>Complete Month Archive</h1>
      <p class="dek">Month-by-month access to every dated journal, vault page, snapshot, and legacy private entry present in this repository.</p>
    </header>
  </div>
  <main>
    <section>
      <h2>Coverage</h2>
      <div class="metric-strip">
        <div class="metric"><span class="metric-value">$($allDates.Count)</span><span class="metric-label">Dated Sessions</span></div>
        <div class="metric metric-open"><span class="metric-value">$($posts.Count)</span><span class="metric-label">Journal Pages</span></div>
        <div class="metric metric-buybox"><span class="metric-value">$($vault.Count)</span><span class="metric-label">Vault Pages</span></div>
        <div class="metric metric-review"><span class="metric-value">$($snapshots.Count)</span><span class="metric-label">Snapshots</span></div>
      </div>
    </section>
    <div class="archive-shell">
      $(Build-ArchiveRows $allDates $collections '../')
    </div>
  </main>
  <footer>Static archive. Not financial advice.</footer>
</body>
</html>
"@
Write-Text 'archive/index.html' $archive

Build-CollectionPage 'posts/index.html' 'Daily Journal Archive' 'Finished public journal summaries, grouped by month.' 'posts' $posts 'posts'
Build-CollectionPage 'snapshots/index.html' 'Tracking Snapshot Archive' 'Cleaned static board snapshots generated from the tracking sheet, grouped by month.' 'snapshots' $snapshots 'snapshots'
Build-CollectionPage 'vault/index.html' 'Private Market Vault' 'Encrypted daily market journal copies, grouped by month and ordered newest first.' 'vault' $vault 'vault'
if ($private.Count -gt 0) {
  Build-CollectionPage 'private/index.html' 'Legacy Private Archive' 'Older encrypted private entries retained for continuity.' 'archive' $private 'private'
}

# posts.json stays in chronological order for existing consumers.
$jsonItems = $posts | ForEach-Object {
  [pscustomobject]@{
    date = $_.Date
    href = $_.Href
    title = if ($_.File -like '*sunday-livestream*') { 'Sunday Night Livestream Journal' } else { 'Daily Market Journal' }
  }
}
Write-Text 'posts.json' ($jsonItems | ConvertTo-Json -Depth 4)

# Dated page navigation.
$sortedPosts = @($posts | Sort-Object Date)
for ($i = 0; $i -lt $sortedPosts.Count; $i++) {
  $entry = $sortedPosts[$i]
  $links = @(
    '<a href="https://ximxesabortion.github.io/">Home</a>',
    '<a href="../index.html">Archive Hub</a>',
    '<a href="../posts/">Journal Archive</a>'
  )
  if ($i -gt 0) { $links += "<a href=""../posts/$($sortedPosts[$i - 1].File)"">Previous: $($sortedPosts[$i - 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Previous</span>' }
  if ($i -lt $sortedPosts.Count - 1) { $links += "<a href=""../posts/$($sortedPosts[$i + 1].File)"">Next: $($sortedPosts[$i + 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Next</span>' }
  if ($collections.Snapshots[$entry.Date]) { $links += "<a href=""../snapshots/$($collections.Snapshots[$entry.Date].File)"">Snapshot</a>" }
  if ($collections.Vault[$entry.Date]) { $links += "<a href=""../vault/$($collections.Vault[$entry.Date].File)"">Vault</a>" }
  Replace-Nav (Join-Path $SiteRoot $entry.Href) ('<nav class="top-nav">' + ($links -join '') + '</nav>')
  Update-SnapshotCallout (Join-Path $SiteRoot $entry.Href) $collections.Snapshots[$entry.Date]
}

$sortedVault = @($vault | Sort-Object Date)
for ($i = 0; $i -lt $sortedVault.Count; $i++) {
  $entry = $sortedVault[$i]
  $links = @(
    '<a href="https://ximxesabortion.github.io/">Home</a>',
    '<a href="../index.html">Archive Hub</a>',
    '<a href="../vault/">Vault Archive</a>'
  )
  if ($i -gt 0) { $links += "<a href=""../vault/$($sortedVault[$i - 1].File)"">Previous: $($sortedVault[$i - 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Previous</span>' }
  if ($i -lt $sortedVault.Count - 1) { $links += "<a href=""../vault/$($sortedVault[$i + 1].File)"">Next: $($sortedVault[$i + 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Next</span>' }
  if ($collections.Snapshots[$entry.Date]) { $links += "<a href=""../snapshots/$($collections.Snapshots[$entry.Date].File)"">Snapshot</a>" }
  if ($collections.Posts[$entry.Date]) { $links += "<a href=""../posts/$($collections.Posts[$entry.Date].File)"">Journal</a>" }
  Replace-Nav (Join-Path $SiteRoot $entry.Href) ('<nav class="top-nav">' + ($links -join '') + '</nav>')
}

$sortedSnapshots = @($snapshots | Sort-Object Date)
for ($i = 0; $i -lt $sortedSnapshots.Count; $i++) {
  $entry = $sortedSnapshots[$i]
  $links = @(
    '<a href="https://ximxesabortion.github.io/">Home</a>',
    '<a href="../index.html">Archive Hub</a>',
    '<a href="../snapshots/">Snapshot Archive</a>'
  )
  if ($i -gt 0) { $links += "<a href=""../snapshots/$($sortedSnapshots[$i - 1].File)"">Previous: $($sortedSnapshots[$i - 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Previous</span>' }
  if ($i -lt $sortedSnapshots.Count - 1) { $links += "<a href=""../snapshots/$($sortedSnapshots[$i + 1].File)"">Next: $($sortedSnapshots[$i + 1].Date)</a>" }
  else { $links += '<span class="nav-disabled">Next</span>' }
  if ($collections.Posts[$entry.Date]) { $links += "<a href=""../posts/$($collections.Posts[$entry.Date].File)"">Journal</a>" }
  if ($collections.Vault[$entry.Date]) { $links += "<a href=""../vault/$($collections.Vault[$entry.Date].File)"">Vault</a>" }
  Replace-Nav (Join-Path $SiteRoot $entry.Href) ('<nav class="top-nav">' + ($links -join '') + '</nav>')
}

foreach ($entry in $vault) {
  Repair-LegacyLinks (Join-Path $SiteRoot $entry.Href) 'vault'
}

foreach ($entry in $private) {
  Repair-LegacyLinks (Join-Path $SiteRoot $entry.Href) 'private'
}

Write-Host "Built archive site: $($allDates.Count) dates, $($posts.Count) posts, $($vault.Count) vault entries, $($snapshots.Count) snapshots."
