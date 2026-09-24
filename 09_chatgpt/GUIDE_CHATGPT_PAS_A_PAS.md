# Faire produire toutes les spécifications par ChatGPT (web), pas à pas

ChatGPT web n'a pas accès à GitHub ni à ton ordinateur : tu lui donnes les fichiers une seule fois, il te rend des fichiers, tu les ranges dans un dossier, et Claude fait le reste (publication pour tous les agents, contrôle, transformation en étapes du tableau).

## 1. Préparer un « Projet » ChatGPT (une seule fois, 5 minutes)

Un Projet garde les fichiers et les instructions pour toutes ses conversations : tu n'as plus rien à recoller.

1. Dans ChatGPT (barre de gauche), clique **« Nouveau projet »**, nomme-le **Rewayah - Spécifications**.
2. Dans **Fichiers du projet**, ajoute :
   - `DOSSIER_POUR_CHATGPT.md` et `PROMPT_MAITRE_CHATGPT.md` (ce dossier) ;
   - les maquettes du dossier `D:\RA _APP\docs de lancement\tutuor image\` (et son sous-dossier `mobile`).
3. Dans **Instructions du projet**, colle exactement ceci :

```text
Tu travailles pour Rewayah Academy. Avant CHAQUE réponse, applique intégralement le fichier du projet PROMPT_MAITRE_CHATGPT.md (mission, consigne d'autorité, méthode verticale, gabarit de fiche écran, copywriting, maquettes, format de livraison) et appuie-toi uniquement sur DOSSIER_POUR_CHATGPT.md pour les faits sur l'existant.
Consigne d'autorité : exhaustivité totale (jamais « etc. », « similaire à », résumé ou liste tronquée) ; si la réponse devient trop longue, arrête-toi à la fin d'un écran complet et écris « SUITE AU PROCHAIN MESSAGE : <écran suivant> », puis reprends au même niveau de détail quand on te dit « continue » ; auto-contrôle chiffré à la fin de chaque document ; ce qui est nouveau est marqué PROPOSITION, ce qui contredit le dossier est marqué CONFLIT ; plan fermé.
Dans chaque conversation, tu ne produis QUE le document demandé dans le premier message. Tu le livres en fichier Markdown téléchargeable, et les maquettes en images nommées par leur identifiant.
```

Si ton offre ChatGPT n'a pas les Projets : ouvre une conversation par document, joins les deux fichiers et les maquettes utiles, et colle le texte ci-dessus avant le message du document.

## 2. Une conversation par document, dans cet ordre

Dans le Projet, ouvre une **nouvelle conversation pour chaque document** (une conversation trop longue fait oublier des consignes à ChatGPT). Colle le message de la ligne, puis réponds `continue` chaque fois qu'il écrit « SUITE AU PROCHAIN MESSAGE ».

| N° | Message à coller dans la nouvelle conversation | Ajoute ensuite aux fichiers du projet |
|---|---|---|
| 00 | `Produis 00_GUIDE_UX_UI.md puis, dans la même conversation, 00_GUIDE_COPYWRITING.md, selon PROMPT_MAITRE_CHATGPT.md. Commence par résumer en 10 lignes ce que tu as compris du dossier et liste les fichiers du projet que tu n'arrives pas à lire.` | les deux guides livrés |
| 01 | `Produis 01_TUTEUR_COMPLEMENTS.md (section D du dossier : écrans SM-01 à SM-52, planche 3, recharge et solde par enfant, ajout d'enfant revu), avec les nouvelles maquettes.` | - |
| 02 | `Produis 02_CLASSE_ET_VISIO.md : un élève et un enseignant se rencontrent et se voient (priorité n° 1 du directeur), côté élève et côté enseignant.` | - |
| 03 | `Produis 03_ADMIN_VALIDATION_DOSSIERS.md.` | - |
| 04 | `Produis 04_ENSEIGNANT.md.` | - |
| 05 | `Produis 05_ELEVE_ADULTE.md.` | - |
| 06 | `Produis 06_ELEVE_ENFANT.md (Interface guidée).` | - |
| 07 | `Produis 07_ADMINISTRATION.md (tous les domaines de la section E du dossier).` | - |
| 08 | `Produis 08_CONTROLEUR_ET_INVITE.md.` | - |
| 09 | `Produis 09_FINANCE_ET_COMPTABLE.md.` | - |
| 10 | `Produis 10_BIBLIOTHEQUE_ET_RESSOURCES.md.` | - |
| 11 | `Produis 11_LECTEUR_DU_CORAN.md.` | - |
| 12 | `Produis 12_PUBLIC_ET_LANDING.md.` | - |
| 13 | `Produis 13_PUBLICATION.md (stores, règles pour les applications utilisées par des enfants, logo et icône, e-mails, légal).` | - |

Tu peux lancer plusieurs conversations en parallèle une fois les guides 00 livrés et ajoutés au projet.

## 3. Rendre le travail à Claude

1. Télécharge chaque fichier `.md` et chaque image livrés.
2. Range-les sur le poste A dans `D:\RA _APP\specs chatgpt\<N°>_<nom>\` (exemple : `D:\RA _APP\specs chatgpt\04_ENSEIGNANT\`).
3. Écris à Claude : « specs 04 déposées ». Claude les contrôle (complétude, conflits avec les décisions, faisabilité), te signale les manques à redemander à ChatGPT, les publie pour tous les agents et coche la ligne correspondante du tableau de suivi (phase « Spécifications ChatGPT »).
