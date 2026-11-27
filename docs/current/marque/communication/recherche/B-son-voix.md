# B. Son et voix pour les vidéos courtes de Rewayah Academy

Recherche du 27/11/2026. Machine d'essai : conteneur Linux, 4 cœurs, 15 Go, sans carte graphique, Python 3.13, ffmpeg 6.1.1.

## 0. Ce qui n'est pas prouvé (à lire en premier)

- **Je n'entends pas le son.** Tous les essais ci-dessous prouvent qu'un outil tourne ici et en combien de temps. Aucun ne prouve que le résultat sonne « agence ». Seule l'oreille du directeur tranche. Les fichiers à écouter sont listés au §6.
- **L'arabe par voix de synthèse n'est pas validé.** Deux moteurs le produisent ici, mais personne n'a vérifié la prononciation. Pour une académie de Coran, une faute d'arabe coûte cher. Jamais de récitation, de verset ni de formule religieuse en voix de synthèse.
- **Aucune plateforme (TikTok, Instagram) ne publie de cible officielle de volume.** Le « -14 LUFS » est une convention de métier, pas une règle écrite par elles.
- **Les règles de métier du §1 ne sont pas attribuées à Buck, Oddfellows ou aux publicités Apple.** Je n'ai trouvé aucune source primaire qui décrive leur méthode. Ce sont des pratiques courantes du métier telles que je les connais, avec des chiffres de départ que je propose sans source, plus trois principes publiés par Apple pour ses interfaces.
- **La zone grise religieuse reste à trancher par le directeur** : un son à hauteur définie fabriqué sans instrument (§3.3), et l'audit de chaque fichier de banque (§2.4).
- Licences non vérifiées jusqu'au bout : voix arabe de Piper (§4.2), licence « effets sonores » de Mixkit, téléchargement par script chez Kenney et Pixabay.

Légende : **[L]** licence lue à la source · **[T]** testé ici · **[NV]** non vérifié.

---

## 1. Le métier : ce qui fait un son haut de gamme

### 1.1 Références

- Apple, « Designing Audio-Haptic Experiences » (WWDC 2019), trois principes : **causalité** (on doit comprendre ce qui a causé le son ; se demander quel bruit ferait l'objet s'il était réel), **harmonie** (ce qu'on voit, ce qu'on entend et ce qu'on ressent vont ensemble), **utilité** (n'ajouter un son que s'il apporte quelque chose). https://developer.apple.com/videos/play/wwdc2019/810/ (résumé : https://wwdcnotes.com/documentation/wwdc19-810-designing-audiohaptic-experiences/)
- Sono Sanctus (Wesley Slover, studio de son pour le motion design, clients Google, Airbnb) : étude de cas piste par piste, 85 minutes. Devise du studio : « Don't let audio be an afterthought ». À écouter par celui qui fera le son. https://schoolofmotion.com/blog/sono-sanctus-podcast-podcast et https://motionhatch.com/animation-sound-design-music
- Autres noms à écouter comme modèles (non étudiés ici) : Antfood, Ambrose Yu, Echoic Audio.

### 1.2 Règles concrètes (pratiques courantes du métier ; les chiffres sont mes valeurs de départ, sans source, à valider à l'oreille)

1. **Le son se décide avec l'animation, pas après.** Chaque son part d'une image clé précise. Tolérance : une image (33 ms à 30 i/s). Un son en retard se voit ; un son en avance de 1 à 2 images passe souvent mieux.
2. **Un bon effet = 2 à 4 couches, chacune avec un rôle.** Attaque (clic, choc court, 5 à 30 ms), corps (la matière : bois, air, tissu), queue (résonance, pièce). Un son de banque posé seul sonne « banque » ; c'est le défaut des vidéos IA.
3. **Le « whoosh » suit la courbe du mouvement.** Son pic tombe sur le pic de vitesse ou sur l'arrivée, pas au départ. Montée lente, chute rapide. Longueur = longueur du mouvement.
4. **La retenue.** Tout mouvement n'a pas un son. 3 à 6 événements sonores marqués par 10 secondes au plus ; le reste est porté par l'ambiance. Le silence avant un moment fort le rend plus fort (couper l'ambiance 150 à 300 ms avant l'ouverture de la porte).
5. **Une ambiance de fond continue (room tone)**, très basse (-40 à -50 dB), pour que la voix ne flotte pas dans le vide et que les coupes ne s'entendent pas.
6. **Une seule famille de matières par vidéo, la même d'une vidéo à l'autre.** Bois, pierre, air, souffle : c'est ce qui crée une signature. La porte de l'arche doit avoir **le même son à chaque fois** (comme un logo sonore).
7. **La voix passe devant tout.** Les effets baissent de 4 à 8 dB quand la voix parle (ducking), et on creuse 2 à 4 kHz dans les effets pour laisser la place aux consonnes.
8. **Mixer pour le téléphone.** Haut-parleur de téléphone : presque rien sous 200 Hz. Un choc grave doit avoir une couche médium (300 à 800 Hz) sinon il disparaît. Vérifier en mono. Écouter le rendu final sur un téléphone, dans l'application.
9. **Praxis a ses propres sons.** Petits mouvements = sons courts, doux, aigus (souffle, frottement léger), cohérents avec sa taille et sa matière. Même jeu de 5 à 8 sons réutilisés.
10. **Jamais de son « dessin animé » de banque** (boing, pop synthétique, cloche de notification) : c'est le marqueur du contenu bas de gamme, et souvent un instrument.

### 1.3 Volume

- Cible de métier : **-14 LUFS intégré, crête vraie ≤ -1 dBTP**, plage acceptable -16 à -12. Source (non officielle, et qui le dit elle-même) : « TikTok does not publish an official loudness target […] −14 LUFS and a −1 dBTP ceiling are practical targets, not platform rules » https://magicmaster.pro/blog/tiktok-mastering-loudness
- Voix seule avant mixage : -16 LUFS, puis le mixage final à -14.
- WhatsApp recompresse fort : livrer en AAC 256 kb/s, 48 kHz, et garder 1 dB de marge de crête.
- Mesure et réglage en deux passes avec `loudnorm` de ffmpeg **[T]** (§5).

---

## 2. Banques d'effets sonores gratuites et utilisables pour un usage commercial

| Source | Licence (lue à la source) | Compte ? | Par script ? | Verdict |
| :-- | :-- | :-- | :-- | :-- |
| **Sonniss GameAudioGDC** | **[L]** Licence 2.0 du 27/08/2026 : usage commercial, sans crédit, projets illimités. Interdits : redistribuer les fichiers (même modifiés), entraîner une IA. https://sonniss.com/gdc-bundle-license/ | Non (liens directs et torrents officiels) **[NV par script]** | Oui en principe | **Sûr. Meilleure qualité** (enregistrements professionnels). Des dizaines de Go par année : ne prendre qu'une année. **Ne jamais mettre les fichiers bruts dans un dépôt partagé.** |
| **OpenGameArt, filtre CC0** | CC0 par page (à vérifier sur chaque page) | Non | **[T]** Oui : téléchargement direct réussi (HTTP 200) | Sûr si la page dit CC0. Qualité inégale. |
| **Kenney** | **[L]** « all game assets […] are public domain licensed (CC0) […] even in commercial projects » https://kenney.nl/support | Non | **[NV]** lien du zip non trouvé par script dans la page | Sûr. Sons d'interface et de chocs, propres mais « jeu vidéo ». |
| **Freesound, filtre CC0** | CC0 par son | **Oui.** Clé d'API obligatoire même pour chercher ; OAuth2 pour les fichiers d'origine ; seuls les aperçus MP3 se téléchargent avec la clé simple. https://freesound.org/docs/api/overview.html | Oui, avec compte | Sûr (CC0 seulement, pas CC-BY-NC). Demande au directeur d'ouvrir un compte gratuit. Plus grand choix. |
| **Pixabay** | **[L, résumé seulement ; le texte complet n'a pas été lu]** Usage gratuit, sans crédit, modification permise ; interdit de revendre tel quel ou d'en faire une marque. https://pixabay.com/service/license-summary/ | Téléchargement sans compte **[NV]** | **Non** : l'API officielle ne couvre que les images et les vidéos, et interdit le téléchargement en masse. https://pixabay.com/api/docs/ | Sûr côté licence, mais téléchargement à la main. Beaucoup de sons générés par IA et de sons avec instruments. |
| **Mixkit** | Licence « Sound Effects Free License », commercial permis selon le site **[NV : texte complet non lu]** https://mixkit.co/license/ | Non | **[NV]** | Probable, à lire avant usage. |
| **Wikimedia Commons** | Par fichier (CC0, CC-BY…) | Non | **[NV]** l'API n'a pas répondu en JSON depuis ce conteneur | Possible, peu de choix. |
| **BBC Sound Effects** | **[L] INTERDIT.** « For non-commercial, personal or research purposes » ; usage commercial ou par une organisation à but non lucratif = permission payante ; et « no uploading to social media sites ». https://sound-effects.bbcrewind.co.uk/licensing | | | **À exclure.** |

### 2.4 Contrainte religieuse sur les banques

Les fichiers nommés « whoosh », « riser », « shimmer », « magic », « cinematic », « transition » contiennent très souvent des carillons, cloches, cordes, nappes de synthétiseur ou cymbales inversées. **Chaque fichier de banque doit être écouté et accepté par une personne avant d'entrer dans la bibliothèque de l'académie.** Les catégories sûres par nature : portes, bois, pierre, tissu, pas, air, vent, eau, feu, papier, ambiances de pièce. Tenir un fichier `sons-acceptes.csv` (fichier, source, licence, écouté par, date).

---

## 3. Effets fabriqués sur cette machine

### 3.1 Modèles d'IA « texte vers son »

| Modèle | Licence des poids | Verdict |
| :-- | :-- | :-- |
| AudioGen (Meta, AudioCraft) | **[L]** CC-BY-NC 4.0 https://hf.co/facebook/audiogen-medium | **Exclu** (non commercial). |
| AudioLDM2 | **[L]** CC-BY-NC-SA 4.0 https://hf.co/cvssp/audioldm2 | **Exclu.** |
| TangoFlux | Aucune licence déclarée sur la page **[NV]** https://hf.co/declare-lab/TangoFlux | Exclu tant que non clarifié. |
| Stable Audio Open 1.0 et Small | **[L]** Stability AI Community License : commercial permis sous 1 M$ de chiffre d'affaires annuel, **avec inscription obligatoire auprès de Stability AI**, et modèle « gated » (compte Hugging Face et acceptation des conditions). https://stability.ai/license https://hf.co/stabilityai/stable-audio-open-1.0 | Utilisable légalement, mais demande un compte et une inscription. Version 1.0 (1,2 milliard de paramètres) très lente sans carte graphique ; version Small annoncée pour processeur (10 s de son en environ 7 s sur processeur Arm, selon Arm) **[NV ici]**. Entraîné aussi sur de la musique : peut sortir des sons instrumentaux. **Non recommandé en premier.** |

Avis de métier : ces modèles donnent exactement le son « générique d'IA » que le directeur rejette. À garder comme source de matière brute à retravailler, pas comme effet final.

### 3.2 Synthèse procédurale **[T]**

Script d'essai : `/tmp/claude-0/-home-user-Rewayah-Academy-Official-App/250ae9e7-8a6b-5e50-b765-052d5cb2c173/scratchpad/essais/sfx_proc.py` (numpy et scipy seuls, licences BSD). **Cinq sons générés en 0,15 seconde** :

- whoosh : bruit filtré dont la fréquence glisse, pic à 70 % de la durée, déplacement stéréo ;
- porte lourde : grincement par impulsions « colle-glisse » dans des résonances de bois, puis choc grave avec couche médium ;
- lumière, version sans hauteur : souffle d'air aigu qui s'ouvre et grains scintillants de bruit ;
- lumière, version à hauteur définie (zone grise, voir 3.3) ;
- ambiance de pièce : bruit brun très bas.

Avantage : 100 % à nous, aucune licence, paramétrable à l'image près (durée = durée du mouvement), signature reproductible. Limite : un son purement synthétique sonne vite « propre et froid ». **La bonne pratique est de superposer : corps enregistré (banque) + mouvement procédural.** Qualité non jugée (je n'entends pas).

Autres outils, licences citées de mémoire **[NV]** : sfxr / jsfxr (libre, sons 8 bits de jeu rétro : **à éviter**, hors du ton). Csound (LGPL), SuperCollider (GPL-3), pyo (LGPL) : plus puissants, non installés ici ; inutiles tant que numpy suffit.

### 3.3 Zone grise à trancher par le directeur

Fichier `sfx_lumiere_tonale_ZONE_GRISE.wav` : du bruit passé dans des résonateurs accordés. Aucun instrument, mais l'oreille entend une note tenue, proche d'une nappe de synthétiseur. Trois réponses possibles, du plus sûr au moins sûr :

1. **Sans hauteur** : air, souffle, grain (`sfx_lumiere_air.wav`). Aucun doute.
2. **Voix humaine** : un « ah » ou un souffle enregistré par une personne, étiré 8 fois et réverbéré. Matière humaine, donc dans le cadre permis ; mais le résultat peut ressembler à une nappe musicale. **Attention : le fichier d'essai `sfx_nappe_vocale.wav` (0,07 s de calcul [T]) part d'un morceau de parole de synthèse (Kokoro), pas d'une voix humaine.** Il montre le procédé seulement ; pour décider, il faut refaire l'essai avec une vraie voix tenue.
3. **Tonal synthétique** : à n'utiliser que si le directeur l'autorise explicitement.

Recommandation : construire la signature de la porte et de la lumière sur 1 et 2, et faire écouter 3 au directeur une seule fois pour décision écrite. L'option 2 est à refaire avec une vraie voix avant de la lui présenter.

---

## 4. Voix

### 4.1 Voix enregistrée du directeur : nettoyage **[T]**

Essai sur une voix bruitée artificiellement (8,3 s) :

| Outil | Licence | Temps mesuré |
| :-- | :-- | :-- |
| ffmpeg `afftdn` + égalisation + dé-esseur + compresseur | ffmpeg (LGPL/GPL) | 0,08 s |
| ffmpeg `arnndn` (RNNoise) avec modèle `sh.rnnn` | modèles déclarés hors droit d'auteur par leur auteur https://github.com/GregorR/rnnoise-models | 0,12 s |
| **DeepFilterNet** (binaire `deep-filter` 0.5.6, sans Python) | **[L]** code et poids MIT ou Apache-2.0 au choix https://github.com/Rikorose/DeepFilterNet | 3,1 s (48 kHz obligatoire) |

Recommandation : **DeepFilterNet d'abord** (le plus propre sur bruit de pièce, d'après la littérature ; non jugé à l'oreille ici), `afftdn` en secours. Puis : passe-haut 80 Hz, -2 dB à 250 Hz, +2,5 dB à 3,5 kHz, dé-esseur, compresseur 3:1, `loudnorm` en deux passes à -16 LUFS (mesuré : -16,0 LUFS, crête -1,5 dB **[T]**). Le nettoyage ne rattrape pas une mauvaise prise : micro à 15 cm, pièce avec tissus, pas d'écho.

### 4.2 Voix de Praxis par synthèse

| Moteur | Licence code / poids | FR | EN | AR | Sur ce processeur |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **Supertonic 3** (Supertone) | **[L]** code MIT ; poids **OpenRAIL-M** : commercial permis, **avec obligation de dire que le contenu est généré par une machine** (annexe A, point e) https://hf.co/Supertone/supertonic-3 | oui | oui | oui | **[T]** 0,15 à 0,19 s de calcul par seconde de son ; 10 voix fixes ; 44,1 kHz ; 386 Mo ; aucun compte |
| **Kokoro-82M** | **[L]** poids Apache-2.0 https://hf.co/hexgrad/Kokoro-82M ; `kokoro-onnx` MIT **[NV : les métadonnées du paquet installé ne déclarent pas de licence]** ; phonétiseur espeak-ng GPL-3 **[NV]** (outil) | oui (1 seule voix) | oui (28 voix) | **non** | **[T]** 0,20 à 0,22 ; 24 kHz |
| **Piper** (`piper-tts` 1.8.0) | **[L]** code GPL-3 (outil ; les sons produits ne sont pas touchés) ; **licence par voix** : FR `siwis` CC-BY 4.0 (crédit à donner) ; AR `kareem` : la fiche du modèle dit seulement « License: See URL » **[L]** ; d'après les titres des résultats de recherche, le dépôt source a deux demandes de clarification de licence (je n'ai pas pu ouvrir ces pages) **[NV]** | oui | oui | oui mais **licence incertaine** | **[T]** 0,1 ; 22 kHz, qualité moyenne |
| Chatterbox Multilingual | **[L]** MIT, 23 langues dont AR et FR https://hf.co/ResembleAI/chatterbox | oui | oui | oui | **Non testé ici [NV].** Selon un seul article tiers : projet arrêté depuis août 2026, filigrane inaudible dans chaque fichier, 1,9 s de calcul par seconde de son pour le plus petit modèle (anglais seul, autre machine). Le modèle multilingue n'a été mesuré par personne ici. https://www.socialvik.com/blog/chatterbox-tts-cpu-commercial-use |
| pocket-tts (Kyutai) | CC-BY 4.0, modèle « gated » | oui | oui | non | **[NV]** |
| MeloTTS / OpenVoice V2 | MIT | oui | oui | non | **[NV]** |
| Parler-TTS mini v1 | Apache-2.0 | non (anglais) | oui | non | **[NV]** |
| **XTTS-v2 (Coqui)** | **[L] CPML : « allows only non-commercial use of a machine learning model and its outputs »** https://hf.co/coqui/XTTS-v2 | | | | **Exclu.** |
| **F5-TTS**, **Habibi-TTS** (arabe) | **[L]** CC-BY-NC 4.0 / CC-BY-NC-SA 4.0 | | | | **Exclus.** |
| **MMS-TTS arabe** (Meta), **SpeechT5 ClArTTS** | **[L]** CC-BY-NC 4.0 | | | | **Exclus.** |
| OmniVoice | CC-BY-NC d'après un tiers **[NV]** | | | | Exclu par prudence. |
| StyleTTS2 | Code MIT ; poids avec conditions propres **[NV]** | | | | Inutile : Kokoro en dérive. |

**Seul Supertonic 3 couvre le français, l'anglais et l'arabe, avec usage commercial, testé sur ce processeur.** Deux réserves : la mention « voix générée par IA » devient obligatoire (cohérent avec Praxis, qui est un assistant IA) ; l'arabe non vocalisé peut être mal lu **[NV]**, donc écrire le texte arabe avec ses voyelles et le faire écouter par un arabophone.

### 4.3 Voix de Praxis par une personne, transformée (recommandé)

Une personne joue Praxis au micro ; on déplace la hauteur et le timbre pour en faire une voix de personnage. C'est la seule voie qui couvre les trois langues par construction, avec un jeu d'acteur réel et un arabe juste.

- ffmpeg `rubberband` : +5 demi-tons, timbre conservé ou déplacé : **0,2 s pour 8,3 s de son [T]**. (Bibliothèque Rubber Band : GPL **[NV]**, outil.)
- `pedalboard` (Spotify, GPL-3 d'après les métadonnées du paquet installé, outil) : chaîne passe-haut, hauteur +4, brillance, compresseur, petite pièce, limiteur : **0,12 s [T]**.
- Réglages de départ pour une petite boule ronde et douce (proposition, non jugée à l'oreille) : +3 à +5 demi-tons, débit +5 %, petite réverbération courte, toujours la même. Le filtre `rubberband` de ffmpeg n'offre que deux réglages de timbre, `preserved` (timbre gardé, voix naturelle plus aiguë) et `shifted` (timbre monté avec la hauteur, effet « écureuil ») : les deux ont été testés. Un déplacement partiel du timbre demanderait un autre outil **[NV]**.
- Conversion de voix par IA (non testée) : Seed-VC (GPL-3), OpenVoice V2 (MIT). À n'envisager que si le déplacement simple ne suffit pas.

Les fichiers `vc_*.wav` de l'essai partent d'une voix de synthèse, pas d'une vraie prise : ils montrent le traitement, pas le résultat final.

### 4.4 Bouche de Praxis : Rhubarb Lip Sync

- **[L]** MIT, « including the creation of commercial software » ; les données produites « belong to you alone ». https://github.com/DanielSWolf/rhubarb-lip-sync/blob/master/LICENSE.md
- **[T]** Binaire Linux 1.14.0, aucune installation. Sortie JSON : une forme de bouche (A à H, X = fermée) avec début et fin.
  - anglais, reconnaissance par défaut : 5,5 s pour 7,2 s de son, 46 formes ;
  - français, option `-r phonetic` : 1,1 s pour 8,3 s, 56 formes ;
  - arabe, option `-r phonetic` : 1,1 s pour 8,8 s, 58 formes.
- La reconnaissance par défaut ne connaît que l'anglais ; **pour le français et l'arabe, toujours `-r phonetic`**. Praxis n'a qu'une bouche simple : réduire les 9 formes à 3 ou 4 (fermée, entrouverte, ouverte, ronde) et lisser (pas de forme de moins de 2 images).
- Rappel de la compétence `praxis-rewayah` : seuls la bouche et les membres s'ajoutent ; les yeux ne changent jamais.

---

## 5. Chaîne recommandée (modèle de commandes ; les mêmes filtres ont tourné ici avec des valeurs voisines, le bloc n'a pas été rejoué mot pour mot)

```bash
# 0. Environnement (aucune installation système)
python3 -m venv venv && venv/bin/pip install supertonic kokoro-onnx soundfile numpy scipy pedalboard

# 1. Voix du directeur : débruitage puis traitement puis -16 LUFS
deep-filter -o propre/ prise48k.wav
ffmpeg -i propre/prise48k.wav -af "highpass=f=80,equalizer=f=250:t=q:w=1.2:g=-2,equalizer=f=3500:t=q:w=1.5:g=2.5,deesser=i=0.4,acompressor=threshold=-20dB:ratio=3:attack=8:release=120:makeup=3" voix_pre.wav
ffmpeg -i voix_pre.wav -af loudnorm=I=-16:TP=-1.5:LRA=7:print_format=json -f null -   # passe 1 : mesure
ffmpeg -i voix_pre.wav -af "loudnorm=I=-16:TP=-1.5:LRA=7:measured_I=..:measured_TP=..:measured_LRA=..:measured_thresh=..:offset=..:linear=true" -ar 48000 voix.wav

# 2a. Praxis, prise humaine transformée
ffmpeg -i praxis_prise.wav -af "rubberband=pitch=1.26:formant=preserved:pitchq=quality" praxis.wav
# 2b. Praxis, synthèse (brouillon, ou si personne n'enregistre)
python -c "from supertonic import TTS; t=TTS(); s=t.get_voice_style(voice_name='F1'); w,d=t.synthesize('Bonjour.',voice_style=s,lang='fr'); t.save_audio(w,'praxis.wav')"

# 3. Bouche
ffmpeg -i praxis.wav -ar 16000 -ac 1 praxis16.wav
rhubarb -r phonetic -f json -o praxis_bouche.json praxis16.wav

# 4. Effets : banque acceptée (Sonniss, CC0) + couches procédurales (sfx_proc.py), calés à l'image avec adelay

# 5. Mixage : effets baissés sous la voix, limiteur, puis -14 LUFS / -1 dBTP, AAC 256 kb/s
ffmpeg -i voix.wav -i ambiance.wav -i whoosh.wav -i porte.wav -filter_complex "
 [0:a]aformat=channel_layouts=stereo,asplit=2[vx][vsc];
 [2:a]adelay=200:all=1[w];[3:a]adelay=2500:all=1[d];
 [1:a][w][d]amix=inputs=3:duration=longest:normalize=0[fx];
 [fx][vsc]sidechaincompress=threshold=0.03:ratio=5:attack=15:release=250[fxd];
 [vx][fxd]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.89[m]" -map "[m]" mix.wav
ffmpeg -i mix.wav -af "loudnorm=I=-14:TP=-1:LRA=9" -ar 48000 -c:a aac -b:a 256k final.m4a   # une passe testée ici ; deux passes (comme en 1) sont plus précises
```

Mesure du mixage d'essai : **-14,1 LUFS, crête -2,7 dB [T]**, calcul 0,1 s.

### Classement

**Effets sonores**
1. Banque Sonniss GDC (corps des sons) + couches procédurales numpy (mouvement), fichiers audités un par un.
2. CC0 d'OpenGameArt et Kenney en complément ; Freesound CC0 si le directeur ouvre un compte.
3. Stable Audio Open Small : seulement comme matière brute, après inscription.
Exclus : BBC, AudioGen, AudioLDM2, sfxr.

**Voix de Praxis**
1. Personne au micro + hauteur et timbre déplacés (ffmpeg `rubberband` ou `pedalboard`).
2. Supertonic 3 : seul moteur FR + EN + AR commercial qui tourne ici ; mention « voix générée par IA » obligatoire ; arabe à faire valider.
3. Kokoro-82M : français et anglais seulement, licence la plus simple (Apache-2.0).
Exclus par leur licence : XTTS, F5-TTS, Habibi, MMS. Écarté par prudence : Piper arabe (licence incertaine). Non testé, écarté pour l'instant sur la foi d'un article tiers : Chatterbox Multilingual (MIT, FR + EN + AR) ; à essayer si Supertonic déçoit à l'oreille.

**Voix du directeur** : DeepFilterNet, puis chaîne ffmpeg, -16 LUFS.
**Bouche** : Rhubarb, option `phonetic`.
**Volume final** : -14 LUFS, -1 dBTP, vérifié en mono et sur téléphone.

---

## 6. Fichiers à écouter

Dossier : `/tmp/claude-0/-home-user-Rewayah-Academy-Official-App/250ae9e7-8a6b-5e50-b765-052d5cb2c173/scratchpad/essais/sorties/`

- Voix de synthèse : `supertonic_fr_F1.wav`, `supertonic_en_F1.wav`, `supertonic_ar_F1.wav` (et `_M1`), `kokoro_fr.wav`, `kokoro_en.wav`, `piper_ar.wav`, `piper_fr.wav`
- Transformation de voix : `vc_pitch_formant_preserve.wav`, `vc_pitch_formant_shift.wav`, `vc_pedalboard.wav`
- Nettoyage : `voix_bruitee.wav` → `voix_nettoyee.wav`, `voix_rnnoise.wav`, `df/voix_bruitee48.wav`
- Effets procéduraux : `sfx_whoosh.wav`, `sfx_porte.wav`, `sfx_lumiere_air.wav`, `sfx_lumiere_tonale_ZONE_GRISE.wav`, `sfx_roomtone.wav` ; `sfx_nappe_vocale.wav` (faite à partir de parole de synthèse, pas d'une voix humaine)
- Mixage d'essai : `mix_demo_-14LUFS.m4a`
- Bouche : `rhubarb_fr.json`, `rhubarb_en.json`, `rhubarb_ar.json`

Ce dossier est temporaire : il disparaît avec la session. Rien n'a été installé dans le système ni écrit dans le dépôt.

## 7. Décisions à demander au directeur

1. Son à hauteur définie sans instrument : permis ou non ? (écouter les trois versions de la lumière)
2. Voix de Praxis : qui l'enregistre ? Sinon, accepte-t-il une voix de synthèse avec la mention « voix générée par IA » ?
3. Arabe en voix de synthèse : permis pour Praxis, ou voix humaine seulement ?
4. Ouvrir un compte Freesound gratuit (clé d'API) : oui ou non ?
5. Qui écoute et accepte chaque son de banque avant son entrée dans la bibliothèque ?
