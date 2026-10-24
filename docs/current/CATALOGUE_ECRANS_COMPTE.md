# Catalogue des écrans : Compte (tous les rôles)

Registre des écrans du Compte ajoutés après la remise à plat, au format du registre général
(Code, Écran, Rôle, niveau de charge, profondeur, route, mobile, bureau, état). Inscrit le
23 octobre 2026 **avant le code** (COURRIELS-2, migration `20261023140000`).

**État** : présent dans le code et testé localement (`flutter test`, 320 px, texte ×2, LTR et RTL),
frontend seulement. Ni staging ni déploiement. En production le port vaut
`LanguesCommunicationSupabase` ; sans lui l'écran dit « Choix de la langue indisponible ».

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `CPT-LANG` | Langue des e-mails et des messages | Tous les rôles connectés | E | 2 | `/compte/langue-courriels` (tuteur et élève adulte : `/tuteur/compte/preferences/langue-courriels`) | Une phrase de contexte, une liste de cartes de choix, une action pleine | Idem, colonne bornée | **construit (23/10)**, port `PortLanguesCommunication`, adaptateur `LanguesCommunicationSupabase`, démo `LanguesCommunicationDemonstration` |

## CPT-LANG : Langue des e-mails et des messages

- **Tâche** : choisir la langue dans laquelle on reçoit les e-mails de l'académie et les messages de la
  direction. La direction écrit une seule fois ; le serveur traduit (Google Traduction) à l'envoi.
- **Placement** : sous-page des réglages du Compte, atteinte par la première ligne de « Langue et
  région » (`ReglagesComptePage`, `/compte/reglages`, commun à tous les rôles). Le tuteur et l'élève
  adulte, dont `/compte/reglages` rejoint les Préférences, y accèdent par la ligne « Langue et région »
  des Préférences. Une seule page, deux routes, aucune entrée de navigation en plus.
- **Contexte (K-58)** : « Les e-mails de l'académie et les messages de la direction vous arrivent dans
  cette langue. Un message écrit dans une autre langue est traduit automatiquement. »
- **Choisi** (K-57) : la langue, par `ChoiceCardGroup`, une carte par langue du serveur
  (`langues_communication_lister`), chacune écrite dans sa propre langue (Français, English, العربية…),
  avec « Vous recevez les e-mails et les messages en… ». Tout est **choisi**, rien n'est saisi ni
  déduit ; la langue déjà réglée est cochée, Français quand le serveur n'en a retenu aucune.
- **Pas de carte « Autre »** : exception admise des listes fermées par le serveur
  (`autoriserSaisieLibre: false`, comme les catégories d'e-mail et les listes du cahier). Une langue
  saisie à la main ne saurait être ni traduite ni retenue par le serveur, qui refuse tout code hors liste.
- **Action** : « Enregistrer la langue », une seule action pleine, **rendue seulement quand la carte
  touchée diffère de la langue enregistrée** (jamais grisée). Aucune confirmation : le geste se
  rejoue et se défait en choisissant une autre langue.
- **Issue** (D5, K-59) : « C'est enregistré » seulement après la réponse du serveur. Langue qui n'est plus
  proposée (`22023`), droits (`42501`), changement non confirmé (la langue précédente reste en place),
  réseau absent (rien n'est enregistré). Après un succès, l'adaptateur pose aussi la langue dans les
  données de l'utilisateur d'authentification (`user_metadata.langue`) pour que les e-mails de connexion
  la suivent ; si cette seconde écriture échoue, la langue du profil reste enregistrée.
- **États** : chargement (`Skeleton`), contenu, vide (« Aucune langue n'est proposée… »), erreur
  (« Réessayer »), hors ligne (`EtatSansDonnees`), fonction indisponible tant que le serveur n'est pas branché.
- **Droits** (serveur) : toute personne ayant un profil ; la liste des langues est lisible sans compte.
- **Hors fiche** : la langue de l'interface (le français seul, ligne inchangée de « Langue et région ») ;
  l'arabe de l'application n'est pas lié à ce choix.
