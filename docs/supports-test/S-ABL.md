# S-ABL - Les ablutions (al-wudû')

> **ÉCHANTILLON DE TEST - à relire avant usage réel**

- Support : `S-ABL`, 4 pages. Étape : PED-SUPPORTS (supports de test, pas la version finale).
- Public : enfants et adultes débutants, voie d'Ahl as-Sunna. Contenu limité aux actes qui font consensus et aux sunna courantes ; là où les écoles divergent, une ligne « Divergence » le signale sans trancher.
- Numérotation : chaque ligne porte `S-ABL / p.N / l.M` (support, page, ligne). La ligne 1 de chaque page est son titre. Une référence cite toujours les trois éléments, par exemple « S-ABL / p.2 / l.4 ».
- Texte coranique : copié depuis `supabase/migrations/0013_corpus_coranique.sql` (Tanzil Quran Text, Uthmani 1.1, CC BY 3.0, https://tanzil.net), jamais retapé ; le générateur refuse de rendre une ligne qui ne lui est pas identique caractère pour caractère. La ligne 5:6 est rendue en Uthman Taha Naskh et non en UthmanicHafs : cette police ne dessine pas le signe U+06DF du texte Tanzil (elle afficherait un cercle pointillé). Le texte n'est pas modifié, seule la police change.
- Références de hadith : numérotation courante (al-Bukhârî et Muslim selon Muhammad Fu'âd 'Abd al-Bâqî, les Sunan selon les éditions usuelles). Toutes sont à contrôler à la relecture.
- Rendu : `outils/generer.py` produit `rendu/S-ABL.pdf` et une image PNG par page.

Format des lignes : `### l.M | type`, puis des champs `clé: valeur` (ar = arabe vocalisé, tr = translittération, fr = traduction ou consigne, src = source, statut = obligatoire ou sunna, ref = sourate:verset du texte coranique).

## p.1 - Avant de commencer

### l.1 | titre
fr: Les ablutions (al-wudû') : avant de commencer

### l.2 | parole
ar: لَا تُقْبَلُ صَلَاةٌ بِغَيْرِ طُهُورٍ
tr: Lâ tuqbalu salâtun bi-ghayri tuhûr.
fr: « Aucune prière n'est acceptée sans purification. » Les ablutions se font avant la prière.
src: Muslim 224 (d'après Ibn 'Umar)

### l.3 | coran
ref: 5:6 mots 1-17
ar: يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓا۟ إِذَا قُمْتُمْ إِلَى ٱلصَّلَوٰةِ فَٱغْسِلُوا۟ وُجُوهَكُمْ وَأَيْدِيَكُمْ إِلَى ٱلْمَرَافِقِ وَٱمْسَحُوا۟ بِرُءُوسِكُمْ وَأَرْجُلَكُمْ إِلَى ٱلْكَعْبَيْنِ
tr: Yâ ayyuhal-ladhîna âmanû idhâ qumtum ilas-salâti fa-ghsilû wujûhakum wa aydiyakum ilal-marâfiqi wamsahû bi-ru'ûsikum wa arjulakum ilal-ka'bayn.
fr: « Ô vous qui croyez ! Lorsque vous vous levez pour la prière, lavez vos visages et vos mains jusqu'aux coudes, passez les mains mouillées sur vos têtes, et lavez vos pieds jusqu'aux chevilles. » (début du verset, traduction du sens)
src: Sourate Al-Mâ'ida 5:6

### l.4 | parole
ar: إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ
tr: Innamal-a'mâlu bin-niyyât.
fr: L'intention (an-niyya) : vouloir, dans son cœur, faire les ablutions pour Allah. « Les actes ne valent que par les intentions. »
src: al-Bukhârî 1 ; Muslim 1907 (d'après 'Umar ibn al-Khattâb)

### l.5 | divergence
fr: L'intention est une condition des ablutions pour les malikites, les chafiites et les hanbalites ; une sunna pour les hanafites. La prononcer à voix haute : les avis divergent ; elle a son siège dans le cœur.

### l.6 | parole
ar: بِسْمِ اللَّهِ
tr: Bismillâh.
fr: Au nom d'Allah. On le dit au début des ablutions.
src: Abû Dâwud 101 ; at-Tirmidhî 25 ; Ibn Mâja 399 (« Pas d'ablutions pour qui n'y mentionne pas le nom d'Allah »)

### l.7 | divergence
fr: Dire « Bismillâh » : obligatoire selon un avis connu chez les hanbalites ; sunna pour la majorité.

### l.8 | note
fr: On commence toujours par la droite, puis la gauche.
src: al-Bukhârî 168 ; Muslim 268 (d'après 'Â'isha)

### l.9 | note
fr: Laver une fois chaque membre suffit ; deux fois est permis ; trois fois est la sunna.
src: al-Bukhârî 157 (une fois), 158 (deux fois), 159 (trois fois)

## p.2 - Les gestes (1 à 4)

### l.1 | titre
fr: Les gestes, dans l'ordre (1 à 4)

### l.2 | geste
statut: sunna
ar: غَسْلُ الْكَفَّيْنِ
tr: Ghaslul-kaffayn.
fr: Geste 1 : laver les mains jusqu'aux poignets, trois fois.
src: al-Bukhârî 159 ; Muslim 226 (description de 'Uthmân ibn 'Affân)

### l.3 | illustration
fr: [Illustration à venir : geste 1, laver les mains jusqu'aux poignets]

### l.4 | geste
statut: sunna
ar: الْمَضْمَضَةُ وَالِاسْتِنْشَاقُ
tr: Al-madmada wal-istinshâq.
fr: Geste 2 : rincer la bouche, puis aspirer l'eau par le nez et la rejeter, trois fois.
src: al-Bukhârî 185 et 191 ; Muslim 235 (description de 'Abd Allâh ibn Zayd)

### l.5 | illustration
fr: [Illustration à venir : geste 2, rincer la bouche et le nez]

### l.6 | divergence
fr: Rincer la bouche et le nez : obligatoire chez les hanbalites ; sunna confirmée pour les autres écoles.

### l.7 | geste
statut: obligatoire
ar: غَسْلُ الْوَجْهِ
tr: Ghaslul-wajh.
fr: Geste 3 : laver le visage, du haut du front jusqu'au menton et d'une oreille à l'autre, trois fois.
src: Sourate Al-Mâ'ida 5:6 ; al-Bukhârî 159

### l.8 | illustration
fr: [Illustration à venir : geste 3, laver le visage]

### l.9 | geste
statut: obligatoire
ar: غَسْلُ الْيَدَيْنِ إِلَى الْمِرْفَقَيْنِ
tr: Ghaslul-yadayni ilal-mirfaqayn.
fr: Geste 4 : laver le bras droit, du bout des doigts jusqu'au coude compris, trois fois ; puis le bras gauche de la même façon.
src: Sourate Al-Mâ'ida 5:6 ; al-Bukhârî 159 ; Muslim 226

### l.10 | illustration
fr: [Illustration à venir : geste 4, laver les bras jusqu'aux coudes]

## p.3 - Les gestes (5 à 7)

### l.1 | titre
fr: Les gestes, dans l'ordre (5 à 7)

### l.2 | geste
statut: obligatoire
ar: مَسْحُ الرَّأْسِ
tr: Mashur-ra's.
fr: Geste 5 : passer les mains mouillées sur la tête, de l'avant jusqu'à la nuque, puis revenir à l'avant, une fois.
src: Sourate Al-Mâ'ida 5:6 ; al-Bukhârî 185 ; Muslim 235

### l.3 | illustration
fr: [Illustration à venir : geste 5, passer les mains sur la tête]

### l.4 | divergence
fr: Partie de la tête à essuyer : toute la tête (malikites, hanbalites), une partie (chafiites), le quart (hanafites).

### l.5 | geste
statut: sunna
ar: مَسْحُ الْأُذُنَيْنِ
tr: Mashul-udhunayn.
fr: Geste 6 : passer les index mouillés à l'intérieur des oreilles et les pouces derrière, une fois.
src: an-Nasâ'î 102 ; at-Tirmidhî 36 (d'après Ibn 'Abbâs)

### l.6 | illustration
fr: [Illustration à venir : geste 6, essuyer les oreilles]

### l.7 | divergence
fr: Les oreilles : sunna pour la majorité ; les hanbalites les rattachent à la tête et en font une obligation.

### l.8 | geste
statut: obligatoire
ar: غَسْلُ الرِّجْلَيْنِ إِلَى الْكَعْبَيْنِ
tr: Ghaslur-rijlayni ilal-ka'bayn.
fr: Geste 7 : laver le pied droit jusqu'aux chevilles comprises, trois fois, en passant entre les orteils ; puis le pied gauche. Aucun endroit, pas même le talon, ne doit rester sec.
src: Sourate Al-Mâ'ida 5:6 ; al-Bukhârî 159 ; « Malheur aux talons [négligés] : le Feu ! » al-Bukhârî 165 ; Muslim 242

### l.9 | illustration
fr: [Illustration à venir : geste 7, laver les pieds jusqu'aux chevilles]

### l.10 | divergence
fr: Respecter l'ordre des gestes (at-tartîb) : obligatoire chez les chafiites et les hanbalites, sunna chez les hanafites et les malikites. Enchaîner sans longue pause (al-muwâlât) : obligatoire chez les malikites et les hanbalites. Frotter les membres (ad-dalk) : obligatoire chez les malikites.

## p.4 - Après les ablutions

### l.1 | titre
fr: Après les ablutions : les invocations

### l.2 | parole
ar: أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ
tr: Ash-hadu an lâ ilâha illallâhu wahdahû lâ sharîka lah, wa ash-hadu anna Muhammadan 'abduhû wa rasûluh.
fr: J'atteste qu'il n'y a de divinité [digne d'adoration] qu'Allah, Seul, sans associé, et j'atteste que Muhammad est Son serviteur et Son messager.
src: Muslim 234 (d'après 'Umar ibn al-Khattâb : les huit portes du Paradis s'ouvrent pour celui qui le dit)

### l.3 | parole
ar: اللَّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ، وَاجْعَلْنِي مِنَ الْمُتَطَهِّرِينَ
tr: Allâhumma j'alnî minat-tawwâbîn, waj'alnî minal-mutatahhirîn.
fr: Ô Allah, place-moi parmi ceux qui se repentent souvent et place-moi parmi ceux qui se purifient.
src: at-Tirmidhî 55 (ajout à la parole de Muslim 234 ; at-Tirmidhî signale une faiblesse dans la chaîne, d'autres savants l'authentifient)

### l.4 | parole
ar: سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا أَنْتَ، أَسْتَغْفِرُكَ وَأَتُوبُ إِلَيْكَ
tr: Subhânakallâhumma wa bi-hamdik, ash-hadu an lâ ilâha illâ ant, astaghfiruka wa atûbu ilayk.
fr: Gloire à Toi, ô Allah, et louange à Toi. J'atteste qu'il n'y a de divinité que Toi. Je Te demande pardon et je me repens à Toi.
src: an-Nasâ'î, 'Amal al-yawm wa-l-layla, n° 81 (d'après Abû Sa'îd al-Khudrî ; numéro à vérifier)

### l.5 | note
fr: Aucune invocation particulière n'est établie pour chaque membre lavé ; on s'en tient aux paroles ci-dessus.
src: an-Nawawî, al-Adhkâr, chapitre des ablutions

### l.6 | note
fr: Ce qui annule les ablutions sera vu dans un autre support.
