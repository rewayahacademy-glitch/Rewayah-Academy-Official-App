# Cahier BE-DOSSIER-2 : corrections du dossier vu en production (directeur, 16/11/2026)

Le dossier en trois étages (PR 508) est en production. Constats du directeur, avec captures :

1. **Page vide au bout** : en défilant jusqu'à la fin, la page continue sur un grand vide
   (« quand tu scrolles à la fin, il ne s'arrête plus »). Cause : la place gardée sous les
   rubriques pour que le titre ne bouge pas à la fermeture (accepté à tort par le
   coordinateur). **La page s'arrête au dernier contenu, toujours.** Garder le titre immobile
   seulement à l'ouverture ; à la fermeture, la page se raccourcit (un léger mouvement vaut
   mieux qu'un vide).
2. **Trop de rubriques repliées** : « il faut seulement déplier les sections qui ont beaucoup
   d'informations ; le reste, tu l'affiches comme il se doit. » Repliées : Réponses
   détaillées, Historique, Autres compétences. **Affichées directement** : Pièce d'identité,
   Versement, Accords, Entretien, Responsable, Contact, chacune sur une ligne ou deux avec
   ses gestes.
3. **Une carte de profil en tête, comme un profil de réseau social** : photo plus grande,
   nom, drapeau et pays, langues, mémorisation, ijaza, situation, et **la messagerie sur la
   carte** (bouton « Écrire », nombre de messages non lus, dernier message en une ligne ;
   la conversation s'ouvre dans le volet existant). Le tableau de synthèse reste juste
   dessous pour le reste (disponibilités, versement, public).
4. **Heures mélangées à l'arabe** : « الجمعة · السبت · الأحد : 0:00، 1:00، 2:00… » se mélange
   (chiffres latins dans une phrase arabe). Règle : les jours sur une ligne, les heures sur
   la ligne suivante, **en plages** (heures consécutives réunies : 00 h – 04 h, 07 h – 11 h),
   chaque plage isolée de gauche à droite, séparées par des espaces, jamais par « ، ». Même
   règle en français (« Ven · Sam · Dim » puis « 00 h – 04 h · 07 h – 11 h »). Le calcul des
   plages vit dans `lib/core/candidature/synthese_candidature.dart`, avec ses tests.

Zone : `lib/features/admin_candidature`, `lib/core/candidature/synthese_candidature.dart`.
Captures 360 et 1366, français et arabe, **en défilant jusqu'au bout** (la dernière capture
montre la fin de la page). Une PR à part, avant BE-SUIVANT.

Phrase à rendre vraie : « J'ouvre un dossier et je connais la personne d'un coup d'œil ; la
page s'arrête où elle finit ; les heures se lisent en arabe comme en français. »
