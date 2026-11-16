# Décision du directeur, 16/11/2026 : les questions de versement du candidat

Statut : **décidé** (directeur, 16/11/2026 : « oui pour le paiement, corrige sa réponse et lance le
lot. mais les modifications s'arrêtent après la validation du dossier »). Cette décision clôt les
allers-retours sur cette question ; on ne la change que sur nouvelle décision datée du directeur.

## Pourquoi

Une candidate (CAND-00013) a répondu « non » au compte bancaire, puis a pris le pays du compte de
son mari (Arabie saoudite, où seul le virement est confirmé). Le candidat ne pouvait changer après
l'envoi que le pays, jamais le « non » ; la direction n'avait aucun geste pour le débloquer. Le
dossier restait « aucun moyen possible » sans issue des deux côtés.

## La règle

1. **D'abord** : « Avez-vous un compte bancaire pour recevoir votre rémunération, à votre nom ou à
   celui d'un proche de confiance ? » Oui / Non.
2. **Si Oui** : « Dans quel pays est ce compte ? »
3. **Si Non** : « Dans quel pays pouvez-vous recevoir de l'argent sur votre téléphone ? », puis les
   services de mobile money de ce pays (liste du référentiel).
4. **Si aucun moyen ne marche** : la candidature reste en attente, jamais refusée pour ce motif, avec
   la phrase qui dit pourquoi et la solution du proche dans un pays pris en charge.
5. **Après l'envoi**, le candidat modifie lui-même **tout le bloc** (compte oui/non, pays, services)
   depuis sa page ; chaque modification recalcule le paiement côté serveur.
6. **Les modifications s'arrêtent à la validation du dossier** : dès que la direction fait passer la
   candidature au-delà de la préqualification, le bloc n'est plus modifiable par le candidat (la
   page le dit en une phrase et renvoie vers la messagerie). Avant, il l'est autant de fois que
   nécessaire.
7. **Côté direction** : un geste « Débloquer le versement » permet de confirmer à la main un cas
   particulier même quand aucun moyen n'est déclaré ; il exige un motif écrit et laisse une trace.

Arbitrages du pilote, 16/11/2026 (lot VERSEMENT-QUESTIONS, PR #528) :

- une modification du bloc par le candidat lève le déblocage de la direction (le calcul repart des nouvelles réponses) ;
- pas de nouvelle version du questionnaire : elle rendrait périmées toutes les réponses déjà envoyées ; l'ordre « compte d'abord » se règle à l'écran ;
- le geste « Débloquer le versement » existe côté serveur ; son écran viendra dans un lot des écrans de candidature, après #515.

Inchangé : validation automatique si le pays et le moyen sont confirmés dans le référentiel ; la
direction décide une fois par pays non encore pris en charge ; pays sous embargo refusés
automatiquement avec une solution (règle du 15/11/2026, `BUREAU-EQUIPE`).

## Cas CAND-00013

Correction de sa réponse « compte bancaire » à **oui** par une migration tracée, sur décision écrite
du directeur ci-dessus (16/11/2026) et sur le message de la candidate (« j'ai choisi l'Arabie
saoudite comme pays de versement parce que mon mari y est », messagerie, 16/11/2026), puis recalcul
du paiement.

## Lot

`VERSEMENT-QUESTIONS` : voir `BUREAU-EQUIPE/SUIVI.md` et `REGISTRE-LOTS.md`.
