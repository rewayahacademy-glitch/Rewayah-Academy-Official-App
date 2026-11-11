# Les situations de la salle : avant, pendant, après, après une coupure

Relevé en lecture seule du 11/11/2026, demandé par le directeur : « toutes les situations avant
d'entrer à la salle et pendant et après la fin du cours et après qu'on ait coupé, après qu'on ait
pris une pause. Tout. »

**Règle de ce relevé.** Chaque ligne dit ce que le code fait, avec le fichier et la ligne. Je n'ai
rien lancé : ni test, ni build, ni essai en production. « Lu » veut donc dire « lu dans le code,
pas rejoué ». Quand je n'ai pas trouvé le code qui prouve un comportement, j'écris `non vérifié`.
Aucun document n'est recopié comme preuve : les documents du pilote ne servent ici qu'à signaler
ce qui les contredit (fin du fichier).

## Ce que le relevé a trouvé de plus grave, d'abord

1. **Personne ne ferme la salle, et rien n'avertit les élèves quand l'enseignant n'est pas là ou
   part.** Aucun appel serveur ne ferme la salle ou ne retire les gens à la fin (pas de
   `deleteRoom`, seulement `removeParticipant` pour un geste ou une visite coupée). Un élève, mineur,
   peut rester dedans, micro possible, avant l'ouverture, après le départ de l'enseignant et après
   la fin ; et s'il y a d'autres élèves, l'écran n'affiche aucun mot sur l'enseignant absent
   (`salle_page.dart:3704`).
2. **Recharger la page ou planter le navigateur fait perdre l'appel sans un mot** : retour à
   l'accueil, micro fermé ; chez l'enseignant, le tableau, les traits et la page partagée en
   mémoire sont perdus (`redirection.dart:306-309`, `synchro_salle.dart:100`).
3. **Un micro refusé ou occupé n'est pas détecté avant l'entrée et l'échec est muet** : le geste
   « micro » n'a aucun rattrapage d'erreur et le signal « micro bloqué » n'est jamais alimenté
   (`salle_page.dart:1118-1119`, `livekit_session_provider.dart:700`).
4. **La pause n'est visible que de l'enseignant** (élève et tuteur : rien), elle ne touche à aucun
   micro, et elle ne repousse pas la fin prévue (`salle_page.dart:1329-1334`,
   `chrono_seance.dart:166`).
5. **Plusieurs messages disent autre chose que la vraie cause** : un tuteur coupé à la fin de son
   quota lit « Votre enseignant vous a fait sortir du cours » ; un élève non inscrit, suspendu pour
   paiement ou sorti par l'enseignant lit « La salle s'ouvre peu avant l'heure du cours »
   (`livekit_session_provider.dart:242`, `salle_page.dart:4534`).

## Légende des chemins (tous relatifs à la racine du dépôt)

| Sigle | Fichier |
| :-- | :-- |
| SP | `lib/features/salle/salle_page.dart` |
| VSA | `lib/features/salle/vue_salle.dart` |
| SYN | `lib/features/salle/synchro_salle.dart` |
| LK | `lib/core/video/livekit_session_provider.dart` |
| SV | `lib/core/video/service_video.dart` |
| PV | `lib/core/video/pre_vol.dart` |
| CS | `lib/features/salle_seance/chrono_salle.dart` |
| SPE | `lib/core/tc_classe/session_persistante.dart` |
| RED | `lib/core/router/redirection.dart` |
| BIL | `lib/core/router/billet_salle.dart` |
| CRT | `supabase/functions/create-room-token/index.ts` |
| LIVE | `supabase/functions/_shared/livekit.ts` |
| M-JETON | `supabase/migrations/20261102500000_remplacement_auto.sql` (corps de `autoriser_jeton_video`, ensuite retouché par `20261102800000_seance_ouverte_par_le_jeton.sql`, `20261105700000_a3bis_remplacement_sans_perte.sql` et `20261106500000_snt_seance_non_tenue.sql`) |
| M-MOTIF | `supabase/migrations/20261104100000_motif_refus_salle_acces_perdu.sql` (`motif_refus_salle`, retouchée ensuite par A3-bis et SNT) |
| M-CLOT | `supabase/migrations/20261018180000_ses_cloture_auto.sql` |
| M-ALERTE | `supabase/migrations/20261105700000_a3bis_remplacement_sans_perte.sql` |
| M-SNT | `supabase/migrations/20261106500000_snt_seance_non_tenue.sql` |
| M-PRES | `supabase/migrations/20261102900000_presence_minutes.sql` |

Réserve générale : les migrations sont lues dans le dépôt. Je n'ai pas vérifié lesquelles sont
installées en production, ni que les webhooks LiveKit y arrivent (la présence, l'ouverture de
séance et la paie en dépendent : `20261030120000_seance_ouverte_par_l_enseignant.sql`, en-tête).

Rôles : **Ens** = celui qui conduit la séance ; **Él** = élève ; **Tut** = tuteur qui observe ;
**Ctl** = contrôleur ; **Fam** = famille hors salle ; **Dir** = direction.

## 1. AVANT d'entrer

| N° | Situation | Qui | Ce que fait l'application aujourd'hui | Verdict | Ce qu'il faudrait |
| :-- | :-- | :-- | :-- | :-- | :-- |
| A1 | Arriver trop tôt, avant l'ouverture | Él, Ens, Tut | La carte dit « Cours dans … » (`emplacement_entree.dart:129`). Si on force l'entrée, le serveur refuse « salle pas encore ouverte » (M-JETON:471) et l'écran dit « La salle ouvrira à {heure} » (SP:4511), sans bouton Réessayer (VSA:127-133). | bien | Rien d'urgent. |
| A2 | Dans les 20 minutes avant l'heure (salle ouverte, enseignant pas là) | Él | L'entrée est permise dès l'ouverture (M-JETON:468-472). Aucune minute n'est comptée avant l'heure (`fenetre_seance.dart:78-85`). Le jeton d'un élève lui donne la voix (M-JETON:506). Aucun adulte n'est exigé dans la salle. | défaut | Garder les élèves dans une attente sans voix tant que l'enseignant n'est pas entré (constat SEC-1). |
| A3 | Permission du micro refusée | Él, Ens | Le pré-vol ne fait que lister les appareils (PV:78-95). Sur le web, sans permission, les appareils existent avec un nom vide et sont comptés comme présents (PV:82-84) : le refus n'est connu qu'à l'ouverture du micro, après l'entrée. Là, `reglerMicro` n'a aucun `try/catch` (LK:700) et ses deux appels n'en ont pas (SP:1118-1119, 1359-1361, 4377) ; le signal « micro bloqué » n'est jamais mis à vrai (aucune écriture de `microBloque:` hors démonstration ; défaut `false` dans `vue_seance.dart:562`). | défaut (lu, non rejoué) | Attraper l'échec du micro, nommer la cause (refusé, occupé, absent) et ouvrir la feuille « micro bloqué » qui existe déjà. |
| A4 | Aucun micro sur l'appareil | Él, Ens | Impasse « Aucun micro utilisable » (SP:600-603 ; `refusMateriel`) ; l'élève peut « Continuer sans micro » (SP:1859). L'enseignant ne le peut pas. | bien | Rien. |
| A5 | Micro occupé par une autre application | Él, Ens | Aucun cas propre au micro. Seule la caméra a un message « déjà utilisée » (`cameraEchecOccupee`). | absent | Voir A3 : un seul traitement d'échec du micro. |
| A6 | Caméra refusée, absente ou occupée | Él, Ens | Phrase exacte du navigateur, cause et geste à faire, bandeau qui se ferme (SP:1124-1150 ; textes `cameraEchec*`). Pas de caméra à l'entrée pour personne (LK:290-306). | bien | Rien. |
| A7 | Enseignant pas encore là, personne d'autre dans la salle | Él | « En attente de {prénom} » / « Restez sur cet écran » (SP:4056-4066). Le chrono est en attente avant T0. | bien | Rien. |
| A8 | Enseignant pas là, mais d'autres élèves sont déjà entrés | Él | `_Seul` n'apparaît que si personne d'autre n'est visible (SP:3704-3705). Avec des camarades, l'élève ne voit que eux, sans mot sur l'enseignant. | défaut | Dire « Votre enseignant n'est pas encore arrivé » dès que l'enseignant manque, quels que soient les autres. |
| A9 | Enseignant en retard de 5 minutes | Él, Fam, Ens, Dir | Él : la même phrase d'attente, sans l'heure ni la durée du retard. Fam : rien (l'avis « titulaire en retard » n'est émis qu'avec une absence déclarée, donc avec un remplaçant prêt : M-ALERTE:10-16 ; M-JETON:586-603). Ens : avertissement à T+3 (`contenu_notification.dart:157-166`). Dir : e-mail à T+3 si personne n'est dans la salle (M-ALERTE:25-33). | défaut (Él, Fam) | Une ligne « votre enseignant a N minutes de retard » dans la salle et l'accueil de la famille. |
| A10 | Enseignant en retard de 10 minutes | Él, Fam, Dir | Avec un remplaçant prêt : à T+8 absence automatique, le titulaire perd l'accès (M-JETON:447), la famille lit « Le professeur titulaire est en retard… restez dans la salle » et la direction reçoit l'avis dans l'application (M-JETON:586-603). Sans remplaçant prêt : le titulaire garde son accès, la famille ne reçoit rien de plus. L'élève en salle ne voit toujours que l'attente. | défaut sans remplaçant ; non vérifié en production | Même ligne qu'en A9, avec l'état (« un remplaçant est recherché »). |
| A11 | Enseignant en retard de 30 minutes | Él, Fam, Dir | À T+30 sans enseignant entré : séance « reportée » (statut `teacher_absent`), classe prévenue, e-mail à la direction, nouvelle date fixée ensuite par la direction (M-SNT:61-70). Un nouvel arrivant lit « Aucun enseignant n'a rejoint la salle à temps » (SP:4530). L'élève **déjà connecté** n'est ni prévenu ni sorti : la salle n'écoute aucun changement de statut (voir A12). | bien côté serveur ; défaut côté élève en salle ; non vérifié en production | Prévenir dans la salle (ligne + retour à l'accueil) quand la séance est reportée. |
| A12 | Séance annulée ou reportée avant l'heure | Él, Fam, Ens | Carte « annulée » (`emplacement_entree.dart`, état `annulee`) ; jeton refusé avec le motif « annulée » (M-MOTIF:104-105) → « Cette séance est annulée. » (SP:4515) ; avis « séance déplacée » (`contenu_notification.dart:141-145`). | bien | Rien. |
| A13 | Enseignant remplacé avant l'heure | Él, Fam, Ens | Le remplaçant entre comme enseignant effectif ; le titulaire écarté lit « Vous n'avez pas rejoint la salle à temps » ; le premier entré ferme la porte à l'autre (M-ALERTE:284-300 ; SP:4519-4529). | bien | Rien. |
| A14 | Élève pas inscrit à cette séance | Él | Le serveur refuse « non inscrit à cette seance » (M-JETON:431, 440) ; `motif_refus_salle` ne rend rien (M-MOTIF:95) ; l'écran dit « Ce cours ne vous est pas ouvert… La salle s'ouvre peu avant l'heure du cours » (SP:4534). | défaut (trompe) | Dire « Vous n'êtes pas inscrit à ce cours » ou renvoyer vers la direction. |
| A15 | Élève suspendu pour paiement | Él, Fam | Refus « acces suspendu pour paiement » (M-JETON:453), même message générique que A14. | défaut (trompe) | Un motif propre, dit à la famille. |
| A16 | Élève sorti par l'enseignant qui retente l'entrée | Él | Le refus « sorti de la seance par l'enseignant » (M-JETON:465) retombe sur le message générique de A14, alors que l'écran « Votre enseignant vous a fait sortir » existe (SP:4563). | défaut (trompe) | Rendre le motif « sorti » à l'élève qui réessaie. |
| A17 | Salle pleine | Él, Tut | Le jeton ne pose aucune limite de participants (M-JETON:376-540). Le plafond est celui de la classe en base (6 élèves). La limite du serveur de visio n'est pas lisible dans le dépôt. | non vérifié | Décider si la salle a un plafond et le tester à pleine taille. |
| A18 | Deuxième appareil du même compte | Él, Ens | Le serveur de visio ferme la première salle ; l'écran dit « La salle est ouverte sur un autre onglet ou appareil » avec Réessayer pour reprendre ici (LK:245 ; SP:429). | bien | Rien. |
| A19 | Lien d'entrée périmé, ou page rouverte plus tard | Tous | Le billet vaut 20 minutes (BIL:52) et ne survit pas au rechargement (BIL:8-12). Sans billet valable, redirection silencieuse vers l'accueil du rôle (RED:306-309). | défaut (gêne) | Un mot sur l'accueil : « Pour rejoindre le cours, touchez Rejoindre. » |
| A20 | Pas de réseau avant d'entrer | Él, Ens | Préparation « hors ligne » (`preparation_eleve.dart:47-48, 359-361` ; `preparation_enseignant.dart:263`). Sans préparation (tuteur, contrôleur) : « La salle n'a pas pu s'ouvrir… Réessayer » (SP:4545). | bien | Rien. |
| A21 | Tuteur qui fait entrer son enfant depuis son appareil | Tut, Él | Le tuteur demande le jeton de l'enfant, la base vérifie le foyer et l'inscription (CRT:60-77). | bien | Rien. |
| A22 | Tuteur observateur dont le quota est déjà atteint | Tut | Le serveur refuse « quota d'observation atteint » avant le jeton (M-JETON:482) ; le motif exact n'est pas dans la liste des motifs renvoyés (`motif_salle.ts:14-17`) : message générique. | non vérifié (l'écran exact) | Un motif « quota atteint ». |
| A23 | Compte échu ou invalide | Tous | Refus « compte non valide » (M-JETON:394-410), message générique. Toute panne de base côté jeton donne aussi un 403 générique (CRT:85-89, 113). | défaut (trompe, léger) | Distinguer panne et refus. |
| A24 | Préparation de l'enseignant | Ens | Contexte de séance, document prévu, reprise à la page enregistrée côté serveur, élèves attendus (textes `preparation.*` ; `salle_page.dart:1741-1760`). | bien | Rien. |

## 2. PENDANT la séance

| N° | Situation | Qui | Ce que fait l'application aujourd'hui | Verdict | Ce qu'il faudrait |
| :-- | :-- | :-- | :-- | :-- | :-- |
| P1 | Un élève entre en retard | Él, Ens | Entrée permise jusqu'à fin + 15 minutes (M-JETON:474). Le poste de l'enseignant rejoue à l'arrivant la page, le tableau, la parole et les traits (SYN:183-209). Présence au prorata des minutes (M-PRES, en-tête). | bien (si le poste de l'enseignant est connecté) | Rien. |
| P2 | Un élève sort puis revient | Él, Ens | Sortie annoncée avant la déconnexion, donc distincte d'une perte (SP:514-522, 877 ; SV:232-245). « Revenir » repasse par pré-vol et jeton (SP:1951-1955). Les intervalles de présence sont fusionnés (M-PRES). | bien | Rien. |
| P3 | L'enseignant fait sortir un élève | Ens, Él | Confirmation (SP:922) ; retrait réel côté serveur (LIVE:188) ; l'élève lit « Votre enseignant vous a fait sortir du cours » (SP:4563) ; l'enseignant le réadmet (SP:949-960). | bien | Voir A16. |
| P4 | Micro coupé par l'enseignant | Ens, Él | Le serveur coupe la piste (LIVE:207). Aucun texte du bloc `salle` ne dit à l'élève qu'il a été coupé ; seule l'icône change. Rien n'empêche l'élève de le rouvrir (constat SEC-3). | défaut (trompe) | Une ligne « Votre enseignant a coupé votre micro », et un blocage réel si voulu. |
| P5 | Caméra coupée par l'enseignant | Ens, Él | Même mécanisme (LIVE:207) et même silence. | défaut (trompe) | Idem P4. |
| P6 | « Faire réciter » | Ens, Él | Envoie seulement l'étiquette « X récite » à la classe (SP:966-977 ; SYN:259-295). Aucun micro ouvert ou coupé, l'élève choisi n'est pas prévenu. La parole n'est retirée que par « Arrêter » ou « Faire sortir » (SP:938-943), pas quand le récitant se déconnecte. | défaut (G-2) | Prévenir l'élève, ouvrir son micro, retirer la parole s'il part. |
| P7 | « Faire sonner » (Appeler discrètement) | Ens, Él | Paquet adressé au seul élève (SYN:316-330), délai de 45 s (`rappel_discret.dart:81`), affichage 5 s (`app_mouvement.dart:150`), son possiblement muet dans le navigateur (`signal_rappel_web.dart:46-54`). Aucun accusé de réception ne revient à l'enseignant (SYN:299). | défaut (G-1) | Retour visible à l'enseignant et rappel qui reste tant que l'élève n'a pas réagi. |
| P8 | Main levée | Él, Ens | Absent : aucune fonction. Seul un texte de démonstration en parle (`seance_demo.dart:321`). « Signaler un besoin » (`panneau_eleves.dart:678`) est un signalement de l'enseignant sur un élève, pas une demande de l'élève. | absent | Décider si la main levée existe ; sinon retirer l'idée des documents. |
| P9 | Page partagée | Ens, Él, Tut | Paquet fiable (LK:515-527), le plus récent gagne (LK:464-467), republié après reconnexion (LK:348, 497-503). | bien | Voir S-2, S-5 du constat. |
| P10 | Pointeur | Ens, Él | Non relu par ce relevé. | non vérifié (constat P-1) | — |
| P11 | Tableau ouvert, fermé, traits | Ens, Él | Ouverture diffusée et rejouée (SYN:207-240). Les traits sont gardés en mémoire seulement (SYN:100) ; un message « notes non sauvegardées » existe (`seance.synchro.nonSauvegardees`). | bien (diffusion) ; défaut si rechargement (voir C2) | Garder les traits côté serveur ou le dire clairement. |
| P12 | Pause : qui la déclenche | Ens | Seul l'enseignant, si le serveur lui donne `peut_piloter` (SP:1367-1370, 1692-1715 ; adaptateur branché en production : `main.dart:669-670`). La pause programmée ne démarre pas toute seule : elle ne s'affiche que si l'enseignant la lance. | bien | Rien. |
| P13 | Pause : ce que voit l'élève et le tuteur | Él, Tut | Rien. L'état de la pause n'est lu que pour l'enseignant (`enseignant ? … : null`, SP:1329-1334). | défaut (trompe) | Montrer « Pause, reprise à 18:30 » à toute la classe. |
| P14 | Pause : que deviennent les micros | Tous | Aucun code ne touche aux micros ni aux caméras pendant la pause (SP:1692-1715 n'appelle que le port de pause). Tout le monde reste ouvert. | absent | Décider : micros coupés pendant la pause, ou non. |
| P15 | Pause : que devient le chrono | Ens | Le temps écoulé se fige, mais le temps restant et la fin prévue continuent : la pause ne repousse pas la fin (`chrono_seance.dart:166-168`). | non tranché | Décision du directeur : la fin recule-t-elle ? |
| P16 | Pause : reprise et pause non prise | Ens | La reprise « à HH:MM » est une information : rien ne la termine à l'heure. L'état n'est relu qu'après un geste (SP:1714), pas par minuterie : un second appareil de l'enseignant ne la voit pas. | défaut | Relire l'état régulièrement et signaler la reprise. |
| P17 | Réseau faible chez l'élève | Él, Ens | Repli : la caméra est coupée d'office, les vidéos reçues baissent, la voix reste (LK:560-600 ; texte `videoSuspendue`). | bien (voix d'abord) ; défauts C6-4, C6-10, V-3 du constat | Voir le constat. |
| P18 | Réseau faible ou coupé chez l'enseignant, vu par l'élève | Él | Le SDK tente de se reconnecter (LK:333-349). Si l'enseignant disparaît, l'élève ne voit aucun message sur l'enseignant (voir A8). | défaut | Message « Votre enseignant a perdu la connexion ». |
| P19 | Connexion interrompue puis rétablie | Tous | États « Connexion interrompue. Reconnexion en cours… » puis « Connexion rétablie » (LK:333-346 ; textes `secours.*`) ; l'enseignant republie la page (LK:348). | bien | Rien. |
| P20 | Écran éteint ou onglet en arrière-plan | Tous | Le chrono se recalcule au retour (CS:212-217). Le contrôleur de session note la suspension et ne coupe rien (SPE:415-440). Dans `/salle`, rien ne s'affiche au retour (`retourDeSuspension` n'est lu que par `barre_seance_en_direct.dart:212`). Ce que le navigateur fait du micro et de la caméra : aucun code. | non vérifié | Essai réel sur téléphone. |
| P21 | Appel téléphonique entrant | Él, Ens | Aucun code propre (ni interruption audio, ni piste terminée : recherche faite dans `lib/core/video/`). | absent / non vérifié | Essai réel ; dire « Votre micro a été coupé par le téléphone ». |
| P22 | Salle réduite (la séance continue hors de l'écran) | Él, Ens | L'appel est confié au contrôleur de session et continue ; une barre « Séance toujours en direct » le montre (SP:484-512 ; `barre_seance_en_direct.dart`). | bien (dans l'application ; pas après rechargement) | Rien. |
| P23 | Visite de contrôle | Ctl, Él, Ens | Le jeton du contrôleur est masqué et muet (M-JETON:505). La mention fixe « Visite de contrôle possible » est rendue dès que la salle est ouverte (`depuis_salle.dart:110`, `vue_seance.dart:1085-1088`). L'état « Contrôle actif » n'est jamais alimenté par une donnée réelle (`EtatControle` n'est renseigné que dans la démonstration). | bien (invisibilité) ; absent (« actif ») | Dire clairement si « actif » existe ; sinon l'ôter des textes. |
| P24 | Tuteur qui observe | Tut, Él | Jeton masqué, rien ne se publie (M-JETON:505-506). L'enfant lit « Ton parent observe la séance » (`depuis_salle.dart:77-88`). | bien | Rien. |
| P25 | Tuteur coupé à la fin de son quota | Tut | Le serveur le retire (`observation-coupure/index.ts`). Le client lit « participant retiré » comme « l'enseignant vous a fait sortir » (LK:242 → SP:437, 4563) : le tuteur lit « Votre enseignant vous a fait sortir du cours ». | défaut (trompe ; lu, non rejoué) | Un motif propre « Votre temps d'observation est terminé ». |
| P26 | Les cinq dernières minutes | Ens, Él | Le chrono passe en « bientôt » à 5 minutes (`chrono_vivant.dart:60`). Deux notes douces pour qui conduit la séance seulement (`chrome_seance.dart:362, 431` ; CS:174) ; pour l'élève, un changement de teinte. | bien | Rien. |
| P27 | Fin prévue atteinte | Tous | Le chrono passe au dépassement ; note sonore pour l'enseignant. Rien d'autre : pas de message à la classe, rien ne se ferme. | bien (affichage) | Voir F2. |
| P28 | Dépassement | Tous | Le chrono compte « +mm:ss » (`chrono_vivant.dart:117`) jusqu'au dépassement permis, réglage du serveur (`bornes_salle.dart:75-79` ; 15 minutes par défaut). | bien | Rien. |
| P29 | Fin du dépassement | Tous | Le chrono s'arrête sur « Temps prévu écoulé » (`chrono_seance.dart:156-163`). Les entrées neuves sont refusées (M-JETON:474), mais ceux qui sont dedans restent connectés. | défaut (SEC-1) | Voir F2. |
| P30 | Document partagé qui ne s'affiche pas | Ens, Él | « Le document ne s'affiche pas… la séance et le son continuent » + Réessayer (`seance.surface.supportIndisponible*`). | bien | Rien. |
| P31 | Le tuteur change la politique de caméra de l'enfant en séance | Él | Toutes les 30 s l'élève relit la politique (`politique_camera.dart:46`) ; si elle change, il ferme et rouvre la salle avec un nouveau jeton et rouvre son micro (SP:744-800). Effet pour l'élève (coupure brève, présence) : aucun essai. | non vérifié | Essayer, et prévenir l'élève. |

## 3. APRÈS la fin du cours

| N° | Situation | Qui | Ce que fait l'application aujourd'hui | Verdict | Ce qu'il faudrait |
| :-- | :-- | :-- | :-- | :-- | :-- |
| F1 | L'enseignant quitte (bouton Quitter) | Ens, Él | Confirmation (SP:838-846), sortie annoncée avant la déconnexion (SP:514-522, 877), puis écran de fin et cahier (SP:862-887). La séance n'est pas close (`close: false`, SP:865). Les élèves restent dans la salle, sans message : ils voient les autres, ou l'attente « votre professeur n'est pas encore arrivé » (SP:3704, 4056). | défaut | Dire aux élèves que l'enseignant est parti et les renvoyer à l'accueil. |
| F2 | La salle se ferme-t-elle ? | Tous | Non. Aucun appel serveur ne ferme la salle ; le jeton est refusé après fin + 15 minutes (M-JETON:474) ; le statut passe à « terminée » par la tâche planifiée à fin + 30 minutes (M-CLOT:34, 64-100). Aucun bouton « Terminer pour tous ». | défaut (SEC-1) | Une fermeture serveur à la fin du dépassement, qui sort les derniers et le dit. |
| F3 | L'élève quitte avant la fin | Él | Confirmation, puis « Vous avez quitté la séance. Vous pourrez revenir tant qu'elle reste ouverte », avec « Revenir » (SP:895, 1912-1960 ; textes `fin.quitte*`). La sortie est inscrite comme volontaire. | bien | Rien. |
| F4 | Qui ferme la séance, quand, comment | Dir | La tâche planifiée seule : séance avec enseignant entré → `ended` ; sans arrivée → `teacher_absent` ; ouverte sans arrivée → jamais `tech_failure` (M-CLOT:84-100 ; `20261102800000_seance_ouverte_par_le_jeton.sql`, §2). Séance ouverte à problème technique : la direction fixe la durée. | bien (serveur) ; non vérifié en production | Rien. |
| F5 | Cahier de transmission | Ens | Après Quitter : écran de fin puis `_ouvrirCahier` (SP:1059-1075) ; si la route manque, « Réessayer » (textes `fin.enseignant.erreurCahier`). Hors salle, le bouton de la carte devient « Remplir le cahier » ou « Voir le cahier » (`cta_seance.dart:100-120`). | bien | Rien. |
| F6 | Écran d'arrivée après la sortie | Él | « Séance terminée » ou « Vous avez quitté » + carte de retour éclair (SP:1912-1960) ; version Mode Accessibilité (SP:1916-1938). | bien | Rien. |
| F7 | Revenir dans une séance finie | Él, Ens | Refus avec le motif « terminée » : « La séance s'est terminée à {heure}. La salle a fermé peu après. » (M-MOTIF:106-109 ; SP:4507). | bien | Rien. |
| F8 | Présence et absences enregistrées | Dir, Fam, Ens | Entrées et sorties viennent des webhooks LiveKit et de l'annonce de sortie (`livekit-webhook/index.ts:93-104`) ; présent à 50 % de la durée, partiel en dessous, absent sans connexion (M-PRES, en-tête). | bien dans le code ; non vérifié en production | Vérifier que les webhooks arrivent (`livekit_webhook_deliveries`). |
| F9 | Séance non tenue | Fam, Dir, Ens | Statut `teacher_absent`, jamais payée à l'enseignant, famille et direction prévenues, nouvelle date fixée par la direction (M-SNT:61-95) ; la famille lit le statut (`seance_famille.dart:174`). | bien côté serveur | Voir A11 pour l'élève en salle. |
| F10 | Le contrôleur quitte | Ctl | Sans confirmation, direction le compte rendu (SP:905-917). | bien | Rien. |
| F11 | Les élèves encore dedans après le départ de l'enseignant | Él | Ils restent, micro possible, sans adulte, jusqu'à ce qu'ils partent (même cause que F2). | défaut (SEC-1) | Voir F2. |

## 4. APRÈS UNE COUPURE

| N° | Situation | Qui | Ce que fait l'application aujourd'hui | Verdict | Ce qu'il faudrait |
| :-- | :-- | :-- | :-- | :-- | :-- |
| C1 | Rechargement de la page, côté élève | Él | Le billet vit dans la mémoire du routeur et se perd (BIL:8-12) : retour silencieux à l'accueil (RED:306-309). L'appel confié au contrôleur de session est en mémoire aussi (SPE:158-175). L'élève retrouve la séance par « Rejoindre » sur l'accueil si la fenêtre est ouverte ; micro fermé, caméra fermée (LK:290-306) ; la page revient par le rejeu de l'enseignant s'il est là (SYN:183-209) ; le chrono se recalcule sur les heures du serveur (CS:212-217). | défaut | Revenir directement dans la salle avec le même message de reconnexion. |
| C2 | Rechargement, côté enseignant | Ens | Sa page présentée est perdue (LK:845 vide `_dernierContenu`) ; la classe garde l'ancienne page ; il doit « Reprendre page N », lue côté serveur (SP:1741-1760), sans présentation automatique ; les traits et le tableau (en mémoire : SYN:100) sont perdus ; la parole aussi. | défaut | Reprendre la séance telle qu'elle était (page, tableau, parole). |
| C3 | Plantage du navigateur | Tous | Même chose que C1/C2 ; côté présence, la sortie est lue comme une déconnexion, ce qui est exact (SV:160-167, 232-245). | bien (présence) ; défaut (reprise) | Voir C1. |
| C4 | Perte de réseau longue (le SDK abandonne) | Tous | La salle passe en échec : « La connexion au cours est perdue » avec Réessayer (SP:430-434, 4561). Réessayer repasse par pré-vol et nouveau jeton ; micro et caméra reviennent fermés (SP:549-611). Si la fin prévue est passée, le serveur est interrogé et dit « séance terminée » (SP:661-735). | défaut (pas de reprise automatique après l'abandon du SDK) | Tenter une reprise automatique avec le même état de micro. |
| C5 | Retour après fermeture de l'onglet | Tous | Comme C1 ; si la salle est fermée (fin + 15 min), le message dit l'heure de fin (SP:4507). | bien (message) | Rien. |
| C6 | Retrouve-t-on la page partagée ? | Él | Pendant une simple reconnexion du SDK, le récepteur garde la page (LK:338-348). Après une nouvelle entrée, la page ne revient que si le poste de l'enseignant est connecté et rejoue (SYN:183-209) ; sinon « n'a rien partagé » (textes `rienPartage`). | bien (si l'enseignant est là) | Rien. |
| C7 | Retrouve-t-on le micro ? | Él, Ens | Non après une nouvelle entrée : rien ne s'ouvre sans geste (LK:290-306). Après une simple reconnexion du SDK : état de la piste locale non vérifié. | défaut (nouvelle entrée) ; non vérifié (reconnexion) | Dire « touchez le micro pour reprendre ». |
| C8 | Retrouve-t-on le chrono ? | Tous | Oui, recalculé sur les heures du serveur (CS:212-217). Sans lecture des bornes, aucun chrono (`bornes_salle.dart`, « null → pas de chrono »). | bien | Rien. |
| C9 | Retrouve-t-on la pause ? | Ens | Relue au serveur pour l'enseignant (SP:1329-1334). Pour l'élève : jamais affichée (P13). | bien (Ens) ; absent (Él) | Voir P13. |
| C10 | Une longue séance : le jeton de connexion expire-t-il avant une reconnexion ? | Tous | Le jeton ne dure que le temps réglé (`token_ttl_seconds`, 300 s sans réglage : M-JETON:492) ; si le SDK refait une connexion complète avec le même jeton après ce délai, rien dans le dépôt n'indique qu'il en reçoit un neuf. | non vérifié | Essai de coupure longue au banc `tool/salle/`. |
| C11 | Retour de l'application après suspension (mobile) | Tous | La barre « en direct » dit un doute au retour (`barre_seance_en_direct.dart:212`) ; dans `/salle`, rien. | non vérifié | Essai réel. |
| C12 | L'enseignant se déconnecte et les élèves restent | Él | Voir F1 : aucun message aux élèves. Sa présence est lue comme « connexion interrompue » dans son panneau (20 s, `service_presence.dart:326`). | défaut | Voir F1. |

## 5. Défauts et absences, du plus grave au moins grave

Gravité : **A** = empêche le cours ; **B** = trompe la personne ; **C** = gêne.

| Rang | Grav. | Défaut ou absence | Situations | Dans le constat ? |
| :-- | :-- | :-- | :-- | :-- |
| 1 | A | Aucune fermeture de salle ; mineurs sans enseignant, micro possible, avant l'ouverture, après le départ, après la fin | A2, P29, F1, F2, F11 | **SEC-1** (la partie « jamais fermée » est confirmée par ce relevé) |
| 2 | A | L'élève ne sait pas que l'enseignant est absent ou parti quand d'autres élèves sont là, ni quand il quitte | A8, P18, F1, C12 | **Nouveau** (le point 30 de `MESSAGES-DE-LA-SALLE.md` l'annonce « à relier ») |
| 3 | A | Micro refusé, occupé : non détecté avant l'entrée, échec muet, « micro bloqué » jamais alimenté | A3, A5 | **Nouveau** |
| 4 | A | Rechargement ou plantage : appel perdu sans mot ; enseignant : page, tableau, traits, parole perdus | C1, C2, C3 | **C-1** couvre seulement la connexion perdue ; le rechargement est **nouveau** |
| 5 | A | Après l'abandon du SDK, aucune reprise automatique ; micro et caméra reviennent fermés | C4, C7 | **C-1** (à nuancer : voir fin du fichier) |
| 6 | A | Voix : pertes en rafales, pas de mesure montrée | P17 | **V-3, V-2** |
| 7 | B | Le tuteur coupé à la fin de son quota lit « Votre enseignant vous a fait sortir du cours » | P25 | **Nouveau** |
| 8 | B | Refus d'entrée qui disent « la salle s'ouvre peu avant l'heure » pour des causes autres (non inscrit, paiement, sorti, compte, panne) | A14, A15, A16, A22, A23 | **Nouveau** |
| 9 | B | Pause invisible pour la classe, sans effet sur les micros, ne repousse pas la fin, reprise non automatique | P13, P14, P15, P16, C9 | **Nouveau** (contredit `MESSAGES-DE-LA-SALLE.md`, n° 16) |
| 10 | B | Retard de l'enseignant : l'élève et la famille ne voient ni durée ni état à 5 et 10 minutes (sans remplaçant, rien) ; à T+30, l'élève déjà en salle n'est pas prévenu | A9, A10, A11 | **Nouveau** (le point 30 de `MESSAGES-DE-LA-SALLE.md` le dit « à relier ») |
| 11 | B | « Faire réciter » ne fait qu'une étiquette | P6 | **G-2** |
| 12 | B | « Faire sonner » invisible ou muet, sans retour à l'enseignant | P7 | **G-1** |
| 13 | B | Micro ou caméra coupé par l'enseignant : l'élève n'est pas prévenu et peut rouvrir | P4, P5 | **SEC-3** (le blocage) ; le silence est **nouveau** |
| 14 | B | « Contrôle actif » promis par les textes mais jamais alimenté ; la mention fixe se dit « possible » | P23 | **Nouveau** |
| 15 | C | Pas de main levée | P8 | **Nouveau** |
| 16 | C | La parole « X récite » reste si le récitant se déconnecte | P6 | **Nouveau** |
| 17 | C | Changement de politique de caméra : l'élève ferme et rouvre la salle toutes les 30 s au plus | P31 | **Nouveau** (non rejoué) |
| 18 | C | Billet périmé : retour silencieux à l'accueil | A19 | **Nouveau** |
| 19 | C | Arrière-plan, appel téléphonique, suspension : aucun code ni message dans `/salle` | P20, P21, C11 | **Nouveau** (à essayer sur appareil) |
| 20 | C | Jeton de connexion : tenue d'une reconnexion longue non vérifiée | C10 | **Nouveau** (à mesurer au banc) |
| 21 | C | Pas de plafond de participants posé par l'application | A17 | **Nouveau** (lié à la décision sur la taille des classes, constat §2 bis) |

## 6. Ce que ce relevé contredit ou nuance dans les documents du pilote

- **`CONSTAT.md`, C-1** (« aucune reprise automatique ») : exact seulement après l'abandon du SDK.
  Avant, le SDK se reconnecte tout seul, l'écran le dit, et l'enseignant republie la page
  (`livekit_session_provider.dart:333-349`).
- **`CONSTAT.md`, SEC-1** : confirmé par le code. Précision : la salle n'est fermée par aucun
  appel serveur ; le statut « terminée » vient de la tâche planifiée à fin + 30 minutes
  (`20261018180000_ses_cloture_auto.sql:34, 64-100`).
- **`MESSAGES-DE-LA-SALLE.md`, n° 16** (« Pause, reprise à 18:30 », destinataires « Tous ») :
  aujourd'hui seul l'enseignant la lit (`salle_page.dart:1329-1334`).
- **`MESSAGES-DE-LA-SALLE.md`, n° 30** (« Votre enseignant est en retard », à relier) : confirmé
  absent ; l'élève ne lit que l'attente (`salle_page.dart:4056-4066`).
- **Commentaires périmés dans le code**, à corriger sans urgence : `billet_salle.dart:14-17` dit
  « T-10 min à T+fin+10 min » (le serveur applique 20 et 15 minutes) ; l'en-tête de
  `port_pause_seance.dart` dit « frontend seul, la production rend `CapaciteIndisponible` » alors
  que `main.dart:669-670` branche l'adaptateur Supabase.
- **Valeurs écrites en dur côté client** : `seuilOuvertureSalle` (20 minutes, `pre_vol.dart:29`) et
  `graceApresFin` (15 minutes, `service_controle.dart:22`) existent comme repli, alors que le
  serveur les règle (`app_config`). Le chrono reçoit le dépassement du serveur
  (`bornes_salle.dart:75-79`) ; la fenêtre d'ouverture, elle, reste la valeur écrite.
