# Exécute une commande Flutter/Dart lourde sous un verrou système partagé par tous les agents.
# Usage (dans UN SEUL appel PowerShell) :
#   & "D:\RA _APP\pilotage-tuteur-v1\outils\flutter-verrou.ps1" -Dossier "D:\RA_TUTEUR\lot-b" -Commande "dart analyze lib/features/suivi_foyer"
# Le verrou est libéré à la fin de la commande, ou automatiquement si le processus meurt.
# Pourquoi : 4 cœurs et 7,9 Go de RAM ; deux analyses ou suites de tests simultanées saturent la machine.
param(
  [Parameter(Mandatory = $true)][string]$Dossier,
  [Parameter(Mandatory = $true)][string]$Commande,
  [int]$AttenteMaxMinutes = 40
)

$mutex = New-Object System.Threading.Mutex($false, 'Global\RewayahTuteurFlutterLourd')
$acquis = $false
try {
  try {
    $acquis = $mutex.WaitOne([TimeSpan]::FromMinutes($AttenteMaxMinutes))
  } catch [System.Threading.AbandonedMutexException] {
    $acquis = $true
  }
  if (-not $acquis) {
    Write-Output "VERROU: attente de $AttenteMaxMinutes min dépassée, commande NON exécutée."
    exit 99
  }
  $debut = Get-Date
  Write-Output "VERROU acquis $(Get-Date -Format HH:mm:ss) -> $Commande"
  Push-Location $Dossier
  try {
    $env:PATH = "C:\flutter\bin;" + $env:PATH
    cmd /c $Commande
    $code = $LASTEXITCODE
  } finally {
    Pop-Location
  }
  Write-Output ("VERROU libéré, durée {0:N0} s, code {1}" -f ((Get-Date) - $debut).TotalSeconds, $code)
  exit $code
} finally {
  if ($acquis) { $mutex.ReleaseMutex() }
  $mutex.Dispose()
}
