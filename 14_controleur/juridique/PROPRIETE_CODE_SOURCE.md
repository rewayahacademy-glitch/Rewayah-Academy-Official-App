# Propriété du code source et licence de Rewayah Academy Ltd (05/10/2026)

**Origine.** Consigne du directeur, 05/10/2026 : « le code source appartient à moi Abdoulaye Mouhidine Sow, mais Rewayah Academy a accès à la copie qu'elle utilise gratuitement ; mais le code source ne peut pas être vendu avec l'académie ; le code source de l'app peut être revendu ou cédé par son propriétaire à qui il veut mais cela ne doit pas retirer l'accès à la partie déployée par Rewayah Academy ». Mise en forme par délégation, à contre-revoir par une autre session.

**Statut : règle du projet.** Elle s'applique à toutes les sessions, comme les invariants de `CLAUDE.md`. Le fichier `LICENSE` à la racine du dépôt de l'app en est la version anglaise, qui fait foi.

## 1. La règle en six points

1. **Propriétaire.** Le code source de l'application Rewayah Academy appartient personnellement à **Abdoulaye Mouhidine Sow**, avec tous les droits d'auteur et droits voisins. Cela couvre tout le code, quel qu'en soit l'auteur : lui-même, un agent IA travaillant sur ses instructions, un prestataire ou l'académie. Pour une œuvre générée par ordinateur, l'auteur est la personne qui a pris les dispositions nécessaires à sa création (CDPA 1988, s. 9(3)). Tout droit que l'académie, un salarié ou un prestataire pourrait avoir sur une partie du code est cédé au propriétaire dès sa création (CDPA 1988, s. 91).
2. **Licence gratuite de l'académie.** Rewayah Academy Ltd reçoit une licence gratuite, non exclusive, mondiale, perpétuelle et irrévocable. Elle peut utiliser, exécuter, héberger et déployer l'application pour sa propre activité d'académie, et la faire maintenir et corriger. Cette licence couvre chaque version que l'académie a déployée (« versions déployées ») et chaque mise à jour que le propriétaire lui remet.
3. **Ce que l'académie ne peut pas faire.** Elle ne peut pas vendre le code, le céder, le sous-licencier, le louer ou le mettre en gage. Elle ne peut pas l'inclure dans une vente de l'académie, de son fonds ou de ses actifs. Elle ne peut pas s'en dire propriétaire. Si l'académie est vendue, le code n'est jamais compris dans la vente.
4. **Liberté du propriétaire.** Le propriétaire peut vendre, céder ou concéder sous licence le code à qui il veut, gratuitement ou non.
5. **Aucune vente ne retire l'accès de l'académie.** Toute cession du code se fait sous réserve de la licence de l'académie. L'acheteur est tenu par cette licence (CDPA 1988, s. 90(4)), et le propriétaire le prévient par écrit dans l'acte de cession. Le fichier `LICENSE` du dépôt prévient aussi tout acquéreur. Ni le propriétaire ni un acquéreur ne peuvent arrêter, retirer ou rendre inutilisable une version déployée par l'académie.
6. **Les données ne sont pas le code.** Les données des utilisateurs, les contenus pédagogiques, les marques, le nom de domaine et les comptes de l'académie appartiennent à l'académie ou à leurs auteurs. La propriété du code ne donne au propriétaire, ni à un acquéreur, aucun droit sur ces données.

## 2. Ce qui rend la règle applicable

| Mesure | Où | Qui |
|---|---|---|
| Fichier `LICENSE` (droits réservés, texte anglais ci-dessous) à la racine du dépôt | Branche `juridique/licence-code`, puis `main` à la prochaine fusion autorisée | Sessions |
| Ligne « Propriété du code » dans les invariants de `CLAUDE.md` | Même branche | Sessions |
| `publish_to: 'none'` dans `pubspec.yaml` et aucune licence libre | Déjà en place | Sessions |
| Copie de l'académie : à chaque mise en production, l'académie garde une archive du code source exact de la version déployée, pour pouvoir l'exécuter et la maintenir si le dépôt change de mains | Étiquette git `deploy-AAAA-MM-JJ` et archive sur le Drive de l'académie | Session de déploiement |
| Licences des dépendances tierces (paquets Dart, Flutter, Supabase, LiveKit) conservées : elles ne sont pas la propriété du propriétaire | `pubspec.lock` | Sessions |
| Tout prestataire humain qui écrit du code signe avant de commencer une cession de ses droits au propriétaire, et l'académie reçoit la même licence sur ce code | Contrat du prestataire | Directeur |
| Conflit d'intérêts : le propriétaire est aussi directeur de l'académie. Il déclare son intérêt et la licence est approuvée par une décision écrite du directeur (Companies Act 2006, s. 177 et 182, modèle ci-dessous), gardée avec les registres de la société | Registre de la société | Directeur, une signature |

## 3. Texte du fichier `LICENSE` (anglais, fait foi)

```
Copyright (c) 2025-2026 Abdoulaye Mouhidine Sow. All rights reserved.

This source code is the property of Abdoulaye Mouhidine Sow (the "Owner").
It is not open source. No licence is granted except as stated below.

1. Licence to Rewayah Academy Ltd. REWAYAH ACADEMY LTD (company number
   16624644, England and Wales) holds a free, non-exclusive, worldwide,
   perpetual and irrevocable licence to use, run, host, deploy, maintain and
   have maintained this software for its own academy activities, covering
   every version it has deployed and every update the Owner provides.
2. Restrictions. Rewayah Academy Ltd may not sell, assign, sub-license, rent
   or charge the source code, include it in any sale of its business, shares
   or assets, or claim ownership of it.
3. Transfers by the Owner. The Owner may sell, assign or license the source
   code to anyone. Every such transfer is subject to the licence in clause 1,
   which binds every successor in title (Copyright, Designs and Patents Act
   1988, s. 90(4)). No transfer may withdraw, disable or restrict a version
   deployed by Rewayah Academy Ltd.
4. Data. This notice gives the Owner, or any successor, no rights in the
   data, content, trade marks, domain names or accounts of Rewayah Academy
   Ltd or of its users.
5. Third-party components keep their own licences.
6. This notice is governed by the law of England and Wales.
```

## 4. Décision écrite du directeur (à signer une fois)

> **REWAYAH ACADEMY LTD (16624644). Décision écrite du directeur unique, le ____ 2026.**
> Le directeur, Abdoulaye Mouhidine Sow, déclare être personnellement propriétaire du code source de l'application utilisée par la société, et donc intéressé à la présente décision (Companies Act 2006, s. 177). Il est décidé que la société accepte la licence gratuite, perpétuelle et irrévocable décrite dans le fichier `LICENSE` du dépôt, ainsi que ses limites. La société reconnaît ne pas être propriétaire du code source. Elle reconnaît aussi que le code ne fait pas partie de ses actifs cessibles.
> Signature : ______________________

## 5. Choix faits par délégation

| Point | Choix | Raison |
|---|---|---|
| Changement d'actionnaire de l'académie | La licence continue, toujours incessible, sans droit de propriété sur le code | « Ne doit pas retirer l'accès à la partie déployée » ; la société reste la même personne morale. |
| Fin de la licence | Seulement si l'académie est dissoute | « Irrévocable » protège l'académie ; une résiliation pour faute ouvrirait une porte de retrait. |
| Modifications faites par ou pour l'académie | Elles appartiennent au propriétaire et entrent dans la licence | Évite deux propriétaires sur un même code. |
| Dépôt GitHub | Il est sur le compte `rewayahacademy-glitch`. Il est recommandé que ce compte, ou son transfert, reste sous le contrôle personnel du propriétaire | Détenir le compte n'est pas détenir les droits, mais cela évite tout litige pratique. |
