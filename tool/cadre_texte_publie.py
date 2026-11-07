#!/usr/bin/env python3
"""CADRE-MIGRATIONS (07/11/2026) : le texte publie du cadre religieux de
l'enseignant, tire du fichier valide par le directeur, avec la normalisation
arbitree par le garde-cap le 07/11 (aucun mot change) :

  (1) dans un paragraphe, un retour a la ligne devient une espace ;
  (2) le titre perd ses « ** » et forme le premier paragraphe ;
  (3) chaque element de liste garde sa ligne, « - » devient « • » ;
  (4) paragraphes separes par une ligne vide (\\n\\n), sans espace final.

CADRE-LANGUES (07/11/2026) : les traductions anglaise, espagnole et portugaise
(docs/current/TEXTES-VALIDES/CADRE-RELIGIEUX-TRADUCTIONS.md) prennent la meme
normalisation, sans changer un mot ; le texte d'une langue commence au titre en
gras de sa section et finit au filet « --- » ou a la fin du fichier (le statut et
la liste des corrections qui le precedent ne sont pas publies).

Usage : python3 tool/cadre_texte_publie.py          -> sha256 et longueurs (fr, ar)
        python3 tool/cadre_texte_publie.py toutes   -> idem, les cinq langues
        python3 tool/cadre_texte_publie.py fr|ar|en|es|pt    -> le texte publie
"""
import hashlib
import sys
from pathlib import Path

SOURCE = Path(__file__).resolve().parent.parent / 'docs/current/TEXTES-VALIDES/CADRE-RELIGIEUX-ENSEIGNANT.md'
TRADUCTIONS = Path(__file__).resolve().parent.parent / 'docs/current/TEXTES-VALIDES/CADRE-RELIGIEUX-TRADUCTIONS.md'
ENTETES_TRADUCTIONS = {'en': '## English\n', 'es': '## Español (espagnol)\n', 'pt': '## Português (portugais)\n'}


def sections() -> dict[str, str]:
    s = SOURCE.read_text(encoding='utf-8')
    fr = s[s.index('## Français\n\n') + len('## Français\n\n'):s.index('\n\n---\n\n## العربية')]
    fin_ar = s.index('\n\n---\n\n## Publication') if '\n\n---\n\n## Publication' in s else len(s)
    ar = s[s.index('## العربية\n\n') + len('## العربية\n\n'):fin_ar].rstrip('\n')
    return {'fr': fr, 'ar': ar}


def sections_traduites() -> dict[str, str]:
    s = TRADUCTIONS.read_text(encoding='utf-8')
    sortie: dict[str, str] = {}
    for langue, entete in ENTETES_TRADUCTIONS.items():
        debut = s.index(entete) + len(entete)
        fin = s.find('\n---\n', debut)
        corps = s[debut:fin if fin != -1 else len(s)]
        # Le texte publie commence au titre en gras ; ce qui precède (statut,
        # corrections du relecteur) n'est pas publie.
        titre = corps.index('\n**') + 1
        sortie[langue] = corps[titre:].strip('\n')
    return sortie


def normaliser(section: str) -> str:
    blocs = []
    for bloc in section.strip('\n').split('\n\n'):
        lignes = bloc.split('\n')
        if lignes[0].startswith('- '):
            elements: list[str] = []
            for l in lignes:
                if l.startswith('- '):
                    elements.append(l[2:].strip())
                else:
                    elements[-1] += ' ' + l.strip()
            blocs.append('\n'.join('• ' + e for e in elements))
        else:
            texte = ' '.join(l.strip() for l in lignes)
            if texte.startswith('**') and texte.endswith('**'):
                texte = texte[2:-2].strip()
            blocs.append(texte)
    return '\n\n'.join(b.rstrip() for b in blocs)


def publies() -> dict[str, str]:
    return {k: normaliser(v) for k, v in sections().items()}


def publies_toutes() -> dict[str, str]:
    return {k: normaliser(v) for k, v in {**sections(), **sections_traduites()}.items()}


if __name__ == '__main__':
    p = publies_toutes() if len(sys.argv) > 1 else publies()
    if len(sys.argv) > 1 and sys.argv[1] != 'toutes':
        sys.stdout.write(p[sys.argv[1]])
    else:
        for k, v in p.items():
            b = v.encode('utf-8')
            print(k, len(b), 'sha256', hashlib.sha256(b).hexdigest(), 'md5', hashlib.md5(b).hexdigest())
