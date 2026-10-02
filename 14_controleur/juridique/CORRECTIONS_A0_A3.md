# Corrections proposées aux textes A0 et A3 (propositions)

**Statut.** Propositions d'un agent juriste, 02/10/2026 (lot JUR-SUITE-1), **à valider par le directeur**. **Rien n'est appliqué dans l'application** : ni dans `assets/i18n`, ni dans `09_consentements/TEXTES_V2.md`. Le directeur lit la version française ; la version anglaise fera foi dans l'application ; les trois autres langues viendront à LG-1, traduites depuis l'anglais validé.

**Source des anciens textes.** `09_consentements/TEXTES_V2.md`, version `2026-10-v2`, sections A0 et A3.

**Règle de version (principe 10 et écarts X10, X40).** Si la version `2026-10-v2` n'a encore été montrée à aucun compte réel, ces corrections entrent dans `2026-10-v2`. Si elle a déjà été acceptée par un compte, elles demandent une **nouvelle version** et l'écran « Ce texte a changé » (A7). On ne change jamais un texte déjà accepté sous la même version.

---

## 1. A0 : information sur la religion

### Ce qui change

Seul le paragraphe « Qui voit » change. Le reste de A0 est gardé mot pour mot.

| | Texte |
|---|---|
| **Ancien (FR)** | **Qui voit.** L'enseignant de {prenom} et l'équipe de l'académie. Personne d'autre. Nous ne la vendons pas. Nous ne l'utilisons pas pour de la publicité. Nos messages ont un titre neutre. |
| **Nouveau (FR)** | **Qui voit.** L'enseignant de {prenom} et l'équipe de l'académie, y compris les personnes chargées des visites de contrôle. Personne d'autre. Nous ne la vendons pas. Nous ne l'utilisons pas pour de la publicité. Nos messages ont un titre neutre. |
| **Nouveau (EN)** | **Who can see it.** {prenom}'s teacher and the academy team, including the people who carry out inspection visits. No one else. We do not sell it. We do not use it for advertising. Our messages have neutral subject lines. |

Ligne de métadonnées (hors texte affiché) :

| | |
|---|---|
| Ancien | Base : consentement explicite (RGPD art. 9.2.a), à valider par un juriste. |
| Nouveau | Base : consentement explicite, UK GDPR art. 9(2)(a) ; RGPD art. 9(2)(a) pour les personnes dans l'UE. Validé par la relecture juridique du 02/10/2026 (`ART9_RELIGION.md`). |

### Raison

Un contrôleur voit le cours, donc il apprend que l'élève suit un cours de Coran. Un contrôleur n'est pas toujours un membre permanent de l'équipe (il peut être un enseignant d'une autre Classe, ou un intervenant). Le parent doit savoir à qui il confie cette information sensible : un consentement explicite n'est valable que pour ce qui a été annoncé (UK GDPR art. 4(11) et 9(2)(a)). Sans cet ajout, le contrôle irait au-delà de ce que le parent a accepté (`ART9_RELIGION.md` §5 point 2). La ligne de base est corrigée parce que le droit principal est le UK GDPR, pas le RGPD.

### A0 complet, nouvelle version anglaise (pour LG-1)

> **Title:** Information about religion
>
> **What we do.** Your registration shows that {prenom} is learning the Quran. This is information about religion. The law gives it special protection.
>
> **Why.** We need it to give the lessons. We ask nothing else about your religion or your practice.
>
> **Who can see it.** {prenom}'s teacher and the academy team, including the people who carry out inspection visits. No one else. We do not sell it. We do not use it for advertising. Our messages have neutral subject lines.
>
> **How long.** As long as {prenom} is registered, then {duree_apres_depart}.
>
> **How to withdraw.** Account, My agreements, Withdraw. Lessons stop at the end of the paid period. What was done before remains valid.
>
> **If you refuse.** We cannot give lessons. We delete what you entered within 30 days.
>
> [ I agree ] [ I refuse ]

---

## 2. A3 : l'enregistrement audio et la visite de contrôle

### Ce qui change

Trois paragraphes : « Ce que nous faisons », « Qui écoute » (renommé « Qui peut écouter ») et, par cohérence, la phrase sur l'image.

| Paragraphe | Ancien (FR) | Nouveau (FR) |
|---|---|---|
| Ce que nous faisons | Chaque cours est enregistré en audio. Pas d'image. Un contrôleur de l'académie peut aussi écouter un cours en direct, sans être vu. La salle le rappelle en permanence. | Chaque cours est enregistré en audio. L'image n'est pas enregistrée. Une personne de l'académie chargée du contrôle peut aussi suivre un cours en direct : elle voit et entend le cours, sans être vue ni entendue. Elle n'enregistre rien. La salle le rappelle en permanence. |
| Qui écoute | **Qui écoute.** Seulement les personnes de l'académie chargées de la qualité et de la protection, pour une raison précise. Chaque écoute est inscrite au journal, avec le nom de qui écoute. Vous pouvez demander qui a écouté. | **Qui peut écouter l'enregistrement.** Seulement les personnes de l'académie chargées de la qualité et de la protection, et seulement pour une raison précise, par exemple un signalement. Chaque écoute est inscrite dans un journal. Vous pouvez demander si un enregistrement a été écouté, et pourquoi. |

Les paragraphes « Titre », « Pourquoi », « Combien de temps », « Si vous n'êtes pas d'accord » et les boutons sont gardés mot pour mot. Le bandeau `salle.bandeauPermanent` (« Cours enregistré, visite de contrôle possible. ») n'est **pas** touché (décision du 24/09).

### Raisons

1. **Le contrôleur voit aussi l'image.** L'ancien texte dit qu'il « peut écouter ». En réalité il voit le support, la vidéo de l'enseignant et les vignettes des élèves (doc 08 §8.1 ; `../DPIA_CONTROLEUR.md` 2.1). Un texte d'information doit décrire ce qui se passe vraiment (UK GDPR art. 5(1)(a) et 13 ; principe 10 de la charte : le texte suit la réalité). « Pas d'image » devient « L'image n'est pas enregistrée », pour ne pas laisser croire que personne ne voit l'image.
2. **« Vous pouvez demander qui a écouté » contredit B15.** Le directeur a décidé que l'identité d'un contrôleur n'est jamais révélée. La même logique protège les personnes qui écoutent un enregistrement après un signalement : donner leur nom les exposerait à des pressions. Le droit d'accès n'oblige pas à donner le nom d'un membre de l'équipe quand cela révèle un tiers (DPA 2018, annexe 2, partie 3, paragraphe 16). Une promesse qu'on ne tiendra pas est une information trompeuse. La nouvelle phrase garde ce qui est utile à la famille : savoir **si** et **pourquoi** l'enregistrement a été écouté.
3. **« avec le nom de qui écoute »** est retiré du texte public : le journal garde bien le nom, mais l'annoncer au public suggère qu'on le communiquera. Le journal interne n'a pas à être décrit en détail.
4. **« Qui peut écouter l'enregistrement »** : le titre précise qu'on parle de l'enregistrement, pas de la visite en direct, décrite juste avant.

### A3 complet, nouvelle version française

> **Titre :** Les cours sont enregistrés (le son seulement)
>
> **Ce que nous faisons.** Chaque cours est enregistré en audio. L'image n'est pas enregistrée. Une personne de l'académie chargée du contrôle peut aussi suivre un cours en direct : elle voit et entend le cours, sans être vue ni entendue. Elle n'enregistre rien. La salle le rappelle en permanence.
>
> **Pourquoi.** Pour protéger les enfants et les enseignants. Si quelqu'un signale un problème, nous pouvons vérifier ce qui s'est passé.
>
> **Qui peut écouter l'enregistrement.** Seulement les personnes de l'académie chargées de la qualité et de la protection, et seulement pour une raison précise, par exemple un signalement. Chaque écoute est inscrite dans un journal. Vous pouvez demander si un enregistrement a été écouté, et pourquoi.
>
> **Combien de temps.** {duree_enreg} jours, puis effacé. S'il y a un signalement, l'enregistrement est gardé jusqu'à la fin de l'examen.
>
> **Si vous n'êtes pas d'accord.** Vous pouvez vous opposer : Compte, Mes accords, Je m'oppose à l'enregistrement. Nous vous répondons sous un mois. Nous chercherons une solution avec vous. Si aucune n'est possible, vous pouvez arrêter sans frais pour les cours pas encore suivis.
>
> [ J'ai lu ] [ Je m'oppose ]

### A3 complet, nouvelle version anglaise

> **Title:** Lessons are recorded (sound only)
>
> **What we do.** Every lesson is recorded as audio. The picture is not recorded. A member of the academy in charge of inspections may also follow a lesson live: they see and hear the lesson, without being seen or heard. They record nothing. The lesson room reminds everyone of this at all times.
>
> **Why.** To protect children and teachers. If someone reports a problem, we can check what happened.
>
> **Who can listen to the recording.** Only the academy staff in charge of quality and child protection, and only for a specific reason, for example a report. Every listen is logged. You can ask whether a recording was listened to, and why.
>
> **How long.** {duree_enreg} days, then deleted. If there is a report, the recording is kept until the review is finished.
>
> **If you disagree.** You can object: Account, My agreements, I object to recording. We reply within one month. We will look for a solution with you. If none is possible, you can stop at no cost for the lessons not yet taken.
>
> [ I have read this ] [ I object ]

### Version enseignant (E1)

Les mêmes corrections s'appliquent à E1 (`accordsV2.enregistrementEnseignant.*`). Les deux ajouts propres à E1 sont gardés. Pour l'enseignant, la phrase sur le contrôle peut ajouter : « Elle envoie ensuite un compte rendu à l'académie. » / « They then send a report to the academy. » La politique de contrôle (`POLITIQUE_CONTROLE_ENSEIGNANTS.md`) donne le détail.

---

## 3. Ce qui reste au directeur

| Point | Décision attendue |
|---|---|
| Valider A0 (paragraphe « Qui voit ») | Oui ou non |
| Valider A3 (trois paragraphes) et l'ajout E1 | Oui ou non |
| Version | Garder `2026-10-v2` si aucun compte réel n'a vu ces textes ; sinon nouvelle version |
| Mot anglais pour « contrôleur » | « inspection » / « inspector » proposé (« controller » désigne en droit le responsable du traitement) ; choix final à LG-1 |
