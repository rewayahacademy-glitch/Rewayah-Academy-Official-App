# Courriel d'attente aux candidats enseignants (B3.1)

Décidé par le pilotage le 24/10/2026 (`docs/orchestration/PILOTAGE-BOUCLES-2026-10-24.md`,
Boucle 3). Texte soumis au directeur le 24/10 ; il le corrige ici ou le valide tel quel.

## Envoi

- Expéditeur : `recrutement@rewayahacademy.com` (catégorie `recrutement`, non essentielle :
  lien de désinscription en un clic).
- Destinataires : les personnes des formulaires Google (feuille des candidats), une fois par
  adresse, adresses exclues respectées par `courriel_enfiler`, clé d'idempotence
  `candidat_attente:<adresse>` : jamais deux fois.
- Cadence : environ 200 par jour sur trois jours, pour rester loin des limites de Workspace et
  des filtres anti-pourriel. D'abord une copie au directeur sur une adresse test.
- Mise en oeuvre : un modèle `attente_candidat` dans `supabase/functions/_shared/courriel/`
  (déployé par la fusion dans `main`), puis une page de collage pour la mise en file (SQL
  fabriqué depuis la feuille, collé par le directeur dans la base de production).

## Objet

Votre candidature pour enseigner à Rewayah Academy : où nous en sommes

## Corps

Assalamou alaykoum wa rahmatoullah,

Vous avez rempli notre formulaire pour enseigner le Coran à Rewayah Academy. Nous vous
remercions de votre confiance et nous vous devons une réponse claire.

Vous êtes près de six cents à avoir répondu. Nous lisons chaque candidature une par une, et nous
n'ouvrons les classes qu'avec des enseignants que nous avons rencontrés. Cela prend du temps, et
nous préférons le prendre plutôt que de mal faire.

Ce qui va se passer :

1. D'ici trois semaines, vous recevrez un courriel personnel de notre part, dans tous les cas.
2. Si votre profil correspond à nos besoins du moment, ce courriel contiendra une invitation à
   créer votre compte dans l'application Rewayah, puis un entretien en visio avec la direction.
3. Si ce n'est pas le cas pour l'instant, nous vous le dirons aussi, et nous garderons votre
   candidature pour les prochaines ouvertures, sauf si vous préférez qu'on l'efface.

Vous n'avez rien à faire aujourd'hui. Inutile de nous écrire pour demander où en est votre
dossier : c'est nous qui reviendrons vers vous, à cette adresse.

Si vous ne souhaitez plus enseigner avec nous, un clic sur le lien en bas de ce message suffit,
sans justification.

Qu'Allah vous récompense pour votre démarche.

La direction
Rewayah Academy
