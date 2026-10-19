# Marque Rewayah Academy : lire d'abord

Dossier actif depuis le 19/10/2026. Il fait autorité sur l'identité, le discours et l'expression visuelle
de Rewayah Academy hors des écrans de l'app (Brand Book, documents, communication, futur site).
Pour les écrans de l'app, `docs/current/03_DESIGN_SYSTEM_ET_UX.md` et `lib/CLAUDE.md` restent la règle.

| Fichier | Sert à | Quand le lire |
|---|---|---|
| `REGISTRE-DECISIONS-MARQUE.md` | Ce qui est décidé, proposé, ouvert | **Toujours en premier** |
| `MANIFESTE-MARQUE.md` | Identité, raison d'être, promesse, publics, valeurs, ton, signatures | Avant d'écrire sur Rewayah |
| `CAHIER-DES-CHARGES-VISUEL.md` | Logo, couleurs, polices, images, grilles, manques ; texte d'amorçage pour Claude Design | Avant de composer un support |
| `AUDIT-MARQUE-2026-10-19.md` | Inventaire, contradictions, audit du brief ChatGPT, carte de diffusion | Pour comprendre un choix |
| `import/` | Textes à importer à la main dans les outils hors du dépôt (compétence claude.ai, mémoire du poste) | Pour le directeur |

## Ordre d'autorité

1. La demande explicite la plus récente du directeur.
2. Les décisions datées : ce registre, puis les `DECISION-*.md` de `docs/current/`.
3. Les sources qui font foi pour leur sujet : `assets/brand/logo/README.md` (logo),
   `docs/current/BRAND-ORN-1.md` (ornement), `lib/core/theme/` (jetons), `.claude/skills/mots-rewayah`
   (mots), `.claude/skills/programme-rewayah` (programme).
4. Le manifeste et le cahier visuel.
5. Rien d'autre : ni `docs/archive/`, ni le site public (brouillon), ni une compétence de compte qui les
   contredit.

## Règles pour tout agent

- Lire les sources avant de proposer une modification de marque.
- Ne pas réinventer le logo, les couleurs ni les polices.
- Une proposition reste une proposition tant qu'aucune ligne datée du registre ne la valide.
- Signaler une contradiction dans le registre (section 3) plutôt que la trancher en silence.
- PISI est un autre projet : aucun élément de PISI dans Rewayah (M-12).
- L'application reste la priorité : un travail de marque ne modifie ni le code produit, ni le backend.
- Mettre à jour le registre et le document concerné dans le même commit.
