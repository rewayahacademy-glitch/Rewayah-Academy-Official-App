# Écart entre les specs et l'application réelle

> Relevé du 18 septembre 2026, établi en regardant l'application déployée
> (`https://rewayah-academy.vercel.app`) et la base de production
> (`gggmtelinlpseweouyav`), pas en lisant le code.

## 0. Ce qui compte comme preuve dans ce document

Chaque ligne porte son type de preuve. C'est la seule façon de ne pas répéter
l'erreur qui a produit ce document : des sessions entières ont déclaré « vert »
sur la foi de tests unitaires et de codes HTTP 200.

| Marque | Sens |
| :-- | :--- |
| 👁 | **Vu à l'écran** dans un navigateur réel, capture à l'appui |
| 📊 | **Mesuré en base** de production par requête SQL |
| 📄 | **Déclaré par le dépôt lui-même** (`PROGRESS.md`, `HANDOFF.md`) |
| ❓ | **Non vérifié** — ni vu, ni mesuré. N'est affirmé dans aucun sens |

**Le dépôt admet déjà le problème de fond.** `PROGRESS.md` §184-203 :
« La recette navigateur authentifiée reste non prouvée […] Le dépôt ne contient
aucun test d'intégration navigateur ; les tests Flutter ne sont pas une preuve
de ce parcours. » Les 743 tests verts et les 144 contrôles SQL ne disent rien de
ce qui s'affiche.

---

## 1. Le constat central : l'académie est bloquée et le tableau de bord dit zéro

📊 La base contient **trois enseignants inscrits qui attendent depuis sept jours** :

| Identifiant | Inscrit le | État du compte | Contrats signés | Pièce d'identité |
| :--- | :-- | :--- | :-: | :--- |
| `TEACHER-AS-000001` | 11/09 | `pending_kyc` | 2 | aucune |
| `TEACHER-AS-000002` | 11/09 | `pending_kyc` | 2 | aucune |
| `TEACHER-AD-000003` | 15/09 | `pending_kyc` | 2 | aucune |

Ils ont accepté les deux contrats : ils ont traversé le tunnel d'entrée et se
sont arrêtés au dépôt de la pièce.

👁 L'écran `ADM-01` affiche **« 0 Dossiers à valider »**, et `ADM-02` affiche
**« Aucun dossier en attente »**.

📊 La cause exacte : `dossiers_en_attente()` fait
`select … from kyc_documents where status = 'pending'`. Elle **compte des
documents, pas des personnes**. Zéro document déposé, donc zéro ligne.

Le chiffre est exact et le message est faux. La fiche `ADM-01` du catalogue
avait pourtant écrit la phrase du danger — *« l'admin verrait une ruche vide et
croirait tout traité »* — mais uniquement pour le cas d'une lecture en échec.
Le cas où la donnée existe et qu'aucun compteur ne la compte n'a jamais été
prévu.

📊 En parallèle : **1 foyer attend un enseignant**. Il y a trois enseignants qui
attendent d'être validés. Personne ne peut les rejoindre, et rien ne le signale.

**Aucun écran de l'application ne liste les personnes.** La Zone Administration
du catalogue contient `ADM-01`, `ADM-02`, `ADM-04`, `ADM-06`, `ADM-07` — centre
de commande, dossiers, journal, demandes, accès agents. Il n'existe nulle part
d'écran qui réponde à « qui s'est inscrit ? » ou « qui attend ? ». Ce n'est pas
un bug : cet écran n'a jamais été conçu.

---

## 2. Zone Administration, écran par écran

Le catalogue (`docs/design/08-catalogue-ecrans.md` §2) affirme : **« L'espace
admin n'a plus un seul écran manquant. »** Voici ce qui s'affiche réellement.

| Écran | Le catalogue dit | Ce qui s'affiche | Verdict |
| :--- | :--- | :--- | :--- |
| `ADM-01` Centre de commande | construit | 👁 Six compteurs qui se chargent et affichent leurs valeurs, zéros compris | **Fonctionne, mais compte la mauvaise chose** (§1) |
| `ADM-02` Validation des dossiers | repris (R4) | 👁 État vide « Aucun dossier en attente », correctement rédigé | **Fonctionne, vide à tort** (§1) |
| `ADM-04` Journal d'audit | construit (12/09) | 👁 Bandeau d'intégrité « Journal intact · 91 entrées relues », filtres par période, par événement et par acteur | **Fonctionne**, avec une fuite (§4) |
| `ADM-05` Attribution manuelle | construit (12/09) | 👁 Le titre et la phrase d'intro s'affichent, puis **rien** : aucune liste, aucun état vide, aucune erreur, aucun squelette | **Cassé** |
| `ADM-06` Demandes et règles | repris (R4) | 👁 Route existante mais **hors de la barre latérale**, par choix de code assumé dans `app_router.dart` | **Inatteignable par la navigation** |
| `ADM-07` Accès des agents IA | construit (18/09) | 👁 **Seul le titre s'affiche.** Pas de formulaire, pas de liste de jetons, pas de barre latérale | **Cassé** |

Sur six écrans déclarés terminés : **deux fonctionnent sans réserve**, un fuit
des identités, un est inatteignable, **deux ne rendent que leur titre**.

👁 Les deux écrans cassés (`ADM-05`, `ADM-07`) partagent exactement la même
signature : l'en-tête est peint, le corps ne l'est jamais, **et il n'y a aucune
erreur en console ni aucun appel réseau en échec**. Les RPC dont ils dépendent
répondent `200`. Ce n'est donc ni un problème de droits ni un problème de
données : c'est un défaut de rendu, probablement commun aux deux.

📄 Deux écrans admin réintroduits dans le MVP-0 par
`docs/historique/couverture-specs.md` ne figurent même pas au catalogue :
`ADM-03` (séquestre des téléchargements) et `CTR-03` (grille d'audit du
contrôleur). Le handoff §10.4 les remet en V1 « tant que leur contradiction de
périmètre n'est pas tranchée ». La contradiction est ouverte depuis le début.

---

## 3. Ce qui ne peut pas fonctionner du tout aujourd'hui

Ces points ne sont pas des écrans ratés : ce sont des chaînes qui n'ont jamais
pu s'exécuter une seule fois.

| Fonction | État réel |
| :--- | :--- |
| **La salle de cours** (`ELV-03`, `ENS-03`, `CTR-02`) — le cœur du produit | 📄 Aucun compte LiveKit n'existe. `PROGRESS.md` ligne 148 : « il ne manque que le compte ». La chaîne répond « vidéo non configurée ». **Aucun cours n'a jamais pu avoir lieu dans l'application.** |
| **Connexion par Google** | 👁 Google renvoie `invalid_client` — « The OAuth client was not found » — pour `client_id=portail.rewayahacademy.com`. Ce `client_id` a la forme d'un nom de domaine, pas d'un identifiant Google (`…apps.googleusercontent.com`). **Le bouton ne peut fonctionner pour personne.** |
| **Connexion par lien courriel** | 📄 Handoff §10.3 : aucun SMTP externe n'est configuré pour les liens destinés aux vrais usagers |
| **Enregistrement audio des séances** (ADR-002, obligatoire) | 📄 Handoff §10.2 : « aucun Egress/R2 opérationnel n'est présent dans le périmètre livré » |
| **Notifications** (validation KYC, attribution, fin de séance) | 📄 Handoff §10.3 : `device_tokens` existe dans le modèle, « le canal push et ses secrets ne sont pas livrés ». Le parcours tuteur repose pourtant dessus : `parcours-utilisateurs.md` §1 étape 4 « Notification à la validation », et `TUT-06` « une notification part à la fin de chaque séance » |
| **Libellés parlés pour les 6-8 ans** (`AudioLabel`) | 📄 Handoff §10.3 : `assets/audio/fr/` ne contient que `.gitkeep`. La spec dit : « Les libellés audio comptent plus que le texte pour les moins de 8 ans » |
| **Interface en arabe** | 📄 Handoff §10.3 : les clés existent, la traduction est vide. La spec dit : « L'arabe n'est pas un cas particulier de ce produit, c'est sa langue principale » (`05-regles-responsive.md` §7) |

---

## 4. Règles transverses des specs, jamais honorées

### Desktop : l'interdiction explicite a été enfreinte

`05-regles-responsive.md` §2 : **« Ne pas agrandir l'application mobile.
Réorganiser. »** Puis §3, écran par écran :

| Écran | Desktop exigé par la spec | 👁 Desktop réel (1366 px) |
| :--- | :--- | :--- |
| `ADM-01` | Grille de **quatre** chiffres, liste « à traiter » pleine largeur dessous | Deux colonnes de rectangles étirés |
| `ADM-02` | File à gauche, **dossier à droite** | Colonne unique centrée |
| `ADM-04` | **Tableau dense**, « c'est sa forme naturelle » | Pastilles de filtre empilées |
| `ADM-05` | **Deux listes côte à côte** | Rien (écran cassé) |

§8.4 exige en plus « une capture de chaque écran du catalogue aux trois largeurs,
en français et en arabe, dans la galerie ». ❓ Cette vérification n'a jamais été
produite.

### Navigation et sortie

- 👁 **Aucune déconnexion nulle part dans l'application authentifiée.** Le mot
  n'apparaît que dans `attente_page.dart` (le portail *avant* validation),
  `salle_page.dart` (quitter un cours) et `compte_page.dart` (espace comptable,
  hors MVP-0). Un admin, un tuteur ou un enseignant validé n'a aucun moyen de
  sortir autrement qu'en vidant le cache du navigateur.
- 👁 La barre latérale admin porte quatre entrées — conforme au modèle de
  navigation de `parcours-utilisateurs.md` (« Admin : 4 — tableau de bord,
  dossiers, attribution, journal ») — mais `ADM-06` et `ADM-07` sont donc
  structurellement hors d'atteinte, et rien d'autre ne les expose.
- ❓ Navigation avant/arrière du navigateur : **non vérifiée**.

### États d'écran

`parcours-utilisateurs.md` §Règles communes : **« Trois états à concevoir, pas
un. Chaque écran existe en état normal, état vide et état dégradé. »**

- 👁 `ADM-05` et `ADM-07` n'ont **aucun** des trois : ni contenu, ni vide, ni
  erreur. Un écran qui ne rend que son titre n'a pas d'état du tout.
- 📄 Handoff §10.2 classe « Refonte loading » en **P0 non fait** : des textes
  « Chargement… » et des `EmptyState` détournés tiennent encore lieu de
  squelettes sur les écrans restants.

### Contradiction jamais tranchée dans la spec elle-même

`parcours-utilisateurs.md` §5 annonce « **Cinq** indicateurs », puis écrit deux
fois « sous les **quatre** chiffres ». 👁 Le code en affiche **six**. Le
catalogue (`08` §6, fiche `ADM-01`) signale l'écart et demande un arbitrage qui
n'a jamais eu lieu.

---

## 5. Ce qui n'a jamais été construit (déclaré par le dépôt, §10.2 et §10.3)

📄 Lots **P0 du MVP-0 encore ouverts**, dans les mots du handoff :

- `ENS-04` **cahier de transmission** — l'écran de fin de cours. Sans lui,
  `TUT-06` et le suivi élève affichent une coquille sans contenu pédagogique, et
  la spec le dit : « le contenu pédagogique le rejoindra avec `ENS-04` ».
- **Synchronisation du cahier** hors ligne (file locale, idempotence, rejeu).
- `ENS-05` **profil enseignant** — la route rend encore `EcranAConstruire`.
- **N6 Coran partagé** — « Quand l'enseignant pousse une page, l'enfant la
  reçoit sans rien chercher » (spec `ELV-03`). Le bouton n'existe pas ; le canal
  de diffusion n'est pas tranché.
- **Présence corrigeable** — aucun geste humain pour corriger ou excuser une
  absence. Rappel du piège connu : `etat_presence()` déduit « absente » d'un
  cours que l'académie n'a pas donné.
- **Chaîne LiveKit réelle** et **enregistrement safeguarding** (voir §3).
- **Recette navigateur authentifiée** — jamais exécutée.

📄 `ELV-05` **suivi pédagogique côté élève** : identifié comme « écart trouvé »
dans `couverture-specs.md` §B, jamais replanifié depuis.

---

## 6. Ce que je n'ai pas vérifié

À ne pas compter comme fonctionnel ni comme cassé :

- ❓ Les parcours **tuteur, enseignant, élève et contrôleur** en entier. Ce
  relevé ne couvre que l'administration.
- ❓ La navigation avant/arrière du navigateur.
- ❓ Le rendu à 390 px et 768 px, le RTL, le clavier, le zoom à 200 %.
- ❓ Le comportement hors ligne.
- ❓ Le contenu de la liste « À traiter en premier » d'`ADM-01` (visible mais
  non déroulée).

---

## 7. Réparé le 18 septembre

- ✅ **`GRANT EXECUTE` manquant pour le rôle `agent_ro`** sur dix fonctions de
  lecture (`indicateurs_admin`, `dossiers_en_attente`, `demandes_en_attente`,
  `eleves_sans_enseignant`, `enseignants_pour`, `jetons_agent_actifs`,
  `journal_audit`, `journal_audit_filtres`, `read_kyc_documents`,
  `verifier_chaine_audit`). Sans ce correctif, toute session d'observation
  agent recevait `403` sur chaque écran. Les fonctions d'écriture restent
  refusées à ce rôle, conformément à l'ADR-025. 👁 Vérifié à l'écran.

- ✅ **La cause racine des écrans vides : `PageShell` dé-bornait la hauteur de
  son contenu.** Il enveloppait le contenu de chaque écran dans son propre
  `Column` pour ajouter une respiration de bas de page ; un `Column` donne à
  ses enfants non flexibles une hauteur **non bornée**, donc tout écran en
  `defilante: false` avec un `Expanded` échouait à se mesurer. En build release
  les assertions de layout sont retirées : le corps disparaissait **sans une
  ligne d'erreur, sans un appel réseau en échec, et sans qu'aucun test ne le
  voie**. Cinq écrans de production, quatre rôles : `ADM-07`, `ADM-04`,
  `CTR-01`, le suivi élève et `TUT-06`. Verrouillé par
  `test/widgets/page_shell_test.dart`, **prouvé rouge avant le correctif et
  vert après**.

- ✅ **La déconnexion existe enfin.** Le mot n'apparaissait que dans le portail
  d'attente — donc *avant* validation — et dans la salle. Un pied de coquille
  dans `NavShell` (`secondairesPour`) porte désormais le compte, `ADM-06`,
  `ADM-07` et `ADM-08`, sans toucher à la règle des quatre destinations.
  ⚠ Limite : ce pied n'existe qu'à partir de 600 px ; sous 600, ces entrées
  passent par les tuiles « Outils » du tableau de bord.

- ✅ **`ADM-08 Comptes` créé**, avec sa fiche au catalogue et la migration
  `0015`. `dossiers_en_attente()` rend une ligne par **personne** et non par
  document ; `indicateurs_admin()` compte des personnes ; `ADM-02` affiche une
  personne sans pièce en disant ce qui manque, au lieu de proposer deux
  verdicts qui échoueraient.

- ✅ **Les boutons « Réessayer » qui n'existaient pas.** `EmptyState` ne rend
  son action que dans le registre `actionnable` ; deux états d'erreur le
  déclaraient en registre `subi` **avec** un libellé d'action, donc sans aucun
  bouton à l'écran.

- ✅ **Le journal ne montre plus de clés brutes.** Les lots `AGT-01`, `CTR-01`
  et `N2` avaient ajouté cinq événements sans libellé : la base en journalise
  **19**, l'écran n'en nommait que 14.

- ✅ **`ADM-01` respecte enfin le responsive.** Le diviseur de colonnes était
  `2` en dur à toutes les largeurs ; la grille suit désormais le gabarit, avec
  quatre chiffres sur desktop comme l'exige `05-regles-responsive.md` §3.

- ✅ **Le journal d'audit ne se noie plus.** `read_kyc_documents()` journalise
  chaque appel : le tableau de bord écrivait une entrée « dossier consulté » à
  chaque ouverture, même sans pièce à lire (52 entrées pour zéro lecture
  réelle). `dossiers_en_attente()` ne l'appelle plus que s'il y a à lire.

**Reste faux dans ce document et corrigé depuis :** le §2 décrivait `ADM-05`
comme cassé. Il ne l'était pas — son code est correct et il s'affiche
parfaitement en local. Il était cassé **en production seulement**, ce qui
restait à expliquer au moment de la rédaction.

---

## 8. Ce que ce relevé change

Le problème n'est pas une liste de bugs. C'est que **rien n'a jamais été
regardé** : le dépôt a mesuré des tests, des migrations et des codes HTTP, et a
déclaré vert un produit dont le cours en visio n'a jamais démarré une seule
fois, dont deux écrans d'administration ne rendent que leur titre, dont
personne ne peut se déconnecter, et dont le tableau de bord annonce « rien à
faire » à une académie où trois enseignants attendent depuis une semaine.

La première règle à ajouter au protocole du dépôt : **un écran n'existe que
quand quelqu'un l'a vu fonctionner dans un navigateur.**
