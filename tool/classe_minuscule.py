#!/usr/bin/env python3
"""Lot mecanique « Classe » en minuscule (arbitrage du garde-cap, 06/11/2026).

Regle : « classe(s) » en minuscule au milieu d'une phrase, y compris
« la classe An-Nour » ; majuscule seulement en debut de phrase et de titre.
Exceptions (garde-cap, 06/11) : « Espace Classe » (nom d'ecran) ; les cles
juridique.* et contrat.politique.* (un texte juridique change avec une
nouvelle version et une nouvelle acceptation) ; recrutement.parcours.* et
recrutement.questionnaire.* (majuscule, reponse du directeur du 22/10/2026) ;
debut de phrase et de titre.
Francais seulement (assets/i18n/fr.i18n.json). Le fichier garde sa forme :
le remplacement se fait ligne a ligne, dans les valeurs, sans reformater.

Usage, depuis la racine du depot, sur main frais :
  python3 tool/classe_minuscule.py            # liste ce qui changerait
  python3 tool/classe_minuscule.py --ecrire   # ecrit, puis slang, build_runner, tests
"""
import json
import re
import sys

FICHIER = 'assets/i18n/fr.i18n.json'
# Une valeur : « "cle": "texte" » ou une ligne de liste « "texte" ».
LIGNE = re.compile(r'^(\s*(?:"(?:[^"\\]|\\.)*"\s*:\s*)?")((?:[^"\\]|\\.)*)("\s*,?\s*)$')
MOT = re.compile(r'\bClasse(s?)\b')
# Debut de phrase : debut de la valeur, ou apres . ! ? : « » et des espaces
# (l'espace insecable s'ecrit   dans le fichier).
DEBUT = re.compile(r'(^|[.!?:«»]((\s|\\u00a0|\\u202f)*)|\\n)$')


EXCLUES = ('juridique.', 'contrat.politique.',
           # Parcours du candidat : majuscule (reponse du directeur du 22/10/2026,
           # test libelles_parcours_test ; garde-cap, 06/11).
           'recrutement.parcours.', 'recrutement.questionnaire.')
OUVRE = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*:\s*[\[{]\s*$')
FERME = re.compile(r'^\s*[\]}]')


def traiter(valeur):
    sorties, changes, pos = [], 0, 0
    for m in MOT.finditer(valeur):
        avant = valeur[:m.start()]
        sorties.append(valeur[pos:m.start()])
        if (DEBUT.search(avant.rstrip(' ')) or avant == ''
                or avant.endswith('Espace ')):
            sorties.append(m.group(0))
        else:
            sorties.append('classe' + m.group(1))
            changes += 1
        pos = m.end()
    sorties.append(valeur[pos:])
    return ''.join(sorties), changes


def main():
    ecrire = '--ecrire' in sys.argv
    lignes = open(FICHIER, encoding='utf-8').read().split('\n')
    total, cles = 0, 0
    pile = []
    for i, ligne in enumerate(lignes):
        o = OUVRE.match(ligne)
        if o:
            pile.append(o.group(1))
            continue
        if FERME.match(ligne):
            if pile:
                pile.pop()
            continue
        chemin = '.'.join(pile) + '.'
        if chemin.startswith(EXCLUES):
            continue
        m = LIGNE.match(ligne)
        if not m or 'Classe' not in m.group(2):
            continue
        nouvelle, n = traiter(m.group(2))
        if n:
            total += n
            cles += 1
            print(f'{i + 1}: {m.group(2)}\n   -> {nouvelle}')
            lignes[i] = m.group(1) + nouvelle + m.group(3)
    texte = '\n'.join(lignes)
    json.loads(texte)  # le fichier reste du JSON valide
    print(f'{cles} lignes, {total} remplacements')
    if ecrire:
        open(FICHIER, 'w', encoding='utf-8').write(texte)
        print('ecrit ; ensuite : dart run slang ; dart run build_runner build '
              '--delete-conflicting-outputs ; tests qui citent ces phrases '
              '(grep -rn "Classe" test) ; tool/libelles_sources.json si '
              'verifier_revue signale libelle-sans-source')


if __name__ == '__main__':
    main()
