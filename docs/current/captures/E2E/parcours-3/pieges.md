# Parcours 3 : pièges (famille pressée, non technique, au téléphone)

Règle : si l'application laisse faire une erreur sans un mot clair et sans un moyen de revenir, le
parcours est rouge. Script : `tool/e2e/pieges_3.mjs`. Les cas réels A et B (adulte devenue
tutrice, mère inscrite au nom de l'enfant) sont joués à part : `captures/E2E/cas-A`, `cas-B`.

| # | Écran | Famille | Piège | Joué | Résultat |
|---|---|---|---|---|---|
| 3.1 | Lien d'e-mail | 2 | Le lien est ouvert sur un autre appareil (ou un autre navigateur) que celui du questionnaire | oui | rouge : le lien ouvert sur un autre appareil arrive sur « Se connecter » (adresse `?code=…#/connexion`) sans un mot ; les réponses du questionnaire (enfant, âge, niveau) sont perdues → FN-111 |
| 3.2 | Questionnaire, âge | 3 | « 5 ans » choisi (l'écran d'ajout de profil dit « âge minimum 6 ans ») | oui | rouge : « 5 ans » est accepté sans un mot au questionnaire, alors que l'ajout d'un profil élève dit « L'âge minimum est de 6 ans » → UX-032 |
| 3.3 | Adresse e-mail | 3 | Adresse tapée avec majuscules et espaces autour | oui | vert : adresse avec majuscules et espaces : lien recu (adresse normalisee) |
| 3.4 | Récapitulatif | 2 | Double clic sur « Envoyer ma demande » | non | non joué : pas de « Envoyer ma demande » sur cet appareil (voir 3.1) |
| 3.5 | Après « Votre demande est en cours » | 2 | Retour arrière du navigateur | non | non joué : le test ouvrait un onglet neuf, sans historique (retour arrière vers about:blank) ; à rejouer dans l'onglet de l'inscription |
| 3.6 | Questionnaire | 4 | Elle s'arrête au milieu du questionnaire et revient plus tard (rechargement) : ses réponses sont-elles gardées ? | oui | vert : avant : http://127.0.0.1:8090/#/commencer?etape=niveau-0 ; apres rechargement : http://127.0.0.1:8090/#/commencer?etape=niveau-0 ; « flt-semantics:Étape 5 sur 9 / flt-semantics:Où en est E2E Piegemvx1hug5 aujourd'hui ? / flt-semantics:Votre réponse oriente les premières propositions. Elle ne fixe pas le niveau officiel : celui-ci est attribué par l'académie après un échange avec un enseignant » |
| 3.7 | Tous les écrans | 5 | Lecture des libellés (« Où en est … aujourd'hui ? », « Avant le prochain cours », « Lien coupé », « État inconnu ») | non | non joué : lecture faite sur les captures, voir le bilan |
