# Poste A : recopie le dossier de pilotage vers le worktree Git de la branche pilotage/tuteur-v1,
# sans toucher aux fichiers écrits par le poste B (etat/, demandes/, 05_recette/A|B|D),
# puis committe et pousse. Usage : & "D:\RA _APP\pilotage-tuteur-v1\outils\synchroniser-pilotage.ps1" -Message "..."
param([string]$Message = "pilotage: mise a jour du poste A")
$src = "D:\RA _APP\pilotage-tuteur-v1"; $dst = "D:\RA_TUTEUR\pilotage-git"
git -C $dst pull --rebase -q origin pilotage/tuteur-v1
robocopy $src $dst /E /XD tuiles tuiles_V2 captures_0b captures_0c capture_proto polices etat demandes A B D /XF *.log *.dart.txt /NFL /NDL /NJH /NJS | Out-Null
git -C $dst add -A
git -C $dst commit -q -m $Message
git -C $dst push -q origin pilotage/tuteur-v1
git -C $dst log --oneline -1
