# Relecture EA-HORS-LIGNE-1 : REFUSÉE

## Verdict
**REFUSÉE.** Le correctif retire bien la promesse « l'envoi attendra » et le test le prouve : il échoue sur l'ancien texte. En revanche, le travail demandé par la fiche, « vérifier que le texte est vrai sur tous les écrans », n'a pas été fait. Il reste deux majeurs.

1. `reseau.horsLigne` est aussi affiché dans l'état d'erreur des demandes admin. Le message y est faux.
2. « Tout reste consultable » promet trop, ce qui reproduit la classe de défaut que l'étape devait éliminer.

## Périmètre et commandes
- Périmètre : f6ac3658..a6b0ef22, soit 2 commits et 6 fichiers :
  - fr.i18n.json et strings_fr.g.dart (texte du bandeau) ;
  - offline_banner_test.dart (un test ajouté) ;
  - libelles_sources.json (libellé déclaré) ;
  - 2 PNG.
- `dart analyze --fatal-infos` : aucun problème.
- verifier_jetons : 39 violations sur la base et 39 sur la tête, sorties identiques. Rien n'augmente.
- verifier_revue : 1627 violations sur la base et 1627 sur la tête, sorties identiques.
- Contre-épreuve : avec le texte de base et le nouveau test, le test échoue (`Expected: not contains 'envoi'`). Il est vert sur la tête.
- Tests ciblés (--concurrency=2) : bandeau, i18n, invitation du conjoint, observations admin, catalogue et classe tuteur, historique, notifications, compte tuteur, test/tool et demandes admin. Résultat : 214 + 14 réussis, aucun échec.

## Défauts
| Gravité | Où | Quoi |
|---|---|---|
| majeur | lib/features/admin_demandes/demandes_page.dart:132 | L'état d'erreur affiche « L'opération n'a pas abouti : Pas de réseau. Tout reste consultable. » pour n'importe quelle panne, même en ligne (le test demandes_admin_test.dart:257 la déclenche avec StateError). La liste n'a pas chargé, donc rien n'est consultable. Il faut un message d'erreur propre, sans `reseau.horsLigne`. |
| majeur | assets/i18n/fr.i18n.json:133 | « Tout reste consultable » promet trop. Aucune feature ne lit le cache persistant (grep AppDatabase dans lib/features : 0 résultat), et la spec 06:29 limite le cache au planning et aux supports autorisés. Le bandeau apparaît aussi sur le scanner de connexion (scanner_page.dart:478) et sur des écrans jamais chargés. Une formulation vraie existe déjà en fr.i18n.json:29 : « Ce qui est déjà affiché reste consultable. » |
| mineur | docs/current/captures/EA-HORS-LIGNE-1/ | Seulement 2 captures, à 390 en clair et en sombre. Il manque 320, 200 %, 1440, le RTL et le cahier enseignant cité dans la fiche. |
| mineur (hors périmètre) | lib/features/foyer/invitation_conjoint.dart:569 | Le bouton « Envoyer l'invitation » est grisé hors ligne (onPress null), alors que la règle interdit les boutons grisés. Pré-existant depuis EA-6. |

## Captures vues
- ea6_inviter_conjoint_390_light_hors_ligne.png : bandeau sur une ligne, pas de mot coupé, cohérent avec « Rien n'est envoyé ». Bouton principal grisé.
- ea6_inviter_conjoint_390_dark_hors_ligne.png : même constat en sombre, contraste correct.
- Les captures 320, 1440 et 200 % n'existent pas.

## Pour accepter
1. Remplacer le texte par une formulation vraie partout, par exemple « Pas de réseau. Ce qui est déjà affiché reste consultable. », la déclarer dans libelles_sources.json, et adapter le test (présence de « déjà affiché », absence de « tout » et « envoi »).
2. Dans demandes_page.dart:132, ne plus réemployer `reseau.horsLigne` comme cause d'erreur. Afficher une erreur neutre, déclarée, et ajouter un test qui vérifie que l'état d'erreur ne contient pas `reseau.horsLigne`, avec sa contre-épreuve.
3. Ajouter un test de captures du bandeau à 320 (100 % et 200 %), 390 en clair et en sombre, 1440 et en RTL. Ajouter aussi le cahier enseignant hors ligne avec un élément en file, pour montrer que le bandeau et le marqueur « Sera envoyé dès le retour du réseau » ne se contredisent pas. Vérifier ces captures avec aucun_mot_coupe.
4. Pour suivi, hors de cette étape : le bouton grisé de l'invitation du conjoint hors ligne.

## Contre-revue adverse

Verdict confirmé : oui. Verdict final retenu : **REFUSEE**.

Le refus tient. J'ai vérifié chaque défaut grave dans un worktree détaché sur a6b0ef22 (origin/corrections/c2-hors-ligne), retiré ensuite.

(1) Majeur, demandes admin : confirmé. Ligne 132 de lib/features/admin_demandes/demandes_page.dart, l'état hasError affiche t.admin.demandes.erreur(message: t.reseau.horsLigne), soit « L'opération n'a pas abouti : Pas de réseau. Tout reste consultable. ». Ce réemploi existait déjà sur la base f6ac3658, mais la fiche demandait de vérifier que le texte est vrai sur tous les écrans. Or ici la liste n'a pas chargé, et l'état s'affiche pour toute erreur, même en ligne. test/features/demandes_admin_test.dart:257 le déclenche avec StateError('reseau') sans aucun hors ligne. Le texte est donc faux à cet endroit. Les 4 usages de t.reseau.horsLigne dans lib sont bien ceux qu'il cite.

(2) Majeur, promesse « Tout reste consultable » : confirmé. Aucun fichier de lib/features ne lit AppDatabase ni appDatabaseProvider (0 résultat). La ligne 29 de docs/current/06 ne garantit en cache que « Planning et supports autorisés ». Le bandeau est posé sans condition sur le scanner de connexion élève (scanner_page.dart:478), dans PageShell (page_shell.dart:211) et dans ecran_a_construire.dart:28. La formulation vraie existe déjà à la ligne 29 de fr.i18n.json : « Ce qui est déjà affiché reste consultable ». Le lot échange une promesse fausse contre une autre.

(3) et (4) Mineurs : confirmés. Le dossier de captures ne contient que les 2 PNG ea6 à 390 px, et le diff ne touche que offline_banner_test.dart sous test/.

Tests ciblés lancés avec --concurrency=2 sur offline_banner_test et demandes_admin_test : +19, tous verts. Ils sont verts parce qu'aucun ne contrôle la véracité du texte dans l'état d'erreur. Le nouveau test vérifie seulement que la chaîne contient « consultable », ce qui fige la promesse contestée au lieu de la prouver. Il échoue bien sur l'ancien texte, ce qui confirme la contre-épreuve du premier relecteur.

Le cahier enseignant, qui met en file, a son propre message « En attente d'envoi » (cahier_page.dart:1352-1354). Le retrait de « l'envoi attendra » ne crée donc pas de régression là. Je n'ai trouvé aucun défaut manqué ni aucun défaut infondé.

