# S-PRI - La prière (as-salât) : paroles et gestes

> **ÉCHANTILLON DE TEST - à relire avant usage réel**

- Support : `S-PRI`, 8 pages. Étape : PED-SUPPORTS (supports de test, pas la version finale).
- Exemple suivi : une prière de deux unités (rak'a), comme la prière de l'aube (al-fajr). Contenu limité aux actes qui font consensus et aux sunna courantes ; là où les écoles divergent, une ligne « Divergence » le signale sans trancher.
- Numérotation : chaque ligne porte `S-PRI / p.N / l.M` (support, page, ligne). La ligne 1 de chaque page est son titre.
- Texte coranique (Al-Fâtiha 1:1-7, Al-Ikhlâs 112:1-4) : copié depuis `supabase/migrations/0013_corpus_coranique.sql` (Tanzil Quran Text, Uthmani 1.1, CC BY 3.0, https://tanzil.net), jamais retapé ; le générateur refuse de rendre une ligne qui ne lui est pas identique caractère pour caractère. Seule transformation : le texte Tanzil de 112:1 commence par la basmala, qui n'appartient pas au verset ; elle est retirée de 112:1 et affichée sur sa propre ligne (texte identique à 1:1). Rien d'autre n'est modifié.
- Traductions du Coran : traductions du sens, rédigées pour ce support, à relire.
- Références de hadith : numérotation courante (al-Bukhârî et Muslim selon Muhammad Fu'âd 'Abd al-Bâqî, les Sunan selon les éditions usuelles). Toutes sont à contrôler à la relecture.
- Rendu : `outils/generer.py` produit `rendu/S-PRI.pdf` et une image PNG par page.

Format des lignes : `### l.M | type`, puis des champs `clé: valeur` (ar = arabe vocalisé, tr = translittération, fr = traduction ou consigne, src = source, statut = obligatoire ou sunna, ref = sourate:verset du texte coranique).

## p.1 - Debout : commencer la prière


### l.1 | titre
fr: Debout : commencer la prière

### l.2 | parole
ar: صَلُّوا كَمَا رَأَيْتُمُونِي أُصَلِّي
tr: Sallû kamâ ra'aytumûnî usallî.
fr: « Priez comme vous m'avez vu prier. » Avant de commencer : être en état d'ablutions (support S-ABL), couvert, tourné vers la Qibla, à l'heure de la prière.
src: al-Bukhârî 631 (d'après Mâlik ibn al-Huwayrith) ; Qibla : sourate Al-Baqara 2:144

### l.3 | geste
statut: obligatoire
fr: L'intention (an-niyya) : savoir dans son cœur quelle prière on accomplit (par exemple les deux unités de l'aube).
src: al-Bukhârî 1 ; Muslim 1907 (« Les actes ne valent que par les intentions »)

### l.4 | divergence
fr: Prononcer l'intention à voix haute : les avis divergent ; tous s'accordent qu'elle a son siège dans le cœur.

### l.5 | parole
statut: obligatoire
ar: اللَّهُ أَكْبَرُ
tr: Allâhu akbar.
fr: Allah est le plus Grand. C'est le takbîr d'entrée (takbîrat al-ihrâm) : on lève les mains à hauteur des épaules ou des oreilles en le disant.
src: « Elle s'ouvre par le takbîr et se clôt par le salut » Abû Dâwud 61 ; at-Tirmidhî 3 ; mains levées : al-Bukhârî 735 ; Muslim 390 (d'après Ibn 'Umar)

### l.6 | illustration
fr: [Illustration à venir : geste du takbîr d'entrée, mains levées]

### l.7 | geste
statut: sunna
fr: Poser la main droite sur la main gauche, debout, le regard vers le lieu de prosternation.
src: al-Bukhârî 740 (d'après Sahl ibn Sa'd)

### l.8 | illustration
fr: [Illustration à venir : position debout (al-qiyâm), main droite sur la main gauche]

### l.9 | divergence
fr: Les malikites, dans l'avis connu de l'école, laissent les bras le long du corps dans la prière obligatoire ; ceux qui posent les mains divergent sur l'endroit (poitrine, sous la poitrine, sous le nombril).

### l.10 | parole
statut: sunna
ar: سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَىٰ جَدُّكَ، وَلَا إِلَٰهَ غَيْرُكَ
tr: Subhânakallâhumma wa bi-hamdik, wa tabârakasmuk, wa ta'âlâ jadduk, wa lâ ilâha ghayruk.
fr: Gloire à Toi, ô Allah, et louange à Toi. Béni soit Ton nom, élevée soit Ta majesté, et il n'y a de divinité que Toi. (invocation d'ouverture, dite à voix basse dans la première unité)
src: Abû Dâwud 776 ; at-Tirmidhî 243 (d'après 'Â'isha) ; Muslim 399 (pratique de 'Umar)

### l.11 | divergence
fr: D'autres invocations d'ouverture authentiques existent (al-Bukhârî 744 ; Muslim 598). Les malikites ne la disent pas dans la prière obligatoire.

## p.2 - Debout : la lecture d'Al-Fâtiha


### l.1 | titre
fr: Debout : la lecture d'Al-Fâtiha (sourate 1)

### l.2 | parole
statut: sunna
ar: أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ
tr: A'ûdhu billâhi minash-shaytânir-rajîm.
fr: Je cherche refuge auprès d'Allah contre Satan le maudit. (à voix basse, avant de lire)
src: Sourate An-Nahl 16:98 (« Lorsque tu lis le Coran, demande refuge auprès d'Allah contre Satan le maudit »)

### l.3 | coran
ref: 1:1
ar: بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ
tr: Bismillâhir-rahmânir-rahîm.
fr: Au nom d'Allah, le Tout Miséricordieux, le Très Miséricordieux.
src: Sourate Al-Fâtiha 1:1

### l.4 | coran
ref: 1:2
ar: ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ
tr: Al-hamdu lillâhi rabbil-'âlamîn.
fr: Louange à Allah, Seigneur des mondes,
src: Sourate Al-Fâtiha 1:2

### l.5 | coran
ref: 1:3
ar: ٱلرَّحْمَٰنِ ٱلرَّحِيمِ
tr: Ar-rahmânir-rahîm.
fr: le Tout Miséricordieux, le Très Miséricordieux,
src: Sourate Al-Fâtiha 1:3

### l.6 | coran
ref: 1:4
ar: مَٰلِكِ يَوْمِ ٱلدِّينِ
tr: Mâliki yawmid-dîn.
fr: Maître du Jour de la Rétribution.
src: Sourate Al-Fâtiha 1:4

### l.7 | coran
ref: 1:5
ar: إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ
tr: Iyyâka na'budu wa iyyâka nasta'în.
fr: C'est Toi seul que nous adorons, et c'est Toi seul dont nous implorons le secours.
src: Sourate Al-Fâtiha 1:5

### l.8 | coran
ref: 1:6
ar: ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ
tr: Ihdinas-sirâtal-mustaqîm.
fr: Guide-nous sur le droit chemin,
src: Sourate Al-Fâtiha 1:6

### l.9 | coran
ref: 1:7
ar: صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ
tr: Sirâtal-ladhîna an'amta 'alayhim, ghayril-maghdûbi 'alayhim wa lad-dâllîn.
fr: le chemin de ceux que Tu as comblés de bienfaits, non de ceux qui ont encouru Ta colère, ni des égarés.
src: Sourate Al-Fâtiha 1:7

## p.3 - Al-Fâtiha (suite), puis une sourate courte


### l.1 | titre
fr: Al-Fâtiha (suite), puis une sourate courte : Al-Ikhlâs (sourate 112)

### l.2 | parole
statut: sunna
ar: آمِينَ
tr: Âmîn.
fr: Exauce-nous, ô Allah. Dit après Al-Fâtiha, par l'imam et par ceux qui prient derrière lui.
src: al-Bukhârî 780 ; Muslim 410 (d'après Abû Hurayra)

### l.3 | divergence
fr: Lire Al-Fâtiha à chaque unité : pilier pour la majorité (« Pas de prière pour qui ne lit pas la Fâtiha », al-Bukhârî 756 ; Muslim 394) ; obligation sans être pilier chez les hanafites, qui ne la demandent pas à celui qui prie derrière un imam.

### l.4 | divergence
fr: La basmala : lue à voix haute comme verset d'Al-Fâtiha chez les chafiites ; à voix basse chez les hanafites et les hanbalites ; non lue dans la prière obligatoire chez les malikites.

### l.5 | coran
ref: 1:1
ar: بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ
tr: Bismillâhir-rahmânir-rahîm.
fr: Au nom d'Allah, le Tout Miséricordieux, le Très Miséricordieux. (basmala dite avant la sourate ; elle ne fait pas partie de 112:1)
src: Texte identique à Al-Fâtiha 1:1

### l.6 | coran
ref: 112:1 sans basmala
ar: قُلْ هُوَ ٱللَّهُ أَحَدٌ
tr: Qul huwallâhu ahad.
fr: Dis : « Il est Allah, Unique.
src: Sourate Al-Ikhlâs 112:1

### l.7 | coran
ref: 112:2
ar: ٱللَّهُ ٱلصَّمَدُ
tr: Allâhus-samad.
fr: Allah, Celui vers qui l'on se tourne en tout besoin (as-Samad).
src: Sourate Al-Ikhlâs 112:2

### l.8 | coran
ref: 112:3
ar: لَمْ يَلِدْ وَلَمْ يُولَدْ
tr: Lam yalid wa lam yûlad.
fr: Il n'a pas engendré et n'a pas été engendré.
src: Sourate Al-Ikhlâs 112:3

### l.9 | coran
ref: 112:4
ar: وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ
tr: Wa lam yakun lahû kufuwan ahad.
fr: Et nul n'est égal à Lui. »
src: Sourate Al-Ikhlâs 112:4

### l.10 | note
fr: Lire une sourate (ou quelques versets) après Al-Fâtiha dans les deux premières unités est une sunna.
src: al-Bukhârî 759 ; Muslim 451 (d'après Abû Qatâda)

## p.4 - L'inclinaison et le redressement


### l.1 | titre
fr: L'inclinaison (ar-rukû') et le redressement

### l.2 | geste
statut: obligatoire
ar: الرُّكُوعُ
tr: Ar-rukû'.
fr: L'inclinaison : dire « Allâhu akbar », s'incliner, le dos droit, les mains posées sur les genoux, et rester immobile un instant.
src: al-Bukhârî 828 (description d'Abû Humayd as-Sâ'idî) ; takbîr à chaque mouvement : al-Bukhârî 789 ; Muslim 392

### l.3 | illustration
fr: [Illustration à venir : geste de l'inclinaison (ar-rukû'), dos droit]

### l.4 | parole
statut: sunna
ar: سُبْحَانَ رَبِّيَ الْعَظِيمِ
tr: Subhâna rabbiyal-'azîm. (trois fois)
fr: Gloire à mon Seigneur, le Très Grand.
src: Muslim 772 (d'après Hudhayfa) ; Abû Dâwud 869

### l.5 | divergence
fr: Le dire au moins une fois : obligatoire chez les hanbalites ; sunna pour la majorité.

### l.6 | parole
ar: سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ
tr: Sami'allâhu liman hamidah.
fr: Allah entend celui qui Le loue. Dit en se redressant de l'inclinaison.
src: al-Bukhârî 789 ; Muslim 392 (d'après Abû Hurayra)

### l.7 | parole
statut: sunna
ar: رَبَّنَا وَلَكَ الْحَمْدُ
tr: Rabbanâ wa lakal-hamd.
fr: Notre Seigneur, à Toi la louange. Dit une fois debout, immobile, les bras le long du corps ou les mains posées.
src: al-Bukhârî 789 et 732 ; Muslim 392

### l.8 | illustration
fr: [Illustration à venir : position redressée après l'inclinaison (al-i'tidâl)]

### l.9 | divergence
fr: Les formes « Rabbanâ lakal-hamd », « Allâhumma rabbanâ lakal-hamd » sont aussi authentiques. Derrière un imam : seulement « Rabbanâ wa lakal-hamd » pour la majorité ; les deux paroles chez les chafiites. Le statut de « Sami'allâhu liman hamidah » (obligatoire ou sunna) varie selon les écoles.

## p.5 - Les prosternations


### l.1 | titre
fr: Les deux prosternations

### l.2 | geste
statut: obligatoire
ar: السُّجُودُ
tr: As-sujûd.
fr: La prosternation : dire « Allâhu akbar » et se prosterner sur sept parties du corps : le front avec le nez, les deux mains, les deux genoux, les extrémités des deux pieds.
src: al-Bukhârî 812 ; Muslim 490 (d'après Ibn 'Abbâs)

### l.3 | illustration
fr: [Illustration à venir : geste de la prosternation (as-sujûd), sept appuis]

### l.4 | parole
statut: sunna
ar: سُبْحَانَ رَبِّيَ الْأَعْلَىٰ
tr: Subhâna rabbiyal-a'lâ. (trois fois)
fr: Gloire à mon Seigneur, le Très Haut.
src: Muslim 772 (d'après Hudhayfa) ; Abû Dâwud 869

### l.5 | geste
statut: obligatoire
ar: الْجُلُوسُ بَيْنَ السَّجْدَتَيْنِ
tr: Al-julûsu baynas-sajdatayn.
fr: Dire « Allâhu akbar » et s'asseoir entre les deux prosternations, immobile un instant.
src: al-Bukhârî 757 ; Muslim 397

### l.6 | illustration
fr: [Illustration à venir : position assise entre les deux prosternations]

### l.7 | parole
statut: sunna
ar: رَبِّ اغْفِرْ لِي، رَبِّ اغْفِرْ لِي
tr: Rabbighfir lî, rabbighfir lî.
fr: Seigneur, pardonne-moi. Seigneur, pardonne-moi.
src: Abû Dâwud 874 ; an-Nasâ'î 1145 ; Ibn Mâja 897 (d'après Hudhayfa)

### l.8 | geste
statut: obligatoire
fr: Dire « Allâhu akbar » et faire la deuxième prosternation, avec les mêmes paroles (S-PRI / p.5 / l.4).
src: al-Bukhârî 757 ; Muslim 397

### l.9 | illustration
fr: [Illustration à venir : deuxième prosternation]

### l.10 | parole
ar: ثُمَّ ارْكَعْ حَتَّى تَطْمَئِنَّ رَاكِعًا
tr: Thummarka' hattâ tatma'inna râki'â.
fr: « Puis incline-toi jusqu'à être immobile dans l'inclinaison. » Chaque position se tient dans le calme (at-tuma'nîna), sans se presser.
src: al-Bukhârî 757 ; Muslim 397 (hadith de celui qui priait mal, d'après Abû Hurayra)

### l.11 | note
fr: Se relever en disant « Allâhu akbar » pour la deuxième unité, et la faire comme la première, sans l'invocation d'ouverture.
src: al-Bukhârî 789 ; Muslim 392

## p.6 - L'assise : le tashahhud


### l.1 | titre
fr: L'assise après la deuxième unité : le tashahhud

### l.2 | geste
statut: obligatoire
fr: S'asseoir, les mains sur les cuisses, l'index droit tendu pendant le tashahhud.
src: Muslim 580 (d'après Ibn 'Umar)

### l.3 | illustration
fr: [Illustration à venir : position assise du tashahhud, index tendu]

### l.4 | parole
ar: التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ
tr: At-tahiyyâtu lillâhi was-salawâtu wat-tayyibât.
fr: Les salutations sont à Allah, ainsi que les prières et les bonnes paroles.
src: al-Bukhârî 831 ; Muslim 402 (tashahhud d'Ibn Mas'ûd)

### l.5 | parole
ar: السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ
tr: As-salâmu 'alayka ayyuhan-nabiyyu wa rahmatullâhi wa barakâtuh.
fr: Que la paix soit sur toi, ô Prophète, ainsi que la miséricorde d'Allah et Ses bénédictions.
src: al-Bukhârî 831 ; Muslim 402 (tashahhud d'Ibn Mas'ûd)

### l.6 | parole
ar: السَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللَّهِ الصَّالِحِينَ
tr: As-salâmu 'alaynâ wa 'alâ 'ibâdillâhis-sâlihîn.
fr: Que la paix soit sur nous et sur les vertueux serviteurs d'Allah.
src: al-Bukhârî 831 ; Muslim 402 (tashahhud d'Ibn Mas'ûd)

### l.7 | parole
ar: أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ
tr: Ash-hadu an lâ ilâha illallâh, wa ash-hadu anna Muhammadan 'abduhû wa rasûluh.
fr: J'atteste qu'il n'y a de divinité [digne d'adoration] qu'Allah, et j'atteste que Muhammad est Son serviteur et Son messager.
src: al-Bukhârî 831 ; Muslim 402 (tashahhud d'Ibn Mas'ûd)

### l.8 | divergence
fr: Plusieurs formules authentiques du tashahhud existent : celle d'Ibn Mas'ûd (ci-dessus, préférée des hanafites et des hanbalites), celle d'Ibn 'Abbâs (Muslim 403, préférée des chafiites), celle de 'Umar (Muwatta' de Mâlik, préférée des malikites).

### l.9 | note
fr: Dans une prière de trois ou quatre unités, on se relève ici (« Allâhu akbar ») pour l'unité suivante ; dans une prière de deux unités, on poursuit à la page 7 (S-PRI / p.7).

## p.7 - Fin de la prière : la prière sur le Prophète


### l.1 | titre
fr: Fin de la prière : la prière sur le Prophète

### l.2 | parole
ar: اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ
tr: Allâhumma salli 'alâ Muhammadin wa 'alâ âli Muhammad,
fr: Ô Allah, prie sur Muhammad et sur la famille de Muhammad,
src: al-Bukhârî 3370 ; Muslim 406 (d'après Ka'b ibn 'Ujra)

### l.3 | parole
ar: كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ
tr: kamâ sallayta 'alâ Ibrâhîma wa 'alâ âli Ibrâhîm, innaka hamîdun majîd.
fr: comme Tu as prié sur Ibrâhîm et sur la famille d'Ibrâhîm. Tu es digne de louange et de gloire.
src: al-Bukhârî 3370 ; Muslim 406 (d'après Ka'b ibn 'Ujra)

### l.4 | parole
ar: اللَّهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ
tr: Allâhumma bârik 'alâ Muhammadin wa 'alâ âli Muhammad,
fr: Ô Allah, bénis Muhammad et la famille de Muhammad,
src: al-Bukhârî 3370 ; Muslim 406 (d'après Ka'b ibn 'Ujra)

### l.5 | parole
ar: كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ
tr: kamâ bârakta 'alâ Ibrâhîma wa 'alâ âli Ibrâhîm, innaka hamîdun majîd.
fr: comme Tu as béni Ibrâhîm et la famille d'Ibrâhîm. Tu es digne de louange et de gloire.
src: al-Bukhârî 3370 ; Muslim 406 (d'après Ka'b ibn 'Ujra)

### l.6 | divergence
fr: La prière sur le Prophète dans le dernier tashahhud : pilier chez les chafiites et les hanbalites ; sunna chez les hanafites et les malikites.

### l.7 | parole
statut: sunna
ar: اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ جَهَنَّمَ، وَمِنْ عَذَابِ الْقَبْرِ، وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ، وَمِنْ شَرِّ فِتْنَةِ الْمَسِيحِ الدَّجَّالِ
tr: Allâhumma innî a'ûdhu bika min 'adhâbi jahannam, wa min 'adhâbil-qabr, wa min fitnatil-mahyâ wal-mamât, wa min sharri fitnatil-masîhid-dajjâl.
fr: Ô Allah, je cherche refuge auprès de Toi contre le châtiment de l'Enfer, le châtiment de la tombe, l'épreuve de la vie et de la mort, et le mal de l'épreuve du faux messie (ad-Dajjâl).
src: Muslim 588 (d'après Abû Hurayra)

## p.8 - Fin de la prière : le salut


### l.1 | titre
fr: Fin de la prière : le salut (at-taslîm)

### l.2 | parole
statut: obligatoire
ar: السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ
tr: As-salâmu 'alaykum wa rahmatullâh. (en tournant la tête à droite)
fr: Que la paix soit sur vous, ainsi que la miséricorde d'Allah.
src: Muslim 582 (d'après Sa'd ibn Abî Waqqâs) ; Abû Dâwud 996 ; at-Tirmidhî 295 (d'après Ibn Mas'ûd)

### l.3 | illustration
fr: [Illustration à venir : salut final, tête tournée à droite]

### l.4 | parole
statut: sunna
ar: السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ
tr: As-salâmu 'alaykum wa rahmatullâh. (en tournant la tête à gauche)
fr: Que la paix soit sur vous, ainsi que la miséricorde d'Allah.
src: Muslim 582 ; Abû Dâwud 996 ; at-Tirmidhî 295

### l.5 | illustration
fr: [Illustration à venir : salut final, tête tournée à gauche]

### l.6 | divergence
fr: Le salut : le premier est obligatoire et le second sunna pour la majorité (un seul salut suffit chez les malikites) ; les hanbalites tiennent les deux pour obligatoires dans la prière obligatoire ; pour les hanafites, sortir de la prière par le salut est une obligation sans être pilier.
