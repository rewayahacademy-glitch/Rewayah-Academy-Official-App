# UX_REVIEW_OFFRES-FAM-1 : suivi des demandes de créneau, côté famille

Date : 09/10/2026. Lot : OFFRES-FAM-1 (décision du directeur du 09/10/2026,
`DECISION-OFFRES-GROUPES-2026-10-09.md`, §2 et §4). Écran `/tuteur/demandes`
(`lib/features/suivi_demandes/`), carte d'entrée sur l'accueil famille, port
`lib/core/offres/port_suivi_demandes.dart`, adaptateur de démonstration
`lib/features/demo/suivi_demandes_demo.dart`.

## Demande du directeur (source des libellés)

- La famille est tenue au courant à chaque étape : notification **et** suivi
  visible dans son espace (§4).
- Étapes et phrases, mot pour mot : « Votre demande est arrivée à l'administration »
  (prochaine étape : constitution de la classe) ; « Votre classe a été validée »
  (prochaine étape : affectation de l'enseignant) ; « Classe validée · enseignant affecté »
  (début des cours : date et heure locale) ; refus ou retrait : le motif en clair et ce
  qu'elle peut faire ensuite.
- Créneau personnalisé : une notice dit qu'il ne s'ouvrira que si d'autres élèves le
  choisissent et remplissent la classe (§2).
- La famille ne voit jamais qui d'autre a demandé le même créneau ni combien de personnes
  l'ont demandé (§4). Aucun nom d'enseignant dans la vitrine (§2) ; dans le suivi, le nom
  n'apparaît qu'à l'étape 3 (consigne du lot).

## Libellés ajoutés (`suiviDemandes`)

Mot pour mot de la décision : les trois phrases de situation, les deux « Prochaine étape »
et la notice. Délégation du 02/10 (« le reste tu te débrouilles pour le bien de
l'académie ») pour les autres, rédigés par l'agent, à faire valider par le directeur :

- Titre : « Suivi des demandes de créneau »
- Contexte (K-58) : « Chaque demande avance en trois étapes. Vous êtes prévenu à chaque passage. »
- Titre de carte (qui et quoi) : « Demande de créneau {dePrenom} » (« Demande de créneau de Yusuf », « Demande de créneau d'Aïcha »)
- Rappel : « Jours choisis », « Heure choisie », « {debut} et {dernier} » (« Lundi, mardi et jeudi »), « {heure}, heure {deVille} » (« 18:00, heure de Paris »)
- Frise : « Demande envoyée », « Classe validée », « Enseignant affecté » ; états « Fait », « Prochaine étape », « À venir »
- Situation : « Votre demande est arrivée à l'administration », « Votre classe a été validée », « Classe validée · enseignant affecté »
- Prochaine étape : « Prochaine étape : constitution de la classe », « Prochaine étape : affectation de l'enseignant »
- Étape 3 : « Début des cours », « {date} à {heure}, heure {deVille} » (« Lundi 19 octobre à 17:30, heure de Paris »), « La date du premier cours s'affichera ici dès qu'elle sera fixée. », « Enseignant »
- Notice : « Ce créneau ne s'ouvrira que si d'autres élèves le choisissent et remplissent la classe. »
- Pastilles d'une demande close : « Demande retirée », « Demande non retenue »
- Motifs en clair : « Vous avez retiré cette demande. », « L'académie a retiré ce créneau de ses offres. », « La classe de ce créneau n'a pas pu être constituée. », « La direction n'a pas pu retenir cette demande. »
- Suite : « Vous pouvez choisir un autre créneau parmi ceux proposés. » ; sans capacité de rechoisir : « Aucun autre créneau n'est proposé pour le moment. Revenez sur cette page plus tard. »
- Lien : « Choisir un autre créneau pour {prenom} »
- Vide : « Aucune demande de créneau en cours. »
- Échec serveur (K-59) : « Le suivi des demandes n'a pas pu être chargé : le serveur n'a pas répondu. Réessayez dans un instant. »
- Hors ligne sans données (EA-HL-DOUBLE-1, dit ce qui manque) : « Le suivi des demandes n'a pas pu être chargé »
- Accueil : « Vos demandes de créneau », « {prenom} : {etat} », « Voir le suivi des demandes »
- Notifications : « Demande de créneau {dePrenom} : votre demande est arrivée à l'administration », « Demande de créneau {dePrenom} : votre classe a été validée », « Demande de créneau {dePrenom} : classe validée · enseignant affecté », « Demande de créneau {dePrenom} : {motif} »

## Contrôle UX

| Proposition | Règle et source | Conclusion | Conséquence dans l'écran |
| :--- | :--- | :--- | :--- |
| Une carte par élève concerné, détachées | K-55 (`PileCartes`) ; Gestalt, proximité | conforme | `PileCartes` (16) ; demandes en cours d'abord, closes ensuite |
| Frise d'étapes | WCAG 2.2 SC 1.4.1 (jamais la couleur seule) ; Nielsen n° 1, visibilité de l'état | ajustée | Trois signaux par étape : icône (coche pleine, horloge, sablier), mot (« Fait », « Prochaine étape », « À venir »), encre ; une ligne lue d'un tenant (`MergeSemantics`) |
| Phrase de situation, puis prochaine étape | Nielsen n° 1 ; décision §4 | conforme | La phrase du directeur en `bodyLarge` fort, la prochaine étape juste sous la frise |
| Heures dans le fuseau de la famille | 03 « locales et fuseaux » ; règle métier (le serveur rend l'heure murale du foyer) | conforme | Aucune conversion par l'appareil ; la ville du fuseau est dite (« heure de Paris », « heure de New York ») |
| Aucun nombre ni identité d'autres demandeurs, aucun enseignant avant l'étape 3 | Décision §4 ; DESIGN-GOV §4.3 (la visibilité des données ne bouge pas) | conforme | Le contrat n'a aucun champ pour eux ; le modèle efface l'enseignant avant l'étape 3 ; test dédié |
| Refus ou retrait | K-59 (ce qui s'est passé, quoi faire) ; Nielsen n° 9 | conforme | Pastille à mot + motif en clair + suite ; le lien n'existe que si le serveur rend la capacité, sinon une phrase (jamais grisé) |
| Aucun bouton plein | K-56 ; DESIGN-GOV §4 bis.2 règle 4 | conforme | Écran de lecture : aucune `ActionPrincipale` ; l'action rare est un `LienFleche` au bord de fin de sa carte (16 sous le contenu) |
| États | 03 §États ; DESIGN-GOV §4 bis.6 | conforme | `Skeleton.liste` dans `BlocAsynchrone`, contenu, `EmptyState` (registre subi), `EtatSysteme` avec « Réessayer », hors ligne par le bandeau de `PageShell` seul (bloc `EtatSansDonnees` seulement sans données) |
| Carte d'entrée de l'accueil | lib/CLAUDE.md (« brancher l'entrée, pas seulement la route ») | conforme | Silencieuse sans port, pendant la lecture et sans demande ; en échec, dit ce qui manque et garde le lien |
| 320 px, texte ×2, RTL | WCAG 2.2 SC 1.4.4 et 1.4.10 ; COUPE-MOTS-1 | conforme | Titres en `TexteSansCoupure`, `LigneCleValeur` empilée à 200 %, pastille sous le titre quand la ligne manque (`OverflowBar`) ; tests LTR et RTL |
| Capacité, pas rôle | invariant `CLAUDE.md` | conforme | La carte et l'écran ne lisent que le port et `peutChoisirAutreCreneau` |

## Besoin serveur (ligne Backend proposée)

Port `lib/core/offres/port_suivi_demandes.dart` : flux des demandes de créneau du foyer
connecté (une par élève concerné), avec l'étape (`envoyee`, `classe_validee`,
`enseignant_affecte`, `close`), le motif fermé de clôture (`retrait_famille`,
`offre_retiree`, `classe_non_constituee`, `refus_direction`), les jours ISO et l'heure
**en heure murale du fuseau du foyer**, le fuseau IANA du foyer, le drapeau
`personnalise`, la capacité `peut_choisir_autre_creneau`, et, à l'étape 3 seulement, le
nom d'affichage de l'enseignant et le début des cours (heure murale du foyer). Jamais de
nombre de demandeurs, d'identité d'autrui ni d'enseignant proposé non confirmé. RLS : le
foyer ne lit que ses demandes. Notification à chaque transition, titre et destination
`/tuteur/demandes` (le port des notifications existant suffit, sans modification).
