# Assemble a my-edition page: template + rail + content fragments, MathJax inlined.
# usage: powershell -NoProfile -ExecutionPolicy Bypass -File assemble.ps1 <template> <title.txt> <rail.html> <mathjax.js|-> <out.html> <fragment.html>...
# Pass "-" for <mathjax.js> to keep the CDN tag (light version).
# Fragments may contain {{FILE:<path>}} which is replaced by that file's contents.
param(
  [Parameter(Mandatory=$true, Position=0)][string]$Template,
  [Parameter(Mandatory=$true, Position=1)][string]$TitleFile,
  [Parameter(Mandatory=$true, Position=2)][string]$Rail,
  [Parameter(Mandatory=$true, Position=3)][string]$MathJax,
  [Parameter(Mandatory=$true, Position=4)][string]$Out,
  [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Fragments
)
$ErrorActionPreference = 'Stop'
foreach ($p in @($Template, $TitleFile, $Rail)) {
  if (-not (Test-Path -LiteralPath $p)) { throw "not found: $p" }
}
if ($MathJax -ne '-' -and -not (Test-Path -LiteralPath $MathJax)) { throw "not found: $MathJax" }
for ($i = 0; $i -lt $Fragments.Length; $i++) {
  if (-not (Test-Path -LiteralPath $Fragments[$i])) { throw "not found: $($Fragments[$i])" }
  if ($i -lt $Fragments.Length - 1) {
    if ((Get-Content -LiteralPath $Fragments[$i] -Raw) -like '*class="colophon"*') {
      Write-Warning "$($Fragments[$i]) is not the last fragment but contains a colophon; it will appear mid-book"
    }
  }
}
$enc  = [System.Text.Encoding]::UTF8
$utf8 = New-Object System.Text.UTF8Encoding($false)
$title = @([System.IO.File]::ReadAllLines($TitleFile, $enc))[0]
if ($title -match "['<>&]") { Write-Warning "title contains a special character; use a plain title" }
$token = '{{BOOK_TITLE}}'
function Expand-FileTokens([string]$s) {
  while ($true) {
    $p = $s.IndexOf('{{FILE:')
    if ($p -lt 0) { break }
    $q = $s.IndexOf('}}', $p)
    if ($q -lt 0) { break }
    $path = $s.Substring($p + 7, $q - $p - 7)
    if (Test-Path -LiteralPath $path) {
      $data = ([System.IO.File]::ReadAllText($path, $enc)) -replace "`r?`n", ''
    } else {
      Write-Warning "referenced file not found: $path"
      $data = ''
    }
    $s = $s.Substring(0, $p) + $data + $s.Substring($q + 2)
  }
  return $s
}
$sw = New-Object System.IO.StreamWriter($Out, $false, $utf8)
$sw.NewLine = "`n"
try {
  foreach ($line in [System.IO.File]::ReadAllLines($Template, $enc)) {
    if ($line.Contains('<!-- RAIL -->')) {
      foreach ($l in [System.IO.File]::ReadAllLines($Rail, $enc)) { $sw.WriteLine((Expand-FileTokens $l)) }
    }
    elseif ($line.Contains('<!-- CONTENT -->')) {
      foreach ($f in $Fragments) {
        foreach ($l in [System.IO.File]::ReadAllLines($f, $enc)) { $sw.WriteLine((Expand-FileTokens $l)) }
        $sw.WriteLine('')
      }
    }
    elseif ($line.Contains('<script id="MathJax-script"')) {
      if ($MathJax -ne '-') {
        $sw.WriteLine('<script id="MathJax-script">')
        $sw.Write([System.IO.File]::ReadAllText($MathJax, $enc))
        $sw.WriteLine()
        $sw.WriteLine('</script>')
      } else {
        $sw.WriteLine($line.Replace($token, $title))
      }
    }
    else { $sw.WriteLine($line.Replace($token, $title)) }
  }
} finally { $sw.Close() }
Write-Output "wrote $Out"
