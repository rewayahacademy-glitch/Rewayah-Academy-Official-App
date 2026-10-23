# UX_REVIEW_ADM-PAI : la saisie des paiements reçus (17/10/2026)

- **Étape** : ADM-PAI (passation du 17/10, point 3 ; FAC-C-01), cinquième onglet du domaine
  Finance de la direction.
- **Cadre** : `lib/CLAUDE.md` (K-54 à K-59, ONGLETS-1) ; `03_DESIGN_SYSTEM_ET_UX.md` ;
  DESIGN-GOV-2026-09-26 (aucun jeton, composant ni durée nouveaux). La disposition reprend
  celle de l'onglet « À valider » (liste puis feuille de décision), déjà construite.
- **Sources** : Material 3 (bottom sheets ; dialogs sur grand écran), WCAG 2.2 (3.3.1 Error
  Identification, 3.3.3 Error Suggestion, 3.3.4 Error Prevention pour les données
  financières), Nielsen (prévention des erreurs, reconnaissance plutôt que rappel), Baymard
  (préremplir ce qui est connu). Pas de navigation web dans cette session : règles citées de
  mémoire.

| Point | Règle | Conclusion |
|---|---|---|
| Liste puis fiche | Nielsen, reconnaissance ; K-55 | Deux sections à lignes fines (`CarteLignes`), jamais de cartes collées ; la ligne entière ouvre la fiche (`SettingRow`, lien). |
| Ordre | Hick ; tâche fréquente d'abord | « À régulariser » en tête, le plus dû d'abord (ordre du serveur). |
| Montant | K-57 ; Baymard | Prérempli avec le reste à payer, corrigeable ; la devise est dans l'étiquette, jamais à saisir. |
| Erreur de saisie | WCAG 3.3.1, 3.3.3 ; K-59 | La phrase sous le champ dit quoi écrire (« par exemple 50 ou 50,50 ») ; rien ne part. |
| Double envoi | WCAG 3.3.4 ; D5 | Clé d'idempotence tirée une fois par fiche ; « Réessayer » rejoue la même clé et le même montant ; l'écran annonce seulement ce que le serveur rend. |
| Une action pleine | K-56 | « Enregistrer le paiement de {prénom} » plein, au bord trailing ; « Annuler » tertiaire. |
| Bureau | Material 3, dialogs | `AppBottomSheet.ouvrir` rend une boîte de dialogue sur bureau, une feuille sur téléphone. |
| Navigation | ONGLETS-1 | Cinq sections : `SelecteurSection` passe en menu déroulant sur téléphone, en ligne sur bureau, sans rien découper. |

Limite (§4.3) : aucun standard ne change qui peut saisir (direction et comptabilité, décidé
côté serveur), ni la règle de financement (aucun débit partiel, FIN4-09).

Preuves : `test/features/admin_finance/paiements_test.dart` (320 px texte ×2 et 1440 px,
clair et sombre, LTR et RTL, une seule action pleine) ;
`test/core/capacites/paiements_saisis_supabase_test.dart` (JSON réels de la base rejouée).
