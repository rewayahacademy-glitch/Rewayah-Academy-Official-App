# À faire maintenant : la seule liste (directeur, 27/11/2026)

Ordre du directeur du 27/11/2026 : garder seulement ce qu'il a demandé ces dix derniers jours (17 au 27/11) et qui
**n'est pas fait**, ou qui est **fait mais ne marche pas**, avec un plan, « quelque part où personne ne les oublie ».
Il constate que les endroits précédents « n'ont pas marché ».

**Règles de cette liste (directeur, 27/11/2026) :**
1. Tout agent la lit **avant toute autre chose**, avant le plan de la Boucle 1 et avant la table de `CLAUDE.md`.
2. On n'en sort une ligne qu'avec la preuve : numéro de PR fusionnée **et** « prouvé par le directeur le JJ/MM ».
   Sans la preuve du directeur, la ligne reste, marquée « livré, à prouver ».
3. Une nouvelle demande du directeur entre ici le jour même, pas dans un nouveau fichier.
4. Une ligne qui dort plus de sept jours est dite au directeur en première phrase.
5. Le détail vit dans les fichiers cités ; ici, une ligne par chose.

Relevé fait le 27/11/2026 sur `main` `6f6f1339`, en relisant les sessions du 17 au 27/11 et la base de production. Ce
qui précède le 17/11 est dans `INVENTAIRE-NON-PRODUCTION-2026-11-27.md`.

## 1. Fait, mais ne marche pas

| # | Quoi | Ce qui ne marche pas | Qui débloque |
|---|---|---|---|
| M1 | Arrêt de Praxis (« il faut arrêter praxis, il répond à tout et à n'importe quoi », 21/11 23 h 26) | Seule la tâche horaire est coupée. En base, le 27/11 : `actif = true`, `autonome = true`. Praxis se tait seulement parce que sa clé a expiré le 24/11 ; une nouvelle clé le relancerait aussitôt | Le directeur coupe dans « Accès des agents IA », ou dit « vas-y » pour une migration d'une ligne |
| M2 | Praxis visible sur ses bulles, photo et « #Ra_Praxis » (17/11 ; #634, #635) | Dernier mot du directeur après #634 : « ça n'a pas marché ». #635 fusionnée une minute avant la panne de jetons de la session ; personne n'a revérifié | Un agent vérifie en production (pas sur des tests), puis le directeur |
| M3 | Page « Personnes » (bureau du directeur) | Livrée, puis rejetée le 21/11 : « j'ai tout détesté ». Aperçu inutile, liste coupée à 4 ou 5 lignes sur 14 pouces, filtres en menus déroulants, pas d'accès d'un clic depuis la barre réduite. Détail : `PARCOURS-ENSEIGNANT/RESTE-A-FAIRE.md` §0 bis | Montrer des références au directeur, puis coder ; vérifier à 1280 et 1440 |
| M4 | Liste des élèves et des familles | Le 27/11 : « tellement la pagaille… on le laisse d'abord de côté » | Mise de côté par le directeur : ne pas lancer sans ordre |
| M5 | Guide de l'enseignant, en ligne depuis le 21/11 | Il promet ce que l'application ne fait pas (voir N1) | Décisions du directeur, voir N1 |
| M6 | « Enregistrer l'image » dans la messagerie | La règle CORS du seau R2_MESSAGING couvre l'envoi, pas la lecture (`GET`) | Le directeur dans Cloudflare |
| M7 | CI des PR (27/11, 14 h 57 UTC) | Tous les jobs échouaient en une seconde sans obtenir de machine : le dépôt était passé en privé le 27/11, et le quota de minutes Actions d'un compte privé s'épuise en quelques passages de cette CI. Le directeur l'a remis en public le 27/11. À vérifier : la CI suivante tourne de nouveau | Un agent regarde la CI suivante ; si le dépôt repasse en privé, prévoir un budget Actions avant |

## 2. Demandé, pas fait

| # | Quoi (date, mot du directeur) | État | Qui débloque |
|---|---|---|---|
| N1 | Contradictions guide contre application : P1 part enfant ~45 % contre 47 %, P2 absent payé à moitié, P3 montants en dollars aux candidats, L1 arabe langue de cours ; puis A2, A5, A6, P5 (21/11 : « corriger la contradiction dans l'app ») | Rien écrit ni codé. L'agent s'est arrêté : décision non confirmée, taux enfant ambigu (45 %, 24 $ fixes ou 43,6 %). Détail : `CANDIDATURES/LETTRE-CANDIDATS/REGLES-NOUVELLES.md` | Le directeur : taux enfant, et « le guide prévaut » confirmé par écrit |
| N2 | Paiement P1, la preuve : un vrai paiement de 1 $ puis son remboursement (plan validé le 23/11) | Pas fait ; « personne n'a payé dans l'application » au 27/11. Le premier paiement avant le cours reste éteint tant que P1 n'est pas prouvé | Le directeur paie 1 $ |
| N3 | Paiement P7 (une seule page « Paiements », « Payer » au lieu de « Recharger », reçu Stripe), P8 (ménage, espace du comptable), P9 (une famille test traverse tout) | Pas lancés. Détail : `PAIEMENT/STRATEGIE-PAIEMENT-2026-11-23.md` §7 | Un agent, après N2 |
| N4 | Payer la dette de famille dans l'application (23/11) | Seule la direction peut la solder aujourd'hui | Un agent |
| N5 | Audit famille du 22/11 : correctifs 5 (premier paiement dans le parcours) et 9 (capacité), liste « familles en attente d'un horaire » | Non faits | Un agent |
| N6 | Paie des enseignants sans que l'académie voie leurs coordonnées bancaires (20/11) | Verto « pas très réactif » (27/11), alternative à chercher. **Aujourd'hui les coordonnées sont stockées en clair** | Le directeur : prestataire ; un agent : la sécurité des coordonnées |
| N7 | Prospection : relance du jour 2 aux ~130 organisations écrites du 23 au 26/11 qui n'ont pas répondu | Annoncée, pas faite. Les 100 lettres courtes partent du 29/11 21 h 24 au 30/11 19 h 25 UTC ; contrôles prévus le 29/11 21 h 45 et le 30/11 21 h 30 | Un agent, après le premier contrôle |
| N8 | Bras droit de Praxis : « qu'il m'aide surtout à 100 % » (17/11) ; courriels (« il ne faut pas lui amputer les bras ») ; réveil sur événement ; mention IA discrète aux familles ; le chat du directeur relié à Praxis (#627, #632 à #638) | Rien en production. #625 à #630 gelées et en conflit, #632 en conflit. **Praxis est arrêté depuis le 21/11 (M1) : on ne relance rien sans ordre** | Le directeur : relancer Praxis ou non |
| N9 | Restes des maquettes validées (19-20/11) : écran de chargement et de mise à jour avec Praxis, tableau de bord, icônes, mouvement, en-tête, « Plus », interface de l'enseignant | Pas faits. Le plan du parcours de l'enseignant (19/11) n'est pas validé. Détail : `PARCOURS-ENSEIGNANT/RESTE-A-FAIRE.md` §1-2 | Le directeur valide le plan |
| N10 | Guide : Praxis qui répond aux commentaires depuis le texte validé, badge des fils en attente (20/11) | Pas faits ; dépend de Praxis (M1) | Après M1 |
| N11 | Relecture du guide en arabe et en anglais par une personne de la langue ; relecture du hadith des lettres de prospection par un enseignant | Pas faites | Le directeur désigne qui relit |
| N12 | Politique de confidentialité : relire l'anglais et l'arabe, aligner la copie du site public ; vérifier qu'elle nomme Gemini et OpenAI (17/11) | Pas fait, ou non vérifié | Un agent |
| N13 | Purge des pièces d'identité | Jamais exécutée | Un agent, avec le pilote |

## 3. Livré, jamais prouvé par le directeur (à prouver, pas à recoder)

Cloche style C (#696, #698) ; annonces fermables et traduites (#693, #694, #697 ; traduction d'une **nouvelle** annonce
non vérifiée) ; guide et ses commentaires (#665, #687, #690, #692, #695) ; écran « Recharger », prix famille, dette et
avance (#718, #719) ; un compte une personne, second appareil (#717) ; WhatsApp à l'inscription (#714) ; lots famille
et admissions du 22/11 (#699 à #712) ; recopie retirée de l'espace de traitement (#684) ; politique v2 (#645) ;
carte des gestes de la direction (8 lots, 17/11).

## 4. Questions au directeur (la réponse débloque la ligne)

1. **M1** : couper Praxis vous-même, ou « vas-y » pour la migration ? Le « point du jour » aussi ?
2. **N1** : quel taux enfant ? Le guide prévaut-il sur P1, P2, P3, L1 ?
3. **R-06** : une notification qui mène à un fil, une classe ou un paiement s'ouvre-t-elle directement, ou d'abord par son détail ?
4. **N9** : le plan du parcours de l'enseignant est-il validé ? Et PE-A7 (#655) ?
5. Facture de novembre de Dyna (65 $) : l'annuler ? Le petit frère garde-t-il sa remise quand l'aîné ne paie pas ? Prévenir les familles à prix spécial ?
6. Garder ou retirer la mention de PISI dans les lettres de prospection ?
7. Le nom « Guide de l'enseignant » est-il le bon ?

## 5. Plan, dans l'ordre

1. **Aujourd'hui, sans code** : le directeur règle M7 (Billing GitHub), M1 (Praxis) et répond aux questions 1 à 3.
2. **Semaine du 30/11, quatre agents au plus, une PR par ligne** :
   - agent A : N1 dès la réponse (règle écrite datée, puis paie et langues), puis M5 se ferme ;
   - agent B : M2 (vérifier en production, corriger), puis N12 et N13 ;
   - agent C : N4, N5 puis N3, après N2 ;
   - agent D : M3, références montrées d'abord, puis code ; N6 (coordonnées bancaires) en parallèle si le directeur choisit.
3. **Preuves** : une feuille de recette courte pour le §3, un passage par parcours (famille, candidat, direction), faite
   par le directeur sur la production ; chaque défaut devient une ligne du §1.
4. **Le 29/11 au soir** : contrôle des lettres de prospection, puis N7.
5. **Sur ordre seulement** : N8 (Praxis), N9 (maquettes et parcours), M4 (liste des familles).

## 6. Pourquoi les endroits précédents « n'ont pas marché » (constaté le 27/11)

- `CLAUDE.md` ordonne en tête de lire **seulement** le plan de la Boucle 1, « sans relire la table » : les alertes de
  la table passaient après, ou jamais.
- Six lignes de la table disent « toujours, avant tout » ; une dizaine de fichiers de suivi coexistent
  (`REGISTRE-LOTS`, `BUREAU-EQUIPE/SUIVI`, `CHECKLIST-PASSATION`, `RESTE-A-FAIRE`, `REGLES-NOUVELLES`, alertes…).
- Personne ne les tient à jour : 60 des 63 lots « à livrer » du registre étaient déjà dans `main`, et `SUIVI.md` est figé
  depuis le 16/11. Un agent qui les lit croit le travail à faire, ou fait, à tort.
- Remède : cette liste unique, en première ligne de `CLAUDE.md`, et répétée à chaque ouverture de session par le
  message de démarrage (fichier `.claude/hooks/demarrage.sh`, protégé : il ne change que sur ordre du directeur).
