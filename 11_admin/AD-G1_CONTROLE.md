# AD-G1 : contrôle des règles gelées DESIGN-GOV-2026-09-26 (seconde session, poste A)

Session `A-2026-09-26-service`, 26/09/2026. Méthode : 4 agents de comparaison (lecture seule, comparaison ligne à ligne au caractère près avec la spec `projet/ressources:specs/03_admin_validation_dossiers/03_ADMIN_VALIDATION_DOSSIERS_V1_2.md`), puis un agent de contre-vérification adversariale par écart (32 agents, run `wf_46b277cd-b3f`). Bases : `projet/ressources` @ `1555cab`, `ui/tuteur-v1` @ `73f12c8`.

## Verdict

**Les deux copies intégrales sont conformes mot pour mot** : `memoire/DESIGN-GOV-2026-09-26.md` (ressources) et `docs/current/DESIGN-GOV-2026-09-26.md` (ui/tuteur-v1). 275 lignes comparées : §1, §4, §4 bis et la directive de progression du §0 sont identiques à l'octet près (apostrophes, tirets, accents, espaces compris).

Écarts de forme seulement, sans effet sur les règles :
- une ligne vide de la spec (l.198, entre §4.3 et §4 bis) remplacée par un séparateur `---` (copie l.100) ;
- §0 : seule la directive de progression est recopiée, comme l'annonce l'en-tête. Le titre « # 0. » et le contexte propre au lot (spec l.14-24) manquent, dont la phrase garde-fou l.24 : « Ce document ne doit pas être interprété comme une autorisation de réécrire l'authentification, le routeur, le stockage KYC, les rôles ou l'ensemble du domaine Administration. » ;
- en-tête du coordinateur (l.1-7) : ajouts de coordination (nom `UX_REVIEW_<lot>.md`, exception K-37, renvoi HU-1), sans contradiction.

**Les résumés ne sont pas identiques mot pour mot** : ils renvoient tous au texte intégral, qui seul fait foi, mais certains durcissent ou omettent une nuance. Rien n'est contredit.

| Emplacement | Écart confirmé | Risque |
|---|---|---|
| `docs/current/03_DESIGN_SYSTEM_ET_UX.md:8-11` et `lib/CLAUDE.md:18-21` (bloc identique) | §4.3 absent : « les standards UX ne peuvent pas modifier les permissions, règles KYC, états serveur… ; la règle métier prévaut » | le plus notable : un agent qui ne lit que le résumé pourrait laisser un standard UX primer sur une règle métier |
| idem, l.10 | « pas de pleine largeur sur ordinateur » sans « sans justification » (spec l.255) | durcissement |
| idem, l.11 | « aucune marche arrière » sans « uniquement parce que » ni l'exception du directeur (spec l.370, l.379) | durcissement : une correction demandée par le directeur pourrait être refusée à tort |
| idem, l.10 | « échelle 4 à 64 » au lieu de la liste discrète 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 (spec l.208) ; `lib/CLAUDE.md:30` donne bien la liste, la charte 03 non | imprécision |
| idem, l.8-10 | hiérarchie §1 sans « plan compatible en cas de divergence » ni « une proposition ne remplace jamais silencieusement une règle serveur » ; §4.2 sans « proposition contrôlée » ni « justification de toute dérogation » ; §4 bis.2 règles 2 à 6 et règle du pied sticky absentes ; mesures 288/336/24/728 et durées du contrat E seulement par renvoi | omissions de résumé |
| consigne K-38 du tableau | mêmes durcissements (pleine largeur, marche arrière sans exception) ; ajout « jusqu'à la fin du projet » ; squelettes sans la limite « chargement initial substantiel » | mineur, K-38 renvoie au texte intégral |
| `ressources:LISEZ-MOI.md:10` | marche arrière sans l'exception du directeur | mineur |
| `ressources:memoire/MEMORY.md:3` | exemple Tuteur compléments absent de l'index (présent dans le fichier) | mineur |

Le détail complet (texte de la spec, texte de la copie, preuve de chaque contre-vérification) est dans le journal du run : `C:\Users\dell\.claude\projects\C--Users-dell-AppData-Local-Programs-WindowsTerminal\0253bce4-d3f5-4f60-91a9-db7b165dee45\tasks\wlep2npti.output` (poste A).

## Suite donnée

- Le poste A **ne modifie pas** ces fichiers : ils appartiennent à la base `ui/tuteur-v1`, que seul le coordinateur écrit (K-14), et aux ressources publiées par le poste B (AD-G0). La note de la ligne demandait « si tout est identique, passer AD-G0 à vérifié » : **ce n'est pas le cas pour les résumés**, AD-G0 reste donc « fait », avec ce rapport en remarque.
- Proposition au coordinateur (poste B), à trancher par lui : ajouter au bloc résumé de `03_DESIGN_SYSTEM_ET_UX.md` et `lib/CLAUDE.md` une ligne pour la limite du §4.3 et rétablir les deux nuances (« sans justification » ; « sauf demande explicite du directeur sur un écran ou un lot précis »), idem dans K-38 et LISEZ-MOI. Une fois fait, une autre session repasse AD-G0 à « vérifié ».
- Pour le travail Admin du poste A : les agents lisent le **texte intégral** (`memoire/DESIGN-GOV-2026-09-26.md`), jamais les seuls résumés.
