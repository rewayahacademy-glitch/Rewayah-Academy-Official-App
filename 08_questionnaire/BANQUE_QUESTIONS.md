# Banque de questions d'accueil (tous rôles)

Statut : PROPOSITION du 25/09, en attente des décisions du directeur. Ne rien coder avant validation.
Page de revue pour le directeur : https://claude.ai/artifact/UwExdHDgacg6b8ZJ4p4ikZ
Tableau : ligne HL-B-4 ; consigne K-24.

## Règles (valables pour tout rôle)
1. Une question = une fiche (ci-dessous). Les écrans lisent la fiche ; ne jamais réécrire une question à la main.
2. Un seul visuel : `PageParcours` (lib/core/widgets/page_parcours.dart) + `ChoiceCardGroup`/`OptionChoix` (coteACote pour 2-3 choix courts) + phrase « pourquoi » sous la question + récapitulatif `GroupeReglages`.
3. Toujours dire pourquoi, et la réponse doit changer quelque chose de visible. Sinon ne pas demander.
4. Ne jamais demander deux fois ni demander ce que l'appareil sait (âge déjà saisi, appareil, fuseau suggéré).
5. Question sensible = tard, facultative, formulée en besoins, avec « Je préfère ne pas répondre ». Jamais de diagnostic.
6. Tout se modifie depuis la fiche de l'élève ; rien n'est verrouillé.
7. Moments : 1 inscription (≤ 4) ; 2 ajout d'un profil ; 3 questionnaire de l'élève (6 en général, 8 au plus) ; 4 avant la 1re séance ; 5 plus tard dans la fiche.

## Existant (ui/tuteur-v1, ne pas recréer)
- Inscription : usage, identité, genre, récapitulatif (lib/features/inscription/etapes/).
- Ajout d'un enfant : pour qui ; prénom, nom, âge en chiffres (lib/features/foyer/formulaire_profil_eleve.dart).
- Questionnaire élève : âge (tranche), langue, lieu, niveau, objectif, moments (lib/features/parcours_offres/parcours_offres_page.dart ; textes fr.i18n.json « parcours »).
- Stockage existant : student_profiles.langue_cours, cohorte, niveau_declare, objectif, riwaya (défaut hafs), camera_policy (défaut forbidden), interface_mode ; households.timezone.

## Fiches proposées
Champs : id · question · pourquoi · choix · condition · moment · obligatoire · qui la voit · stockage · rôles.

- Q-AGE-DEDUIT · (retrait de la question tranche d'âge) · la tranche se déduit de l'âge saisi à l'ajout · moment 3 · stockage cohorte (existe) · rôles : enfant, adulte.
- Q-ENSEIGNANT-GENRE · « Pour {prenom}, vous préférez… » · « Nous vous montrerons d'abord les classes qui respectent ce choix. » · Un enseignant / Une enseignante / Peu importe (côte à côte) · toujours · moment 3 · obligatoire · administration seulement · À CRÉER · enfant, adulte ; miroir enseignant « publics acceptés ». Décision directeur : libre choix ou règle de l'académie.
- Q-MEMORISATION · « Jusqu'où {prenom} a-t-il/elle mémorisé ? » · « Une estimation suffit. L'enseignant vérifiera… » · Quelques courtes sourates / Tout le Juz 'Amma / De 2 à 5 parties / Plus de 5 parties · si niveau = memorisation_partielle · moment 3 · obligatoire · enseignant + admin · À CRÉER · enfant, adulte ; lecteur du Coran (suivi).
- Q-LECTURE (riwaya) · « Avec quelle lecture {prenom} a-t-il/elle appris ? » · « Son enseignant et son Mushaf suivront la même lecture. » · Hafs / Warsh / Je ne sais pas · si niveau ≥ lecture lente · moment 3 · obligatoire · enseignant, admin, lecteur · student_profiles.riwaya (existe) · enfant, adulte ; miroir enseignant « lectures enseignées ». Décision directeur : l'académie enseigne-t-elle Warsh ?
- Q-ADULTE-PRESENT · « Pendant les séances, qui sera près de {prenom} ? » · « Si {prenom} se déconnecte, l'enseignant saura qui prévenir. » · Un adulte à côté / Un adulte dans la maison, joignable / Seul(e) · si cohorte enfant_5_7 ou enfant_8_10 · moment 4 · obligatoire · enseignant + admin · À CRÉER · élève enfant, visio.
- Q-CAMERA · « Pendant les séances, la caméra de {prenom} peut-elle être allumée ? » · « Rien n'est jamais enregistré. Modifiable dans sa fiche. » · Non, seulement le micro (défaut) / Oui, visible de l'enseignant et de la classe · toujours · moment 4 · obligatoire · enseignant + admin · student_profiles.camera_policy (existe) · enfant, adulte, enseignant, visio. Décision directeur : caméra des enfants permise ?
- V-TEST-TECHNIQUE · (pas une question) test automatique micro, son, connexion + appareil détecté · moment 4 · aucun stockage · tous les rôles en visio.
- Q-AIDES-APPRENTISSAGE · « Qu'est-ce qui aide {prenom} à bien apprendre ? » · « Seul son enseignant verra cette réponse. » · multiple : Des pauses fréquentes / Qu'on parle lentement / Ne pas être interrogé(e) en premier / Entend ou voit mal / Autre (phrase courte) + « Je préfère ne pas répondre » · moment 5 (fiche) · facultatif · enseignant seulement · À CRÉER (accès restreint) · enfant, adulte.

## Écartées
Date de naissance ; test de lecture enregistré ; classe scolaire ; pratique religieuse ; « comment nous avez-vous connus » (e-mail après inscription).

## Décision en attente sur l'objectif
Si Tawhid, Fiqh, Sira, Éthique sont proposés dans l'app : ajouter l'objectif « Apprendre les bases de la religion ».
Toute colonne « À CRÉER » = migration = accord écrit du directeur (K-19).

