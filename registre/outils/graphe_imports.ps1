<#
  R1 - Graphe d'imports Dart depuis lib/main.dart sur une reference Git (LECTURE SEULE).

  Usage : powershell -NoProfile -ExecutionPolicy Bypass -File graphe_imports.ps1 [-Ref main]

  Le depot n'est jamais ecrit : seules `git rev-parse`, `git ls-tree`, `git show` et
  `git cat-file --batch` (lecture d'objets) sont appelees. Les sorties vont dans -OutDir
  (par defaut le dossier du script, hors depot).

  Directives lues : import, export, part (pas `part of`), y compris les imports
  conditionnels (`import 'a.dart' if (dart.library.io) 'b.dart'` : les deux cibles comptent).
  URI resolues : relatives au fichier, et package:<nom du pubspec>/... -> lib/...
  Les URI dart: et package: d'autres paquets sont ignorees.
  Le BOM UTF-8 eventuel en tete de fichier est retire avant analyse (sinon la premiere
  directive d'un fichier a BOM serait manquee).
#>
param(
  [string]$Repo = 'D:\RA _APP\RA -OFFICIAL-APP',
  [string]$Ref = 'main',
  [string]$OutDir = $PSScriptRoot
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$utf8 = New-Object Text.UTF8Encoding($false)

$sha = (git -C $Repo rev-parse --verify "$Ref^{commit}").Trim()
$pubspec = (git -C $Repo show "${sha}:pubspec.yaml") -join "`n"
$pkg = ([regex]::Match($pubspec, '(?m)^name:\s*(\S+)')).Groups[1].Value
if (-not $pkg) { throw 'nom de paquet introuvable dans pubspec.yaml' }

$files = @(git -C $Repo -c core.quotepath=off ls-tree -r --name-only $sha | Where-Object { $_ -like '*.dart' })
$set = @{}; foreach ($f in $files) { $set[$f] = $true }

# --- lecture des blobs en un seul processus git (cat-file --batch, lecture pure) ---
$psi = New-Object Diagnostics.ProcessStartInfo
$psi.FileName = 'git'
$psi.Arguments = "-C `"$Repo`" cat-file --batch"
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$proc = [Diagnostics.Process]::Start($psi)
$script:stdin = $proc.StandardInput.BaseStream
$script:stdout = $proc.StandardOutput.BaseStream
# .NET Framework ecrit un BOM sur stdin a la creation de StandardInput (AutoFlush) quand
# l'encodage console est UTF-8 : une premiere requete sacrificielle l'absorbe.
$sac = $utf8.GetBytes("absorbe-bom`n"); $script:stdin.Write($sac, 0, $sac.Length); $script:stdin.Flush()

function Read-LineBytes {
  $ms = New-Object IO.MemoryStream
  while ($true) {
    $b = $script:stdout.ReadByte()
    if ($b -lt 0 -or $b -eq 10) { break }
    $ms.WriteByte([byte]$b)
  }
  return $utf8.GetString($ms.ToArray())
}
[void](Read-LineBytes)   # reponse « absorbe-bom missing »
function Read-Blob([string]$path) {
  $req = $utf8.GetBytes("${sha}:$path`n")
  $script:stdin.Write($req, 0, $req.Length); $script:stdin.Flush()
  $hdr = Read-LineBytes
  if ($hdr -match 'missing$') { throw "absent : $path" }
  $size = [int]($hdr.Split(' ')[2])
  $buf = New-Object byte[] $size
  $off = 0
  while ($off -lt $size) {
    $n = $script:stdout.Read($buf, $off, $size - $off)
    if ($n -le 0) { throw "EOF sur $path" }
    $off += $n
  }
  [void]$script:stdout.ReadByte()
  return $utf8.GetString($buf)
}

function Resolve-DartUri([string]$from, [string]$uri) {
  if ($uri.StartsWith('dart:')) { return $null }
  if ($uri.StartsWith('package:')) {
    $p = $uri.Substring(8); $i = $p.IndexOf('/')
    if ($i -lt 0 -or $p.Substring(0, $i) -ne $pkg) { return $null }
    return 'lib/' + $p.Substring($i + 1)
  }
  if ($uri -match '^[A-Za-z][A-Za-z0-9+.-]*:') { return $null }
  $dir = $from.Substring(0, $from.LastIndexOf('/'))
  $parts = New-Object System.Collections.Generic.List[string]
  foreach ($s in ($dir + '/' + $uri).Split('/')) {
    if ($s -eq '.' -or $s -eq '') { continue }
    if ($s -eq '..') { if ($parts.Count) { $parts.RemoveAt($parts.Count - 1) }; continue }
    $parts.Add($s)
  }
  return ($parts -join '/')
}

$rxDir = [regex]'(?m)^[ \t]*(?:import|export|part)\b(?![ \t]+of\b)([^;]*);'
$rxStr = [regex]"'([^']*)'|`"([^`"]*)`""

$edges = @{}; $lineCount = @{}; $unresolved = New-Object System.Collections.Generic.List[string]
$bomFiles = New-Object System.Collections.Generic.List[string]
foreach ($f in $files) {
  $t = Read-Blob $f
  if ($t.Length -gt 0 -and $t[0] -eq [char]0xFEFF) { $bomFiles.Add($f); $t = $t.Substring(1) }
  $lineCount[$f] = $t.Length - $t.Replace("`n", '').Length
  $targets = New-Object System.Collections.Generic.List[string]
  foreach ($m in $rxDir.Matches($t)) {
    foreach ($q in $rxStr.Matches($m.Groups[1].Value)) {
      $u = if ($q.Groups[1].Success) { $q.Groups[1].Value } else { $q.Groups[2].Value }
      $res = Resolve-DartUri $f $u
      if ($null -eq $res) { continue }
      if ($set.ContainsKey($res)) { $targets.Add($res) } else { $unresolved.Add("$f -> $u") }
    }
  }
  $edges[$f] = $targets
}
$script:stdin.Close(); $proc.WaitForExit()

function Get-Closure([string]$root) {
  $seen = New-Object 'System.Collections.Generic.HashSet[string]'
  $q = New-Object 'System.Collections.Generic.Queue[string]'
  [void]$seen.Add($root); $q.Enqueue($root)
  while ($q.Count) {
    $c = $q.Dequeue()
    foreach ($n in $edges[$c]) { if ($seen.Add($n)) { $q.Enqueue($n) } }
  }
  return , $seen
}

$reach = Get-Closure 'lib/main.dart'
$lib = @($files | Where-Object { $_ -like 'lib/*' })
$unreach = @($lib | Where-Object { -not $reach.Contains($_) })
$unreachNoGen = @($unreach | Where-Object { $_ -notlike '*.g.dart' })

# importeurs dans lib/ (graphe inverse)
$importers = @{}
foreach ($f in $lib) { foreach ($n in $edges[$f]) { if (-not $importers.ContainsKey($n)) { $importers[$n] = New-Object System.Collections.Generic.List[string] }; $importers[$n].Add($f) } }

# tests : import direct et atteinte transitive
$tests = @($files | Where-Object { $_ -like 'test/*' })
$direct = @{}; $trans = @{}
foreach ($t in $tests) {
  foreach ($n in $edges[$t]) { if ($n -like 'lib/*') { if (-not $direct.ContainsKey($n)) { $direct[$n] = New-Object System.Collections.Generic.List[string] }; if (-not $direct[$n].Contains($t)) { $direct[$n].Add($t) } } }
  foreach ($n in (Get-Closure $t)) { if ($n -like 'lib/*') { if (-not $trans.ContainsKey($n)) { $trans[$n] = New-Object System.Collections.Generic.List[string] }; $trans[$n].Add($t) } }
}

$rows = foreach ($f in $unreach) {
  $imp = if ($importers.ContainsKey($f)) { @($importers[$f]) } else { @() }
  $impReach = @($imp | Where-Object { $reach.Contains($_) })
  [pscustomobject]@{
    fichier            = $f
    module             = $f.Substring(0, $f.LastIndexOf('/'))
    genere             = ($f -like '*.g.dart')
    lignes             = $lineCount[$f]
    importeurs_lib     = ($imp -join ' ; ')
    importeurs_atteints = ($impReach -join ' ; ')
    tests_directs      = if ($direct.ContainsKey($f)) { (@($direct[$f]) -join ' ; ') } else { '' }
    nb_tests_transitifs = if ($trans.ContainsKey($f)) { $trans[$f].Count } else { 0 }
    tests_transitifs   = if ($trans.ContainsKey($f)) { (@($trans[$f] | Where-Object { $_ -like '*_test.dart' }) -join ' ; ') } else { '' }
  }
}

$outTsv = Join-Path $OutDir "r1_non_atteignables_$($sha.Substring(0,7)).tsv"
$rows | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation | ForEach-Object { $_ } | Set-Content -Encoding UTF8 $outTsv
$outReach = Join-Path $OutDir "r1_atteignables_$($sha.Substring(0,7)).txt"
@($lib | Where-Object { $reach.Contains($_) } | Sort-Object) | Set-Content -Encoding UTF8 $outReach
$outUnres = Join-Path $OutDir "r1_uri_non_resolues_$($sha.Substring(0,7)).txt"
@($unresolved) | Set-Content -Encoding UTF8 $outUnres

"ref=$Ref sha=$sha paquet=$pkg"
"fichiers .dart dans l'arbre : $($files.Count) ; lib/ : $($lib.Count) (dont .g.dart : $(@($lib | Where-Object { $_ -like '*.g.dart' }).Count)) ; test/ : $($tests.Count)"
"atteignables depuis lib/main.dart (lib/) : $(@($lib | Where-Object { $reach.Contains($_) }).Count)"
"NON atteignables lib/ : $($unreach.Count) ; hors .g.dart : $($unreachNoGen.Count) ; lignes hors .g.dart : $((@($unreachNoGen | ForEach-Object { $lineCount[$_] }) | Measure-Object -Sum).Sum)"
"fichiers a BOM : $($bomFiles.Count) -> $($bomFiles -join ', ')"
"URI package:$pkg / relatives non resolues : $($unresolved.Count)"
"sorties : $outTsv | $outReach | $outUnres"
