# UX_REVIEW PE-CONDUITE-ACTIVATION : le code de conduite sur la page des accords (21/10/2026)

- **Lot** : `CAND-Q15`, lot conduite
  (`docs/current/CANDIDATURES/CORRECTIFS_HORS_MODULE_PROPOSES.md`, section 7).
- **Écran** : `/attente/accords`, la page unique des accords du lot E6
  (`lib/features/dossier/accords_page.dart`). Écran existant : aucune route, aucun
  écran nouveau. Le portail `/attente` ne change pas d'apparence.
- **Cadre** :
  - DECISION-ENTREE-2026-10-17, section « Accords et consentements » ;
  - DESIGN-GOV-2026-09-26, §4 et §4 bis (aucune couleur, police, durée ni jeton
    nouveau, K-37) ;
  - `CLAUDE.md` : un widget lit une capacité, jamais un rôle ; cinq états.
- **Règle métier tenue** (non modifiable par ce document, §4.3) : la règle 9 du code
  validé le 19/10, « si vous refusez ces règles, l'académie ne peut pas vous confier
  d'élèves ». Depuis la migration `20261021210400`, la garde d'activation du compte
  enseignant exige le code à sa version requise (`2026-10-19`). Le code se signe donc
  avant l'activation, sur cette page.

## Ce qui change à l'écran

1. **Une cinquième section**, « Code de conduite de l'enseignant », après celle du
   contrat. Elle n'apparaît que si le serveur dit le code à accepter
   (`etat_dossier()` rend `code_conduite_signe` faux). Le serveur rend vrai pour tout
   compte qui n'est pas enseignant : l'écran ne lit aucun rôle pour la montrer, et un
   tuteur ne la voit jamais.
2. **Le texte est celui du profil**, mot pour mot : l'introduction puis les neuf règles
   numérotées. Il sort de `ContenuCodeConduite` dans un widget partagé,
   `TexteCodeConduite`, que le profil et la page des accords affichent tous les deux.
3. **Une case**, « J'ai lu le code de conduite et je l'accepte. »
   (`t.codeConduite.caseAccord`, clé existante). C'est le composant partagé
   `CaseAccordTexte` : toute la carte est la cible.
4. **Le bouton « Suivant »** reste inactif tant que cette case manque. La ligne
   au-dessus du bouton la compte : « Il reste N accords à cocher ».
5. **L'envoi** : accusé, contrat, puis code de conduite, à sa version requise, avant la
   relecture du dossier. Un échec arrête l'envoi, la page et les cases restent, et la
   reprise n'envoie que ce qui manque.
6. **Seul le code manque** (enseignant déjà en attente, accords signés avant ce lot) :
   - « Lire et accepter » du portail mène à la même page ;
   - la case de l'accusé y reste affichée, cochée et figée ;
   - seule la section du code est à cocher.

Aucune clé i18n nouvelle (`t.codeConduite.*` existe en français et en arabe). Aucun
jeton, composant ou espacement nouveau.

## Règles et conclusions

| Point | Règle (consultée le 21/10/2026) | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Une page, une case par texte | DECISION-ENTREE du 17/10 | Conforme : le code est un texte de plus, avec sa propre case, sur la même page qui défile | Section 5 de `accords_page.dart` |
| Pas de passage sans consentir | DECISION-ENTREE du 17/10 (le bouton reste inactif tant qu'une case manque, en remplacement de BOUTONS-GRISES-1 pour les accords) | Conforme : la case du code entre dans le décompte des cases requises | `_Case.codeConduite` dans `requises` |
| Jamais de renvoi en arrière pour cocher après coup | DECISION-ENTREE du 17/10 | Conforme : le code se signe avant l'activation, sur la page d'entrée. Avant ce lot, il se signait au profil, après l'activation | Garde serveur, puis section sur la page |
| Annoncer un état qui change | WCAG 2.2 AA, 4.1.3 Status Messages | Conforme sans changement : la ligne « Il reste N accords » est déjà une région vive ; elle compte le code | Aucune |
| Structure lisible par un lecteur d'écran | WCAG 2.2 AA, 1.3.1 Info and Relationships | Conforme : le titre de section est un en-tête (`_Section`, `Semantics(header: true)`) et les règles gardent leur numéro, écrit dans le texte | Aucune |
| Cible tactile | WCAG 2.2 AA, 2.5.8 Target Size (Minimum) | Conforme : toute la carte de la case est la cible (`CaseAccordTexte`) | Aucune |
| Visibilité de l'état, prévention des erreurs | Nielsen, heuristiques 1 et 5 | Conforme : la ligne au-dessus du bouton dit ce qui manque. Un appui sur le bouton inactif n'envoie rien | Aucune |
| Longueur de ligne d'un texte long | Material 3, typographie ; DESIGN-GOV §4 bis | Conforme : colonne bornée à `AppPage.largeurReglages`, corps `bodyLarge` comme au profil (même texte, même lecture) | Aucune |
| Espacements | DESIGN-GOV §4 bis.1, contrat A | Conforme : mêmes écarts que les autres sections (`Ecart.vXxl` entre sections, `Ecart.vMd` sous le titre, `Ecart.vXl` avant la case) | Aucune |
| Un widget lit une capacité, jamais un rôle | `CLAUDE.md` | Conforme : la section dépend du seul `codeConduiteSigne` lu au serveur | `EtatDossier.codeConduiteSigne` |
| Cinq états | `CLAUDE.md` | Conforme : la page garde ses états. Chargement : squelette. Contenu : la section. Vide : « Vos accords sont déjà enregistrés. ». Erreur : `t.contrat.erreur`, page et cases gardées. Hors ligne : `t.contrat.horsLigne` | Aucune |
| Serveur d'avant ce lot | Prévention des erreurs | Une clé `code_conduite_signe` absente se lit « signé » : un serveur qui n'exige pas le code ne le fait pas demander | `depuisJson` |

Pas de navigation web dans cette session : les règles WCAG, Material et Nielsen sont
citées de mémoire, comme pour `UX_REVIEW_FILTERPILL-ETAT-1.md`.

## Dérogation

Aucune. Un écart de forme, assumé :
- les autres textes de la page sont des lignes groupées (`GroupeReglages`) ;
- le code garde sa liste numérotée en `bodyLarge`.

Raison : c'est le texte validé par le directeur, tel qu'il est lu au profil. La « règle
9 » y est citée par son numéro. Le mettre en lignes groupées en ferait un second texte.

## Preuves

- `test/features/dossier_accords_test.dart`, groupe « Enseignant : le code de conduite
  avant l activation » :
  - la section et sa case après le contrat, « Suivant » inactif tant qu'elle manque ;
  - l'ordre des envois (accusé, contrat, code, version `2026-10-19`) ;
  - « seul le code manque » ;
  - le port de signature serveur ;
  - un échec puis la reprise ;
  - un code déjà accepté ;
  - un tuteur.
- `test/features/attente_test.dart` : le code manquant mène à « Nos conditions » puis à
  la page des accords.
- `test/features/dossier_test.dart` : lecture de `code_conduite_signe`, clé absente,
  ordre de `manquants`, `==` et `hashCode`.
- `test/features/protection_enfants/code_conduite_test.dart` : le profil, inchangé avec
  le texte partagé.
- Contre-épreuve : avec les deux pages d'avant ce lot, cinq des nouveaux tests échouent.
- Captures (`CAPTURE_DIR`, groupe « Capture E6 ») dans
  `docs/current/captures/PE-CONDUITE-ACTIVATION/` :
  - `pe_conduite_accords_390x844_section.png` ;
  - `pe_conduite_accords_1440x900_case.png`.

Arabe : textes existants, à relire par un locuteur natif comme le reste du code de
conduite.
