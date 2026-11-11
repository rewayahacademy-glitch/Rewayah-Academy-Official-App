# Banc d'essai de la salle

De vraies séances sur une pile **locale** : la vraie application, un vrai serveur LiveKit, un
navigateur par participant, un réseau qu'on abîme à la demande, et la mesure de ce que chacun
entend. Rien n'écrit en production, rien ne sort de la machine.

Mission et raisons : `docs/current/CAHIER-SALLE.md`, `docs/current/salle/JOURNAL-DECISIONS.md` (D-002).

## Mise en route

```
tool/e2e/pile.sh            # Supabase local, fonctions Edge, LiveKit, application (voir tool/e2e/README.md)
tool/salle/banc.sh          # met LiveKit derrière le relais qui abîme le réseau
node tool/salle/mesure_voix.mjs <etiquette> --sens=ens-eleve     # l'élève écoute l'enseignant
node tool/salle/mesure_voix.mjs <etiquette> --sens=eleve-ens     # l'enseignant écoute l'élève
```

Prérequis en plus de ceux de `tool/e2e/` :

- `iptables` (le banc ferme le chemin direct entre LiveKit et le navigateur) ;
- pour noter le son : un Python avec `numpy scipy soundfile pystoi jiwer faster-whisper`
  (`BANC_PYTHON`, défaut `/opt/banc-audio/venv/bin/python`), `ffmpeg`, et le modèle de
  reconnaissance converti une fois (`BANC_MODELE`, défaut `/opt/banc-audio/whisper-quran-ct2`) :
  `ct2-transformers-converter --model tarteel-ai/whisper-base-ar-quran --output_dir <dossier> --quantization int8` ;
- une récitation d'essai en WAV mono 48 kHz (`BANC_RECITATION`). **Elle n'est pas dans le dépôt** :
  on y met une récitation dont on a les droits.

## Les fichiers

| Fichier | Rôle |
| :-- | :-- |
| `banc.sh` | Relance LiveKit dans un conteneur dont le média n'est joignable que par le relais ; pose la règle de pare-feu ; lance le relais. |
| `reseau_degrade.mjs` | Le relais UDP. Par flux et par sens : pertes (en rafales, modèle de Gilbert-Elliott), latence, gigue, plafond de débit, coupure. Piloté par HTTP local (`/flux`, `/profil`). Écrit pour ce banc parce que le noyau de la machine de test n'a pas `netem`. |
| `amorce.mjs` | Crée en SQL local une classe de N élèves et sa séance en cours (données fictives, préfixe E2E). |
| `banc.mjs` | Un participant = un navigateur Chromium (micro factice qui lit un fichier, caméra factice). Un crochet lit les statistiques WebRTC et enregistre le son **reçu**, après reconstruction, donc tel qu'il sort du haut-parleur. |
| `mesure_voix.mjs` | Le scénario « comprend-on chaque mot ? » : une séance, un qui récite, un qui écoute sous huit réseaux (parfait ; 10, 20, 30 % de pertes, indépendantes ou en rafales ; 300 ms de latence ; 3G). |
| `micro_avant_enseignant.mjs` | La règle de sécurité D-008 (défaut SEC-1) prouvée par les vraies fonctions Edge et le vrai LiveKit : un élève seul ne peut pas ouvrir son micro (le serveur refuse), l'enseignant entre, il le peut. Participants légers (page nue, comme `robots.mjs`). `SANS_WEBHOOK=1` essaie le filet quand le webhook de LiveKit est coupé. |
| `mesure_audio.py` | La note d'un enregistrement : mots perdus ou changés (reconnaissance de la récitation, modèle Whisper affiné par Tarteel), intelligibilité ESTOI et son pire passage, trous. |

## Lire un résultat

Pour chaque réseau, une ligne :

- **mots perdus ou changés** (WER) : 0 = chaque mot de la récitation est reconnu comme dans
  l'original ; 0,10 = un mot sur dix est perdu ou changé ;
- **ESTOI** : intelligibilité objective, de 0 à 1 ; « pire » est le plus mauvais passage de 10 s ;
- **son reconstruit** : part du son que le navigateur a dû inventer pour boucher un trou
  (statistique WebRTC `concealedSamples / totalSamplesReceived`). C'est la mesure que l'application
  peut lire en direct chez chaque participant ;
- **pertes** : paquets audio perdus après les mécanismes de rattrapage.

## Limites

- Un seul poste : ni la distance réelle entre pays, ni les vrais téléphones. Le banc prouve le
  comportement de l'application sous un réseau donné ; la preuve finale reste celle du directeur,
  en production.
- Le « téléphone » est un écran tactile de 390 points avec un agent de navigateur d'ordinateur
  (avec un agent mobile, Flutter n'allume l'arbre d'accessibilité que par un vrai toucher).
- Ne rien lancer de lourd sur la machine pendant un enregistrement : un processeur saturé hache le
  son et fausse la mesure. Le réseau « parfait » sert de témoin (son reconstruit proche de 0).
