# Cahier BE-PAYS-MAJEUR : le Ghana introuvable, et l'attestation « 18 ans ou plus »

Deux demandes du directeur du 16/11/2026, en deux PR, par le même agent, dans cet ordre.

## PR 1 : PAYS-RECHERCHE (petit, à livrer d'abord)

Le directeur : « Quelqu'un dit qu'il ne retrouve pas le Ghana dans le formulaire. »

Vérifié le 16/11 : le Ghana **existe** (serveur `private.pays_iso_3166`, 249 pays ;
`lib/core/i18n/pays_iso.dart:222` ; 3 candidats l'ont déjà choisi). **Cause** : dans
`lib/features/candidature/question_etape.dart` (`_Pays`) et
`lib/features/candidature/pays_versement_portail.dart`, la recherche ne lit que le nom dans
la langue de l'interface ; le champ `motsCles` d'`ElementChoix` (prévu pour « le nom dans
l'autre langue ») n'est rempli nulle part. Un candidat dont l'application est en arabe tape
« Ghana » en lettres latines et ne trouve rien. De plus, la liste courte affichée d'abord
(`paysCourants`) ne correspond pas aux vrais candidats (en tête aujourd'hui : SA 204, NG 51,
YE 12, EG 8, DZ 5, BJ 4, GH 3, TD 3).

À faire (zone : `lib/features/candidature` seulement) :
1. Chaque pays porte `motsCles` = nom français, nom arabe, nom anglais et code, partout où un
   pays se choisit dans le parcours du candidat.
2. `paysCourants` : SA, NG, YE, EG, DZ, BJ, GH, TD, SN, ML, GN, MA, FR, BE, GB (ordre des vrais
   candidats, puis les pays d'Europe déjà présents).
3. Tests : en arabe, taper « Ghana », « gh » ou « GH » trouve le Ghana ; en français, taper
   « غانا » le trouve aussi.

## PR 2 : MAJEUR (serveur et écran)

Le directeur : « Il faut ajouter une consigne qui demande si le candidat a plus de 18 ans.
S'il a plus de 18 ans, il peut continuer ; sinon, il ne peut pas continuer. Pour ceux qui sont
déjà avancés et acceptés, il faut le leur ramener dans leur page, là où ils sont ; ils vont
devoir le cocher. »

Zone : `supabase/**` (plage `20261128400000` à `20261128400900`), `lib/features/candidature`,
`lib/core/candidature`, et dans `lib/features/admin_candidature` la seule rubrique Accords
(après la fusion de la PR 508).

1. **Serveur** : une attestation par candidature (`majorite_attestee_le`, `majorite_declaree`
   vrai ou faux), écrite par le candidat seul par une fonction dédiée, tracée dans
   `candidature_evenements`. L'envoi des réponses (salle 1) est refusé sans attestation vraie.
   Une déclaration « moins de 18 ans » : la candidature est mise en pause automatiquement,
   motif « âge », visible de la direction ; rien n'est supprimé.
2. **Candidat, salle 1** : une case en tête du parcours, avant les questions : « J'ai 18 ans
   ou plus. » ; et un lien « J'ai moins de 18 ans ». Sans la case, « Continuer » ne s'affiche
   pas et une phrase dit pourquoi (K-56). Avec « moins de 18 ans » : une phrase claire et
   bienveillante dit que le recrutement est réservé aux personnes de 18 ans et plus.
3. **Candidats déjà avancés** (salle 2, salle 3, confirmés, enseignants accueillis) : à leur
   prochaine ouverture, la même case s'affiche **en tête de leur page, là où ils sont**, et
   leurs gestes suivants attendent qu'elle soit cochée. Rien n'est perdu de leur dossier.
4. **Direction** : dans la rubrique Accords du dossier, « 18 ans ou plus : attesté le … » ou
   « non attesté » ; filtre `majorite` (attestée, non attestée, moins de 18) dans la liste.
5. Textes en français, arabe, anglais (`mots-rewayah`). Scénario SQL : envoi refusé sans
   attestation, accepté avec, pause automatique si « moins de 18 », personne d'autre que le
   candidat ne peut attester pour lui.
6. Lu en production avant la PR, sans rien écrire : combien de candidatures en cours devront
   cocher (par étape).

Phrases à rendre vraies : « Un candidat qui tape Ghana le trouve, quelle que soit la langue
de son application. » « Personne n'avance dans le recrutement sans avoir attesté avoir 18 ans
ou plus, et ceux qui étaient déjà avancés le font à leur prochaine visite. »
