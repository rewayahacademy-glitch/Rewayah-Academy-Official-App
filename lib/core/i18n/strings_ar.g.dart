///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TraductionsAr extends Traductions with BaseTranslations<AppLocale, Traductions> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TraductionsAr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Traductions>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ar>.
	final TranslationMetadata<AppLocale, Traductions> _meta;
	@override TranslationMetadata<AppLocale, Traductions> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TraductionsAr _root = this; // ignore: unused_field

	@override 
	TraductionsAr $copyWith({TranslationMetadata<AppLocale, Traductions>? meta}) => TraductionsAr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Traductions$commun$ar commun = _Traductions$commun$ar._(_root);
	@override late final _Traductions$etat$ar etat = _Traductions$etat$ar._(_root);
	@override late final _Traductions$classe$ar classe = _Traductions$classe$ar._(_root);
	@override late final _Traductions$salle$ar salle = _Traductions$salle$ar._(_root);
	@override late final _Traductions$eleve$ar eleve = _Traductions$eleve$ar._(_root);
	@override late final _Traductions$enseignant$ar enseignant = _Traductions$enseignant$ar._(_root);
	@override late final _Traductions$compte$ar compte = _Traductions$compte$ar._(_root);
	@override late final _Traductions$tc$ar tc = _Traductions$tc$ar._(_root);
	@override late final _Traductions$nav$ar nav = _Traductions$nav$ar._(_root);
	@override late final _Traductions$accessibilite$ar accessibilite = _Traductions$accessibilite$ar._(_root);
	@override late final _Traductions$reseau$ar reseau = _Traductions$reseau$ar._(_root);
	@override late final _Traductions$vide$ar vide = _Traductions$vide$ar._(_root);
	@override late final _Traductions$notifications$ar notifications = _Traductions$notifications$ar._(_root);
	@override late final _Traductions$choix$ar choix = _Traductions$choix$ar._(_root);
	@override late final _Traductions$accuse$ar accuse = _Traductions$accuse$ar._(_root);
	@override late final _Traductions$aConstruire$ar aConstruire = _Traductions$aConstruire$ar._(_root);
	@override late final _Traductions$destructif$ar destructif = _Traductions$destructif$ar._(_root);
	@override late final _Traductions$avatar$ar avatar = _Traductions$avatar$ar._(_root);
	@override late final _Traductions$pin$ar pin = _Traductions$pin$ar._(_root);
	@override late final _Traductions$enfant$ar enfant = _Traductions$enfant$ar._(_root);
	@override late final _Traductions$reglagesEnfant$ar reglagesEnfant = _Traductions$reglagesEnfant$ar._(_root);
	@override late final _Traductions$galerie$ar galerie = _Traductions$galerie$ar._(_root);
	@override late final _Traductions$ficheEleve$ar ficheEleve = _Traductions$ficheEleve$ar._(_root);
	@override late final _Traductions$parcours$ar parcours = _Traductions$parcours$ar._(_root);
	@override late final _Traductions$eleveConnexion$ar eleveConnexion = _Traductions$eleveConnexion$ar._(_root);
	@override late final _Traductions$presence$ar presence = _Traductions$presence$ar._(_root);
	@override late final _Traductions$priere$ar priere = _Traductions$priere$ar._(_root);
	@override late final _Traductions$tuteur$ar tuteur = _Traductions$tuteur$ar._(_root);
	@override late final _Traductions$historique$ar historique = _Traductions$historique$ar._(_root);
	@override late final _Traductions$appareils$ar appareils = _Traductions$appareils$ar._(_root);
	@override late final _Traductions$connexion$ar connexion = _Traductions$connexion$ar._(_root);
	@override late final _Traductions$attente$ar attente = _Traductions$attente$ar._(_root);
	@override late final _Traductions$inscription$ar inscription = _Traductions$inscription$ar._(_root);
	@override late final _Traductions$consentement$ar consentement = _Traductions$consentement$ar._(_root);
	@override late final _Traductions$foyer$ar foyer = _Traductions$foyer$ar._(_root);
	@override late final _Traductions$adulte$ar adulte = _Traductions$adulte$ar._(_root);
	@override late final _Traductions$dossiers$ar dossiers = _Traductions$dossiers$ar._(_root);
	@override late final _Traductions$kyc$ar kyc = _Traductions$kyc$ar._(_root);
	@override late final _Traductions$contrat$ar contrat = _Traductions$contrat$ar._(_root);
	@override late final _Traductions$bienvenue$ar bienvenue = _Traductions$bienvenue$ar._(_root);
	@override late final _Traductions$creneaux$ar creneaux = _Traductions$creneaux$ar._(_root);
	@override late final _Traductions$disponibilites$ar disponibilites = _Traductions$disponibilites$ar._(_root);
	@override late final _Traductions$controleur$ar controleur = _Traductions$controleur$ar._(_root);
	@override late final _Traductions$agent$ar agent = _Traductions$agent$ar._(_root);
	@override late final _Traductions$admin$ar admin = _Traductions$admin$ar._(_root);
}

// Path: commun
class _Traductions$commun$ar extends Traductions$commun$fr {
	_Traductions$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$sections$ar sections = _Traductions$commun$sections$ar._(_root);
	@override String get marque => 'Rewayah Academy';
	@override String get continuer => 'متابعة';
	@override String get retour => 'رجوع';
	@override String get valider => 'تأكيد';
	@override String get annuler => 'إلغاء';
	@override String get fermer => 'إغلاق';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get chargement => 'جارٍ التحميل';
	@override late final _Traductions$commun$demonstration$ar demonstration = _Traductions$commun$demonstration$ar._(_root);
	@override late final _Traductions$commun$etape$ar etape = _Traductions$commun$etape$ar._(_root);
	@override late final _Traductions$commun$choix$ar choix = _Traductions$commun$choix$ar._(_root);
	@override late final _Traductions$commun$etats$ar etats = _Traductions$commun$etats$ar._(_root);
	@override late final _Traductions$commun$entete$ar entete = _Traductions$commun$entete$ar._(_root);
	@override late final _Traductions$commun$selecteurProfils$ar selecteurProfils = _Traductions$commun$selecteurProfils$ar._(_root);
	@override late final _Traductions$commun$theme$ar theme = _Traductions$commun$theme$ar._(_root);
	@override late final _Traductions$commun$demarrage$ar demarrage = _Traductions$commun$demarrage$ar._(_root);
	@override late final _Traductions$commun$dates$ar dates = _Traductions$commun$dates$ar._(_root);
}

// Path: etat
class _Traductions$etat$ar extends Traductions$etat$fr {
	_Traductions$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enDirect => 'مباشر';
	@override String get seanceAnnulee => 'ملغاة';
	@override String annuleeValeur({required Object valeur}) => 'ملغاة: ⁨${valeur}⁩';
	@override String get motifNonCommunique => 'السبب غير متوفر';
	@override String get aucunRemplacantTrouve => 'لم يُعثر على بديل';
	@override String get seanceNonFacturee => 'الحصة غير مفوترة';
	@override String raisonEtSuite({required Object raison, required Object suite}) => '⁨${raison}⁩ · ⁨${suite}⁩';
	@override String get imminent => 'قريبًا جدًا';
	@override String get annule => 'ملغى';
	@override String get enAttente => 'قيد الانتظار';
	@override String get enRetard => 'متأخر';
	@override String get termine => 'منتهٍ';
}

// Path: classe
class _Traductions$classe$ar extends Traductions$classe$fr {
	_Traductions$classe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$classe$entree$ar entree = _Traductions$classe$entree$ar._(_root);
	@override String get catalogue => 'اختيار فصل';
	@override String get planning => 'الجدول';
	@override String get travail => 'قبل الدرس القادم';
	@override String get ressources => 'المكتبة';
	@override String get progression => 'التقدم';
	@override String get observer => 'متابعة الحصة';
	@override String get titre => 'الفصل';
	@override String get historique => 'السجل';
	@override String sousTitre({required Object prenom, required Object enseignant}) => '⁨${prenom}⁩ · ⁨${enseignant}⁩';
	@override String get indisponiblePhrase => 'تفاصيل الفصل غير متاحة هنا بعد.';
	@override String get introuvableTitre => 'هذا الفصل غير مفتوح لهذا الملف';
	@override String get introuvablePhrase => 'ربما انتهى، أو يخص طالبًا آخر في الأسرة.';
	@override late final _Traductions$classe$seance$ar seance = _Traductions$classe$seance$ar._(_root);
	@override late final _Traductions$classe$observation$ar observation = _Traductions$classe$observation$ar._(_root);
	@override late final _Traductions$classe$pagePlanning$ar pagePlanning = _Traductions$classe$pagePlanning$ar._(_root);
	@override late final _Traductions$classe$pageTravail$ar pageTravail = _Traductions$classe$pageTravail$ar._(_root);
	@override late final _Traductions$classe$pageRessources$ar pageRessources = _Traductions$classe$pageRessources$ar._(_root);
	@override late final _Traductions$classe$pageProgression$ar pageProgression = _Traductions$classe$pageProgression$ar._(_root);
	@override late final _Traductions$classe$pageCatalogue$ar pageCatalogue = _Traductions$classe$pageCatalogue$ar._(_root);
}

// Path: salle
class _Traductions$salle$ar extends Traductions$salle$fr {
	_Traductions$salle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get microOuvert => 'الميكروفون مفتوح';
	@override String get microCoupe => 'الميكروفون مغلق';
	@override String get cameraAllumee => 'الكاميرا مشغّلة';
	@override String get cameraCoupee => 'الكاميرا مطفأة';
	@override late final _Traductions$salle$secours$ar secours = _Traductions$salle$secours$ar._(_root);
	@override late final _Traductions$salle$preparation$ar preparation = _Traductions$salle$preparation$ar._(_root);
	@override String get bandeauPermanent => 'يُسجَّل الدرس، وقد تجري زيارة مراقبة.';
	@override late final _Traductions$salle$seance$ar seance = _Traductions$salle$seance$ar._(_root);
	@override late final _Traductions$salle$fin$ar fin = _Traductions$salle$fin$ar._(_root);
	@override String get micro => 'الميكروفون';
	@override String get camera => 'الكاميرا';
	@override String get quitter => 'مغادرة';
	@override String get ouvrirCoran => 'فتح القرآن';
	@override String get confirmerSortie => 'مغادرة الدرس؟';
	@override String get expiree => 'لم تعد هذه القاعة متاحة. عد إلى صفحتك الرئيسية للانضمام إلى الدرس القادم.';
	@override String get ouverture => 'جارٍ فتح القاعة';
	@override String get verificationMateriel => 'جارٍ التحقق من الميكروفون';
	@override String get connexion => 'جارٍ الاتصال بالدرس';
	@override String get reconnexion => 'الاتصال غير مستقر، جارٍ إعادة الاتصال';
	@override String get reconnexionCourt => 'إعادة الاتصال';
	@override String get perdue => 'انقطع الاتصال بالدرس';
	@override String get seulEnseignant => 'لم يصل معلمك بعد';
	@override String get seulEnseignantDetail => 'ابقَ على هذه الشاشة. ستراه يظهر.';
	@override String get seulEleve => 'لم يصل طالبك بعد';
	@override String get seulEleveDetail => 'ابقَ على هذه الشاشة. ستراه يظهر.';
	@override String get seulObservation => 'لم يدخل أحد هذه القاعة بعد';
	@override String get seulObservationDetail => 'لم يبدأ الدرس، أو انتهى بالفعل.';
	@override String get refusAcces => 'هذا الدرس غير مفتوح لك الآن';
	@override String get refusAccesDetail => 'تُفتح القاعة قبل موعد الدرس بعشر دقائق، وتُغلق بعد نهايته بربع ساعة.';
	@override String get refusConfiguration => 'القاعة غير متاحة بعد';
	@override String get refusConfigurationDetail => 'المشكلة ليست في جهازك: خدمة مكالمات الفيديو غير موصولة. الفريق على علم بذلك.';
	@override String get refusReseau => 'لم تستجب القاعة';
	@override String get refusReseauDetail => 'تحقّق من اتصالك، ثم أعد المحاولة.';
	@override String get refusMateriel => 'لا يوجد ميكروفون صالح على هذا الجهاز';
	@override String get refusMaterielDetail => 'درس القرآن يكون بالصوت. اسمح بالوصول إلى الميكروفون، أو وصّل سماعة، ثم أعد المحاولة.';
	@override String get retourAccueil => 'العودة إلى صفحتي الرئيسية';
	@override String get ouvrirMicro => 'فتح الميكروفون';
	@override String get fermerMicro => 'إغلاق الميكروفون';
	@override String get ouvrirCamera => 'تشغيل الكاميرا';
	@override String get fermerCamera => 'إطفاء الكاميرا';
	@override String get quitterLeCours => 'مغادرة الدرس';
	@override String get consequenceSortie => 'يستمر الدرس دونك، ويُسجَّل خروجك في الحصة.';
	@override String get vousMeme => 'أنت';
	@override String get sansImage => 'دون صورة';
	@override String get lienMediocre => 'اتصال ضعيف';
	@override String get lienPerdu => 'انقطع الاتصال';
	@override String get videoSuspendue => 'توقفت الصورة إلى أن يعود الاتصال. الصوت مستمر.';
	@override String get roleEnseignant => 'المعلم';
	@override String get roleEleve => 'الطالب';
	@override String get roleTuteur => 'وليّ الأمر، متابِع';
	@override String get roleAdministration => 'إدارة Rewayah';
	@override String get observationMuette => 'أنت تحضر الدرس. لا أحد يسمعك.';
	@override String get observationMuetteTitre => 'أنت تحضر الدرس.';
	@override String get bandeauControle => 'زيارة مراقبة. لا أحد يراك أو يسمعك، ويُسجَّل مرورك في السجل.';
	@override String get bandeauControleTitre => 'زيارة مراقبة.';
	@override late final _Traductions$salle$visiteControle$ar visiteControle = _Traductions$salle$visiteControle$ar._(_root);
}

// Path: eleve
class _Traductions$eleve$ar extends Traductions$eleve$fr {
	_Traductions$eleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$eleve$suivi$ar suivi = _Traductions$eleve$suivi$ar._(_root);
	@override late final _Traductions$eleve$accueil$ar accueil = _Traductions$eleve$accueil$ar._(_root);
	@override late final _Traductions$eleve$coran$ar coran = _Traductions$eleve$coran$ar._(_root);
}

// Path: enseignant
class _Traductions$enseignant$ar extends Traductions$enseignant$fr {
	_Traductions$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$enseignant$journee$ar journee = _Traductions$enseignant$journee$ar._(_root);
	@override late final _Traductions$enseignant$ficheGroupe$ar ficheGroupe = _Traductions$enseignant$ficheGroupe$ar._(_root);
	@override late final _Traductions$enseignant$classes$ar classes = _Traductions$enseignant$classes$ar._(_root);
	@override late final _Traductions$enseignant$eleve$ar eleve = _Traductions$enseignant$eleve$ar._(_root);
	@override late final _Traductions$enseignant$signalement$ar signalement = _Traductions$enseignant$signalement$ar._(_root);
	@override late final _Traductions$enseignant$demo$ar demo = _Traductions$enseignant$demo$ar._(_root);
	@override late final _Traductions$enseignant$bienvenue$ar bienvenue = _Traductions$enseignant$bienvenue$ar._(_root);
	@override late final _Traductions$enseignant$photo$ar photo = _Traductions$enseignant$photo$ar._(_root);
	@override late final _Traductions$enseignant$salle$ar salle = _Traductions$enseignant$salle$ar._(_root);
	@override late final _Traductions$enseignant$cahier$ar cahier = _Traductions$enseignant$cahier$ar._(_root);
	@override late final _Traductions$enseignant$profil$ar profil = _Traductions$enseignant$profil$ar._(_root);
	@override late final _Traductions$enseignant$creneaux$ar creneaux = _Traductions$enseignant$creneaux$ar._(_root);
	@override late final _Traductions$enseignant$revue$ar revue = _Traductions$enseignant$revue$ar._(_root);
}

// Path: compte
class _Traductions$compte$ar extends Traductions$compte$fr {
	_Traductions$compte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get themeContexte => 'اختر مظهر التطبيق. يتم التغيير فورًا ويبقى على هذا الجهاز، ويمكنك تعديله في أي وقت.';
	@override String get themeSysteme => 'النظام';
	@override String get themeSystemeDetail => 'يتبع إعداد جهازك';
	@override String get themeClair => 'فاتح';
	@override String get themeClairDetail => 'خلفية فاتحة مهما كان إعداد جهازك';
	@override String get themeSombre => 'داكن';
	@override String get themeSombreDetail => 'خلفية داكنة مهما كان إعداد جهازك';
	@override String get titre => 'حسابي';
	@override String get intro => 'معلوماتك وتفضيلاتك وصلاحياتك، في مكان واحد.';
	@override String get informations => 'المعلومات';
	@override String get profil => 'الملف الشخصي';
	@override String get profilDetail => 'عرض معلوماتك وإدارتها';
	@override String get reglages => 'الإعدادات';
	@override String get reglagesDetail => 'المظهر والإشعارات وإمكانية الوصول';
	@override String get profils => 'إدارة أسرتي';
	@override String get profilsDetail => 'إدارة ملفات أطفالك';
	@override String get appareils => 'الأسرة';
	@override String get appareilsDetail => 'الأجهزة والملفات المرتبطة بأسرتك';
	@override String get confidentialite => 'الخصوصية';
	@override String get confidentialiteDetail => 'قريبًا';
	@override String get espaces => 'المساحات';
	@override String get espacesDetail => 'المساحات التي يتيحها حسابك';
	@override String get espacesMissionEnCours => 'للعودة إلى مساحتك الرئيسية، غادر أولًا الزيارة الجارية.';
	@override String get habilitation => 'مخوَّل';
	@override String get deconnexion => 'تسجيل الخروج';
	@override String get deconnexionDetail => 'إنهاء الجلسة على هذا الجهاز';
	@override String get identifiant => 'المعرّف';
	@override String get nonDisponible => 'غير متاح';
	@override String get contact => 'التواصل';
	@override String get contactDetail => 'تديره الأكاديمية';
	@override String get langue => 'اللغة';
	@override String get francais => 'الفرنسية';
	@override String get fuseau => 'المنطقة الزمنية';
	@override String get academie => 'الأكاديمية';
	@override String get securite => 'الأمان';
	@override String get statut => 'الحالة';
	@override String get reglagesTitre => 'الإعدادات';
	@override String get reglagesIntro => 'تبقى هذه التفضيلات على هذا الجهاز وتُطبَّق فورًا.';
	@override String get apparence => 'المظهر';
	@override String get accessibilite => 'إمكانية الوصول';
	@override String get animations => 'تقليل الحركة';
	@override String get animationsDetail => 'يحدّ من الحركة على الشاشة';
	@override String get effets => 'تقليل المؤثرات';
	@override String get effetsDetail => 'يحدّ من الشفافية والظلال';
	@override String get lisibiliteDetail => 'حجم النص يتبع إعداد جهازك.';
	@override String get langueRegion => 'اللغة والمنطقة';
	@override String get francaisDetail => 'لغة الواجهة';
	@override String get actif => 'مفعَّل';
	@override String get arabe => 'العربية';
	@override String get arabeDetail => 'قريبًا';
	@override String get fuseauDetail => 'يُكتشف تلقائيًا';
	@override String get notifications => 'الإشعارات';
	@override String get notificationsCours => 'الدروس';
	@override String get notificationsCoursDetail => 'تذكيرات قبل دروسك';
	@override String get notificationsFoyer => 'الأسرة';
	@override String get notificationsFoyerDetail => 'نشاط ملفات أسرتك';
	@override String get notificationsEtat => 'تعتمد الإشعارات أيضًا على إعدادات جهازك ومتصفحك.';
	@override String get coursDonnees => 'الدروس والبيانات';
	@override String get economieDonnees => 'توفير البيانات';
	@override String get economieDonneesDetail => 'يخفّض جودة الفيديو على شبكة الجوال';
	@override String get lectureGrande => 'القراءة بنص كبير';
	@override String get lectureGrandeDetail => 'يعرض القرآن بحجم أكبر افتراضيًا';
	@override String get profilsTitre => 'ملفات الأسرة';
	@override String get profilsIntro => 'الأطفال المرتبطون بأسرتك.';
	@override String get erreurProfils => 'تعذّرت قراءة الملفات.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get aucunProfil => 'لا ملفات حتى الآن';
	@override String get aucunProfilDetail => 'أضف طفلًا للبدء';
	@override String get ajouterEnfant => 'إضافة طفل';
	@override String get ouvrirProfil => 'فتح الملف';
	@override String get modeEnfant => 'وضع إمكانية الوصول';
	@override String get modeStandard => 'الوضع العادي';
	@override String get cameraLabel => 'الكاميرا';
	@override String get cameraAutorisee => 'مسموح بها';
	@override String get cameraInterdite => 'ممنوعة';
	@override String get accesSansFin => 'وصول دون تاريخ انتهاء';
	@override String accesJusqua({required Object date}) => 'وصول حتى ⁨${date}⁩';
	@override String get statutActif => 'مفعَّل';
	@override String get statutProvisoire => 'مفعَّل مؤقتًا';
	@override String profilEnfant({required Object prenom}) => 'ملف ⁨${prenom}⁩';
	@override String identifiantEnfant({required Object identifiant}) => 'المعرّف: ⁨${identifiant}⁩';
	@override late final _Traductions$compte$roles$ar roles = _Traductions$compte$roles$ar._(_root);
	@override late final _Traductions$compte$roleDetail$ar roleDetail = _Traductions$compte$roleDetail$ar._(_root);
	@override late final _Traductions$compte$tuteur$ar tuteur = _Traductions$compte$tuteur$ar._(_root);
}

// Path: tc
class _Traductions$tc$ar extends Traductions$tc$fr {
	_Traductions$tc$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$bibliotheque$ar bibliotheque = _Traductions$tc$bibliotheque$ar._(_root);
	@override late final _Traductions$tc$groupe$ar groupe = _Traductions$tc$groupe$ar._(_root);
	@override late final _Traductions$tc$coran$ar coran = _Traductions$tc$coran$ar._(_root);
	@override late final _Traductions$tc$outils$ar outils = _Traductions$tc$outils$ar._(_root);
	@override late final _Traductions$tc$classe$ar classe = _Traductions$tc$classe$ar._(_root);
	@override late final _Traductions$tc$realtime$ar realtime = _Traductions$tc$realtime$ar._(_root);
	@override late final _Traductions$tc$observation$ar observation = _Traductions$tc$observation$ar._(_root);
	@override late final _Traductions$tc$parcours$ar parcours = _Traductions$tc$parcours$ar._(_root);
}

// Path: nav
class _Traductions$nav$ar extends Traductions$nav$fr {
	_Traductions$nav$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$nav$eleve$ar eleve = _Traductions$nav$eleve$ar._(_root);
	@override late final _Traductions$nav$tuteur$ar tuteur = _Traductions$nav$tuteur$ar._(_root);
	@override late final _Traductions$nav$enseignant$ar enseignant = _Traductions$nav$enseignant$ar._(_root);
	@override late final _Traductions$nav$controleur$ar controleur = _Traductions$nav$controleur$ar._(_root);
	@override late final _Traductions$nav$admin$ar admin = _Traductions$nav$admin$ar._(_root);
	@override String get compte => 'حسابي';
	@override String get principale => 'التنقل الرئيسي';
	@override String get motSymbole => 'Rewayah';
	@override String get replier => 'طي شريط التنقل';
	@override String get deplier => 'فتح شريط التنقل';
}

// Path: accessibilite
class _Traductions$accessibilite$ar extends Traductions$accessibilite$fr {
	_Traductions$accessibilite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$accessibilite$demo$ar demo = _Traductions$accessibilite$demo$ar._(_root);
	@override late final _Traductions$accessibilite$accueil$ar accueil = _Traductions$accessibilite$accueil$ar._(_root);
	@override late final _Traductions$accessibilite$coran$ar coran = _Traductions$accessibilite$coran$ar._(_root);
	@override late final _Traductions$accessibilite$maClasse$ar maClasse = _Traductions$accessibilite$maClasse$ar._(_root);
	@override late final _Traductions$accessibilite$tutoiement$ar tutoiement = _Traductions$accessibilite$tutoiement$ar._(_root);
	@override late final _Traductions$accessibilite$apres$ar apres = _Traductions$accessibilite$apres$ar._(_root);
	@override late final _Traductions$accessibilite$monEspace$ar monEspace = _Traductions$accessibilite$monEspace$ar._(_root);
}

// Path: reseau
class _Traductions$reseau$ar extends Traductions$reseau$fr {
	_Traductions$reseau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get horsLigne => 'لا شبكة. ما هو معروض يبقى قابلًا للاطلاع.';
	@override String get enAttenteEnvoi => 'سيُرسل بمجرد عودة الشبكة';
	@override String get retabli => 'عادت الشبكة';
	@override String get syncImpossible => 'تعذّرت المزامنة';
}

// Path: vide
class _Traductions$vide$ar extends Traductions$vide$fr {
	_Traductions$vide$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucunCours => 'لا دروس اليوم';
	@override String get aucunCoursDetail => 'سيظهر درسك القادم هنا.';
	@override String get aucunCreneau => 'لا موعد متاح الآن';
	@override String get aucunRapport => 'لا دفتر متابعة حتى الآن';
	@override String get aucunAppareil => 'لا جهاز مقترن';
}

// Path: notifications
class _Traductions$notifications$ar extends Traductions$notifications$fr {
	_Traductions$notifications$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإشعارات';
	@override String get indisponibleTitre => 'الإشعارات غير متاحة بعد';
	@override String get indisponiblePhrase => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية بمجرد فتحها.';
	@override String get videTitre => 'لا إشعارات';
	@override String get videPhrase => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية.';
	@override String ligne({required Object titre, required Object date, required Object heure}) => '⁨${titre}⁩، في ⁨${date}⁩ الساعة ⁨${heure}⁩';
}

// Path: choix
class _Traductions$choix$ar extends Traductions$choix$fr {
	_Traductions$choix$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get autre => 'أخرى';
	@override String get autreInvite => 'حدّد';
	@override String get selectionMultiple => 'يمكن اختيار عدة إجابات';
}

// Path: accuse
class _Traductions$accuse$ar extends Traductions$accuse$fr {
	_Traductions$accuse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ما يجب معرفته قبل البدء';
	@override String get compris => 'فهمت';
}

// Path: aConstruire
class _Traductions$aConstruire$ar extends Traductions$aConstruire$fr {
	_Traductions$aConstruire$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'شاشة قيد الإنشاء';
	@override String get detail => 'تأتي هذه الشاشة في المرحلة 3.';
}

// Path: destructif
class _Traductions$destructif$ar extends Traductions$destructif$fr {
	_Traductions$destructif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get irreversible => 'لا يمكن التراجع عن هذا الإجراء.';
}

// Path: avatar
class _Traductions$avatar$ar extends Traductions$avatar$fr {
	_Traductions$avatar$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sansPhoto => 'لا صورة بعد';
}

// Path: pin
class _Traductions$pin$ar extends Traductions$pin$fr {
	_Traductions$pin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'أدخل رمزك';
	@override String get erreur => 'هذا الرمز غير مطابق';
	@override String get effacer => 'مسح';
}

// Path: enfant
class _Traductions$enfant$ar extends Traductions$enfant$fr {
	_Traductions$enfant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'إضافة ملف طالب';
	@override String get aucun => 'لا ملف طالب في الأسرة';
	@override String get aucunDetail => 'أضف أولًا ملف طالب من «الأسرة».';
}

// Path: reglagesEnfant
class _Traductions$reglagesEnfant$ar extends Traductions$reglagesEnfant$fr {
	_Traductions$reglagesEnfant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإعدادات حسب ملف الطالب';
	@override String get intro => 'تُضبط صورة كل طالب وكاميرته وواجهته في بطاقته، من «الأسرة». أما الطلبات إلى الإدارة فتبقى هنا.';
	@override String get renvoi => 'الصورة والكاميرا والواجهة';
	@override String renvoiLegende({required Object prenom}) => 'في بطاقة ⁨${prenom}⁩';
}

// Path: galerie
class _Traductions$galerie$ar extends Traductions$galerie$fr {
	_Traductions$galerie$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'معرض المكونات';
	@override String get avertissement => 'منصة اختبار للتطوير. غير موجودة في إصدارات الإنتاج.';
	@override String get paires => 'أزواج الألوان';
	@override String get elevation => 'الارتفاع والزوايا';
	@override String get typographie => 'سلالم الخطوط';
	@override String get polices => 'الخطوط';
	@override String get composants => 'المكونات المشتركة';
	@override String get modeEnfant => 'وضع إمكانية الوصول';
	@override String get modeStandard => 'الوضع العادي';
}

// Path: ficheEleve
class _Traductions$ficheEleve$ar extends Traductions$ficheEleve$fr {
	_Traductions$ficheEleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titreRepli => 'ملف الطالب';
	@override String get parametres => 'إعدادات الطالب';
	@override String get appareilsGroupe => 'الأجهزة';
	@override late final _Traductions$ficheEleve$introuvable$ar introuvable = _Traductions$ficheEleve$introuvable$ar._(_root);
	@override late final _Traductions$ficheEleve$lignes$ar lignes = _Traductions$ficheEleve$lignes$ar._(_root);
	@override late final _Traductions$ficheEleve$informations$ar informations = _Traductions$ficheEleve$informations$ar._(_root);
	@override late final _Traductions$ficheEleve$inscription$ar inscription = _Traductions$ficheEleve$inscription$ar._(_root);
	@override late final _Traductions$ficheEleve$interface$ar interface = _Traductions$ficheEleve$interface$ar._(_root);
	@override late final _Traductions$ficheEleve$camera$ar camera = _Traductions$ficheEleve$camera$ar._(_root);
	@override late final _Traductions$ficheEleve$acces$ar acces = _Traductions$ficheEleve$acces$ar._(_root);
}

// Path: parcours
class _Traductions$parcours$ar extends Traductions$parcours$fr {
	_Traductions$parcours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String titre({required Object prenom}) => 'مسار ⁨${prenom}⁩';
	@override String get intro => 'بعض الأسئلة لتخصيص مسارك. لن ترى بعدها إلا المواعيد والخيارات المناسبة لوضعك.';
	@override String get reprendre => 'استئناف';
	@override String get commencer => 'تخصيص المسار';
	@override String get modifier => 'تعديل إجاباتي';
	@override String get erreur => 'تعذّر حفظ هذه الإجابة. أعد المحاولة.';
	@override String get chargement => 'نحضّر خياراتك.';
	@override String pourPrenom({required Object prenom}) => 'لـ⁨${prenom}⁩';
	@override String get retourAccueil => 'العودة إلى الرئيسية';
	@override String get retourFoyer => 'العودة إلى الأسرة';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get indisponibleTitre => 'الاستبيان غير متاح بعد';
	@override String get indisponibleDetail => 'لم تفتح الأكاديمية هذه الخطوة بعد. لا شيء عليك فعله الآن: لم يضِع شيء، ويمكنك تعبئتها بمجرد فتحها.';
	@override String get horsLigneTitre => 'لا اتصال';
	@override String get horsLigneDetail => 'تحقّق من اتصالك، ثم أعد المحاولة. إجاباتك محفوظة.';
	@override String get erreurChargement => 'تعذّر عرض الاستبيان';
	@override String get erreurChargementDetail => 'حدث خطأ من جهتنا. أعد المحاولة بعد لحظة؛ إجاباتك محفوظة.';
	@override String get introuvableTitre => 'لم يُعثر على ملف الطالب هذا';
	@override String get introuvableDetail => 'ربما أُزيل من الأسرة. عد إلى «الأسرة» لاختيار ملف طالب.';
	@override String finTitre({required Object prenom}) => 'حُفظ التفضيل لـ⁨${prenom}⁩';
	@override String get finDetail => 'سُجِّل هذا الموعد كتفضيل لك. لا يحجز مقعدًا بعد.';
	@override String get finAjouterDetail => 'هل يرغب شخص آخر من الأسرة في التعلم؟';
	@override String get finAjouterProfil => 'إضافة ملف طالب';
	@override String ageQuestion({required Object prenom}) => 'كم عمر ⁨${prenom}⁩؟';
	@override String get ageRaison => 'العمر يحدد مدة الحصص وعدد الطلاب في الفصل. لا نطلب تاريخ الميلاد: تكفي الفئة العمرية.';
	@override String get langueQuestion => 'بأي لغة يُقدَّم الدرس؟';
	@override String get langueRaison => 'هي اللغة التي سيتكلمها المعلم أثناء الحصة. وهي مستقلة عن لغة التطبيق، التي يمكنك تغييرها في أي وقت من إعداداتك.';
	@override String get lieuQuestion => 'أين تقيم؟';
	@override String get lieuRaison => 'نستخدمها فقط لنعرض لك المواعيد بتوقيتك المحلي. لا نطلب أبدًا موقعك الدقيق، ولا تغادر هذه الإجابة ملفك.';
	@override String get lieuSuggere => 'مقترح حسب توقيت جهازك';
	@override String niveauQuestion({required Object prenom}) => 'أين وصل ⁨${prenom}⁩ اليوم؟';
	@override String get niveauRaison => 'إجابتك توجّه المقترحات الأولى. لا تحدد المستوى الرسمي: تحدده الأكاديمية بعد لقاء مع معلم.';
	@override String get niveauDebutLettres => 'نبدأ بالحروف';
	@override String get niveauLettresAvecAide => 'الحروف معروفة، والقراءة تحتاج إلى مساعدة';
	@override String get niveauLectureLente => 'القراءة ممكنة، ببطء';
	@override String get niveauLectureCourante => 'يقرأ القرآن بطلاقة';
	@override String get niveauMemorisationPartielle => 'حفظ بعضه';
	@override String get objectifQuestion => 'ماذا تريد أولًا؟';
	@override String get objectifRaison => 'يمكنك تغيير الهدف لاحقًا: هو يوجّه عمل المعلم، ولا يُلزمك.';
	@override String get objectifApprendreALire => 'تعلّم القراءة';
	@override String get objectifDevenirFluide => 'القراءة بطلاقة أكبر';
	@override String get objectifMemoriser => 'الحفظ';
	@override String get objectifIndecis => 'لا أعرف بعد';
	@override String get momentsQuestion => 'أي أوقات اليوم تناسبك أكثر؟';
	@override String get momentsRaison => 'هذه الإجابة لا تنشئ أي موعد ولا تحجز شيئًا. تفيد فقط في إبراز المواعيد الأنسب لك من بين التي تقترحها الأكاديمية. سترى كل المواعيد الأخرى أدناه.';
	@override String get momentMatin => 'الصباح';
	@override String get momentApresMidi => 'بعد الظهر';
	@override String get momentSoir => 'المساء';
	@override String offresQuestion({required Object prenom}) => 'هذه المواعيد المفتوحة لـ⁨${prenom}⁩';
	@override String get offresRaison => 'تُعرض هذه المواعيد بتوقيتك المحلي. اختيار موعد يحفظ تفضيلك: لا يحجز مقعدًا ولا يكوّن فصلًا بعد.';
	@override String get offreRecommandee => 'الأقرب إلى إجاباتك';
	@override String get offresAutres => 'مواعيد ممكنة أخرى';
	@override String offreRecurrence({required Object seances, required Object duree}) => '⁨${seances}⁩ حصص في الأسبوع، ⁨${duree}⁩ دقيقة';
	@override String offreRecurrencePause({required Object seances, required Object duree, required Object pause}) => '⁨${seances}⁩ حصص في الأسبوع، ⁨${duree}⁩ دقيقة منها ⁨${pause}⁩ دقيقة استراحة';
	@override String offreLangue({required Object langue}) => 'الدرس بـ⁨${langue}⁩';
	@override String offreFuseau({required Object fuseau}) => 'التوقيت المعروض لـ⁨${fuseau}⁩';
	@override String get offreTraduite => 'معروض بتوقيتك المحلي';
	@override String offreJours({required Object jours}) => '⁨${jours}⁩';
	@override String get offreChoisir => 'اختيار هذا الموعد';
	@override String get offreChoisie => 'الموعد المختار';
	@override String get aucuneOffre => 'لا موعد مفتوح يناسب بعد';
	@override String get aucuneOffreDetail => 'تفتح الأكاديمية مواعيد جديدة مع توالي التسجيلات. يمكنك إبلاغنا بحاجتك: هذا يساعدنا على تحديد ما نفتحه.';
	@override String get refusAucun => 'لا يناسبني أي من هذه المواعيد';
	@override String get refusPrevenir => 'إعلامي إن فُتحت مواعيد جديدة';
	@override String get refusEffet => 'نسجّل أن الطلب موجود. هذا لا ينشئ فصلًا، ولا يبحث عن معلم، ولا يعد بأي موعد مستقبلي.';
	@override String get refusEnregistre => 'تم التسجيل. سنعلمك إن فُتح موعد مناسب.';
	@override String get etatAPersonnaliser => 'مسار للتخصيص';
	@override String etatAPersonnaliserDetail({required Object prenom}) => 'بعض الأسئلة، ولن نعرض لك إلا ما يناسب ⁨${prenom}⁩.';
	@override String get etatHoraireAChoisir => 'موعد للاختيار';
	@override String etatHoraireAChoisirDetail({required Object prenom}) => 'المواعيد المفتوحة لـ⁨${prenom}⁩ بانتظارك.';
	@override String get etatOffreIndisponible => 'هذا الموعد لم يعد مقترحًا';
	@override String etatOffreIndisponibleDetail({required Object prenom}) => 'سُحب الموعد المختار لـ⁨${prenom}⁩ قبل تكوين فصل. اختر موعدًا آخر: لم يضِع شيء.';
	@override String get etatDiagnosticRequis => 'التفضيل محفوظ';
	@override String etatDiagnosticRequisDetail({required Object prenom}) => 'بقي لقاء مع معلم لتحديد مستوى ⁨${prenom}⁩. ستقترح عليك الأكاديمية موعدًا.';
	@override String get etatDiagnosticEnAttente => 'الموعد مبرمج';
	@override String etatDiagnosticEnAttenteDetail({required Object prenom}) => 'لقاء مبرمج لتحديد مستوى ⁨${prenom}⁩.';
	@override String get etatClasseEnFormation => 'الفصل قيد التكوين';
	@override String etatClasseEnFormationDetail({required Object minimum}) => 'يبدأ الفصل ابتداءً من ⁨${minimum}⁩ طلاب. سنعلمك بمجرد تأكيده.';
	@override String get etatClasseEnFormationDetailSansMinimum => 'يبدأ الفصل ابتداءً من عدد معين من الطلاب. سنعلمك بمجرد تأكيده.';
	@override String get etatClasseConfirmee => 'الفصل مؤكَّد';
	@override String etatClasseConfirmeeDetail({required Object prenom}) => 'تكوّن فصل ⁨${prenom}⁩. ستجد حصصه في مساحته.';
	@override String get fuseauChange => 'تغيّر مكانك منذ هذا الاختيار';
	@override String get fuseauChangeDetail => 'الموعد نفسه عند الأكاديمية، لكنه لم يعد يقع في الساعة نفسها عندك. تحقّق من أنه ما زال يناسبك.';
	@override String get voirHoraires => 'عرض المواعيد';
	@override String get changerHoraire => 'تغيير الموعد';
	@override String get renoncerMotif => 'غيّرت الأسرة موعدها بعد اختيار المسار';
}

// Path: eleveConnexion
class _Traductions$eleveConnexion$ar extends Traductions$eleveConnexion$fr {
	_Traductions$eleveConnexion$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get entrerCode => 'لدي رمز';
	@override String get scanner => 'مسح المربع';
	@override String get choisirProfil => 'من أنت؟';
	@override late final _Traductions$eleveConnexion$profils$ar profils = _Traductions$eleveConnexion$profils$ar._(_root);
	@override late final _Traductions$eleveConnexion$pin$ar pin = _Traductions$eleveConnexion$pin$ar._(_root);
	@override late final _Traductions$eleveConnexion$saisie$ar saisie = _Traductions$eleveConnexion$saisie$ar._(_root);
	@override late final _Traductions$eleveConnexion$lecteur$ar lecteur = _Traductions$eleveConnexion$lecteur$ar._(_root);
	@override late final _Traductions$eleveConnexion$refus$ar refus = _Traductions$eleveConnexion$refus$ar._(_root);
}

// Path: presence
class _Traductions$presence$ar extends Traductions$presence$fr {
	_Traductions$presence$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الحضور';
	@override String get voir => 'عرض الحضور';
	@override String get mienne => 'حضورك';
	@override String get consolide => 'مُوحَّد';
	@override String get planifiee => 'درس قادم';
	@override String get enAttente => 'لم يصل بعد';
	@override String get enConnexion => 'جارٍ الاتصال';
	@override String get presente => 'في القاعة';
	@override String get enRetard => 'متأخر';
	@override String get deconnectee => 'انقطع الاتصال';
	@override String get enReconnexion => 'جارٍ إعادة الاتصال';
	@override String get reconnectee => 'عاد';
	@override String get sortie => 'غادر الدرس';
	@override String get absente => 'غياب';
	@override String get excusee => 'غياب بعذر';
	@override String get confirmationEnAttente => 'للتأكيد';
	@override String get corrigeeManuel => 'تصحيح يدوي';
	@override String get finalisee => 'نهائي';
	@override String get inconnu => 'حالة غير معروفة';
	@override String get entreeInstant => 'دخل القاعة للتو';
	@override String entreeMinutes({required Object minutes}) => 'في القاعة منذ ⁨${minutes}⁩ دقيقة';
	@override String retardMinutes({required Object minutes}) => '⁨${minutes}⁩ دقيقة بعد الموعد';
	@override String get silenceInstant => 'لا أخبار منذ بضع ثوانٍ';
	@override String silenceMinutes({required Object minutes}) => 'لا أخبار منذ ⁨${minutes}⁩ دقيقة';
	@override String get attenteInstant => 'بدأ الدرس للتو';
	@override String attenteMinutes({required Object minutes}) => 'بدأ الدرس منذ ⁨${minutes}⁩ دقيقة';
}

// Path: priere
class _Traductions$priere$ar extends Traductions$priere$fr {
	_Traductions$priere$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get fajr => 'الفجر';
	@override String get dhuhr => 'الظهر';
	@override String get asr => 'العصر';
	@override String get maghrib => 'المغرب';
	@override String get isha => 'العشاء';
	@override String entree({required Object priere, required Object minutes}) => '⁨${priere}⁩، ⁨${minutes}⁩ دقيقة';
	@override String annonce({required Object priere, required Object heure}) => 'سيتوقف هذا الدرس لصلاة ⁨${priere}⁩، نحو ⁨${heure}⁩.';
	@override String get annonceAucune => 'لا توقف مقرر أثناء هذا الدرس.';
	@override String alerte({required Object priere, required Object minutes}) => '⁨${priere}⁩ بعد ⁨${minutes}⁩ دقيقة';
	@override String alerteMaintenant({required Object priere, required Object heure}) => 'استراحة لصلاة ⁨${priere}⁩، الاستئناف الساعة ⁨${heure}⁩';
	@override String get pause => 'استراحة';
	@override String lieu({required Object lieu}) => 'أوقات محسوبة لـ⁨${lieu}⁩';
	@override String get lieuSansNom => 'أوقات محسوبة لمكان المعلم';
	@override String ajustee({required Object priere, required Object minutes}) => 'عدّل المعلم ⁨${priere}⁩ بـ⁨${minutes}⁩ دقيقة';
	@override String get reglagesAbsents => 'لم يضبط المعلم أوقات الصلاة بعد.';
}

// Path: tuteur
class _Traductions$tuteur$ar extends Traductions$tuteur$fr {
	_Traductions$tuteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tuteur$accueil$ar accueil = _Traductions$tuteur$accueil$ar._(_root);
	@override late final _Traductions$tuteur$reglages$ar reglages = _Traductions$tuteur$reglages$ar._(_root);
}

// Path: historique
class _Traductions$historique$ar extends Traductions$historique$fr {
	_Traductions$historique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'السجل';
	@override String get detailSeance => 'تفاصيل الحصة';
	@override late final _Traductions$historique$segments$ar segments = _Traductions$historique$segments$ar._(_root);
	@override List<String> get moisCourts => [
		'يناير',
		'فبراير',
		'مارس',
		'أبريل',
		'مايو',
		'يونيو',
		'يوليو',
		'أغسطس',
		'سبتمبر',
		'أكتوبر',
		'نوفمبر',
		'ديسمبر',
	];
	@override String dateCourte({required Object jour, required Object mois, required Object annee}) => '⁨${jour}⁩ ⁨${mois}⁩ ⁨${annee}⁩';
	@override String dateLongue({required Object jourSemaine, required Object jour, required Object mois, required Object annee}) => '⁨${jourSemaine}⁩ ⁨${jour}⁩ ⁨${mois}⁩ ⁨${annee}⁩';
	@override String plage({required Object debut, required Object fin}) => '⁨${debut}⁩ - ⁨${fin}⁩';
	@override late final _Traductions$historique$duree$ar duree = _Traductions$historique$duree$ar._(_root);
	@override String get fuseauListe => 'الساعات معروضة بتوقيت هذا الجهاز.';
	@override String fuseauDetail({required Object decalage}) => 'الساعات معروضة بتوقيت هذا الجهاز (UTC⁨${decalage}⁩).';
	@override String get classeInconnue => 'الفصل غير متاح';
	@override late final _Traductions$historique$selecteur$ar selecteur = _Traductions$historique$selecteur$ar._(_root);
	@override late final _Traductions$historique$filtres$ar filtres = _Traductions$historique$filtres$ar._(_root);
	@override String get retour => 'العودة إلى السجل';
	@override late final _Traductions$historique$etat$ar etat = _Traductions$historique$etat$ar._(_root);
	@override String get presenceIllisible => 'تعذّرت قراءة الحضور: تبقى الحالات غير معروفة الآن.';
	@override late final _Traductions$historique$seances$ar seances = _Traductions$historique$seances$ar._(_root);
	@override late final _Traductions$historique$observations$ar observations = _Traductions$historique$observations$ar._(_root);
	@override late final _Traductions$historique$seance$ar seance = _Traductions$historique$seance$ar._(_root);
	@override late final _Traductions$historique$observation$ar observation = _Traductions$historique$observation$ar._(_root);
}

// Path: appareils
class _Traductions$appareils$ar extends Traductions$appareils$fr {
	_Traductions$appareils$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الأجهزة';
	@override late final _Traductions$appareils$foyer$ar foyer = _Traductions$appareils$foyer$ar._(_root);
	@override late final _Traductions$appareils$eleve$ar eleve = _Traductions$appareils$eleve$ar._(_root);
	@override late final _Traductions$appareils$plateforme$ar plateforme = _Traductions$appareils$plateforme$ar._(_root);
	@override late final _Traductions$appareils$retrait$ar retrait = _Traductions$appareils$retrait$ar._(_root);
	@override late final _Traductions$appareils$emetteur$ar emetteur = _Traductions$appareils$emetteur$ar._(_root);
	@override String get regenerer => 'إنشاء رمز جديد';
	@override String get revoquer => 'إزالة';
	@override String get revoquerConfirmation => 'إزالة هذا الجهاز؟ لن يستطيع الاتصال ما لم يُعد وليّ الأمر ربطه برمز جديد.';
}

// Path: connexion
class _Traductions$connexion$ar extends Traductions$connexion$fr {
	_Traductions$connexion$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'تسجيل الدخول';
	@override String get intro => 'نرسل لك رابطًا بالبريد الإلكتروني. لا كلمة مرور تحفظها، ولا كلمة مرور تضيع.';
	@override String get courriel => 'بريدك الإلكتروني';
	@override String get courrielIndice => 'name@example.com';
	@override String get motDePasseDemo => 'كلمة مرور العرض التجريبي';
	@override String get envoyerLien => 'استلام الرابط';
	@override String get avecGoogle => 'المتابعة بحساب Google';
	@override String get ou => 'أو';
	@override String get lienEnvoye => 'أُرسل الرابط';
	@override String lienEnvoyeDetail({required Object courriel}) => 'افتح الرسالة المرسلة إلى ⁨${courriel}⁩، ثم اتبع الرابط. يمكنك ترك هذه الصفحة مفتوحة.';
	@override String get changerAdresse => 'استخدام عنوان آخر';
	@override String get erreurCourriel => 'يبدو أن هذا العنوان غير صالح.';
	@override String get erreurEnvoi => 'لم يكتمل الإرسال. أعد المحاولة بعد لحظة.';
	@override String get appareilEleveAide => 'أنت وليّ أمر وتجهّز جهاز طالب؟';
	@override String get appareilEleve => 'ربط جهاز طالب';
	@override String get renvoyer => 'إعادة إرسال الرابط';
	@override String renvoye({required Object courriel}) => 'أُرسل رابط جديد إلى ⁨${courriel}⁩. استخدم رابط أحدث رسالة.';
	@override String get erreurTropTot => 'أُرسل رابط للتو. انتظر قليلًا قبل طلب رابط آخر.';
	@override String get horsLigne => 'أنت غير متصل: لا يمكن إرسال الرابط الآن.';
	@override String get probleme => 'انتهت صلاحية الرابط أو لم يصل؟';
	@override String get decouvrir => 'اكتشف Rewayah Academy';
	@override late final _Traductions$connexion$recuperation$ar recuperation = _Traductions$connexion$recuperation$ar._(_root);
	@override late final _Traductions$connexion$feuilleAppareil$ar feuilleAppareil = _Traductions$connexion$feuilleAppareil$ar._(_root);
}

// Path: attente
class _Traductions$attente$ar extends Traductions$attente$fr {
	_Traductions$attente$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ملفك قيد التحقق';
	@override String get dossierIncomplet => 'ما زالت تنقص ملفك بعض الوثائق.';
	@override String get enVerification => 'نتحقق من ملفك.';
	@override String get refuse => 'رُفض الملف';
	@override String get suspendu => 'حسابك موقوف.';
	@override String get contacterAcademie => 'التواصل مع الأكاديمية';
	@override String deposeLe({required Object date}) => 'أُودع في ⁨${date}⁩';
	@override String get delai => 'يستغرق التحقق عادة أقل من 48 ساعة.';
	@override String get aFournir => 'للتقديم';
	@override String get pieceIdentite => 'وثيقة هوية';
	@override String get signatureContrat => 'توقيع العقد';
	@override String get carteAccuse => 'ما يجب أن تعرفه';
	@override String get deposerLaPiece => 'إيداع وثيقتي';
	@override String get signerLeContrat => 'القراءة والتوقيع';
	@override String get lireLaCarte => 'قراءة';
	@override String get toutEstDepose => 'كل شيء مودَع.';
	@override String get corriger => 'تصحيح';
	@override String get correctionImpossible => 'لا يمكن تعديل هذا الملف الآن.';
	@override String get actualiser => 'تحديث حالة الملف';
	@override String get suspenduDetail => 'يمكنك التواصل مع الأكاديمية لمعرفة الخطوات المطلوبة.';
	@override String get seDeconnecter => 'تسجيل الخروج';
	@override String get titreDossier => 'ملفك';
	@override String get titreCompte => 'حسابك';
	@override String get accordsARelire => 'بقي عليك قراءة شروطنا وقبولها.';
	@override String get accesTitre => 'أُنشئ حسابك';
	@override String get accesEnPreparation => 'فتح حسابك ليس تلقائيًا بعد.';
	@override String get aucunDocument => 'ليس عليك إرسال أي وثيقة.';
	@override String get accesContact => 'يمكن للأكاديمية فتحه لك: تواصل معها.';
	@override String get actualiserCompte => 'تحديث';
	@override String reste({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لم يبق أي عنصر للتقديم.',
		one: 'بقي عنصر واحد للتقديم.',
		two: 'بقي عنصران للتقديم.',
		few: 'بقيت ⁨${n}⁩ عناصر للتقديم.',
		many: 'بقي ⁨${n}⁩ عنصرًا للتقديم.',
		other: 'بقي ⁨${n}⁩ عنصر للتقديم.',
	);
	@override String get etatAFournir => 'للتقديم';
	@override String prochaineEtape({required Object etape}) => 'الخطوة التالية: ⁨${etape}⁩';
	@override String refuseDetail({required Object element}) => 'لطلب التحقق من جديد، ابدأ بهذا العنصر: ⁨${element}⁩.';
	@override String get refuseSansElement => 'يمكنك التواصل مع الأكاديمية لمعرفة الخطوات المطلوبة.';
	@override String get illisible => 'حالة ملفك لا تظهر الآن.';
	@override String get horsLigne => 'أنت غير متصل. ستظهر حالة ملفك بمجرد عودة الشبكة.';
}

// Path: inscription
class _Traductions$inscription$ar extends Traductions$inscription$fr {
	_Traductions$inscription$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'إنشاء حسابك';
	@override String etapeSur({required Object n, required Object total}) => 'الخطوة ⁨${n}⁩ من ⁨${total}⁩';
	@override String tempsRestant({required Object minutes}) => 'نحو ⁨${minutes}⁩ دقيقة';
	@override String get roleQuestion => 'هل تسجّل كوليّ أمر أم كمعلم؟';
	@override String get roleTuteur => 'وليّ أمر';
	@override String get roleEleveAdulte => 'طالب بالغ، لنفسي';
	@override String get roleEnseignant => 'معلم';
	@override String get autreAide => 'راسل الأكاديمية وسننشئ لك وصولك. لا تستطيع هذه الصفحة فعل ذلك عنك.';
	@override String get identiteQuestion => 'ما اسمك؟';
	@override String get identiteRaison => 'يجب أن يكون هذا الاسم هو الاسم الموجود في وثيقة هويتك.';
	@override String get prenom => 'الاسم';
	@override String get nom => 'اللقب';
	@override String get genreQuestion => 'أنت';
	@override String get genreHomme => 'رجل';
	@override String get genreFemme => 'امرأة';
	@override String get genreRaison => 'تُستخدم هذه الإجابة فقط لتسليم وثيقة هويتك إلى موظف من الجنس نفسه.';
	@override String get recapitulatif => 'قبل المتابعة';
	@override String get creer => 'إنشاء حسابي';
	@override String get erreur => 'لم يكتمل إنشاء الحساب. أعد المحاولة بعد لحظة.';
	@override String get champRequis => 'هذه الإجابة ضرورية للمتابعة.';
	@override String etapeCourte({required Object n, required Object total}) => '⁨${n}⁩ من ⁨${total}⁩';
	@override String get retourEtape => 'العودة إلى الخطوة السابقة';
	@override String get seDeconnecter => 'تسجيل الخروج';
	@override String get modifier => 'تعديل';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get erreurActualisation => 'أُنشئ حسابك، لكن تعذّر تحديث الاتصال. أعد المحاولة، أو سجّل الخروج ثم الدخول من جديد.';
	@override late final _Traductions$inscription$usage$ar usage = _Traductions$inscription$usage$ar._(_root);
	@override late final _Traductions$inscription$recap$ar recap = _Traductions$inscription$recap$ar._(_root);
}

// Path: consentement
class _Traductions$consentement$ar extends Traductions$consentement$fr {
	_Traductions$consentement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الموافقات';
	@override late final _Traductions$consentement$texte$ar texte = _Traductions$consentement$texte$ar._(_root);
	@override late final _Traductions$consentement$comment$ar comment = _Traductions$consentement$comment$ar._(_root);
	@override late final _Traductions$consentement$compte$ar compte = _Traductions$consentement$compte$ar._(_root);
}

// Path: foyer
class _Traductions$foyer$ar extends Traductions$foyer$fr {
	_Traductions$foyer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الأسرة';
	@override String get ajouterProfil => 'إضافة ملف طالب';
	@override String get sousTitre => 'ملفات الطلاب في أسرتك';
	@override String get membres => 'ملفات الطلاب';
	@override late final _Traductions$foyer$vide$ar vide = _Traductions$foyer$vide$ar._(_root);
	@override late final _Traductions$foyer$membre$ar membre = _Traductions$foyer$membre$ar._(_root);
	@override String get classesIndisponibles => 'فصل كل طالب لا يظهر في هذه الصفحة بعد.';
	@override String get classesEchec => 'تعذّرت قراءة فصل بعض الطلاب.';
	@override String get relireClasses => 'إعادة قراءة الفصول';
	@override String get inscriptionIllisible => 'التسجيل الجاري لكل طالب لا يظهر في هذه الصفحة بعد.';
	@override String get appareilsPartages => 'الأجهزة المشتركة';
	@override String get appareilsFoyer => 'أجهزة الأسرة';
	@override String get appareilsFoyerLegende => 'ربط جهاز، عرض الأجهزة المربوطة، إزالة أحدها';
	@override String get creerMonProfil => 'إنشاء ملفي كطالب';
	@override late final _Traductions$foyer$monProfil$ar monProfil = _Traductions$foyer$monProfil$ar._(_root);
	@override late final _Traductions$foyer$ajout$ar ajout = _Traductions$foyer$ajout$ar._(_root);
}

// Path: adulte
class _Traductions$adulte$ar extends Traductions$adulte$fr {
	_Traductions$adulte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$adulte$nav$ar nav = _Traductions$adulte$nav$ar._(_root);
	@override late final _Traductions$adulte$accueil$ar accueil = _Traductions$adulte$accueil$ar._(_root);
	@override late final _Traductions$adulte$historique$ar historique = _Traductions$adulte$historique$ar._(_root);
	@override late final _Traductions$adulte$maClasse$ar maClasse = _Traductions$adulte$maClasse$ar._(_root);
	@override late final _Traductions$adulte$monEspace$ar monEspace = _Traductions$adulte$monEspace$ar._(_root);
	@override late final _Traductions$adulte$coranDemo$ar coranDemo = _Traductions$adulte$coranDemo$ar._(_root);
	@override late final _Traductions$adulte$recharge$ar recharge = _Traductions$adulte$recharge$ar._(_root);
	@override late final _Traductions$adulte$paiements$ar paiements = _Traductions$adulte$paiements$ar._(_root);
	@override late final _Traductions$adulte$famille$ar famille = _Traductions$adulte$famille$ar._(_root);
	@override late final _Traductions$adulte$invitation$ar invitation = _Traductions$adulte$invitation$ar._(_root);
	@override late final _Traductions$adulte$acceptation$ar acceptation = _Traductions$adulte$acceptation$ar._(_root);
	@override late final _Traductions$adulte$sortie$ar sortie = _Traductions$adulte$sortie$ar._(_root);
	@override late final _Traductions$adulte$reprise$ar reprise = _Traductions$adulte$reprise$ar._(_root);
	@override late final _Traductions$adulte$demo$ar demo = _Traductions$adulte$demo$ar._(_root);
}

// Path: dossiers
class _Traductions$dossiers$ar extends Traductions$dossiers$fr {
	_Traductions$dossiers$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ملفات للاعتماد';
	@override String get sousTitre => 'ادرس الملفات الجاهزة لاتخاذ قرار.';
	@override String get aucun => 'لا ملف ينتظر الاعتماد.';
	@override String get aucunDetail => 'ستظهر الملفات الجديدة هنا حين تصبح جاهزة.';
	@override late final _Traductions$dossiers$file$ar file = _Traductions$dossiers$file$ar._(_root);
	@override late final _Traductions$dossiers$detail$ar detail = _Traductions$dossiers$detail$ar._(_root);
	@override late final _Traductions$dossiers$visionneuse$ar visionneuse = _Traductions$dossiers$visionneuse$ar._(_root);
	@override late final _Traductions$dossiers$revue$ar revue = _Traductions$dossiers$revue$ar._(_root);
	@override String get restantUn => 'ملف واحد قيد الانتظار';
	@override String restants({required Object n}) => '⁨${n}⁩ ملفات قيد الانتظار';
	@override String deposeLe({required Object date}) => 'أُودع في ⁨${date}⁩';
	@override String get inscritAujourdhui => 'مسجَّل اليوم';
	@override String get inscritDepuisUnJour => 'مسجَّل منذ يوم';
	@override String inscritDepuis({required Object jours}) => 'مسجَّل منذ ⁨${jours}⁩ أيام';
	@override String get sansPiece => 'لا وثيقة مودَعة';
	@override String get sansPieceDetail => 'أنشأ هذا الشخص حسابه وقبل العقود، لكنه لم يرسل وثيقة هويته بعد. لا شيء للتحقق إذن: الخطوة عنده.';
	@override String get pieceNonVisible => 'وثيقة خارج صلاحيتك';
	@override String get pieceNonVisibleDetail => 'أُودعت وثيقة بالفعل، لكن قاعدة الجنس تمنعك من الاطلاع عليها. يجب أن يتحقق منها موظف من جنس هذا الشخص.';
	@override String get rienATrancher => 'لا شيء للحسم الآن';
	@override String get apercu => 'الوثيقة المودَعة';
	@override String get apercuIndisponible => 'المعاينة غير متاحة';
	@override String get verifications => 'عمليات التحقق';
	@override String get pointLisible => 'الوثيقة مقروءة';
	@override String get pointNom => 'الاسم يطابق اسم الحساب';
	@override String get pointValidite => 'الوثيقة غير منتهية الصلاحية';
	@override String get verdict => 'القرار';
	@override String get approuver => 'اعتماد الملف';
	@override String get refuser => 'رفض الملف';
	@override late final _Traductions$dossiers$profilACompleter$ar profilACompleter = _Traductions$dossiers$profilACompleter$ar._(_root);
	@override late final _Traductions$dossiers$refus$ar refus = _Traductions$dossiers$refus$ar._(_root);
	@override late final _Traductions$dossiers$validation$ar validation = _Traductions$dossiers$validation$ar._(_root);
	@override late final _Traductions$dossiers$decision$ar decision = _Traductions$dossiers$decision$ar._(_root);
}

// Path: kyc
class _Traductions$kyc$ar extends Traductions$kyc$fr {
	_Traductions$kyc$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'وثيقة هويتك';
	@override String get intro => 'تكفي صورة مقروءة. تُحفظ مدة التحقق، ثم تُحذف.';
	@override String get confidentialite => 'تُودَع وثيقة هويتك كما هي: ليست عامة أبدًا، ولا يطلع عليها إلا الإدارة، وتشترطها قوانين حماية الطفولة.';
	@override String get typeQuestion => 'أي وثيقة تودع؟';
	@override String get carteIdentite => 'بطاقة هوية';
	@override String get passeport => 'جواز سفر';
	@override String get titreSejour => 'بطاقة إقامة';
	@override String get choisirFichier => 'اختيار الصورة';
	@override String get fichierChoisi => 'الصورة جاهزة للإرسال';
	@override String get envoyer => 'إرسال وثيقتي';
	@override String get envoiEnCours => 'جارٍ الإرسال';
	@override String get deposee => 'استُلمت الوثيقة';
	@override String get erreur => 'لم يكتمل الإرسال. أعد المحاولة بعد لحظة.';
	@override String tropVolumineux({required Object taille}) => 'هذه الصورة تتجاوز ⁨${taille}⁩ م.ب. التقطها بجودة أقل.';
}

// Path: contrat
class _Traductions$contrat$ar extends Traductions$contrat$fr {
	_Traductions$contrat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ما توقّع عليه';
	@override String get intro => 'نقطتان أهم من غيرهما. هما مكتوبتان هنا بوضوح بدل أن تكونا وسط نص طويل.';
	@override String get pointEnregistrement => 'يُسجَّل كل درس صوتيًا، ويُحفظ ثلاثين يومًا، ثم يُحذف. كل استماع يُدوَّن في السجل، مع اسم المستمع.';
	@override String get pointControle => 'يمكن لمراقب جودة أن يحضر درسًا دون أن يُرى. تذكّر القاعة بذلك باستمرار، سواء جرت الزيارة أم لا.';
	@override String get pointCoordonnees => 'لا ترى أبدًا بيانات اتصال أسرة: لا الاسم الكامل، ولا البريد الإلكتروني، ولا الهاتف.';
	@override String get lireTexte => 'قراءة النص كاملًا';
	@override String get accepter => 'قرأت وأوافق';
	@override String accepteLe({required Object date}) => 'مقبول في ⁨${date}⁩';
	@override String get erreur => 'لم يكتمل التوقيع. أعد المحاولة بعد لحظة.';
	@override String get horsLigne => 'أنت غير متصل. ستُحفظ موافقتك بمجرد عودة الشبكة، بالضغط من جديد.';
	@override String get caseRequise => 'حدّد المربع للمتابعة.';
}

// Path: bienvenue
class _Traductions$bienvenue$ar extends Traductions$bienvenue$fr {
	_Traductions$bienvenue$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مرحبًا';
	@override String get accroche => 'تعلّم القرآن في فصل، مع معلم ثابت';
	@override String get phrase => 'حصص عبر الفيديو، في موعد ثابت، لك أو لطلاب أسرتك.';
	@override String get pointsTitre => 'كيف تجري الأمور';
	@override String get pointClasseTitre => 'فصل ثابت';
	@override String get pointClasse => 'الزملاء أنفسهم والموعد نفسه، كل أسبوع.';
	@override String get pointEnseignantTitre => 'معلم ثابت';
	@override String get pointEnseignant => 'سيد أو سيدة يتابع كل طالب من حصة إلى أخرى.';
	@override String get pointFoyerTitre => 'حساب واحد للأسرة';
	@override String get pointFoyer => 'تُتابَع حصص كل طالب في الأسرة من حسابك.';
	@override String get commencer => 'ابدأ';
	@override String get dejaCompte => 'لدي حساب بالفعل';
}

// Path: creneaux
class _Traductions$creneaux$ar extends Traductions$creneaux$fr {
	_Traductions$creneaux$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المواعيد';
	@override String get ongletHeures => 'ساعاتي';
	@override String get ongletEleves => 'طلاب في الانتظار';
	@override String mesEleves({required Object nombre, required Object plafond}) => 'تتابع ⁨${nombre}⁩ طلاب من ⁨${plafond}⁩ ممكنين.';
	@override String get aucunEleve => 'لا طالب في الانتظار في ساعاتك';
	@override String get aucunEleveDetail => 'اقترح ساعات أخرى لترى أسرًا أكثر.';
	@override String attendDepuis({required Object jours}) => 'ينتظر منذ ⁨${jours}⁩ أيام';
	@override String get attendUnJour => 'ينتظر منذ يوم';
	@override String get attendAujourdhui => 'قُدِّم الطلب اليوم';
	@override String niveau({required Object niveau}) => 'المستوى ⁨${niveau}⁩';
	@override String prendre({required Object jour, required Object heure}) => 'قبول ⁨${jour}⁩ الساعة ⁨${heure}⁩';
	@override String get priseEnCours => 'جارٍ الحفظ';
	@override String plafondAtteint({required Object nombre}) => 'تتابع بالفعل ⁨${nombre}⁩ طلاب، وهو حدك الأقصى. قبول طالب التزام دائم، لا حجز.';
	@override String get plafondDemander => 'طلب متابعة طلاب أكثر';
	@override String get demandeTitre => 'كم طالبًا يمكنك أن تتابع؟';
	@override String get demandeMotif => 'لماذا هذا التغيير؟';
	@override String get demandeMotifRequis => 'السبب ضروري: هو الذي يسمح بالحسم.';
	@override String get demandeEnvoyer => 'إرسال الطلب';
	@override String get demandeEnvoyee => 'أُرسل الطلب. ستحسم فيه الإدارة.';
	@override String eleves({required Object nombre}) => '⁨${nombre}⁩ طلاب';
	@override String erreur({required Object message}) => 'لم تكتمل العملية: ⁨${message}⁩';
}

// Path: disponibilites
class _Traductions$disponibilites$ar extends Traductions$disponibilites$fr {
	_Traductions$disponibilites$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'متى يستطيع أطفالك متابعة درس؟';
	@override String get titreEnseignant => 'متى تستطيع التدريس؟';
	@override String consigne({required Object prenom}) => 'المس الساعات الممكنة لـ⁨${prenom}⁩.';
	@override String get consigneEnseignant => 'المس الساعات التي تكون فيها متاحًا.';
	@override String get effet => 'سيختار معلم من بين هذه الساعات. كلما اقترحت أكثر، بدأ الدرس أسرع.';
	@override String get effetEnseignant => 'لن ترى إلا الطلاب الذين تتقاطع ساعاتهم مع ساعاتك.';
	@override String fuseau({required Object fuseau}) => 'الساعات معروضة بتوقيت ⁨${fuseau}⁩';
	@override String aucune({required Object prenom}) => 'لا ساعة مقترحة لـ⁨${prenom}⁩';
	@override String aucuneDetail({required Object prenom}) => 'دون موعد، لا يستطيع أي معلم تولي ⁨${prenom}⁩.';
	@override String posees({required Object nombre}) => '⁨${nombre}⁩ ساعات مقترحة';
	@override String get poseeUne => 'ساعة واحدة مقترحة';
	@override String cellulePosee({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩، مقترحة. المس للإزالة';
	@override String celluleLibre({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩، شاغرة. المس للاقتراح';
	@override String get erreur => 'تعذّر حفظ هذا الموعد. أعد المحاولة.';
	@override List<String> get joursCourts => [
		'اثن',
		'ثلا',
		'أرب',
		'خمي',
		'جمع',
		'سبت',
		'أحد',
	];
	@override List<String> get joursLongs => [
		'الاثنين',
		'الثلاثاء',
		'الأربعاء',
		'الخميس',
		'الجمعة',
		'السبت',
		'الأحد',
	];
}

// Path: controleur
class _Traductions$controleur$ar extends Traductions$controleur$fr {
	_Traductions$controleur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$controleur$historique$ar historique = _Traductions$controleur$historique$ar._(_root);
	@override late final _Traductions$controleur$complement$ar complement = _Traductions$controleur$complement$ar._(_root);
	@override late final _Traductions$controleur$compteRendu$ar compteRendu = _Traductions$controleur$compteRendu$ar._(_root);
	@override late final _Traductions$controleur$observation$ar observation = _Traductions$controleur$observation$ar._(_root);
	@override late final _Traductions$controleur$echanges$ar echanges = _Traductions$controleur$echanges$ar._(_root);
	@override late final _Traductions$controleur$demo$ar demo = _Traductions$controleur$demo$ar._(_root);
	@override late final _Traductions$controleur$acces$ar acces = _Traductions$controleur$acces$ar._(_root);
	@override late final _Traductions$controleur$controle$ar controle = _Traductions$controleur$controle$ar._(_root);
}

// Path: agent
class _Traductions$agent$ar extends Traductions$agent$fr {
	_Traductions$agent$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'دخول موظف';
	@override String get intro => 'تفتح هذه الصفحة التطبيق للقراءة فقط، بالرمز الذي سلّمته الأكاديمية.';
	@override String get jeton => 'رمز المتابعة';
	@override String get jetonExemple => 'rag_...';
	@override String get entrer => 'فتح التطبيق';
	@override String get ouverture => 'جارٍ الفتح';
	@override String get refus => 'رُفض الرمز';
	@override String get refusDetail => 'هذا الرمز غير معروف أو ملغى أو منتهي الصلاحية. اطلب رمزًا جديدًا من الأكاديمية.';
	@override String get indisponible => 'الخدمة غير متاحة';
	@override String get indisponibleDetail => 'لم تستجب عملية فتح الجلسة. أعد المحاولة بعد لحظة.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get bandeau => 'متابعة، للقراءة فقط';
	@override String get bandeauMasque => 'الأسماء مخفية';
	@override String bandeauExpire({required Object heure}) => 'حتى ⁨${heure}⁩';
}

// Path: admin
class _Traductions$admin$ar extends Traductions$admin$fr {
	_Traductions$admin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$admin$tableau$ar tableau = _Traductions$admin$tableau$ar._(_root);
	@override late final _Traductions$admin$demandes$ar demandes = _Traductions$admin$demandes$ar._(_root);
	@override late final _Traductions$admin$attribution$ar attribution = _Traductions$admin$attribution$ar._(_root);
	@override late final _Traductions$admin$groupes$ar groupes = _Traductions$admin$groupes$ar._(_root);
	@override late final _Traductions$admin$diagnostics$ar diagnostics = _Traductions$admin$diagnostics$ar._(_root);
	@override late final _Traductions$admin$qualite$ar qualite = _Traductions$admin$qualite$ar._(_root);
	@override late final _Traductions$admin$regles$ar regles = _Traductions$admin$regles$ar._(_root);
	@override late final _Traductions$admin$fonctionnalites$ar fonctionnalites = _Traductions$admin$fonctionnalites$ar._(_root);
	@override late final _Traductions$admin$conservationDonnees$ar conservationDonnees = _Traductions$admin$conservationDonnees$ar._(_root);
	@override late final _Traductions$admin$politiqueRevueKyc$ar politiqueRevueKyc = _Traductions$admin$politiqueRevueKyc$ar._(_root);
	@override late final _Traductions$admin$evaluations$ar evaluations = _Traductions$admin$evaluations$ar._(_root);
	@override late final _Traductions$admin$progression$ar progression = _Traductions$admin$progression$ar._(_root);
	@override late final _Traductions$admin$programmes$ar programmes = _Traductions$admin$programmes$ar._(_root);
	@override late final _Traductions$admin$journal$ar journal = _Traductions$admin$journal$ar._(_root);
	@override late final _Traductions$admin$observations$ar observations = _Traductions$admin$observations$ar._(_root);
	@override late final _Traductions$admin$comptes$ar comptes = _Traductions$admin$comptes$ar._(_root);
	@override late final _Traductions$admin$agents$ar agents = _Traductions$admin$agents$ar._(_root);
	@override late final _Traductions$admin$notifications$ar notifications = _Traductions$admin$notifications$ar._(_root);
}

// Path: commun.sections
class _Traductions$commun$sections$ar extends Traductions$commun$sections$fr {
	_Traductions$commun$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get page => 'أقسام الصفحة';
}

// Path: commun.demonstration
class _Traductions$commun$demonstration$ar extends Traductions$commun$demonstration$fr {
	_Traductions$commun$demonstration$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get repere => 'عرض تجريبي';
	@override String get repereLu => 'وضع العرض التجريبي';
}

// Path: commun.etape
class _Traductions$commun$etape$ar extends Traductions$commun$etape$fr {
	_Traductions$commun$etape$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String sur({required Object n, required Object total}) => '⁨${n}⁩ من ⁨${total}⁩';
	@override String surLue({required Object n, required Object total}) => 'الخطوة ⁨${n}⁩ من ⁨${total}⁩';
}

// Path: commun.choix
class _Traductions$commun$choix$ar extends Traductions$commun$choix$fr {
	_Traductions$commun$choix$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get indisponible => 'غير متاح';
}

// Path: commun.etats
class _Traductions$commun$etats$ar extends Traductions$commun$etats$fr {
	_Traductions$commun$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$etats$chargementProlonge$ar chargementProlonge = _Traductions$commun$etats$chargementProlonge$ar._(_root);
	@override late final _Traductions$commun$etats$horsLigne$ar horsLigne = _Traductions$commun$etats$horsLigne$ar._(_root);
	@override late final _Traductions$commun$etats$reconnexion$ar reconnexion = _Traductions$commun$etats$reconnexion$ar._(_root);
	@override late final _Traductions$commun$etats$echecServeur$ar echecServeur = _Traductions$commun$etats$echecServeur$ar._(_root);
	@override late final _Traductions$commun$etats$introuvable$ar introuvable = _Traductions$commun$etats$introuvable$ar._(_root);
	@override late final _Traductions$commun$etats$accesRefuse$ar accesRefuse = _Traductions$commun$etats$accesRefuse$ar._(_root);
	@override late final _Traductions$commun$etats$sessionExpiree$ar sessionExpiree = _Traductions$commun$etats$sessionExpiree$ar._(_root);
	@override late final _Traductions$commun$etats$dossierEnAttente$ar dossierEnAttente = _Traductions$commun$etats$dossierEnAttente$ar._(_root);
	@override late final _Traductions$commun$etats$aucunResultat$ar aucunResultat = _Traductions$commun$etats$aucunResultat$ar._(_root);
	@override late final _Traductions$commun$etats$permissionRefusee$ar permissionRefusee = _Traductions$commun$etats$permissionRefusee$ar._(_root);
	@override late final _Traductions$commun$etats$ressourceExpiree$ar ressourceExpiree = _Traductions$commun$etats$ressourceExpiree$ar._(_root);
	@override late final _Traductions$commun$etats$indisponible$ar indisponible = _Traductions$commun$etats$indisponible$ar._(_root);
	@override String get reessaisEpuises => 'ما زال لا رد. أعد المحاولة لاحقًا.';
	@override String get horsLigneDemarrage => 'يحتاج Rewayah إلى الإنترنت للتحقق من حسابك. أعد توصيل هذا الجهاز، ثم أعد المحاولة.';
	@override late final _Traductions$commun$etats$actions$ar actions = _Traductions$commun$etats$actions$ar._(_root);
}

// Path: commun.entete
class _Traductions$commun$entete$ar extends Traductions$commun$entete$fr {
	_Traductions$commun$entete$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get retour => 'رجوع';
	@override String get notifications => 'الإشعارات';
	@override String get notificationsUneNonLue => 'الإشعارات، واحد غير مقروء';
	@override String notificationsNonLues({required Object nombre}) => 'الإشعارات، ⁨${nombre}⁩ غير مقروءة';
}

// Path: commun.selecteurProfils
class _Traductions$commun$selecteurProfils$ar extends Traductions$commun$selecteurProfils$fr {
	_Traductions$commun$selecteurProfils$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String etiquette({required Object prenom, required Object etat}) => '⁨${prenom}⁩، ⁨${etat}⁩';
	@override String get ajouter => 'إضافة';
	@override String get ajouterSemantique => 'إضافة ملف طالب';
}

// Path: commun.theme
class _Traductions$commun$theme$ar extends Traductions$commun$theme$fr {
	_Traductions$commun$theme$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'المظهر';
	@override String get clair => 'المظهر الفاتح';
	@override String get sombre => 'المظهر الداكن';
}

// Path: commun.demarrage
class _Traductions$commun$demarrage$ar extends Traductions$commun$demarrage$fr {
	_Traductions$commun$demarrage$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouverture => 'جارٍ فتح Rewayah';
}

// Path: commun.dates
class _Traductions$commun$dates$ar extends Traductions$commun$dates$fr {
	_Traductions$commun$dates$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override List<String> get jours => [
		'الاثنين',
		'الثلاثاء',
		'الأربعاء',
		'الخميس',
		'الجمعة',
		'السبت',
		'الأحد',
	];
	@override List<String> get mois => [
		'يناير',
		'فبراير',
		'مارس',
		'أبريل',
		'مايو',
		'يونيو',
		'يوليو',
		'أغسطس',
		'سبتمبر',
		'أكتوبر',
		'نوفمبر',
		'ديسمبر',
	];
	@override String jourDate({required Object jour, required Object numero, required Object mois}) => '⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩';
}

// Path: classe.entree
class _Traductions$classe$entree$ar extends Traductions$classe$entree$fr {
	_Traductions$classe$entree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String coursDans({required Object duree}) => 'الدرس بعد ⁨${duree}⁩';
	@override String get coursImminent => 'الدرس بعد أقل من دقيقة';
	@override String get rejoindre => 'انضمام';
	@override String rejoindreLecteur({required Object classe}) => 'الانضمام إلى حصة ⁨${classe}⁩';
	@override String salleOuverte({required Object duree}) => 'القاعة مفتوحة. تبدأ الحصة بعد ⁨${duree}⁩.';
	@override String get salleOuverteImminent => 'القاعة مفتوحة. تبدأ الحصة بعد أقل من دقيقة.';
	@override String get preparation => 'التحضير جارٍ';
	@override String attente({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ⁨${duree}⁩.';
	@override String get attenteImminent => 'أنت في القاعة. تبدأ الحصة بعد أقل من دقيقة.';
	@override String get enDirect => 'الحصة مباشرة';
	@override String get tempsEcoule => 'انتهى الوقت المقرر';
	@override String get terminee => 'انتهت الحصة';
	@override String get annulee => 'أُلغيت الحصة';
	@override String get aucune => 'لا توجد حصة مقررة';
	@override String get horsLigne => 'أنت غير متصل. تحتاج الحصة إلى اتصال.';
	@override String get indisponible => 'معلومات الحصة غير متاحة حاليًا.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get chargementSeance => 'جارٍ تحميل الحصة القادمة.';
	@override String progressionValeur({required Object chapitre, required Object pourcentage}) => '⁨${chapitre}⁩ · ⁨${pourcentage}⁩٪';
	@override String dst({required Object avant, required Object apres}) => 'تغيير التوقيت: سينتقل الدرس من ⁨${avant}⁩ إلى ⁨${apres}⁩.';
	@override late final _Traductions$classe$entree$annonce$ar annonce = _Traductions$classe$entree$annonce$ar._(_root);
	@override String get accesInverifiable => 'تعذّر التحقق من الدخول إلى القاعة الآن.';
	@override late final _Traductions$classe$entree$demo$ar demo = _Traductions$classe$entree$demo$ar._(_root);
}

// Path: classe.seance
class _Traductions$classe$seance$ar extends Traductions$classe$seance$fr {
	_Traductions$classe$seance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucune => 'لا حصة مقررة';
	@override String aucuneDetail({required Object prenom}) => 'ستظهر هنا الحصة القادمة لـ⁨${prenom}⁩ بمجرد جدولتها.';
	@override String get illisible => 'تعذّرت قراءة الحصة القادمة.';
	@override String presence({required Object prenom, required Object etat}) => '⁨${prenom}⁩: ⁨${etat}⁩';
}

// Path: classe.observation
class _Traductions$classe$observation$ar extends Traductions$classe$observation$fr {
	_Traductions$classe$observation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get commentCaMarche => 'كيف يعمل ذلك؟';
	@override String get uneVisite => 'زيارة واحدة متاحة';
	@override String visites({required Object nombre}) => '⁨${nombre}⁩ زيارات متاحة';
	@override String resume({required Object visites, required Object duree}) => '⁨${visites}⁩ · ⁨${duree}⁩ لكل زيارة';
	@override String get restanteAucune => 'لا زيارة متبقية لهذه الحصة';
	@override String get restanteUne => 'زيارة واحدة متبقية لهذه الحصة';
	@override String restantes({required Object nombre}) => 'الزيارات المتبقية لهذه الحصة: ⁨${nombre}⁩';
	@override String minutes({required Object minutes}) => '⁨${minutes}⁩ دقيقة';
	@override String minutesSecondes({required Object minutes, required Object secondes}) => '⁨${minutes}⁩ د ⁨${secondes}⁩ ث';
	@override String secondes({required Object secondes}) => '⁨${secondes}⁩ ث';
	@override late final _Traductions$classe$observation$motif$ar motif = _Traductions$classe$observation$motif$ar._(_root);
}

// Path: classe.pagePlanning
class _Traductions$classe$pagePlanning$ar extends Traductions$classe$pagePlanning$fr {
	_Traductions$classe$pagePlanning$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get prochaines => 'الحصص القادمة';
	@override String ligne({required Object heure, required Object duree}) => '⁨${heure}⁩ · ⁨${duree}⁩';
	@override String ligneFuseau({required Object heure, required Object fuseau, required Object duree}) => '⁨${heure}⁩ (⁨${fuseau}⁩) · ⁨${duree}⁩';
	@override String get aucune => 'لا حصص قادمة حتى الآن';
	@override String aucuneDetail({required Object prenom}) => 'ستظهر هنا الحصص القادمة لـ⁨${prenom}⁩ بمجرد جدولتها.';
	@override String get habituelIndisponible => 'الأيام المعتادة للفصل لا تظهر هنا بعد: تظهر فقط الحصص المجدولة.';
	@override String get indisponible => 'جدول الفصل غير مربوط بهذه المساحة بعد.';
}

// Path: classe.pageTravail
class _Traductions$classe$pageTravail$ar extends Traductions$classe$pageTravail$fr {
	_Traductions$classe$pageTravail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucun => 'لا شيء للتحضير الآن';
	@override String get aucunDetail => 'سيظهر هنا العمل الذي يكلّف به المعلم.';
	@override String get indisponible => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.';
	@override String echeance({required Object date}) => 'الموعد النهائي: ⁨${date}⁩';
	@override String get nonCochable => 'لا يمكن بعد تعليم عمل كمنجز من هنا.';
	@override late final _Traductions$classe$pageTravail$statut$ar statut = _Traductions$classe$pageTravail$statut$ar._(_root);
}

// Path: classe.pageRessources
class _Traductions$classe$pageRessources$ar extends Traductions$classe$pageRessources$fr {
	_Traductions$classe$pageRessources$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucune => 'لا موارد لهذا الفصل حتى الآن';
	@override String get aucuneDetail => 'ستظهر هنا المواد التي يختارها المعلم.';
	@override String get indisponible => 'مكتبة الفصل غير مربوطة بهذه المساحة بعد.';
}

// Path: classe.pageProgression
class _Traductions$classe$pageProgression$ar extends Traductions$classe$pageProgression$fr {
	_Traductions$classe$pageProgression$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String indisponible({required Object prenom}) => 'تقدم ⁨${prenom}⁩ غير مُشارَك هنا بعد.';
	@override String get niveau => 'المستوى';
	@override String get jalons => 'المراحل المنجزة';
	@override String get aucune => 'لا مرحلة مُشارَكة حتى الآن';
	@override String get aucuneDetail => 'سيظهر هنا التقدم الذي يشاركه المعلم مع الأسرة.';
}

// Path: classe.pageCatalogue
class _Traductions$classe$pageCatalogue$ar extends Traductions$classe$pageCatalogue$fr {
	_Traductions$classe$pageCatalogue$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String pour({required Object prenom}) => 'لـ⁨${prenom}⁩';
	@override String get proposees => 'الفصول المقترحة';
	@override String get indisponible => 'اختيار الفصل عبر الإنترنت غير مفتوح بعد.';
	@override String get aucune => 'لا فصل مناسب الآن';
	@override String aucuneDetail({required Object prenom}) => 'لا فصل مفتوح يناسب ملف ⁨${prenom}⁩ حاليًا.';
	@override String get eleveInconnuTitre => 'هذا الملف ليس في أسرتك';
	@override String get eleveInconnuPhrase => 'عد إلى الرئيسية واختر ملف الطالب المعني.';
	@override String get horairesAbsents => 'أيام هذا الفصل وساعاته لا تظهر هنا بعد.';
	@override String seanceHebdo({required Object jour, required Object heure, required Object duree}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩ · ⁨${duree}⁩ دقيقة';
	@override String fuseauClasse({required Object fuseau}) => 'توقيت الفصل (⁨${fuseau}⁩)';
	@override String get placeUne => 'مقعد واحد متبقٍ';
	@override String places({required Object nombre}) => '⁨${nombre}⁩ مقاعد متبقية';
	@override late final _Traductions$classe$pageCatalogue$etat$ar etat = _Traductions$classe$pageCatalogue$etat$ar._(_root);
	@override String get choisir => 'اختيار هذا الفصل';
	@override String get rejoindreAttente => 'الانضمام إلى قائمة الانتظار';
	@override String get precisionsTitre => 'قبل الاختيار';
	@override String get precisionEnseignant => 'يحتفظ الفصل بالمعلم نفسه في كل حصصه.';
	@override String get precisionPlaces => 'المقاعد المعروضة هي مقاعد الأكاديمية لحظة القراءة.';
	@override String get precisionReserve => 'لا شيء محجوز قبل تأكيدك.';
	@override String get confirmerTitre => 'تأكيد الفصل';
	@override String confirmerPhrase({required Object prenom}) => 'أنت تسجّل ⁨${prenom}⁩ في هذا الفصل.';
	@override String confirmerAttentePhrase({required Object prenom}) => 'أنت تسجّل ⁨${prenom}⁩ في قائمة انتظار هذا الفصل.';
	@override String memeEnseignant({required Object enseignant}) => 'الفصل نفسه والمعلم نفسه في كل حصص الأسبوع: ⁨${enseignant}⁩.';
	@override String get confirmer => 'تأكيد التسجيل';
	@override String get confirmerAttente => 'تأكيد قائمة الانتظار';
	@override String get envoiIncertain => 'لم يصل رد الأكاديمية. إعادة المحاولة لا تنشئ تسجيلًا ثانيًا.';
	@override String get envoiIndisponible => 'التسجيل عبر الإنترنت غير مفتوح بعد: لم يُحجز أي مقعد.';
	@override late final _Traductions$classe$pageCatalogue$resultat$ar resultat = _Traductions$classe$pageCatalogue$resultat$ar._(_root);
}

// Path: salle.secours
class _Traductions$salle$secours$ar extends Traductions$salle$secours$fr {
	_Traductions$salle$secours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get reseauFaible => 'الشبكة ضعيفة. الأولوية للصوت.';
	@override String get reseauFaibleGuidee => 'الشبكة ضعيفة.';
	@override String get reseauFaibleGuideeSuite => 'الصوت يبقى أولوية.';
	@override String get reconnexion => 'انقطع الاتصال. جارٍ إعادة الاتصال…';
	@override String get reconnexionGuidee => 'جارٍ إعادة الاتصال بالحصة…';
	@override String get retablie => 'عاد الاتصال.';
	@override String get echec => 'تعذّرت إعادة الاتصال.';
	@override String get echecGuidee => 'الاتصال لا يعود.';
	@override String get horsLigne => 'أنت غير متصل. تحتاج الحصة إلى اتصال.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get quitter => 'مغادرة';
	@override String indisponible({required Object commande}) => '${commande}. غير متاح أثناء إعادة الاتصال.';
	@override String get cameraInterdite => 'الكاميرا معطّلة لهذا الملف.';
	@override String get microBloque => 'الميكروفون محظور في إعدادات هذا الجهاز.';
	@override String get microBloqueGuidee => 'الميكروفون محظور على هذا الجهاز.';
	@override String get continuerSansMicro => 'المتابعة دون ميكروفون';
	@override String get ouvrirReglages => 'فتح الإعدادات';
}

// Path: salle.preparation
class _Traductions$salle$preparation$ar extends Traductions$salle$preparation$fr {
	_Traductions$salle$preparation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الاستعداد لدخول الفصل';
	@override String get retour => 'العودة إلى الفصل';
	@override String get cameraCoupee => 'الكاميرا مطفأة';
	@override String get testerCamera => 'اختبار الكاميرا';
	@override String get testCameraFait => 'انتهى الاختبار المحلي. تبقى الكاميرا مطفأة عند الدخول.';
	@override String get equipement => 'أجهزتك';
	@override String get connexion => 'الاتصال';
	@override String get micro => 'الميكروفون';
	@override String get sortieAudio => 'مخرج الصوت';
	@override String get camera => 'الكاميرا';
	@override String get verification => 'جارٍ التحقق…';
	@override String get chargement => 'جارٍ التحقق من الأجهزة…';
	@override String get connexionPrete => 'الاتصال جاهز';
	@override String get connexionInstable => 'الاتصال غير مستقر';
	@override String get reseauFaible => 'الاتصال غير مستقر. الأولوية للصوت.';
	@override String get microPret => 'تم العثور على ميكروفون · الميكروفون مغلق عند الدخول';
	@override String get microAbsent => 'لم يُعثر على ميكروفون';
	@override String get microAbsentRaison => 'لم يُعثر على ميكروفون. وصّل ميكروفونًا أو فعّله لتتمكن من التدريس.';
	@override String get microBloque => 'الميكروفون محظور';
	@override String get permissionRefusee => 'الميكروفون محظور في إعدادات هذا الجهاز.';
	@override String get ouvrirReglages => 'فتح الإعدادات';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get sortieSysteme => 'مخرج النظام';
	@override String get cameraPrete => 'تم العثور على كاميرا · الكاميرا مطفأة عند الدخول';
	@override String get cameraAbsente => 'الكاميرا غير متاحة. يمكنك الدخول دون كاميرا.';
	@override String get modifierPeripheriques => 'تغيير الأجهزة';
	@override String get contexte => 'سياق الحصة';
	@override String get classe => 'الفصل';
	@override String get debut => 'البداية';
	@override String get support => 'المادة المقررة';
	@override String get reprise => 'الاستئناف';
	@override String get eleves => 'الطلاب المنتظرون';
	@override String get entrer => 'دخول الفصل';
	@override String get terminee => 'انتهت هذه الحصة.';
	@override String get nonAssignee => 'هذه الحصة غير مسندة إليك.';
	@override String get retourJournee => 'العودة إلى يومي';
	@override late final _Traductions$salle$preparation$demo$ar demo = _Traductions$salle$preparation$demo$ar._(_root);
	@override late final _Traductions$salle$preparation$eleve$ar eleve = _Traductions$salle$preparation$eleve$ar._(_root);
}

// Path: salle.seance
class _Traductions$salle$seance$ar extends Traductions$salle$seance$fr {
	_Traductions$salle$seance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'حصة مباشرة';
	@override String get titreGuidee => 'حصتي';
	@override String ligne({required Object debut, required Object fin}) => '⁨${debut}⁩ · ⁨${fin}⁩';
	@override String minutesRestantes({required Object minutes}) => 'الوقت المتبقي: ⁨${minutes}⁩ د';
	@override String get sePoursuit => 'الحصة مستمرة.';
	@override String get enLigne => 'متصل';
	@override String get reconnexion => 'إعادة الاتصال';
	@override String get coursEnregistreCourt => 'الدرس مسجَّل.';
	@override String get votreParentObserve => 'وليّ أمرك يتابع الحصة.';
	@override String get tonParentObserve => 'وليّ أمرك يتابع الحصة.';
	@override String tuteurDeObserve({required Object prenom}) => 'وليّ أمر ⁨${prenom}⁩ يتابع.';
	@override String get unParentObserve => 'وليّ أمر يتابع هذه الحصة';
	@override String leTuteurDeObserve({required Object prenom}) => 'وليّ أمر ⁨${prenom}⁩ يتابع الحصة.';
	@override String mentionEtNotice({required Object mention, required Object notice}) => '⁨${mention}⁩ ⁨${notice}⁩';
	@override String get retour => 'رجوع';
	@override String get notifications => 'الإشعارات';
	@override String get reglages => 'الإعدادات';
	@override String compteDe({required Object nom}) => 'حساب ⁨${nom}⁩';
	@override String get sortir => 'مغادرة الحصة';
	@override String get commandesAppel => 'عناصر التحكم في المكالمة';
	@override String compteurEleves({required Object connectes, required Object inscrits}) => 'الطلاب ⁦⁨${connectes}⁩/⁨${inscrits}⁩⁩';
	@override String get parler => 'تحدّث';
	@override String get agrandir => 'تكبير';
	@override String get reduire => 'تصغير';
	@override String rienPartage({required Object nom}) => 'لم تصل أي مشاركة من ⁨${nom}⁩ بعد.';
	@override String videoDe({required Object nom}) => 'فيديو ⁨${nom}⁩';
	@override String page({required Object page, required Object pages}) => '⁨${page}⁩ / ⁨${pages}⁩';
	@override String pageSemantique({required Object page, required Object pages}) => 'الصفحة ⁨${page}⁩ من ⁨${pages}⁩';
	@override String get zoomLocal => 'تكبير محلي، لا يؤثر في الآخرين';
	@override String zoomValeur({required Object valeur}) => '⁨${valeur}⁩ ٪';
	@override String get zoomMoins => 'تقليل التكبير';
	@override String get zoomPlus => 'زيادة التكبير';
	@override String get quitterQuestion => 'مغادرة الحصة؟';
	@override String get quitterConsequence => 'يمكنك العودة ما دامت الحصة مفتوحة.';
	@override String get illustration => 'رسم توضيحي للمادة';
	@override String get quitterCahierConsequence => 'ستنتقل بعد ذلك إلى دفتر المتابعة.';
	@override String get quitterCahier => 'المغادرة وفتح دفتر المتابعة';
	@override String get rester => 'البقاء';
	@override String get supports => 'المواد';
	@override String get reseau => 'الشبكة';
	@override String get pagePrecedente => 'الصفحة السابقة';
	@override String get pageSuivante => 'الصفحة التالية';
	@override late final _Traductions$salle$seance$outils$ar outils = _Traductions$salle$seance$outils$ar._(_root);
	@override late final _Traductions$salle$seance$rail$ar rail = _Traductions$salle$seance$rail$ar._(_root);
	@override String get fermerPanneau => 'إغلاق اللوحة';
	@override late final _Traductions$salle$seance$panneauSupports$ar panneauSupports = _Traductions$salle$seance$panneauSupports$ar._(_root);
	@override String get eleves => 'الطلاب';
	@override String get rappeler => 'نداء خاص';
	@override String get faireReciter => 'طلب التلاوة';
	@override String get fileRecitation => 'ترتيب التلاوة';
	@override String get aSuivre => 'التالي';
	@override String vousAppelle({required Object nom}) => 'نداء من ⁨${nom}⁩';
	@override String get signalerBesoin => 'الإبلاغ عن حاجة';
	@override String deplierFiche({required Object prenom}) => 'عرض بطاقة ⁨${prenom}⁩';
	@override String replierFiche({required Object prenom}) => 'إخفاء بطاقة ⁨${prenom}⁩';
	@override late final _Traductions$salle$seance$fiche$ar fiche = _Traductions$salle$seance$fiche$ar._(_root);
	@override String optionsPanneau({required Object titre}) => 'خيارات لوحة ⁨${titre}⁩';
	@override late final _Traductions$salle$seance$commandes$ar commandes = _Traductions$salle$seance$commandes$ar._(_root);
	@override late final _Traductions$salle$seance$bibliotheque$ar bibliotheque = _Traductions$salle$seance$bibliotheque$ar._(_root);
	@override late final _Traductions$salle$seance$surface$ar surface = _Traductions$salle$seance$surface$ar._(_root);
	@override late final _Traductions$salle$seance$capsule$ar capsule = _Traductions$salle$seance$capsule$ar._(_root);
	@override late final _Traductions$salle$seance$contexte$ar contexte = _Traductions$salle$seance$contexte$ar._(_root);
	@override late final _Traductions$salle$seance$demo$ar demo = _Traductions$salle$seance$demo$ar._(_root);
	@override late final _Traductions$salle$seance$statut$ar statut = _Traductions$salle$seance$statut$ar._(_root);
}

// Path: salle.fin
class _Traductions$salle$fin$ar extends Traductions$salle$fin$fr {
	_Traductions$salle$fin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'انتهت الحصة';
	@override String get phrase => 'تجد عملك في فصلك.';
	@override String get retourClasse => 'العودة إلى الفصل';
	@override String get quitteTitre => 'غادرت الحصة.';
	@override String get quittePhrase => 'يمكنك العودة ما دامت مفتوحة.';
	@override String get accesRetireTitre => 'انتهى دخولك إلى هذه الحصة.';
	@override String get titreGuidee => 'انتهت الحصة.';
	@override String get retourAccueil => 'العودة إلى الصفحة الرئيسية';
	@override late final _Traductions$salle$fin$enseignant$ar enseignant = _Traductions$salle$fin$enseignant$ar._(_root);
}

// Path: salle.visiteControle
class _Traductions$salle$visiteControle$ar extends Traductions$salle$visiteControle$fr {
	_Traductions$salle$visiteControle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مراقبة Rewayah';
	@override String get sonRecu => 'الصوت الوارد مفتوح';
	@override String get sonCoupe => 'الصوت الوارد مكتوم';
	@override String get couperSon => 'كتم الصوت الوارد';
	@override String get retablirSon => 'إعادة الصوت الوارد';
	@override String get agrandir => 'تكبير المادة';
	@override String get reduire => 'تصغير المادة';
}

// Path: eleve.suivi
class _Traductions$eleve$suivi$ar extends Traductions$eleve$suivi$fr {
	_Traductions$eleve$suivi$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'متابعة دروسي';
	@override String get colonneDate => 'التاريخ';
	@override String get colonneCours => 'الدرس';
	@override String get colonneEnseignant => 'المعلم';
	@override String get colonneEtat => 'الحضور';
	@override String get cours => 'درس القرآن';
	@override String get moi => 'حضوري';
	@override String aujourdhui({required Object heure}) => 'اليوم، ⁨${heure}⁩';
	@override String hier({required Object heure}) => 'أمس، ⁨${heure}⁩';
	@override String date({required Object date, required Object heure}) => '⁨${date}⁩، ⁨${heure}⁩';
	@override String get annule => 'درس ملغى';
	@override String get nonTenu => 'درس لم يُعقد';
	@override String get vide => 'لا توجد دروس حتى الآن';
	@override String get videDetail => 'ستظهر دروسك هنا من الأحدث إلى الأقدم مع حالة حضورك.';
	@override String get erreur => 'تعذرت قراءة المتابعة. حاول مرة أخرى بعد قليل.';
	@override String tronquee({required Object nombre}) => 'تظهر أحدث الدروس، وعددها ⁨${nombre}⁩.';
	@override String fin({required Object nombre}) => 'عدد الدروس في المتابعة: ⁨${nombre}⁩.';
	@override String get finUn => 'درس واحد في المتابعة.';
}

// Path: eleve.accueil
class _Traductions$eleve$accueil$ar extends Traductions$eleve$accueil$fr {
	_Traductions$eleve$accueil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get rejoindre => 'انضمام';
	@override String get coran => 'القرآن';
	@override String get coranDetail => 'اقرأه متى شئت';
	@override String get coranEcouter => 'استمع: القرآن';
	@override String get prochainCours => 'الدرس القادم';
	@override String get coursEnDirect => 'بدأ درسك';
	@override String avec({required Object prenom}) => 'مع ⁨${prenom}⁩';
	@override String dansMinutes({required Object minutes}) => 'بعد ⁨${minutes}⁩ دقيقة';
	@override String dansHeures({required Object heures, required Object minutes}) => 'بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د';
	@override String get imminent => 'حان الوقت تقريبًا';
	@override String get aucunCours => 'لا دروس اليوم';
	@override String get aucunCoursDetail => 'معلمك يحضّر الدرس القادم.';
	@override String get erreurCours => 'تعذّرت قراءة دروسك. أعد المحاولة بعد لحظة.';
	@override String get prochainAujourdhui => 'درسك القادم لاحقًا اليوم.';
	@override String get prochainDemain => 'درسك القادم غدًا.';
	@override String prochainDansJours({required Object jours}) => 'درسك القادم بعد ⁨${jours}⁩ أيام.';
	@override String get annulee => 'لن يُعقد هذا الدرس';
	@override String get horsLigne => 'لا شبكة';
	@override String get horsLigneDetail => 'يمكنك الدخول بمجرد عودة الشبكة.';
	@override String get pausePriere => 'استراحة للصلاة';
	@override String pausePriereDetail({required Object priere, required Object heure}) => '⁨${priere}⁩، نحو ⁨${heure}⁩';
}

// Path: eleve.coran
class _Traductions$eleve$coran$ar extends Traductions$eleve$coran$fr {
	_Traductions$eleve$coran$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'القرآن';
	@override String page({required Object page, required Object total}) => 'الصفحة ⁨${page}⁩ من ⁨${total}⁩';
	@override String juz({required Object juz}) => 'الجزء ⁨${juz}⁩';
	@override String get mecquoise => 'مكية';
	@override String get medinoise => 'مدنية';
	@override String get reprendre => 'متابعة القراءة';
	@override String reprendreDetail({required Object page}) => 'كنت في الصفحة ⁨${page}⁩';
	@override String get chargement => 'النص في الطريق';
	@override String get indisponible => 'تعذّر تحميل النص';
	@override String get indisponibleDetail => 'بمجرد عودة الشبكة، تُفتح صفحتك هنا من جديد.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get absent => 'هذه الصفحة فارغة';
	@override String get absentDetail => 'لم يُثبَّت النص في هذه الصفحة. أبلغ عن ذلك: الخطأ ليس منك.';
	@override String get pagePrecedente => 'الصفحة السابقة';
	@override String get pageSuivante => 'الصفحة التالية';
	@override String get reglages => 'إعدادات القراءة';
	@override String get fermerReglages => 'إغلاق الإعدادات';
	@override String get taille => 'حجم النص';
	@override String get agrandir => 'تكبير النص';
	@override String get reduire => 'تصغير النص';
	@override String get source => 'نص القرآن: Tanzil Project';
	@override String get sourceLien => 'tanzil.net';
	@override String get edition => 'مصحف المدينة، رواية حفص';
}

// Path: enseignant.journee
class _Traductions$enseignant$journee$ar extends Traductions$enseignant$journee$fr {
	_Traductions$enseignant$journee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get derniereSeance => 'آخر حصة';
	@override String get rejoindreSalle => 'الدخول إلى القاعة';
	@override String rejoindreSalleLecteur({required Object classe}) => 'الدخول إلى قاعة الفصل ⁨${classe}⁩';
	@override String get remplirCahier => 'تعبئة دفتر المتابعة';
	@override String remplirCahierLecteur({required Object classe}) => 'تعبئة دفتر المتابعة للفصل ⁨${classe}⁩';
	@override String cahierObligatoire({required Object classe}) => 'إلزامي: يُعبَّأ دفتر المتابعة للفصل ⁨${classe}⁩ في نهاية كل حصة.';
	@override String voirCahier({required Object classe}) => 'عرض دفتر المتابعة للفصل ⁨${classe}⁩';
	@override String voirCahierLecteur({required Object classe}) => 'عرض دفتر المتابعة للفصل ⁨${classe}⁩';
	@override String get lancer => 'بدء الدرس';
	@override String get preflight => 'التحقق قبل الدرس';
	@override String get titre => 'اليوم';
	@override String get prochainCours => 'الدرس القادم';
	@override String get coursEnCours => 'حصة مباشرة';
	@override String minuteurHeures({required Object heures, required Object minutes}) => 'بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د';
	@override String minuteurMinutes({required Object minutes}) => 'بعد ⁨${minutes}⁩ دقيقة';
	@override String get minuteurImminent => 'يبدأ الآن';
	@override String jusqua({required Object heure}) => 'حتى ⁨${heure}⁩';
	@override String unAutreJour({required Object jour, required Object heure}) => '⁨${jour}⁩، الساعة ⁨${heure}⁩';
	@override String get lancementPlusTard => 'يُتاح البدء قبل موعد الدرس بعشر دقائق.';
	@override String get aucunCours => 'لا دروس قادمة';
	@override String get aucunCoursDetail => 'اقبل طالبًا في الانتظار: هذا ما يملأ يومك.';
	@override String get colonne => 'اليوم';
	@override String ligneCours({required Object prenom}) => 'درس مع ⁨${prenom}⁩';
	@override String get lignePause => 'استراحة';
	@override String plage({required Object debut, required Object fin}) => '⁨${debut}⁩ إلى ⁨${fin}⁩';
	@override String duree({required Object minutes}) => '⁨${minutes}⁩ دقيقة';
	@override String get rienAujourdhui => 'لا شيء مقرر اليوم';
	@override String rienAujourdhuiDetail({required Object jour, required Object heure}) => 'درسك القادم ⁨${jour}⁩ الساعة ⁨${heure}⁩.';
	@override String journeeTerminee({required Object nombre}) => 'عدد الدروس المقدَّمة اليوم: ⁨${nombre}⁩.';
	@override String get journeeTermineeUn => 'درس واحد قُدِّم اليوم.';
	@override String get voirCreneaux => 'عرض مواعيدي';
	@override String get erreur => 'تعذّرت قراءة اليوم كاملًا. أعد المحاولة بعد لحظة.';
	@override String get coursIndividuel => 'درس فردي';
	@override String effectif({required Object nombre}) => '⁨${nombre}⁩ طلاب';
	@override String get effectifUn => 'طالب واحد';
	@override String get preflightOk => 'الميكروفون جاهز';
	@override String get preflightBloque => 'متصفحك يحظر الميكروفون. اسمح به لبدء الدرس.';
	@override String get preflightSansMicro => 'لم يُعثر على ميكروفون. وصّل واحدًا لبدء الدرس.';
	@override String get preflightIndisponible => 'لم يكتمل التحقق من الأجهزة. أعد المحاولة قبل بدء الدرس.';
	@override String get lancerHorsLigne => 'دون شبكة، لا يمكن فتح القاعة. أعد الاتصال لبدء الدرس.';
	@override String get erreurPartielle => 'تعذّر تحميل أوقات الصلاة واستراحاتك (اتصال غير مستقر أو خدمة غير متاحة مؤقتًا). الحصص المعروضة محدَّثة: يمكنك بدؤها بشكل عادي.';
	@override String absenceDetectee({required Object eleve}) => 'لم يدخل ⁨${eleve}⁩ القاعة.';
	@override String coupureDetectee({required Object eleve}) => 'انقطع اتصال ⁨${eleve}⁩.';
	@override String coursAnnule({required Object heure}) => 'أُلغي درس الساعة ⁨${heure}⁩.';
	@override String get rapportsTitre => 'تقارير بانتظار الإيداع';
	@override String rapportLigne({required Object jour, required Object heure}) => 'درس ⁨${jour}⁩ الساعة ⁨${heure}⁩';
	@override String rapportAttente({required Object heures}) => 'للإيداع منذ ⁨${heures}⁩ س';
	@override String rapportRetard({required Object heures}) => 'متأخر ⁨${heures}⁩ س';
	@override String get enAttenteTitre => 'طلاب في الانتظار';
	@override String get enAttenteLibelle => 'طلاب في الانتظار في ساعاتك';
	@override String get enAttenteLibelleUn => 'طالب في الانتظار في ساعاتك';
	@override String get prochaineSeance => 'الحصة القادمة';
	@override String get maJournee => 'يومي';
	@override String get aTerminer => 'للإنهاء';
	@override String get aTerminerVide => 'كل دفاترك منتهية.';
	@override String get aTerminerErreur => 'تعذّرت قراءة الدفاتر المطلوب إنهاؤها. أعد المحاولة بعد لحظة.';
	@override String get aTerminerAide => 'دفتر المتابعة يساعد طلابك ويتيح لك تعديل الدرس القادم.';
	@override String get rappelCahier => 'دفاتر متابعة تنتظر الإنهاء';
	@override String cahierLigne({required Object classe}) => 'دفتر متابعة ⁨${classe}⁩';
	@override String cahierDetail({required Object jour, required Object numero, required Object mois, required Object heure}) => 'حصة ⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩ الساعة ⁨${heure}⁩';
	@override String get alertesUtiles => 'تنبيهات مفيدة';
	@override String get alertesVide => 'لا تنبيهات مفيدة الآن.';
	@override String get alertesErreur => 'تعذّرت قراءة تنبيهات الحضور: لم يستجب الاتصال أو الخادم. أعد المحاولة بعد لحظة.';
	@override String get voirAutreAlerte => 'عرض التنبيه الآخر';
	@override String voirAutresAlertes({required Object nombre}) => 'عرض التنبيهات الأخرى (⁨${nombre}⁩)';
	@override String get remplacementsTitre => 'الاستخلافات المؤكَّدة';
	@override String get remplacementsVide => 'لا درس لزميل تتولاه الآن.';
	@override String voirTousRemplacements({required Object nombre}) => 'عرض الكل: الاستخلافات المؤكَّدة (⁨${nombre}⁩)';
	@override String get heure => 'الساعة';
	@override String get eleves => 'الطلاب';
	@override String get classe => 'الفصل';
	@override String classeNommee({required Object classe}) => 'الفصل ⁨${classe}⁩';
	@override String get preparerSeance => 'تحضير الحصة';
	@override String preparerSeanceLecteur({required Object classe}) => 'تحضير حصة ⁨${classe}⁩';
	@override String get voirClasse => 'عرض الفصل';
	@override String voirClasseLecteur({required Object classe}) => 'عرض الفصل ⁨${classe}⁩';
	@override String get aucuneSeance => 'لا حصص قادمة';
	@override String get aucuneSeanceDetail => 'ستظهر هنا حصصك القادمة.';
	@override String date({required Object jour, required Object numero, required Object mois}) => '⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩';
	@override late final _Traductions$enseignant$journee$absence$ar absence = _Traductions$enseignant$journee$absence$ar._(_root);
	@override late final _Traductions$enseignant$journee$remplacement$ar remplacement = _Traductions$enseignant$journee$remplacement$ar._(_root);
}

// Path: enseignant.ficheGroupe
class _Traductions$enseignant$ficheGroupe$ar extends Traductions$enseignant$ficheGroupe$fr {
	_Traductions$enseignant$ficheGroupe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get elevesTitre => 'الطلاب';
	@override String get preparationTitre => 'للتحضير';
	@override String get supportPrevu => 'المادة المقررة';
	@override String get positionReprise => 'موضع الاستئناف';
	@override String get objectif => 'الهدف';
	@override String get preparationVide => 'لم يُسجَّل أي تحضير لهذه الحصة.';
	@override String get supportsTitre => 'أحدث المواد';
	@override String repriseEleve({required Object page}) => 'نقطة الاستئناف: ⁨${page}⁩';
	@override String dernierPoint({required Object texte}) => 'آخر ملاحظة: ⁨${texte}⁩';
	@override String get chargementClasse => 'جارٍ تحميل الفصل.';
	@override String creneauHebdo({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩، كل أسبوع';
	@override String get aucunMembre => 'لا طالب في هذا الفصل';
	@override String get aucunMembreDetail => 'الإدارة تكوّن الفصول: هذا الفصل ليس فيه طالب بعد.';
	@override String get erreur => 'تعذّرت قراءة هذا الفصل. أعد المحاولة بعد لحظة.';
	@override String get introuvable => 'هذا الفصل ليس من فصولك';
	@override String get introuvableDetail => 'ربما أُغلق، أو هو لمعلم آخر.';
	@override String get revue => 'فتح مراجعة الفصل';
	@override String get ressourcesTitre => 'الموارد الأخيرة';
	@override String get progressionTitre => 'تقدم الفصل';
}

// Path: enseignant.classes
class _Traductions$enseignant$classes$ar extends Traductions$enseignant$classes$fr {
	_Traductions$enseignant$classes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الفصول';
	@override String get vide => 'لا فصل مسند إليك';
	@override String get videDetail => 'ستظهر هنا الفصول المؤكَّدة.';
	@override String get erreur => 'تعذّرت قراءة فصولك. أعد المحاولة بعد لحظة.';
	@override String get chargement => 'جارٍ تحميل فصولك.';
	@override String niveau({required Object niveau}) => 'المستوى ⁨${niveau}⁩';
	@override String get eleveUn => 'طالب واحد';
	@override String eleves({required Object nombre}) => '⁨${nombre}⁩ طلاب';
	@override String prochaine({required Object jour, required Object heure}) => 'الحصة القادمة: ⁨${jour}⁩ الساعة ⁨${heure}⁩';
	@override String get sansProchaine => 'لا حصة مقررة';
	@override String get remplacement => 'استخلاف';
	@override String get rappelCahier => 'دفتر متابعة ينتظر التأكيد';
	@override String get cahierAValider => 'دفتر المتابعة بانتظار التأكيد';
}

// Path: enseignant.eleve
class _Traductions$enseignant$eleve$ar extends Traductions$enseignant$eleve$fr {
	_Traductions$enseignant$eleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String titre({required Object prenom}) => 'بطاقة ⁨${prenom}⁩';
	@override String get retour => 'الطلاب';
	@override String identifiant({required Object id}) => 'معرّف الأكاديمية: ⁨${id}⁩';
	@override String photo({required Object prenom}) => 'صورة ⁨${prenom}⁩';
	@override String get niveau => 'المستوى';
	@override String get objectif => 'الهدف';
	@override String get presence => 'الحضور الأخير';
	@override String get travail => 'العمل';
	@override String travailReprise({required Object page}) => 'الاستئناف من ⁨${page}⁩';
	@override String get derniereSeance => 'آخر حصة';
	@override String get nonRenseigne => 'غير محدد';
	@override String get signaler => 'الإشارة إلى حاجة';
	@override String get signalerAide => 'حاجة تُرفع إلى الأكاديمية، دون إعادة كتابة السياق.';
}

// Path: enseignant.signalement
class _Traductions$enseignant$signalement$ar extends Traductions$enseignant$signalement$fr {
	_Traductions$enseignant$signalement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإشارة إلى حاجة';
	@override String contexte({required Object prenom, required Object classe}) => 'لـ⁨${prenom}⁩ · ⁨${classe}⁩';
	@override String get categorieTitre => 'الفئة';
	@override late final _Traductions$enseignant$signalement$categories$ar categories = _Traductions$enseignant$signalement$categories$ar._(_root);
	@override String get details => 'تفاصيل داخلية';
	@override String get detailsAide => 'يقرؤها فريق الأكاديمية فقط.';
	@override String get resume => 'ملخص قابل للمشاركة';
	@override String get resumeAide => 'يمكن للأكاديمية مشاركته مع الأسرة.';
	@override String get notice => 'لا تُرسل التفاصيل الداخلية تلقائيًا إلى الأسرة.';
	@override String get choisirCategorie => 'اختر فئة للمتابعة.';
	@override String get detailsRequis => 'في «أخرى»، قل في كلمات قليلة بماذا يتعلق الأمر.';
	@override String get envoyer => 'إرسال الإشارة';
	@override String get demoSucces => 'عرض تجريبي: هذه الإشارة جاهزة، لكن لم يُرسل شيء.';
	@override String get demoSuccesDetail => 'في التطبيق الموصول، ستُرسل إلى فريق الأكاديمية.';
	@override String get fermer => 'إغلاق';
}

// Path: enseignant.demo
class _Traductions$enseignant$demo$ar extends Traductions$enseignant$demo$fr {
	_Traductions$enseignant$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'عرض تجريبي للمعلم';
	@override String get mention => 'بيانات وهمية، لا إرسال.';
	@override String get intro => 'اختر شاشة من شاشات السيد إبراهيم.';
	@override String get ecrans => 'الشاشات';
	@override String get etats => 'الحالات';
	@override String get etatNominal => 'يوم عادي';
	@override String get etatVide => 'لا حصة';
	@override String get etatHorsLigne => 'غير متصل';
}

// Path: enseignant.bienvenue
class _Traductions$enseignant$bienvenue$ar extends Traductions$enseignant$bienvenue$fr {
	_Traductions$enseignant$bienvenue$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الخطوات الأولى';
	@override String salutation({required Object prenom}) => 'مرحبًا، ⁨${prenom}⁩.';
	@override String get salutationSansNom => 'مرحبًا.';
	@override String get dossierValide => 'تم اعتماد ملفك.';
	@override String get sousTitre => 'جهّز مساحتك قبل فصلك الأول.';
	@override String get aCompleter => 'للإكمال';
	@override String compteur({required Object fait, required Object total}) => '⁨${fait}⁩ من ⁨${total}⁩';
	@override String get prerequisPhoto => 'إضافة صورتي المهنية';
	@override String get prerequisLangues => 'التحقق من لغات تدريسي';
	@override String get prerequisFuseau => 'التحقق من منطقتي الزمنية';
	@override String get ctaPhoto => 'إضافة صورتي';
	@override String get ctaInformations => 'التحقق من معلوماتي';
	@override String get ctaJournee => 'عرض يومي';
	@override String get rappels => 'أمران لا ينبغي اكتشافهما في منتصف الطريق';
	@override String get declarer => 'التصريح بأوقات توفري';
	@override String get versJournee => 'الذهاب إلى يومي';
	@override String get horsLigne => 'دون شبكة، لا يمكن حفظ مواعيدك.';
	@override String get dossierIncomplet => 'لم يُعتمد ملفك بعد.';
	@override String get dossierIncompletDetail => 'بوابة الانتظار تخبرك بما بقي عليك تقديمه.';
	@override String get versAttente => 'عرض ملفي';
	@override String get erreur => 'تعذّرت قراءة ملفك الشخصي. أعد المحاولة بعد لحظة.';
}

// Path: enseignant.photo
class _Traductions$enseignant$photo$ar extends Traductions$enseignant$photo$fr {
	_Traductions$enseignant$photo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الصورة المهنية';
	@override String get aide => 'صورتك إلزامية: الأسر لا تأتمن أطفالها لشخص مجهول على الإنترنت. تراها أسر طلابك.';
	@override String get obligatoireLecteur => 'الصورة إلزامية';
	@override String get voile => 'إن كنتِ ترتدين النقاب، يمكن أن تظهركِ صورة الملف منتقبة.';
	@override String get notice => 'لا تستخدم بطاقة هويتك.';
	@override String get choisir => 'اختيار صورة';
	@override String get utiliser => 'استخدام هذه الصورة';
	@override String get remplacer => 'استبدال الصورة';
	@override String get autre => 'اختيار صورة أخرى';
	@override String get changer => 'تغيير الصورة';
	@override String get alternatif => 'صورتك العامة';
	@override String get succes => 'حُفظت الصورة.';
	@override String get echec => 'تعذّر إرسال الصورة. لم يتغير شيء في الملف.';
	@override String get selectionEchec => 'تعذّر فتح الصورة. تحقّق من إذن الوصول إلى صور الجهاز، ثم أعد المحاولة.';
	@override String get horsLigne => 'أنت غير متصل. يمكن إرسال الصورة عند عودة الاتصال.';
}

// Path: enseignant.salle
class _Traductions$enseignant$salle$ar extends Traductions$enseignant$salle$fr {
	_Traductions$enseignant$salle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String reference({required Object page, required Object total, required Object reference}) => 'المعروض: الصفحة ⁨${page}⁩ من ⁨${total}⁩ · ⁨${reference}⁩';
	@override String get rien => 'لا شيء معروض';
	@override String get rienInvitation => 'افتح القرآن لتعرض صفحة على فصلك.';
	@override String get attenteSalle => 'لست في القاعة بعد';
	@override String get attenteSalleDetail => 'تُفتح أوامر العرض بمجرد اتصال الدرس.';
	@override String get lienFaibleDetail => 'قد يصل تقليب الصفحة متأخرًا إلى فصلك';
	@override String get presentationConservee => 'الصفحة المعروضة محفوظة، وستُرسل عند عودة الاتصال';
	@override String get presentationSuspendue => 'العرض موقوف';
	@override String get precedente => 'عرض الصفحة السابقة';
	@override String get suivante => 'عرض الصفحة التالية';
	@override String get bibliotheque => 'اختيار سورة';
	@override String presenterSourate({required Object sourate}) => 'عرض بداية ⁨${sourate}⁩';
	@override String sourateDetail({required Object numero, required Object versets}) => 'السورة ⁨${numero}⁩ · عدد آياتها ⁨${versets}⁩';
	@override String get souratesIndisponibles => 'تعذّرت قراءة قائمة السور';
	@override String get souratesIndisponiblesDetail => 'لم يتغير ما يراه فصلك. أعد المحاولة.';
	@override String get pageIndisponible => 'تعذّرت قراءة هذه الصفحة';
	@override String get pageIndisponibleDetail => 'لم يصل النص إلى هنا. ما زال فصلك يرى الصفحة المعروضة.';
	@override String get corpusAbsent => 'نص القرآن غير مثبَّت';
	@override String get corpusAbsentDetail => 'لا شيء للعرض.';
	@override String get echecPresentation => 'تعذّر تحديد موضع هذه الآية في المصحف. لم يُرسل شيء إلى فصلك.';
	@override String get sansDroitPresentation => 'دخولك إلى هذه الحصة لا يسمح بعرض محتوى.';
}

// Path: enseignant.cahier
class _Traductions$enseignant$cahier$ar extends Traductions$enseignant$cahier$fr {
	_Traductions$enseignant$cahier$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'دفتر المتابعة';
	@override String get obligatoire => 'إلزامي';
	@override String get sousTitre => 'إلزامي بعد كل حصة';
	@override String get description => 'دوّن أين وصل كل طالب (السورة، الآية، القاعدة التي عُمل عليها). إن استخلفك معلم آخر، يستأنف تمامًا من حيث توقفت الحصة.';
	@override String duree({required Object minutes}) => '⁨${minutes}⁩ دقيقة من الدرس';
	@override String dureeEtInterruption({required Object minutes, required Object interruption}) => '⁨${minutes}⁩ دقيقة من الدرس، منها ⁨${interruption}⁩ دقيقة انقطاع';
	@override String get unEleve => 'طالب واحد';
	@override String eleves({required Object nombre}) => '⁨${nombre}⁩ طلاب';
	@override String get toutEstNominal => 'جرى كل شيء كما هو متوقع.';
	@override String get toutEstNominalDetail => 'أكّد، ويستمر يومك.';
	@override String get exceptions => 'للنظر';
	@override String get uneException => 'طالب واحد يحتاج إلى نظرة.';
	@override String plusieursExceptions({required Object nombre}) => '⁨${nombre}⁩ طلاب يحتاجون إلى نظرة.';
	@override String get nominaux => 'لا شيء يُذكر';
	@override String get curriculumFige => 'المستوى والمنهج من الأكاديمية: لا يُعدَّلان من دفتر المتابعة.';
	@override String get valider => 'تأكيد دفتر المتابعة';
	@override String get validerTout => 'كل شيء مطابق، تأكيد';
	@override String get validerSansConstat => 'الإيداع دون المعاينة';
	@override String get retourJournee => 'العودة إلى يومي';
	@override String get vide => 'تعذّر استنتاج المعاينة';
	@override String get videDetail => 'لم يُسجَّل حضور ولا حدث لهذه الحصة. يمكنك مع ذلك إيداع دفتر المتابعة.';
	@override String get erreur => 'تعذّرت قراءة المعاينة.';
	@override String get erreurDetail => 'أعد المحاولة، أو أودع دفتر المتابعة دون المعاينة.';
	@override String get echecEnvoi => 'لم يُؤكَّد الإرسال. تحقّق قبل إعادة المحاولة.';
	@override String get dejaDepose => 'دفتر متابعة هذه الحصة مودَع بالفعل.';
	@override String get dejaDeposeDetail => 'يُودَع دفتر المتابعة مرة واحدة، ولا يُحذف من هنا.';
	@override String get depose => 'حُفظ دفتر المتابعة';
	@override String get deposeDetail => 'استلمته الأكاديمية.';
	@override String get enFileTitre => 'بانتظار الإرسال';
	@override String get enFile => 'سيُرسل دفتر المتابعة عند عودة الاتصال.';
	@override String get enFileDetail => 'سيُرسل دفتر المتابعة عند عودة الاتصال.';
	@override String get enFileDetailHorsLigne => 'دون شبكة، يبقى دفتر المتابعة على هذا الجهاز ويُرسل بمجرد عودة الشبكة. يمكنك الانتقال إلى درسك التالي.';
	@override String ajusterPour({required Object eleve}) => 'تعديل · ⁨${eleve}⁩';
	@override String get ajusterValider => 'حفظ لهذا الطالب';
	@override String get exceptionConsignee => 'استثناء مُبلَغ عنه';
	@override String get pointPhonetique => 'ملاحظة في النطق';
	@override String get pointPhonetiqueDetail => 'زوج من الحروف، لا تقييم. اتركه فارغًا إن لم يكن هناك ما يُقال.';
	@override String get pointPhonetiqueNote => 'دُوِّنت ملاحظة النطق';
	@override String objectif({required Object eleve}) => 'هدف ⁨${eleve}⁩';
	@override String objectifDetail({required Object eleve}) => 'ما يجب أن يبلغه ⁨${eleve}⁩، في إطار منهج الأكاديمية.';
	@override String travailMaison({required Object eleve}) => 'واجب ⁨${eleve}⁩';
	@override String get travailMaisonDetail => 'عدّل الاقتراح، أو اتركه كما هو.';
	@override String get travailMaisonSaisi => 'دوّنت هذا الواجب بالفعل. عدّله أو اتركه كما هو.';
	@override String suite({required Object eleve}) => 'الخطوة التالية لـ⁨${eleve}⁩';
	@override String get suiteContinuer => 'المتابعة';
	@override String get suiteRenforcer => 'التثبيت';
	@override String get suspendreNouveau => 'إيقاف الجديد';
	@override String devoirPrecedent({required Object devoir}) => 'الواجب السابق: ⁨${devoir}⁩';
	@override String devoirPlage({required Object sourate, required Object debut, required Object fin}) => 'مراجعة سورة ⁨${sourate}⁩، الآيات ⁨${debut}⁩ إلى ⁨${fin}⁩.';
	@override String get suspendreNouveauDetail => 'تستمر المراجعة، ولا يُضاف شيء جديد لهذا الطالب.';
	@override String position({required Object sourate, required Object verset}) => 'القراءة: سورة ⁨${sourate}⁩، الآية ⁨${verset}⁩';
	@override String get makhrajSinSad => 'السين / الصاد (س / ص)';
	@override String get makhrajTaTah => 'التاء / الطاء (ت / ط)';
	@override String get makhrajDhalZay => 'الذال / الزاي (ذ / ز)';
	@override String get makhrajHaHah => 'الهاء / الحاء (ه / ح)';
	@override String get exceptionTitre => 'الإبلاغ عن استثناء';
	@override String get exceptionCorriger => 'تصحيح الحضور';
	@override String get exceptionExcuser => 'تبرير الغياب';
	@override String get exceptionConfirmation => 'تأكيد الاستثناء';
	@override String get exceptionMotif => 'السبب';
	@override String get exceptionMotifRequis => 'السبب إلزامي.';
	@override String get exceptionEnCours => 'جارٍ الحفظ…';
	@override String get exceptionSucces => 'دُوِّن الاستثناء. سيُرسل مع دفتر المتابعة.';
	@override String get exceptionErreur => 'تعذّر تدوين الاستثناء.';
	@override String get exceptionHorsLigne => 'دون شبكة، لا يمكن تأكيد استثناء. أما دفتر المتابعة فيُرسل على كل حال.';
	@override String get aValider => 'للتأكيد';
	@override String statutPresents({required Object nombre}) => 'الحاضرون ⁨${nombre}⁩';
	@override String statutAbsents({required Object nombre}) => 'الغائبون ⁨${nombre}⁩';
	@override String statutEnRetard({required Object nombre}) => 'المتأخرون ⁨${nombre}⁩';
	@override String get performance => 'الأداء';
	@override String get faiblesses => 'نقاط الضعف';
	@override String get niveauARevoir => 'للمراجعة';
	@override String get niveauEnProgres => 'في تقدم';
	@override String get niveauAcquis => 'مكتسَب';
	@override String get niveauMaitrise => 'متقَن';
	@override String get faiblesseMakharij => 'المخارج';
	@override String get faiblesseMadd => 'المد';
	@override String get faiblesseGhunna => 'الغنة';
	@override String get faiblesseWaqf => 'الوقف';
	@override String get faiblesseFluidite => 'الطلاقة';
	@override String get faiblesseMemorisation => 'الحفظ';
	@override String get niveauARevoirDetail => 'يُعاد المقطع في الحصة القادمة.';
	@override String get niveauEnProgresDetail => 'الطالب يتقدم، وبقيت بعض الأخطاء.';
	@override String get niveauAcquisDetail => 'المقطع محفوظ، بأخطاء قليلة.';
	@override String get niveauMaitriseDetail => 'المقطع محفوظ دون خطأ، ويمكن للطالب أن يتقدم.';
	@override String get faiblesseMakharijDetail => 'نطق الحروف.';
	@override String get faiblesseMaddDetail => 'المدود.';
	@override String get faiblesseGhunnaDetail => 'الصوت الأنفي.';
	@override String get faiblesseWaqfDetail => 'مواضع الوقف.';
	@override String get faiblesseFluiditeDetail => 'القراءة دون تردد.';
	@override String get faiblesseMemorisationDetail => 'التلاوة من الحفظ.';
	@override String get reprise => 'أين توقف الفصل';
	@override String get repriseDetail => 'هذا موضع الاستئناف للمعلم البديل.';
	@override String repriseProposee({required Object sourate, required Object verset}) => 'سورة ⁨${sourate}⁩، الآية ⁨${verset}⁩';
	@override String get repriseRequise => 'حدّد أين توقف الفصل: سيستأنف البديل من هنا.';
	@override String get integrite => 'ما تكتبه هنا أمانة. قد لا يتحقق منه الناس، لكن الله يرى كل شيء.';
	@override String get corriger => 'تصحيح دفتر المتابعة';
	@override String corrigeLe({required Object date}) => 'صُحِّح في ⁨${date}⁩';
}

// Path: enseignant.profil
class _Traductions$enseignant$profil$ar extends Traductions$enseignant$profil$fr {
	_Traductions$enseignant$profil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الملف الشخصي';
	@override String get compteValide => 'حساب معلم موثَّق';
	@override String get intro => 'ما تعرفه الأكاديمية عنك، وما يمكنك تغييره فيه.';
	@override String get identite => 'الهوية المهنية';
	@override String get pays => 'البلد';
	@override String get langues => 'اللغات';
	@override String get fuseau => 'المنطقة الزمنية لدروسي';
	@override String get fuseauDetail => 'هي التي تحدد توقيت مواعيدك، لا توقيت هذا الجهاز.';
	@override String get plafond => 'الحد الأسبوعي';
	@override String plafondValeur({required Object nombre}) => '⁨${nombre}⁩ ساعة في الأسبوع';
	@override String get plafondDetail => 'تحدده الأكاديمية.';
	@override String get nonRenseigne => 'غير محدد';
	@override String get statutSection => 'حالة الحساب';
	@override String get statutValideDetail => 'يمكنك التدريس والتصريح بساعاتك.';
	@override String get statutEnAttente => 'الملف قيد التحقق';
	@override String get statutEnAttenteDetail => 'تتحقق الأكاديمية من وثائقك. لا شيء آخر عليك فعله.';
	@override String get statutProvisoire => 'دخول مؤقت';
	@override String get statutProvisoireDetail => 'أنت تدرّس بالفعل. يبقى ملفك للإكمال، دون انقطاع تلقائي.';
	@override String get statutSuspendu => 'الحساب موقوف';
	@override String get statutSuspenduDetail => 'يمكنك التواصل مع الأكاديمية لمعرفة الخطوات المطلوبة.';
	@override String get statutInconnu => 'الحالة غير متاحة';
	@override String get statutInconnuDetail => 'تعذّرت قراءة حالتك.';
	@override String get statutDivergent => 'تغيّرت هذه الحالة للتو. أعد فتح التطبيق ليتبعها دخولك.';
	@override String get verification => 'التحقق من الملف';
	@override String get verificationEnAttente => 'قيد الانتظار';
	@override String get verificationValidee => 'معتمَد';
	@override String get verificationRefusee => 'يحتاج إلى مراجعة';
	@override String get contratSection => 'العقد والإقرارات';
	@override String get contratEnseignant => 'عقد المعلم';
	@override String get contratConditions => 'شروط الاستخدام';
	@override String get contratAccuse => 'التسجيل الصوتي وزيارة المراقبة';
	@override String contratDetail({required Object version, required Object date}) => 'الإصدار ⁨${version}⁩، مقبول في ⁨${date}⁩';
	@override String get contratAucun => 'لا عقد مسجَّل';
	@override String get contratAucunDetail => 'لم يمر ملفك بالتوقيع بعد.';
	@override String get contratErreur => 'تعذّرت قراءة عقودك.';
	@override String get contratLectureSeule => 'هذه الوثائق للقراءة فقط.';
	@override String get personnel => 'إعداداتي';
	@override String get deconnexionQuestion => 'تسجيل الخروج من هذا الجهاز؟';
	@override String get deconnexionConfirmer => 'تسجيل خروجي الآن';
	@override String get deconnexionConsequence => 'يبقى يومك ومواعيدك ودفاترك محفوظة. ستحتاج إلى رابط دخول جديد للعودة.';
	@override String get erreur => 'تعذّرت قراءة ملفك الشخصي. أعد المحاولة بعد لحظة.';
	@override String get vide => 'لا ملف معلم';
	@override String get videDetail => 'ليس لهذا الحساب ملف معلم. الأكاديمية وحدها يمكنها إنشاؤه.';
	@override String get horsLigne => 'لا شبكة: لا يمكن تعديل شيء هنا الآن.';
	@override String get modifierPays => 'تعديل البلد';
	@override String get modifierLangues => 'تعديل اللغات';
	@override String get languesIndice => 'افصل بين اللغات بفاصلة';
	@override String get enregistrer => 'حفظ';
	@override String get enregistre => 'حُفظ التعديل';
	@override String get editionErreur => 'لم يتم التعديل. أعد المحاولة بعد لحظة.';
}

// Path: enseignant.creneaux
class _Traductions$enseignant$creneaux$ar extends Traductions$enseignant$creneaux$fr {
	_Traductions$enseignant$creneaux$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String heureLibelle({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩';
	@override String get aucuneHeure => 'لم تقترح أي ساعة. دون موعد، لا يمكن أن يُقترح عليك أي فصل.';
	@override String heureEnregistree({required Object heure}) => 'حُفظت ⁨${heure}⁩';
	@override String heureRetiree({required Object heure}) => 'أُزيلت ⁨${heure}⁩';
	@override String retraitEngage({required Object heure}) => 'أُزيلت ⁨${heure}⁩. الحصة المسندة في هذه الساعة مستمرة: اطلب إعادة إسناد لإيقافها.';
	@override String get grilleErreur => 'تعذّرت قراءة ساعاتك';
	@override String get grilleErreurDetail => 'الساعات التي حددتها لم تضِع.';
	@override String get horsLigneGrille => 'دون شبكة، تبقى ساعاتك قابلة للعرض لكن لا يمكن تعديلها.';
	@override String heureEngagee({required Object heures}) => 'لديك فصل بالفعل في ⁨${heures}⁩. إزالة هذه الساعة لا تنهي الحصة: يلزم إعادة إسناد.';
	@override String heuresEngagees({required Object heures}) => 'لديك فصل بالفعل في ⁨${heures}⁩. إزالة هذه الساعات لا تنهي الحصص: يلزم إعادة إسناد.';
	@override String get feedErreur => 'تعذّرت قراءة الأسر المنتظرة';
	@override String get feedErreurDetail => 'لم يضِع شيء: لم يُؤخذ أحد، وساعاتك باقية.';
	@override String get horsLignePrise => 'دون شبكة، لا يمكنك قبول طالب. تبقى الطلبات أدناه قابلة للعرض.';
	@override String get horsLigneDemande => 'دون شبكة، لن يُرسل هذا الطلب. أعد المحاولة عند عودة الاتصال.';
	@override String get refusDejaPris => 'قبِل معلم آخر هذا الطالب للتو. القائمة أدناه محدَّثة.';
	@override String get refusDejaSuivi => 'لهذا الطالب معلم بالفعل. القائمة أدناه محدَّثة.';
	@override String get refusCreneauRetire => 'لم تعد هذه الأسرة تقترح هذا الموعد. القائمة أدناه محدَّثة.';
	@override String get refusHorsMesHeures => 'لم يعد هذا الموعد ضمن ساعاتك. أعد إضافته في «ساعاتي» لتتمكن من قبوله.';
	@override String get refusPlafond => 'بلغت الحد الأقصى لطلابك. اطلب زيادة لتتابع طالبًا آخر.';
	@override String get mesDisponibilites => 'أوقات توفري';
	@override String get ajouterCreneau => 'إضافة موعد';
	@override String heure({required Object heure}) => 'الساعة ⁨${heure}⁩';
	@override String get classesDisponibles => 'الفصول المتاحة';
	@override String get etatDisponible => 'متاح';
	@override String get etatEnAttente => 'بانتظار الاعتماد';
	@override String get etatLimite => 'بلغت الحد الأقصى للعبء';
	@override String get limiteDetail => 'عبؤك الحالي لا يسمح بحجز فصل إضافي.';
	@override String get aucuneClasse => 'لا فصل متوافق الآن';
	@override String get aucuneClasseDetail => 'عدّل أوقات توفرك إن تغيّر جدولك.';
	@override String get reserver => 'حجز هذا الفصل';
	@override String get demandeTransmise => 'أُرسل طلبك.';
	@override String get demandeTransmiseDetail => 'سيظهر في فصولك بعد التأكيد.';
	@override String get confirmerTitre => 'تأكيد هذا الفصل؟';
	@override String get confirmer => 'تأكيد هذا الفصل';
	@override String get revenir => 'رجوع';
	@override String get cleNiveau => 'المستوى';
	@override String get cleLangue => 'اللغة';
	@override String get cleRecurrence => 'التكرار';
	@override String get cleFuseau => 'المنطقة الزمنية المرجعية';
	@override String get cleHeureLocale => 'التوقيت المحلي';
	@override String get cleDuree => 'المدة';
	@override String duree({required Object minutes}) => '⁨${minutes}⁩ دقيقة';
}

// Path: enseignant.revue
class _Traductions$enseignant$revue$ar extends Traductions$enseignant$revue$fr {
	_Traductions$enseignant$revue$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مراجعة الفصل';
	@override String titreClasse({required Object classe}) => 'مراجعة الفصل ⁨${classe}⁩';
	@override String get aucuneAnomalie => 'لا شيء يتطلب انتباهك.';
	@override String get erreur => 'تعذّرت قراءة المراجعة.';
	@override String get erreurDetail => 'ربما ليس هذا الفصل فصلك، أو فشلت القراءة.';
	@override String get pasDeDecision => 'أنت تُبلغ، والأكاديمية تقرر: النقل وإعادة التوجيه لا يُقرَّران من هنا.';
	@override String get typeGate => 'مرحلة قادمة';
	@override String get typeCorridor => 'طالب خارج المسار المتوقع';
	@override String get typeTransfert => 'اقتراح نقل';
	@override String get typeReorientation => 'اقتراح إعادة توجيه';
}

// Path: compte.roles
class _Traductions$compte$roles$ar extends Traductions$compte$roles$fr {
	_Traductions$compte$roles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get admin => 'مدير';
	@override String get accountant => 'محاسب';
	@override String get controller => 'مراقب';
	@override String get teacher => 'معلم';
	@override String get guardian => 'وليّ أمر';
	@override String get student => 'طالب';
}

// Path: compte.roleDetail
class _Traductions$compte$roleDetail$ar extends Traductions$compte$roleDetail$fr {
	_Traductions$compte$roleDetail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get admin => 'يدير ملفات الأكاديمية والإسناد والسجل';
	@override String get accountant => 'يدير المدفوعات والفواتير';
	@override String get controller => 'يتابع الحصص من أجل الجودة التعليمية';
	@override String get teacher => 'يقدّم الدروس ويتابع مواعيده';
	@override String get guardian => 'يتابع الأسرة وأطفالها';
	@override String get student => 'يتابع دروسه وقراءته للقرآن';
}

// Path: compte.tuteur
class _Traductions$compte$tuteur$ar extends Traductions$compte$tuteur$fr {
	_Traductions$compte$tuteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get preferences => 'التفضيلات';
	@override String dateLongue({required Object jour, required Object mois, required Object annee}) => '⁨${jour}⁩ ⁨${mois}⁩ ⁨${annee}⁩';
	@override late final _Traductions$compte$tuteur$identite$ar identite = _Traductions$compte$tuteur$identite$ar._(_root);
	@override late final _Traductions$compte$tuteur$acces$ar acces = _Traductions$compte$tuteur$acces$ar._(_root);
	@override late final _Traductions$compte$tuteur$securite$ar securite = _Traductions$compte$tuteur$securite$ar._(_root);
	@override late final _Traductions$compte$tuteur$informations$ar informations = _Traductions$compte$tuteur$informations$ar._(_root);
	@override late final _Traductions$compte$tuteur$foyer$ar foyer = _Traductions$compte$tuteur$foyer$ar._(_root);
	@override late final _Traductions$compte$tuteur$aide$ar aide = _Traductions$compte$tuteur$aide$ar._(_root);
	@override late final _Traductions$compte$tuteur$deconnexion$ar deconnexion = _Traductions$compte$tuteur$deconnexion$ar._(_root);
	@override late final _Traductions$compte$tuteur$pageInformations$ar pageInformations = _Traductions$compte$tuteur$pageInformations$ar._(_root);
	@override late final _Traductions$compte$tuteur$pageSecurite$ar pageSecurite = _Traductions$compte$tuteur$pageSecurite$ar._(_root);
	@override late final _Traductions$compte$tuteur$pageAcces$ar pageAcces = _Traductions$compte$tuteur$pageAcces$ar._(_root);
	@override late final _Traductions$compte$tuteur$pagePaiements$ar pagePaiements = _Traductions$compte$tuteur$pagePaiements$ar._(_root);
	@override late final _Traductions$compte$tuteur$pagePreferences$ar pagePreferences = _Traductions$compte$tuteur$pagePreferences$ar._(_root);
	@override late final _Traductions$compte$tuteur$pageApparence$ar pageApparence = _Traductions$compte$tuteur$pageApparence$ar._(_root);
	@override late final _Traductions$compte$tuteur$pageAide$ar pageAide = _Traductions$compte$tuteur$pageAide$ar._(_root);
	@override late final _Traductions$compte$tuteur$pageLegal$ar pageLegal = _Traductions$compte$tuteur$pageLegal$ar._(_root);
}

// Path: tc.bibliotheque
class _Traductions$tc$bibliotheque$ar extends Traductions$tc$bibliotheque$fr {
	_Traductions$tc$bibliotheque$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$bibliotheque$sections$ar sections = _Traductions$tc$bibliotheque$sections$ar._(_root);
	@override String get titre => 'المكتبة';
	@override String get rechercheIndication => 'العنوان أو المستوى أو السورة أو الصفحة';
	@override String get rechercheLibelle => 'البحث عن مادة';
	@override String get effacerRecherche => 'عرض الكل';
	@override late final _Traductions$tc$bibliotheque$filtre$ar filtre = _Traductions$tc$bibliotheque$filtre$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$vide$ar vide = _Traductions$tc$bibliotheque$vide$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$aucunResultat$ar aucunResultat = _Traductions$tc$bibliotheque$aucunResultat$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$indisponible$ar indisponible = _Traductions$tc$bibliotheque$indisponible$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$introuvable$ar introuvable = _Traductions$tc$bibliotheque$introuvable$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$offline$ar offline = _Traductions$tc$bibliotheque$offline$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$type$ar type = _Traductions$tc$bibliotheque$type$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$detail$ar detail = _Traductions$tc$bibliotheque$detail$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$action$ar action = _Traductions$tc$bibliotheque$action$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$message$ar message = _Traductions$tc$bibliotheque$message$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$classe$ar classe = _Traductions$tc$bibliotheque$classe$ar._(_root);
}

// Path: tc.groupe
class _Traductions$tc$groupe$ar extends Traductions$tc$groupe$fr {
	_Traductions$tc$groupe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$groupe$enseignant$ar enseignant = _Traductions$tc$groupe$enseignant$ar._(_root);
	@override late final _Traductions$tc$groupe$mesGroupes$ar mesGroupes = _Traductions$tc$groupe$mesGroupes$ar._(_root);
	@override late final _Traductions$tc$groupe$commun$ar commun = _Traductions$tc$groupe$commun$ar._(_root);
	@override late final _Traductions$tc$groupe$carte$ar carte = _Traductions$tc$groupe$carte$ar._(_root);
	@override late final _Traductions$tc$groupe$cours$ar cours = _Traductions$tc$groupe$cours$ar._(_root);
	@override late final _Traductions$tc$groupe$temps$ar temps = _Traductions$tc$groupe$temps$ar._(_root);
	@override late final _Traductions$tc$groupe$duree$ar duree = _Traductions$tc$groupe$duree$ar._(_root);
	@override late final _Traductions$tc$groupe$horloges$ar horloges = _Traductions$tc$groupe$horloges$ar._(_root);
	@override late final _Traductions$tc$groupe$dst$ar dst = _Traductions$tc$groupe$dst$ar._(_root);
	@override late final _Traductions$tc$groupe$session$ar session = _Traductions$tc$groupe$session$ar._(_root);
	@override late final _Traductions$tc$groupe$espace$ar espace = _Traductions$tc$groupe$espace$ar._(_root);
	@override late final _Traductions$tc$groupe$emplacement$ar emplacement = _Traductions$tc$groupe$emplacement$ar._(_root);
}

// Path: tc.coran
class _Traductions$tc$coran$ar extends Traductions$tc$coran$fr {
	_Traductions$tc$coran$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$coran$modes$ar modes = _Traductions$tc$coran$modes$ar._(_root);
	@override late final _Traductions$tc$coran$mushaf$ar mushaf = _Traductions$tc$coran$mushaf$ar._(_root);
	@override late final _Traductions$tc$coran$fidelite$ar fidelite = _Traductions$tc$coran$fidelite$ar._(_root);
	@override late final _Traductions$tc$coran$zoom$ar zoom = _Traductions$tc$coran$zoom$ar._(_root);
	@override late final _Traductions$tc$coran$navigation$ar navigation = _Traductions$tc$coran$navigation$ar._(_root);
	@override late final _Traductions$tc$coran$reprise$ar reprise = _Traductions$tc$coran$reprise$ar._(_root);
	@override late final _Traductions$tc$coran$focus$ar focus = _Traductions$tc$coran$focus$ar._(_root);
}

// Path: tc.outils
class _Traductions$tc$outils$ar extends Traductions$tc$outils$fr {
	_Traductions$tc$outils$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$outils$dock$ar dock = _Traductions$tc$outils$dock$ar._(_root);
	@override late final _Traductions$tc$outils$intention$ar intention = _Traductions$tc$outils$intention$ar._(_root);
	@override late final _Traductions$tc$outils$trait$ar trait = _Traductions$tc$outils$trait$ar._(_root);
	@override late final _Traductions$tc$outils$portee$ar portee = _Traductions$tc$outils$portee$ar._(_root);
	@override late final _Traductions$tc$outils$marquer$ar marquer = _Traductions$tc$outils$marquer$ar._(_root);
	@override late final _Traductions$tc$outils$revision$ar revision = _Traductions$tc$outils$revision$ar._(_root);
	@override late final _Traductions$tc$outils$masquer$ar masquer = _Traductions$tc$outils$masquer$ar._(_root);
	@override late final _Traductions$tc$outils$focus$ar focus = _Traductions$tc$outils$focus$ar._(_root);
	@override late final _Traductions$tc$outils$annotation$ar annotation = _Traductions$tc$outils$annotation$ar._(_root);
}

// Path: tc.classe
class _Traductions$tc$classe$ar extends Traductions$tc$classe$fr {
	_Traductions$tc$classe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$classe$entete$ar entete = _Traductions$tc$classe$entete$ar._(_root);
	@override late final _Traductions$tc$classe$roster$ar roster = _Traductions$tc$classe$roster$ar._(_root);
	@override late final _Traductions$tc$classe$etat$ar etat = _Traductions$tc$classe$etat$ar._(_root);
	@override late final _Traductions$tc$classe$fiche$ar fiche = _Traductions$tc$classe$fiche$ar._(_root);
	@override late final _Traductions$tc$classe$action$ar action = _Traductions$tc$classe$action$ar._(_root);
	@override late final _Traductions$tc$classe$rappel$ar rappel = _Traductions$tc$classe$rappel$ar._(_root);
	@override late final _Traductions$tc$classe$recitation$ar recitation = _Traductions$tc$classe$recitation$ar._(_root);
	@override late final _Traductions$tc$classe$support$ar support = _Traductions$tc$classe$support$ar._(_root);
	@override late final _Traductions$tc$classe$commandes$ar commandes = _Traductions$tc$classe$commandes$ar._(_root);
	@override late final _Traductions$tc$classe$scene$ar scene = _Traductions$tc$classe$scene$ar._(_root);
	@override late final _Traductions$tc$classe$reseau$ar reseau = _Traductions$tc$classe$reseau$ar._(_root);
	@override late final _Traductions$tc$classe$attente$ar attente = _Traductions$tc$classe$attente$ar._(_root);
	@override late final _Traductions$tc$classe$lien$ar lien = _Traductions$tc$classe$lien$ar._(_root);
	@override late final _Traductions$tc$classe$barre$ar barre = _Traductions$tc$classe$barre$ar._(_root);
	@override late final _Traductions$tc$classe$prevol$ar prevol = _Traductions$tc$classe$prevol$ar._(_root);
	@override late final _Traductions$tc$classe$observation$ar observation = _Traductions$tc$classe$observation$ar._(_root);
}

// Path: tc.realtime
class _Traductions$tc$realtime$ar extends Traductions$tc$realtime$fr {
	_Traductions$tc$realtime$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$realtime$transport$ar transport = _Traductions$tc$realtime$transport$ar._(_root);
	@override late final _Traductions$tc$realtime$etat$ar etat = _Traductions$tc$realtime$etat$ar._(_root);
}

// Path: tc.observation
class _Traductions$tc$observation$ar extends Traductions$tc$observation$fr {
	_Traductions$tc$observation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$observation$entree$ar entree = _Traductions$tc$observation$entree$ar._(_root);
	@override late final _Traductions$tc$observation$explication$ar explication = _Traductions$tc$observation$explication$ar._(_root);
	@override late final _Traductions$tc$observation$disponibilite$ar disponibilite = _Traductions$tc$observation$disponibilite$ar._(_root);
	@override late final _Traductions$tc$observation$connexion$ar connexion = _Traductions$tc$observation$connexion$ar._(_root);
	@override late final _Traductions$tc$observation$duree$ar duree = _Traductions$tc$observation$duree$ar._(_root);
	@override late final _Traductions$tc$observation$refus$ar refus = _Traductions$tc$observation$refus$ar._(_root);
	@override late final _Traductions$tc$observation$visite$ar visite = _Traductions$tc$observation$visite$ar._(_root);
	@override late final _Traductions$tc$observation$fin$ar fin = _Traductions$tc$observation$fin$ar._(_root);
	@override late final _Traductions$tc$observation$resultat$ar resultat = _Traductions$tc$observation$resultat$ar._(_root);
	@override late final _Traductions$tc$observation$annonce$ar annonce = _Traductions$tc$observation$annonce$ar._(_root);
	@override late final _Traductions$tc$observation$reglages$ar reglages = _Traductions$tc$observation$reglages$ar._(_root);
}

// Path: tc.parcours
class _Traductions$tc$parcours$ar extends Traductions$tc$parcours$fr {
	_Traductions$tc$parcours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$parcours$avant$ar avant = _Traductions$tc$parcours$avant$ar._(_root);
	@override late final _Traductions$tc$parcours$intention$ar intention = _Traductions$tc$parcours$intention$ar._(_root);
	@override late final _Traductions$tc$parcours$plage$ar plage = _Traductions$tc$parcours$plage$ar._(_root);
	@override late final _Traductions$tc$parcours$feedback$ar feedback = _Traductions$tc$parcours$feedback$ar._(_root);
	@override late final _Traductions$tc$parcours$signalement$ar signalement = _Traductions$tc$parcours$signalement$ar._(_root);
	@override late final _Traductions$tc$parcours$postCours$ar postCours = _Traductions$tc$parcours$postCours$ar._(_root);
}

// Path: nav.eleve
class _Traductions$nav$eleve$ar extends Traductions$nav$eleve$fr {
	_Traductions$nav$eleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'الرئيسية';
	@override String get maClasse => 'فصلي';
	@override String get coran => 'القرآن';
	@override String get monEspace => 'مساحتي';
	@override String get suivi => 'المتابعة';
	@override String get compte => 'الحساب';
}

// Path: nav.tuteur
class _Traductions$nav$tuteur$ar extends Traductions$nav$tuteur$fr {
	_Traductions$nav$tuteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'الرئيسية';
	@override String get foyer => 'الأسرة';
	@override String get disponibilites => 'أوقات التوفر';
	@override String get reglages => 'الإعدادات';
	@override String get suivi => 'المتابعة';
	@override String get historique => 'السجل';
	@override String get compte => 'الحساب';
}

// Path: nav.enseignant
class _Traductions$nav$enseignant$ar extends Traductions$nav$enseignant$fr {
	_Traductions$nav$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get journee => 'اليوم';
	@override String get classes => 'الفصول';
	@override String get creneaux => 'أوقات التوفر';
	@override String get profil => 'الملف الشخصي';
}

// Path: nav.controleur
class _Traductions$nav$controleur$ar extends Traductions$nav$controleur$fr {
	_Traductions$nav$controleur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get planning => 'الجدول';
	@override String get controle => 'المراقبة';
	@override String get historique => 'السجل';
	@override String get echanges => 'المراسلات';
	@override String get compte => 'الحساب';
}

// Path: nav.admin
class _Traductions$nav$admin$ar extends Traductions$nav$admin$fr {
	_Traductions$nav$admin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tableauDeBord => 'لوحة التحكم';
	@override String get dossiers => 'الملفات';
	@override String get demandes => 'الطلبات';
	@override String get attribution => 'الإسناد';
	@override String get journal => 'السجل';
	@override String get comptes => 'الحسابات';
	@override String get accesAgents => 'صلاحيات الموظفين';
	@override String get accueil => 'الرئيسية';
	@override String get operations => 'العمليات';
	@override String get personnes => 'الأشخاص';
	@override String get pedagogie => 'التعليم';
	@override String get finance => 'المالية';
	@override String get configuration => 'الإعدادات العامة';
	@override String get securite => 'الأمان والتدقيق';
	@override String get direction => 'الإدارة';
	@override String get recherche => 'البحث';
	@override String get rechercheIndication => 'البحث عن شاشة';
	@override String get notificationsTitre => 'الإشعارات';
	@override String get menu => 'القائمة';
}

// Path: accessibilite.demo
class _Traductions$accessibilite$demo$ar extends Traductions$accessibilite$demo$fr {
	_Traductions$accessibilite$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'عرض تجريبي لوضع إمكانية الوصول';
	@override String get mention => 'بيانات وهمية، لا إرسال.';
	@override String get intro => 'اختر طالبًا ولحظة من الحصة.';
	@override String get eleveMineure => 'مريم، طالبة قاصر';
	@override String get eleveAdulte => 'إدريس، طالب بالغ';
	@override String get etatAvant => 'قبل الحصة';
	@override String get etatFenetre => 'قبيل الحصة، الدخول مفتوح';
	@override String get etatPendant => 'أثناء الحصة';
	@override String get etatApres => 'بعد الحصة';
}

// Path: accessibilite.accueil
class _Traductions$accessibilite$accueil$ar extends Traductions$accessibilite$accueil$fr {
	_Traductions$accessibilite$accueil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String salutation({required Object prenom}) => 'السلام عليكم، ⁨${prenom}⁩.';
	@override String get prochaineSeance => 'الحصة القادمة';
	@override String avec({required Object nomme}) => 'مع ⁨${nomme}⁩';
	@override String get voirMaClasse => 'عرض فصلي';
	@override String get lireCoran => 'قراءة القرآن';
	@override String get lireCoranDetail => 'فتح المصحف';
	@override String get aide => 'تحتاج إلى مساعدة؟';
	@override String get erreurTitre => 'لم تُحمَّل الحصة القادمة';
	@override String get erreurPhrase => 'تعذّرت قراءة الحصة والعمل المطلوب، غالبًا بسبب الاتصال. يكفي أن تعيد المحاولة بعد لحظة.';
	@override String get indisponibleTitre => 'الحصة القادمة لا تظهر هنا بعد';
	@override String get indisponiblePhrase => 'الصفحة الرئيسية لا تستقبل حصة الفصل بعد. تجدها في «فصلي».';
	@override String get videTitre => 'لا فصل بعد';
	@override String get videPhrase => 'لم يُسند أي فصل بعد. يُختار الفصل مع الأكاديمية. وإلى ذلك الحين، يبقى القرآن والمساعدة متاحين أدناه.';
}

// Path: accessibilite.coran
class _Traductions$accessibilite$coran$ar extends Traductions$accessibilite$coran$fr {
	_Traductions$accessibilite$coran$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouvrir => 'فتح القرآن';
	@override String get reprendre => 'المتابعة من آخر صفحة';
	@override String get reprendreVous => 'المتابعة من آخر صفحة';
	@override String reprendreDetail({required Object page}) => 'كنت في الصفحة ⁨${page}⁩.';
	@override String reprendreDetailVous({required Object page}) => 'كنت في الصفحة ⁨${page}⁩.';
	@override String get repriseRecherche => 'جارٍ البحث عن آخر صفحة…';
	@override String get repriseRechercheVous => 'جارٍ البحث عن آخر صفحة…';
	@override String get repriseErreur => 'تعذّر العثور على آخر صفحة، غالبًا بسبب الاتصال. افتح القرآن واختر صفحتك في القارئ. إعدادات القراءة تبقى محفوظة.';
	@override String get repriseErreurVous => 'تعذّر العثور على آخر صفحة، غالبًا بسبب الاتصال. افتح القرآن واختر صفحتك في القارئ. إعدادات القراءة تبقى محفوظة.';
	@override String get lectureGrande => 'يُفتح القرآن في قراءة مكبَّرة، آية آية.';
	@override String get retour => 'العودة إلى مدخل القرآن';
	@override String get demoSansTexte => 'نص القرآن غير محمَّل في العرض التجريبي';
	@override String get demoSansTexteDetail => 'ليس هذا عطلًا: العرض التجريبي لا يحتوي على النص. لا شيء عليك فعله. في التطبيق، يُفتح القرآن هنا على صفحتك، وتبقى إعدادات القراءة محفوظة.';
	@override String get demoSansTexteDetailVous => 'ليس هذا عطلًا: العرض التجريبي لا يحتوي على النص. لا شيء عليك فعله. في التطبيق، يُفتح القرآن هنا على صفحتك، وتبقى إعدادات القراءة محفوظة.';
}

// Path: accessibilite.maClasse
class _Traductions$accessibilite$maClasse$ar extends Traductions$accessibilite$maClasse$fr {
	_Traductions$accessibilite$maClasse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'فصلي';
	@override String get suivi => 'متابعتي';
	@override String get suiviDetail => 'الحصص الماضية والحضور';
}

// Path: accessibilite.tutoiement
class _Traductions$accessibilite$tutoiement$ar extends Traductions$accessibilite$tutoiement$fr {
	_Traductions$accessibilite$tutoiement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tonHeure => 'توقيتك';
	@override String get attenteDetail => 'وقت الانتظار هذا لا يُحتسب في حضورك.';
	@override String attente({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ⁨${duree}⁩.';
	@override String get attenteImminent => 'أنت في القاعة. تبدأ الحصة بعد أقل من دقيقة.';
	@override String get annonceAttente => 'أنت في القاعة';
	@override String get horsLigne => 'أنت غير متصل. تحتاج الحصة إلى اتصال.';
	@override String get finPhrase => 'تجد عملك في فصلك.';
}

// Path: accessibilite.apres
class _Traductions$accessibilite$apres$ar extends Traductions$accessibilite$apres$fr {
	_Traductions$accessibilite$apres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get revoirSupport => 'مراجعة مادة الدرس';
	@override String get revoirSupportDetail => 'تبقى المادة في فصلك.';
	@override String get revoirSupportDetailVous => 'تبقى المادة في فصلك.';
}

// Path: accessibilite.monEspace
class _Traductions$accessibilite$monEspace$ar extends Traductions$accessibilite$monEspace$fr {
	_Traductions$accessibilite$monEspace$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مساحتي';
	@override String get mode => 'وضع إمكانية الوصول';
	@override String get modeDetail => 'واجهة مبسطة ومكيَّفة لتعلم أكثر طمأنينة.';
	@override String get modeActif => 'مفعَّل';
	@override String get presentationStandard => 'العرض العادي';
	@override String get demanderDetail => 'اطلب من وليّ أمرك الانتقال إلى العرض العادي.';
	@override String get demandeEnCours => 'جارٍ إرسال طلبك.';
	@override String get demandeEnvoyee => 'أُرسل طلبك إلى وليّ أمرك.';
	@override String get demandeNonConfirmee => 'لم يُؤكَّد الإرسال، غالبًا بسبب الاتصال. تحقّق من اتصالك، ثم المس السطر لإعادة المحاولة. لم يتغير شيء في الأثناء: يبقى العرض كما هو.';
}

// Path: ficheEleve.introuvable
class _Traductions$ficheEleve$introuvable$ar extends Traductions$ficheEleve$introuvable$fr {
	_Traductions$ficheEleve$introuvable$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'لم يُعثر على ملف الطالب هذا';
	@override String get phrase => 'ليس من أسرتك، أو الرابط ناقص.';
	@override String get retour => 'العودة إلى الأسرة';
}

// Path: ficheEleve.lignes
class _Traductions$ficheEleve$lignes$ar extends Traductions$ficheEleve$lignes$fr {
	_Traductions$ficheEleve$lignes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get informations => 'المعلومات';
	@override String get informationsLegende => 'الاسم والصورة';
	@override String get inscription => 'المسار والتسجيل';
	@override String get inscriptionLegende => 'الاستبيان والفصل';
	@override String get interface => 'الواجهة';
	@override String get camera => 'الكاميرا أثناء الدرس';
	@override String get cameraAutorisee => 'مسموح بها';
	@override String get cameraNonAutorisee => 'غير مسموح بها';
	@override String get acces => 'الوصول إلى Rewayah';
	@override String appareils({required Object prenom}) => 'أجهزة ⁨${prenom}⁩';
	@override String get appareilsLegende => 'ربط جهاز، عرض الأجهزة المربوطة، إزالة أحدها';
}

// Path: ficheEleve.informations
class _Traductions$ficheEleve$informations$ar extends Traductions$ficheEleve$informations$fr {
	_Traductions$ficheEleve$informations$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'معلومات الطالب';
	@override String get identite => 'الهوية';
	@override String get prenom => 'الاسم';
	@override String get identiteNote => 'لا يُعدَّل الاسم من هذه الصفحة بعد.';
	@override String get ageNote => 'العمر وتاريخ الميلاد غير مسجلين في الملف بعد.';
	@override String get photo => 'الصورة';
	@override String photoLegende({required Object prenom}) => 'صورة لوجه ⁨${prenom}⁩. ليست وثيقة هوية.';
	@override String get photoAucune => 'لا صورة بعد';
	@override String get photoPresente => 'الصورة محفوظة';
	@override String get choisir => 'اختيار صورة';
	@override String get changer => 'تغيير الصورة';
	@override String get apercuTitre => 'معاينة';
	@override String get apercuPhrase => 'تحقّق من الصورة قبل إرسالها.';
	@override String get apercuIllisible => 'لا تظهر المعاينة على هذا الجهاز. يمكن مع ذلك إرسال الصورة.';
	@override String get envoyer => 'إرسال هذه الصورة';
	@override String get autre => 'اختيار صورة أخرى';
	@override String get annuler => 'إلغاء';
	@override String get etapeEnvoi => 'إرسال الصورة، الخطوة 1 من 2';
	@override String get etapeEnregistrement => 'الحفظ في الملف، الخطوة 2 من 2';
	@override String get succes => 'حُفظت الصورة.';
	@override String tropLourde({required Object taille}) => 'هذه الصورة تتجاوز ⁨${taille}⁩ م.ب. اختر صورة أخف.';
	@override String get echecEnvoi => 'تعذّر إرسال الصورة. لم يتغير شيء في الملف.';
	@override String get echecEnregistrement => 'أُرسلت الصورة، لكن تعذّر حفظها في الملف.';
	@override String get reprendre => 'إعادة المحاولة';
	@override String get selectionEchec => 'تعذّر فتح الصورة. تحقّق من إذن الوصول إلى صور الجهاز، ثم أعد المحاولة.';
	@override String get horsLigne => 'أنت غير متصل. يمكن إرسال الصورة عند عودة الاتصال.';
}

// Path: ficheEleve.inscription
class _Traductions$ficheEleve$inscription$ar extends Traductions$ficheEleve$inscription$fr {
	_Traductions$ficheEleve$inscription$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المسار والتسجيل';
	@override String intro({required Object prenom}) => 'أين وصل ⁨${prenom}⁩: الاستبيان والفصل.';
	@override String get questionnaire => 'الاستبيان';
	@override String get classe => 'الفصل';
	@override String get lecture => 'جارٍ القراءة';
	@override String get etatInconnu => 'حالة الاستبيان لا تظهر بعد.';
	@override String get aRemplir => 'للتعبئة';
	@override String get horaireAChoisir => 'مُعبّأ، الموعد للاختيار';
	@override String get horaireRetire => 'سُحب الموعد، يجب اختياره من جديد';
	@override String get echangeAPrevoir => 'التفضيل محفوظ، لقاء تحديد المستوى للبرمجة';
	@override String get echangePrevu => 'لقاء تحديد المستوى مبرمج';
	@override String get classeEnConstitution => 'الفصل قيد التكوين';
	@override String get classeConfirmee => 'الفصل مؤكَّد';
	@override String get classeAucune => 'لا فصل بعد. اختيار فصل';
	@override String get classeIndisponible => 'الفصل لا يظهر هنا بعد. اختيار فصل';
	@override String get classeEchec => 'تعذّرت قراءة الفصل.';
	@override String get relireClasse => 'إعادة قراءة الفصل';
}

// Path: ficheEleve.interface
class _Traductions$ficheEleve$interface$ar extends Traductions$ficheEleve$interface$fr {
	_Traductions$ficheEleve$interface$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الواجهة';
	@override String intro({required Object prenom}) => 'اختر كيف يظهر Rewayah على جهاز ⁨${prenom}⁩. يمكنك تغيير هذا الاختيار في أي وقت.';
	@override String get guidee => 'وضع إمكانية الوصول';
	@override String guideeDescription({required Object prenom}) => 'حين يفضّل ⁨${prenom}⁩ شاشات خفيفة: نصوص أكبر، وإجراء واحد في كل مرة. الأقسام نفسها والصلاحيات نفسها.';
	@override String get standard => 'العرض العادي';
	@override String standardDescription({required Object prenom}) => 'حين يرتاح ⁨${prenom}⁩ لشاشات أكثف: معلومات أكثر في كل شاشة. الأقسام نفسها والصلاحيات نفسها.';
	@override String get politique => 'أنت من يختار هذا الإعداد. لا يُطلب أي سبب، ولا يرى المعلم إلا اسم الوضع.';
	@override String application({required Object prenom}) => 'يُطبَّق التغيير عند الفتح التالي لـRewayah على جهاز ⁨${prenom}⁩.';
	@override String get demandeEleve => 'طلب التغيير من الطالب نفسه غير متاح بعد.';
	@override String get enCours => 'جارٍ الحفظ';
	@override String echec({required Object prenom}) => 'لم يُحفظ التغيير، غالبًا بسبب انقطاع الاتصال بـRewayah. تحقّق من اتصالك، ثم المس اختيارك من جديد. يبقى العرض الحالي لـ⁨${prenom}⁩ كما هو على جهازه.';
	@override String get horsLigne => 'أنت غير متصل. يمكن تغيير العرض عند عودة الاتصال.';
}

// Path: ficheEleve.camera
class _Traductions$ficheEleve$camera$ar extends Traductions$ficheEleve$camera$fr {
	_Traductions$ficheEleve$camera$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الكاميرا أثناء الدرس';
	@override String get ligne => 'الكاميرا أثناء الحصص';
	@override String autorisee({required Object prenom}) => 'يمكن لـ⁨${prenom}⁩ تشغيل كاميرته أثناء الحصص.';
	@override String interdite({required Object prenom}) => 'لن يظهر زر الكاميرا لـ⁨${prenom}⁩ أثناء الحصص.';
	@override String application({required Object prenom}) => 'يُحتسب التغيير عند الدخول التالي لـ⁨${prenom}⁩ إلى حصة.';
	@override String get distincte => 'هذا الإعداد لا يغيّر إذن الكاميرا في الجهاز، الذي يطلبه الهاتف لقراءة رمز QR.';
	@override String get echec => 'لم يُحفظ التغيير. أعد المحاولة.';
	@override String get horsLigne => 'أنت غير متصل. يمكن ضبط الكاميرا عند عودة الاتصال.';
}

// Path: ficheEleve.acces
class _Traductions$ficheEleve$acces$ar extends Traductions$ficheEleve$acces$fr {
	_Traductions$ficheEleve$acces$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الوصول إلى Rewayah';
	@override String ligne({required Object prenom}) => 'وصول ⁨${prenom}⁩';
	@override String get pastilleSansEcheance => 'دون موعد انتهاء';
	@override String get pastilleEnCours => 'ساري';
	@override String get pastilleExpire => 'منتهٍ';
	@override String get sansEcheance => 'لا تاريخ انتهاء مسجَّل.';
	@override String jusquau({required Object date}) => 'حتى ⁨${date}⁩';
	@override String expireDepuis({required Object date}) => 'منتهٍ منذ ⁨${date}⁩';
	@override String expirePhrase({required Object prenom}) => 'منذ هذا التاريخ، لا يستطيع ⁨${prenom}⁩ الدخول إلى Rewayah.';
	@override String get detailIndisponible => 'بداية الوصول وسببه لا يظهران بعد.';
}

// Path: eleveConnexion.profils
class _Traductions$eleveConnexion$profils$ar extends Traductions$eleveConnexion$profils$fr {
	_Traductions$eleveConnexion$profils$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get phrase => 'المس اسمك للمتابعة.';
	@override String get ajouter => 'إضافة ملف على هذا الجهاز';
	@override String get ajouterLegende => 'بالرمز الذي يعرضه وليّ الأمر';
	@override String profilLibelle({required Object prenom}) => 'المتابعة باسم ⁨${prenom}⁩';
	@override String get videTitre => 'لا ملف على هذا الجهاز';
	@override String get vide => 'لاستخدام هذا الجهاز، يجب أن يعرض وليّ الأمر رمزًا جديدًا على جهازه.';
	@override String get videAction => 'إدخال رمز';
	@override String retire({required Object prenom}) => 'أُزيل هذا الجهاز لـ⁨${prenom}⁩. اطلب من وليّ الأمر إعادة ربطه برمز جديد.';
	@override String jetonAbsent({required Object prenom}) => 'لم يعد هذا الجهاز يجد اتصال ⁨${prenom}⁩. اطلب من وليّ الأمر عرض رمز جديد، ثم أدخله هنا.';
}

// Path: eleveConnexion.pin
class _Traductions$eleveConnexion$pin$ar extends Traductions$eleveConnexion$pin$fr {
	_Traductions$eleveConnexion$pin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String bonjour({required Object prenom}) => 'مرحبًا ⁨${prenom}⁩';
	@override String get creer => 'اختر رمزك الشخصي';
	@override String get creerPhrase => 'أربعة أرقام، لك وحدك. يبقى على هذا الجهاز.';
	@override String get confirmer => 'أدخله مرة أخرى';
	@override String get different => 'الرمزان غير متطابقين. اختر رمزك من جديد.';
	@override String get ouverture => 'جارٍ الاتصال';
	@override String get horsLigne => 'لا اتصال بالإنترنت. رمزك صحيح: أعد المحاولة عند عودة الإنترنت.';
	@override String get tropDEssais => 'محاولات كثيرة. انتظر قليلًا قبل إعادة المحاولة.';
	@override String get echec => 'لم يكتمل الاتصال. أعد المحاولة بعد لحظة.';
	@override String get changerProfil => 'تغيير الملف';
	@override String get oublie => 'نسيت الرمز؟';
	@override String get oubliePhrase => 'اطلب من وليّ الأمر عرض رمز جديد على جهازه، ثم أدخله هنا. ستختار حينها رمزًا شخصيًا جديدًا.';
	@override String get oublieAction => 'إدخال رمز جديد';
}

// Path: eleveConnexion.saisie
class _Traductions$eleveConnexion$saisie$ar extends Traductions$eleveConnexion$saisie$fr {
	_Traductions$eleveConnexion$saisie$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ربط هذا الجهاز';
	@override String get phrase => 'أدخل الرمز المكوَّن من ستة أحرف المعروض تحت رمز QR، على جهاز وليّ الأمر.';
	@override String get champ => 'الرمز';
	@override String get aide => 'أرقام من 2 إلى 9 وحروف لاتينية، دون I ولا O.';
	@override String get valider => 'ربط الجهاز';
	@override String get scanner => 'مسح رمز QR';
	@override String get horsLigne => 'لا اتصال بالإنترنت. يمكن التحقق من الرمز عند عودة الشبكة.';
}

// Path: eleveConnexion.lecteur
class _Traductions$eleveConnexion$lecteur$ar extends Traductions$eleveConnexion$lecteur$fr {
	_Traductions$eleveConnexion$lecteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مسح رمز QR';
	@override String get consigne => 'وجّه الكاميرا نحو رمز QR المعروض على جهاز وليّ الأمر.';
	@override String get demarrage => 'اسمح بالكاميرا إن طلب الجهاز ذلك.';
	@override String get libelleApercu => 'عرض الكاميرا';
	@override String get contenuInvalide => 'رمز QR هذا ليس رمز ربط من Rewayah. وجّه الكاميرا نحو الرمز الذي يعرضه وليّ الأمر.';
	@override String get saisir => 'إدخال الرمز';
	@override String get scannerANouveau => 'المسح من جديد';
	@override String get verificationTitre => 'جارٍ التحقق من الرمز';
	@override String get verificationPhrase => 'الكاميرا متوقفة أثناء التحقق.';
	@override String get refuseeTitre => 'الكاميرا غير مسموح بها';
	@override String get refuseePhrase => 'لقراءة رمز QR، اسمح بالكاميرا. يمكنك أيضًا إدخال الرمز المعروض تحت رمز QR.';
	@override String get refuseeAction => 'السماح بالكاميرا';
	@override String get refuseeDurablementTitre => 'الكاميرا محظورة';
	@override String get refuseeDurablementPhrase => 'ما زالت الكاميرا مرفوضة لـRewayah. اسمح بها في إعدادات الجهاز أو المتصفح، أو أدخل الرمز.';
	@override String get occupeeTitre => 'الكاميرا مشغولة';
	@override String get occupeePhrase => 'تطبيق آخر يستخدم الكاميرا. أغلقه ثم أعد المحاولة، أو أدخل الرمز.';
	@override String get absenteTitre => 'لا كاميرا';
	@override String get absentePhrase => 'لا كاميرا متاحة على هذا الجهاز. أدخل الرمز المعروض تحت رمز QR.';
	@override String get nonSupporteeTitre => 'القراءة غير ممكنة هنا';
	@override String get nonSupporteePhrase => 'هذا الجهاز أو المتصفح لا يقرأ رموز QR. أدخل الرمز المعروض تحت رمز QR.';
	@override String get erreurTitre => 'لم تبدأ الكاميرا';
	@override String get erreurPhrase => 'أعد المحاولة، أو أدخل الرمز المعروض تحت رمز QR.';
}

// Path: eleveConnexion.refus
class _Traductions$eleveConnexion$refus$ar extends Traductions$eleveConnexion$refus$fr {
	_Traductions$eleveConnexion$refus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get format => 'الرمز ستة أحرف: أرقام من 2 إلى 9 وحروف لاتينية، دون I ولا O.';
	@override String get inconnuTitre => 'رمز غير معروف';
	@override String get inconnu => 'هذا الرمز غير موجود، أو حلّ محله رمز أحدث. تحقّق منه، أو اعرض رمزًا جديدًا على جهاز وليّ الأمر.';
	@override String get expireTitre => 'رمز منتهي الصلاحية';
	@override String get expire => 'هذا الرمز لم يعد صالحًا. اعرض رمزًا جديدًا على جهاز وليّ الأمر.';
	@override String get dejaUtiliseTitre => 'رمز مستخدَم';
	@override String get dejaUtilise => 'استُخدم هذا الرمز لربط جهاز من قبل. اعرض رمزًا جديدًا على جهاز وليّ الأمر.';
	@override String get revoqueTitre => 'جهاز مُزال';
	@override String get revoque => 'أزال وليّ الأمر هذا الجهاز. اطلب منه عرض رمز جديد.';
	@override String get plafondTitre => 'بلغت حد الأجهزة';
	@override String get plafond => 'بلغ ملف الطالب هذا عدد الأجهزة المسموح به. يمكن لوليّ الأمر إزالة أحدها من «الأسرة»، ثم عرض رمز جديد.';
	@override String get tropDEssaisTitre => 'محاولات كثيرة';
	@override String get tropDEssais => 'انتظر قليلًا قبل إعادة المحاولة.';
	@override String get horsLigneTitre => 'لا اتصال';
	@override String get horsLigne => 'تعذّر التحقق من الرمز. تحقّق من الاتصال بالإنترنت، ثم أعد المحاولة.';
	@override String get nonEnregistreTitre => 'لم يُحفظ الربط';
	@override String get nonEnregistre => 'لم يستطع هذا الجهاز الاحتفاظ بالربط. ربما استُخدم الرمز من قبل: اعرض رمزًا جديدًا على جهاز وليّ الأمر، ثم ابدأ من جديد.';
	@override String get generiqueTitre => 'لم يكتمل الربط';
	@override String get generique => 'لم يكتمل التحقق من الرمز. أعد المحاولة بعد لحظة.';
}

// Path: tuteur.accueil
class _Traductions$tuteur$accueil$ar extends Traductions$tuteur$accueil$fr {
	_Traductions$tuteur$accueil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الرئيسية';
	@override String get voirLaClasse => 'عرض الفصل';
	@override String get prochaineSeance => 'الحصة القادمة';
	@override String heureDe({required Object ville}) => 'توقيت ⁨${ville}⁩';
	@override String get heureAppareil => 'توقيت هذا الجهاز';
	@override String dateEtFuseau({required Object date, required Object fuseau}) => '⁨${date}⁩ · ⁨${fuseau}⁩';
	@override String heureClasse({required Object heure, required Object ville}) => 'توقيت الفصل: ⁨${heure}⁩ ⁨${ville}⁩';
	@override String get seanceEnDirect => 'حصة مباشرة';
	@override String get seanceTerminee => 'انتهت الحصة';
	@override String get seanceAnnulee => 'لن تُعقد هذه الحصة.';
	@override String get seanceNonTenue => 'تعذّر عقد هذه الحصة.';
	@override String get horaireIncertain => 'فتح القاعة غير مؤكَّد الآن';
	@override String get pastilleAnnulee => 'ملغاة';
	@override String get pastilleNonTenue => 'لم تُعقد';
	@override String get pastilleTerminee => 'منتهية';
	@override String get aucuneSeance => 'لا حصة مقررة';
	@override String aucuneSeanceDetail({required Object prenom}) => 'ستظهر هنا الحصة القادمة لـ⁨${prenom}⁩ بمجرد جدولتها.';
	@override String get seanceIllisible => 'تعذّرت قراءة الحصة القادمة.';
	@override String get classeIndisponible => 'تفاصيل الفصل غير متاحة هنا بعد.';
	@override String get classeIllisible => 'تعذّرت قراءة الفصل.';
	@override String sansClasseTitre({required Object prenom}) => 'لا فصل لـ⁨${prenom}⁩';
	@override String sansClassePhrase({required Object prenom}) => 'اختر فصلًا ليتمكن ⁨${prenom}⁩ من بدء الدروس.';
	@override String get foyerVideTitre => 'لا ملف طالب حتى الآن';
	@override String get foyerVidePhrase => 'أضف ملف طالب لاختيار فصل ومتابعة حصصه.';
	@override String get ajouterProfil => 'إضافة ملف طالب';
	@override String get profilsIllisibles => 'تعذّرت قراءة ملفات الأسرة.';
	@override String blocageAppareilTitre({required Object prenom}) => 'لا جهاز جاهز لـ⁨${prenom}⁩';
	@override String blocageAppareilPhrase({required Object prenom}) => 'دون جهاز مربوط، لن يستطيع ⁨${prenom}⁩ دخول الفصل.';
	@override String get connecterAppareil => 'ربط جهاز';
	@override String get avantProchainCours => 'قبل الدرس القادم';
	@override String get voirTout => 'عرض الكل';
	@override String get travailIndisponible => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.';
	@override String get travailIllisible => 'تعذّرت قراءة العمل المطلوب تحضيره.';
	@override String get rienAPreparer => 'لا شيء للتحضير الآن';
	@override String get derniereSeance => 'آخر حصة';
	@override String get voirHistorique => 'عرض السجل';
	@override String get detailsSeance => 'تفاصيل الحصة';
	@override String get aucuneDerniere => 'لا حصة ماضية حتى الآن';
	@override String get derniereIllisible => 'تعذّرت قراءة آخر حصة.';
	@override String dateEtDuree({required Object date, required Object duree}) => '⁨${date}⁩ · ⁨${duree}⁩';
	@override late final _Traductions$tuteur$accueil$etatCourt$ar etatCourt = _Traductions$tuteur$accueil$etatCourt$ar._(_root);
	@override String get assister => 'الحضور';
	@override String get assisterRefuse => 'تعذّر الانضمام إلى الدرس. ربما انتهى للتو.';
	@override String enCours({required Object prenom}) => 'جارٍ مع ⁨${prenom}⁩';
	@override String depuisMinutes({required Object minutes}) => 'بدأ منذ ⁨${minutes}⁩ دقيقة';
	@override String get depuisInstant => 'بدأ للتو';
	@override String aujourdhui({required Object heure, required Object prenom}) => 'اليوم الساعة ⁨${heure}⁩، مع ⁨${prenom}⁩';
	@override String unAutreJour({required Object jour, required Object heure, required Object prenom}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩، مع ⁨${prenom}⁩';
	@override String get rienAujourdhui => 'لا شيء اليوم';
	@override String get aucunCoursPrevu => 'لا درس مجدول حتى الآن';
	@override String get aucunCoursPrevuDetail => 'تُحضَّر دروس الأسبوع مسبقًا. سيظهر هذا الدرس هنا.';
	@override String get enRecherche => 'جارٍ البحث عن معلم';
	@override String enRechercheDepuis({required Object date}) => 'قُدِّم الطلب في ⁨${date}⁩';
	@override String enRechercheSansDate({required Object prenom}) => 'سيتولى معلم ⁨${prenom}⁩ من بين الساعات المقترحة.';
	@override String sansCreneau({required Object prenom}) => 'لا ساعة مقترحة لـ⁨${prenom}⁩';
	@override String sansCreneauDetail({required Object prenom}) => 'دون موعد، لا يستطيع أي معلم تولي ⁨${prenom}⁩.';
	@override String get poserDesHeures => 'اقتراح ساعات';
	@override String annulee({required Object heure}) => 'لن يُعقد درس الساعة ⁨${heure}⁩';
	@override String get motifAnnulee => 'حصة ملغاة';
	@override String get motifAnnuleeTard => 'حصة ملغاة قبيل موعدها';
	@override String proposeApres({required Object jour, required Object heure}) => 'الدرس القادم ⁨${jour}⁩ الساعة ⁨${heure}⁩';
	@override String get proposeAucun => 'سيُقترح عليك درس جديد.';
	@override String get gererLeFoyer => 'إدارة الأسرة';
	@override String get blocAppareils => 'أجهزة الأسرة';
	@override String get blocAppareilsDetail => 'إضافة جهاز، أو إزالة أحدها.';
	@override String get blocReglages => 'الإعدادات لكل طفل';
	@override String get blocReglagesDetail => 'الصورة والكاميرا والعرض، طفلًا بطفل.';
	@override String get blocGroupesDetail => 'الفصل والمعلم والدرس القادم لكل طفل.';
	@override String get acces => 'الوصول';
	@override String accesJusqua({required Object prenom, required Object date}) => 'وصول ⁨${prenom}⁩ حتى ⁨${date}⁩';
	@override String accesSansFin({required Object prenom}) => 'وصول ⁨${prenom}⁩ دون تاريخ انتهاء';
	@override String get aucunEnfant => 'لا طفل في الأسرة';
	@override String get aucunEnfantDetail => 'أضف طفلك الأول للبدء.';
	@override String get erreur => 'تعذّرت قراءة الأسرة كاملة. أعد المحاولة بعد لحظة.';
}

// Path: tuteur.reglages
class _Traductions$tuteur$reglages$ar extends Traductions$tuteur$reglages$fr {
	_Traductions$tuteur$reglages$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإعدادات لكل طفل';
	@override String get intro => 'تُطبَّق هذه الإعدادات على الحصة التالية، وأبدًا أثناء درس.';
	@override String get photo => 'الصورة';
	@override String photoAucune({required Object prenom}) => 'ليس لـ⁨${prenom}⁩ صورة بعد. تبقى مرئية للأسرة وحدها.';
	@override String photoPresente({required Object prenom}) => 'تبقى صورة ⁨${prenom}⁩ مرئية للأسرة وحدها، ولا يراها معلمه ولا الطلاب الآخرون.';
	@override String get photoAjouter => 'إضافة صورة';
	@override String get photoChanger => 'تغيير الصورة';
	@override String photoTropLourde({required Object taille}) => 'هذه الصورة تتجاوز ⁨${taille}⁩ م.ب. التقطها بجودة أقل.';
	@override String get camera => 'الكاميرا';
	@override String cameraAutorisee({required Object prenom}) => 'يمكن لـ⁨${prenom}⁩ تشغيل كاميرته أثناء الدرس.';
	@override String cameraInterdite({required Object prenom}) => 'لن يظهر زر الكاميرا لـ⁨${prenom}⁩.';
	@override String cameraAutoriser({required Object prenom}) => 'السماح بكاميرا ⁨${prenom}⁩';
	@override String cameraRetirer({required Object prenom}) => 'إلغاء كاميرا ⁨${prenom}⁩';
	@override String get mode => 'العرض';
	@override String modeEnfant({required Object prenom}) => 'عرض كبير، دون قراءة: يتعرف ⁨${prenom}⁩ على الصور ويستمع.';
	@override String modeStandard({required Object prenom}) => 'عرض عادي: يقرأ ⁨${prenom}⁩ شاشته.';
	@override String modePasserEnfant({required Object prenom}) => 'نقل ⁨${prenom}⁩ إلى العرض الكبير';
	@override String modePasserStandard({required Object prenom}) => 'نقل ⁨${prenom}⁩ إلى العرض العادي';
	@override String get demandes => 'طلب تغيير';
	@override String get demandeReaffectation => 'تغيير المعلم';
	@override String get demandeDuree => 'تغيير مدة الدروس';
	@override String get demandeMinimum => 'تغيير المدة الدنيا المدفوعة';
	@override String demandeSansEnseignant({required Object prenom}) => 'ليس لـ⁨${prenom}⁩ معلم بعد: لا شيء يُغيَّر.';
	@override String demandeTitreReaffectation({required Object prenom}) => 'تغيير معلم ⁨${prenom}⁩';
	@override String demandeTitreDuree({required Object prenom}) => 'مدة دروس ⁨${prenom}⁩';
	@override String demandeTitreMinimum({required Object prenom}) => 'المدة الدنيا المدفوعة لـ⁨${prenom}⁩';
	@override String demandeActuelle({required Object minutes}) => 'حاليًا: ⁨${minutes}⁩ دقيقة';
	@override String demandeMinutes({required Object minutes}) => '⁨${minutes}⁩ دقيقة';
	@override String get demandeMotif => 'لماذا هذا التغيير؟';
	@override String get demandeMotifRequis => 'السبب ضروري: هو الذي يسمح بالحسم.';
	@override String get demandeEnvoyer => 'إرسال الطلب';
	@override String get demandeEnvoyee => 'أُرسل الطلب. ستحسم فيه الإدارة.';
	@override String get aucunEnfant => 'لا طفل في الأسرة';
	@override String get aucunEnfantDetail => 'أضف طفلًا لتتمكن من ضبط عرضه وكاميرته.';
	@override String erreur({required Object message}) => 'لم يكتمل الحفظ: ⁨${message}⁩';
}

// Path: historique.segments
class _Traductions$historique$segments$ar extends Traductions$historique$segments$fr {
	_Traductions$historique$segments$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get seances => 'الحصص';
	@override String get observations => 'المتابعات';
}

// Path: historique.duree
class _Traductions$historique$duree$ar extends Traductions$historique$duree$fr {
	_Traductions$historique$duree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String secondes({required Object s}) => '⁨${s}⁩ ث';
	@override String minutes({required Object m}) => '⁨${m}⁩ دقيقة';
	@override String minutesSecondes({required Object m, required Object s}) => '⁨${m}⁩ د ⁨${s}⁩ ث';
	@override String heures({required Object h}) => '⁨${h}⁩ س';
	@override String heuresMinutes({required Object h, required Object m}) => '⁨${h}⁩ س ⁨${m}⁩ د';
}

// Path: historique.selecteur
class _Traductions$historique$selecteur$ar extends Traductions$historique$selecteur$fr {
	_Traductions$historique$selecteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucune => 'لا حصة';
	@override String get une => 'حصة واحدة';
	@override String plusieurs({required Object n}) => '⁨${n}⁩ حصص';
}

// Path: historique.filtres
class _Traductions$historique$filtres$ar extends Traductions$historique$filtres$fr {
	_Traductions$historique$filtres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get classe => 'الفصل';
	@override String get toutesClasses => 'كل الفصول';
	@override String get periode => 'الفترة';
	@override String get toutePeriode => 'كامل الفترة';
	@override String get septJours => 'آخر 7 أيام';
	@override String get trenteJours => 'آخر 30 يومًا';
	@override String get troisMois => 'آخر 3 أشهر';
	@override String get statut => 'الحالة';
	@override String get tousStatuts => 'كل الحالات';
}

// Path: historique.etat
class _Traductions$historique$etat$ar extends Traductions$historique$etat$fr {
	_Traductions$historique$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get presence => 'حضور';
	@override String retard({required Object minutes}) => 'تأخر ⁨${minutes}⁩ دقيقة';
	@override String get retardSansDuree => 'تأخر';
	@override String get verification => 'قيد التحقق';
	@override String get annule => 'درس ملغى';
	@override String get nonTenu => 'درس لم يُعقد';
}

// Path: historique.seances
class _Traductions$historique$seances$ar extends Traductions$historique$seances$fr {
	_Traductions$historique$seances$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get videTitre => 'لا حصة ماضية';
	@override String videPhrase({required Object prenom}) => 'ستظهر هنا الحصص الماضية لـ⁨${prenom}⁩.';
	@override String get videPhraseFoyer => 'ستظهر هنا الحصص الماضية لملفات الطلاب.';
	@override String get filtreVideTitre => 'لا حصة مطابقة';
	@override String get filtreVidePhrase => 'غيّر عوامل التصفية لتجد الحصص الأخرى.';
	@override String tronquee({required Object nombre}) => 'تُعرض أحدث ⁨${nombre}⁩ حصة.';
	@override String ouvrir({required Object date, required Object classe, required Object etat}) => 'حصة ⁨${date}⁩، ⁨${classe}⁩، ⁨${etat}⁩';
}

// Path: historique.observations
class _Traductions$historique$observations$ar extends Traductions$historique$observations$fr {
	_Traductions$historique$observations$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get indisponibleTitre => 'سجل المتابعات غير متاح';
	@override String get indisponiblePhrase => 'لا يمكن بعد قراءة الزيارات المسجَّلة في التطبيق.';
	@override String get videTitre => 'لا متابعة';
	@override String videPhrase({required Object prenom}) => 'ستظهر هنا الزيارات التي تقوم بها أثناء حصص ⁨${prenom}⁩.';
	@override String get videPhraseFoyer => 'ستظهر هنا زياراتك أثناء الحصص.';
	@override String get filtreVideTitre => 'لا متابعة مطابقة';
	@override String get filtreVidePhrase => 'غيّر عوامل التصفية لتجد الزيارات الأخرى.';
	@override String get visiteUne => 'زيارة واحدة';
	@override String visites({required Object n}) => '⁨${n}⁩ زيارات';
	@override String get dureeNonConfirmee => 'المدة غير مؤكَّدة';
	@override String get terminee => 'منتهية';
	@override String get nonRefermee => 'الخروج غير مسجَّل';
	@override String get eleveInconnu => 'طالب';
	@override String get tronquee => 'تُعرض أحدث الزيارات فقط.';
	@override String ouvrir({required Object date, required Object classe, required Object etat}) => 'متابعات ⁨${date}⁩، ⁨${classe}⁩، ⁨${etat}⁩';
}

// Path: historique.seance
class _Traductions$historique$seance$ar extends Traductions$historique$seance$fr {
	_Traductions$historique$seance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String titreSansClasse({required Object date}) => 'حصة ⁨${date}⁩';
	@override String get blocSeance => 'الحصة';
	@override String blocPresence({required Object prenom}) => 'حضور ⁨${prenom}⁩';
	@override String get date => 'التاريخ';
	@override String get horaire => 'الموعد';
	@override String get dureePrevue => 'المدة المقررة';
	@override String get classe => 'الفصل';
	@override String get enseignant => 'المعلم';
	@override String get presence => 'الحضور';
	@override String get arrivee => 'الوصول';
	@override String get interruption => 'الانقطاع';
	@override String get verificationPhrase => 'لم يُؤكَّد الحضور بعد لهذه الحصة.';
	@override String get nonTenuPhrase => 'لم تُعقد الحصة: ليس الأمر من فعل الطالب.';
	@override String get annulePhrase => 'أُلغيت الحصة.';
	@override String get introuvableTitre => 'لم يُعثر على الحصة';
	@override String get introuvablePhrase => 'هذه الحصة ليست في سجل أسرتك.';
}

// Path: historique.observation
class _Traductions$historique$observation$ar extends Traductions$historique$observation$fr {
	_Traductions$historique$observation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String titreSansClasse({required Object date}) => 'متابعات ⁨${date}⁩';
	@override String get blocResume => 'الملخص';
	@override String get blocVisites => 'الزيارات';
	@override String get observateur => 'المتابِع';
	@override String get vous => 'أنت';
	@override String get eleve => 'الطالب';
	@override String get enseignant => 'المعلم';
	@override String get dureeTotale => 'المدة الكلية';
	@override String visite({required Object n}) => 'الزيارة ⁨${n}⁩';
	@override String plageOuverte({required Object debut}) => 'الدخول الساعة ⁨${debut}⁩';
	@override String get terminee => 'انتهت الزيارة';
	@override String get introuvableTitre => 'لا زيارة لهذه الحصة';
	@override String get introuvablePhrase => 'لا زيارة مسجَّلة تطابق هذه الحصة.';
}

// Path: appareils.foyer
class _Traductions$appareils$foyer$ar extends Traductions$appareils$foyer$fr {
	_Traductions$appareils$foyer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'أجهزة الأسرة';
	@override String get phrase => 'لكل ملف طالب أجهزته. المس ملفًا لترى أجهزته، أو تزيل أحدها، أو تربط جهازًا جديدًا.';
	@override String get groupeProfils => 'ملفات الطلاب';
	@override String get aucunAppareil => 'لا جهاز مربوط';
	@override String unAppareil({required Object nom}) => 'جهاز واحد مربوط: ⁨${nom}⁩';
	@override String plusieursAppareils({required Object nombre, required Object noms}) => '⁨${nombre}⁩ أجهزة مربوطة: ⁨${noms}⁩';
	@override String get partageTitre => 'جهاز مشترك';
	@override String get partage => 'على جهاز مشترك، يختار كل طالب ملفه ثم يدخل رمزه الشخصي. يظهر هذا الجهاز حينها تحت كل ملف يستخدمه.';
	@override String get videTitre => 'لا ملف طالب';
	@override String get vide => 'أضف ملف طالب لتربط به جهازًا لوحيًا أو هاتفًا أو حاسوبًا.';
	@override String get videAction => 'إضافة ملف طالب';
}

// Path: appareils.eleve
class _Traductions$appareils$eleve$ar extends Traductions$appareils$eleve$fr {
	_Traductions$appareils$eleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String sousTitre({required Object prenom}) => 'أدر الأجهزة المسموح بها لـ⁨${prenom}⁩.';
	@override String get groupe => 'الأجهزة المربوطة';
	@override String get connecter => 'ربط جهاز';
	@override String get videTitre => 'لا جهاز مربوط';
	@override String vide({required Object prenom}) => 'اربط الجهاز اللوحي أو الهاتف أو الحاسوب الخاص بـ⁨${prenom}⁩ بالرمز الذي يعرضه الزر أدناه.';
	@override String get introuvableTitre => 'لم يُعثر على ملف الطالب';
	@override String get introuvable => 'ملف الطالب هذا غير مرتبط بأسرتك.';
	@override String get introuvableAction => 'عرض أجهزة الأسرة';
	@override String connecteLe({required Object date}) => 'رُبط في ⁨${date}⁩';
	@override String utiliseLe({required Object date}) => 'آخر استخدام: ⁨${date}⁩';
	@override String get jamaisUtilise => 'لم يُستخدم بعد';
	@override String retirerLibelle({required Object appareil}) => 'إزالة ⁨${appareil}⁩';
	@override String get horsLigne => 'إزالة جهاز أو ربطه يتطلب اتصالًا بالإنترنت.';
	@override String get partageTitre => 'اختيار الملف والرمز الشخصي';
	@override String get partage => 'على جهاز مشترك، يختار كل طالب ملفه ثم يدخل رمزه الشخصي، المحفوظ على هذا الجهاز.';
	@override String get retraitTitre => 'إزالة جهاز';
	@override String get retrait => 'الجهاز المُزال لا يستطيع إعادة الاتصال. إن كان متصلًا الآن، يبقى كذلك حتى انقطاعه التالي.';
}

// Path: appareils.plateforme
class _Traductions$appareils$plateforme$ar extends Traductions$appareils$plateforme$fr {
	_Traductions$appareils$plateforme$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get android => 'هاتف أو جهاز لوحي Android';
	@override String get ios => 'iPhone أو iPad';
	@override String get web => 'متصفح ويب';
	@override String get windows => 'حاسوب';
	@override String get inconnue => 'جهاز';
}

// Path: appareils.retrait
class _Traductions$appareils$retrait$ar extends Traductions$appareils$retrait$fr {
	_Traductions$appareils$retrait$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get question => 'إزالة هذا الجهاز؟';
	@override String consequence({required Object appareil, required Object prenom}) => 'لن يستطيع ⁨${appareil}⁩ الاتصال بملف ⁨${prenom}⁩. إن كان متصلًا الآن، يبقى كذلك حتى انقطاعه التالي.';
	@override String get confirmer => 'إزالة الجهاز';
	@override String get enCours => 'جارٍ الإزالة';
	@override String get reussi => 'أُزيل الجهاز. إن كان متصلًا الآن، يبقى كذلك حتى انقطاعه التالي.';
	@override String get echec => 'لم تكتمل الإزالة. ما زال الجهاز مسموحًا به. أعد المحاولة بعد لحظة.';
	@override String get horsLigne => 'لا اتصال بالإنترنت: لم يُزل الجهاز.';
}

// Path: appareils.emetteur
class _Traductions$appareils$emetteur$ar extends Traductions$appareils$emetteur$fr {
	_Traductions$appareils$emetteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ربط جهاز';
	@override String pourEleve({required Object prenom}) => 'لـ⁨${prenom}⁩';
	@override String get consigneTitre => 'على الجهاز الآخر';
	@override String get consigne => 'افتح Rewayah، والمس «ربط جهاز طالب»، ثم امسح رمز QR هذا أو أدخل الرمز.';
	@override String get libelleQr => 'رمز QR للربط. الرمز نفسه مكتوب أيضًا على هذه الشاشة، لإدخاله إن لم يقرأ الجهاز رمز QR.';
	@override String get codeManuel => 'الرمز للإدخال';
	@override String codeLu({required Object code}) => 'الرمز للإدخال: ⁨${code}⁩';
	@override String valableJusqua({required Object heure}) => 'صالح حتى ⁨${heure}⁩';
	@override String restant({required Object temps}) => 'بقي ⁨${temps}⁩';
	@override String sortie({required Object heure}) => 'مغادرة هذه الشاشة لا تلغي الرمز: يبقى صالحًا حتى ⁨${heure}⁩.';
	@override String get suiviIndisponible => 'لا تستطيع هذه الشاشة تأكيد الربط. تحقّق على جهاز الطالب.';
	@override String get preparation => 'جارٍ تحضير الرمز';
	@override late final _Traductions$appareils$emetteur$verification$ar verification = _Traductions$appareils$emetteur$verification$ar._(_root);
	@override late final _Traductions$appareils$emetteur$confirme$ar confirme = _Traductions$appareils$emetteur$confirme$ar._(_root);
	@override late final _Traductions$appareils$emetteur$expire$ar expire = _Traductions$appareils$emetteur$expire$ar._(_root);
	@override late final _Traductions$appareils$emetteur$remplace$ar remplace = _Traductions$appareils$emetteur$remplace$ar._(_root);
	@override late final _Traductions$appareils$emetteur$dejaActif$ar dejaActif = _Traductions$appareils$emetteur$dejaActif$ar._(_root);
	@override late final _Traductions$appareils$emetteur$horsLigne$ar horsLigne = _Traductions$appareils$emetteur$horsLigne$ar._(_root);
	@override late final _Traductions$appareils$emetteur$erreur$ar erreur = _Traductions$appareils$emetteur$erreur$ar._(_root);
}

// Path: connexion.recuperation
class _Traductions$connexion$recuperation$ar extends Traductions$connexion$recuperation$fr {
	_Traductions$connexion$recuperation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'استعادة الوصول';
	@override String get intro => 'لا كلمة مرور لإعادة تعيينها: أدخل عنوانك، ونرسل لك رابط دخول جديدًا.';
	@override String get lienExpireTitre => 'هذا الرابط لم يعد صالحًا';
	@override String get lienExpire => 'رابط الدخول يُستخدم مرة واحدة وتنتهي صلاحيته بعد مدة. اطلب رابطًا جديدًا أدناه.';
	@override String get lienRefuseTitre => 'لم يكتمل الدخول';
	@override String get lienRefuse => 'تعذّر الدخول بهذا الرابط. اطلب رابطًا جديدًا أدناه.';
	@override String get envoyer => 'استلام رابط جديد';
	@override String get envoyeTitre => 'أُرسل رابط جديد';
	@override String envoye({required Object courriel}) => 'افتح الرسالة المرسلة إلى ⁨${courriel}⁩، ثم اتبع الرابط.';
	@override String get envoyeEncart => 'قد تستغرق الرسالة بضع دقائق لتصل. تذكّر أن تنظر في البريد غير المرغوب فيه.';
	@override String get autreAdresse => 'استخدام عنوان آخر';
	@override String get revenirConnexion => 'العودة إلى تسجيل الدخول';
}

// Path: connexion.feuilleAppareil
class _Traductions$connexion$feuilleAppareil$ar extends Traductions$connexion$feuilleAppareil$fr {
	_Traductions$connexion$feuilleAppareil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get pourQui => 'مخصص لأولياء الأمور المسجلين. تمنح هذه الشاشة طالبًا من أسرتك وصوله الخاص، على جهازه اللوحي أو هاتفه، دون أن تسلّمه حسابك.';
	@override String get etapesTitre => 'أين تجد الرمز';
	@override String get etape1 => 'على جهازك، افتح «الأسرة»، ثم «أجهزة الأسرة».';
	@override String get etape2 => 'المس ملف الطالب، ثم «ربط جهاز».';
	@override String get etape3 => 'يظهر رمز QR ورمز من ستة أحرف، مع وقت انتهائهما.';
	@override String get etape4 => 'على جهاز الطالب، امسح رمز QR أو أدخل الرمز.';
	@override String get plafond => 'عدد الأجهزة لكل طالب محدود. إن بلغت الحد، أزل أحدها من «الأسرة»، «أجهزة الأسرة».';
	@override String get saisir => 'إدخال الرمز';
	@override String get fermer => 'إغلاق';
}

// Path: inscription.usage
class _Traductions$inscription$usage$ar extends Traductions$inscription$usage$fr {
	_Traductions$inscription$usage$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get question => 'أي نوع من الحسابات تريد إنشاءه؟';
	@override String get moiTitre => 'أنا فقط';
	@override String get moiDescription => 'أريد متابعة الدروس بملفي الخاص كطالب.';
	@override String get familleTitre => 'أنا وأسرتي';
	@override String get familleDescription => 'سجّل أطفالك أو أقاربك، معك أو دونك. يمكنك إنشاء ملفك الخاص كطالب في أي وقت.';
	@override String get enseignant => 'أنا معلم';
}

// Path: inscription.recap
class _Traductions$inscription$recap$ar extends Traductions$inscription$recap$fr {
	_Traductions$inscription$recap$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get usage => 'نوع الحساب';
	@override String get identite => 'الاسم';
	@override String get genre => 'الجنس';
	@override String get enseignant => 'معلم';
}

// Path: consentement.texte
class _Traductions$consentement$texte$ar extends Traductions$consentement$texte$fr {
	_Traductions$consentement$texte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'زيارات أولياء الأمور';
	@override String get quiResponsable => 'يمكن لأولياء أمور الطلاب الحاضرين متابعة الحصة لوقت قصير.';
	@override String get quiResponsableDetail => 'يسمعون المعلم والطلاب الذين يتكلمون، ومنهم طفلك. يبقى ميكروفونهم وكاميرتهم معطَّلين: لا يستطيعون الكلام ولا الكتابة ولا الظهور على الشاشة.';
	@override String get quiAdulte => 'يمكن لأولياء أمور الطلاب الآخرين الحاضرين متابعة الحصة لوقت قصير.';
	@override String get quiAdulteDetail => 'يسمعون المعلم والطلاب الذين يتكلمون، ومنهم أنت. يبقى ميكروفونهم وكاميرتهم معطَّلين: لا يستطيعون الكلام ولا الكتابة ولا الظهور على الشاشة.';
	@override String get pourquoi => 'لمتابعة التعلم دون مقاطعة الفصل.';
	@override String get pourquoiDetail => 'يأتي وليّ الأمر ليرى إن كان طفله يشارك، ثم ينصرف. تذكّر القاعة باستمرار بأن الزيارة ممكنة.';
	@override String get limites => 'زيارات قصيرة، بعدد محدود.';
	@override String get limitesDetail => 'لكل وليّ أمر عدد قليل من الزيارات في كل حصة، تحدده الأكاديمية ويُذكَّر به في «كيف يعمل ذلك؟». الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة.';
	@override String get caseResponsable => 'أوافق على هذه الشروط لطفلي';
	@override String get caseAdulte => 'أوافق على هذه الشروط';
	@override String get continuer => 'متابعة';
	@override String get retour => 'رجوع';
}

// Path: consentement.comment
class _Traductions$consentement$comment$ar extends Traductions$consentement$comment$fr {
	_Traductions$consentement$comment$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'كيف يعمل ذلك؟';
	@override String visites({required num n, required Object minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لا زيارة في الحصة.',
		one: 'زيارة واحدة مدتها ⁨${minutes}⁩ دقيقة في كل حصة.',
		two: 'زيارتان مدة كل منهما ⁨${minutes}⁩ دقيقة في كل حصة.',
		few: '⁨${n}⁩ زيارات مدة كل منها ⁨${minutes}⁩ دقيقة في كل حصة.',
		many: '⁨${n}⁩ زيارةً مدة كل منها ⁨${minutes}⁩ دقيقة في كل حصة.',
		other: '⁨${n}⁩ زيارة مدة كل منها ⁨${minutes}⁩ دقيقة في كل حصة.',
	);
	@override String visitesSansDuree({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لا زيارة في الحصة.',
		one: 'زيارة قصيرة واحدة في كل حصة.',
		two: 'زيارتان قصيرتان في كل حصة.',
		few: '⁨${n}⁩ زيارات قصيرة في كل حصة.',
		many: '⁨${n}⁩ زيارةً قصيرة في كل حصة.',
		other: '⁨${n}⁩ زيارة قصيرة في كل حصة.',
	);
	@override String get parParent => 'يسري هذا العدد على كل وليّ أمر، سواء جمعت الحصة طفلًا واحدًا من أطفاله أو أكثر.';
	@override String get ecourtee => 'الزيارة التي تُغادَر قبل نهايتها تُحتسب: لا يبقى إلا التالية، حتى الأخيرة.';
	@override String get ecouter => 'تسمع المعلم والطلاب الذين يتكلمون، ومنهم طفلك.';
	@override String get sansMicro => 'يبقى الميكروفون والكاميرا معطَّلين أثناء الزيارة.';
	@override String get valeursIndisponibles => 'يظهر عدد الزيارات ومدتها من فصل طفلك، حسب قواعد فصله.';
	@override String get fermee => 'زيارات المتابعة غير مفتوحة لهذا الفصل.';
}

// Path: consentement.compte
class _Traductions$consentement$compte$ar extends Traductions$consentement$compte$fr {
	_Traductions$consentement$compte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'أضافت الأكاديمية إلى شروطها فقرة عن زيارات أولياء الأمور. لا يُعدّ شيء مقبولًا ما لم تقبله أنت.';
	@override String accepteLe({required Object date}) => 'قبلت هذه الشروط في ⁨${date}⁩.';
	@override String get merci => 'شكرًا، حُفظت موافقتك.';
	@override String get chargement => 'جارٍ قراءة موافقاتك';
	@override String get erreur => 'موافقاتك لا تظهر الآن.';
	@override String get horsLigne => 'أنت غير متصل. ستظهر موافقاتك بمجرد عودة الشبكة.';
	@override String get sansProfil => 'لا حساب متصل: سجّل الدخول من جديد لقراءة موافقاتك.';
	@override String get invite => 'نسخة جديدة للقراءة: زيارات أولياء الأمور';
	@override String get inviteAction => 'قراءة';
}

// Path: foyer.vide
class _Traductions$foyer$vide$ar extends Traductions$foyer$vide$fr {
	_Traductions$foyer$vide$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'لا ملف طالب حتى الآن';
	@override String get phrase => 'أضف ملف طالب لتسجيله في فصل وربط جهازه.';
}

// Path: foyer.membre
class _Traductions$foyer$membre$ar extends Traductions$foyer$membre$fr {
	_Traductions$foyer$membre$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sansClasse => 'لا فصل بعد';
	@override String get classeEchec => 'تعذّرت قراءة الفصل';
	@override String get accesSansEcheance => 'وصول دون موعد انتهاء';
	@override String accesJusquau({required Object date}) => 'وصول حتى ⁨${date}⁩';
	@override String accesExpire({required Object date}) => 'انتهى الوصول منذ ⁨${date}⁩';
	@override String date({required Object jour, required Object mois, required Object annee}) => '⁨${jour}⁩ ⁨${mois}⁩ ⁨${annee}⁩';
}

// Path: foyer.monProfil
class _Traductions$foyer$monProfil$ar extends Traductions$foyer$monProfil$fr {
	_Traductions$foyer$monProfil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'إنشاء ملفي كطالب';
	@override String get indisponibleTitre => 'غير ممكن بعد';
	@override String get indisponiblePhrase => 'متابعة الدروس بنفسك بملفك الخاص كطالب ستُقترح قريبًا. يبقى حسابك كوليّ أمر كما هو.';
	@override String get retour => 'العودة إلى الأسرة';
}

// Path: foyer.ajout
class _Traductions$foyer$ajout$ar extends Traductions$foyer$ajout$fr {
	_Traductions$foyer$ajout$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get suivant => 'التالي';
	@override String get creer => 'إنشاء الملف';
	@override late final _Traductions$foyer$ajout$porte$ar porte = _Traductions$foyer$ajout$porte$ar._(_root);
	@override late final _Traductions$foyer$ajout$pourQui$ar pourQui = _Traductions$foyer$ajout$pourQui$ar._(_root);
	@override late final _Traductions$foyer$ajout$identite$ar identite = _Traductions$foyer$ajout$identite$ar._(_root);
	@override late final _Traductions$foyer$ajout$erreurs$ar erreurs = _Traductions$foyer$ajout$erreurs$ar._(_root);
	@override late final _Traductions$foyer$ajout$refus$ar refus = _Traductions$foyer$ajout$refus$ar._(_root);
	@override late final _Traductions$foyer$ajout$incertaine$ar incertaine = _Traductions$foyer$ajout$incertaine$ar._(_root);
	@override String get horsLigne => 'أنت غير متصل. يمكن إنشاء الملف عند عودة الاتصال.';
}

// Path: adulte.nav
class _Traductions$adulte$nav$ar extends Traductions$adulte$nav$fr {
	_Traductions$adulte$nav$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'الرئيسية';
	@override String get maClasse => 'فصلي';
	@override String get coran => 'القرآن';
	@override String get monEspace => 'مساحتي';
}

// Path: adulte.accueil
class _Traductions$adulte$accueil$ar extends Traductions$adulte$accueil$fr {
	_Traductions$adulte$accueil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String salutation({required Object prenom}) => 'مرحبًا ⁨${prenom}⁩';
	@override String get prochaineSeance => 'الحصة القادمة';
	@override String get parcours => 'مساري';
	@override String get dernieresSeances => 'آخر الحصص';
	@override String get ressources => 'موارد الفصل';
	@override String get absence => 'الغياب';
	@override String get aucuneClasse => 'لا فصل حتى الآن.';
	@override String get aucuneClasseDetail => 'ستظهر حصتك القادمة هنا بمجرد فتح فصلك.';
	@override String get echec => 'تعذّر تحميل حصتك القادمة وآخر حصصك: لم يستجب الخادم. أعد المحاولة بعد لحظة.';
}

// Path: adulte.historique
class _Traductions$adulte$historique$ar extends Traductions$adulte$historique$fr {
	_Traductions$adulte$historique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'حصصي الماضية';
	@override String get echec => 'تعذّر تحميل حصصك الماضية: لم يستجب الخادم. أعد المحاولة بعد لحظة.';
	@override String get vide => 'لا حصة ماضية حتى الآن.';
	@override String get videDetail => 'ستظهر حصصك هنا بعد درسك الأول.';
}

// Path: adulte.maClasse
class _Traductions$adulte$maClasse$ar extends Traductions$adulte$maClasse$fr {
	_Traductions$adulte$maClasse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aPropos => 'عن هذا الفصل';
	@override String get participants => 'المشاركون';
	@override String vous({required Object prenom}) => '⁨${prenom}⁩ (أنت)';
	@override String get progression => 'تقدمي في هذا الفصل';
	@override String get aucuneClasseDetail => 'سيظهر فصلك ومشاركوه وموارده هنا بمجرد فتحه.';
}

// Path: adulte.monEspace
class _Traductions$adulte$monEspace$ar extends Traductions$adulte$monEspace$fr {
	_Traductions$adulte$monEspace$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get role => 'طالب بالغ';
	@override String get monCompte => 'حسابي';
	@override String get informations => 'معلوماتي';
	@override String get coursAcces => 'الدروس والوصول';
	@override String get coursAccesLegende => 'الفصل والحصص والوصول';
	@override String get paiements => 'المدفوعات';
	@override String get paiementsLegende => 'السجل والإيصالات';
	@override String get accords => 'موافقاتي';
	@override String get accordsLegende => 'الموافقات الممنوحة للأكاديمية';
	@override String get securiteLegende => 'طريقة الدخول وعنوانه';
	@override late final _Traductions$adulte$monEspace$pageAccords$ar pageAccords = _Traductions$adulte$monEspace$pageAccords$ar._(_root);
	@override late final _Traductions$adulte$monEspace$pageCoursAcces$ar pageCoursAcces = _Traductions$adulte$monEspace$pageCoursAcces$ar._(_root);
}

// Path: adulte.coranDemo
class _Traductions$adulte$coranDemo$ar extends Traductions$adulte$coranDemo$fr {
	_Traductions$adulte$coranDemo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'متاح بعد تسجيل الدخول';
	@override String get phrase => 'ليس هذا عطلًا: العرض التجريبي لا يحتوي على نص القرآن. بعد الدخول إلى مساحتك كطالب، يُفتح هنا.';
}

// Path: adulte.recharge
class _Traductions$adulte$recharge$ar extends Traductions$adulte$recharge$fr {
	_Traductions$adulte$recharge$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'شحن جديد';
	@override String get phrase => 'اختر مستفيدًا أو أكثر، ثم اختر عرضًا لكل واحد.';
	@override String get toutSelectionner => 'تحديد الكل';
	@override String get toutDeselectionner => 'إلغاء تحديد الكل';
	@override String offrePour({required Object prenom}) => 'عرض لـ⁨${prenom}⁩';
	@override String get verifier => 'مراجعة الشحن';
	@override String get raisonAucun => 'اختر مستفيدًا واحدًا على الأقل للمتابعة.';
	@override String get raisonOffre => 'اختر عرضًا لكل مستفيد محدد.';
	@override String get horsLigneVerifier => 'أنت غير متصل. يمكنك مراجعة الشحن عند عودة الاتصال.';
	@override String get indisponibleTitre => 'الشحن غير متاح بعد';
	@override String get indisponiblePhrase => 'عروض الشحن غير متاحة في التطبيق بعد. لا دفع ممكن هنا الآن.';
	@override String get verificationEchecTitre => 'لم تكتمل المراجعة.';
	@override String get verificationEchecPhrase => 'اختياراتك محفوظة. يمكنك إعادة المحاولة.';
	@override String get verifierTitre => 'مراجعة الشحن';
	@override String get verifierPhrase => 'راجع التفاصيل قبل الدفع.';
	@override String get recapitulatif => 'الملخص حسب المستفيد';
	@override String get montantPaye => 'المبلغ المدفوع';
	@override String get soldeAttribue => 'الرصيد المخصص';
	@override String get statut => 'حالة التخصيص';
	@override String get modifier => 'تعديل';
	@override String get total => 'المجموع المستحق';
	@override String payer({required Object montant}) => 'دفع ⁨${montant}⁩';
	@override String get horsLignePayer => 'أنت غير متصل. يمكنك الدفع عند عودة الاتصال.';
	@override String get paiementEchecTitre => 'لم يُؤكَّد الدفع.';
	@override String get paiementEchecPhrase => 'تحقّق قبل إعادة المحاولة.';
	@override String get paiementIndisponibleTitre => 'الدفع غير متاح بعد';
	@override String get paiementIndisponiblePhrase => 'لم يُجرَ أي دفع. الدفع عبر الإنترنت غير مفتوح في التطبيق بعد.';
	@override String get revenirPaiements => 'العودة إلى مدفوعات الأسرة';
}

// Path: adulte.paiements
class _Traductions$adulte$paiements$ar extends Traductions$adulte$paiements$fr {
	_Traductions$adulte$paiements$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get beneficiaires => 'المستفيدون';
	@override String get recharger => 'شحن';
	@override String recapitulatif({required Object valeur}) => 'ملخص الأسرة: ⁨${valeur}⁩. يبقى كل رصيد خاصًا بمستفيده.';
	@override String get bientotEpuise => 'على وشك النفاد';
	@override String get inactif => 'غير نشط';
	@override String get historique => 'سجل المدفوعات';
	@override String get soldesIndisponiblesTitre => 'الأرصدة غير قابلة للاطلاع بعد';
	@override String get soldesIndisponiblesPhrase => 'رصيد كل مستفيد غير متاح في التطبيق بعد. لا شحن ممكن هنا الآن.';
	@override String get aucunBeneficiaireTitre => 'لا مستفيد';
	@override String get aucunBeneficiairePhrase => 'لا ملف طالب في أسرتك له رصيد للشحن الآن.';
}

// Path: adulte.famille
class _Traductions$adulte$famille$ar extends Traductions$adulte$famille$fr {
	_Traductions$adulte$famille$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ajouter => 'إضافة أسرتي';
	@override String get ajouterLegende => 'سجّل أطفالك وادعُ زوجك أو زوجتك للانضمام إلى باقة الأسرة.';
	@override String get ajouterPhrase => 'يمكنك إضافة أطفالك ودعوة زوجك أو زوجتك للانضمام إلى باقة الأسرة. تبقى مساحتك كطالب كما هي.';
	@override String get inscrireEnfant => 'تسجيل طفل';
	@override String get maFamille => 'أسرتي';
	@override String get forfaitFamille => 'باقة الأسرة';
	@override String get retourMonEspace => 'العودة إلى مساحتي';
	@override String get titulaire => 'أنت صاحب حساب الأسرة';
	@override String get paiementsFoyer => 'مدفوعات الأسرة';
	@override String get aProposForfait => 'عن باقة الأسرة';
	@override String get aProposForfaitPhrase => 'تضم باقة الأسرة صاحب الحساب، وزوجًا أو زوجة بالغًا، والأطفال أو المراهقين الذين في رعاية صاحب الحساب. يحتفظ كل بالغ بحسابه الخاص.';
	@override String get profilNonCreeTitre => 'عرض تجريبي: لم يُنشأ أي ملف';
	@override String get profilNonCreePhrase => 'في العرض التجريبي، لا يُرسل شيء. تبقى «أسرتي» كما كانت.';
	@override String get profilNonCreePhraseSeul => 'في العرض التجريبي، لا يُرسل شيء. تبقى مساحتك كطالب كما كانت.';
	@override String get monProfilIndisponibleTitre => 'غير متاح بعد';
	@override String get monProfilIndisponiblePhrase => 'إنشاء ملف طالب منفصل غير متاح بعد. تبقى دروسك و«أسرتي» كما هي.';
	@override String get indisponibleTitre => 'قسم الأسرة غير متاح بعد';
	@override String get indisponiblePhrase => 'ستظهر أسرتك أو باقة أسرتك هنا بمجرد إتاحتها.';
	@override late final _Traductions$adulte$famille$place$ar place = _Traductions$adulte$famille$place$ar._(_root);
}

// Path: adulte.invitation
class _Traductions$adulte$invitation$ar extends Traductions$adulte$invitation$fr {
	_Traductions$adulte$invitation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titreElle => 'دعوة زوجتي';
	@override String get titreLui => 'دعوة زوجي';
	@override String get enteteElle => 'حساب شخصي لها';
	@override String get enteteLui => 'حساب شخصي له';
	@override String get phraseElle => 'ستستخدم زوجتك حسابها الخاص. لن تستطيع إدارة أسرتك ولا ملفات الطلاب التي أنشأتها.';
	@override String get phraseLui => 'سيستخدم زوجك حسابه الخاص. لن يستطيع إدارة أسرتك ولا ملفات الطلاب التي أنشأتها.';
	@override String get prenom => 'الاسم';
	@override String get nom => 'اللقب';
	@override String get nomAide => 'اختياري.';
	@override String get courriel => 'البريد الإلكتروني';
	@override String get courrielAideElle => 'سيُستخدم البريد الإلكتروني لإرسال دعوة الانضمام إلى Rewayah إلى زوجتك.';
	@override String get courrielAideLui => 'سيُستخدم البريد الإلكتروني لإرسال دعوة الانضمام إلى Rewayah إلى زوجك.';
	@override String get prenomRequis => 'أدخل الاسم.';
	@override String get courrielRequis => 'أدخل البريد الإلكتروني.';
	@override String get courrielInvalide => 'تحقّق من البريد الإلكتروني: يجب أن يشبه ⁦name@example.com⁩.';
	@override String get verifier => 'متابعة';
	@override String get verifierTitre => 'المراجعة والإرسال';
	@override String get verifierPhrase => 'أعد قراءة هذه المعلومات. ستُرسل الدعوة إلى هذا العنوان.';
	@override String get nonRenseigne => 'غير محدد';
	@override String get modifier => 'تعديل';
	@override String get envoyer => 'إرسال الدعوة';
	@override String get horsLigne => 'أنت غير متصل. لم يُرسل شيء. يمكنك إرسال الدعوة بنفسك عند عودة الاتصال.';
	@override String get echecTitre => 'لم يُؤكَّد الإرسال.';
	@override String get echecPhrase => 'تحقّق قبل إعادة المحاولة. معلوماتك محفوظة.';
	@override String get refusTitre => 'لا يمكن إرسال هذه الدعوة';
	@override String get refusPhrase => 'تعرض «أسرتي» الحالة الحالية للمقعد.';
	@override String get envoyeeTitre => 'أُرسلت الدعوة';
	@override String envoyeePhrase({required Object courriel}) => 'أُرسلت الدعوة إلى ⁨${courriel}⁩.';
	@override String get revenirMaFamille => 'العودة إلى أسرتي';
	@override String get detailPhrase => 'الدعوة بانتظار الرد. يمكنك إلغاؤها ما لم تُقبل.';
	@override String get annuler => 'إلغاء الدعوة';
	@override String annulerQuestion({required Object prenom}) => 'إلغاء دعوة ⁨${prenom}⁩؟';
	@override String get annulerQuestionSansPrenom => 'إلغاء هذه الدعوة؟';
	@override String get annulerHorsLigne => 'أنت غير متصل. لم يُلغَ شيء. يمكنك إلغاء الدعوة بنفسك عند عودة الاتصال.';
	@override String get annulerConsequence => 'لن يعود ممكنًا قبول الدعوة. يمكنك إرسال دعوة جديدة متى شئت.';
	@override String get garder => 'الإبقاء على الدعوة';
	@override String get annulationEchecTitre => 'لم يُؤكَّد الإلغاء.';
	@override String get annulationEchecPhrase => 'تحقّق قبل إعادة المحاولة.';
}

// Path: adulte.acceptation
class _Traductions$adulte$acceptation$ar extends Traductions$adulte$acceptation$fr {
	_Traductions$adulte$acceptation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String notification({required Object prenom}) => 'يدعوك ⁨${prenom}⁩ للانضمام إلى باقة أسرته.';
	@override String titre({required Object prenom}) => 'الانضمام إلى باقة أسرة ⁨${prenom}⁩';
	@override String get faisonsTitre => 'ما نفعله';
	@override String faisons({required Object prenom}) => 'يدعوك ⁨${prenom}⁩ إلى باقة أسرته. إن قبلت، يُربط حسابك بأسرته. يبقى حسابك ملكك. لا يُدمج شيء.';
	@override String get pourquoiTitre => 'لماذا';
	@override String pourquoiElle({required Object prenom}) => 'تدير ⁨${prenom}⁩ الأسرة وتدفع عن أفرادها. لتدفع عن دروسك، يجب أن ترى رصيدك.';
	@override String pourquoiLui({required Object prenom}) => 'يدير ⁨${prenom}⁩ الأسرة ويدفع عن أفرادها. ليدفع عن دروسك، يجب أن يرى رصيدك.';
	@override String verraTitre({required Object prenom}) => 'ما سيراه ⁨${prenom}⁩';
	@override String get verraElle => 'اسمك ولقبك. رصيدك، أو الحاجة إلى شحنه. العرض الذي يخصك. حالة وصولك، إن كانت تمنع الدفع. وستعرف أيضًا إن غادرت باقة الأسرة.';
	@override String get verraLui => 'اسمك ولقبك. رصيدك، أو الحاجة إلى شحنه. العرض الذي يخصك. حالة وصولك، إن كانت تمنع الدفع. وسيعرف أيضًا إن غادرت باقة الأسرة.';
	@override String verraPasTitre({required Object prenom}) => 'ما لن يراه ⁨${prenom}⁩';
	@override String get verraPas => 'فصلك. مستواك. حصصك وحضورك. تقدمك. رسائلك. إشعاراتك. وسائل دفعك الشخصية. وثائق هويتك.';
	@override String get vousTitre => 'ما لن تراه أنت';
	@override String vous({required Object prenom}) => 'دروس ⁨${prenom}⁩ وتقدمه ورسائله، وكذلك أطفال الأسرة. لن تستطيع إضافة طفل، ولا دعوة أحد، ولا تعديل الأسرة.';
	@override String get autresTitre => 'من يرى أيضًا';
	@override String get autres => 'معلمك لا يرى شيئًا من أسرتك. يرى فريق الأكاديمية الربط، لإدارته واعتماده عند الحاجة.';
	@override String get dureeTitre => 'إلى متى';
	@override String duree({required Object prenom}) => 'يستمر الربط حتى تغادر باقة الأسرة، أو ينهيه ⁨${prenom}⁩.';
	@override String conservation({required Object duree}) => 'نحتفظ بأثر الربط ⁨${duree}⁩.';
	@override String get partirTitre => 'كيف تغادر';
	@override String get partir => 'في «مساحتي»، «باقة الأسرة»، «مغادرة باقة الأسرة». لا تحتاج إلى موافقته. يبقى حسابك ودروسك وسجلك ورصيدك متاحة.';
	@override String get refusTitre => 'إن رفضت';
	@override String get refus => 'لا يتغير شيء في حسابك ولا دروسك ولا رصيدك.';
	@override String get validation => 'يجب أن تعتمد إدارة الأكاديمية هذا الربط. وإلى ذلك الحين، يعمل حسابك ودروسك بشكل عادي.';
	@override String get refuser => 'رفض الدعوة';
	@override String get accepter => 'قبول الدعوة';
	@override String get horsLigne => 'أنت غير متصل. لم يُرسل شيء. يمكنك الرد بنفسك عند عودة الاتصال.';
	@override String get acceptationEchecTitre => 'لم يُؤكَّد القبول.';
	@override String get refusEchecTitre => 'لم يُؤكَّد الرفض.';
	@override String get echecPhrase => 'تحقّق قبل إعادة المحاولة.';
	@override String get accepteeTitre => 'قُبلت الدعوة';
	@override String rejoint({required Object prenom}) => 'انضممت إلى باقة أسرة ⁨${prenom}⁩.';
	@override String get refuseeTitre => 'رُفضت الدعوة';
	@override String get impossible => 'لا يمكن لهذا الحساب الانضمام إلى هذه الباقة حاليًا.';
	@override String get perimee => 'هذه الدعوة لم تعد صالحة.';
	@override String get monEspace => 'الذهاب إلى مساحتي';
	@override String recu({required Object date}) => 'سُجِّل الرد في ⁨${date}⁩.';
	@override String get titreNeutre => 'دعوة إلى باقة الأسرة';
	@override String get sansCompteTitre => 'دعوة إلى باقة الأسرة';
	@override String get sansCompte => 'للرد، سجّل الدخول إلى حسابك، أو أنشئ حسابًا. ستقرأ حينها ما سيراه الشخص الذي يدعوك وما لن يراه قبل أن تقرر.';
	@override String get sansCompteAction => 'تسجيل الدخول أو إنشاء حسابي';
}

// Path: adulte.sortie
class _Traductions$adulte$sortie$ar extends Traductions$adulte$sortie$fr {
	_Traductions$adulte$sortie$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get retirerElle => 'إزالة زوجتي';
	@override String get retirerLui => 'إزالة زوجي';
	@override String get retirerQuestionElle => 'إزالة زوجتي؟';
	@override String get retirerQuestionLui => 'إزالة زوجي؟';
	@override String get retirerConsequence => 'لن يُحذف حسابه ولا دروسه ولا سجله ولا رصيده.';
	@override String placePhrase({required Object prenom}) => '⁨${prenom}⁩ جزء من باقة أسرتك، بحسابه الخاص.';
	@override String get quitter => 'مغادرة باقة الأسرة';
	@override String get quitterQuestion => 'مغادرة باقة الأسرة؟';
	@override String get quitterConfirmer => 'مغادرة الباقة';
	@override String get quitterConsequence => 'يبقى حسابك ودروسك وسجلك ورصيدك متاحة. ينتهي الربط بباقة الأسرة.';
	@override String forfaitPhrase({required Object prenom}) => 'أنت جزء من باقة أسرة ⁨${prenom}⁩.';
	@override String get resultatTitre => 'انتهى الربط بباقة الأسرة';
	@override String get resultatTitulaire => 'يبقى حسابه ودروسه وسجله ورصيده متاحة.';
	@override String get resultatSecondAdulte => 'يبقى حسابك ودروسك وسجلك ورصيدك متاحة.';
	@override String get compris => 'فهمت';
	@override String get retraitEchecTitre => 'لم تُؤكَّد الإزالة.';
	@override String get departEchecTitre => 'لم تُؤكَّد المغادرة.';
	@override String get echecPhrase => 'تحقّق قبل إعادة المحاولة.';
	@override String get horsLigne => 'أنت غير متصل. لم يُرسل شيء. يمكنك إعادة المحاولة بنفسك عند عودة الاتصال.';
	@override String notificationQuitte({required Object prenom}) => 'غادر ⁨${prenom}⁩ باقة أسرتك.';
	@override String notificationRetiree({required Object prenom}) => 'أُزلتِ من باقة أسرة ⁨${prenom}⁩.';
	@override String notificationRetire({required Object prenom}) => 'أُزلتَ من باقة أسرة ⁨${prenom}⁩.';
	@override String get delaiTitre => 'دعوة جديدة غير متاحة';
	@override String delaiPhrase({required Object date}) => 'يمكن تقديم طلب جديد ابتداءً من ⁨${date}⁩. ثم يجب أن تعتمده الإدارة.';
	@override String get pourquoi => 'لماذا هذا الانتظار؟';
	@override String get pourquoiPhrase => 'يضمن هذا الإجراء أمان الأسر وحسن إدارة وصول الأطفال.';
}

// Path: adulte.reprise
class _Traductions$adulte$reprise$ar extends Traductions$adulte$reprise$fr {
	_Traductions$adulte$reprise$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'طلب استلام الأسرة';
	@override String get explication => 'استخدم هذا الإجراء إن توفي صاحب حساب الأسرة. سيُبلَّغ الحساب المعني بالطلب وستدرسه الإدارة.';
	@override String get reprisTitre => 'ما سيُستلم';
	@override late final _Traductions$adulte$reprise$repris$ar repris = _Traductions$adulte$reprise$repris$ar._(_root);
	@override String get jamaisTitre => 'ما لا يُستلم أبدًا';
	@override late final _Traductions$adulte$reprise$jamais$ar jamais = _Traductions$adulte$reprise$jamais$ar._(_root);
	@override String get succession => 'الأمر انتقال لصفة صاحب حساب الأسرة، لا استيلاء على الحساب الشخصي.';
	@override String get deposer => 'تقديم الطلب';
	@override String get deposerQuestion => 'تقديم هذا الطلب؟';
	@override String get deposerConsequence => 'سيُبلَّغ صاحب حساب الأسرة ويمكنه رفضه. ثم تدرس الإدارة الطلب وتقرر.';
	@override String get horsLigne => 'أنت غير متصل. لم يُرسل شيء. يمكنك تقديم الطلب بنفسك عند عودة الاتصال.';
	@override String get depotEchecTitre => 'لم يُؤكَّد الطلب.';
	@override String get echecPhrase => 'تحقّق قبل إعادة المحاولة.';
	@override String get motif => 'السبب';
	@override String get motifDeces => 'وفاة صاحب الحساب المصرَّح بها';
	@override String get deposeeLe => 'قُدِّم في';
	@override String get etat => 'الحالة';
	@override late final _Traductions$adulte$reprise$etats$ar etats = _Traductions$adulte$reprise$etats$ar._(_root);
	@override late final _Traductions$adulte$reprise$phrases$ar phrases = _Traductions$adulte$reprise$phrases$ar._(_root);
	@override late final _Traductions$adulte$reprise$titulaire$ar titulaire = _Traductions$adulte$reprise$titulaire$ar._(_root);
	@override late final _Traductions$adulte$reprise$notifications$ar notifications = _Traductions$adulte$reprise$notifications$ar._(_root);
}

// Path: adulte.demo
class _Traductions$adulte$demo$ar extends Traductions$adulte$demo$fr {
	_Traductions$adulte$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'عرض تجريبي للطالب البالغ';
	@override String get mention => 'البيانات وهمية ولا يُرسل شيء.';
	@override String get intro => 'اختر شاشة، ثم حالة من حالات أسرة ديالو.';
	@override String get ecrans => 'الشاشات';
	@override String get situations => 'حالات الأسرة';
	@override String get variantes => 'المتغيرات';
	@override String get titulaireFemme => 'صاحبة الحساب امرأة، وزوجها هو البالغ الثاني.';
	@override String get vueConjointe => '«مساحتي» كما تراها الزوجة، البالغة الثانية في الأسرة.';
	@override String get vueConjoint => '«مساحتي» كما يراها الزوج، البالغ الثاني في الأسرة.';
	@override String get invitationRecueConjointe => 'الدعوة كما تستلمها الزوجة، في حسابها الخاص.';
	@override String get invitationRecueConjoint => 'الدعوة كما يستلمها الزوج، في حسابه الخاص.';
	@override String get invitationSansCompte => 'الدعوة مفتوحة دون حساب.';
	@override String get reseauCoupe => 'الشبكة مقطوعة: الرئيسية و«فصلي» دون اتصال.';
	@override late final _Traductions$adulte$demo$donnees$ar donnees = _Traductions$adulte$demo$donnees$ar._(_root);
	@override late final _Traductions$adulte$demo$etats$ar etats = _Traductions$adulte$demo$etats$ar._(_root);
}

// Path: dossiers.file
class _Traductions$dossiers$file$ar extends Traductions$dossiers$file$fr {
	_Traductions$dossiers$file$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get chargement => 'جارٍ تحميل الملفات…';
	@override String get erreur => 'تعذّر تحميل الملفات.';
	@override String get horsLigne => 'أنت غير متصل. لا يمكن تحديث الملفات.';
	@override String get accesRefuse => 'ليس لديك إذن بالوصول إلى الملفات المطلوب اعتمادها.';
	@override String get actualisation => 'جارٍ تحديث الملفات…';
	@override String get chargementProlonge => 'التحميل يستغرق وقتًا أطول من المتوقع.';
	@override String get suivantsErreur => 'تعذّر تحميل الملفات التالية.';
	@override String get indisponible => 'الاطلاع على الملفات غير متاح الآن.';
	@override String get selectionRetiree => 'هذا الملف لم يعد متاحًا في القائمة.';
	@override String get actualiser => 'تحديث الملفات';
	@override String get aucuneSelection => 'اختر ملفًا لدراسته.';
	@override String get suivants => 'تحميل الملفات التالية';
	@override String ouvrirDe({required Object nom}) => 'فتح ملف ⁨${nom}⁩';
	@override String ouvrirElide({required Object nom}) => 'فتح ملف ⁨${nom}⁩';
	@override String get enVerification => 'قيد التحقق';
	@override String get sansNom => 'ملف دون اسم متاح';
	@override String legende({required Object type, required Object date}) => '⁨${type}⁩ · ⁨${date}⁩';
	@override String dateHeure({required Object date, required Object heure, required Object zone}) => '⁨${date}⁩ الساعة ⁨${heure}⁩ (⁨${zone}⁩)';
	@override String dateChiffres({required Object jour, required Object mois, required Object annee}) => '⁨${jour}⁩/⁨${mois}⁩/⁨${annee}⁩';
	@override String heureChiffres({required Object heures, required Object minutes}) => '⁨${heures}⁩:⁨${minutes}⁩';
	@override String get zoneUtc => 'UTC';
	@override String suivantAnnonce({required Object nom}) => 'الملف التالي: ⁨${nom}⁩';
}

// Path: dossiers.detail
class _Traductions$dossiers$detail$ar extends Traductions$dossiers$detail$fr {
	_Traductions$dossiers$detail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String titreDe({required Object nom}) => 'ملف ⁨${nom}⁩';
	@override String titreElide({required Object nom}) => 'ملف ⁨${nom}⁩';
}

// Path: dossiers.visionneuse
class _Traductions$dossiers$visionneuse$ar extends Traductions$dossiers$visionneuse$fr {
	_Traductions$dossiers$visionneuse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get chargement => 'جارٍ تحميل الوثيقة…';
	@override String get erreur => 'لا يمكن عرض الوثيقة.';
	@override String get expire => 'انتهى الوصول إلى هذه الوثيقة.';
	@override String get recharger => 'إعادة تحميل الوثيقة';
	@override String get formatNonPrisEnCharge => 'لا يمكن عرض تنسيق هذه الوثيقة.';
	@override String get accesRetire => 'لم يعد لديك وصول إلى هذه الوثيقة.';
	@override String get horsLigne => 'أنت غير متصل. لا يمكن تحميل الوثيقة.';
	@override String get aucune => 'لا وثيقة متاحة.';
	@override String get fermerPiece => 'إغلاق الوثيقة';
	@override String get agrandir => 'تكبير';
	@override String get reduire => 'تصغير';
	@override String get ajuster => 'ملاءمة الشاشة';
	@override String infoBulle({required Object action, required Object touche}) => '⁨${action}⁩ (المفتاح ⁨${touche}⁩)';
	@override String get documentFictif => 'وثيقة وهمية';
}

// Path: dossiers.revue
class _Traductions$dossiers$revue$ar extends Traductions$dossiers$revue$fr {
	_Traductions$dossiers$revue$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get identite => 'الهوية والملف';
	@override String get pieceNonTransmise => 'لم تُرسل الوثيقة المطلوبة.';
	@override String get piece => 'وثيقة الهوية';
	@override String get voirPiece => 'عرض الوثيقة';
	@override String get accords => 'الموافقات والعناصر المقدَّمة';
	@override String get nom => 'اللقب';
	@override String get prenom => 'الاسم';
	@override String get typeDossier => 'نوع الملف';
	@override String get dateDepot => 'تاريخ الإيداع';
	@override String get etatDossier => 'حالة الملف';
	@override String get dateIndisponible => 'تاريخ الإيداع غير متاح';
	@override String get pasPret => 'هذا الملف ليس جاهزًا للاعتماد بعد.';
	@override String get erreurChargement => 'تعذّر تحميل هذا الملف.';
	@override String get pieceIndisponible => 'الاطلاع على الوثيقة غير متاح الآن.';
	@override late final _Traductions$dossiers$revue$etats$ar etats = _Traductions$dossiers$revue$etats$ar._(_root);
}

// Path: dossiers.profilACompleter
class _Traductions$dossiers$profilACompleter$ar extends Traductions$dossiers$profilACompleter$fr {
	_Traductions$dossiers$profilACompleter$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الملف الشخصي للإكمال';
	@override String get texte => 'يجب إكمال ملفك الشخصي قبل الاطلاع على الملفات التي تسمح بها هذه القاعدة.';
}

// Path: dossiers.refus
class _Traductions$dossiers$refus$ar extends Traductions$dossiers$refus$fr {
	_Traductions$dossiers$refus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'رفض الملف';
	@override String nomType({required Object nom, required Object type}) => '⁨${nom}⁩ · ⁨${type}⁩';
	@override String get corps => 'حدّد السبب الذي سيُعرض على الشخص المعني.';
	@override String get champ => 'سبب الرفض';
	@override String get aide => 'اشرح ما يجب تصحيحه، دون بيانات داخلية ولا تعليق شخصي.';
	@override String get erreurVide => 'حدّد سبب الرفض.';
	@override String get tropLong => 'السبب يتجاوز الطول المسموح.';
	@override String get envoi => 'جارٍ الرفض…';
	@override String get erreur => 'تعذّر رفض الملف.';
	@override String get horsLigne => 'أنت غير متصل. لم يُرسل الرفض.';
	@override String get inconnu => 'نتيجة الرفض غير مؤكَّدة بعد.';
	@override String get interdit => 'لم يعد بإمكانك رفض هذا الملف.';
	@override String get indisponible => 'الرفض غير متاح الآن.';
	@override String get succes => 'رُفض الملف.';
	@override String get abandonQuestion => 'التخلي عن السبب المكتوب؟';
	@override String get continuerSaisie => 'متابعة الكتابة';
	@override String get abandonner => 'تخلٍّ';
}

// Path: dossiers.validation
class _Traductions$dossiers$validation$ar extends Traductions$dossiers$validation$fr {
	_Traductions$dossiers$validation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'اعتماد هذا الملف؟';
	@override String corpsActivation({required Object nom}) => 'سيُعتمد ملف ⁨${nom}⁩. سيتمكن حسابه من الوصول إلى مساحته.';
	@override String corpsDocumentaire({required Object nom}) => 'سيُعتمد ملف ⁨${nom}⁩. تبقى شروط الوصول الأخرى سارية.';
	@override String get indisponible => 'الاعتماد غير متاح الآن.';
	@override String get envoi => 'جارٍ الاعتماد…';
	@override String get erreur => 'تعذّر اعتماد الملف.';
	@override String get horsLigne => 'أنت غير متصل. لم يُرسل الاعتماد.';
	@override String get inconnu => 'نتيجة الاعتماد غير مؤكَّدة بعد.';
	@override String get plusPret => 'هذا الملف لم يعد جاهزًا للاعتماد.';
	@override String get interdit => 'لم يعد بإمكانك اعتماد هذا الملف.';
	@override String get succes => 'اعتُمد الملف.';
}

// Path: dossiers.decision
class _Traductions$dossiers$decision$ar extends Traductions$dossiers$decision$fr {
	_Traductions$dossiers$decision$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get verifierResultat => 'التحقق من النتيجة';
	@override String get dejaTraite => 'عولج هذا الملف من قبل.';
	@override String get conflit => 'عالج هذا الملف عضو آخر في الفريق.';
	@override String nomComplet({required Object prenom, required Object nom}) => '⁨${prenom}⁩ ⁨${nom}⁩';
}

// Path: controleur.historique
class _Traductions$controleur$historique$ar extends Traductions$controleur$historique$fr {
	_Traductions$controleur$historique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'السجل';
	@override String get provisoire => 'هذه الشاشة قيد التحضير.';
	@override String get envoye => 'أُرسل';
	@override String get complementAjoute => 'أُضيفت تكملة';
	@override String get aTerminer => 'للإنهاء';
	@override String get filtreEtat => 'الحالة';
	@override String get tousEtats => 'كل الحالات';
	@override String duree({required Object minutes}) => '⁨${minutes}⁩ دقيقة من المتابعة';
	@override String meta({required Object heure, required Object duree}) => '⁨${heure}⁩ · ⁨${duree}⁩';
	@override String dateHeure({required Object date, required Object heure}) => '⁨${date}⁩، ⁨${heure}⁩';
	@override String dateHeureAuteur({required Object date, required Object heure, required Object auteur}) => '⁨${date}⁩، ⁨${heure}⁩ · ⁨${auteur}⁩';
	@override String ligne({required Object date, required Object classe, required Object enseignant, required Object duree, required Object statut}) => '⁨${date}⁩، ⁨${classe}⁩، ⁨${enseignant}⁩، ⁨${duree}⁩، ⁨${statut}⁩';
	@override String get vide => 'لا مراقبة حتى الآن.';
	@override String get videFiltres => 'لا مراقبة تطابق هذه المعايير.';
	@override String resultats({required Object n}) => 'عمليات المراقبة المعروضة: ⁨${n}⁩';
	@override String titreDetail({required Object classe, required Object date}) => '⁨${classe}⁩ · ⁨${date}⁩';
	@override String get sectionMission => 'الفصل المراقَب';
	@override String get sectionObservation => 'ملاحظة المراقب';
	@override String get sectionComplements => 'التكملات';
	@override String get sectionEchanges => 'المراسلات مع الإدارة';
	@override String get cleClasse => 'الفصل';
	@override String get cleEnseignant => 'المعلم';
	@override String get cleDate => 'التاريخ';
	@override String get cleDuree => 'مدة المتابعة';
	@override String get cleElevesPresents => 'الحاضرون';
	@override String get cleReponse => 'الرد';
	@override String get sansComplement => 'لا تكملة.';
	@override String get faitsIndisponibles => 'السجل التلقائي لهذه الزيارة (الساعات، الطلاب الحاضرون، إعادة الاتصال) لم يصل بعد: انتهت الحصة للتو أو انقطع الاتصال. سيظهر هنا بمجرد وصوله. باقي التقرير موثوق.';
	@override String motif({required Object motif}) => 'السبب: ⁨${motif}⁩';
	@override String get ajouterComplement => 'إضافة تكملة';
}

// Path: controleur.complement
class _Traductions$controleur$complement$ar extends Traductions$controleur$complement$fr {
	_Traductions$controleur$complement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get bandeau => 'ستُضاف هذه التكملة إلى التقرير الموجود.';
	@override String get questionMotif => 'لماذا تضيف هذه التكملة؟';
	@override String get contexteMotif => 'اختياري: السبب يساعد الإدارة على قراءة التكملة. التقرير الأصلي لا يتغير.';
	@override String get precision => 'توضيح';
	@override String get precisionAide => 'حين تنقص تفصيلة · يكمّل التقرير دون أن يغيّر فيه شيئًا';
	@override String get correction => 'تصحيح';
	@override String get correctionAide => 'حين تكون معلومة في التقرير غير دقيقة · يبقى الأصل مقروءًا، ويظهر التصحيح تحته';
	@override String get faitNouveau => 'معلومة جديدة';
	@override String get faitNouveauAide => 'حين تعرفها بعد الزيارة · تحمل تاريخ يوم الإضافة';
	@override String get questionTexte => 'ماذا تضيف إلى التقرير؟';
	@override String get texteObligatoire => 'إلزامي: ما لاحظته، في جمل قليلة.';
	@override String get libelleTexte => 'التكملة';
	@override String get aideTexte => 'ما لاحظته أو عرفته منذ الزيارة.';
	@override String get texteRequis => 'اكتب التكملة للمتابعة.';
	@override String get questionRecap => 'راجع قبل الإرسال';
	@override String get cleRapport => 'التقرير الأصلي';
	@override String rapportInchange({required Object classe, required Object date}) => '⁨${classe}⁩ · ⁨${date}⁩، دون تغيير';
	@override String get cleMotif => 'السبب';
	@override String get sansMotif => 'لا سبب';
	@override String get cleTexte => 'التكملة';
	@override String get envoyer => 'إرسال التكملة';
	@override String get echec => 'لم يُؤكَّد الإرسال: لم يستجب الاتصال أو الخادم. نصك محفوظ هنا، أعد المحاولة بعد لحظة. يبقى التقرير الأصلي سليمًا.';
	@override String get envoyeTitre => 'أُضيفت التكملة';
	@override String get envoyePhrase => 'تظهر تحت التقرير الأصلي، الذي يبقى دون تغيير.';
	@override String get revenir => 'العودة إلى التقرير';
}

// Path: controleur.compteRendu
class _Traductions$controleur$compteRendu$ar extends Traductions$controleur$compteRendu$fr {
	_Traductions$controleur$compteRendu$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'التقرير';
	@override String get provisoire => 'هذه الشاشة قيد التحضير.';
	@override String get revenir => 'العودة إلى المراقبة';
	@override String sousTitre({required Object classe, required Object heure}) => '⁨${classe}⁩ · ⁨${heure}⁩';
	@override String get faits => 'السجل التلقائي للحصة';
	@override String get faitsReplies => 'السجل التلقائي للحصة، مطوي';
	@override String get faitsDeplies => 'السجل التلقائي للحصة، مفتوح';
	@override String get faitsChargement => 'جارٍ قراءة السجل التلقائي للحصة: الساعات، الطلاب الحاضرون، إعادة الاتصال.';
	@override String get faitsAbsents => 'السجل التلقائي للحصة (الساعات، الطلاب الحاضرون، إعادة الاتصال) لم يصل بعد: انتهت الحصة للتو أو انقطع الاتصال. يمكنك الرد دونه؛ وسيُرفق بالتقرير بمجرد وصوله.';
	@override String get cleHoraire => 'الموعد المقرر';
	@override String horaire({required Object debut, required Object fin}) => '⁨${debut}⁩ إلى ⁨${fin}⁩';
	@override String get cleDebutReel => 'البداية الفعلية';
	@override String debutRetard({required Object heure, required Object minutes}) => '⁨${heure}⁩، تأخر ⁨${minutes}⁩ دقيقة';
	@override String debutALHeure({required Object heure}) => '⁨${heure}⁩، في الموعد';
	@override String get cleFin => 'النهاية';
	@override String get enCours => 'جارية';
	@override String get clePresents => 'الطلاب الحاضرون';
	@override String presents({required Object presents, required Object attendus}) => '⁨${presents}⁩ من ⁨${attendus}⁩';
	@override String get cleReconnexions => 'إعادات الاتصال';
	@override String get question => 'هل لديك ما تبلغ عنه؟';
	@override String get contexte => 'يُضاف ردك إلى السجل التلقائي للحصة: الساعات، الحاضرون، إعادات الاتصال.';
	@override String get rienASignaler => 'لا شيء يُذكر';
	@override String get rienASignalerAide => 'حين جرت الحصة بشكل عادي · يُرسل التقرير بإجراء واحد؛ ويمكنك إضافة تكملة بعد ذلك';
	@override String get ajouterObservation => 'إضافة ملاحظة';
	@override String get ajouterObservationAide => 'حين تريد تدوين ما رأيته · بعض الأسئلة القصيرة، واحد في كل مرة';
	@override String get pointImportant => 'الإبلاغ عن نقطة مهمة';
	@override String get pointImportantAide => 'حين يتطلب ما رأيته انتباه الإدارة · سيُطلب نصك';
	@override String get envoyer => 'إرسال التقرير';
	@override String get plusTard => 'لاحقًا';
	@override String get notice => 'يُرسل هذا التقرير تلقائيًا إلى الإدارة.';
	@override String get echec => 'لم يُؤكَّد الإرسال: لم يستجب الاتصال أو الخادم. نصك محفوظ هنا؛ أعد المحاولة بعد لحظة. إن استمرت المشكلة، راسل الإدارة.';
	@override String get echecRien => 'لم يُؤكَّد الإرسال: لم يستجب الاتصال أو الخادم. يبقى اختيارك محددًا؛ أعد المحاولة بعد لحظة. إن استمرت المشكلة، راسل الإدارة.';
	@override String get envoyeTitre => 'أُرسل التقرير';
	@override String get envoyePhrase => 'أُرسل إلى الإدارة. للعودة إليه، افتحه في «السجل» واختر «إضافة تكملة».';
	@override String get ecrireAdmin => 'مراسلة الإدارة';
	@override String get visiteEnCours => 'جارٍ إرسال الزيارة إلى الإدارة.';
	@override String get visiteTransmise => 'أُرسلت الزيارة وسجلها التلقائي إلى الإدارة.';
	@override String get visiteEchec => 'لم يُؤكَّد إرسال الزيارة: لم يستجب الاتصال أو الخادم. أعد المحاولة؛ يبقى سجل الزيارة محفوظًا على الخادم.';
	@override String get aTerminer => 'تقرير للإنهاء';
	@override String get reprendre => 'استئناف التقرير';
}

// Path: controleur.observation
class _Traductions$controleur$observation$ar extends Traductions$controleur$observation$fr {
	_Traductions$controleur$observation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get important => 'أنت تبلغ عن نقطة مهمة: سيُطلب نصك.';
	@override String get questionNature => 'ما طبيعة ملاحظتك؟';
	@override String get contexteNature => 'تنضم ملاحظتك إلى تقرير هذه الزيارة، المرسل إلى الإدارة.';
	@override String get pointPositif => 'نقطة إيجابية';
	@override String get pointPositifAide => 'حين تستحق ممارسة أن تُذكر · تظهر في التقرير كنقطة إيجابية';
	@override String get aSuivre => 'للمتابعة';
	@override String get aSuivreAide => 'حين يجب مراجعة نقطة في زيارة قادمة · تظهر في التقرير كنقطة للمتابعة';
	@override String get interventionAdmin => 'تدخل الإدارة مطلوب';
	@override String get interventionAdminAide => 'حين يجب أن تتصرف الإدارة · سيُطلب نصك، وتستلمه مع التقرير';
	@override String get questionDomaine => 'أي مجال تخص؟';
	@override String get contexteDomaine => 'يساعد المجال الإدارة على قراءة ملاحظتك.';
	@override String get pedagogie => 'التعليم';
	@override String get pedagogieAide => 'حين يتعلق الأمر بالتدريس: الشرح، التدرج، المواد';
	@override String get interaction => 'التفاعل مع الطلاب';
	@override String get interactionAide => 'حين يتعلق الأمر بالتواصل بين المعلم والطلاب';
	@override String get gestionClasse => 'إدارة الفصل';
	@override String get gestionClasseAide => 'حين يتعلق الأمر بتنظيم الحصة: الوقت، التعليمات، السير';
	@override String get respectCadre => 'احترام الإطار';
	@override String get respectCadreAide => 'حين يتعلق الأمر بقواعد الأكاديمية والحصة';
	@override String get climat => 'السلوك / الجو العام';
	@override String get climatAide => 'حين يتعلق الأمر بسلوك الفصل أو جوه العام';
	@override String get autre => 'آخر';
	@override String get autreAide => 'حين لا يناسب أي مجال آخر · حدّده في نصك';
	@override String get questionPersonne => 'من المعني؟';
	@override String get contextePersonne => 'حدّد من تخصه الملاحظة. يُختار الطالب من قائمة الفصل، بالاسم فقط.';
	@override String get enseignant => 'المعلم';
	@override String get enseignantAide => 'حين تخص الملاحظة معلم الحصة';
	@override String get classeEntiere => 'الفصل كله';
	@override String get classeEntiereAide => 'حين تخص مجموع الطلاب الحاضرين';
	@override String get elevePrecis => 'طالب محدد';
	@override String get elevePrecisAide => 'حين يكون طالب واحد معنيًا · تختاره من القائمة، بالاسم فقط';
	@override String get aucun => 'لا مشارك محدد';
	@override String get aucunAide => 'حين لا تستهدف أحدًا بعينه، مثل سير الحصة';
	@override String get questionEleve => 'اختر الطالب من قائمة الفصل.';
	@override String get rosterChargement => 'جارٍ قراءة قائمة الطلاب الحاضرين.';
	@override String get rosterIndisponible => 'لم تصل قائمة الطلاب الحاضرين، غالبًا بسبب الاتصال. أعد المحاولة، أو اختر «الفصل كله» أو «لا مشارك محدد». إجاباتك الأخرى محفوظة.';
	@override String get rosterVide => 'لا طالب حاضر في قائمة هذه الزيارة. اختر «الفصل كله» أو «لا مشارك محدد».';
	@override String get questionTexte => 'ماذا لاحظت؟';
	@override String get texteObligatoire => 'نصك ضروري لهذه الملاحظة.';
	@override String get texteFacultatif => 'هذا النص اختياري.';
	@override String get libelleTexte => 'ملاحظتك';
	@override String get aideTexte => 'صف فقط ما لاحظته.';
	@override String get texteRequis => 'اكتب ما لاحظته للمتابعة.';
	@override String get questionRecap => 'راجع ملاحظتك قبل الإرسال.';
	@override String get cleNature => 'الطبيعة';
	@override String get cleDomaine => 'المجال';
	@override String get clePersonne => 'الشخص المعني';
	@override String get cleTexte => 'الملاحظة';
	@override String get sansTexte => 'لا نص';
	@override String get echec => 'لم يُؤكَّد الإرسال: لم يستجب الاتصال أو الخادم. نصك محفوظ هنا؛ أعد المحاولة بعد لحظة. إن استمرت المشكلة، راسل الإدارة.';
}

// Path: controleur.echanges
class _Traductions$controleur$echanges$ar extends Traductions$controleur$echanges$fr {
	_Traductions$controleur$echanges$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المراسلات';
	@override String titreFil({required Object classe, required Object date}) => '⁨${classe}⁩ · ⁨${date}⁩';
	@override String derniereActivite({required Object date}) => 'آخر نشاط: ⁨${date}⁩';
	@override String get reponseRecue => 'وصل رد';
	@override String get enAttente => 'قيد الانتظار';
	@override String get vide => 'لا مراسلات مع الإدارة حتى الآن.';
	@override String get contexte => 'سياق الزيارة، مرفق تلقائيًا';
	@override String get cleClasse => 'الفصل';
	@override String get cleDate => 'التاريخ';
	@override String get cleHeure => 'الساعة';
	@override String get auteurVous => 'أنت';
	@override String get auteurAdmin => 'الإدارة';
	@override String get champ => 'الرد على الإدارة…';
	@override String get champLibelle => 'الرد على الإدارة';
	@override String get envoyer => 'إرسال';
	@override String get champVide => 'اكتب رسالة لتتمكن من إرسالها.';
	@override String get enCours => 'جارٍ الإرسال.';
	@override String get envoye => 'أُرسل.';
	@override String get echec => 'لم يُؤكَّد الإرسال: لم يستجب الاتصال أو الخادم. نصك محفوظ هنا؛ أعد المحاولة بعد لحظة. إن استمرت المشكلة، راسل الإدارة.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String nouveauMessage({required Object auteur, required Object texte}) => 'رسالة جديدة من ⁨${auteur}⁩: ⁨${texte}⁩';
}

// Path: controleur.demo
class _Traductions$controleur$demo$ar extends Traductions$controleur$demo$fr {
	_Traductions$controleur$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'عرض تجريبي للمراقب';
	@override String get mention => 'بيانات وهمية، لا إرسال.';
	@override String get intro => 'اختر شاشة من شاشات المراقبة وحالة زيارة.';
	@override String get etatAucune => 'لا زيارة';
	@override String get etatPasEncoreEnDirect => 'الحصة لم تبدأ مباشرة بعد';
	@override String get etatEnDirect => 'حصة مباشرة';
	@override String get etatIndisponible => 'الزيارة لم تعد مقترحة';
	@override String get etatDejaControlee => 'الفصل مراقَب بالفعل';
	@override String get espaces => 'المساحات والوصول';
	@override String get espacesIntro => 'الحساب نفسه، عدة مساحات: ينتقل المعلم أو المدير إلى «المراقبة» من «الحساب»، ثم «المساحات».';
	@override String get enseignantControle => 'معلم مراقب، مساحة المراقبة';
	@override String get enseignantPrincipal => 'معلم مراقب، مساحة المعلم';
	@override String get adminControle => 'مدير مراقب، مساحة المراقبة';
	@override String get adminPrincipal => 'مدير مراقب، مساحة الإدارة';
	@override String get missionEnCours => 'زيارة جارية، العودة إلى المساحة الرئيسية';
	@override String get accesRevoque => 'سُحب الوصول أثناء التصفح';
	@override String get sansCapacite => 'معلم دون صلاحية المراقبة';
	@override String get compteRenduIndisponible => 'التقرير، الزيارة لم تعد مقترحة';
}

// Path: controleur.acces
class _Traductions$controleur$acces$ar extends Traductions$controleur$acces$fr {
	_Traductions$controleur$acces$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get revoque => 'وصولك إلى المراقبة لم يعد ساريًا.';
	@override String get revenir => 'العودة إلى مساحتي';
}

// Path: controleur.controle
class _Traductions$controleur$controle$ar extends Traductions$controleur$controle$fr {
	_Traductions$controleur$controle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المراقبة';
	@override String get mission => 'فصلك القادم للمراقبة';
	@override String get missionEnDirect => 'فصل للمراقبة الآن';
	@override String get commencer => 'بدء المراقبة';
	@override String get vide => 'لا مراقبة مطلوبة الآن.';
	@override String get videAide => 'سيقترح عليك Rewayah فصلًا للمراقبة حين تتوفر حصة مناسبة.';
	@override String get indisponible => 'هذه الزيارة لم تعد مقترحة: أُلغيت الحصة أو أُسندت إلى مراقب آخر.';
	@override String get attente => 'تُفتح المراقبة بمجرد أن تصبح الحصة مباشرة.';
	@override String get dejaEnCours => 'مراقبة جارية بالفعل في هذا الفصل.';
	@override String get dejaEnCoursAide => 'مراقبة واحدة في كل مرة لكل فصل. اختر حصة أخرى، أو عد لاحقًا: يمكنك البدء حين تنتهي هذه المراقبة.';
	@override String get incognito => 'لا يُعلَن عن حضورك في الوقت الفعلي.';
	@override String horaire({required Object debut, required Object fin}) => '⁨${debut}⁩ إلى ⁨${fin}⁩';
	@override String duree({required Object minutes}) => '⁨${minutes}⁩ دقيقة مقررة';
	@override String eleves({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لا طالب',
		one: 'طالب واحد',
		two: 'طالبان',
		few: '⁨${n}⁩ طلاب',
		many: '⁨${n}⁩ طالبًا',
		other: '⁨${n}⁩ طالب',
	);
	@override String get chargement => 'جارٍ قراءة زيارتك القادمة.';
	@override String get erreur => 'تعذّرت قراءة زيارتك القادمة، غالبًا بسبب الاتصال أو خدمة غير متاحة مؤقتًا. أعد المحاولة بعد لحظة.';
}

// Path: admin.tableau
class _Traductions$admin$tableau$ar extends Traductions$admin$tableau$fr {
	_Traductions$admin$tableau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مركز القيادة';
	@override String get dossiers => 'ملفات للاعتماد';
	@override String get dossiersDetail => 'فتح القائمة، الأقدم أولًا.';
	@override String get demandesDetail => 'أسر ومعلمون ينتظرون ردًا.';
	@override String get foyers => 'طلاب دون معلم';
	@override String get rapports => 'دفاتر ناقصة';
	@override String get incidents => 'حوادث (24 س)';
	@override String get comptes => 'وصول منتهٍ';
	@override String get incidentsEtAcces => 'الحوادث والوصول';
	@override String get demandes => 'طلبات للحسم';
	@override String get compteursErreur => 'تعذّرت قراءة العدادات. أعد المحاولة بعد لحظة.';
	@override String get calme => 'لا شيء ينتظر قرارًا اليوم.';
	@override String get apercuErreur => 'تعذّرت قراءة القائمة.';
	@override String get outils => 'الأدوات';
	@override String get outilsComptes => 'الحسابات';
	@override String get outilsComptesDetail => 'كل الأشخاص المسجلين، والذين ينتظرون قرارًا أولًا. بمن فيهم من لم يودع وثيقته بعد.';
	@override String get outilsAccesAgents => 'وصول الوكلاء الآليين';
	@override String get outilsAccesAgentsDetail => 'فتح وصول للقراءة فقط، محدود زمنيًا، على مسار شخص.';
	@override String get outilsGroupesDetail => 'الفصول وطلابها ومعلمها.';
	@override String ligneDossier({required Object prenom}) => 'ملف هوية ⁨${prenom}⁩';
	@override String ligneReaffectation({required Object prenom}) => 'تغيير معلم ⁨${prenom}⁩';
	@override String lignePlafond({required Object prenom}) => 'الحد الأقصى لطلاب ⁨${prenom}⁩';
	@override String ligneRegle({required Object prenom}) => 'تغيير قاعدة لـ⁨${prenom}⁩';
	@override String get attenteAujourdhui => 'أُودع اليوم';
	@override String get attenteUnJour => 'ينتظر منذ يوم';
	@override String attenteJours({required Object jours}) => 'ينتظر منذ ⁨${jours}⁩ أيام';
}

// Path: admin.demandes
class _Traductions$admin$demandes$ar extends Traductions$admin$demandes$fr {
	_Traductions$admin$demandes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الطلبات والقواعد';
	@override String get restanteUne => 'طلب واحد قيد الانتظار';
	@override String restantes({required Object n}) => '⁨${n}⁩ طلبات قيد الانتظار';
	@override String get aucune => 'لا طلب قيد الانتظار';
	@override String get aucuneDetail => 'تصل هنا طلبات الأسر والطلاب المستقلين والمعلمين، الأقدم أولًا.';
	@override String faitePar({required Object date, required Object role}) => 'طُلب في ⁨${date}⁩، من ⁨${role}⁩';
	@override String get roleGuardian => 'وليّ أمر';
	@override String get roleTeacher => 'معلم';
	@override String get roleStudent => 'طالب مستقل';
	@override String get roleAdmin => 'الإدارة';
	@override String get roleController => 'مراقب';
	@override String get roleInconnu => 'طرف في الملف';
	@override String get reclame => 'المطلوب';
	@override String reclameReaffectation({required Object prenom}) => 'تغيير معلم ⁨${prenom}⁩';
	@override String reclamePlafond({required Object valeur}) => 'رفع الحد الأقصى إلى ⁨${valeur}⁩ طلاب';
	@override String reclameRegle({required Object regle, required Object valeur}) => 'جعل ⁨${regle}⁩ ⁨${valeur}⁩ دقيقة';
	@override String reclameRegleSansValeur({required Object regle}) => 'مراجعة ⁨${regle}⁩';
	@override String get motifDemande => 'السبب المذكور';
	@override String get verdict => 'القرار';
	@override String get accorder => 'قبول';
	@override String get refuser => 'رفض';
	@override String get motif => 'ما يبرر هذا الرفض، في جملة واحدة';
	@override String get motifRequis => 'يجب أن يقول الرفض السبب: إنها الجملة الوحيدة التي سيتلقاها الطرف.';
	@override String get effet => 'القبول يطبّق الأثر في قاعدة البيانات: يُغلق الإسناد، أو تُوضع القاعدة. هذه الشاشة تصدر الحكم فقط.';
	@override String get journalisation => 'يُدوَّن كل قرار وكل قاعدة موضوعة في سجل التدقيق، مع اسمك.';
	@override String feuille({required Object prenom}) => 'قواعد ⁨${prenom}⁩';
	@override String get feuilleIntro => 'قيمة المنصة والقيمة المطبقة، جنبًا إلى جنب. تُغيَّر القاعدة هنا دون حاجة إلى طلب.';
	@override String get regleDuree => 'مدة الحصة';
	@override String get regleMinimum => 'المدة الدنيا المدفوعة';
	@override String get reglePause => 'الاستراحة بين درسين';
	@override String get reglePlafond => 'الحد الأقصى للطلاب';
	@override String get regleInconnue => 'قاعدة غير معروفة';
	@override String plateforme({required Object valeur}) => 'المنصة: ⁨${valeur}⁩';
	@override String effective({required Object valeur}) => 'المطبقة: ⁨${valeur}⁩';
	@override String minutes({required Object valeur}) => '⁨${valeur}⁩ دقيقة';
	@override String eleves({required Object valeur}) => '⁨${valeur}⁩ طلاب';
	@override String surchargeDepuis({required Object date, required Object motif}) => 'وُضعت في ⁨${date}⁩: ⁨${motif}⁩';
	@override String get sansSurcharge => 'يتبع هذا الطالب قاعدة المنصة.';
	@override String get changer => 'تغيير';
	@override String get clore => 'العودة إلى قاعدة المنصة';
	@override String get historique => 'الاستثناءات المغلقة';
	@override String historiqueLigne({required Object valeur, required Object debut, required Object fin}) => '⁨${valeur}⁩، من ⁨${debut}⁩ إلى ⁨${fin}⁩';
	@override String historiqueMotifs({required Object motif, required Object cloture}) => 'وُضعت: ⁨${motif}⁩. أُغلقت: ⁨${cloture}⁩.';
	@override String poserTitre({required Object regle, required Object prenom}) => '⁨${regle}⁩، لـ⁨${prenom}⁩';
	@override String cloreTitre({required Object prenom}) => 'إغلاق استثناء ⁨${prenom}⁩';
	@override String get poserMotif => 'لماذا هذا التغيير؟';
	@override String get poserMotifRequis => 'قاعدة دون سبب لا تُفهم بعد ستة أشهر.';
	@override String get poserEnvoyer => 'وضع القاعدة';
	@override String get cloreEnvoyer => 'إغلاق الاستثناء';
	@override String get erreurFile => 'تعذّر تحميل قائمة الطلبات. أعد المحاولة بعد لحظة.';
}

// Path: admin.attribution
class _Traductions$admin$attribution$ar extends Traductions$admin$attribution$fr {
	_Traductions$admin$attribution$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإسناد';
	@override String get intro => 'حين لا يأخذ أي معلم طفلًا، هنا يُسند إليه معلم.';
	@override String get colonneEleves => 'طلاب دون معلم';
	@override String get colonneEnseignants => 'المعلمون';
	@override String get aucunEleve => 'لكل طالب معلمه';
	@override String get aucunEleveDetail => 'سيظهر هنا الأطفال الذين لم يأخذهم أحد بعد، الأطول انتظارًا أولًا.';
	@override String get erreurEleves => 'تعذّرت قراءة القائمة. أعد المحاولة بعد لحظة.';
	@override String get erreurEnseignants => 'تعذّرت قراءة المعلمين. أعد المحاولة بعد لحظة.';
	@override String get attendAujourdhui => 'مسجَّل اليوم';
	@override String get attendUnJour => 'ينتظر منذ يوم';
	@override String attendJours({required Object jours}) => 'ينتظر منذ ⁨${jours}⁩ أيام';
	@override String niveau({required Object niveau}) => 'المستوى ⁨${niveau}⁩';
	@override String heuresProposees({required Object nombre}) => '⁨${nombre}⁩ ساعات مقترحة';
	@override String get heureProposee => 'ساعة واحدة مقترحة';
	@override String get sansHeure => 'لا ساعة مقترحة';
	@override String get sansHeureDetail => 'ما دامت الأسرة لم تحدد أي موعد، لا يستطيع أحد أن يسند إليها معلمًا، ولا أنت. الخطوة عندها، في أوقات توفرها.';
	@override String get changerEleve => 'اختيار طالب آخر';
	@override String get choisirEleve => 'اختر طالبًا';
	@override String get choisirEleveDetail => 'سيظهر المعلمون هنا، والذين يشاركونه ساعة أولًا.';
	@override String charge({required Object actifs, required Object plafond}) => '⁨${actifs}⁩ طلاب من ⁨${plafond}⁩';
	@override String get complet => 'بلغ الحد الأقصى';
	@override String libreSur({required Object jour, required Object heure}) => 'متاح ⁨${jour}⁩ الساعة ⁨${heure}⁩';
	@override String libreSurPlusieurs({required Object nombre}) => 'متاح في ⁨${nombre}⁩ من الساعات المقترحة';
	@override String get sansHeureCommune => 'لا ساعة مشتركة';
	@override String get quelleHeure => 'في أي ساعة؟';
	@override String creneau({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩';
	@override String get motif => 'لماذا التجاوز؟';
	@override String motifRequis({required Object prenom}) => 'لم يحدد ⁨${prenom}⁩ هذه الساعة. قد يُبرَّر إسنادها مع ذلك، ويُدوَّن ذلك في السجل.';
	@override String attribuer({required Object eleve, required Object enseignant}) => 'إسناد ⁨${eleve}⁩ إلى ⁨${enseignant}⁩';
	@override String get journalisation => 'يُدوَّن كل إسناد: من قرر، ومتى، وفي أي ساعة، والسبب إن لزم التجاوز.';
	@override String get effet => 'يغادر الطالب هذه القائمة وتُوضع دروسه في الجدول فورًا.';
	@override String erreur({required Object message}) => 'لم يكتمل الإسناد: ⁨${message}⁩';
}

// Path: admin.groupes
class _Traductions$admin$groupes$ar extends Traductions$admin$groupes$fr {
	_Traductions$admin$groupes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الفصول';
	@override String get intro => 'يجمع كل فصل معلمًا وطلابه حول موعد مشترك: هناك يُقدَّم الدرس.';
	@override String get colonneGroupe => 'الفصل';
	@override String get colonneEnseignant => 'المعلم';
	@override String get colonneType => 'الفئة';
	@override String get colonneMembres => 'الأعضاء';
	@override String get colonneCreneau => 'الموعد';
	@override String get colonneEtat => 'الحالة';
	@override String get typeEnfant => 'أطفال';
	@override String get typeAdulte => 'بالغون';
	@override String get filtreTousTypes => 'كل الفئات';
	@override String get etatActif => 'نشط';
	@override String get etatCloture => 'مغلق';
	@override String membresSur({required Object actifs, required Object seuil}) => '⁨${actifs}⁩ / ⁨${seuil}⁩';
	@override String get aucun => 'لا فصل منشأ';
	@override String get aucunDetail => 'أنشئ فصلًا أول لتمنح موعدًا مشتركًا معلمًا وطلابًا.';
	@override String get aucunAvecCeFiltre => 'لا فصل بهذا المعيار';
	@override String get aucunAvecCeFiltreDetail => 'غيّر المعيار لترى الفصول الأخرى.';
	@override String get erreur => 'تعذّرت قراءة الفصول. أعد المحاولة بعد لحظة.';
	@override String get creer => 'إنشاء فصل';
	@override String get creerTitre => 'إنشاء فصل';
	@override String get champLibelle => 'اسم الفصل';
	@override String get champEnseignantId => 'معرّف المعلم';
	@override String get champType => 'الفئة';
	@override String get champJour => 'اليوم';
	@override String get champHeure => 'الساعة (0-23)';
	@override String get champSeuil => 'الحد الأقصى';
	@override String get creerEnvoyer => 'إنشاء الفصل';
	@override String creerErreur({required Object message}) => 'لم يكتمل الإنشاء: ⁨${message}⁩';
	@override String detailTitre({required Object libelle}) => 'الفصل ⁨${libelle}⁩';
	@override String get detailMembres => 'الأعضاء';
	@override String get detailAucunMembre => 'لا طالب في هذا الفصل حتى الآن.';
	@override String get actionAjouter => 'إضافة طالب';
	@override String get actionRetirer => 'إزالة';
	@override String get actionModifierSeuil => 'تعديل الحد';
	@override String get actionObservation => 'إعدادات المتابعة';
	@override String get actionCloturer => 'إغلاق الفصل';
	@override String ajouterTitre({required Object libelle}) => 'إضافة طالب إلى ⁨${libelle}⁩';
	@override String get champEleveId => 'معرّف الطالب';
	@override String get champMotif => 'السبب';
	@override String get motifRequis => 'السبب مطلوب، ويُدوَّن في سجل التدقيق.';
	@override String get ajouterEnvoyer => 'إضافة';
	@override String ajouterErreur({required Object message}) => 'لم تكتمل الإضافة: ⁨${message}⁩';
	@override String retirerTitre({required Object prenom, required Object libelle}) => 'إزالة ⁨${prenom}⁩ من ⁨${libelle}⁩';
	@override String get retirerEnvoyer => 'إزالة';
	@override String retirerErreur({required Object message}) => 'لم تكتمل الإزالة: ⁨${message}⁩';
	@override String modifierSeuilTitre({required Object libelle}) => 'الحد الأقصى لـ⁨${libelle}⁩';
	@override String get modifierSeuilEnvoyer => 'حفظ';
	@override String modifierSeuilErreur({required Object message}) => 'لم يكتمل التعديل: ⁨${message}⁩';
	@override String cloturerTitre({required Object libelle}) => 'إغلاق ⁨${libelle}⁩';
	@override String get cloturerDetail => 'سيُزال كل الأعضاء النشطين من الفصل. لا يمكن التراجع عن هذا الإجراء.';
	@override String get cloturerEnvoyer => 'إغلاق';
	@override String cloturerErreur({required Object message}) => 'لم يكتمل الإغلاق: ⁨${message}⁩';
	@override String get journalisation => 'يُدوَّن كل إنشاء وإضافة وإزالة وإغلاق في سجل التدقيق.';
	@override String observationTitre({required Object libelle}) => 'المتابعة: ⁨${libelle}⁩';
	@override String get observationErreur => 'تعذّر حفظ الإعداد.';
	@override String get observationCapaciteAbsente => 'هذا التثبيت لا يملك بعد تحديث الخادم الذي يتطلبه هذا الإعداد (الترحيل 0036). إعادة المحاولة لن تغيّر شيئًا: يجب تطبيقه أولًا على قاعدة البيانات.';
}

// Path: admin.diagnostics
class _Traductions$admin$diagnostics$ar extends Traductions$admin$diagnostics$fr {
	_Traductions$admin$diagnostics$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'تحديد المستوى';
	@override String get intro => 'ينتظر كل طالب مسجَّل مستوى أول قبل الانضمام إلى فصل: هنا يُقرَّر هذا التوجيه.';
	@override String get aucunProgramme => 'لا منهج منشور';
	@override String get aucunProgrammeDetail => 'انشر إصدارًا أول من المنهج («التعليم» > «المناهج») قبل أن تتمكن من تقرير توجيه.';
	@override String get erreur => 'تعذّرت قراءة القائمة. أعد المحاولة بعد لحظة.';
	@override String restants({required Object n}) => '⁨${n}⁩ طلاب متبقون';
	@override String get restantUn => 'طالب واحد متبقٍ';
	@override String get inscritAujourdhui => 'مسجَّل اليوم';
	@override String get inscritDepuisUnJour => 'مسجَّل منذ يوم';
	@override String inscritDepuis({required Object jours}) => 'مسجَّل منذ ⁨${jours}⁩ أيام';
	@override String get aucun => 'لا طالب لتحديد مستواه';
	@override String get aucunDetail => 'لكل الطلاب المسجلين مستوى مقرر بالفعل.';
	@override String get champNiveau => 'مستوى التوجيه';
	@override String get champMotif => 'السبب';
	@override String get motifRequis => 'السبب مطلوب، ويُدوَّن في سجل التدقيق.';
	@override String get decider => 'تقرير التوجيه';
	@override String deciderErreur({required Object message}) => 'لم يكتمل القرار: ⁨${message}⁩';
	@override String get journalisation => 'يُدوَّن كل توجيه مقرر في سجل التدقيق.';
}

// Path: admin.qualite
class _Traductions$admin$qualite$ar extends Traductions$admin$qualite$fr {
	_Traductions$admin$qualite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الجودة';
	@override String get intro => 'الخلل التعليمي المكتشف: تقارير ناقصة، عوائق دون متابعة، تقييمات متأخرة.';
	@override String get erreur => 'تعذّرت قراءة حالات الخلل. أعد المحاولة بعد لحظة.';
	@override String get aucune => 'لا خلل مكتشف';
	@override String get aucuneDetail => 'كل شيء محدَّث: التقارير محررة، والعوائق متابَعة، والتقييمات في موعدها.';
	@override String get filtreToutes => 'الكل';
	@override String get filtreOuvertes => 'مفتوحة';
	@override String get filtreTraitees => 'معالَجة';
	@override String get groupeRapportManquant => 'تقارير حصص ناقصة';
	@override String get groupeBlocageSansSuivi => 'عوائق دون متابعة';
	@override String get groupeEvaluationEnRetard => 'تقييمات متأخرة';
	@override String get colonnePersonne => 'يخص';
	@override String get colonneDepuis => 'منذ';
	@override String get colonneStatut => 'الحالة';
	@override String get statutOuvert => 'مفتوحة';
	@override String get statutTraite => 'معالَجة';
	@override String get depuisAujourdhui => 'اليوم';
	@override String get depuisUnJour => 'يوم واحد';
	@override String depuisJours({required Object jours}) => '⁨${jours}⁩ أيام';
	@override String get actionTraiter => 'تعليم كمعالَج';
	@override String traiterTitre({required Object personne}) => 'تعليم كمعالَج: ⁨${personne}⁩';
	@override String get champNote => 'ملاحظة (اختيارية)';
	@override String get traiterEnvoyer => 'تعليم كمعالَج';
	@override String traiterErreur({required Object message}) => 'لم تكتمل المعالجة: ⁨${message}⁩';
}

// Path: admin.regles
class _Traductions$admin$regles$ar extends Traductions$admin$regles$fr {
	_Traductions$admin$regles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'القواعد';
	@override String get intro => 'القيم الافتراضية للمنصة كلها. يُوضع الاستثناء لملف محدد من «العمليات» > «القواعد الفردية»، وأبدًا من هنا.';
	@override String get erreur => 'تعذّرت قراءة القواعد. أعد المحاولة بعد لحظة.';
	@override String erreurEcriture({required Object message}) => 'لم يكتمل الحفظ: ⁨${message}⁩';
	@override String get valeurInvalide => 'أدخل رقمًا صالحًا.';
	@override String get envoyer => 'حفظ';
	@override String get champValeur => 'القيمة';
	@override String get absenceSeuil => 'حد الغياب';
	@override String get absenceSeuilDetail => 'بعد هذا العدد من الدقائق دون الانضمام إلى الحصة، يُسجَّل الطالب غائبًا.';
	@override String get dureeSeance => 'مدة الحصة';
	@override String get dureeSeanceDetail => 'المدة الافتراضية للحصة، قبل أي استثناء فردي.';
	@override String get dureeMinimalePayee => 'المدة الدنيا المدفوعة';
	@override String get dureeMinimalePayeeDetail => 'دون هذه المدة، تبقى الحصة المختصرة مدفوعة كاملة.';
	@override String get pauseEntreSeances => 'الاستراحة بين حصتين';
	@override String get pauseEntreSeancesDetail => 'الوقت الأدنى المتروك للمعلم بين حصتين متتاليتين.';
	@override String get elevesParEnseignant => 'الطلاب لكل معلم';
	@override String get elevesParEnseignantDetail => 'العدد الأقصى للطلاب الذين يمكن لمعلم متابعتهم في آن واحد.';
	@override String get horizonAffectation => 'أفق الإسناد';
	@override String get horizonAffectationDetail => 'عدد الأسابيع مسبقًا التي يبحث فيها الإسناد عن معلم متاح.';
	@override String get ageCameraAuto => 'العمر الأدنى للكاميرا التلقائية';
	@override String get ageCameraAutoDetail => 'دون هذا العمر، يبقى تشغيل الكاميرا خاضعًا لموافقة وليّ الأمر.';
	@override String get ageInterfaceEnfant => 'العمر الأقصى لواجهة الطفل';
	@override String get ageInterfaceEnfantDetail => 'دون هذا العمر، ينتقل الملف إلى الواجهة المبسطة عند إنشائه.';
	@override String get appareilsParEleve => 'الأجهزة لكل طالب';
	@override String get appareilsParEleveDetail => 'عدد الأجهزة التي يمكن أن تكون نشطة لطالب في الوقت نفسه.';
	@override String get seancesSimultanees => 'الحصص المتزامنة لكل ملف';
	@override String get seancesSimultaneesDetail => 'عدد الحصص التي يمكن لملف واحد متابعتها في الوقت نفسه.';
	@override String uniteMinutes({required Object n}) => '⁨${n}⁩ دقيقة';
	@override String uniteSemaines({required Object n}) => '⁨${n}⁩ أسبوع';
	@override String uniteNombre({required Object n}) => '⁨${n}⁩';
}

// Path: admin.fonctionnalites
class _Traductions$admin$fonctionnalites$ar extends Traductions$admin$fonctionnalites$fr {
	_Traductions$admin$fonctionnalites$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الوظائف';
	@override String get intro => 'الوظائف التي تغيّر سلوك المنصة كلها.';
	@override String get erreur => 'تعذّرت قراءة الوظائف. أعد المحاولة بعد لحظة.';
	@override String erreurEcriture({required Object message}) => 'لم يكتمل الحفظ: ⁨${message}⁩';
	@override String get valeurInvalide => 'أدخل رقمًا صالحًا.';
	@override String get envoyer => 'حفظ';
	@override String get champValeur => 'القيمة';
	@override String get multiParticipants => 'حصص متعددة المشاركين';
	@override String get multiParticipantsDetail => 'يسمح بعدة طلاب في حصة الفيديو نفسها.';
	@override String get participantsMax => 'الحد الأقصى للمشاركين';
	@override String get participantsMaxDetail => 'عدد المشاركين المسموح به حين تكون الحصص متعددة المشاركين مفعَّلة.';
	@override String uniteNombre({required Object n}) => '⁨${n}⁩';
}

// Path: admin.conservationDonnees
class _Traductions$admin$conservationDonnees$ar extends Traductions$admin$conservationDonnees$fr {
	_Traductions$admin$conservationDonnees$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الاحتفاظ بالبيانات';
	@override String get intro => 'المدة التي تبقى فيها هذه العناصر متاحة قبل حذفها التلقائي.';
	@override String get erreur => 'تعذّرت قراءة مدد الاحتفاظ. أعد المحاولة بعد لحظة.';
	@override String erreurEcriture({required Object message}) => 'لم يكتمل الحفظ: ⁨${message}⁩';
	@override String get valeurInvalide => 'أدخل رقمًا صالحًا.';
	@override String get envoyer => 'حفظ';
	@override String get champValeur => 'القيمة';
	@override String get enregistrements => 'تسجيلات الحصص';
	@override String get enregistrementsDetail => 'عدد الأيام التي يبقى فيها تسجيل الحصة متاحًا.';
	@override String get documentsIdentite => 'وثائق الهوية';
	@override String get documentsIdentiteDetail => 'عدد الأيام التي تبقى فيها وثيقة الهوية المودعة متاحة قبل حذفها.';
	@override String uniteJours({required Object n}) => '⁨${n}⁩ ي';
}

// Path: admin.politiqueRevueKyc
class _Traductions$admin$politiqueRevueKyc$ar extends Traductions$admin$politiqueRevueKyc$fr {
	_Traductions$admin$politiqueRevueKyc$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'سياسة الجنس في مراجعة الهوية';
	@override String get libelle => 'حصر مراجعة الهوية حسب الجنس';
	@override String get aide => 'حين تُعطَّل هذه القاعدة، يمكن لكل عضو مخوَّل بمراجعة الملفات معالجة ملفات نطاقه، أيًا كان جنسه.';
	@override String get echecEnregistrement => _root.admin.groupes.observationErreur;
}

// Path: admin.evaluations
class _Traductions$admin$evaluations$ar extends Traductions$admin$evaluations$fr {
	_Traductions$admin$evaluations$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'التقييمات';
	@override String get intro => 'ما هو مقرر، وما أُجري، والشهادات المحصَّلة.';
	@override String get erreur => 'تعذّرت قراءة التقييمات. أعد المحاولة بعد لحظة.';
	@override String get aucune => 'لا تقييم';
	@override String get aucuneDetail => 'برمج تقييمًا أول لطالب حُدِّد مستواه بالفعل.';
	@override String get aucuneAvecCeFiltre => 'لا تقييم بهذا المعيار';
	@override String get aucuneAvecCeFiltreDetail => 'غيّر المعيار لترى التقييمات الأخرى.';
	@override String get filtreToutes => 'الكل';
	@override String get filtrePlanifiees => 'مبرمجة';
	@override String get filtreRealisees => 'منجزة';
	@override String get filtreAnnulees => 'ملغاة';
	@override String get filtreCertifications => 'الشهادات';
	@override String get colonneEleve => 'الطالب';
	@override String get colonneNiveau => 'المستوى';
	@override String get colonneType => 'النوع';
	@override String get colonneDatePrevue => 'مقرر في';
	@override String get colonneStatut => 'الحالة';
	@override String get colonneResultat => 'النتيجة';
	@override String get typeInitiale => 'أولي';
	@override String get typePeriodique => 'دوري';
	@override String get typeReevaluation => 'إعادة تقييم';
	@override String get typeCertification => 'شهادة';
	@override String get statutPlanifiee => 'مبرمج';
	@override String get statutRealisee => 'منجز';
	@override String get statutAnnulee => 'ملغى';
	@override String get resultatReussi => 'ناجح';
	@override String get resultatEchec => 'راسب';
	@override String get resultatARevoir => 'للمراجعة';
	@override String get planifier => 'برمجة تقييم';
	@override String get planifierTitre => 'برمجة تقييم';
	@override String get champEleveId => 'معرّف الطالب';
	@override String get champNiveau => 'المستوى المقيَّم';
	@override String get champType => 'النوع';
	@override String get champDatePrevue => 'التاريخ المقرر (يوم/شهر/سنة)';
	@override String get planifierEnvoyer => 'برمجة';
	@override String planifierErreur({required Object message}) => 'لم تكتمل البرمجة: ⁨${message}⁩';
	@override String get actionEnregistrerResultat => 'حفظ النتيجة';
	@override String get actionAnnuler => 'إلغاء التقييم';
	@override String resultatTitre({required Object eleve}) => 'نتيجة ⁨${eleve}⁩';
	@override String get champNotes => 'ملاحظات (اختيارية)';
	@override String get resultatEnvoyer => 'حفظ';
	@override String resultatErreur({required Object message}) => 'لم يكتمل الحفظ: ⁨${message}⁩';
	@override String annulerTitre({required Object eleve}) => 'إلغاء تقييم ⁨${eleve}⁩';
	@override String get annulerEnvoyer => 'إلغاء';
	@override String annulerErreur({required Object message}) => 'لم يكتمل الإلغاء: ⁨${message}⁩';
	@override String get champMotif => 'السبب';
	@override String get motifRequis => 'السبب مطلوب، ويُدوَّن في سجل التدقيق.';
	@override String get journalisation => 'تُدوَّن كل برمجة ونتيجة وإلغاء في سجل التدقيق.';
}

// Path: admin.progression
class _Traductions$admin$progression$ar extends Traductions$admin$progression$fr {
	_Traductions$admin$progression$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'التقدم';
	@override String get intro => 'المستوى الحالي لكل طالب، وفصله، والعوائق أو الاستثناءات الجارية.';
	@override String get erreur => 'تعذّرت قراءة التقدم. أعد المحاولة بعد لحظة.';
	@override String get aucun => 'لا طالب نشط';
	@override String get aucunDetail => 'سيظهر الطلاب هنا بمجرد أول تحديد لمستواهم.';
	@override String get colonneEleve => 'الطالب';
	@override String get colonneGroupe => 'الفصل';
	@override String get colonneNiveau => 'المستوى';
	@override String get colonneDepuis => 'منذ';
	@override String get colonneException => 'الاستثناء';
	@override String get sansGroupe => 'دون فصل';
	@override String get sansNiveau => 'لم يُحدَّد مستواه';
	@override String get filtreTousCycles => 'كل المراحل';
	@override String get depuisAujourdhui => 'اليوم';
	@override String get depuisUnJour => 'يوم واحد';
	@override String depuisJours({required Object jours}) => '⁨${jours}⁩ أيام';
	@override String get typeBlocage => 'عائق';
	@override String get typeDerogation => 'استثناء';
	@override String get actionPoserBlocage => 'وضع عائق';
	@override String get actionPoserDerogation => 'وضع استثناء';
	@override String get actionCloreException => 'إغلاق الاستثناء';
	@override String get actionPromouvoir => 'تغيير المستوى';
	@override String poserExceptionTitre({required Object type, required Object eleve}) => '⁨${type}⁩ لـ⁨${eleve}⁩';
	@override String get poserExceptionEnvoyer => 'وضع الاستثناء';
	@override String poserExceptionErreur({required Object message}) => 'لم يكتمل الوضع: ⁨${message}⁩';
	@override String clorerExceptionTitre({required Object eleve}) => 'إغلاق استثناء ⁨${eleve}⁩';
	@override String get clorerExceptionEnvoyer => 'إغلاق';
	@override String clorerExceptionErreur({required Object message}) => 'لم يكتمل الإغلاق: ⁨${message}⁩';
	@override String promouvoirTitre({required Object eleve}) => 'تغيير مستوى ⁨${eleve}⁩';
	@override String get promouvoirChampNiveau => 'المستوى الجديد';
	@override String get promouvoirEnvoyer => 'حفظ';
	@override String promouvoirErreur({required Object message}) => 'لم يكتمل التغيير: ⁨${message}⁩';
	@override String get champMotif => 'السبب';
	@override String get motifRequis => 'السبب مطلوب، ويُدوَّن في سجل التدقيق.';
	@override String get journalisation => 'يُدوَّن كل استثناء موضوع ومغلق، وكل تغيير مستوى، في سجل التدقيق.';
}

// Path: admin.programmes
class _Traductions$admin$programmes$ar extends Traductions$admin$programmes$fr {
	_Traductions$admin$programmes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المناهج';
	@override String get intro => 'منهج Rewayah، بإصدارات: الإصدار المنشور لا يُعدَّل، وكل تطور أكاديمي ينشئ إصدارًا جديدًا.';
	@override String get aucuneVersion => 'لا إصدار من المنهج';
	@override String get aucuneVersionDetail => 'أنشئ الإصدار الأول، كمسودة، لتبدأ بإضافة المستويات إليه.';
	@override String get erreur => 'تعذّرت قراءة المنهج. أعد المحاولة بعد لحظة.';
	@override String get statutBrouillon => 'مسودة';
	@override String get statutPubliee => 'منشور';
	@override String get statutArchivee => 'مؤرشف';
	@override String versionNumero({required Object numero}) => 'الإصدار ⁨${numero}⁩';
	@override String niveauxSur({required Object nombre}) => '⁨${nombre}⁩ مستويات';
	@override String get creerVersion => 'إنشاء إصدار';
	@override String get creerVersionVide => 'إنشاء إصدار فارغ';
	@override String get enregistrerVersion => 'حفظ الإصدار';
	@override String get creerVersionDepuisPubliee => 'إنشاء إصدار جديد انطلاقًا من هذا';
	@override String creerVersionErreur({required Object message}) => 'لم يكتمل الإنشاء: ⁨${message}⁩';
	@override String get niveauxTitre => 'المستويات';
	@override String get niveauAucun => 'لا مستوى في هذا الإصدار';
	@override String get niveauAucunDetail => 'أضف مستوى أول لتبدأ بتكوين هذا الإصدار.';
	@override String codeTechnique({required Object code}) => 'الرمز: ⁨${code}⁩';
	@override String get ajouterNiveau => 'إضافة مستوى';
	@override String ajouterNiveauTitre({required Object version}) => 'إضافة مستوى إلى ⁨${version}⁩';
	@override String get ajouterNiveauEnvoyer => 'إضافة';
	@override String ajouterNiveauErreur({required Object message}) => 'لم تكتمل الإضافة: ⁨${message}⁩';
	@override String get modifierNiveau => 'تعديل';
	@override String modifierNiveauTitre({required Object nom}) => 'تعديل ⁨${nom}⁩';
	@override String get modifierNiveauEnvoyer => 'حفظ';
	@override String modifierNiveauErreur({required Object message}) => 'لم يكتمل التعديل: ⁨${message}⁩';
	@override String get supprimerNiveau => 'حذف';
	@override String supprimerNiveauTitre({required Object nom}) => 'حذف ⁨${nom}⁩';
	@override String get supprimerNiveauEnvoyer => 'حذف';
	@override String supprimerNiveauErreur({required Object message}) => 'لم يكتمل الحذف: ⁨${message}⁩';
	@override String get publierVersion => 'نشر الإصدار';
	@override String publierVersionTitre({required Object version}) => 'نشر ⁨${version}⁩';
	@override String get publierVersionDetail => 'بعد نشره، لا يمكن تعديل هذا الإصدار. كل تطور أكاديمي سينشئ إصدارًا جديدًا.';
	@override String get publierVersionEnvoyer => 'نشر';
	@override String publierVersionErreur({required Object message}) => 'لم يكتمل النشر: ⁨${message}⁩';
	@override String get champCodeTechnique => 'الرمز التقني (استخدام داخلي، لا يُعرض للطالب أبدًا)';
	@override String get champNomHumain => 'الاسم المعروض';
	@override String get champCycle => 'المرحلة';
	@override String get champOrdre => 'الترتيب';
	@override String get champDescription => 'الوصف (اختياري)';
	@override String get champMotif => 'السبب';
	@override String get motifRequis => 'السبب مطلوب، ويُدوَّن في سجل التدقيق.';
	@override String get journalisation => 'يُدوَّن كل إنشاء وتعديل وحذف ونشر في سجل التدقيق.';
}

// Path: admin.journal
class _Traductions$admin$journal$ar extends Traductions$admin$journal$fr {
	_Traductions$admin$journal$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'السجل';
	@override String get chaineIntacte => 'السجل سليم';
	@override String chaineIntacteDetail({required Object nombre}) => 'أُعيدت قراءة ⁨${nombre}⁩ مدخلًا واحدًا واحدًا: لم يُعدَّل أي منها ولم يُحذف منذ كتابته.';
	@override String get chaineRompue => 'السجل معدَّل';
	@override String chaineRompueUne({required Object entree}) => 'مدخل لم يعد يطابق بصمته، رقم ⁨${entree}⁩. شيء ما مسّ قاعدة البيانات من خارج التطبيق.';
	@override String chaineRompueDetail({required Object nombre, required Object entree}) => '⁨${nombre}⁩ مدخلات لم تعد تطابق بصمتها، ابتداءً من الرقم ⁨${entree}⁩. شيء ما مسّ قاعدة البيانات من خارج التطبيق.';
	@override String get chaineInconnue => 'السلامة غير معروفة';
	@override String get chaineInconnueDetail => 'لم يكتمل التحقق. تبقى المدخلات أدناه مقروءة، لكن لا شيء يضمن الآن أنها كاملة.';
	@override String get chaineEnCours => 'جارٍ التحقق';
	@override String get chaineEnCoursDetail => 'إعادة قراءة بصمة كل مدخل.';
	@override String get periodeSemaine => 'آخر 7 أيام';
	@override String get periodeMois => 'آخر 30 يومًا';
	@override String get periodeTout => 'منذ البداية';
	@override String get tousTypes => 'كل الأحداث';
	@override String get tousActeurs => 'الجميع';
	@override String get colonneQuand => 'متى';
	@override String get colonneQui => 'من';
	@override String get colonneRole => 'بأي صفة';
	@override String get colonneQuoi => 'ما الذي فُعل';
	@override String get colonneCible => 'على ماذا';
	@override String get colonneDetail => 'التفاصيل';
	@override String horodatage({required Object date, required Object heure}) => '⁨${date}⁩ الساعة ⁨${heure}⁩';
	@override String get acteurSysteme => 'النظام';
	@override String get acteurInconnu => 'حساب محذوف';
	@override String get roleAdmin => 'الإدارة';
	@override String get roleEnseignant => 'معلم';
	@override String get roleTuteur => 'وليّ أمر';
	@override String get roleEleve => 'طالب';
	@override String get roleControleur => 'مراقب';
	@override String get roleComptable => 'محاسب';
	@override String get roleAucun => 'خارج الجلسة';
	@override String get evtKycLu => 'اطُّلع على ملف الهوية';
	@override String get evtKycTranche => 'حُسم ملف الهوية';
	@override String get evtProfilCree => 'أُنشئ ملف';
	@override String get evtProfilEnfantCree => 'أُنشئ ملف طفل';
	@override String get evtCodeCree => 'أُنشئ رمز ربط';
	@override String get evtAppareilAppaire => 'رُبط جهاز';
	@override String get evtAppareilRevoque => 'أُلغي جهاز';
	@override String get evtPedagogie => 'عُدِّلت الإعدادات التعليمية';
	@override String get evtAffectationPrise => 'قبل معلم طالبًا';
	@override String get evtAffectationAttribuee => 'أسندت الإدارة طالبًا';
	@override String get evtDemandeCreee => 'قُدِّم طلب';
	@override String get evtDemandeTranchee => 'حُسم طلب';
	@override String get evtReglePosee => 'وُضعت قاعدة';
	@override String get evtRegleClose => 'أُغلقت قاعدة';
	@override String get filtreEvenement => 'الحدث';
	@override String get filtreActeur => 'الفاعل';
	@override String get evtAgentJetonEmis => 'صدر وصول وكيل آلي';
	@override String get evtAgentJetonRevoque => 'أُلغي وصول وكيل آلي';
	@override String get evtAgentSessionOuverte => 'فُتحت جلسة وكيل آلي';
	@override String get evtObservationControleur => 'بدأت زيارة مراقبة';
	@override String get evtJetonVideo => 'سُمح بالدخول إلى القاعة';
	@override String get vide => 'لا حدث مسجَّل';
	@override String get videDetail => 'ستُدوَّن هنا كل قراءة لملف، وكل قرار، وكل إسناد.';
	@override String get videFiltre => 'لا حدث مطابق';
	@override String get videFiltreDetail => 'وسّع الفترة، أو خفّف أحد المعايير.';
	@override String get effacerFiltres => 'مسح المعايير';
	@override String get erreur => 'تعذّرت قراءة السجل. أعد المحاولة بعد لحظة.';
	@override String get erreurSuite => 'تعذّرت قراءة المدخلات الأقدم.';
	@override String get chargerSuite => 'تحميل المدخلات الأقدم';
	@override String get fin => 'وصلت إلى أول مدخل في السجل.';
	@override late final _Traductions$admin$journal$evenements$ar evenements = _Traductions$admin$journal$evenements$ar._(_root);
}

// Path: admin.observations
class _Traductions$admin$observations$ar extends Traductions$admin$observations$fr {
	_Traductions$admin$observations$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المتابعات';
	@override String get titrePage => 'سجل المتابعات';
	@override String get sousTitre => 'الإدارة';
	@override String get recherche => 'البحث عن وليّ أمر أو طالب';
	@override String get rechercheCourte => 'أدخل حرفين على الأقل.';
	@override String get rechercheAucune => 'لا وليّ أمر ولا طالب بهذا الاسم.';
	@override String get rechercheErreur => 'لم يكتمل البحث. أعد المحاولة.';
	@override String get roleTuteur => 'وليّ أمر';
	@override String get roleEleve => 'طالب';
	@override String filtreTuteur({required Object nom}) => 'وليّ الأمر: ⁨${nom}⁩';
	@override String filtreEleve({required Object nom}) => 'الطالب: ⁨${nom}⁩';
	@override String retirerFiltre({required Object filtre}) => 'إزالة المعيار ⁨${filtre}⁩';
	@override String get classe => 'الفصل';
	@override String get toutesClasses => 'كل الفصول';
	@override String get periode => 'الفترة';
	@override String get statut => 'الحالة';
	@override String get tousStatuts => 'كل الحالات';
	@override String get colonneDate => 'التاريخ';
	@override String get colonneTuteur => 'وليّ الأمر';
	@override String get colonneEleve => 'الطالب';
	@override String get colonneClasse => 'الفصل';
	@override String get colonneEntree => 'الدخول';
	@override String get colonneSortie => 'الخروج';
	@override String get colonneDuree => 'المدة';
	@override String get colonneStatut => 'الحالة';
	@override String get terminee => 'منتهية';
	@override String get ouverte => 'الخروج غير مسجَّل';
	@override String get sortieAbsente => 'غير مسجَّل';
	@override String get dureeNonConfirmee => 'غير مؤكَّدة';
	@override String get nomInconnu => 'الاسم غير متاح';
	@override String get classeInconnue => 'الفصل غير متاح';
	@override String plage({required Object entree, required Object sortie}) => '⁨${entree}⁩ - ⁨${sortie}⁩';
	@override String ligne({required Object rang, required Object date, required Object tuteur, required Object eleve, required Object classe, required Object entree, required Object sortie, required Object duree, required Object statut}) => 'الزيارة ⁨${rang}⁩ في ⁨${date}⁩، ⁨${tuteur}⁩ لـ⁨${eleve}⁩، ⁨${classe}⁩، الدخول ⁨${entree}⁩، الخروج ⁨${sortie}⁩، المدة ⁨${duree}⁩، ⁨${statut}⁩';
	@override String fuseau({required Object decalage}) => 'الساعات معروضة بتوقيت هذا الجهاز (UTC⁨${decalage}⁩).';
	@override String get indisponibleTitre => 'سجل المتابعات غير متاح';
	@override String get indisponiblePhrase => 'قراءة زيارات المتابعة غير مفتوحة في التطبيق بعد.';
	@override String get videTitre => 'لا زيارة مسجَّلة';
	@override String get videPhrase => 'ستظهر هنا زيارات متابعة أولياء الأمور.';
	@override String get videFiltreTitre => 'لا زيارة مطابقة';
	@override String get videFiltrePhrase => 'وسّع الفترة أو أزل أحد المعايير.';
	@override String get effacerFiltres => 'مسح المعايير';
	@override String get chargerSuite => 'تحميل الزيارات الأقدم';
	@override String get erreurSuite => 'تعذّرت قراءة الزيارات الأقدم.';
	@override String get fin => 'كل الزيارات معروضة.';
}

// Path: admin.comptes
class _Traductions$admin$comptes$ar extends Traductions$admin$comptes$fr {
	_Traductions$admin$comptes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الحسابات';
	@override String get intro => 'كل الأشخاص المسجلين، والذين ينتظرون قرارًا أولًا. المعلم الذي لم يودع وثيقة هويته يبقى ظاهرًا هنا: إنه المكان الوحيد الذي يُظهره.';
	@override String get attenteUneAujourdhui => 'شخص واحد ينتظر قرارًا، مسجَّل اليوم.';
	@override String get attenteUneUnJour => 'شخص واحد ينتظر قرارًا منذ يوم.';
	@override String attenteUne({required Object jours}) => 'شخص واحد ينتظر قرارًا منذ ⁨${jours}⁩ أيام.';
	@override String attentePlusieurs({required Object nombre}) => '⁨${nombre}⁩ أشخاص ينتظرون قرارًا.';
	@override String get filtreTousEtats => 'الكل';
	@override String get filtreTousRoles => 'كل الأدوار';
	@override String get filtreRole => 'الدور';
	@override String get aucunAvecCeFiltre => 'لا حساب بهذا المعيار';
	@override String get aucunAvecCeFiltreDetail => 'أزل أحد المعايير لتوسيع القائمة.';
	@override String get erreur => 'تعذّرت قراءة الحسابات. أعد المحاولة بعد لحظة.';
	@override String get colonnePersonne => 'الشخص';
	@override String get colonneIdentifiant => 'المعرّف';
	@override String get colonneRole => 'الدور';
	@override String get colonneEtat => 'الحالة';
	@override String get colonnePiece => 'وثيقة الهوية';
	@override String get colonneAttente => 'مسجَّل منذ';
	@override String get colonneContrats => 'العقود';
	@override String get etatEnAttente => 'قيد الانتظار';
	@override String get etatActif => 'نشط';
	@override String get etatProvisoire => 'مؤقت';
	@override String get etatSuspendu => 'موقوف';
	@override String get etatInconnu => 'حالة غير معروفة';
	@override String get roleAdmin => 'الإدارة';
	@override String get roleComptable => 'محاسب';
	@override String get roleControleur => 'مراقب';
	@override String get roleEnseignant => 'معلم';
	@override String get roleTuteur => 'وليّ أمر';
	@override String get roleEleve => 'طالب';
	@override String get roleInconnu => 'دور غير معروف';
	@override String get pieceAucune => 'لا وثيقة مودَعة';
	@override String get pieceAVerifier => 'للتحقق';
	@override String get pieceValidee => 'معتمَدة';
	@override String get pieceRefusee => 'مرفوضة';
	@override String get pieceNonVisible => 'خارج صلاحيتك';
	@override String get pieceSansObjet => 'لا ينطبق';
	@override String get attendAujourdhui => 'اليوم';
	@override String get attendUnJour => 'يوم واحد';
	@override String attendJours({required Object jours}) => '⁨${jours}⁩ أيام';
}

// Path: admin.agents
class _Traductions$admin$agents$ar extends Traductions$admin$agents$fr {
	_Traductions$admin$agents$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'وصول الوكلاء الآليين';
	@override String get intro => 'يسمح الرمز لوكيل آلي بفتح التطبيق وقراءة ما يقرؤه شخص فيه. لا يستطيع كتابة شيء ولا إلغاء شيء ولا تعديل شيء: قاعدة البيانات تمنعه، لا الواجهة.';
	@override String get emettre => 'إصدار رمز';
	@override String get libelle => 'الغرض من هذا الرمز';
	@override String get libelleAide => 'إلزامي. الرمز دون اسم رمز لا يجرؤ أحد على إلغائه.';
	@override String get libelleExemple => 'مراجعة متابعة مريم';
	@override String get qui => 'من يتابعه الوكيل';
	@override String get quiAide => 'سيرى الوكيل شاشة هذا الشخص تمامًا، وسيكون مساره مساره.';
	@override String get quiVide => 'اختيار شخص';
	@override String get chercher => 'البحث عن اسم أو معرّف';
	@override String get duree => 'لكم من الوقت';
	@override String dureeHeure({required Object nombre}) => '⁨${nombre}⁩ س';
	@override String get dureePlafond => 'أربع وعشرون ساعة على الأكثر، وقاعدة البيانات تتحقق من ذلك بنفسها.';
	@override String get identite => 'الأسماء';
	@override String get identiteMasquee => 'مخفية';
	@override String get identiteMasqueeDetail => 'يقرأ الوكيل المعرّفات (ELV-0042) بدل الأسماء. قاعدة البيانات هي التي تستبدلها: الاسم لا يخرج.';
	@override String get identiteVisible => 'ظاهرة';
	@override String get identiteVisibleDetail => 'يقرأ الوكيل الأسماء، كما يراها الشخص المتابَع.';
	@override String get pourra => 'سيستطيع';
	@override String get pourraDetail => 'فتح التطبيق والتنقل فيه وقراءة كل ما يقرؤه هذا الشخص.';
	@override String get nePourraPas => 'لن يستطيع';
	@override String get nePourraPasDetail => 'كتابة أي شيء، ولا رؤية وثيقة هوية، ولا جهاز، ولا سجل التدقيق، ولا الخروج من نطاق هذا الشخص.';
	@override String get emissionEnCours => 'جارٍ الإصدار';
	@override String get emis => 'صدر الرمز';
	@override String get emisDetail => 'سلّم هذا الرابط للوكيل. لن يظهر بعد ذلك: لا هذه الشاشة ولا قاعدة البيانات تستطيعان استعادته.';
	@override String get copier => 'نسخ الرابط';
	@override String get copie => 'نُسخ الرابط';
	@override String get termine => 'نسخت الرابط';
	@override String get erreurEmission => 'تعذّر إصدار الرمز. أعد المحاولة بعد لحظة.';
	@override String get colonneLibelle => 'الرمز';
	@override String get colonneQui => 'يتابع';
	@override String get colonneParcours => 'المسار';
	@override String get colonneIdentite => 'الأسماء';
	@override String get colonneExpire => 'حتى';
	@override String get colonneUsage => 'مرات الفتح';
	@override String get colonneEtat => 'الحالة';
	@override String get parcoursEleve => 'طالب';
	@override String get parcoursTuteur => 'وليّ أمر';
	@override String get parcoursEnseignant => 'معلم';
	@override String get parcoursControleur => 'مراقبة الجودة';
	@override String get parcoursAdmin => 'الإدارة';
	@override String get parcoursComptable => 'محاسب';
	@override String get parcoursInconnu => 'مسار غير معروف';
	@override String get etatActif => 'نشط';
	@override String get etatRevoque => 'ملغى';
	@override String get etatExpire => 'منتهي الصلاحية';
	@override String get jamaisServi => 'لم يُستخدم قط';
	@override String usage({required Object nombre, required Object quand}) => '⁨${nombre}⁩ مرات، آخرها ⁨${quand}⁩';
	@override String get revoquer => 'إلغاء';
	@override String get revoquerTitre => 'إلغاء هذا الرمز؟';
	@override String get revoquerDetail => 'سيفقد الوكيل الوصول عند طلبه التالي. هذا نهائي: الرمز الملغى لا يُعاد تفعيله.';
	@override String get revoquerConfirmer => 'إلغاء';
	@override String get annuler => 'تراجع';
	@override String get revoque => 'أُلغي الرمز';
	@override String get erreurRevocation => 'لم يكتمل الإلغاء. أعد المحاولة.';
	@override String get vide => 'لا رمز متابعة';
	@override String get videDetail => 'لا وكيل آلي لديه وصول إلى التطبيق الآن.';
	@override String get erreur => 'تعذّرت قراءة قائمة الرموز.';
}

// Path: admin.notifications
class _Traductions$admin$notifications$ar extends Traductions$admin$notifications$fr {
	_Traductions$admin$notifications$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإشعارات';
	@override String get vide => 'لا إشعارات';
	@override String get videDetail => 'لا شيء يُذكر الآن.';
}

// Path: commun.etats.chargementProlonge
class _Traductions$commun$etats$chargementProlonge$ar extends Traductions$commun$etats$chargementProlonge$fr {
	_Traductions$commun$etats$chargementProlonge$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الاتصال يستغرق وقتًا أطول من المتوقع';
	@override String get phrase => 'يمكنك الانتظار قليلًا أو إعادة المحاولة.';
}

// Path: commun.etats.horsLigne
class _Traductions$commun$etats$horsLigne$ar extends Traductions$commun$etats$horsLigne$fr {
	_Traductions$commun$etats$horsLigne$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'أنت غير متصل';
	@override String get phrase => 'تحقّق من اتصالك. ما هو معروض يبقى قابلًا للاطلاع.';
}

// Path: commun.etats.reconnexion
class _Traductions$commun$etats$reconnexion$ar extends Traductions$commun$etats$reconnexion$fr {
	_Traductions$commun$etats$reconnexion$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'جارٍ إعادة الاتصال';
	@override String get phrase => 'محاولة اتصال جديدة جارية.';
}

// Path: commun.etats.echecServeur
class _Traductions$commun$etats$echecServeur$ar extends Traductions$commun$etats$echecServeur$fr {
	_Traductions$commun$etats$echecServeur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'تعذّر تحميل هذه المعلومات';
	@override String get phrase => 'لم يكتمل التحميل. أعد المحاولة بعد لحظة.';
}

// Path: commun.etats.introuvable
class _Traductions$commun$etats$introuvable$ar extends Traductions$commun$etats$introuvable$fr {
	_Traductions$commun$etats$introuvable$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'هذه الصفحة غير موجودة';
	@override String get phrase => 'ربما الرابط ناقص، أو لم تعد الصفحة موجودة.';
}

// Path: commun.etats.accesRefuse
class _Traductions$commun$etats$accesRefuse$ar extends Traductions$commun$etats$accesRefuse$fr {
	_Traductions$commun$etats$accesRefuse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ليس لديك إذن بالوصول إلى هذه الصفحة';
	@override String get phrase => 'هذا المحتوى غير مفتوح لحسابك.';
}

// Path: commun.etats.sessionExpiree
class _Traductions$commun$etats$sessionExpiree$ar extends Traductions$commun$etats$sessionExpiree$fr {
	_Traductions$commun$etats$sessionExpiree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'انتهت جلستك';
	@override String get phrase => 'سجّل الدخول من جديد للمتابعة.';
}

// Path: commun.etats.dossierEnAttente
class _Traductions$commun$etats$dossierEnAttente$ar extends Traductions$commun$etats$dossierEnAttente$fr {
	_Traductions$commun$etats$dossierEnAttente$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ملفك قيد الانتظار';
	@override String get phrase => 'بقيت خطوة قبل فتح هذه المساحة.';
}

// Path: commun.etats.aucunResultat
class _Traductions$commun$etats$aucunResultat$ar extends Traductions$commun$etats$aucunResultat$fr {
	_Traductions$commun$etats$aucunResultat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'لا نتائج';
	@override String get phrase => 'لا شيء مطابق الآن.';
}

// Path: commun.etats.permissionRefusee
class _Traductions$commun$etats$permissionRefusee$ar extends Traductions$commun$etats$permissionRefusee$fr {
	_Traductions$commun$etats$permissionRefusee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإذن مرفوض';
	@override String get phrase => 'دون هذا الإذن، لا يمكن فتح هذه الوظيفة. يمكنك تغييره في إعدادات جهازك.';
}

// Path: commun.etats.ressourceExpiree
class _Traductions$commun$etats$ressourceExpiree$ar extends Traductions$commun$etats$ressourceExpiree$fr {
	_Traductions$commun$etats$ressourceExpiree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'هذا المحتوى لم يعد متاحًا';
	@override String get phrase => 'سُحب، أو انتهى الوصول إليه.';
}

// Path: commun.etats.indisponible
class _Traductions$commun$etats$indisponible$ar extends Traductions$commun$etats$indisponible$fr {
	_Traductions$commun$etats$indisponible$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'غير متاح بعد';
	@override String get phrase => 'هذه الوظيفة غير مفتوحة بعد.';
}

// Path: commun.etats.actions
class _Traductions$commun$etats$actions$ar extends Traductions$commun$etats$actions$fr {
	_Traductions$commun$etats$actions$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get reessayer => 'إعادة المحاولة';
	@override String get retourAccueil => 'العودة إلى الرئيسية';
	@override String get seConnecter => 'تسجيل الدخول';
	@override String get seReconnecter => 'تسجيل الدخول من جديد';
	@override String get voirDossier => 'عرض ملفي';
	@override String get reinitialiserFiltres => 'إعادة ضبط عوامل التصفية';
	@override String get revenir => 'الرجوع';
}

// Path: classe.entree.annonce
class _Traductions$classe$entree$annonce$ar extends Traductions$classe$entree$annonce$fr {
	_Traductions$classe$entree$annonce$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aVenir => 'حصة قادمة';
	@override String get fenetreOuverte => 'القاعة مفتوحة';
	@override String get attente => 'أنت في القاعة';
}

// Path: classe.entree.demo
class _Traductions$classe$entree$demo$ar extends Traductions$classe$entree$demo$fr {
	_Traductions$classe$entree$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الدخول إلى الفصل';
	@override String get mention => 'عرض تجريبي';
	@override String get intro => 'بيانات وهمية، دون أي اتصال بالخادم. كل رابط يُظهر ما تقوله خانة الدخول لدور ولحظة.';
	@override late final _Traductions$classe$entree$demo$roles$ar roles = _Traductions$classe$entree$demo$roles$ar._(_root);
	@override late final _Traductions$classe$entree$demo$etats$ar etats = _Traductions$classe$entree$demo$etats$ar._(_root);
	@override String get formeBouton => 'الشكل: زر';
	@override String get formeLigne => 'الشكل: سطر حالة';
	@override String lecteur({required Object texte}) => 'قارئ الشاشة: ⁨${texte}⁩';
	@override String annonce({required Object texte}) => 'الإعلان: ⁨${texte}⁩';
	@override String detail({required Object texte}) => 'التفاصيل: ⁨${texte}⁩';
	@override String get retour => 'العودة إلى القائمة';
}

// Path: classe.observation.motif
class _Traductions$classe$observation$motif$ar extends Traductions$classe$observation$motif$fr {
	_Traductions$classe$observation$motif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get visitesEpuisees => 'استخدمت زياراتك لهذه الحصة.';
	@override String get tempsEpuise => 'نفد وقت متابعتك لهذه الحصة.';
	@override String get seanceNonCommencee => 'تُفتح المتابعة حين تبدأ الحصة.';
	@override String get seanceTerminee => 'انتهت الحصة.';
	@override String get seanceNonTenue => 'هذه الحصة لا تُعقد: لا شيء للمتابعة.';
	@override String get horsFenetre => 'القاعة غير مفتوحة في هذا الوقت.';
	@override String get observationDesactivee => 'المتابعة مغلقة لهذا الفصل.';
	@override String get lienAbsent => 'لا طالب من أسرتك مرتبط بهذه الحصة.';
	@override String enfantAbsent({required Object prenom}) => 'تنتظر المتابعة وصول ⁨${prenom}⁩.';
	@override String presenceEnVerification({required Object prenom}) => 'جارٍ التحقق من حضور ⁨${prenom}⁩.';
	@override String get visiteDejaOuverte => 'زيارة مفتوحة بالفعل، على هذا الجهاز أو على غيره.';
	@override String get garantieServeurAbsente => 'متابعة الحصص غير مفتوحة بعد.';
	@override String get reseau => 'تعذّر التحقق من توفر المتابعة.';
	@override String get capaciteAbsente => 'المتابعة غير متاحة الآن.';
}

// Path: classe.pageTravail.statut
class _Traductions$classe$pageTravail$statut$ar extends Traductions$classe$pageTravail$statut$fr {
	_Traductions$classe$pageTravail$statut$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aFaire => 'للإنجاز';
	@override String get enCours => 'بدأ';
	@override String get fait => 'منجز';
	@override String get expire => 'فات الموعد';
}

// Path: classe.pageCatalogue.etat
class _Traductions$classe$pageCatalogue$etat$ar extends Traductions$classe$pageCatalogue$etat$fr {
	_Traductions$classe$pageCatalogue$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouverte => 'مفتوح';
	@override String get complete => 'مكتمل';
	@override String get listeAttente => 'قائمة الانتظار';
}

// Path: classe.pageCatalogue.resultat
class _Traductions$classe$pageCatalogue$resultat$ar extends Traductions$classe$pageCatalogue$resultat$fr {
	_Traductions$classe$pageCatalogue$resultat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get inscritTitre => 'تم تأكيد التسجيل';
	@override String inscritPhrase({required Object prenom, required Object classe}) => 'ينضم ⁨${prenom}⁩ إلى ⁨${classe}⁩.';
	@override String get voirClasse => 'عرض الفصل';
	@override String get validationTitre => 'أُرسل الطلب';
	@override String validationPhrase({required Object prenom, required Object classe}) => 'ما زال على الأكاديمية اعتماد تسجيل ⁨${prenom}⁩ في ⁨${classe}⁩.';
	@override String get listeAttenteTitre => 'التسجيل في قائمة الانتظار';
	@override String listeAttentePhrase({required Object prenom, required Object classe}) => '⁨${prenom}⁩ في قائمة انتظار ⁨${classe}⁩. لم يُحجز أي مقعد حتى الآن.';
	@override String get refuseTitre => 'لم يُقبل التسجيل';
	@override String refusePhrase({required Object prenom}) => 'لم يُحجز أي مقعد لـ⁨${prenom}⁩. يمكنك اختيار فصل آخر.';
	@override String get autresClasses => 'عرض الفصول الأخرى';
	@override String get retourAccueil => 'العودة إلى الرئيسية';
}

// Path: salle.preparation.demo
class _Traductions$salle$preparation$demo$ar extends Traductions$salle$preparation$demo$fr {
	_Traductions$salle$preparation$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get section => 'استعداد المعلم';
	@override String get pret => 'جاهز';
	@override String get reseauFaible => 'شبكة ضعيفة';
	@override String get microAbsent => 'لا يوجد ميكروفون';
	@override String get permissionRefusee => 'الإذن مرفوض';
}

// Path: salle.preparation.eleve
class _Traductions$salle$preparation$eleve$ar extends Traductions$salle$preparation$eleve$fr {
	_Traductions$salle$preparation$eleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get verification => 'نتحقق من جهازك…';
	@override String get pret => 'كل شيء جاهز';
	@override String get audio => 'الصوت';
	@override String get acces => 'الدخول إلى الفصل';
	@override String get accesOk => 'يمكنك الدخول';
	@override String get accesAttente => 'في انتظار الاتصال';
	@override String get microCoupe => 'ستدخل والميكروفون مغلق.';
	@override String get microInaccessible => 'لا يمكن الوصول إلى الميكروفون';
	@override String get microInaccessibleDetail => 'لن يسمعك أحد في الفصل ما دام الوصول إلى الميكروفون محظورًا.';
	@override String get autoriserMicro => 'السماح بالميكروفون';
	@override late final _Traductions$salle$preparation$eleve$guidee$ar guidee = _Traductions$salle$preparation$eleve$guidee$ar._(_root);
	@override late final _Traductions$salle$preparation$eleve$demo$ar demo = _Traductions$salle$preparation$eleve$demo$ar._(_root);
}

// Path: salle.seance.outils
class _Traductions$salle$seance$outils$ar extends Traductions$salle$seance$outils$fr {
	_Traductions$salle$seance$outils$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'أدوات التدريس';
	@override String get pointeur => 'المؤشر';
	@override String get marquer => 'وضع علامة';
	@override String get masquer => 'إخفاء';
	@override String get annoter => 'كتابة ملاحظات';
}

// Path: salle.seance.rail
class _Traductions$salle$seance$rail$ar extends Traductions$salle$seance$rail$fr {
	_Traductions$salle$seance$rail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get navigation => 'التنقل';
	@override String get marque => 'Rewayah';
	@override String get sousMarque => 'Academy';
	@override String get journee => 'يومي';
	@override String get classes => 'الفصول';
	@override String get ressources => 'الموارد';
	@override String get profil => 'الملف الشخصي';
}

// Path: salle.seance.panneauSupports
class _Traductions$salle$seance$panneauSupports$ar extends Traductions$salle$seance$panneauSupports$fr {
	_Traductions$salle$seance$panneauSupports$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get reprendre => 'استئناف';
	@override String get recents => 'المستخدمة مؤخرًا';
	@override String get ressourcesClasse => 'موارد الفصل';
	@override String get voirTout => 'عرض الكل';
	@override String get ouvrir => 'فتح';
	@override String ouvrirSupport({required Object titre}) => 'فتح ⁨${titre}⁩';
	@override String get voirBibliotheque => 'عرض المكتبة كاملة';
}

// Path: salle.seance.fiche
class _Traductions$salle$seance$fiche$ar extends Traductions$salle$seance$fiche$fr {
	_Traductions$salle$seance$fiche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucuneSeanceSemaine => 'لا حصص هذا الأسبوع';
	@override String get uneSeanceSemaine => 'حصة واحدة هذا الأسبوع';
	@override String seancesSemaine({required Object nombre}) => 'عدد الحصص هذا الأسبوع: ⁨${nombre}⁩';
}

// Path: salle.seance.commandes
class _Traductions$salle$seance$commandes$ar extends Traductions$salle$seance$commandes$fr {
	_Traductions$salle$seance$commandes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get declencheur => 'التحكم';
	@override String get declencheurSemantique => 'فتح عناصر التحكم في المادة والسبورة';
	@override String get titre => 'عناصر التحكم';
	@override String get reduire => 'تصغير';
	@override String get reduireSemantique => 'تصغير عناصر التحكم';
	@override String get ongletSupport => 'المادة';
	@override String get ongletOutils => 'الأدوات';
	@override String get bibliotheque => 'المكتبة';
	@override String get affichageSupport => 'المادة';
	@override String get affichageAvecNotes => 'مع الملاحظات';
	@override String get affichageTableau => 'السبورة';
	@override String get lecture => 'القراءة';
	@override String get ajuster => 'ملاءمة الشاشة';
	@override String get affichage => 'العرض';
	@override String get focus => 'التركيز';
	@override String get focusSemantique => 'التركيز، تكبير المحتوى وتصغير اللوحات';
	@override String get quitterFocus => 'الخروج من التركيز';
}

// Path: salle.seance.bibliotheque
class _Traductions$salle$seance$bibliotheque$ar extends Traductions$salle$seance$bibliotheque$fr {
	_Traductions$salle$seance$bibliotheque$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'المادة التي تختارها تُفتح لك وحدك. يبقى الفصل على المادة الحالية حتى «عرض على الفصل».';
	@override String get apercu => 'معاينة خاصة';
	@override String get apercuClasse => 'ما زال الطلاب يرون المادة الحالية.';
	@override String get presenter => 'عرض على الفصل';
	@override String get revenir => 'العودة إلى المواد';
	@override String get ouverture => 'جارٍ فتح المادة…';
	@override String get echec => 'تعذّر فتح الملف.';
	@override String get echecDetail => 'تعذّر تحميل ملف هذه المادة. أعد المحاولة، أو عد إلى المواد لاختيار مادة أخرى.';
}

// Path: salle.seance.surface
class _Traductions$salle$seance$surface$ar extends Traductions$salle$seance$surface$fr {
	_Traductions$salle$seance$surface$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucunSupport => 'اختر مادة أو اكتب على السبورة.';
	@override String page({required Object titre, required Object page, required Object pages}) => '⁨${titre}⁩، الصفحة ⁨${page}⁩ من ⁨${pages}⁩';
	@override String get supportMasque => 'السبورة، المادة مخفية';
}

// Path: salle.seance.capsule
class _Traductions$salle$seance$capsule$ar extends Traductions$salle$seance$capsule$fr {
	_Traductions$salle$seance$capsule$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String avatar({required Object nom}) => 'عرض معلومات ⁨${nom}⁩';
	@override String get controlePossible => 'المراقبة ممكنة. عرض المعلومات';
	@override String get controleActif => 'المراقبة جارية. عرض المعلومات';
	@override String get enregistrementActif => 'التسجيل جارٍ';
}

// Path: salle.seance.contexte
class _Traductions$salle$seance$contexte$ar extends Traductions$salle$seance$contexte$fr {
	_Traductions$salle$seance$contexte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'معلومات الحصة';
	@override String get reseau => 'الشبكة';
	@override String get detailReseau => 'تفاصيل الشبكة';
	@override String get enregistrementActif => 'التسجيل جارٍ';
	@override String get controle => 'المراقبة';
	@override String get controlePossible => 'المراقبة ممكنة';
	@override String get controleActif => 'المراقبة جارية';
	@override String get controlePossibleDetail => 'قد تجري زيارة مراقبة. هذا لا يعني أن أحدًا يتابع الآن.';
	@override String get controleActifDetail => 'تجري زيارة مراقبة الآن.';
	@override String get reduire => 'تصغير';
	@override String get reduireParticipants => 'تصغير المشاركين';
	@override String get reduireInformations => 'تصغير المعلومات';
}

// Path: salle.seance.demo
class _Traductions$salle$seance$demo$ar extends Traductions$salle$seance$demo$fr {
	_Traductions$salle$seance$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'قاعة العرض التجريبي';
	@override String get intro => 'بيانات وهمية، دون خادم. اختر دورًا وحالة.';
	@override late final _Traductions$salle$seance$demo$groupes$ar groupes = _Traductions$salle$seance$demo$groupes$ar._(_root);
	@override late final _Traductions$salle$seance$demo$roles$ar roles = _Traductions$salle$seance$demo$roles$ar._(_root);
	@override late final _Traductions$salle$seance$demo$etats$ar etats = _Traductions$salle$seance$demo$etats$ar._(_root);
	@override late final _Traductions$salle$seance$demo$tb$ar tb = _Traductions$salle$seance$demo$tb$ar._(_root);
}

// Path: salle.seance.statut
class _Traductions$salle$seance$statut$ar extends Traductions$salle$seance$statut$fr {
	_Traductions$salle$seance$statut$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get connecte => 'متصل';
	@override String get pasEncoreConnecte => 'لم يتصل بعد';
	@override String get connexionInterrompue => 'انقطع الاتصال';
}

// Path: salle.fin.enseignant
class _Traductions$salle$fin$enseignant$ar extends Traductions$salle$fin$enseignant$fr {
	_Traductions$salle$fin$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get terminee => 'منتهية';
	@override String get phrase => 'دفتر المتابعة جاهز بمعلومات الحصة.';
	@override String get recapitulatif => 'ملخص الحصة';
	@override String get fin => 'النهاية';
	@override String connectes({required Object n}) => 'الطلاب المتصلون: ⁨${n}⁩';
	@override String unConnecte({required Object n}) => 'الطلاب المتصلون: ⁨${n}⁩';
	@override String inscrits({required Object n}) => 'من أصل ⁨${n}⁩';
	@override String unInscrit({required Object n}) => 'من ⁨${n}⁩ مسجَّل';
	@override String get cahierSeance => 'دفتر المتابعة';
	@override String get cahierACompleter => 'دفتر المتابعة بانتظار الإكمال';
	@override String get ouvrirCahier => 'فتح دفتر المتابعة';
	@override String get revenirJournee => 'العودة إلى يومي';
	@override String get erreurCahier => 'تعذّر فتح دفتر المتابعة الآن. أعد المحاولة بعد لحظة.';
}

// Path: enseignant.journee.absence
class _Traductions$enseignant$journee$absence$ar extends Traductions$enseignant$journee$absence$fr {
	_Traductions$enseignant$journee$absence$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouvrir => 'الإبلاغ عن غيابي في هذه الحصة';
	@override String get ouvrirContexte => 'سيُبحث عن بديل لطلابك.';
	@override String get titre => 'لن تستطيع تولي هذه الحصة؟';
	@override String get cleDate => 'التاريخ';
	@override String get notice => 'يبقى إسنادك إلى الفصل كما هو.';
	@override String get declarer => 'التصريح بغيابي';
	@override String get echec => 'لم يكتمل الطلب. أعد المحاولة بعد لحظة.';
	@override late final _Traductions$enseignant$journee$absence$etats$ar etats = _Traductions$enseignant$journee$absence$etats$ar._(_root);
}

// Path: enseignant.journee.remplacement
class _Traductions$enseignant$journee$remplacement$ar extends Traductions$enseignant$journee$remplacement$fr {
	_Traductions$enseignant$journee$remplacement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'تولي هذا الاستخلاف؟';
	@override String get assurer => 'تولي هذا الاستخلاف';
	@override String get pasCetteFois => 'ليس هذه المرة';
}

// Path: enseignant.signalement.categories
class _Traductions$enseignant$signalement$categories$ar extends Traductions$enseignant$signalement$categories$fr {
	_Traductions$enseignant$signalement$categories$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get pedagogique => 'مشكلة تعليمية';
	@override String get presence => 'الحضور';
	@override String get technique => 'تقنية';
	@override String get changement => 'تغيير';
	@override String get autre => 'أخرى';
}

// Path: compte.tuteur.identite
class _Traductions$compte$tuteur$identite$ar extends Traductions$compte$tuteur$identite$fr {
	_Traductions$compte$tuteur$identite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get statutValide => 'الحساب معتمَد';
	@override String get statutProvisoire => 'الملف للإكمال';
	@override String get nomInconnu => 'صاحب الحساب';
	@override String get courrielAbsent => 'عنوان الدخول غير متوفر';
	@override String get connexionLien => 'الدخول برابط يصل بالبريد الإلكتروني';
	@override String get connexionGoogle => 'الدخول بحساب Google';
	@override String get connexionInconnue => 'طريقة الدخول غير محددة';
}

// Path: compte.tuteur.acces
class _Traductions$compte$tuteur$acces$ar extends Traductions$compte$tuteur$acces$fr {
	_Traductions$compte$tuteur$acces$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الوصول والمدفوعات';
	@override String get resume => 'حالة كل ملف طالب وموعد انتهائه';
	@override String get pastilleActif => 'الوصول ساري';
	@override String get pastilleExpire => 'انتهى الوصول';
	@override String get ligne => 'وصول ملفات الطلاب';
	@override String get paiements => 'المدفوعات والإيصالات';
}

// Path: compte.tuteur.securite
class _Traductions$compte$tuteur$securite$ar extends Traductions$compte$tuteur$securite$fr {
	_Traductions$compte$tuteur$securite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الدخول والأمان';
	@override String get methode => 'طريقة الدخول';
	@override String get methodeLien => 'رابط بالبريد الإلكتروني';
	@override String get methodeGoogle => 'Google';
}

// Path: compte.tuteur.informations
class _Traductions$compte$tuteur$informations$ar extends Traductions$compte$tuteur$informations$fr {
	_Traductions$compte$tuteur$informations$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المعلومات الشخصية';
	@override String get resume => 'الاسم وعنوان الدخول واللغة والمنطقة الزمنية';
	@override String langueFuseau({required Object ville}) => 'العربية · ⁨${ville}⁩';
	@override String get consulter => 'عرض معلوماتي';
}

// Path: compte.tuteur.foyer
class _Traductions$compte$tuteur$foyer$ar extends Traductions$compte$tuteur$foyer$fr {
	_Traductions$compte$tuteur$foyer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'أسرتي';
	@override String get aucun => 'لا ملف طالب حتى الآن';
	@override String get un => 'ملف طالب واحد';
	@override String plusieurs({required Object nombre}) => '⁨${nombre}⁩ ملفات طلاب';
	@override String get legende => 'ملفات الطلاب وأجهزة الأسرة';
	@override String get creerMonProfil => 'إنشاء ملفي كطالب';
}

// Path: compte.tuteur.aide
class _Traductions$compte$tuteur$aide$ar extends Traductions$compte$tuteur$aide$fr {
	_Traductions$compte$tuteur$aide$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المساعدة والدعم';
	@override String get ligne => 'المساعدة والتواصل';
	@override String get legal => 'المعلومات القانونية';
}

// Path: compte.tuteur.deconnexion
class _Traductions$compte$tuteur$deconnexion$ar extends Traductions$compte$tuteur$deconnexion$fr {
	_Traductions$compte$tuteur$deconnexion$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get question => 'تسجيل الخروج من Rewayah؟';
	@override String get consequence => 'ستحتاج إلى تسجيل الدخول من جديد للعودة إلى هذا الجهاز. تبقى أجهزتك الأخرى متصلة.';
	@override String get confirmer => 'تسجيل خروجي';
	@override String get echec => 'لم يكتمل تسجيل الخروج. تحقّق من اتصالك، ثم أعد المحاولة.';
}

// Path: compte.tuteur.pageInformations
class _Traductions$compte$tuteur$pageInformations$ar extends Traductions$compte$tuteur$pageInformations$fr {
	_Traductions$compte$tuteur$pageInformations$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المعلومات الشخصية';
	@override String get prenom => 'الاسم';
	@override String get nom => 'اللقب';
	@override String get courriel => 'عنوان الدخول';
	@override String get langue => 'لغة الواجهة';
	@override String get fuseau => 'المنطقة الزمنية للحصص';
	@override String get fuseauIndisponible => 'غير متاح الآن';
	@override String get note => 'تحتفظ الأكاديمية بهذه المعلومات. لا تُعدَّل من التطبيق بعد.';
}

// Path: compte.tuteur.pageSecurite
class _Traductions$compte$tuteur$pageSecurite$ar extends Traductions$compte$tuteur$pageSecurite$fr {
	_Traductions$compte$tuteur$pageSecurite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الدخول والأمان';
	@override String get sousTitre => 'كيف تدخل إلى حسابك.';
	@override String get methode => 'طريقة الدخول';
	@override String get adresse => 'عنوان الدخول';
	@override String get appareils => 'الأجهزة المتصلة بحسابك لا تُعرض في التطبيق بعد.';
	@override String get deconnexion => 'لإغلاق جلسة هذا الجهاز، استخدم «تسجيل الخروج» أسفل «حسابي».';
}

// Path: compte.tuteur.pageAcces
class _Traductions$compte$tuteur$pageAcces$ar extends Traductions$compte$tuteur$pageAcces$fr {
	_Traductions$compte$tuteur$pageAcces$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'وصول ملفات الطلاب';
	@override String get sousTitre => 'حالة وصول كل ملف طالب.';
	@override String get sansEcheance => 'دون تاريخ انتهاء';
	@override String jusqua({required Object date}) => 'مفتوح حتى ⁨${date}⁩';
	@override String expire({required Object date}) => 'انتهى في ⁨${date}⁩';
	@override String get pastilleActif => 'ساري';
	@override String get pastilleExpire => 'منتهٍ';
	@override String get aucunTitre => 'لا ملف طالب';
	@override String get aucunePhrase => 'سيظهر هنا وصول كل ملف طالب.';
	@override String get titulaire => 'حسابك الرئيسي ليس له موعد انتهاء خاص: يُضبط الوصول لكل ملف على حدة.';
}

// Path: compte.tuteur.pagePaiements
class _Traductions$compte$tuteur$pagePaiements$ar extends Traductions$compte$tuteur$pagePaiements$fr {
	_Traductions$compte$tuteur$pagePaiements$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المدفوعات والإيصالات';
	@override String get indisponibleTitre => 'المدفوعات غير قابلة للاطلاع بعد';
	@override String get indisponiblePhrase => 'سجل المدفوعات والإيصالات ووسائل الدفع غير متاحة في التطبيق بعد. لا يُطلب منك أي دفع هنا.';
	@override String get aucunTitre => 'لا دفعة مسجَّلة';
	@override String get aucunePhrase => 'ستظهر هنا المدفوعات التي تسجّلها الأكاديمية.';
	@override String paiementDu({required Object date}) => 'دفعة ⁨${date}⁩';
	@override String get justificatif => 'الإيصال متاح';
}

// Path: compte.tuteur.pagePreferences
class _Traductions$compte$tuteur$pagePreferences$ar extends Traductions$compte$tuteur$pagePreferences$fr {
	_Traductions$compte$tuteur$pagePreferences$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'التفضيلات';
	@override String get sousTitre => 'خصّص تجربتك على هذا الجهاز.';
	@override String get apparence => 'المظهر';
	@override String get apparenceDetail => 'المظهر والراحة البصرية';
	@override String get langue => 'اللغة والمنطقة';
	@override String get notifications => 'الإشعارات';
	@override String get notificationsDetail => 'غير متاحة في التطبيق بعد';
}

// Path: compte.tuteur.pageApparence
class _Traductions$compte$tuteur$pageApparence$ar extends Traductions$compte$tuteur$pageApparence$fr {
	_Traductions$compte$tuteur$pageApparence$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المظهر';
	@override String get sousTitre => 'مطبَّق على هذا الجهاز.';
	@override String get theme => 'مظهر التطبيق';
	@override String get themeDetail => 'خصّص مظهر Rewayah.';
	@override String get confort => 'الراحة البصرية';
	@override String get animations => 'الحركة';
	@override String get animationsDetail => 'تقلّ حين يطلب جهازك ذلك';
	@override String get texte => 'حجم النص';
	@override String get texteDetail => 'يتبع حجم النظام';
}

// Path: compte.tuteur.pageAide
class _Traductions$compte$tuteur$pageAide$ar extends Traductions$compte$tuteur$pageAide$fr {
	_Traductions$compte$tuteur$pageAide$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المساعدة والدعم';
	@override String get indisponibleTitre => 'المساعدة غير متاحة بعد';
	@override String get indisponiblePhrase => 'الأسئلة الشائعة والتواصل مع الأكاديمية غير مفتوحة في التطبيق بعد.';
	@override String get canalCourriel => 'بريد الأكاديمية الإلكتروني';
	@override String get canalLien => 'صفحة مساعدة الأكاديمية';
	@override String get aucunCanal => 'لا قناة مساعدة منشورة الآن.';
}

// Path: compte.tuteur.pageLegal
class _Traductions$compte$tuteur$pageLegal$ar extends Traductions$compte$tuteur$pageLegal$fr {
	_Traductions$compte$tuteur$pageLegal$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المعلومات القانونية';
	@override String get documents => 'الوثائق المقبولة';
	@override String get conditionsTuteur => 'شروط وليّ الأمر';
	@override String get contratEnseignant => 'عقد المعلم';
	@override String get accuseEnregistrement => 'الإقرار بتسجيل الدروس';
	@override String acceptation({required Object version, required Object date}) => 'الإصدار ⁨${version}⁩، مقبول في ⁨${date}⁩';
	@override String get aucunTitre => 'لا وثيقة مقبولة';
	@override String get aucun => 'لا وثيقة مقبولة مسجَّلة لهذا الحساب.';
	@override String get lectureSeule => 'الوثيقة المقبولة لا تُعدَّل.';
	@override String get textes => 'الشروط والخصوصية';
	@override String get textesIndisponibles => 'الشروط العامة وسياسة الخصوصية والإشعارات القانونية غير قابلة للاطلاع في التطبيق بعد.';
}

// Path: tc.bibliotheque.sections
class _Traductions$tc$bibliotheque$sections$ar extends Traductions$tc$bibliotheque$sections$fr {
	_Traductions$tc$bibliotheque$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'المواد المعروضة';
	@override String get continuer => 'متابعة';
	@override String get pourCeGroupe => 'لهذا الفصل';
	@override String get recents => 'المستخدمة مؤخرًا';
	@override String get tousLesSupports => 'كل المواد';
	@override String get resultats => 'النتائج';
}

// Path: tc.bibliotheque.filtre
class _Traductions$tc$bibliotheque$filtre$ar extends Traductions$tc$bibliotheque$filtre$fr {
	_Traductions$tc$bibliotheque$filtre$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get type => 'النوع';
	@override String get disponibilite => 'التوفر';
}

// Path: tc.bibliotheque.vide
class _Traductions$tc$bibliotheque$vide$ar extends Traductions$tc$bibliotheque$vide$fr {
	_Traductions$tc$bibliotheque$vide$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'لا مادة منشورة حتى الآن';
	@override String get invitation => 'سيضع معلموك هنا مواد دروسك.';
}

// Path: tc.bibliotheque.aucunResultat
class _Traductions$tc$bibliotheque$aucunResultat$ar extends Traductions$tc$bibliotheque$aucunResultat$fr {
	_Traductions$tc$bibliotheque$aucunResultat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'لا مادة مطابقة';
	@override String get invitation => 'جرّب كلمة أخرى، أو خفّف عوامل التصفية.';
}

// Path: tc.bibliotheque.indisponible
class _Traductions$tc$bibliotheque$indisponible$ar extends Traductions$tc$bibliotheque$indisponible$fr {
	_Traductions$tc$bibliotheque$indisponible$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'المكتبة غير متاحة مؤقتًا';
	@override String get action => 'إعادة المحاولة';
}

// Path: tc.bibliotheque.introuvable
class _Traductions$tc$bibliotheque$introuvable$ar extends Traductions$tc$bibliotheque$introuvable$fr {
	_Traductions$tc$bibliotheque$introuvable$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'هذه المادة غير مفتوحة لك';
	@override String get invitation => 'ربما سُحبت، أو هي مخصصة لفصل آخر. يمكن لمعلمك أن يعيد فتحها لك.';
}

// Path: tc.bibliotheque.offline
class _Traductions$tc$bibliotheque$offline$ar extends Traductions$tc$bibliotheque$offline$fr {
	_Traductions$tc$bibliotheque$offline$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aTelecharger => 'للتنزيل';
	@override String get enCours => 'جارٍ التنزيل';
	@override String get enCache => 'في الذاكرة المؤقتة';
	@override String get telecharge => 'تم التنزيل';
	@override String get indisponible => 'غير متاحة دون اتصال';
}

// Path: tc.bibliotheque.type
class _Traductions$tc$bibliotheque$type$ar extends Traductions$tc$bibliotheque$type$fr {
	_Traductions$tc$bibliotheque$type$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get quran => 'القرآن';
	@override String get texteStructure => 'نص';
	@override String get pdf => 'PDF';
	@override String get image => 'صورة';
	@override String get lecon => 'درس';
}

// Path: tc.bibliotheque.detail
class _Traductions$tc$bibliotheque$detail$ar extends Traductions$tc$bibliotheque$detail$fr {
	_Traductions$tc$bibliotheque$detail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المادة';
	@override String get capacites => 'ما تتيحه هذه المادة';
	@override String get niveaux => 'المستويات';
	@override String get sansVersion => 'لا نسخة منشورة: لا شيء للفتح الآن.';
	@override String get apercuIndisponible => 'معاينة هذا التنسيق غير متاحة بعد في التطبيق. يمكنك حفظ نسخة منه.';
	@override String get renduCoran => 'يُفتح القرآن في القارئ المخصص له.';
}

// Path: tc.bibliotheque.action
class _Traductions$tc$bibliotheque$action$ar extends Traductions$tc$bibliotheque$action$fr {
	_Traductions$tc$bibliotheque$action$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get telecharger => 'إتاحتها دون اتصال';
	@override String get liberer => 'تحرير المساحة';
	@override String get enregistrerCopie => 'حفظ نسخة';
}

// Path: tc.bibliotheque.message
class _Traductions$tc$bibliotheque$message$ar extends Traductions$tc$bibliotheque$message$fr {
	_Traductions$tc$bibliotheque$message$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get copieEnregistree => 'حُفظت النسخة';
	@override String get copieImpossible => 'هذه النسخة غير متاحة الآن';
	@override String get telechargementImpossible => 'هذه المادة غير متاحة دون اتصال بعد';
	@override String get horsLigneNonTelecharge => 'تتاح بعد تنزيلها أو عند عودة الاتصال';
	@override String get aucunTelechargement => 'لا ملف للتنزيل في هذه النسخة.';
}

// Path: tc.bibliotheque.classe
class _Traductions$tc$bibliotheque$classe$ar extends Traductions$tc$bibliotheque$classe$fr {
	_Traductions$tc$bibliotheque$classe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'اختيار مادة';
	@override String get sousTitre => 'المادة المختارة تحل محل المعروضة. يستمر الدرس.';
}

// Path: tc.groupe.enseignant
class _Traductions$tc$groupe$enseignant$ar extends Traductions$tc$groupe$enseignant$fr {
	_Traductions$tc$groupe$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sayyid => 'سيد';
	@override String get sayyida => 'سيدة';
	@override String get photoManquante => 'الصورة مطلوبة';
	@override String get photoManquanteDetail => 'لم تُسجَّل صورة المعلم بعد.';
}

// Path: tc.groupe.mesGroupes
class _Traductions$tc$groupe$mesGroupes$ar extends Traductions$tc$groupe$mesGroupes$fr {
	_Traductions$tc$groupe$mesGroupes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'فصولي';
	@override String get aucun => 'لا فصل حتى الآن';
	@override String get aucunDetail => 'ستضعك الأكاديمية في فصل حين يتوفر موعد يناسبك.';
}

// Path: tc.groupe.commun
class _Traductions$tc$groupe$commun$ar extends Traductions$tc$groupe$commun$fr {
	_Traductions$tc$groupe$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get erreur => 'تعذّرت قراءة فصولك';
	@override String get reessayer => 'إعادة المحاولة';
}

// Path: tc.groupe.carte
class _Traductions$tc$groupe$carte$ar extends Traductions$tc$groupe$carte$fr {
	_Traductions$tc$groupe$carte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String ouvrir({required Object libelle}) => 'فتح الفصل ⁨${libelle}⁩';
	@override String capacite({required Object membres, required Object seuil}) => '⁨${membres}⁩ من ⁨${seuil}⁩';
	@override String capacitePhrase({required Object membres, required Object seuil}) => '⁨${membres}⁩ طلاب من ⁨${seuil}⁩ مقاعد';
	@override String get complet => 'مكتمل';
	@override String get prochainCours => 'الدرس القادم';
	@override String get aucuneSeance => 'لا حصة مقررة';
	@override String get aucuneSeanceDetail => 'لم يُحدَّد جدول هذا الفصل بعد.';
	@override String duree({required Object valeur}) => 'المدة ⁨${valeur}⁩';
	@override String get dureeLibelle => 'المدة';
	@override String get rejoindre => 'انضمام';
}

// Path: tc.groupe.cours
class _Traductions$tc$groupe$cours$ar extends Traductions$tc$groupe$cours$fr {
	_Traductions$tc$groupe$cours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String coursEtNiveau({required Object cours, required Object niveau}) => '⁨${cours}⁩ · ⁨${niveau}⁩';
}

// Path: tc.groupe.temps
class _Traductions$tc$groupe$temps$ar extends Traductions$tc$groupe$temps$fr {
	_Traductions$tc$groupe$temps$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String dansMinutes({required Object minutes}) => 'الدرس بعد ⁨${minutes}⁩ دقيقة';
	@override String dansHeures({required Object heures, required Object minutes}) => 'الدرس بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د';
	@override String get imminent => 'الدرس وشيك';
	@override String salleOuverte({required Object reste}) => 'القاعة مفتوحة · ⁨${reste}⁩';
	@override String get salleOuverteCourt => 'القاعة مفتوحة';
	@override String get attente => 'أنت في القاعة. لم يبدأ الدرس بعد.';
	@override String get attenteDetail => 'وقت الانتظار هذا لا يُحتسب في حضورك.';
	@override String get enSalle => 'في القاعة';
	@override String resteMinutes({required Object minutes}) => 'المتبقي ⁨${minutes}⁩ د';
	@override String resteHeures({required Object heures, required Object minutes}) => 'المتبقي ⁨${heures}⁩ س ⁨${minutes}⁩ د';
	@override String enCours({required Object reste}) => 'حصة مباشرة · ⁨${reste}⁩';
	@override String get enDirect => 'مباشر';
	@override String get prolongee => 'الحصة ما زالت مباشرة';
	@override String get depassement => 'تجاوز الوقت';
	@override String get terminee => 'انتهى الدرس';
}

// Path: tc.groupe.duree
class _Traductions$tc$groupe$duree$ar extends Traductions$tc$groupe$duree$fr {
	_Traductions$tc$groupe$duree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String minutes({required Object minutes}) => '⁨${minutes}⁩ د';
	@override String heures({required Object heures}) => '⁨${heures}⁩ س';
	@override String heuresMinutes({required Object heures, required Object minutes}) => '⁨${heures}⁩ س ⁨${minutes}⁩ د';
}

// Path: tc.groupe.horloges
class _Traductions$tc$groupe$horloges$ar extends Traductions$tc$groupe$horloges$fr {
	_Traductions$tc$groupe$horloges$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get votreHeure => 'توقيتك';
	@override String chezEnseignant({required Object nomme}) => 'عند ⁨${nomme}⁩';
	@override String get heureGroupe => 'توقيت الفصل';
	@override String heureEtVille({required Object heure, required Object ville}) => '⁨${heure}⁩ ⁨${ville}⁩';
}

// Path: tc.groupe.dst
class _Traductions$tc$groupe$dst$ar extends Traductions$tc$groupe$dst$fr {
	_Traductions$tc$groupe$dst$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get j30 => 'تغيير التوقيت بعد شهر';
	@override String get j7 => 'تغيير التوقيت الأسبوع القادم';
	@override String get j1 => 'تغيير التوقيت غدًا';
	@override String detail({required Object avant, required Object apres}) => 'سينتقل درسك من ⁨${avant}⁩ إلى ⁨${apres}⁩.';
}

// Path: tc.groupe.session
class _Traductions$tc$groupe$session$ar extends Traductions$tc$groupe$session$fr {
	_Traductions$tc$groupe$session$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get conseilAppareil => 'يُنصح بجهاز لوحي أو حاسوب للدرس. الهاتف مدعوم أيضًا.';
}

// Path: tc.groupe.espace
class _Traductions$tc$groupe$espace$ar extends Traductions$tc$groupe$espace$fr {
	_Traductions$tc$groupe$espace$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get retour => 'فصولي';
	@override String get avantProchainCours => 'قبل الدرس القادم';
	@override String get aucuneAction => 'لا شيء للتحضير الآن';
	@override String get bibliotheque => 'المكتبة';
	@override String get bibliothequeVoirTout => 'عرض الكل';
	@override String get progression => 'التقدم';
	@override String get roster => 'طلاب الفصل';
	@override String get reprendreLeCours => 'استئناف الدرس';
	@override String get introuvable => 'هذا الفصل غير مفتوح لك';
	@override String get introuvableDetail => 'ربما أُغلق، أو يخص ملفًا آخر.';
}

// Path: tc.groupe.emplacement
class _Traductions$tc$groupe$emplacement$ar extends Traductions$tc$groupe$emplacement$fr {
	_Traductions$tc$groupe$emplacement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nonBranche => 'قريبًا';
	@override String get nonBrancheDetail => 'سيُربط هذا المحتوى بهذه المساحة قريبًا.';
}

// Path: tc.coran.modes
class _Traductions$tc$coran$modes$ar extends Traductions$tc$coran$modes$fr {
	_Traductions$tc$coran$modes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get mushaf => 'صفحة المصحف';
	@override String get verset => 'قراءة مكبَّرة';
	@override String get focus => 'التركيز';
	@override String get choisir => 'طريقة القراءة';
}

// Path: tc.coran.mushaf
class _Traductions$tc$coran$mushaf$ar extends Traductions$tc$coran$mushaf$fr {
	_Traductions$tc$coran$mushaf$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get coteDroite => 'الصفحة اليمنى';
	@override String get coteGauche => 'الصفحة اليسرى';
	@override String ouverture({required Object droite, required Object gauche}) => 'الصفحتان المفتوحتان ⁨${droite}⁩ و⁨${gauche}⁩';
}

// Path: tc.coran.fidelite
class _Traductions$tc$coran$fidelite$ar extends Traductions$tc$coran$fidelite$fr {
	_Traductions$tc$coran$fidelite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get approchee => 'تنسيق تقريبي';
	@override String get approcheeDetail => 'آيات هذه الصفحة هي بالضبط آيات صفحة مصحف المدينة. أما توزيعها على الأسطر فهو توزيع هذه الشاشة: لم يُستورد بعد تقسيم الأسطر في الطبعة.';
	@override String get fidele => 'تنسيق الطبعة';
}

// Path: tc.coran.zoom
class _Traductions$tc$coran$zoom$ar extends Traductions$tc$coran$zoom$fr {
	_Traductions$tc$coran$zoom$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get bride => 'التكبير محدود بالعرض: ما زاد عليه يقطع الكلمات.';
	@override String valeur({required Object pourcent}) => '⁨${pourcent}⁩ ٪';
	@override String get renvoiLectureAgrandie => 'لتكبير النص، انتقل إلى القراءة المكبَّرة: صفحة المصحف تحافظ على هيئتها.';
}

// Path: tc.coran.navigation
class _Traductions$tc$coran$navigation$ar extends Traductions$tc$coran$navigation$fr {
	_Traductions$tc$coran$navigation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الانتقال إلى';
	@override String get ouvrir => 'الانتقال إلى صفحة';
	@override String get champ => 'صفحة أو سورة أو جزء أو مرجع';
	@override String get indice => 'مثلًا 18، الكهف، الجزء 15، 2:255';
	@override String get limite => 'يشمل البحث أرقام الصفحات والمراجع وأسماء السور. البحث في نص القرآن غير متاح بعد.';
	@override String get aucunResultat => 'لم يُعثر على مرجع';
	@override String get aucunResultatDetail => 'جرّب رقم صفحة، أو اسم سورة، أو مرجعًا مثل 2:255.';
	@override String pageNumero({required Object page}) => 'الصفحة ⁨${page}⁩';
}

// Path: tc.coran.reprise
class _Traductions$tc$coran$reprise$ar extends Traductions$tc$coran$reprise$fr {
	_Traductions$tc$coran$reprise$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'استئناف الدرس';
	@override String groupeDetail({required Object page}) => 'كان الفصل في الصفحة ⁨${page}⁩';
}

// Path: tc.coran.focus
class _Traductions$tc$coran$focus$ar extends Traductions$tc$coran$focus$fr {
	_Traductions$tc$coran$focus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucunePlage => 'لا مقطع مُبرَز';
	@override String get aucunePlageDetail => 'يتبع التركيز المقطع الذي يحدده المعلم. خارج الفصل، يتمركز على الصفحة المفتوحة.';
	@override String get quitter => 'الخروج من التركيز';
}

// Path: tc.outils.dock
class _Traductions$tc$outils$dock$ar extends Traductions$tc$outils$dock$fr {
	_Traductions$tc$outils$dock$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الأدوات';
	@override String get deplacer => 'نقل الأدوات';
	@override late final _Traductions$tc$outils$dock$position$ar position = _Traductions$tc$outils$dock$position$ar._(_root);
	@override String get bibliotheque => 'المكتبة';
	@override String get focus => 'التركيز';
	@override String get marquer => 'وضع علامة';
	@override String get masquer => 'إخفاء';
	@override String get stylet => 'القلم';
	@override String get pointeur => 'المؤشر';
	@override String get revision => 'المراجعة';
}

// Path: tc.outils.intention
class _Traductions$tc$outils$intention$ar extends Traductions$tc$outils$intention$fr {
	_Traductions$tc$outils$intention$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aApprendre => 'للحفظ';
	@override String get aRevoir => 'للمراجعة';
	@override String get aRenforcer => 'للتثبيت';
	@override String get aEntretenir => 'للتعاهد';
	@override String get pourEvaluation => 'للتقييم';
}

// Path: tc.outils.trait
class _Traductions$tc$outils$trait$ar extends Traductions$tc$outils$trait$fr {
	_Traductions$tc$outils$trait$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get stylet => 'القلم';
	@override String get surligneur => 'تظليل';
	@override String get gomme => 'الممحاة';
	@override String get annuler => 'تراجع';
	@override String get plus => 'المزيد';
	@override String get ardoise => 'لوح الملاحظات، اختياري: يبقى الدرس مقروءًا دونه';
	@override String get effacerDernier => 'مسح آخر خط لي';
}

// Path: tc.outils.portee
class _Traductions$tc$outils$portee$ar extends Traductions$tc$outils$portee$fr {
	_Traductions$tc$outils$portee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get temporaire => 'وقت الشرح';
	@override String get seance => 'حتى نهاية الدرس';
	@override String get enregistree => 'الاحتفاظ بها دائمًا';
	@override String get aide => 'إلى متى نحتفظ بهذه الملاحظات؟';
}

// Path: tc.outils.marquer
class _Traductions$tc$outils$marquer$ar extends Traductions$tc$outils$marquer$fr {
	_Traductions$tc$outils$marquer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'وضع علامة على هذا المقطع';
	@override String get aide => 'اختر ما يحتاجه هذا المقطع.';
	@override String get retirer => 'إزالة العلامة';
}

// Path: tc.outils.revision
class _Traductions$tc$outils$revision$ar extends Traductions$tc$outils$revision$fr {
	_Traductions$tc$outils$revision$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'للتحضير';
	@override String get aide => 'يصبح المقطع المحدد عملًا للتحضير.';
	@override String get groupeEntier => 'الفصل كله';
	@override String get consigne => 'تعليمة قصيرة (اختياري)';
	@override String get creer => 'تكليف بالعمل';
	@override String get posee => 'تم التكليف بعمل للتحضير';
}

// Path: tc.outils.masquer
class _Traductions$tc$outils$masquer$ar extends Traductions$tc$outils$masquer$fr {
	_Traductions$tc$outils$masquer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get reveler => 'إظهار';
	@override String get refermer => 'إخفاء من جديد';
	@override String get tout => 'إظهار الكل';
}

// Path: tc.outils.focus
class _Traductions$tc$outils$focus$ar extends Traductions$tc$outils$focus$fr {
	_Traductions$tc$outils$focus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get quitter => 'الخروج من التركيز';
}

// Path: tc.outils.annotation
class _Traductions$tc$outils$annotation$ar extends Traductions$tc$outils$annotation$fr {
	_Traductions$tc$outils$annotation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ancrageDegrade => 'لا مرجع نصيًا لهذا المقطع: ستتبع الملاحظة الصفحة لا الكلمات.';
	@override String get horsPage => 'الملاحظات مخفية: مقطعها ليس على الشاشة.';
	@override String get aucuneSelection => 'حدّد مقطعًا أولًا.';
}

// Path: tc.classe.entete
class _Traductions$tc$classe$entete$ar extends Traductions$tc$classe$entete$fr {
	_Traductions$tc$classe$entete$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$classe$entete$titreEnseignant$ar titreEnseignant = _Traductions$tc$classe$entete$titreEnseignant$ar._(_root);
	@override String resteMinutes({required Object minutes}) => 'المتبقي ⁨${minutes}⁩ د';
	@override String resteHeuresMinutes({required Object heures, required Object minutes}) => 'المتبقي ⁨${heures}⁩ س ⁨${minutes}⁩ د';
	@override String get coursEnCours => 'الحصة ما زالت مباشرة';
	@override String get photoManquante => 'صورة المعلم غير موجودة';
}

// Path: tc.classe.roster
class _Traductions$tc$classe$roster$ar extends Traductions$tc$classe$roster$fr {
	_Traductions$tc$classe$roster$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الطلاب';
	@override String compteur({required Object presents, required Object attendus}) => 'الحاضرون: ⁨${presents}⁩ من أصل ⁨${attendus}⁩';
	@override String get indisponible => 'قائمة الطلاب غير متاحة';
	@override String get indisponibleDetail => 'تعذّرت قراءة حالات طلابك. يستمر الدرس.';
	@override String get vide => 'لا طالب مسجَّل';
	@override String get videDetail => 'لا طالب مسجَّل في هذه الحصة.';
	@override String ouvrirFiche({required Object prenom}) => 'فتح بطاقة ⁨${prenom}⁩';
	@override String places({required Object inscrits, required Object plafond}) => 'المقاعد: ⁨${inscrits}⁩ من ⁨${plafond}⁩';
}

// Path: tc.classe.etat
class _Traductions$tc$classe$etat$ar extends Traductions$tc$classe$etat$fr {
	_Traductions$tc$classe$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get inconnu => 'حالة غير معروفة';
	@override String get attendu => 'منتظَر';
	@override String get enConnexion => 'جارٍ الاتصال';
	@override String get present => 'حاضر';
	@override String get enRetard => 'متأخر';
	@override String get deconnecte => 'غير متصل';
	@override String get enReconnexion => 'جارٍ إعادة الاتصال';
	@override String get sorti => 'خرج';
	@override String get absent => 'غائب';
}

// Path: tc.classe.fiche
class _Traductions$tc$classe$fiche$ar extends Traductions$tc$classe$fiche$fr {
	_Traductions$tc$classe$fiche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get niveau => 'المستوى';
	@override String get objectif => 'الهدف الحالي';
	@override String get derniereSeance => 'آخر حصة';
	@override String page({required Object page}) => 'الصفحة ⁨${page}⁩';
	@override String travailEnCours({required Object nombre}) => 'العناصر: ⁨${nombre}⁩';
	@override String get aReprendre => 'للاستئناف';
	@override String get presenceRecente => 'الحضور الأخير';
	@override String assiduite({required Object presences, required Object total}) => 'الدروس: ⁨${presences}⁩ من ⁨${total}⁩';
	@override String get travailActuel => 'العمل الحالي';
	@override String get interfaceGuidee => 'وضع إمكانية الوصول';
	@override String get sansPedagogie => 'المتابعة التعليمية غير متاحة';
	@override String get sansPedagogieDetail => 'المسار والأهداف والعمل الجاري غير مفتوحة للمعلم بعد.';
}

// Path: tc.classe.action
class _Traductions$tc$classe$action$ar extends Traductions$tc$classe$action$fr {
	_Traductions$tc$classe$action$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get rappel => 'نداء هادئ';
	@override String get reciter => 'اختيار للتلاوة';
	@override String get noter => 'تدوين ملاحظة';
	@override String get signaler => 'الإبلاغ عن حاجة';
	@override String get contexte => 'فتح السياق';
}

// Path: tc.classe.rappel
class _Traductions$tc$classe$rappel$ar extends Traductions$tc$classe$rappel$fr {
	_Traductions$tc$classe$rappel$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get recu => 'المعلم يناديك';
	@override String get echec => 'تعذّر إرسال النداء';
	@override String get echecDroit => 'دخولك إلى هذه الحصة لا يسمح بنداء طالب';
	@override String cooldown({required Object secondes}) => 'تم النداء. مجددًا بعد ⁨${secondes}⁩ ث';
}

// Path: tc.classe.recitation
class _Traductions$tc$classe$recitation$ar extends Traductions$tc$classe$recitation$fr {
	_Traductions$tc$classe$recitation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'التلاوة';
	@override String actif({required Object prenom}) => 'التلاوة: ⁨${prenom}⁩';
	@override String get pastille => 'في التلاوة';
	@override String get suivants => 'بعد ذلك';
	@override String get personne => 'لا أحد يتلو';
	@override String get arreter => 'إيقاف التلاوة';
}

// Path: tc.classe.support
class _Traductions$tc$classe$support$ar extends Traductions$tc$classe$support$fr {
	_Traductions$tc$classe$support$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucun => 'لا مادة معروضة';
	@override String get aucunDetail => 'افتح المكتبة لعرض مادة على الفصل.';
	@override String get bibliotheque => 'المكتبة';
	@override String get bibliothequeAbsente => 'المكتبة غير موصولة';
	@override String get bibliothequeAbsenteDetail => 'سيتاح اختيار المادة بمجرد دمج الفهرس.';
}

// Path: tc.classe.commandes
class _Traductions$tc$classe$commandes$ar extends Traductions$tc$classe$commandes$fr {
	_Traductions$tc$classe$commandes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get micro => 'فتح الميكروفون';
	@override String get microFermer => 'إغلاق الميكروفون';
	@override String get camera => 'فتح الكاميرا';
	@override String get cameraFermer => 'إغلاق الكاميرا';
	@override String get microCoupe => 'الميكروفون مغلق';
	@override String get quitter => 'مغادرة';
	@override String get quitterQuestion => 'مغادرة الدرس؟';
	@override String get quitterConsequence => 'سيُسجَّل خروجك. يمكنك العودة ما دامت الحصة مفتوحة.';
	@override String get fermerBibliotheque => 'إغلاق المكتبة';
}

// Path: tc.classe.scene
class _Traductions$tc$classe$scene$ar extends Traductions$tc$classe$scene$fr {
	_Traductions$tc$classe$scene$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get vide => 'أنت وحدك في القاعة الآن';
	@override String get sansImage => 'دون صورة';
}

// Path: tc.classe.reseau
class _Traductions$tc$classe$reseau$ar extends Traductions$tc$classe$reseau$fr {
	_Traductions$tc$classe$reseau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get bon => 'الشبكة جيدة';
	@override String get mediocre => 'الشبكة غير مستقرة';
	@override String get perdu => 'انقطعت الشبكة';
}

// Path: tc.classe.attente
class _Traductions$tc$classe$attente$ar extends Traductions$tc$classe$attente$fr {
	_Traductions$tc$classe$attente$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get materiel => 'جارٍ التحقق من الميكروفون';
	@override String get ouverture => 'جارٍ فتح الدرس';
	@override String get connexion => 'جارٍ الاتصال بالدرس';
	@override String get refus => 'الدرس غير متاح الآن';
}

// Path: tc.classe.lien
class _Traductions$tc$classe$lien$ar extends Traductions$tc$classe$lien$fr {
	_Traductions$tc$classe$lien$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get instable => 'الاتصال غير مستقر';
	@override String get reconnexion => 'جارٍ إعادة الاتصال';
	@override String get retabli => 'عاد الاتصال';
	@override String get echec => 'انقطع الاتصال';
	@override String get retourDeSuspension => 'أوقف النظام الدرس مؤقتًا. جارٍ التحقق من الاتصال.';
}

// Path: tc.classe.barre
class _Traductions$tc$classe$barre$ar extends Traductions$tc$classe$barre$fr {
	_Traductions$tc$classe$barre$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'حصة مباشرة';
	@override String revenir({required Object groupe}) => 'العودة إلى درس ⁨${groupe}⁩';
}

// Path: tc.classe.prevol
class _Traductions$tc$classe$prevol$ar extends Traductions$tc$classe$prevol$fr {
	_Traductions$tc$classe$prevol$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'قبل فتح الدرس';
	@override String get microOk => 'تم العثور على ميكروفون';
	@override String get microAbsent => 'لا ميكروفون صالح';
	@override String get cameraOk => 'تم العثور على كاميرا';
	@override String get cameraAbsente => 'لا كاميرا. يبقى الدرس ممكنًا.';
	@override String get permissionRefusee => 'رُفض الوصول إلى الميكروفون. اسمح به لفتح الدرس.';
	@override String get reessayer => 'التحقق من جديد';
}

// Path: tc.classe.observation
class _Traductions$tc$classe$observation$ar extends Traductions$tc$classe$observation$fr {
	_Traductions$tc$classe$observation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String restant({required Object secondes}) => 'بقيت ⁨${secondes}⁩ ث';
}

// Path: tc.realtime.transport
class _Traductions$tc$realtime$transport$ar extends Traductions$tc$realtime$transport$fr {
	_Traductions$tc$realtime$transport$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get partage_indisponible => 'مشاركة المادة غير متاحة على هذا الخادم. يستمر الدرس، لكن الأجهزة الأخرى لن تتبع الصفحة.';
}

// Path: tc.realtime.etat
class _Traductions$tc$realtime$etat$ar extends Traductions$tc$realtime$etat$fr {
	_Traductions$tc$realtime$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get restauration_impossible => 'تعذّر استرجاع المادة الجارية. اطلب من المعلم أن يعرضها من جديد.';
}

// Path: tc.observation.entree
class _Traductions$tc$observation$entree$ar extends Traductions$tc$observation$entree$fr {
	_Traductions$tc$observation$entree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'متابعة الحصة';
	@override String get tuteurIntro => 'يمكنك مشاهدة درس طفلك لوقت قصير. يبقى الميكروفون والكاميرا مغلقين.';
	@override String get adminIntro => 'اختر طريقتك قبل الدخول. لن تتغير بعد ذلك.';
	@override String get controleurIntro => 'تدخل في مراقبة غير مرئية. لا ميكروفون ولا كاميرا.';
	@override String get entrer => 'دخول';
	@override String get modeDiscret => 'المتابعة دون ظهور';
	@override String get modeDiscretDetail => 'غير مرئي للمشاركين. دون ميكروفون ولا كاميرا، ودون إعلان.';
	@override String get modeVisible => 'الانضمام إلى الفصل';
	@override String get modeVisibleDetail => 'مرئي للجميع باسم إدارة Rewayah. الميكروفون والكاميرا مسموحان، ويُعلَن عن الدخول.';
	@override String get nomInstitutionnel => 'إدارة Rewayah';
	@override String get visiteJournalisee => 'زيارة مقيَّدة في السجل: الهوية، والحصة، والدخول، والخروج، والمدة.';
	@override String get roleSansObservation => 'حسابك لا يتابع الحصص.';
	@override String get retourClasse => 'العودة إلى الفصل';
}

// Path: tc.observation.explication
class _Traductions$tc$observation$explication$ar extends Traductions$tc$observation$explication$fr {
	_Traductions$tc$observation$explication$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'لمحة عن تعلّمه';
	@override String regleUne({required Object n, required Object duree}) => '⁨${n}⁩ زيارة مدتها ⁨${duree}⁩';
	@override String regle({required Object n, required Object duree}) => '⁨${n}⁩ زيارات مدة كل منها ⁨${duree}⁩';
	@override String get regleDetail => 'لكل حصة ولكل وليّ أمر، حتى لو كان أكثر من طفل من أطفالك في الفصل.';
	@override String get ecoute => 'استمع إلى المعلم والطلاب';
	@override String get ecouteDetail => 'تسمع المعلم والطلاب الذين يتكلمون، ومنهم طفلك.';
	@override String get sansMedia => 'دون ميكروفون ولا كاميرا';
	@override String get sansMediaDetail => 'يبقى الميكروفون والكاميرا معطَّلين حتى لا يُقاطَع الفصل.';
	@override String get revenir => 'إن كان طالب آخر يتلو في زيارتك الأولى، يمكنك العودة لاحقًا للاستماع إلى طفلك.';
	@override String get ecourtee => 'الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.';
	@override String get sansIntervenir => 'حفاظًا على التركيز، تتابع دون أن تتدخل.';
	@override String get informes => 'طفلك ومعلمه على علم.';
	@override String get observer => 'المتابعة الآن';
	@override String get pasMaintenant => 'ليس الآن';
	@override String restanteUne({required Object restantes, required Object max}) => 'الزيارات المتبقية لهذه الحصة: ⁨${restantes}⁩ من ⁨${max}⁩';
	@override String restantes({required Object restantes, required Object max}) => 'الزيارات المتبقية لهذه الحصة: ⁨${restantes}⁩ من ⁨${max}⁩';
	@override String get aucuneRestante => 'لا زيارة متبقية لهذه الحصة';
}

// Path: tc.observation.disponibilite
class _Traductions$tc$observation$disponibilite$ar extends Traductions$tc$observation$disponibilite$fr {
	_Traductions$tc$observation$disponibilite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get visitesEpuiseesTitre => 'لا زيارة متبقية لهذه الحصة';
	@override String get visitesEpuisees => 'استخدمت زياراتك. يمكنك متابعة الحصة القادمة.';
	@override String get tempsEpuiseTitre => 'انتهى وقت المتابعة';
	@override String get tempsEpuise => 'استُخدم وقت متابعتك لهذه الحصة. يمكنك متابعة الحصة القادمة.';
	@override String get seanceNonCommenceeTitre => 'لم تبدأ الحصة بعد';
	@override String get seanceNonCommencee => 'تُفتح المتابعة أثناء الحصة.';
	@override String get seanceTermineeTitre => 'انتهت الحصة';
	@override String get seanceTerminee => 'يمكنك متابعة الحصة القادمة.';
	@override String get seanceNonTenueTitre => 'هذه الحصة لا تُعقد';
	@override String get seanceNonTenue => 'أُلغيت أو أُجّلت أو لم تُعقد.';
	@override String get horsFenetreTitre => 'الحصة غير مفتوحة الآن';
	@override String get horsFenetre => 'المتابعة ممكنة أثناء الحصة فقط.';
	@override String get desactiveeTitre => 'المتابعة مغلقة لهذا الفصل';
	@override String get desactivee => 'أغلقت الإدارة متابعة هذا الفصل.';
	@override String get lienAbsentTitre => 'لا أحد من أطفالك في هذه الحصة';
	@override String get lienAbsent => 'المتابعة مخصصة لأولياء أمور طلاب الحصة.';
	@override String get enfantAbsentTitre => 'طفلك ليس في الحصة';
	@override String get enfantAbsent => 'تُفتح المتابعة حين يكون طفلك حاضرًا.';
	@override String get presenceTitre => 'جارٍ التحقق من الحضور';
	@override String get presence => 'تُفتح المتابعة بمجرد تأكيد حضور طفلك.';
	@override String get visiteOuverteTitre => 'زيارة مفتوحة بالفعل';
	@override String get visiteOuverte => 'إحدى زياراتك ما زالت مفتوحة لهذه الحصة، على هذا الجهاز أو على غيره. وهي تُحتسب من زياراتك.';
	@override String get fermeeTitre => 'المتابعة غير مفتوحة بعد';
	@override String get fermee => 'متابعة أولياء الأمور للحصص غير مفتوحة بعد. ستُقترح هنا بمجرد فتحها.';
	@override String get reseauTitre => 'تعذّر التحقق';
	@override String get reseau => 'تعذّر التحقق من توفر المتابعة. لم تبدأ أي زيارة.';
	@override String get capaciteTitre => 'المتابعة غير متاحة';
	@override String get capacite => 'المتابعة غير متاحة الآن.';
}

// Path: tc.observation.connexion
class _Traductions$tc$observation$connexion$ar extends Traductions$tc$observation$connexion$fr {
	_Traductions$tc$observation$connexion$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الاتصال والتحقق';
	@override String get phrase => 'يجري التحقق من زياراتك المتبقية. تبدأ الزيارة بمجرد قبول الدخول، بما في ذلك اتصال الفيديو.';
	@override String get enCours => 'جارٍ الاتصال والتحقق';
	@override String get prolongee => 'ابقَ على هذه الصفحة: التحقق مستمر.';
	@override String get impossibleTitre => 'تعذّر الاتصال';
	@override String get impossible => 'لم يتم الدخول إلى الحصة. تحقّق من اتصالك ثم أعد المحاولة: سيُعاد التحقق من زياراتك المتبقية.';
}

// Path: tc.observation.duree
class _Traductions$tc$observation$duree$ar extends Traductions$tc$observation$duree$fr {
	_Traductions$tc$observation$duree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String secondeUne({required Object n}) => '⁨${n}⁩ ثانية';
	@override String secondes({required Object n}) => '⁨${n}⁩ ثوانٍ';
	@override String minuteUne({required Object n}) => '⁨${n}⁩ دقيقة';
	@override String minutes({required Object n}) => '⁨${n}⁩ دقائق';
	@override String minutesSecondes({required Object m, required Object s}) => '⁨${m}⁩ د ⁨${s}⁩ ث';
}

// Path: tc.observation.refus
class _Traductions$tc$observation$refus$ar extends Traductions$tc$observation$refus$fr {
	_Traductions$tc$observation$refus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get politiqueDesactivee => 'المتابعة معطَّلة لهذا الفصل.';
	@override String get quotaVisites => 'استخدمت زياراتك لهذه الحصة بالفعل.';
	@override String get tempsEpuise => 'نفد وقت متابعتك لهذه الحصة.';
	@override String get lienTuteur => 'لست مرتبطًا بأي طالب في هذه الحصة.';
	@override String get seanceNonActive => 'الحصة ليست جارية.';
	@override String get horsFenetre => 'القاعة غير مفتوحة في هذا الوقت.';
	@override String get indisponible => 'المتابعة غير متاحة الآن.';
	@override String get capaciteAbsente => 'المتابعة غير مفعَّلة بعد في هذا التثبيت.';
}

// Path: tc.observation.visite
class _Traductions$tc$observation$visite$ar extends Traductions$tc$observation$visite$fr {
	_Traductions$tc$observation$visite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المتابعة جارية';
	@override String get quitter => 'مغادرة';
	@override String get supportIndisponible => 'تظهر هنا المادة التي يشاركها المعلم.';
	@override String get enseignant => 'المعلم';
	@override String get monEnfant => 'طفلك';
	@override String get budgetIncertain => 'الوقت المتبقي غير مؤكَّد من الخادم.';
	@override String get videoIndisponible => 'تعذّر فتح فيديو الحصة. يستمر احتساب وقت متابعتك.';
	@override String get sortieNonConfirmee => 'تعذّر تأكيد نهاية زيارتك. سيغلقها الخادم.';
	@override String get restantes => 'متبقية';
	@override String decompteLu({required Object duree}) => 'الوقت المتبقي: ⁨${duree}⁩';
	@override String get enDirect => 'مباشر';
	@override String get connexion => 'الاتصال';
	@override String get reconnexion => 'إعادة الاتصال';
	@override String get videoCoupee => 'الفيديو غير متاح';
	@override String get reconnexionDetail => 'انقطع الاتصال، جارٍ إعادة الاتصال. يستمر احتساب وقت متابعتك.';
	@override String get sonRecu => 'الصوت يصل';
	@override String get sonInterrompu => 'الصوت منقطع';
	@override String get agrandir => 'تكبير';
	@override String get reduire => 'تصغير';
	@override String get cameraFermee => 'الكاميرا مغلقة';
	@override String get pasEncoreLa => 'ليس في القاعة بعد';
	@override String parle({required Object nom}) => 'الكلمة الآن لـ⁨${nom}⁩';
	@override String get quitterQuestion => 'مغادرة الزيارة؟';
	@override String quitterConsequence({required Object duree}) => 'بقي لك ⁨${duree}⁩. الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.';
	@override String get quitterConsequenceSansTemps => 'الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.';
	@override String get quitterConfirmer => 'مغادرة الزيارة';
}

// Path: tc.observation.fin
class _Traductions$tc$observation$fin$ar extends Traductions$tc$observation$fin$fr {
	_Traductions$tc$observation$fin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sortieVolontaire => 'غادرت المتابعة.';
	@override String get quotaAtteint => 'انتهى وقت متابعتك.';
	@override String get seanceTerminee => 'انتهت الحصة.';
	@override String get revocationServeur => 'قُطعت متابعتك.';
	@override String get deconnexion => 'انقطع الاتصال.';
}

// Path: tc.observation.resultat
class _Traductions$tc$observation$resultat$ar extends Traductions$tc$observation$resultat$fr {
	_Traductions$tc$observation$resultat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get premiereTerminee => 'انتهت زيارتك الأولى';
	@override String get derniereTerminee => 'انتهت زيارتك الأخيرة';
	@override String get terminee => 'انتهت زيارتك';
	@override String get dureeAtteinte => 'بلغت الزيارة مدتها';
	@override String get interrompue => 'قُطعت المتابعة';
	@override String continuePour({required Object prenom}) => 'تستمر الحصة لـ⁨${prenom}⁩.';
	@override String get continueSansPrenom => 'تستمر الحصة.';
	@override String resteUne({required Object duree}) => 'بقيت لك زيارة واحدة مدتها ⁨${duree}⁩. عد لاحقًا للاستماع إلى طفلك.';
	@override String restent({required Object n, required Object duree}) => 'بقيت لك ⁨${n}⁩ زيارات مدة كل منها ⁨${duree}⁩. عد لاحقًا للاستماع إلى طفلك.';
	@override String get resteUneSansDuree => 'بقيت لك زيارة واحدة. عد لاحقًا للاستماع إلى طفلك.';
	@override String restentSansDuree({required Object n}) => 'بقيت لك ⁨${n}⁩ زيارات. عد لاحقًا للاستماع إلى طفلك.';
	@override String get aucune => 'استخدمت زياراتك لهذه الحصة. يمكنك متابعة الحصة القادمة.';
	@override String get prochaineSeance => 'يمكنك متابعة الحصة القادمة.';
	@override String get verification => 'جارٍ التحقق من زياراتك المتبقية';
	@override String get inconnues => 'تعذّر التحقق من زياراتك المتبقية. سيُعاد التحقق منها في الفصل.';
	@override String get voirObservations => 'عرض متابعاتي';
}

// Path: tc.observation.annonce
class _Traductions$tc$observation$annonce$ar extends Traductions$tc$observation$annonce$fr {
	_Traductions$tc$observation$annonce$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String tuteurObserve({required Object prenomEnfant}) => 'وليّ أمر ⁨${prenomEnfant}⁩ يتابع';
	@override String restant({required Object secondes}) => '⁨${secondes}⁩ ث';
	@override String get enfantIndicateur => 'وليّ أمرك يشاهد الدرس';
	@override String tuteursObservent({required Object nombre}) => '⁨${nombre}⁩ من أولياء الأمور يتابعون';
}

// Path: tc.observation.reglages
class _Traductions$tc$observation$reglages$ar extends Traductions$tc$observation$reglages$fr {
	_Traductions$tc$observation$reglages$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'متابعة أولياء الأمور';
	@override String get intro => 'يمكن لوليّ الأمر مشاهدة درس طفله لوقت قصير، دون ميكروفون ولا كاميرا. يحدد هذا الإعداد ما ينطبق على هذا الفصل.';
	@override String get heriter => 'اتباع إعداد الأكاديمية';
	@override String get personnaliser => 'تخصيص لهذا الفصل';
	@override String get desactiver => 'تعطيل لهذا الفصل';
	@override String get maxVisites => 'الزيارات لكل حصة';
	@override String get tempsTotal => 'الوقت الكلي لكل حصة';
	@override String get plafondVisite => 'أقصى مدة للزيارة';
	@override String get diminuer => 'إنقاص';
	@override String get augmenter => 'زيادة';
	@override String get enregistrer => 'حفظ';
	@override String get invalideVisites => 'زيارة واحدة على الأقل لكل حصة.';
	@override String get invalideTemps => 'ثلاثون ثانية على الأقل لكل حصة.';
	@override String valeurHeritee({required Object valeur}) => 'الأكاديمية: ⁨${valeur}⁩';
	@override String uniteVisiteUne({required Object n}) => '⁨${n}⁩ زيارة';
	@override String uniteVisites({required Object n}) => '⁨${n}⁩ زيارات';
	@override String uniteSecondes({required Object n}) => '⁨${n}⁩ ث';
	@override String versionPolitique({required Object version}) => 'الإصدار ⁨${version}⁩';
}

// Path: tc.parcours.avant
class _Traductions$tc$parcours$avant$ar extends Traductions$tc$parcours$avant$fr {
	_Traductions$tc$parcours$avant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'قبل الدرس القادم';
	@override String get rien => 'لا شيء للتحضير للدرس القادم.';
	@override String get rienDetail => 'سيقترح معلمك العمل في نهاية الحصة القادمة.';
	@override String get nonBranche => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.';
	@override String get nonBrancheDetail => 'هذا لا يعني أنه لا شيء للتحضير: هذه الشاشة لا تعرف قراءته بعد.';
	@override String get reprendre => 'استئناف الدرس';
	@override String reprendreDepuis({required Object position}) => 'استئناف الدرس من ⁨${position}⁩';
}

// Path: tc.parcours.intention
class _Traductions$tc$parcours$intention$ar extends Traductions$tc$parcours$intention$fr {
	_Traductions$tc$parcours$intention$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get apprendre => 'للحفظ';
	@override String get revoir => 'للمراجعة';
	@override String get renforcer => 'للتثبيت';
	@override String get entretenir => 'للتعاهد';
	@override String get evaluation => 'للتقييم';
}

// Path: tc.parcours.plage
class _Traductions$tc$parcours$plage$ar extends Traductions$tc$parcours$plage$fr {
	_Traductions$tc$parcours$plage$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String versets({required Object sourate, required Object premier, required Object dernier}) => 'سورة ⁨${sourate}⁩، الآيات ⁨${premier}⁩ إلى ⁨${dernier}⁩';
	@override String versetUnique({required Object sourate, required Object premier}) => 'سورة ⁨${sourate}⁩، الآية ⁨${premier}⁩';
	@override String versetsCroisee({required Object sourateDebut, required Object versetDebut, required Object sourateFin, required Object versetFin}) => 'سورة ⁨${sourateDebut}⁩، الآية ⁨${versetDebut}⁩ إلى سورة ⁨${sourateFin}⁩، الآية ⁨${versetFin}⁩';
	@override String pages({required Object premiere, required Object derniere}) => 'الصفحات ⁨${premiere}⁩ إلى ⁨${derniere}⁩';
	@override String pageUnique({required Object premiere}) => 'الصفحة ⁨${premiere}⁩';
	@override String section({required Object section}) => 'القسم ⁨${section}⁩';
	@override String get ressource => 'المادة كلها';
}

// Path: tc.parcours.feedback
class _Traductions$tc$parcours$feedback$ar extends Traductions$tc$parcours$feedback$fr {
	_Traductions$tc$parcours$feedback$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$parcours$feedback$cours$ar cours = _Traductions$tc$parcours$feedback$cours$ar._(_root);
	@override late final _Traductions$tc$parcours$feedback$comprehension$ar comprehension = _Traductions$tc$parcours$feedback$comprehension$ar._(_root);
	@override late final _Traductions$tc$parcours$feedback$rythme$ar rythme = _Traductions$tc$parcours$feedback$rythme$ar._(_root);
	@override late final _Traductions$tc$parcours$feedback$technique$ar technique = _Traductions$tc$parcours$feedback$technique$ar._(_root);
	@override late final _Traductions$tc$parcours$feedback$confiance$ar confiance = _Traductions$tc$parcours$feedback$confiance$ar._(_root);
	@override String get merci => 'شكرًا.';
	@override late final _Traductions$tc$parcours$feedback$tendance$ar tendance = _Traductions$tc$parcours$feedback$tendance$ar._(_root);
}

// Path: tc.parcours.signalement
class _Traductions$tc$parcours$signalement$ar extends Traductions$tc$parcours$signalement$fr {
	_Traductions$tc$parcours$signalement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإبلاغ عن حاجة';
	@override String get categorie => 'بماذا يتعلق الأمر؟';
	@override late final _Traductions$tc$parcours$signalement$categorieValeur$ar categorieValeur = _Traductions$tc$parcours$signalement$categorieValeur$ar._(_root);
	@override String get interne => 'ملاحظة داخلية';
	@override String get interneAide => 'تقرؤها الإدارة وحدها. لا تُرسل أبدًا تلقائيًا إلى الأسرة.';
	@override String get famille => 'رسالة إلى الأسرة';
	@override String get familleAide => 'اختيارية. الإدارة وحدها تقرر إرسالها بنقرة واحدة.';
	@override String contexte({required Object eleve}) => 'بخصوص ⁨${eleve}⁩. الحصة والفصل واسمك مرفقة بالفعل.';
	@override String get envoyer => 'إرسال البلاغ';
	@override String get envoye => 'أُرسل البلاغ إلى الإدارة.';
	@override String get interneRequis => 'اكتب على الأقل ما يجب أن تعرفه الإدارة.';
	@override String get echec => 'تعذّر إرسال البلاغ. أعد المحاولة.';
}

// Path: tc.parcours.postCours
class _Traductions$tc$parcours$postCours$ar extends Traductions$tc$parcours$postCours$fr {
	_Traductions$tc$parcours$postCours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'بعد الدرس';
	@override String duree({required Object minutes}) => 'المدة الفعلية ⁨${minutes}⁩ دقيقة';
	@override String get exceptions => 'للتأكيد';
	@override String get toutEstNominal => 'لا شيء يتطلب انتباهك.';
	@override String get reprise => 'الاستئناف المقترح';
	@override String get repriseInconnue => 'لا موضع استئناف معروف لهذه الحصة.';
	@override String get travail => 'العمل المقترح';
	@override String get travailAucun => 'لا عمل مقترح حتى الآن.';
	@override String get valider => 'تأكيد';
	@override String get enFile => 'تم الحفظ. سيُرسل بمجرد عودة الشبكة.';
	@override String get envoye => 'أُغلق الدرس.';
}

// Path: tuteur.accueil.etatCourt
class _Traductions$tuteur$accueil$etatCourt$ar extends Traductions$tuteur$accueil$etatCourt$fr {
	_Traductions$tuteur$accueil$etatCourt$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enDirect => 'مباشر';
	@override String get salleOuverte => 'القاعة مفتوحة';
	@override String dansMinutes({required Object minutes}) => 'بعد ⁨${minutes}⁩ دقيقة';
	@override String dansHeures({required Object heures, required Object minutes}) => 'بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د';
	@override String dansJours({required Object jours}) => 'بعد ⁨${jours}⁩ ي';
	@override String get prevue => 'حصة مقررة';
	@override String get annulee => 'حصة ملغاة';
	@override String get nonTenue => 'حصة لم تُعقد';
	@override String get terminee => 'حصة منتهية';
	@override String get aucune => 'لا حصة';
	@override String get illisible => 'غير متاح';
}

// Path: appareils.emetteur.verification
class _Traductions$appareils$emetteur$verification$ar extends Traductions$appareils$emetteur$verification$fr {
	_Traductions$appareils$emetteur$verification$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'جارٍ التحقق من الرمز';
	@override String get phrase => 'الرمز مخفي ريثما يُتحقق من أنه ما زال صالحًا.';
}

// Path: appareils.emetteur.confirme
class _Traductions$appareils$emetteur$confirme$ar extends Traductions$appareils$emetteur$confirme$fr {
	_Traductions$appareils$emetteur$confirme$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الجهاز مربوط';
	@override String phrase({required Object prenom}) => 'جهاز ⁨${prenom}⁩ جاهز. لم يعد الرمز معروضًا ولا يمكن استخدامه.';
	@override String get phraseSansPrenom => 'جهاز الطالب جاهز. لم يعد الرمز معروضًا ولا يمكن استخدامه.';
	@override String get action => 'تم';
}

// Path: appareils.emetteur.expire
class _Traductions$appareils$emetteur$expire$ar extends Traductions$appareils$emetteur$expire$fr {
	_Traductions$appareils$emetteur$expire$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'انتهت صلاحية هذا الرمز';
	@override String get phrase => 'لم يعد صالحًا. أنشئ رمزًا جديدًا حين يكون الجهاز الآخر جاهزًا.';
}

// Path: appareils.emetteur.remplace
class _Traductions$appareils$emetteur$remplace$ar extends Traductions$appareils$emetteur$remplace$fr {
	_Traductions$appareils$emetteur$remplace$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'استُبدل هذا الرمز';
	@override String get phrase => 'طُلب رمز جديد لهذا الطالب، هنا أو على جهاز آخر. هذا الرمز لم يعد يعمل.';
}

// Path: appareils.emetteur.dejaActif
class _Traductions$appareils$emetteur$dejaActif$ar extends Traductions$appareils$emetteur$dejaActif$fr {
	_Traductions$appareils$emetteur$dejaActif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'رمز صالح بالفعل';
	@override String phrase({required Object heure}) => 'رمز أُنشئ لهذا الطالب صالح حتى ⁨${heure}⁩. لا يمكن عرضه من جديد: إنشاء رمز جديد يُبطل القديم.';
}

// Path: appareils.emetteur.horsLigne
class _Traductions$appareils$emetteur$horsLigne$ar extends Traductions$appareils$emetteur$horsLigne$fr {
	_Traductions$appareils$emetteur$horsLigne$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'انقطع الاتصال';
	@override String phraseAvecCode({required Object heure}) => 'الرمز مخفي حتى عودة الاتصال. يبقى صالحًا حتى ⁨${heure}⁩.';
	@override String get phraseSansCode => 'تعذّر تحضير الرمز. سيُحضَّر بمجرد عودة الاتصال.';
}

// Path: appareils.emetteur.erreur
class _Traductions$appareils$emetteur$erreur$ar extends Traductions$appareils$emetteur$erreur$fr {
	_Traductions$appareils$emetteur$erreur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get plafondTitre => 'بلغت حد الأجهزة';
	@override String get plafondPhrase => 'لدى هذا الطالب الحد الأقصى من الأجهزة. أزل أحدها لربط جهاز آخر.';
	@override String get plafondAction => 'عرض الأجهزة';
	@override String get horsFoyerTitre => 'لم يُعثر على ملف الطالب';
	@override String get horsFoyerPhrase => 'ملف الطالب هذا غير مرتبط بأسرتك. عد إلى «الأسرة» لاختيار ملف.';
	@override String get compteTitre => 'ربط الأجهزة غير مفتوح بعد';
	@override String get comptePhrase => 'يجب فتح حسابك قبل ربط جهاز طالب.';
	@override String get generiqueTitre => 'تعذّر تحضير الرمز';
	@override String get generiquePhrase => 'لم يكتمل الطلب. أعد المحاولة بعد لحظة.';
}

// Path: foyer.ajout.porte
class _Traductions$foyer$ajout$porte$ar extends Traductions$foyer$ajout$porte$fr {
	_Traductions$foyer$ajout$porte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get illisibleTitre => 'تعذّرت قراءة حسابك';
	@override String get illisiblePhrase => 'لا نعرف بعد أي الملفات يمكنك إضافتها. أعد المحاولة بعد لحظة.';
}

// Path: foyer.ajout.pourQui
class _Traductions$foyer$ajout$pourQui$ar extends Traductions$foyer$ajout$pourQui$fr {
	_Traductions$foyer$ajout$pourQui$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get question => 'لمن ملف الطالب هذا؟';
	@override String get sousTitre => 'اختر الشخص الذي سيتابع الدروس.';
	@override String get requis => 'اختر لمن هذا الملف للمتابعة.';
	@override String get indisponible => 'غير متاح';
	@override String get enfantTitre => 'طفل أو قاصر';
	@override String get enfantDescription => 'ملف مرتبط بأسرتك، تديره نيابة عنه.';
	@override String get enfantAttente => 'ممكن بمجرد فتح وصولك.';
	@override String get moiTitre => 'أنا';
	@override String get moiDescription => 'غير ممكن بعد: متابعة الدروس بنفسك بملفك الخاص كطالب ستُقترح قريبًا.';
}

// Path: foyer.ajout.identite
class _Traductions$foyer$ajout$identite$ar extends Traductions$foyer$ajout$identite$fr {
	_Traductions$foyer$ajout$identite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get question => 'من هو الطالب؟';
	@override String get sousTitre => 'اسمه ولقبه وعمره.';
	@override String get prenom => 'الاسم';
	@override String get nom => 'اللقب';
	@override String get nomAide => 'لا يُعرض لقب العائلة على المعلم أبدًا.';
	@override String get age => 'العمر';
	@override String get ageSuffixe => 'سنة';
	@override String get ageAide => 'العمر يحدد العرض والكاميرا في البداية. يمكنك تغييرهما بعد ذلك.';
}

// Path: foyer.ajout.erreurs
class _Traductions$foyer$ajout$erreurs$ar extends Traductions$foyer$ajout$erreurs$fr {
	_Traductions$foyer$ajout$erreurs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get prenomRequis => 'أدخل اسم الطالب.';
	@override String get nomRequis => 'أدخل لقب الطالب.';
	@override String get ageRequis => 'أدخل العمر، بالأرقام.';
	@override String ageHorsBornes({required Object min, required Object max}) => 'أدخل عمرًا بين ⁨${min}⁩ و⁨${max}⁩ سنة.';
}

// Path: foyer.ajout.refus
class _Traductions$foyer$ajout$refus$ar extends Traductions$foyer$ajout$refus$fr {
	_Traductions$foyer$ajout$refus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get compteNonValide => 'يجب فتح وصولك قبل إضافة ملف طالب.';
	@override String get ageHorsBornes => 'هذا العمر غير مقبول. تحقّق منه ثم أعد المحاولة.';
	@override String get refuse => 'لم يُقبل الإنشاء. تحقّق من المعلومات ثم أعد المحاولة.';
}

// Path: foyer.ajout.incertaine
class _Traductions$foyer$ajout$incertaine$ar extends Traductions$foyer$ajout$incertaine$fr {
	_Traductions$foyer$ajout$incertaine$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ربما أُنشئ الملف';
	@override String get phrase => 'لم يصلنا الرد. تحقّق من الأسرة قبل إعادة المحاولة، كي لا يُنشأ الملف مرتين.';
	@override String get voirFoyer => 'عرض الأسرة';
	@override String get reessayer => 'إعادة المحاولة على أي حال';
}

// Path: adulte.monEspace.pageAccords
class _Traductions$adulte$monEspace$pageAccords$ar extends Traductions$adulte$monEspace$pageAccords$fr {
	_Traductions$adulte$monEspace$pageAccords$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get indisponibleTitre => 'موافقاتك غير قابلة للاطلاع بعد';
	@override String get indisponiblePhrase => 'قبول كل موافقة أو رفضها أو سحبها غير ممكن في التطبيق بعد. لا تُطلب منك أي موافقة هنا.';
}

// Path: adulte.monEspace.pageCoursAcces
class _Traductions$adulte$monEspace$pageCoursAcces$ar extends Traductions$adulte$monEspace$pageCoursAcces$fr {
	_Traductions$adulte$monEspace$pageCoursAcces$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get indisponibleTitre => 'الدروس والوصول غير قابلة للاطلاع بعد';
	@override String get indisponiblePhrase => 'تفاصيل دروسك وحصصك ووصولك غير متاحة في التطبيق بعد.';
}

// Path: adulte.famille.place
class _Traductions$adulte$famille$place$ar extends Traductions$adulte$famille$place$fr {
	_Traductions$adulte$famille$place$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ajouterConjointe => 'إضافة زوجة';
	@override String get ajouterConjoint => 'إضافة زوج';
	@override String get inviterConjointe => 'ادعُ زوجتك للانضمام إلى Rewayah بحسابها الخاص.';
	@override String get inviterConjoint => 'ادعُ زوجك للانضمام إلى Rewayah بحسابه الخاص.';
	@override String get invitationEnvoyee => 'أُرسلت الدعوة';
	@override String maConjointe({required Object prenom}) => '⁨${prenom}⁩، زوجتك';
	@override String monConjoint({required Object prenom}) => '⁨${prenom}⁩، زوجك';
	@override String get validationEnAttente => 'بانتظار الاعتماد الإداري';
	@override String get validationRefusee => 'رفضت الإدارة الاعتماد';
	@override String get nouvelleDemande => 'تقديم طلب جديد';
	@override String nouvelleInvitation({required Object date}) => 'دعوة جديدة ممكنة ابتداءً من ⁨${date}⁩';
	@override String envoyeeA({required Object courriel}) => 'أُرسلت إلى ⁨${courriel}⁩';
	@override String get expiree => 'انتهت صلاحية الدعوة السابقة. يمكنك إرسال دعوة جديدة.';
	@override String get annulee => 'أُلغيت الدعوة ولم يعد ممكنًا قبولها. يمكنك إرسال دعوة جديدة.';
}

// Path: adulte.reprise.repris
class _Traductions$adulte$reprise$repris$ar extends Traductions$adulte$reprise$repris$fr {
	_Traductions$adulte$reprise$repris$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get profils => 'ملفات القاصرين الموجودة';
	@override String get composition => 'تكوين الأسرة مستقبلًا وفق القواعد السارية';
	@override String get paiements => 'مدفوعات الأسرة المستقبلية';
	@override String get parcours => 'مسارات وليّ الأمر المرتبطة بالقاصرين';
}

// Path: adulte.reprise.jamais
class _Traductions$adulte$reprise$jamais$ar extends Traductions$adulte$reprise$jamais$fr {
	_Traductions$adulte$reprise$jamais$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get identifiants => 'بيانات دخول صاحب الحساب';
	@override String get messages => 'رسائله الخاصة';
	@override String get conversations => 'محادثاته';
	@override String get historique => 'سجله التعليمي الشخصي';
	@override String get moyensPaiement => 'وسائل الدفع المسجلة لديه';
	@override String get pieces => 'وثائق هويته';
	@override String get donnees => 'بياناته الخاصة التي لا علاقة لها بإدارة الأسرة';
}

// Path: adulte.reprise.etats
class _Traductions$adulte$reprise$etats$ar extends Traductions$adulte$reprise$etats$fr {
	_Traductions$adulte$reprise$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get deposee => 'مقدَّم';
	@override String get refuseeParTitulaire => 'رفضه صاحب الحساب';
	@override String get attenteAdministration => 'بانتظار الإدارة';
	@override String get validee => 'معتمَد';
	@override String get refusee => 'مرفوض';
}

// Path: adulte.reprise.phrases
class _Traductions$adulte$reprise$phrases$ar extends Traductions$adulte$reprise$phrases$fr {
	_Traductions$adulte$reprise$phrases$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get deposee => 'أُبلغ صاحب حساب الأسرة. ستدرس الإدارة الطلب.';
	@override String examenLe({required Object date}) => 'دون رد من صاحب الحساب، يمكن للإدارة دراسته ابتداءً من ⁨${date}⁩.';
	@override String get refuseeParTitulaire => 'رفض صاحب حساب الأسرة هذا الطلب. الإدارة على علم. لا تُنقل أي صلاحية من صلاحيات الأسرة.';
	@override String get attenteAdministration => 'لم يرد صاحب الحساب. لا يُنقل شيء تلقائيًا: ما زال على الإدارة دراسة الطلب.';
	@override String get validee => 'اعتمدت الإدارة الطلب. أصبحت الآن صاحب حساب الأسرة.';
	@override String get refusee => 'رفضت الإدارة الطلب. لا تُنقل أي صلاحية من صلاحيات الأسرة.';
}

// Path: adulte.reprise.titulaire
class _Traductions$adulte$reprise$titulaire$ar extends Traductions$adulte$reprise$titulaire$fr {
	_Traductions$adulte$reprise$titulaire$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get notification => 'قُدِّم طلب لاستلام أسرتك بدعوى وفاتك.';
	@override String get consigne => 'إن كان هذا الطلب خاطئًا، فارفضه.';
	@override String get refuser => 'رفض الطلب';
	@override String get ligne => 'قُدِّم طلب لاستلام أسرتك.';
	@override String get refusEchecTitre => 'لم يُؤكَّد الرفض.';
	@override String get horsLigne => 'أنت غير متصل. لم يُرسل شيء. يمكنك رفض الطلب بنفسك عند عودة الاتصال.';
	@override String get refusee => 'رفضت هذا الطلب. الإدارة على علم. لا تُنقل أي صلاحية من صلاحيات أسرتك.';
}

// Path: adulte.reprise.notifications
class _Traductions$adulte$reprise$notifications$ar extends Traductions$adulte$reprise$notifications$fr {
	_Traductions$adulte$reprise$notifications$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get refuseeParTitulaire => 'رفض صاحب حساب الأسرة طلبك لاستلام الأسرة.';
	@override String get attenteAdministration => 'طلبك لاستلام الأسرة بانتظار الإدارة.';
	@override String get validee => 'اعتُمد طلبك لاستلام الأسرة.';
	@override String get refusee => 'رُفض طلبك لاستلام الأسرة.';
}

// Path: adulte.demo.donnees
class _Traductions$adulte$demo$donnees$ar extends Traductions$adulte$demo$donnees$fr {
	_Traductions$adulte$demo$donnees$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get soldeTitulaire => 'رصيد تجريبي 1';
	@override String get soldeSecondAdulte => 'رصيد تجريبي 2';
	@override String get soldeAicha => 'رصيد تجريبي 3';
	@override String get soldeOumar => 'رصيد تجريبي 4';
	@override String get totalAvecSecondAdulte => 'مجموع تجريبي A';
	@override String get totalSansSecondAdulte => 'مجموع تجريبي B';
	@override String get prixOffreA => '5,00 € (عرض تجريبي)';
	@override String get prixOffreB => '10,00 € (عرض تجريبي)';
	@override String get detailOffreA => 'رصيد تجريبي A';
	@override String get detailOffreB => 'رصيد تجريبي B';
	@override String get totalRecharge5 => '5,00 € (عرض تجريبي)';
	@override String get totalRecharge10 => '10,00 € (عرض تجريبي)';
	@override String get totalRecharge15 => '15,00 € (عرض تجريبي)';
	@override String get totalRecharge20 => '20,00 € (عرض تجريبي)';
	@override String get totalRecharge25 => '25,00 € (عرض تجريبي)';
	@override String get totalRecharge30 => '30,00 € (عرض تجريبي)';
	@override String get totalRecharge35 => '35,00 € (عرض تجريبي)';
	@override String get totalRecharge40 => '40,00 € (عرض تجريبي)';
}

// Path: adulte.demo.etats
class _Traductions$adulte$demo$etats$ar extends Traductions$adulte$demo$etats$fr {
	_Traductions$adulte$demo$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get adulteSeul => 'البالغ وحده، دون أسرة.';
	@override String get titulaireSansConjoint => 'ليس في الأسرة بالغ ثانٍ.';
	@override String get invitationEnAttente => 'دعوة البالغ الثاني بانتظار الرد.';
	@override String get invitationExpiree => 'انتهت صلاحية دعوة البالغ الثاني.';
	@override String get invitationAnnulee => 'أُلغيت دعوة البالغ الثاني.';
	@override String get conjointActif => 'البالغ الثاني جزء من الأسرة.';
	@override String get conjointQuitte => 'غادر البالغ الثاني الأسرة.';
	@override String get conjointRetire => 'أُزيل البالغ الثاني من الأسرة.';
	@override String get delai60 => 'مهلة أولى جارية.';
	@override String get nouvelleDemande => 'دعوة جديدة ممكنة بعد المهلة الأولى.';
	@override String get validationEnAttente => 'الاعتماد الإداري بانتظار القرار.';
	@override String get validationRefusee => 'رُفض الاعتماد الإداري.';
	@override String get secondDepart => 'غادر البالغ الثاني للمرة الثانية.';
	@override String get delai120 => 'مهلة تالية، أطول، جارية.';
	@override String get departsSuivants => 'بعد المغادرة الثالثة، تنطبق المهلة التالية دائمًا.';
	@override String get repriseDemandee => 'قُدِّم طلب لاستلام الأسرة.';
	@override String get repriseRefuseeParTitulaire => 'رفض صاحب الحساب طلب الاستلام.';
	@override String get repriseSansReponse => 'دون رد في المهلة، ينتظر الطلب الإدارة.';
	@override String get repriseValidee => 'اعتُمد استلام الأسرة.';
	@override String get repriseRefusee => 'رُفض استلام الأسرة.';
	@override String get dejaDansUnAutreFoyer => 'البالغ المدعو جزء من أسرة أخرى بالفعل.';
	@override String get erreurReseau => 'انقطعت الشبكة أثناء إجراء.';
	@override String get doubleSoumission => 'أُرسل الإجراء نفسه مرتين.';
	@override String get notificationDansLApplication => 'تعذّر إرسال الإشعار إلى الهاتف، ويبقى ظاهرًا في التطبيق.';
	@override String get emancipation => 'استقلال طالب بلغ سن الرشد: غير مبني في هذه المرحلة.';
}

// Path: dossiers.revue.etats
class _Traductions$dossiers$revue$etats$ar extends Traductions$dossiers$revue$etats$fr {
	_Traductions$dossiers$revue$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get chargement => 'جارٍ تحميل الملف…';
	@override String get horsLigne => 'أنت غير متصل. لا يمكن إرسال أي قرار.';
	@override String get accesPerdu => 'لم يعد لديك وصول إلى هذا الملف.';
	@override String get retourDossiers => 'العودة إلى الملفات';
	@override String get verificationsIncompletes => 'أكمل عمليات التحقق المطلوبة.';
	@override String get accordManquant => 'تنقص هذا الملف موافقة مطلوبة.';
	@override String get decisionIndisponible => 'القرار غير متاح الآن.';
	@override String get modifie => 'تغيّر هذا الملف منذ فتحه.';
	@override String get actualiserDossier => 'تحديث الملف';
	@override String get refusNonAutorise => 'لا يمكن رفض هذا الملف في حالته الحالية.';
}

// Path: admin.journal.evenements
class _Traductions$admin$journal$evenements$ar extends Traductions$admin$journal$evenements$fr {
	_Traductions$admin$journal$evenements$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get observationEntree => 'بدأت زيارة متابعة';
	@override String get observationSortie => 'انتهت زيارة متابعة';
	@override String get observationPolitiqueGroupeModifiee => 'عُدِّلت قواعد متابعة الفصل';
}

// Path: classe.entree.demo.roles
class _Traductions$classe$entree$demo$roles$ar extends Traductions$classe$entree$demo$roles$fr {
	_Traductions$classe$entree$demo$roles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get eleve => 'الطالب';
	@override String get guidee => 'الطالب، وضع إمكانية الوصول';
	@override String get enseignant => 'المعلم';
}

// Path: classe.entree.demo.etats
class _Traductions$classe$entree$demo$etats$ar extends Traductions$classe$entree$demo$etats$fr {
	_Traductions$classe$entree$demo$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aVenir => 'قادمة';
	@override String get fenetreOuverte => 'النافذة مفتوحة';
	@override String get preparation => 'التحضير جارٍ';
	@override String get attente => 'انتظار قبل البداية';
	@override String get enDirect => 'مباشر';
	@override String get tempsEcoule => 'انتهى الوقت المقرر';
	@override String get terminee => 'منتهية';
	@override String get annulee => 'ملغاة';
	@override String get horsLigne => 'غير متصل';
	@override String get indisponible => 'المعلومة غير متاحة';
	@override String get changementHeure => 'تغيير التوقيت';
}

// Path: salle.preparation.eleve.guidee
class _Traductions$salle$preparation$eleve$guidee$ar extends Traductions$salle$preparation$eleve$guidee$fr {
	_Traductions$salle$preparation$eleve$guidee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get verification => 'جارٍ تحضير الحصة…';
	@override String get pret => 'كل شيء جاهز.';
	@override String get microCoupe => 'سيكون الميكروفون مغلقًا عند الدخول.';
	@override String get microQuestion => 'الميكروفون محظور. هل نسمح به؟';
	@override String get microBloque => 'الميكروفون محظور.';
	@override String get horsLigne => 'الاتصال لا يعمل الآن.';
}

// Path: salle.preparation.eleve.demo
class _Traductions$salle$preparation$eleve$demo$ar extends Traductions$salle$preparation$eleve$demo$fr {
	_Traductions$salle$preparation$eleve$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get section => 'استعداد الطالب';
	@override String get sectionGuidee => 'استعداد الطالب، وضع إمكانية الوصول';
	@override String get verification => 'التحقق جارٍ';
	@override String get pret => 'جاهز';
	@override String get microBloque => 'الميكروفون محظور';
	@override String get horsLigne => 'غير متصل';
}

// Path: salle.seance.demo.groupes
class _Traductions$salle$seance$demo$groupes$ar extends Traductions$salle$seance$demo$groupes$fr {
	_Traductions$salle$seance$demo$groupes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get seance => 'مجرى الحصة';
	@override String get secours => 'حالات الطوارئ';
	@override String get tableau => 'المواد والسبورة';
}

// Path: salle.seance.demo.roles
class _Traductions$salle$seance$demo$roles$ar extends Traductions$salle$seance$demo$roles$fr {
	_Traductions$salle$seance$demo$roles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get eleve => 'طالب عادي';
	@override String get guidee => 'وضع إمكانية الوصول';
	@override String get enseignant => 'المعلم';
}

// Path: salle.seance.demo.etats
class _Traductions$salle$seance$demo$etats$ar extends Traductions$salle$seance$demo$etats$fr {
	_Traductions$salle$seance$demo$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get repos => 'وضع عادي';
	@override String get visite => 'زيارة';
	@override String get rienPartage => 'لا شيء مُشارَك';
	@override String get appel => 'نداء خاص';
	@override String get eleves => 'لوحة الطلاب';
	@override String get supports => 'لوحة المواد';
	@override String get fin => 'نهاية الحصة';
	@override String get reseauFaible => 'شبكة ضعيفة';
	@override String get reconnexion => 'إعادة الاتصال';
	@override String get retablie => 'عاد الاتصال';
	@override String get echec => 'تعذّرت إعادة الاتصال';
	@override String get horsLigne => 'غير متصل';
	@override String get microBloque => 'الميكروفون محظور';
	@override String get cameraInterdite => 'الكاميرا ممنوعة';
	@override String get prolongee => 'حصة ممدَّدة';
	@override String get accesRetire => 'سُحب الدخول';
}

// Path: salle.seance.demo.tb
class _Traductions$salle$seance$demo$tb$ar extends Traductions$salle$seance$demo$tb$fr {
	_Traductions$salle$seance$demo$tb$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sal00 => 'SAL-00 القاعة والأشخاص';
	@override String get ped01 => 'PED-01 سبورة حرة، دون مادة';
	@override String get ped02 => 'PED-02 المادة وحدها';
	@override String get ped03 => 'PED-03 المادة مع الملاحظات';
	@override String get ped04 => 'PED-04 السبورة، المادة مخفية';
	@override String get ui01 => 'UI-01 عرض مضغوط';
	@override String get ui02 => 'UI-02 قاعة موسَّعة';
	@override String get ui03 => 'UI-03 تركيز محلي';
	@override String get vis01 => 'VIS-01 شريط الفيديو ظاهر';
	@override String get ctx01 => 'CTX-01 سياق الحصة';
	@override String get ctx02 => 'CTX-02 معلومات المراقبة';
	@override String get cmd01 => 'CMD-01 عناصر التحكم';
	@override String get cmd02 => 'CMD-02 اللون والسُّمك';
	@override String get cmd03 => 'CMD-03 الكتابة جارية';
	@override String get lib01 => 'LIB-01 المكتبة';
	@override String get lib02 => 'LIB-02 معاينة خاصة';
	@override String get lib03 => 'LIB-03 فتح المادة';
	@override String get lib04 => 'LIB-04 بحث دون نتيجة';
	@override String get per01 => 'PER-01 المشاركون والأذونات';
	@override String get dlg01 => 'DLG-01 مسح ملاحظات الصفحة';
	@override String get err01 => 'ERR-01 انقطعت المزامنة';
	@override String get err02 => 'ERR-02 استعادة السبورة';
	@override String get err03 => 'ERR-03 فشل الحفظ';
	@override String get end01 => 'END-01 مغادرة الحصة';
	@override String get supportArrive => 'المادة في الطريق';
	@override String get ressourceIndisponible => 'المورد غير متاح';
	@override String get autorisationEcrire => 'إذن بالكتابة';
	@override String get droitRetire => 'سُحب الإذن';
	@override String get effacementTableau => 'مسح ملاحظات السبورة';
}

// Path: enseignant.journee.absence.etats
class _Traductions$enseignant$journee$absence$etats$ar extends Traductions$enseignant$journee$absence$etats$fr {
	_Traductions$enseignant$journee$absence$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enregistree => 'سُجِّل الغياب';
	@override String get recherche => 'جارٍ البحث عن بديل';
	@override String get remplacantConfirme => 'البديل مؤكَّد';
	@override String get aucunRemplacant => 'لا بديل مؤكَّد';
	@override String get seanceAnnulee => 'أُلغيت الحصة';
	@override String get demandeAnnulee => 'أُلغي الطلب';
}

// Path: tc.outils.dock.position
class _Traductions$tc$outils$dock$position$ar extends Traductions$tc$outils$dock$position$fr {
	_Traductions$tc$outils$dock$position$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get bas => 'في الأسفل';
	@override String get gauche => 'في جهة البداية';
	@override String get droite => 'في جهة النهاية';
}

// Path: tc.classe.entete.titreEnseignant
class _Traductions$tc$classe$entete$titreEnseignant$ar extends Traductions$tc$classe$entete$titreEnseignant$fr {
	_Traductions$tc$classe$entete$titreEnseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sayyid => 'سيد';
	@override String get sayyida => 'سيدة';
}

// Path: tc.parcours.feedback.cours
class _Traductions$tc$parcours$feedback$cours$ar extends Traductions$tc$parcours$feedback$cours$fr {
	_Traductions$tc$parcours$feedback$cours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intitule => 'كيف كان الدرس اليوم؟';
	@override String get difficile => 'صعب';
	@override String get bien => 'جيد';
	@override String get tresBien => 'جيد جدًا';
}

// Path: tc.parcours.feedback.comprehension
class _Traductions$tc$parcours$feedback$comprehension$ar extends Traductions$tc$parcours$feedback$comprehension$fr {
	_Traductions$tc$parcours$feedback$comprehension$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intitule => 'هل فهمت ما تم العمل عليه؟';
	@override String get difficile => 'ليس تمامًا';
	@override String get bien => 'نعم، إلى حدٍّ ما';
	@override String get tresBien => 'تمامًا';
}

// Path: tc.parcours.feedback.rythme
class _Traductions$tc$parcours$feedback$rythme$ar extends Traductions$tc$parcours$feedback$rythme$fr {
	_Traductions$tc$parcours$feedback$rythme$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intitule => 'هل ناسبك إيقاع الدرس؟';
	@override String get difficile => 'سريع جدًا';
	@override String get bien => 'مناسب';
	@override String get tresBien => 'مريح جدًا';
}

// Path: tc.parcours.feedback.technique
class _Traductions$tc$parcours$feedback$technique$ar extends Traductions$tc$parcours$feedback$technique$fr {
	_Traductions$tc$parcours$feedback$technique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intitule => 'هل كان الصوت والصورة مريحين؟';
	@override String get difficile => 'مزعجان';
	@override String get bien => 'مقبولان';
	@override String get tresBien => 'جيدان جدًا';
}

// Path: tc.parcours.feedback.confiance
class _Traductions$tc$parcours$feedback$confiance$ar extends Traductions$tc$parcours$feedback$confiance$fr {
	_Traductions$tc$parcours$feedback$confiance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intitule => 'هل تشعر أنك مستعد للدرس القادم؟';
	@override String get difficile => 'ليس بعد';
	@override String get bien => 'إلى حدٍّ ما';
	@override String get tresBien => 'تمامًا';
}

// Path: tc.parcours.feedback.tendance
class _Traductions$tc$parcours$feedback$tendance$ar extends Traductions$tc$parcours$feedback$tendance$fr {
	_Traductions$tc$parcours$feedback$tendance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'آراء الطلاب';
	@override String get sousSeuil => 'لا تكفي الآراء بعد لاستخلاص اتجاه.';
	@override String get anonyme => 'الآراء مجهولة الهوية ومجمَّعة. لا تكفي وحدها أبدًا لاتخاذ قرار.';
}

// Path: tc.parcours.signalement.categorieValeur
class _Traductions$tc$parcours$signalement$categorieValeur$ar extends Traductions$tc$parcours$signalement$categorieValeur$fr {
	_Traductions$tc$parcours$signalement$categorieValeur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get pedagogique => 'تعليمي';
	@override String get presence => 'الحضور';
	@override String get technique => 'تقني';
	@override String get changement => 'تغيير';
	@override String get autre => 'آخر';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TraductionsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'commun.sections.page' => 'أقسام الصفحة',
			'commun.marque' => 'Rewayah Academy',
			'commun.continuer' => 'متابعة',
			'commun.retour' => 'رجوع',
			'commun.valider' => 'تأكيد',
			'commun.annuler' => 'إلغاء',
			'commun.fermer' => 'إغلاق',
			'commun.reessayer' => 'إعادة المحاولة',
			'commun.chargement' => 'جارٍ التحميل',
			'commun.demonstration.repere' => 'عرض تجريبي',
			'commun.demonstration.repereLu' => 'وضع العرض التجريبي',
			'commun.etape.sur' => ({required Object n, required Object total}) => '⁨${n}⁩ من ⁨${total}⁩',
			'commun.etape.surLue' => ({required Object n, required Object total}) => 'الخطوة ⁨${n}⁩ من ⁨${total}⁩',
			'commun.choix.indisponible' => 'غير متاح',
			'commun.etats.chargementProlonge.titre' => 'الاتصال يستغرق وقتًا أطول من المتوقع',
			'commun.etats.chargementProlonge.phrase' => 'يمكنك الانتظار قليلًا أو إعادة المحاولة.',
			'commun.etats.horsLigne.titre' => 'أنت غير متصل',
			'commun.etats.horsLigne.phrase' => 'تحقّق من اتصالك. ما هو معروض يبقى قابلًا للاطلاع.',
			'commun.etats.reconnexion.titre' => 'جارٍ إعادة الاتصال',
			'commun.etats.reconnexion.phrase' => 'محاولة اتصال جديدة جارية.',
			'commun.etats.echecServeur.titre' => 'تعذّر تحميل هذه المعلومات',
			'commun.etats.echecServeur.phrase' => 'لم يكتمل التحميل. أعد المحاولة بعد لحظة.',
			'commun.etats.introuvable.titre' => 'هذه الصفحة غير موجودة',
			'commun.etats.introuvable.phrase' => 'ربما الرابط ناقص، أو لم تعد الصفحة موجودة.',
			'commun.etats.accesRefuse.titre' => 'ليس لديك إذن بالوصول إلى هذه الصفحة',
			'commun.etats.accesRefuse.phrase' => 'هذا المحتوى غير مفتوح لحسابك.',
			'commun.etats.sessionExpiree.titre' => 'انتهت جلستك',
			'commun.etats.sessionExpiree.phrase' => 'سجّل الدخول من جديد للمتابعة.',
			'commun.etats.dossierEnAttente.titre' => 'ملفك قيد الانتظار',
			'commun.etats.dossierEnAttente.phrase' => 'بقيت خطوة قبل فتح هذه المساحة.',
			'commun.etats.aucunResultat.titre' => 'لا نتائج',
			'commun.etats.aucunResultat.phrase' => 'لا شيء مطابق الآن.',
			'commun.etats.permissionRefusee.titre' => 'الإذن مرفوض',
			'commun.etats.permissionRefusee.phrase' => 'دون هذا الإذن، لا يمكن فتح هذه الوظيفة. يمكنك تغييره في إعدادات جهازك.',
			'commun.etats.ressourceExpiree.titre' => 'هذا المحتوى لم يعد متاحًا',
			'commun.etats.ressourceExpiree.phrase' => 'سُحب، أو انتهى الوصول إليه.',
			'commun.etats.indisponible.titre' => 'غير متاح بعد',
			'commun.etats.indisponible.phrase' => 'هذه الوظيفة غير مفتوحة بعد.',
			'commun.etats.reessaisEpuises' => 'ما زال لا رد. أعد المحاولة لاحقًا.',
			'commun.etats.horsLigneDemarrage' => 'يحتاج Rewayah إلى الإنترنت للتحقق من حسابك. أعد توصيل هذا الجهاز، ثم أعد المحاولة.',
			'commun.etats.actions.reessayer' => 'إعادة المحاولة',
			'commun.etats.actions.retourAccueil' => 'العودة إلى الرئيسية',
			'commun.etats.actions.seConnecter' => 'تسجيل الدخول',
			'commun.etats.actions.seReconnecter' => 'تسجيل الدخول من جديد',
			'commun.etats.actions.voirDossier' => 'عرض ملفي',
			'commun.etats.actions.reinitialiserFiltres' => 'إعادة ضبط عوامل التصفية',
			'commun.etats.actions.revenir' => 'الرجوع',
			'commun.entete.retour' => 'رجوع',
			'commun.entete.notifications' => 'الإشعارات',
			'commun.entete.notificationsUneNonLue' => 'الإشعارات، واحد غير مقروء',
			'commun.entete.notificationsNonLues' => ({required Object nombre}) => 'الإشعارات، ⁨${nombre}⁩ غير مقروءة',
			'commun.selecteurProfils.etiquette' => ({required Object prenom, required Object etat}) => '⁨${prenom}⁩، ⁨${etat}⁩',
			'commun.selecteurProfils.ajouter' => 'إضافة',
			'commun.selecteurProfils.ajouterSemantique' => 'إضافة ملف طالب',
			'commun.theme.groupe' => 'المظهر',
			'commun.theme.clair' => 'المظهر الفاتح',
			'commun.theme.sombre' => 'المظهر الداكن',
			'commun.demarrage.ouverture' => 'جارٍ فتح Rewayah',
			'commun.dates.jours.0' => 'الاثنين',
			'commun.dates.jours.1' => 'الثلاثاء',
			'commun.dates.jours.2' => 'الأربعاء',
			'commun.dates.jours.3' => 'الخميس',
			'commun.dates.jours.4' => 'الجمعة',
			'commun.dates.jours.5' => 'السبت',
			'commun.dates.jours.6' => 'الأحد',
			'commun.dates.mois.0' => 'يناير',
			'commun.dates.mois.1' => 'فبراير',
			'commun.dates.mois.2' => 'مارس',
			'commun.dates.mois.3' => 'أبريل',
			'commun.dates.mois.4' => 'مايو',
			'commun.dates.mois.5' => 'يونيو',
			'commun.dates.mois.6' => 'يوليو',
			'commun.dates.mois.7' => 'أغسطس',
			'commun.dates.mois.8' => 'سبتمبر',
			'commun.dates.mois.9' => 'أكتوبر',
			'commun.dates.mois.10' => 'نوفمبر',
			'commun.dates.mois.11' => 'ديسمبر',
			'commun.dates.jourDate' => ({required Object jour, required Object numero, required Object mois}) => '⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩',
			'etat.enDirect' => 'مباشر',
			'etat.seanceAnnulee' => 'ملغاة',
			'etat.annuleeValeur' => ({required Object valeur}) => 'ملغاة: ⁨${valeur}⁩',
			'etat.motifNonCommunique' => 'السبب غير متوفر',
			'etat.aucunRemplacantTrouve' => 'لم يُعثر على بديل',
			'etat.seanceNonFacturee' => 'الحصة غير مفوترة',
			'etat.raisonEtSuite' => ({required Object raison, required Object suite}) => '⁨${raison}⁩ · ⁨${suite}⁩',
			'etat.imminent' => 'قريبًا جدًا',
			'etat.annule' => 'ملغى',
			'etat.enAttente' => 'قيد الانتظار',
			'etat.enRetard' => 'متأخر',
			'etat.termine' => 'منتهٍ',
			'classe.entree.coursDans' => ({required Object duree}) => 'الدرس بعد ⁨${duree}⁩',
			'classe.entree.coursImminent' => 'الدرس بعد أقل من دقيقة',
			'classe.entree.rejoindre' => 'انضمام',
			'classe.entree.rejoindreLecteur' => ({required Object classe}) => 'الانضمام إلى حصة ⁨${classe}⁩',
			'classe.entree.salleOuverte' => ({required Object duree}) => 'القاعة مفتوحة. تبدأ الحصة بعد ⁨${duree}⁩.',
			'classe.entree.salleOuverteImminent' => 'القاعة مفتوحة. تبدأ الحصة بعد أقل من دقيقة.',
			'classe.entree.preparation' => 'التحضير جارٍ',
			'classe.entree.attente' => ({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ⁨${duree}⁩.',
			'classe.entree.attenteImminent' => 'أنت في القاعة. تبدأ الحصة بعد أقل من دقيقة.',
			'classe.entree.enDirect' => 'الحصة مباشرة',
			'classe.entree.tempsEcoule' => 'انتهى الوقت المقرر',
			'classe.entree.terminee' => 'انتهت الحصة',
			'classe.entree.annulee' => 'أُلغيت الحصة',
			'classe.entree.aucune' => 'لا توجد حصة مقررة',
			'classe.entree.horsLigne' => 'أنت غير متصل. تحتاج الحصة إلى اتصال.',
			'classe.entree.indisponible' => 'معلومات الحصة غير متاحة حاليًا.',
			'classe.entree.reessayer' => 'إعادة المحاولة',
			'classe.entree.chargementSeance' => 'جارٍ تحميل الحصة القادمة.',
			'classe.entree.progressionValeur' => ({required Object chapitre, required Object pourcentage}) => '⁨${chapitre}⁩ · ⁨${pourcentage}⁩٪',
			'classe.entree.dst' => ({required Object avant, required Object apres}) => 'تغيير التوقيت: سينتقل الدرس من ⁨${avant}⁩ إلى ⁨${apres}⁩.',
			'classe.entree.annonce.aVenir' => 'حصة قادمة',
			'classe.entree.annonce.fenetreOuverte' => 'القاعة مفتوحة',
			'classe.entree.annonce.attente' => 'أنت في القاعة',
			'classe.entree.accesInverifiable' => 'تعذّر التحقق من الدخول إلى القاعة الآن.',
			'classe.entree.demo.titre' => 'الدخول إلى الفصل',
			'classe.entree.demo.mention' => 'عرض تجريبي',
			'classe.entree.demo.intro' => 'بيانات وهمية، دون أي اتصال بالخادم. كل رابط يُظهر ما تقوله خانة الدخول لدور ولحظة.',
			'classe.entree.demo.roles.eleve' => 'الطالب',
			'classe.entree.demo.roles.guidee' => 'الطالب، وضع إمكانية الوصول',
			'classe.entree.demo.roles.enseignant' => 'المعلم',
			'classe.entree.demo.etats.aVenir' => 'قادمة',
			'classe.entree.demo.etats.fenetreOuverte' => 'النافذة مفتوحة',
			'classe.entree.demo.etats.preparation' => 'التحضير جارٍ',
			'classe.entree.demo.etats.attente' => 'انتظار قبل البداية',
			'classe.entree.demo.etats.enDirect' => 'مباشر',
			'classe.entree.demo.etats.tempsEcoule' => 'انتهى الوقت المقرر',
			'classe.entree.demo.etats.terminee' => 'منتهية',
			'classe.entree.demo.etats.annulee' => 'ملغاة',
			'classe.entree.demo.etats.horsLigne' => 'غير متصل',
			'classe.entree.demo.etats.indisponible' => 'المعلومة غير متاحة',
			'classe.entree.demo.etats.changementHeure' => 'تغيير التوقيت',
			'classe.entree.demo.formeBouton' => 'الشكل: زر',
			'classe.entree.demo.formeLigne' => 'الشكل: سطر حالة',
			'classe.entree.demo.lecteur' => ({required Object texte}) => 'قارئ الشاشة: ⁨${texte}⁩',
			'classe.entree.demo.annonce' => ({required Object texte}) => 'الإعلان: ⁨${texte}⁩',
			'classe.entree.demo.detail' => ({required Object texte}) => 'التفاصيل: ⁨${texte}⁩',
			'classe.entree.demo.retour' => 'العودة إلى القائمة',
			'classe.catalogue' => 'اختيار فصل',
			'classe.planning' => 'الجدول',
			'classe.travail' => 'قبل الدرس القادم',
			'classe.ressources' => 'المكتبة',
			'classe.progression' => 'التقدم',
			'classe.observer' => 'متابعة الحصة',
			'classe.titre' => 'الفصل',
			'classe.historique' => 'السجل',
			'classe.sousTitre' => ({required Object prenom, required Object enseignant}) => '⁨${prenom}⁩ · ⁨${enseignant}⁩',
			'classe.indisponiblePhrase' => 'تفاصيل الفصل غير متاحة هنا بعد.',
			'classe.introuvableTitre' => 'هذا الفصل غير مفتوح لهذا الملف',
			'classe.introuvablePhrase' => 'ربما انتهى، أو يخص طالبًا آخر في الأسرة.',
			'classe.seance.aucune' => 'لا حصة مقررة',
			'classe.seance.aucuneDetail' => ({required Object prenom}) => 'ستظهر هنا الحصة القادمة لـ⁨${prenom}⁩ بمجرد جدولتها.',
			'classe.seance.illisible' => 'تعذّرت قراءة الحصة القادمة.',
			'classe.seance.presence' => ({required Object prenom, required Object etat}) => '⁨${prenom}⁩: ⁨${etat}⁩',
			'classe.observation.commentCaMarche' => 'كيف يعمل ذلك؟',
			'classe.observation.uneVisite' => 'زيارة واحدة متاحة',
			'classe.observation.visites' => ({required Object nombre}) => '⁨${nombre}⁩ زيارات متاحة',
			'classe.observation.resume' => ({required Object visites, required Object duree}) => '⁨${visites}⁩ · ⁨${duree}⁩ لكل زيارة',
			'classe.observation.restanteAucune' => 'لا زيارة متبقية لهذه الحصة',
			'classe.observation.restanteUne' => 'زيارة واحدة متبقية لهذه الحصة',
			'classe.observation.restantes' => ({required Object nombre}) => 'الزيارات المتبقية لهذه الحصة: ⁨${nombre}⁩',
			'classe.observation.minutes' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة',
			'classe.observation.minutesSecondes' => ({required Object minutes, required Object secondes}) => '⁨${minutes}⁩ د ⁨${secondes}⁩ ث',
			'classe.observation.secondes' => ({required Object secondes}) => '⁨${secondes}⁩ ث',
			'classe.observation.motif.visitesEpuisees' => 'استخدمت زياراتك لهذه الحصة.',
			'classe.observation.motif.tempsEpuise' => 'نفد وقت متابعتك لهذه الحصة.',
			'classe.observation.motif.seanceNonCommencee' => 'تُفتح المتابعة حين تبدأ الحصة.',
			'classe.observation.motif.seanceTerminee' => 'انتهت الحصة.',
			'classe.observation.motif.seanceNonTenue' => 'هذه الحصة لا تُعقد: لا شيء للمتابعة.',
			'classe.observation.motif.horsFenetre' => 'القاعة غير مفتوحة في هذا الوقت.',
			'classe.observation.motif.observationDesactivee' => 'المتابعة مغلقة لهذا الفصل.',
			'classe.observation.motif.lienAbsent' => 'لا طالب من أسرتك مرتبط بهذه الحصة.',
			'classe.observation.motif.enfantAbsent' => ({required Object prenom}) => 'تنتظر المتابعة وصول ⁨${prenom}⁩.',
			'classe.observation.motif.presenceEnVerification' => ({required Object prenom}) => 'جارٍ التحقق من حضور ⁨${prenom}⁩.',
			'classe.observation.motif.visiteDejaOuverte' => 'زيارة مفتوحة بالفعل، على هذا الجهاز أو على غيره.',
			'classe.observation.motif.garantieServeurAbsente' => 'متابعة الحصص غير مفتوحة بعد.',
			'classe.observation.motif.reseau' => 'تعذّر التحقق من توفر المتابعة.',
			'classe.observation.motif.capaciteAbsente' => 'المتابعة غير متاحة الآن.',
			'classe.pagePlanning.prochaines' => 'الحصص القادمة',
			'classe.pagePlanning.ligne' => ({required Object heure, required Object duree}) => '⁨${heure}⁩ · ⁨${duree}⁩',
			'classe.pagePlanning.ligneFuseau' => ({required Object heure, required Object fuseau, required Object duree}) => '⁨${heure}⁩ (⁨${fuseau}⁩) · ⁨${duree}⁩',
			'classe.pagePlanning.aucune' => 'لا حصص قادمة حتى الآن',
			'classe.pagePlanning.aucuneDetail' => ({required Object prenom}) => 'ستظهر هنا الحصص القادمة لـ⁨${prenom}⁩ بمجرد جدولتها.',
			'classe.pagePlanning.habituelIndisponible' => 'الأيام المعتادة للفصل لا تظهر هنا بعد: تظهر فقط الحصص المجدولة.',
			'classe.pagePlanning.indisponible' => 'جدول الفصل غير مربوط بهذه المساحة بعد.',
			'classe.pageTravail.aucun' => 'لا شيء للتحضير الآن',
			'classe.pageTravail.aucunDetail' => 'سيظهر هنا العمل الذي يكلّف به المعلم.',
			'classe.pageTravail.indisponible' => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.',
			'classe.pageTravail.echeance' => ({required Object date}) => 'الموعد النهائي: ⁨${date}⁩',
			'classe.pageTravail.nonCochable' => 'لا يمكن بعد تعليم عمل كمنجز من هنا.',
			'classe.pageTravail.statut.aFaire' => 'للإنجاز',
			'classe.pageTravail.statut.enCours' => 'بدأ',
			'classe.pageTravail.statut.fait' => 'منجز',
			'classe.pageTravail.statut.expire' => 'فات الموعد',
			'classe.pageRessources.aucune' => 'لا موارد لهذا الفصل حتى الآن',
			'classe.pageRessources.aucuneDetail' => 'ستظهر هنا المواد التي يختارها المعلم.',
			'classe.pageRessources.indisponible' => 'مكتبة الفصل غير مربوطة بهذه المساحة بعد.',
			'classe.pageProgression.indisponible' => ({required Object prenom}) => 'تقدم ⁨${prenom}⁩ غير مُشارَك هنا بعد.',
			'classe.pageProgression.niveau' => 'المستوى',
			'classe.pageProgression.jalons' => 'المراحل المنجزة',
			'classe.pageProgression.aucune' => 'لا مرحلة مُشارَكة حتى الآن',
			'classe.pageProgression.aucuneDetail' => 'سيظهر هنا التقدم الذي يشاركه المعلم مع الأسرة.',
			'classe.pageCatalogue.pour' => ({required Object prenom}) => 'لـ⁨${prenom}⁩',
			'classe.pageCatalogue.proposees' => 'الفصول المقترحة',
			'classe.pageCatalogue.indisponible' => 'اختيار الفصل عبر الإنترنت غير مفتوح بعد.',
			'classe.pageCatalogue.aucune' => 'لا فصل مناسب الآن',
			'classe.pageCatalogue.aucuneDetail' => ({required Object prenom}) => 'لا فصل مفتوح يناسب ملف ⁨${prenom}⁩ حاليًا.',
			'classe.pageCatalogue.eleveInconnuTitre' => 'هذا الملف ليس في أسرتك',
			'classe.pageCatalogue.eleveInconnuPhrase' => 'عد إلى الرئيسية واختر ملف الطالب المعني.',
			'classe.pageCatalogue.horairesAbsents' => 'أيام هذا الفصل وساعاته لا تظهر هنا بعد.',
			'classe.pageCatalogue.seanceHebdo' => ({required Object jour, required Object heure, required Object duree}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩ · ⁨${duree}⁩ دقيقة',
			'classe.pageCatalogue.fuseauClasse' => ({required Object fuseau}) => 'توقيت الفصل (⁨${fuseau}⁩)',
			'classe.pageCatalogue.placeUne' => 'مقعد واحد متبقٍ',
			'classe.pageCatalogue.places' => ({required Object nombre}) => '⁨${nombre}⁩ مقاعد متبقية',
			'classe.pageCatalogue.etat.ouverte' => 'مفتوح',
			'classe.pageCatalogue.etat.complete' => 'مكتمل',
			'classe.pageCatalogue.etat.listeAttente' => 'قائمة الانتظار',
			'classe.pageCatalogue.choisir' => 'اختيار هذا الفصل',
			'classe.pageCatalogue.rejoindreAttente' => 'الانضمام إلى قائمة الانتظار',
			'classe.pageCatalogue.precisionsTitre' => 'قبل الاختيار',
			'classe.pageCatalogue.precisionEnseignant' => 'يحتفظ الفصل بالمعلم نفسه في كل حصصه.',
			'classe.pageCatalogue.precisionPlaces' => 'المقاعد المعروضة هي مقاعد الأكاديمية لحظة القراءة.',
			'classe.pageCatalogue.precisionReserve' => 'لا شيء محجوز قبل تأكيدك.',
			'classe.pageCatalogue.confirmerTitre' => 'تأكيد الفصل',
			'classe.pageCatalogue.confirmerPhrase' => ({required Object prenom}) => 'أنت تسجّل ⁨${prenom}⁩ في هذا الفصل.',
			'classe.pageCatalogue.confirmerAttentePhrase' => ({required Object prenom}) => 'أنت تسجّل ⁨${prenom}⁩ في قائمة انتظار هذا الفصل.',
			'classe.pageCatalogue.memeEnseignant' => ({required Object enseignant}) => 'الفصل نفسه والمعلم نفسه في كل حصص الأسبوع: ⁨${enseignant}⁩.',
			'classe.pageCatalogue.confirmer' => 'تأكيد التسجيل',
			'classe.pageCatalogue.confirmerAttente' => 'تأكيد قائمة الانتظار',
			'classe.pageCatalogue.envoiIncertain' => 'لم يصل رد الأكاديمية. إعادة المحاولة لا تنشئ تسجيلًا ثانيًا.',
			'classe.pageCatalogue.envoiIndisponible' => 'التسجيل عبر الإنترنت غير مفتوح بعد: لم يُحجز أي مقعد.',
			'classe.pageCatalogue.resultat.inscritTitre' => 'تم تأكيد التسجيل',
			'classe.pageCatalogue.resultat.inscritPhrase' => ({required Object prenom, required Object classe}) => 'ينضم ⁨${prenom}⁩ إلى ⁨${classe}⁩.',
			'classe.pageCatalogue.resultat.voirClasse' => 'عرض الفصل',
			'classe.pageCatalogue.resultat.validationTitre' => 'أُرسل الطلب',
			'classe.pageCatalogue.resultat.validationPhrase' => ({required Object prenom, required Object classe}) => 'ما زال على الأكاديمية اعتماد تسجيل ⁨${prenom}⁩ في ⁨${classe}⁩.',
			'classe.pageCatalogue.resultat.listeAttenteTitre' => 'التسجيل في قائمة الانتظار',
			'classe.pageCatalogue.resultat.listeAttentePhrase' => ({required Object prenom, required Object classe}) => '⁨${prenom}⁩ في قائمة انتظار ⁨${classe}⁩. لم يُحجز أي مقعد حتى الآن.',
			'classe.pageCatalogue.resultat.refuseTitre' => 'لم يُقبل التسجيل',
			'classe.pageCatalogue.resultat.refusePhrase' => ({required Object prenom}) => 'لم يُحجز أي مقعد لـ⁨${prenom}⁩. يمكنك اختيار فصل آخر.',
			'classe.pageCatalogue.resultat.autresClasses' => 'عرض الفصول الأخرى',
			'classe.pageCatalogue.resultat.retourAccueil' => 'العودة إلى الرئيسية',
			'salle.microOuvert' => 'الميكروفون مفتوح',
			'salle.microCoupe' => 'الميكروفون مغلق',
			'salle.cameraAllumee' => 'الكاميرا مشغّلة',
			'salle.cameraCoupee' => 'الكاميرا مطفأة',
			'salle.secours.reseauFaible' => 'الشبكة ضعيفة. الأولوية للصوت.',
			'salle.secours.reseauFaibleGuidee' => 'الشبكة ضعيفة.',
			'salle.secours.reseauFaibleGuideeSuite' => 'الصوت يبقى أولوية.',
			'salle.secours.reconnexion' => 'انقطع الاتصال. جارٍ إعادة الاتصال…',
			'salle.secours.reconnexionGuidee' => 'جارٍ إعادة الاتصال بالحصة…',
			'salle.secours.retablie' => 'عاد الاتصال.',
			'salle.secours.echec' => 'تعذّرت إعادة الاتصال.',
			'salle.secours.echecGuidee' => 'الاتصال لا يعود.',
			'salle.secours.horsLigne' => 'أنت غير متصل. تحتاج الحصة إلى اتصال.',
			'salle.secours.reessayer' => 'إعادة المحاولة',
			'salle.secours.quitter' => 'مغادرة',
			'salle.secours.indisponible' => ({required Object commande}) => '${commande}. غير متاح أثناء إعادة الاتصال.',
			'salle.secours.cameraInterdite' => 'الكاميرا معطّلة لهذا الملف.',
			'salle.secours.microBloque' => 'الميكروفون محظور في إعدادات هذا الجهاز.',
			'salle.secours.microBloqueGuidee' => 'الميكروفون محظور على هذا الجهاز.',
			'salle.secours.continuerSansMicro' => 'المتابعة دون ميكروفون',
			'salle.secours.ouvrirReglages' => 'فتح الإعدادات',
			'salle.preparation.titre' => 'الاستعداد لدخول الفصل',
			'salle.preparation.retour' => 'العودة إلى الفصل',
			'salle.preparation.cameraCoupee' => 'الكاميرا مطفأة',
			'salle.preparation.testerCamera' => 'اختبار الكاميرا',
			'salle.preparation.testCameraFait' => 'انتهى الاختبار المحلي. تبقى الكاميرا مطفأة عند الدخول.',
			'salle.preparation.equipement' => 'أجهزتك',
			'salle.preparation.connexion' => 'الاتصال',
			'salle.preparation.micro' => 'الميكروفون',
			'salle.preparation.sortieAudio' => 'مخرج الصوت',
			'salle.preparation.camera' => 'الكاميرا',
			'salle.preparation.verification' => 'جارٍ التحقق…',
			'salle.preparation.chargement' => 'جارٍ التحقق من الأجهزة…',
			'salle.preparation.connexionPrete' => 'الاتصال جاهز',
			'salle.preparation.connexionInstable' => 'الاتصال غير مستقر',
			'salle.preparation.reseauFaible' => 'الاتصال غير مستقر. الأولوية للصوت.',
			'salle.preparation.microPret' => 'تم العثور على ميكروفون · الميكروفون مغلق عند الدخول',
			'salle.preparation.microAbsent' => 'لم يُعثر على ميكروفون',
			'salle.preparation.microAbsentRaison' => 'لم يُعثر على ميكروفون. وصّل ميكروفونًا أو فعّله لتتمكن من التدريس.',
			'salle.preparation.microBloque' => 'الميكروفون محظور',
			'salle.preparation.permissionRefusee' => 'الميكروفون محظور في إعدادات هذا الجهاز.',
			'salle.preparation.ouvrirReglages' => 'فتح الإعدادات',
			'salle.preparation.reessayer' => 'إعادة المحاولة',
			'salle.preparation.sortieSysteme' => 'مخرج النظام',
			'salle.preparation.cameraPrete' => 'تم العثور على كاميرا · الكاميرا مطفأة عند الدخول',
			'salle.preparation.cameraAbsente' => 'الكاميرا غير متاحة. يمكنك الدخول دون كاميرا.',
			'salle.preparation.modifierPeripheriques' => 'تغيير الأجهزة',
			'salle.preparation.contexte' => 'سياق الحصة',
			'salle.preparation.classe' => 'الفصل',
			'salle.preparation.debut' => 'البداية',
			'salle.preparation.support' => 'المادة المقررة',
			'salle.preparation.reprise' => 'الاستئناف',
			'salle.preparation.eleves' => 'الطلاب المنتظرون',
			'salle.preparation.entrer' => 'دخول الفصل',
			'salle.preparation.terminee' => 'انتهت هذه الحصة.',
			'salle.preparation.nonAssignee' => 'هذه الحصة غير مسندة إليك.',
			'salle.preparation.retourJournee' => 'العودة إلى يومي',
			'salle.preparation.demo.section' => 'استعداد المعلم',
			'salle.preparation.demo.pret' => 'جاهز',
			'salle.preparation.demo.reseauFaible' => 'شبكة ضعيفة',
			'salle.preparation.demo.microAbsent' => 'لا يوجد ميكروفون',
			'salle.preparation.demo.permissionRefusee' => 'الإذن مرفوض',
			'salle.preparation.eleve.verification' => 'نتحقق من جهازك…',
			'salle.preparation.eleve.pret' => 'كل شيء جاهز',
			'salle.preparation.eleve.audio' => 'الصوت',
			'salle.preparation.eleve.acces' => 'الدخول إلى الفصل',
			'salle.preparation.eleve.accesOk' => 'يمكنك الدخول',
			'salle.preparation.eleve.accesAttente' => 'في انتظار الاتصال',
			'salle.preparation.eleve.microCoupe' => 'ستدخل والميكروفون مغلق.',
			'salle.preparation.eleve.microInaccessible' => 'لا يمكن الوصول إلى الميكروفون',
			'salle.preparation.eleve.microInaccessibleDetail' => 'لن يسمعك أحد في الفصل ما دام الوصول إلى الميكروفون محظورًا.',
			'salle.preparation.eleve.autoriserMicro' => 'السماح بالميكروفون',
			'salle.preparation.eleve.guidee.verification' => 'جارٍ تحضير الحصة…',
			'salle.preparation.eleve.guidee.pret' => 'كل شيء جاهز.',
			'salle.preparation.eleve.guidee.microCoupe' => 'سيكون الميكروفون مغلقًا عند الدخول.',
			'salle.preparation.eleve.guidee.microQuestion' => 'الميكروفون محظور. هل نسمح به؟',
			'salle.preparation.eleve.guidee.microBloque' => 'الميكروفون محظور.',
			'salle.preparation.eleve.guidee.horsLigne' => 'الاتصال لا يعمل الآن.',
			'salle.preparation.eleve.demo.section' => 'استعداد الطالب',
			'salle.preparation.eleve.demo.sectionGuidee' => 'استعداد الطالب، وضع إمكانية الوصول',
			'salle.preparation.eleve.demo.verification' => 'التحقق جارٍ',
			'salle.preparation.eleve.demo.pret' => 'جاهز',
			'salle.preparation.eleve.demo.microBloque' => 'الميكروفون محظور',
			'salle.preparation.eleve.demo.horsLigne' => 'غير متصل',
			'salle.bandeauPermanent' => 'يُسجَّل الدرس، وقد تجري زيارة مراقبة.',
			'salle.seance.titre' => 'حصة مباشرة',
			'salle.seance.titreGuidee' => 'حصتي',
			'salle.seance.ligne' => ({required Object debut, required Object fin}) => '⁨${debut}⁩ · ⁨${fin}⁩',
			'salle.seance.minutesRestantes' => ({required Object minutes}) => 'الوقت المتبقي: ⁨${minutes}⁩ د',
			'salle.seance.sePoursuit' => 'الحصة مستمرة.',
			'salle.seance.enLigne' => 'متصل',
			'salle.seance.reconnexion' => 'إعادة الاتصال',
			'salle.seance.coursEnregistreCourt' => 'الدرس مسجَّل.',
			'salle.seance.votreParentObserve' => 'وليّ أمرك يتابع الحصة.',
			'salle.seance.tonParentObserve' => 'وليّ أمرك يتابع الحصة.',
			'salle.seance.tuteurDeObserve' => ({required Object prenom}) => 'وليّ أمر ⁨${prenom}⁩ يتابع.',
			'salle.seance.unParentObserve' => 'وليّ أمر يتابع هذه الحصة',
			'salle.seance.leTuteurDeObserve' => ({required Object prenom}) => 'وليّ أمر ⁨${prenom}⁩ يتابع الحصة.',
			'salle.seance.mentionEtNotice' => ({required Object mention, required Object notice}) => '⁨${mention}⁩ ⁨${notice}⁩',
			'salle.seance.retour' => 'رجوع',
			'salle.seance.notifications' => 'الإشعارات',
			'salle.seance.reglages' => 'الإعدادات',
			'salle.seance.compteDe' => ({required Object nom}) => 'حساب ⁨${nom}⁩',
			'salle.seance.sortir' => 'مغادرة الحصة',
			'salle.seance.commandesAppel' => 'عناصر التحكم في المكالمة',
			'salle.seance.compteurEleves' => ({required Object connectes, required Object inscrits}) => 'الطلاب ⁦⁨${connectes}⁩/⁨${inscrits}⁩⁩',
			'salle.seance.parler' => 'تحدّث',
			'salle.seance.agrandir' => 'تكبير',
			'salle.seance.reduire' => 'تصغير',
			'salle.seance.rienPartage' => ({required Object nom}) => 'لم تصل أي مشاركة من ⁨${nom}⁩ بعد.',
			'salle.seance.videoDe' => ({required Object nom}) => 'فيديو ⁨${nom}⁩',
			'salle.seance.page' => ({required Object page, required Object pages}) => '⁨${page}⁩ / ⁨${pages}⁩',
			'salle.seance.pageSemantique' => ({required Object page, required Object pages}) => 'الصفحة ⁨${page}⁩ من ⁨${pages}⁩',
			'salle.seance.zoomLocal' => 'تكبير محلي، لا يؤثر في الآخرين',
			'salle.seance.zoomValeur' => ({required Object valeur}) => '⁨${valeur}⁩ ٪',
			'salle.seance.zoomMoins' => 'تقليل التكبير',
			'salle.seance.zoomPlus' => 'زيادة التكبير',
			'salle.seance.quitterQuestion' => 'مغادرة الحصة؟',
			'salle.seance.quitterConsequence' => 'يمكنك العودة ما دامت الحصة مفتوحة.',
			'salle.seance.illustration' => 'رسم توضيحي للمادة',
			'salle.seance.quitterCahierConsequence' => 'ستنتقل بعد ذلك إلى دفتر المتابعة.',
			'salle.seance.quitterCahier' => 'المغادرة وفتح دفتر المتابعة',
			'salle.seance.rester' => 'البقاء',
			'salle.seance.supports' => 'المواد',
			'salle.seance.reseau' => 'الشبكة',
			'salle.seance.pagePrecedente' => 'الصفحة السابقة',
			'salle.seance.pageSuivante' => 'الصفحة التالية',
			'salle.seance.outils.titre' => 'أدوات التدريس',
			'salle.seance.outils.pointeur' => 'المؤشر',
			'salle.seance.outils.marquer' => 'وضع علامة',
			'salle.seance.outils.masquer' => 'إخفاء',
			'salle.seance.outils.annoter' => 'كتابة ملاحظات',
			'salle.seance.rail.navigation' => 'التنقل',
			'salle.seance.rail.marque' => 'Rewayah',
			'salle.seance.rail.sousMarque' => 'Academy',
			'salle.seance.rail.journee' => 'يومي',
			'salle.seance.rail.classes' => 'الفصول',
			'salle.seance.rail.ressources' => 'الموارد',
			'salle.seance.rail.profil' => 'الملف الشخصي',
			'salle.seance.fermerPanneau' => 'إغلاق اللوحة',
			'salle.seance.panneauSupports.reprendre' => 'استئناف',
			'salle.seance.panneauSupports.recents' => 'المستخدمة مؤخرًا',
			'salle.seance.panneauSupports.ressourcesClasse' => 'موارد الفصل',
			'salle.seance.panneauSupports.voirTout' => 'عرض الكل',
			'salle.seance.panneauSupports.ouvrir' => 'فتح',
			'salle.seance.panneauSupports.ouvrirSupport' => ({required Object titre}) => 'فتح ⁨${titre}⁩',
			'salle.seance.panneauSupports.voirBibliotheque' => 'عرض المكتبة كاملة',
			'salle.seance.eleves' => 'الطلاب',
			'salle.seance.rappeler' => 'نداء خاص',
			'salle.seance.faireReciter' => 'طلب التلاوة',
			'salle.seance.fileRecitation' => 'ترتيب التلاوة',
			'salle.seance.aSuivre' => 'التالي',
			'salle.seance.vousAppelle' => ({required Object nom}) => 'نداء من ⁨${nom}⁩',
			'salle.seance.signalerBesoin' => 'الإبلاغ عن حاجة',
			'salle.seance.deplierFiche' => ({required Object prenom}) => 'عرض بطاقة ⁨${prenom}⁩',
			'salle.seance.replierFiche' => ({required Object prenom}) => 'إخفاء بطاقة ⁨${prenom}⁩',
			'salle.seance.fiche.aucuneSeanceSemaine' => 'لا حصص هذا الأسبوع',
			'salle.seance.fiche.uneSeanceSemaine' => 'حصة واحدة هذا الأسبوع',
			'salle.seance.fiche.seancesSemaine' => ({required Object nombre}) => 'عدد الحصص هذا الأسبوع: ⁨${nombre}⁩',
			'salle.seance.optionsPanneau' => ({required Object titre}) => 'خيارات لوحة ⁨${titre}⁩',
			'salle.seance.commandes.declencheur' => 'التحكم',
			'salle.seance.commandes.declencheurSemantique' => 'فتح عناصر التحكم في المادة والسبورة',
			'salle.seance.commandes.titre' => 'عناصر التحكم',
			'salle.seance.commandes.reduire' => 'تصغير',
			'salle.seance.commandes.reduireSemantique' => 'تصغير عناصر التحكم',
			'salle.seance.commandes.ongletSupport' => 'المادة',
			'salle.seance.commandes.ongletOutils' => 'الأدوات',
			'salle.seance.commandes.bibliotheque' => 'المكتبة',
			'salle.seance.commandes.affichageSupport' => 'المادة',
			'salle.seance.commandes.affichageAvecNotes' => 'مع الملاحظات',
			'salle.seance.commandes.affichageTableau' => 'السبورة',
			'salle.seance.commandes.lecture' => 'القراءة',
			'salle.seance.commandes.ajuster' => 'ملاءمة الشاشة',
			'salle.seance.commandes.affichage' => 'العرض',
			'salle.seance.commandes.focus' => 'التركيز',
			'salle.seance.commandes.focusSemantique' => 'التركيز، تكبير المحتوى وتصغير اللوحات',
			'salle.seance.commandes.quitterFocus' => 'الخروج من التركيز',
			'salle.seance.bibliotheque.intro' => 'المادة التي تختارها تُفتح لك وحدك. يبقى الفصل على المادة الحالية حتى «عرض على الفصل».',
			'salle.seance.bibliotheque.apercu' => 'معاينة خاصة',
			'salle.seance.bibliotheque.apercuClasse' => 'ما زال الطلاب يرون المادة الحالية.',
			'salle.seance.bibliotheque.presenter' => 'عرض على الفصل',
			'salle.seance.bibliotheque.revenir' => 'العودة إلى المواد',
			'salle.seance.bibliotheque.ouverture' => 'جارٍ فتح المادة…',
			'salle.seance.bibliotheque.echec' => 'تعذّر فتح الملف.',
			'salle.seance.bibliotheque.echecDetail' => 'تعذّر تحميل ملف هذه المادة. أعد المحاولة، أو عد إلى المواد لاختيار مادة أخرى.',
			'salle.seance.surface.aucunSupport' => 'اختر مادة أو اكتب على السبورة.',
			'salle.seance.surface.page' => ({required Object titre, required Object page, required Object pages}) => '⁨${titre}⁩، الصفحة ⁨${page}⁩ من ⁨${pages}⁩',
			'salle.seance.surface.supportMasque' => 'السبورة، المادة مخفية',
			'salle.seance.capsule.avatar' => ({required Object nom}) => 'عرض معلومات ⁨${nom}⁩',
			'salle.seance.capsule.controlePossible' => 'المراقبة ممكنة. عرض المعلومات',
			'salle.seance.capsule.controleActif' => 'المراقبة جارية. عرض المعلومات',
			'salle.seance.capsule.enregistrementActif' => 'التسجيل جارٍ',
			'salle.seance.contexte.titre' => 'معلومات الحصة',
			'salle.seance.contexte.reseau' => 'الشبكة',
			'salle.seance.contexte.detailReseau' => 'تفاصيل الشبكة',
			'salle.seance.contexte.enregistrementActif' => 'التسجيل جارٍ',
			'salle.seance.contexte.controle' => 'المراقبة',
			'salle.seance.contexte.controlePossible' => 'المراقبة ممكنة',
			'salle.seance.contexte.controleActif' => 'المراقبة جارية',
			'salle.seance.contexte.controlePossibleDetail' => 'قد تجري زيارة مراقبة. هذا لا يعني أن أحدًا يتابع الآن.',
			'salle.seance.contexte.controleActifDetail' => 'تجري زيارة مراقبة الآن.',
			'salle.seance.contexte.reduire' => 'تصغير',
			'salle.seance.contexte.reduireParticipants' => 'تصغير المشاركين',
			'salle.seance.contexte.reduireInformations' => 'تصغير المعلومات',
			'salle.seance.demo.titre' => 'قاعة العرض التجريبي',
			'salle.seance.demo.intro' => 'بيانات وهمية، دون خادم. اختر دورًا وحالة.',
			'salle.seance.demo.groupes.seance' => 'مجرى الحصة',
			'salle.seance.demo.groupes.secours' => 'حالات الطوارئ',
			'salle.seance.demo.groupes.tableau' => 'المواد والسبورة',
			'salle.seance.demo.roles.eleve' => 'طالب عادي',
			'salle.seance.demo.roles.guidee' => 'وضع إمكانية الوصول',
			'salle.seance.demo.roles.enseignant' => 'المعلم',
			'salle.seance.demo.etats.repos' => 'وضع عادي',
			'salle.seance.demo.etats.visite' => 'زيارة',
			'salle.seance.demo.etats.rienPartage' => 'لا شيء مُشارَك',
			'salle.seance.demo.etats.appel' => 'نداء خاص',
			'salle.seance.demo.etats.eleves' => 'لوحة الطلاب',
			'salle.seance.demo.etats.supports' => 'لوحة المواد',
			'salle.seance.demo.etats.fin' => 'نهاية الحصة',
			'salle.seance.demo.etats.reseauFaible' => 'شبكة ضعيفة',
			'salle.seance.demo.etats.reconnexion' => 'إعادة الاتصال',
			'salle.seance.demo.etats.retablie' => 'عاد الاتصال',
			'salle.seance.demo.etats.echec' => 'تعذّرت إعادة الاتصال',
			'salle.seance.demo.etats.horsLigne' => 'غير متصل',
			'salle.seance.demo.etats.microBloque' => 'الميكروفون محظور',
			'salle.seance.demo.etats.cameraInterdite' => 'الكاميرا ممنوعة',
			'salle.seance.demo.etats.prolongee' => 'حصة ممدَّدة',
			'salle.seance.demo.etats.accesRetire' => 'سُحب الدخول',
			'salle.seance.demo.tb.sal00' => 'SAL-00 القاعة والأشخاص',
			'salle.seance.demo.tb.ped01' => 'PED-01 سبورة حرة، دون مادة',
			'salle.seance.demo.tb.ped02' => 'PED-02 المادة وحدها',
			'salle.seance.demo.tb.ped03' => 'PED-03 المادة مع الملاحظات',
			'salle.seance.demo.tb.ped04' => 'PED-04 السبورة، المادة مخفية',
			'salle.seance.demo.tb.ui01' => 'UI-01 عرض مضغوط',
			'salle.seance.demo.tb.ui02' => 'UI-02 قاعة موسَّعة',
			'salle.seance.demo.tb.ui03' => 'UI-03 تركيز محلي',
			'salle.seance.demo.tb.vis01' => 'VIS-01 شريط الفيديو ظاهر',
			'salle.seance.demo.tb.ctx01' => 'CTX-01 سياق الحصة',
			'salle.seance.demo.tb.ctx02' => 'CTX-02 معلومات المراقبة',
			'salle.seance.demo.tb.cmd01' => 'CMD-01 عناصر التحكم',
			'salle.seance.demo.tb.cmd02' => 'CMD-02 اللون والسُّمك',
			'salle.seance.demo.tb.cmd03' => 'CMD-03 الكتابة جارية',
			'salle.seance.demo.tb.lib01' => 'LIB-01 المكتبة',
			'salle.seance.demo.tb.lib02' => 'LIB-02 معاينة خاصة',
			'salle.seance.demo.tb.lib03' => 'LIB-03 فتح المادة',
			'salle.seance.demo.tb.lib04' => 'LIB-04 بحث دون نتيجة',
			'salle.seance.demo.tb.per01' => 'PER-01 المشاركون والأذونات',
			'salle.seance.demo.tb.dlg01' => 'DLG-01 مسح ملاحظات الصفحة',
			'salle.seance.demo.tb.err01' => 'ERR-01 انقطعت المزامنة',
			'salle.seance.demo.tb.err02' => 'ERR-02 استعادة السبورة',
			'salle.seance.demo.tb.err03' => 'ERR-03 فشل الحفظ',
			'salle.seance.demo.tb.end01' => 'END-01 مغادرة الحصة',
			'salle.seance.demo.tb.supportArrive' => 'المادة في الطريق',
			'salle.seance.demo.tb.ressourceIndisponible' => 'المورد غير متاح',
			'salle.seance.demo.tb.autorisationEcrire' => 'إذن بالكتابة',
			'salle.seance.demo.tb.droitRetire' => 'سُحب الإذن',
			'salle.seance.demo.tb.effacementTableau' => 'مسح ملاحظات السبورة',
			'salle.seance.statut.connecte' => 'متصل',
			'salle.seance.statut.pasEncoreConnecte' => 'لم يتصل بعد',
			'salle.seance.statut.connexionInterrompue' => 'انقطع الاتصال',
			'salle.fin.titre' => 'انتهت الحصة',
			'salle.fin.phrase' => 'تجد عملك في فصلك.',
			'salle.fin.retourClasse' => 'العودة إلى الفصل',
			'salle.fin.quitteTitre' => 'غادرت الحصة.',
			'salle.fin.quittePhrase' => 'يمكنك العودة ما دامت مفتوحة.',
			'salle.fin.accesRetireTitre' => 'انتهى دخولك إلى هذه الحصة.',
			'salle.fin.titreGuidee' => 'انتهت الحصة.',
			'salle.fin.retourAccueil' => 'العودة إلى الصفحة الرئيسية',
			'salle.fin.enseignant.terminee' => 'منتهية',
			'salle.fin.enseignant.phrase' => 'دفتر المتابعة جاهز بمعلومات الحصة.',
			'salle.fin.enseignant.recapitulatif' => 'ملخص الحصة',
			_ => null,
		} ?? switch (path) {
			'salle.fin.enseignant.fin' => 'النهاية',
			'salle.fin.enseignant.connectes' => ({required Object n}) => 'الطلاب المتصلون: ⁨${n}⁩',
			'salle.fin.enseignant.unConnecte' => ({required Object n}) => 'الطلاب المتصلون: ⁨${n}⁩',
			'salle.fin.enseignant.inscrits' => ({required Object n}) => 'من أصل ⁨${n}⁩',
			'salle.fin.enseignant.unInscrit' => ({required Object n}) => 'من ⁨${n}⁩ مسجَّل',
			'salle.fin.enseignant.cahierSeance' => 'دفتر المتابعة',
			'salle.fin.enseignant.cahierACompleter' => 'دفتر المتابعة بانتظار الإكمال',
			'salle.fin.enseignant.ouvrirCahier' => 'فتح دفتر المتابعة',
			'salle.fin.enseignant.revenirJournee' => 'العودة إلى يومي',
			'salle.fin.enseignant.erreurCahier' => 'تعذّر فتح دفتر المتابعة الآن. أعد المحاولة بعد لحظة.',
			'salle.micro' => 'الميكروفون',
			'salle.camera' => 'الكاميرا',
			'salle.quitter' => 'مغادرة',
			'salle.ouvrirCoran' => 'فتح القرآن',
			'salle.confirmerSortie' => 'مغادرة الدرس؟',
			'salle.expiree' => 'لم تعد هذه القاعة متاحة. عد إلى صفحتك الرئيسية للانضمام إلى الدرس القادم.',
			'salle.ouverture' => 'جارٍ فتح القاعة',
			'salle.verificationMateriel' => 'جارٍ التحقق من الميكروفون',
			'salle.connexion' => 'جارٍ الاتصال بالدرس',
			'salle.reconnexion' => 'الاتصال غير مستقر، جارٍ إعادة الاتصال',
			'salle.reconnexionCourt' => 'إعادة الاتصال',
			'salle.perdue' => 'انقطع الاتصال بالدرس',
			'salle.seulEnseignant' => 'لم يصل معلمك بعد',
			'salle.seulEnseignantDetail' => 'ابقَ على هذه الشاشة. ستراه يظهر.',
			'salle.seulEleve' => 'لم يصل طالبك بعد',
			'salle.seulEleveDetail' => 'ابقَ على هذه الشاشة. ستراه يظهر.',
			'salle.seulObservation' => 'لم يدخل أحد هذه القاعة بعد',
			'salle.seulObservationDetail' => 'لم يبدأ الدرس، أو انتهى بالفعل.',
			'salle.refusAcces' => 'هذا الدرس غير مفتوح لك الآن',
			'salle.refusAccesDetail' => 'تُفتح القاعة قبل موعد الدرس بعشر دقائق، وتُغلق بعد نهايته بربع ساعة.',
			'salle.refusConfiguration' => 'القاعة غير متاحة بعد',
			'salle.refusConfigurationDetail' => 'المشكلة ليست في جهازك: خدمة مكالمات الفيديو غير موصولة. الفريق على علم بذلك.',
			'salle.refusReseau' => 'لم تستجب القاعة',
			'salle.refusReseauDetail' => 'تحقّق من اتصالك، ثم أعد المحاولة.',
			'salle.refusMateriel' => 'لا يوجد ميكروفون صالح على هذا الجهاز',
			'salle.refusMaterielDetail' => 'درس القرآن يكون بالصوت. اسمح بالوصول إلى الميكروفون، أو وصّل سماعة، ثم أعد المحاولة.',
			'salle.retourAccueil' => 'العودة إلى صفحتي الرئيسية',
			'salle.ouvrirMicro' => 'فتح الميكروفون',
			'salle.fermerMicro' => 'إغلاق الميكروفون',
			'salle.ouvrirCamera' => 'تشغيل الكاميرا',
			'salle.fermerCamera' => 'إطفاء الكاميرا',
			'salle.quitterLeCours' => 'مغادرة الدرس',
			'salle.consequenceSortie' => 'يستمر الدرس دونك، ويُسجَّل خروجك في الحصة.',
			'salle.vousMeme' => 'أنت',
			'salle.sansImage' => 'دون صورة',
			'salle.lienMediocre' => 'اتصال ضعيف',
			'salle.lienPerdu' => 'انقطع الاتصال',
			'salle.videoSuspendue' => 'توقفت الصورة إلى أن يعود الاتصال. الصوت مستمر.',
			'salle.roleEnseignant' => 'المعلم',
			'salle.roleEleve' => 'الطالب',
			'salle.roleTuteur' => 'وليّ الأمر، متابِع',
			'salle.roleAdministration' => 'إدارة Rewayah',
			'salle.observationMuette' => 'أنت تحضر الدرس. لا أحد يسمعك.',
			'salle.observationMuetteTitre' => 'أنت تحضر الدرس.',
			'salle.bandeauControle' => 'زيارة مراقبة. لا أحد يراك أو يسمعك، ويُسجَّل مرورك في السجل.',
			'salle.bandeauControleTitre' => 'زيارة مراقبة.',
			'salle.visiteControle.titre' => 'مراقبة Rewayah',
			'salle.visiteControle.sonRecu' => 'الصوت الوارد مفتوح',
			'salle.visiteControle.sonCoupe' => 'الصوت الوارد مكتوم',
			'salle.visiteControle.couperSon' => 'كتم الصوت الوارد',
			'salle.visiteControle.retablirSon' => 'إعادة الصوت الوارد',
			'salle.visiteControle.agrandir' => 'تكبير المادة',
			'salle.visiteControle.reduire' => 'تصغير المادة',
			'eleve.suivi.titre' => 'متابعة دروسي',
			'eleve.suivi.colonneDate' => 'التاريخ',
			'eleve.suivi.colonneCours' => 'الدرس',
			'eleve.suivi.colonneEnseignant' => 'المعلم',
			'eleve.suivi.colonneEtat' => 'الحضور',
			'eleve.suivi.cours' => 'درس القرآن',
			'eleve.suivi.moi' => 'حضوري',
			'eleve.suivi.aujourdhui' => ({required Object heure}) => 'اليوم، ⁨${heure}⁩',
			'eleve.suivi.hier' => ({required Object heure}) => 'أمس، ⁨${heure}⁩',
			'eleve.suivi.date' => ({required Object date, required Object heure}) => '⁨${date}⁩، ⁨${heure}⁩',
			'eleve.suivi.annule' => 'درس ملغى',
			'eleve.suivi.nonTenu' => 'درس لم يُعقد',
			'eleve.suivi.vide' => 'لا توجد دروس حتى الآن',
			'eleve.suivi.videDetail' => 'ستظهر دروسك هنا من الأحدث إلى الأقدم مع حالة حضورك.',
			'eleve.suivi.erreur' => 'تعذرت قراءة المتابعة. حاول مرة أخرى بعد قليل.',
			'eleve.suivi.tronquee' => ({required Object nombre}) => 'تظهر أحدث الدروس، وعددها ⁨${nombre}⁩.',
			'eleve.suivi.fin' => ({required Object nombre}) => 'عدد الدروس في المتابعة: ⁨${nombre}⁩.',
			'eleve.suivi.finUn' => 'درس واحد في المتابعة.',
			'eleve.accueil.rejoindre' => 'انضمام',
			'eleve.accueil.coran' => 'القرآن',
			'eleve.accueil.coranDetail' => 'اقرأه متى شئت',
			'eleve.accueil.coranEcouter' => 'استمع: القرآن',
			'eleve.accueil.prochainCours' => 'الدرس القادم',
			'eleve.accueil.coursEnDirect' => 'بدأ درسك',
			'eleve.accueil.avec' => ({required Object prenom}) => 'مع ⁨${prenom}⁩',
			'eleve.accueil.dansMinutes' => ({required Object minutes}) => 'بعد ⁨${minutes}⁩ دقيقة',
			'eleve.accueil.dansHeures' => ({required Object heures, required Object minutes}) => 'بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'eleve.accueil.imminent' => 'حان الوقت تقريبًا',
			'eleve.accueil.aucunCours' => 'لا دروس اليوم',
			'eleve.accueil.aucunCoursDetail' => 'معلمك يحضّر الدرس القادم.',
			'eleve.accueil.erreurCours' => 'تعذّرت قراءة دروسك. أعد المحاولة بعد لحظة.',
			'eleve.accueil.prochainAujourdhui' => 'درسك القادم لاحقًا اليوم.',
			'eleve.accueil.prochainDemain' => 'درسك القادم غدًا.',
			'eleve.accueil.prochainDansJours' => ({required Object jours}) => 'درسك القادم بعد ⁨${jours}⁩ أيام.',
			'eleve.accueil.annulee' => 'لن يُعقد هذا الدرس',
			'eleve.accueil.horsLigne' => 'لا شبكة',
			'eleve.accueil.horsLigneDetail' => 'يمكنك الدخول بمجرد عودة الشبكة.',
			'eleve.accueil.pausePriere' => 'استراحة للصلاة',
			'eleve.accueil.pausePriereDetail' => ({required Object priere, required Object heure}) => '⁨${priere}⁩، نحو ⁨${heure}⁩',
			'eleve.coran.titre' => 'القرآن',
			'eleve.coran.page' => ({required Object page, required Object total}) => 'الصفحة ⁨${page}⁩ من ⁨${total}⁩',
			'eleve.coran.juz' => ({required Object juz}) => 'الجزء ⁨${juz}⁩',
			'eleve.coran.mecquoise' => 'مكية',
			'eleve.coran.medinoise' => 'مدنية',
			'eleve.coran.reprendre' => 'متابعة القراءة',
			'eleve.coran.reprendreDetail' => ({required Object page}) => 'كنت في الصفحة ⁨${page}⁩',
			'eleve.coran.chargement' => 'النص في الطريق',
			'eleve.coran.indisponible' => 'تعذّر تحميل النص',
			'eleve.coran.indisponibleDetail' => 'بمجرد عودة الشبكة، تُفتح صفحتك هنا من جديد.',
			'eleve.coran.reessayer' => 'إعادة المحاولة',
			'eleve.coran.absent' => 'هذه الصفحة فارغة',
			'eleve.coran.absentDetail' => 'لم يُثبَّت النص في هذه الصفحة. أبلغ عن ذلك: الخطأ ليس منك.',
			'eleve.coran.pagePrecedente' => 'الصفحة السابقة',
			'eleve.coran.pageSuivante' => 'الصفحة التالية',
			'eleve.coran.reglages' => 'إعدادات القراءة',
			'eleve.coran.fermerReglages' => 'إغلاق الإعدادات',
			'eleve.coran.taille' => 'حجم النص',
			'eleve.coran.agrandir' => 'تكبير النص',
			'eleve.coran.reduire' => 'تصغير النص',
			'eleve.coran.source' => 'نص القرآن: Tanzil Project',
			'eleve.coran.sourceLien' => 'tanzil.net',
			'eleve.coran.edition' => 'مصحف المدينة، رواية حفص',
			'enseignant.journee.derniereSeance' => 'آخر حصة',
			'enseignant.journee.rejoindreSalle' => 'الدخول إلى القاعة',
			'enseignant.journee.rejoindreSalleLecteur' => ({required Object classe}) => 'الدخول إلى قاعة الفصل ⁨${classe}⁩',
			'enseignant.journee.remplirCahier' => 'تعبئة دفتر المتابعة',
			'enseignant.journee.remplirCahierLecteur' => ({required Object classe}) => 'تعبئة دفتر المتابعة للفصل ⁨${classe}⁩',
			'enseignant.journee.cahierObligatoire' => ({required Object classe}) => 'إلزامي: يُعبَّأ دفتر المتابعة للفصل ⁨${classe}⁩ في نهاية كل حصة.',
			'enseignant.journee.voirCahier' => ({required Object classe}) => 'عرض دفتر المتابعة للفصل ⁨${classe}⁩',
			'enseignant.journee.voirCahierLecteur' => ({required Object classe}) => 'عرض دفتر المتابعة للفصل ⁨${classe}⁩',
			'enseignant.journee.lancer' => 'بدء الدرس',
			'enseignant.journee.preflight' => 'التحقق قبل الدرس',
			'enseignant.journee.titre' => 'اليوم',
			'enseignant.journee.prochainCours' => 'الدرس القادم',
			'enseignant.journee.coursEnCours' => 'حصة مباشرة',
			'enseignant.journee.minuteurHeures' => ({required Object heures, required Object minutes}) => 'بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'enseignant.journee.minuteurMinutes' => ({required Object minutes}) => 'بعد ⁨${minutes}⁩ دقيقة',
			'enseignant.journee.minuteurImminent' => 'يبدأ الآن',
			'enseignant.journee.jusqua' => ({required Object heure}) => 'حتى ⁨${heure}⁩',
			'enseignant.journee.unAutreJour' => ({required Object jour, required Object heure}) => '⁨${jour}⁩، الساعة ⁨${heure}⁩',
			'enseignant.journee.lancementPlusTard' => 'يُتاح البدء قبل موعد الدرس بعشر دقائق.',
			'enseignant.journee.aucunCours' => 'لا دروس قادمة',
			'enseignant.journee.aucunCoursDetail' => 'اقبل طالبًا في الانتظار: هذا ما يملأ يومك.',
			'enseignant.journee.colonne' => 'اليوم',
			'enseignant.journee.ligneCours' => ({required Object prenom}) => 'درس مع ⁨${prenom}⁩',
			'enseignant.journee.lignePause' => 'استراحة',
			'enseignant.journee.plage' => ({required Object debut, required Object fin}) => '⁨${debut}⁩ إلى ⁨${fin}⁩',
			'enseignant.journee.duree' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة',
			'enseignant.journee.rienAujourdhui' => 'لا شيء مقرر اليوم',
			'enseignant.journee.rienAujourdhuiDetail' => ({required Object jour, required Object heure}) => 'درسك القادم ⁨${jour}⁩ الساعة ⁨${heure}⁩.',
			'enseignant.journee.journeeTerminee' => ({required Object nombre}) => 'عدد الدروس المقدَّمة اليوم: ⁨${nombre}⁩.',
			'enseignant.journee.journeeTermineeUn' => 'درس واحد قُدِّم اليوم.',
			'enseignant.journee.voirCreneaux' => 'عرض مواعيدي',
			'enseignant.journee.erreur' => 'تعذّرت قراءة اليوم كاملًا. أعد المحاولة بعد لحظة.',
			'enseignant.journee.coursIndividuel' => 'درس فردي',
			'enseignant.journee.effectif' => ({required Object nombre}) => '⁨${nombre}⁩ طلاب',
			'enseignant.journee.effectifUn' => 'طالب واحد',
			'enseignant.journee.preflightOk' => 'الميكروفون جاهز',
			'enseignant.journee.preflightBloque' => 'متصفحك يحظر الميكروفون. اسمح به لبدء الدرس.',
			'enseignant.journee.preflightSansMicro' => 'لم يُعثر على ميكروفون. وصّل واحدًا لبدء الدرس.',
			'enseignant.journee.preflightIndisponible' => 'لم يكتمل التحقق من الأجهزة. أعد المحاولة قبل بدء الدرس.',
			'enseignant.journee.lancerHorsLigne' => 'دون شبكة، لا يمكن فتح القاعة. أعد الاتصال لبدء الدرس.',
			'enseignant.journee.erreurPartielle' => 'تعذّر تحميل أوقات الصلاة واستراحاتك (اتصال غير مستقر أو خدمة غير متاحة مؤقتًا). الحصص المعروضة محدَّثة: يمكنك بدؤها بشكل عادي.',
			'enseignant.journee.absenceDetectee' => ({required Object eleve}) => 'لم يدخل ⁨${eleve}⁩ القاعة.',
			'enseignant.journee.coupureDetectee' => ({required Object eleve}) => 'انقطع اتصال ⁨${eleve}⁩.',
			'enseignant.journee.coursAnnule' => ({required Object heure}) => 'أُلغي درس الساعة ⁨${heure}⁩.',
			'enseignant.journee.rapportsTitre' => 'تقارير بانتظار الإيداع',
			'enseignant.journee.rapportLigne' => ({required Object jour, required Object heure}) => 'درس ⁨${jour}⁩ الساعة ⁨${heure}⁩',
			'enseignant.journee.rapportAttente' => ({required Object heures}) => 'للإيداع منذ ⁨${heures}⁩ س',
			'enseignant.journee.rapportRetard' => ({required Object heures}) => 'متأخر ⁨${heures}⁩ س',
			'enseignant.journee.enAttenteTitre' => 'طلاب في الانتظار',
			'enseignant.journee.enAttenteLibelle' => 'طلاب في الانتظار في ساعاتك',
			'enseignant.journee.enAttenteLibelleUn' => 'طالب في الانتظار في ساعاتك',
			'enseignant.journee.prochaineSeance' => 'الحصة القادمة',
			'enseignant.journee.maJournee' => 'يومي',
			'enseignant.journee.aTerminer' => 'للإنهاء',
			'enseignant.journee.aTerminerVide' => 'كل دفاترك منتهية.',
			'enseignant.journee.aTerminerErreur' => 'تعذّرت قراءة الدفاتر المطلوب إنهاؤها. أعد المحاولة بعد لحظة.',
			'enseignant.journee.aTerminerAide' => 'دفتر المتابعة يساعد طلابك ويتيح لك تعديل الدرس القادم.',
			'enseignant.journee.rappelCahier' => 'دفاتر متابعة تنتظر الإنهاء',
			'enseignant.journee.cahierLigne' => ({required Object classe}) => 'دفتر متابعة ⁨${classe}⁩',
			'enseignant.journee.cahierDetail' => ({required Object jour, required Object numero, required Object mois, required Object heure}) => 'حصة ⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩ الساعة ⁨${heure}⁩',
			'enseignant.journee.alertesUtiles' => 'تنبيهات مفيدة',
			'enseignant.journee.alertesVide' => 'لا تنبيهات مفيدة الآن.',
			'enseignant.journee.alertesErreur' => 'تعذّرت قراءة تنبيهات الحضور: لم يستجب الاتصال أو الخادم. أعد المحاولة بعد لحظة.',
			'enseignant.journee.voirAutreAlerte' => 'عرض التنبيه الآخر',
			'enseignant.journee.voirAutresAlertes' => ({required Object nombre}) => 'عرض التنبيهات الأخرى (⁨${nombre}⁩)',
			'enseignant.journee.remplacementsTitre' => 'الاستخلافات المؤكَّدة',
			'enseignant.journee.remplacementsVide' => 'لا درس لزميل تتولاه الآن.',
			'enseignant.journee.voirTousRemplacements' => ({required Object nombre}) => 'عرض الكل: الاستخلافات المؤكَّدة (⁨${nombre}⁩)',
			'enseignant.journee.heure' => 'الساعة',
			'enseignant.journee.eleves' => 'الطلاب',
			'enseignant.journee.classe' => 'الفصل',
			'enseignant.journee.classeNommee' => ({required Object classe}) => 'الفصل ⁨${classe}⁩',
			'enseignant.journee.preparerSeance' => 'تحضير الحصة',
			'enseignant.journee.preparerSeanceLecteur' => ({required Object classe}) => 'تحضير حصة ⁨${classe}⁩',
			'enseignant.journee.voirClasse' => 'عرض الفصل',
			'enseignant.journee.voirClasseLecteur' => ({required Object classe}) => 'عرض الفصل ⁨${classe}⁩',
			'enseignant.journee.aucuneSeance' => 'لا حصص قادمة',
			'enseignant.journee.aucuneSeanceDetail' => 'ستظهر هنا حصصك القادمة.',
			'enseignant.journee.date' => ({required Object jour, required Object numero, required Object mois}) => '⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩',
			'enseignant.journee.absence.ouvrir' => 'الإبلاغ عن غيابي في هذه الحصة',
			'enseignant.journee.absence.ouvrirContexte' => 'سيُبحث عن بديل لطلابك.',
			'enseignant.journee.absence.titre' => 'لن تستطيع تولي هذه الحصة؟',
			'enseignant.journee.absence.cleDate' => 'التاريخ',
			'enseignant.journee.absence.notice' => 'يبقى إسنادك إلى الفصل كما هو.',
			'enseignant.journee.absence.declarer' => 'التصريح بغيابي',
			'enseignant.journee.absence.echec' => 'لم يكتمل الطلب. أعد المحاولة بعد لحظة.',
			'enseignant.journee.absence.etats.enregistree' => 'سُجِّل الغياب',
			'enseignant.journee.absence.etats.recherche' => 'جارٍ البحث عن بديل',
			'enseignant.journee.absence.etats.remplacantConfirme' => 'البديل مؤكَّد',
			'enseignant.journee.absence.etats.aucunRemplacant' => 'لا بديل مؤكَّد',
			'enseignant.journee.absence.etats.seanceAnnulee' => 'أُلغيت الحصة',
			'enseignant.journee.absence.etats.demandeAnnulee' => 'أُلغي الطلب',
			'enseignant.journee.remplacement.titre' => 'تولي هذا الاستخلاف؟',
			'enseignant.journee.remplacement.assurer' => 'تولي هذا الاستخلاف',
			'enseignant.journee.remplacement.pasCetteFois' => 'ليس هذه المرة',
			'enseignant.ficheGroupe.elevesTitre' => 'الطلاب',
			'enseignant.ficheGroupe.preparationTitre' => 'للتحضير',
			'enseignant.ficheGroupe.supportPrevu' => 'المادة المقررة',
			'enseignant.ficheGroupe.positionReprise' => 'موضع الاستئناف',
			'enseignant.ficheGroupe.objectif' => 'الهدف',
			'enseignant.ficheGroupe.preparationVide' => 'لم يُسجَّل أي تحضير لهذه الحصة.',
			'enseignant.ficheGroupe.supportsTitre' => 'أحدث المواد',
			'enseignant.ficheGroupe.repriseEleve' => ({required Object page}) => 'نقطة الاستئناف: ⁨${page}⁩',
			'enseignant.ficheGroupe.dernierPoint' => ({required Object texte}) => 'آخر ملاحظة: ⁨${texte}⁩',
			'enseignant.ficheGroupe.chargementClasse' => 'جارٍ تحميل الفصل.',
			'enseignant.ficheGroupe.creneauHebdo' => ({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩، كل أسبوع',
			'enseignant.ficheGroupe.aucunMembre' => 'لا طالب في هذا الفصل',
			'enseignant.ficheGroupe.aucunMembreDetail' => 'الإدارة تكوّن الفصول: هذا الفصل ليس فيه طالب بعد.',
			'enseignant.ficheGroupe.erreur' => 'تعذّرت قراءة هذا الفصل. أعد المحاولة بعد لحظة.',
			'enseignant.ficheGroupe.introuvable' => 'هذا الفصل ليس من فصولك',
			'enseignant.ficheGroupe.introuvableDetail' => 'ربما أُغلق، أو هو لمعلم آخر.',
			'enseignant.ficheGroupe.revue' => 'فتح مراجعة الفصل',
			'enseignant.ficheGroupe.ressourcesTitre' => 'الموارد الأخيرة',
			'enseignant.ficheGroupe.progressionTitre' => 'تقدم الفصل',
			'enseignant.classes.titre' => 'الفصول',
			'enseignant.classes.vide' => 'لا فصل مسند إليك',
			'enseignant.classes.videDetail' => 'ستظهر هنا الفصول المؤكَّدة.',
			'enseignant.classes.erreur' => 'تعذّرت قراءة فصولك. أعد المحاولة بعد لحظة.',
			'enseignant.classes.chargement' => 'جارٍ تحميل فصولك.',
			'enseignant.classes.niveau' => ({required Object niveau}) => 'المستوى ⁨${niveau}⁩',
			'enseignant.classes.eleveUn' => 'طالب واحد',
			'enseignant.classes.eleves' => ({required Object nombre}) => '⁨${nombre}⁩ طلاب',
			'enseignant.classes.prochaine' => ({required Object jour, required Object heure}) => 'الحصة القادمة: ⁨${jour}⁩ الساعة ⁨${heure}⁩',
			'enseignant.classes.sansProchaine' => 'لا حصة مقررة',
			'enseignant.classes.remplacement' => 'استخلاف',
			'enseignant.classes.rappelCahier' => 'دفتر متابعة ينتظر التأكيد',
			'enseignant.classes.cahierAValider' => 'دفتر المتابعة بانتظار التأكيد',
			'enseignant.eleve.titre' => ({required Object prenom}) => 'بطاقة ⁨${prenom}⁩',
			'enseignant.eleve.retour' => 'الطلاب',
			'enseignant.eleve.identifiant' => ({required Object id}) => 'معرّف الأكاديمية: ⁨${id}⁩',
			'enseignant.eleve.photo' => ({required Object prenom}) => 'صورة ⁨${prenom}⁩',
			'enseignant.eleve.niveau' => 'المستوى',
			'enseignant.eleve.objectif' => 'الهدف',
			'enseignant.eleve.presence' => 'الحضور الأخير',
			'enseignant.eleve.travail' => 'العمل',
			'enseignant.eleve.travailReprise' => ({required Object page}) => 'الاستئناف من ⁨${page}⁩',
			'enseignant.eleve.derniereSeance' => 'آخر حصة',
			'enseignant.eleve.nonRenseigne' => 'غير محدد',
			'enseignant.eleve.signaler' => 'الإشارة إلى حاجة',
			'enseignant.eleve.signalerAide' => 'حاجة تُرفع إلى الأكاديمية، دون إعادة كتابة السياق.',
			'enseignant.signalement.titre' => 'الإشارة إلى حاجة',
			'enseignant.signalement.contexte' => ({required Object prenom, required Object classe}) => 'لـ⁨${prenom}⁩ · ⁨${classe}⁩',
			'enseignant.signalement.categorieTitre' => 'الفئة',
			'enseignant.signalement.categories.pedagogique' => 'مشكلة تعليمية',
			'enseignant.signalement.categories.presence' => 'الحضور',
			'enseignant.signalement.categories.technique' => 'تقنية',
			'enseignant.signalement.categories.changement' => 'تغيير',
			'enseignant.signalement.categories.autre' => 'أخرى',
			'enseignant.signalement.details' => 'تفاصيل داخلية',
			'enseignant.signalement.detailsAide' => 'يقرؤها فريق الأكاديمية فقط.',
			'enseignant.signalement.resume' => 'ملخص قابل للمشاركة',
			'enseignant.signalement.resumeAide' => 'يمكن للأكاديمية مشاركته مع الأسرة.',
			'enseignant.signalement.notice' => 'لا تُرسل التفاصيل الداخلية تلقائيًا إلى الأسرة.',
			'enseignant.signalement.choisirCategorie' => 'اختر فئة للمتابعة.',
			'enseignant.signalement.detailsRequis' => 'في «أخرى»، قل في كلمات قليلة بماذا يتعلق الأمر.',
			'enseignant.signalement.envoyer' => 'إرسال الإشارة',
			'enseignant.signalement.demoSucces' => 'عرض تجريبي: هذه الإشارة جاهزة، لكن لم يُرسل شيء.',
			'enseignant.signalement.demoSuccesDetail' => 'في التطبيق الموصول، ستُرسل إلى فريق الأكاديمية.',
			'enseignant.signalement.fermer' => 'إغلاق',
			'enseignant.demo.titre' => 'عرض تجريبي للمعلم',
			'enseignant.demo.mention' => 'بيانات وهمية، لا إرسال.',
			'enseignant.demo.intro' => 'اختر شاشة من شاشات السيد إبراهيم.',
			'enseignant.demo.ecrans' => 'الشاشات',
			'enseignant.demo.etats' => 'الحالات',
			'enseignant.demo.etatNominal' => 'يوم عادي',
			'enseignant.demo.etatVide' => 'لا حصة',
			'enseignant.demo.etatHorsLigne' => 'غير متصل',
			'enseignant.bienvenue.titre' => 'الخطوات الأولى',
			'enseignant.bienvenue.salutation' => ({required Object prenom}) => 'مرحبًا، ⁨${prenom}⁩.',
			'enseignant.bienvenue.salutationSansNom' => 'مرحبًا.',
			'enseignant.bienvenue.dossierValide' => 'تم اعتماد ملفك.',
			'enseignant.bienvenue.sousTitre' => 'جهّز مساحتك قبل فصلك الأول.',
			'enseignant.bienvenue.aCompleter' => 'للإكمال',
			'enseignant.bienvenue.compteur' => ({required Object fait, required Object total}) => '⁨${fait}⁩ من ⁨${total}⁩',
			'enseignant.bienvenue.prerequisPhoto' => 'إضافة صورتي المهنية',
			'enseignant.bienvenue.prerequisLangues' => 'التحقق من لغات تدريسي',
			'enseignant.bienvenue.prerequisFuseau' => 'التحقق من منطقتي الزمنية',
			'enseignant.bienvenue.ctaPhoto' => 'إضافة صورتي',
			'enseignant.bienvenue.ctaInformations' => 'التحقق من معلوماتي',
			'enseignant.bienvenue.ctaJournee' => 'عرض يومي',
			'enseignant.bienvenue.rappels' => 'أمران لا ينبغي اكتشافهما في منتصف الطريق',
			'enseignant.bienvenue.declarer' => 'التصريح بأوقات توفري',
			'enseignant.bienvenue.versJournee' => 'الذهاب إلى يومي',
			'enseignant.bienvenue.horsLigne' => 'دون شبكة، لا يمكن حفظ مواعيدك.',
			'enseignant.bienvenue.dossierIncomplet' => 'لم يُعتمد ملفك بعد.',
			'enseignant.bienvenue.dossierIncompletDetail' => 'بوابة الانتظار تخبرك بما بقي عليك تقديمه.',
			'enseignant.bienvenue.versAttente' => 'عرض ملفي',
			'enseignant.bienvenue.erreur' => 'تعذّرت قراءة ملفك الشخصي. أعد المحاولة بعد لحظة.',
			'enseignant.photo.titre' => 'الصورة المهنية',
			'enseignant.photo.aide' => 'صورتك إلزامية: الأسر لا تأتمن أطفالها لشخص مجهول على الإنترنت. تراها أسر طلابك.',
			'enseignant.photo.obligatoireLecteur' => 'الصورة إلزامية',
			'enseignant.photo.voile' => 'إن كنتِ ترتدين النقاب، يمكن أن تظهركِ صورة الملف منتقبة.',
			'enseignant.photo.notice' => 'لا تستخدم بطاقة هويتك.',
			'enseignant.photo.choisir' => 'اختيار صورة',
			'enseignant.photo.utiliser' => 'استخدام هذه الصورة',
			'enseignant.photo.remplacer' => 'استبدال الصورة',
			'enseignant.photo.autre' => 'اختيار صورة أخرى',
			'enseignant.photo.changer' => 'تغيير الصورة',
			'enseignant.photo.alternatif' => 'صورتك العامة',
			'enseignant.photo.succes' => 'حُفظت الصورة.',
			'enseignant.photo.echec' => 'تعذّر إرسال الصورة. لم يتغير شيء في الملف.',
			'enseignant.photo.selectionEchec' => 'تعذّر فتح الصورة. تحقّق من إذن الوصول إلى صور الجهاز، ثم أعد المحاولة.',
			'enseignant.photo.horsLigne' => 'أنت غير متصل. يمكن إرسال الصورة عند عودة الاتصال.',
			'enseignant.salle.reference' => ({required Object page, required Object total, required Object reference}) => 'المعروض: الصفحة ⁨${page}⁩ من ⁨${total}⁩ · ⁨${reference}⁩',
			'enseignant.salle.rien' => 'لا شيء معروض',
			'enseignant.salle.rienInvitation' => 'افتح القرآن لتعرض صفحة على فصلك.',
			'enseignant.salle.attenteSalle' => 'لست في القاعة بعد',
			'enseignant.salle.attenteSalleDetail' => 'تُفتح أوامر العرض بمجرد اتصال الدرس.',
			'enseignant.salle.lienFaibleDetail' => 'قد يصل تقليب الصفحة متأخرًا إلى فصلك',
			'enseignant.salle.presentationConservee' => 'الصفحة المعروضة محفوظة، وستُرسل عند عودة الاتصال',
			'enseignant.salle.presentationSuspendue' => 'العرض موقوف',
			'enseignant.salle.precedente' => 'عرض الصفحة السابقة',
			'enseignant.salle.suivante' => 'عرض الصفحة التالية',
			'enseignant.salle.bibliotheque' => 'اختيار سورة',
			'enseignant.salle.presenterSourate' => ({required Object sourate}) => 'عرض بداية ⁨${sourate}⁩',
			'enseignant.salle.sourateDetail' => ({required Object numero, required Object versets}) => 'السورة ⁨${numero}⁩ · عدد آياتها ⁨${versets}⁩',
			'enseignant.salle.souratesIndisponibles' => 'تعذّرت قراءة قائمة السور',
			'enseignant.salle.souratesIndisponiblesDetail' => 'لم يتغير ما يراه فصلك. أعد المحاولة.',
			'enseignant.salle.pageIndisponible' => 'تعذّرت قراءة هذه الصفحة',
			'enseignant.salle.pageIndisponibleDetail' => 'لم يصل النص إلى هنا. ما زال فصلك يرى الصفحة المعروضة.',
			'enseignant.salle.corpusAbsent' => 'نص القرآن غير مثبَّت',
			'enseignant.salle.corpusAbsentDetail' => 'لا شيء للعرض.',
			'enseignant.salle.echecPresentation' => 'تعذّر تحديد موضع هذه الآية في المصحف. لم يُرسل شيء إلى فصلك.',
			'enseignant.salle.sansDroitPresentation' => 'دخولك إلى هذه الحصة لا يسمح بعرض محتوى.',
			'enseignant.cahier.titre' => 'دفتر المتابعة',
			'enseignant.cahier.obligatoire' => 'إلزامي',
			'enseignant.cahier.sousTitre' => 'إلزامي بعد كل حصة',
			'enseignant.cahier.description' => 'دوّن أين وصل كل طالب (السورة، الآية، القاعدة التي عُمل عليها). إن استخلفك معلم آخر، يستأنف تمامًا من حيث توقفت الحصة.',
			'enseignant.cahier.duree' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة من الدرس',
			'enseignant.cahier.dureeEtInterruption' => ({required Object minutes, required Object interruption}) => '⁨${minutes}⁩ دقيقة من الدرس، منها ⁨${interruption}⁩ دقيقة انقطاع',
			'enseignant.cahier.unEleve' => 'طالب واحد',
			'enseignant.cahier.eleves' => ({required Object nombre}) => '⁨${nombre}⁩ طلاب',
			'enseignant.cahier.toutEstNominal' => 'جرى كل شيء كما هو متوقع.',
			'enseignant.cahier.toutEstNominalDetail' => 'أكّد، ويستمر يومك.',
			'enseignant.cahier.exceptions' => 'للنظر',
			'enseignant.cahier.uneException' => 'طالب واحد يحتاج إلى نظرة.',
			'enseignant.cahier.plusieursExceptions' => ({required Object nombre}) => '⁨${nombre}⁩ طلاب يحتاجون إلى نظرة.',
			'enseignant.cahier.nominaux' => 'لا شيء يُذكر',
			'enseignant.cahier.curriculumFige' => 'المستوى والمنهج من الأكاديمية: لا يُعدَّلان من دفتر المتابعة.',
			'enseignant.cahier.valider' => 'تأكيد دفتر المتابعة',
			'enseignant.cahier.validerTout' => 'كل شيء مطابق، تأكيد',
			'enseignant.cahier.validerSansConstat' => 'الإيداع دون المعاينة',
			'enseignant.cahier.retourJournee' => 'العودة إلى يومي',
			'enseignant.cahier.vide' => 'تعذّر استنتاج المعاينة',
			'enseignant.cahier.videDetail' => 'لم يُسجَّل حضور ولا حدث لهذه الحصة. يمكنك مع ذلك إيداع دفتر المتابعة.',
			'enseignant.cahier.erreur' => 'تعذّرت قراءة المعاينة.',
			'enseignant.cahier.erreurDetail' => 'أعد المحاولة، أو أودع دفتر المتابعة دون المعاينة.',
			'enseignant.cahier.echecEnvoi' => 'لم يُؤكَّد الإرسال. تحقّق قبل إعادة المحاولة.',
			'enseignant.cahier.dejaDepose' => 'دفتر متابعة هذه الحصة مودَع بالفعل.',
			'enseignant.cahier.dejaDeposeDetail' => 'يُودَع دفتر المتابعة مرة واحدة، ولا يُحذف من هنا.',
			'enseignant.cahier.depose' => 'حُفظ دفتر المتابعة',
			'enseignant.cahier.deposeDetail' => 'استلمته الأكاديمية.',
			'enseignant.cahier.enFileTitre' => 'بانتظار الإرسال',
			'enseignant.cahier.enFile' => 'سيُرسل دفتر المتابعة عند عودة الاتصال.',
			'enseignant.cahier.enFileDetail' => 'سيُرسل دفتر المتابعة عند عودة الاتصال.',
			'enseignant.cahier.enFileDetailHorsLigne' => 'دون شبكة، يبقى دفتر المتابعة على هذا الجهاز ويُرسل بمجرد عودة الشبكة. يمكنك الانتقال إلى درسك التالي.',
			'enseignant.cahier.ajusterPour' => ({required Object eleve}) => 'تعديل · ⁨${eleve}⁩',
			'enseignant.cahier.ajusterValider' => 'حفظ لهذا الطالب',
			'enseignant.cahier.exceptionConsignee' => 'استثناء مُبلَغ عنه',
			'enseignant.cahier.pointPhonetique' => 'ملاحظة في النطق',
			'enseignant.cahier.pointPhonetiqueDetail' => 'زوج من الحروف، لا تقييم. اتركه فارغًا إن لم يكن هناك ما يُقال.',
			'enseignant.cahier.pointPhonetiqueNote' => 'دُوِّنت ملاحظة النطق',
			'enseignant.cahier.objectif' => ({required Object eleve}) => 'هدف ⁨${eleve}⁩',
			'enseignant.cahier.objectifDetail' => ({required Object eleve}) => 'ما يجب أن يبلغه ⁨${eleve}⁩، في إطار منهج الأكاديمية.',
			'enseignant.cahier.travailMaison' => ({required Object eleve}) => 'واجب ⁨${eleve}⁩',
			'enseignant.cahier.travailMaisonDetail' => 'عدّل الاقتراح، أو اتركه كما هو.',
			'enseignant.cahier.travailMaisonSaisi' => 'دوّنت هذا الواجب بالفعل. عدّله أو اتركه كما هو.',
			'enseignant.cahier.suite' => ({required Object eleve}) => 'الخطوة التالية لـ⁨${eleve}⁩',
			'enseignant.cahier.suiteContinuer' => 'المتابعة',
			'enseignant.cahier.suiteRenforcer' => 'التثبيت',
			'enseignant.cahier.suspendreNouveau' => 'إيقاف الجديد',
			'enseignant.cahier.devoirPrecedent' => ({required Object devoir}) => 'الواجب السابق: ⁨${devoir}⁩',
			'enseignant.cahier.devoirPlage' => ({required Object sourate, required Object debut, required Object fin}) => 'مراجعة سورة ⁨${sourate}⁩، الآيات ⁨${debut}⁩ إلى ⁨${fin}⁩.',
			'enseignant.cahier.suspendreNouveauDetail' => 'تستمر المراجعة، ولا يُضاف شيء جديد لهذا الطالب.',
			'enseignant.cahier.position' => ({required Object sourate, required Object verset}) => 'القراءة: سورة ⁨${sourate}⁩، الآية ⁨${verset}⁩',
			'enseignant.cahier.makhrajSinSad' => 'السين / الصاد (س / ص)',
			'enseignant.cahier.makhrajTaTah' => 'التاء / الطاء (ت / ط)',
			'enseignant.cahier.makhrajDhalZay' => 'الذال / الزاي (ذ / ز)',
			'enseignant.cahier.makhrajHaHah' => 'الهاء / الحاء (ه / ح)',
			'enseignant.cahier.exceptionTitre' => 'الإبلاغ عن استثناء',
			'enseignant.cahier.exceptionCorriger' => 'تصحيح الحضور',
			'enseignant.cahier.exceptionExcuser' => 'تبرير الغياب',
			'enseignant.cahier.exceptionConfirmation' => 'تأكيد الاستثناء',
			'enseignant.cahier.exceptionMotif' => 'السبب',
			'enseignant.cahier.exceptionMotifRequis' => 'السبب إلزامي.',
			'enseignant.cahier.exceptionEnCours' => 'جارٍ الحفظ…',
			'enseignant.cahier.exceptionSucces' => 'دُوِّن الاستثناء. سيُرسل مع دفتر المتابعة.',
			'enseignant.cahier.exceptionErreur' => 'تعذّر تدوين الاستثناء.',
			'enseignant.cahier.exceptionHorsLigne' => 'دون شبكة، لا يمكن تأكيد استثناء. أما دفتر المتابعة فيُرسل على كل حال.',
			'enseignant.cahier.aValider' => 'للتأكيد',
			'enseignant.cahier.statutPresents' => ({required Object nombre}) => 'الحاضرون ⁨${nombre}⁩',
			'enseignant.cahier.statutAbsents' => ({required Object nombre}) => 'الغائبون ⁨${nombre}⁩',
			'enseignant.cahier.statutEnRetard' => ({required Object nombre}) => 'المتأخرون ⁨${nombre}⁩',
			'enseignant.cahier.performance' => 'الأداء',
			'enseignant.cahier.faiblesses' => 'نقاط الضعف',
			'enseignant.cahier.niveauARevoir' => 'للمراجعة',
			'enseignant.cahier.niveauEnProgres' => 'في تقدم',
			'enseignant.cahier.niveauAcquis' => 'مكتسَب',
			'enseignant.cahier.niveauMaitrise' => 'متقَن',
			'enseignant.cahier.faiblesseMakharij' => 'المخارج',
			'enseignant.cahier.faiblesseMadd' => 'المد',
			'enseignant.cahier.faiblesseGhunna' => 'الغنة',
			'enseignant.cahier.faiblesseWaqf' => 'الوقف',
			'enseignant.cahier.faiblesseFluidite' => 'الطلاقة',
			'enseignant.cahier.faiblesseMemorisation' => 'الحفظ',
			'enseignant.cahier.niveauARevoirDetail' => 'يُعاد المقطع في الحصة القادمة.',
			'enseignant.cahier.niveauEnProgresDetail' => 'الطالب يتقدم، وبقيت بعض الأخطاء.',
			'enseignant.cahier.niveauAcquisDetail' => 'المقطع محفوظ، بأخطاء قليلة.',
			'enseignant.cahier.niveauMaitriseDetail' => 'المقطع محفوظ دون خطأ، ويمكن للطالب أن يتقدم.',
			'enseignant.cahier.faiblesseMakharijDetail' => 'نطق الحروف.',
			'enseignant.cahier.faiblesseMaddDetail' => 'المدود.',
			'enseignant.cahier.faiblesseGhunnaDetail' => 'الصوت الأنفي.',
			'enseignant.cahier.faiblesseWaqfDetail' => 'مواضع الوقف.',
			'enseignant.cahier.faiblesseFluiditeDetail' => 'القراءة دون تردد.',
			'enseignant.cahier.faiblesseMemorisationDetail' => 'التلاوة من الحفظ.',
			'enseignant.cahier.reprise' => 'أين توقف الفصل',
			'enseignant.cahier.repriseDetail' => 'هذا موضع الاستئناف للمعلم البديل.',
			'enseignant.cahier.repriseProposee' => ({required Object sourate, required Object verset}) => 'سورة ⁨${sourate}⁩، الآية ⁨${verset}⁩',
			'enseignant.cahier.repriseRequise' => 'حدّد أين توقف الفصل: سيستأنف البديل من هنا.',
			'enseignant.cahier.integrite' => 'ما تكتبه هنا أمانة. قد لا يتحقق منه الناس، لكن الله يرى كل شيء.',
			'enseignant.cahier.corriger' => 'تصحيح دفتر المتابعة',
			'enseignant.cahier.corrigeLe' => ({required Object date}) => 'صُحِّح في ⁨${date}⁩',
			'enseignant.profil.titre' => 'الملف الشخصي',
			'enseignant.profil.compteValide' => 'حساب معلم موثَّق',
			'enseignant.profil.intro' => 'ما تعرفه الأكاديمية عنك، وما يمكنك تغييره فيه.',
			'enseignant.profil.identite' => 'الهوية المهنية',
			'enseignant.profil.pays' => 'البلد',
			'enseignant.profil.langues' => 'اللغات',
			'enseignant.profil.fuseau' => 'المنطقة الزمنية لدروسي',
			'enseignant.profil.fuseauDetail' => 'هي التي تحدد توقيت مواعيدك، لا توقيت هذا الجهاز.',
			'enseignant.profil.plafond' => 'الحد الأسبوعي',
			'enseignant.profil.plafondValeur' => ({required Object nombre}) => '⁨${nombre}⁩ ساعة في الأسبوع',
			'enseignant.profil.plafondDetail' => 'تحدده الأكاديمية.',
			'enseignant.profil.nonRenseigne' => 'غير محدد',
			'enseignant.profil.statutSection' => 'حالة الحساب',
			'enseignant.profil.statutValideDetail' => 'يمكنك التدريس والتصريح بساعاتك.',
			'enseignant.profil.statutEnAttente' => 'الملف قيد التحقق',
			'enseignant.profil.statutEnAttenteDetail' => 'تتحقق الأكاديمية من وثائقك. لا شيء آخر عليك فعله.',
			'enseignant.profil.statutProvisoire' => 'دخول مؤقت',
			'enseignant.profil.statutProvisoireDetail' => 'أنت تدرّس بالفعل. يبقى ملفك للإكمال، دون انقطاع تلقائي.',
			'enseignant.profil.statutSuspendu' => 'الحساب موقوف',
			'enseignant.profil.statutSuspenduDetail' => 'يمكنك التواصل مع الأكاديمية لمعرفة الخطوات المطلوبة.',
			'enseignant.profil.statutInconnu' => 'الحالة غير متاحة',
			'enseignant.profil.statutInconnuDetail' => 'تعذّرت قراءة حالتك.',
			'enseignant.profil.statutDivergent' => 'تغيّرت هذه الحالة للتو. أعد فتح التطبيق ليتبعها دخولك.',
			'enseignant.profil.verification' => 'التحقق من الملف',
			'enseignant.profil.verificationEnAttente' => 'قيد الانتظار',
			'enseignant.profil.verificationValidee' => 'معتمَد',
			'enseignant.profil.verificationRefusee' => 'يحتاج إلى مراجعة',
			'enseignant.profil.contratSection' => 'العقد والإقرارات',
			'enseignant.profil.contratEnseignant' => 'عقد المعلم',
			'enseignant.profil.contratConditions' => 'شروط الاستخدام',
			'enseignant.profil.contratAccuse' => 'التسجيل الصوتي وزيارة المراقبة',
			'enseignant.profil.contratDetail' => ({required Object version, required Object date}) => 'الإصدار ⁨${version}⁩، مقبول في ⁨${date}⁩',
			'enseignant.profil.contratAucun' => 'لا عقد مسجَّل',
			'enseignant.profil.contratAucunDetail' => 'لم يمر ملفك بالتوقيع بعد.',
			'enseignant.profil.contratErreur' => 'تعذّرت قراءة عقودك.',
			'enseignant.profil.contratLectureSeule' => 'هذه الوثائق للقراءة فقط.',
			'enseignant.profil.personnel' => 'إعداداتي',
			'enseignant.profil.deconnexionQuestion' => 'تسجيل الخروج من هذا الجهاز؟',
			'enseignant.profil.deconnexionConfirmer' => 'تسجيل خروجي الآن',
			'enseignant.profil.deconnexionConsequence' => 'يبقى يومك ومواعيدك ودفاترك محفوظة. ستحتاج إلى رابط دخول جديد للعودة.',
			'enseignant.profil.erreur' => 'تعذّرت قراءة ملفك الشخصي. أعد المحاولة بعد لحظة.',
			'enseignant.profil.vide' => 'لا ملف معلم',
			'enseignant.profil.videDetail' => 'ليس لهذا الحساب ملف معلم. الأكاديمية وحدها يمكنها إنشاؤه.',
			'enseignant.profil.horsLigne' => 'لا شبكة: لا يمكن تعديل شيء هنا الآن.',
			'enseignant.profil.modifierPays' => 'تعديل البلد',
			'enseignant.profil.modifierLangues' => 'تعديل اللغات',
			'enseignant.profil.languesIndice' => 'افصل بين اللغات بفاصلة',
			'enseignant.profil.enregistrer' => 'حفظ',
			'enseignant.profil.enregistre' => 'حُفظ التعديل',
			'enseignant.profil.editionErreur' => 'لم يتم التعديل. أعد المحاولة بعد لحظة.',
			'enseignant.creneaux.heureLibelle' => ({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩',
			'enseignant.creneaux.aucuneHeure' => 'لم تقترح أي ساعة. دون موعد، لا يمكن أن يُقترح عليك أي فصل.',
			'enseignant.creneaux.heureEnregistree' => ({required Object heure}) => 'حُفظت ⁨${heure}⁩',
			'enseignant.creneaux.heureRetiree' => ({required Object heure}) => 'أُزيلت ⁨${heure}⁩',
			'enseignant.creneaux.retraitEngage' => ({required Object heure}) => 'أُزيلت ⁨${heure}⁩. الحصة المسندة في هذه الساعة مستمرة: اطلب إعادة إسناد لإيقافها.',
			'enseignant.creneaux.grilleErreur' => 'تعذّرت قراءة ساعاتك',
			'enseignant.creneaux.grilleErreurDetail' => 'الساعات التي حددتها لم تضِع.',
			'enseignant.creneaux.horsLigneGrille' => 'دون شبكة، تبقى ساعاتك قابلة للعرض لكن لا يمكن تعديلها.',
			'enseignant.creneaux.heureEngagee' => ({required Object heures}) => 'لديك فصل بالفعل في ⁨${heures}⁩. إزالة هذه الساعة لا تنهي الحصة: يلزم إعادة إسناد.',
			'enseignant.creneaux.heuresEngagees' => ({required Object heures}) => 'لديك فصل بالفعل في ⁨${heures}⁩. إزالة هذه الساعات لا تنهي الحصص: يلزم إعادة إسناد.',
			'enseignant.creneaux.feedErreur' => 'تعذّرت قراءة الأسر المنتظرة',
			'enseignant.creneaux.feedErreurDetail' => 'لم يضِع شيء: لم يُؤخذ أحد، وساعاتك باقية.',
			'enseignant.creneaux.horsLignePrise' => 'دون شبكة، لا يمكنك قبول طالب. تبقى الطلبات أدناه قابلة للعرض.',
			'enseignant.creneaux.horsLigneDemande' => 'دون شبكة، لن يُرسل هذا الطلب. أعد المحاولة عند عودة الاتصال.',
			'enseignant.creneaux.refusDejaPris' => 'قبِل معلم آخر هذا الطالب للتو. القائمة أدناه محدَّثة.',
			_ => null,
		} ?? switch (path) {
			'enseignant.creneaux.refusDejaSuivi' => 'لهذا الطالب معلم بالفعل. القائمة أدناه محدَّثة.',
			'enseignant.creneaux.refusCreneauRetire' => 'لم تعد هذه الأسرة تقترح هذا الموعد. القائمة أدناه محدَّثة.',
			'enseignant.creneaux.refusHorsMesHeures' => 'لم يعد هذا الموعد ضمن ساعاتك. أعد إضافته في «ساعاتي» لتتمكن من قبوله.',
			'enseignant.creneaux.refusPlafond' => 'بلغت الحد الأقصى لطلابك. اطلب زيادة لتتابع طالبًا آخر.',
			'enseignant.creneaux.mesDisponibilites' => 'أوقات توفري',
			'enseignant.creneaux.ajouterCreneau' => 'إضافة موعد',
			'enseignant.creneaux.heure' => ({required Object heure}) => 'الساعة ⁨${heure}⁩',
			'enseignant.creneaux.classesDisponibles' => 'الفصول المتاحة',
			'enseignant.creneaux.etatDisponible' => 'متاح',
			'enseignant.creneaux.etatEnAttente' => 'بانتظار الاعتماد',
			'enseignant.creneaux.etatLimite' => 'بلغت الحد الأقصى للعبء',
			'enseignant.creneaux.limiteDetail' => 'عبؤك الحالي لا يسمح بحجز فصل إضافي.',
			'enseignant.creneaux.aucuneClasse' => 'لا فصل متوافق الآن',
			'enseignant.creneaux.aucuneClasseDetail' => 'عدّل أوقات توفرك إن تغيّر جدولك.',
			'enseignant.creneaux.reserver' => 'حجز هذا الفصل',
			'enseignant.creneaux.demandeTransmise' => 'أُرسل طلبك.',
			'enseignant.creneaux.demandeTransmiseDetail' => 'سيظهر في فصولك بعد التأكيد.',
			'enseignant.creneaux.confirmerTitre' => 'تأكيد هذا الفصل؟',
			'enseignant.creneaux.confirmer' => 'تأكيد هذا الفصل',
			'enseignant.creneaux.revenir' => 'رجوع',
			'enseignant.creneaux.cleNiveau' => 'المستوى',
			'enseignant.creneaux.cleLangue' => 'اللغة',
			'enseignant.creneaux.cleRecurrence' => 'التكرار',
			'enseignant.creneaux.cleFuseau' => 'المنطقة الزمنية المرجعية',
			'enseignant.creneaux.cleHeureLocale' => 'التوقيت المحلي',
			'enseignant.creneaux.cleDuree' => 'المدة',
			'enseignant.creneaux.duree' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة',
			'enseignant.revue.titre' => 'مراجعة الفصل',
			'enseignant.revue.titreClasse' => ({required Object classe}) => 'مراجعة الفصل ⁨${classe}⁩',
			'enseignant.revue.aucuneAnomalie' => 'لا شيء يتطلب انتباهك.',
			'enseignant.revue.erreur' => 'تعذّرت قراءة المراجعة.',
			'enseignant.revue.erreurDetail' => 'ربما ليس هذا الفصل فصلك، أو فشلت القراءة.',
			'enseignant.revue.pasDeDecision' => 'أنت تُبلغ، والأكاديمية تقرر: النقل وإعادة التوجيه لا يُقرَّران من هنا.',
			'enseignant.revue.typeGate' => 'مرحلة قادمة',
			'enseignant.revue.typeCorridor' => 'طالب خارج المسار المتوقع',
			'enseignant.revue.typeTransfert' => 'اقتراح نقل',
			'enseignant.revue.typeReorientation' => 'اقتراح إعادة توجيه',
			'compte.themeContexte' => 'اختر مظهر التطبيق. يتم التغيير فورًا ويبقى على هذا الجهاز، ويمكنك تعديله في أي وقت.',
			'compte.themeSysteme' => 'النظام',
			'compte.themeSystemeDetail' => 'يتبع إعداد جهازك',
			'compte.themeClair' => 'فاتح',
			'compte.themeClairDetail' => 'خلفية فاتحة مهما كان إعداد جهازك',
			'compte.themeSombre' => 'داكن',
			'compte.themeSombreDetail' => 'خلفية داكنة مهما كان إعداد جهازك',
			'compte.titre' => 'حسابي',
			'compte.intro' => 'معلوماتك وتفضيلاتك وصلاحياتك، في مكان واحد.',
			'compte.informations' => 'المعلومات',
			'compte.profil' => 'الملف الشخصي',
			'compte.profilDetail' => 'عرض معلوماتك وإدارتها',
			'compte.reglages' => 'الإعدادات',
			'compte.reglagesDetail' => 'المظهر والإشعارات وإمكانية الوصول',
			'compte.profils' => 'إدارة أسرتي',
			'compte.profilsDetail' => 'إدارة ملفات أطفالك',
			'compte.appareils' => 'الأسرة',
			'compte.appareilsDetail' => 'الأجهزة والملفات المرتبطة بأسرتك',
			'compte.confidentialite' => 'الخصوصية',
			'compte.confidentialiteDetail' => 'قريبًا',
			'compte.espaces' => 'المساحات',
			'compte.espacesDetail' => 'المساحات التي يتيحها حسابك',
			'compte.espacesMissionEnCours' => 'للعودة إلى مساحتك الرئيسية، غادر أولًا الزيارة الجارية.',
			'compte.habilitation' => 'مخوَّل',
			'compte.deconnexion' => 'تسجيل الخروج',
			'compte.deconnexionDetail' => 'إنهاء الجلسة على هذا الجهاز',
			'compte.identifiant' => 'المعرّف',
			'compte.nonDisponible' => 'غير متاح',
			'compte.contact' => 'التواصل',
			'compte.contactDetail' => 'تديره الأكاديمية',
			'compte.langue' => 'اللغة',
			'compte.francais' => 'الفرنسية',
			'compte.fuseau' => 'المنطقة الزمنية',
			'compte.academie' => 'الأكاديمية',
			'compte.securite' => 'الأمان',
			'compte.statut' => 'الحالة',
			'compte.reglagesTitre' => 'الإعدادات',
			'compte.reglagesIntro' => 'تبقى هذه التفضيلات على هذا الجهاز وتُطبَّق فورًا.',
			'compte.apparence' => 'المظهر',
			'compte.accessibilite' => 'إمكانية الوصول',
			'compte.animations' => 'تقليل الحركة',
			'compte.animationsDetail' => 'يحدّ من الحركة على الشاشة',
			'compte.effets' => 'تقليل المؤثرات',
			'compte.effetsDetail' => 'يحدّ من الشفافية والظلال',
			'compte.lisibiliteDetail' => 'حجم النص يتبع إعداد جهازك.',
			'compte.langueRegion' => 'اللغة والمنطقة',
			'compte.francaisDetail' => 'لغة الواجهة',
			'compte.actif' => 'مفعَّل',
			'compte.arabe' => 'العربية',
			'compte.arabeDetail' => 'قريبًا',
			'compte.fuseauDetail' => 'يُكتشف تلقائيًا',
			'compte.notifications' => 'الإشعارات',
			'compte.notificationsCours' => 'الدروس',
			'compte.notificationsCoursDetail' => 'تذكيرات قبل دروسك',
			'compte.notificationsFoyer' => 'الأسرة',
			'compte.notificationsFoyerDetail' => 'نشاط ملفات أسرتك',
			'compte.notificationsEtat' => 'تعتمد الإشعارات أيضًا على إعدادات جهازك ومتصفحك.',
			'compte.coursDonnees' => 'الدروس والبيانات',
			'compte.economieDonnees' => 'توفير البيانات',
			'compte.economieDonneesDetail' => 'يخفّض جودة الفيديو على شبكة الجوال',
			'compte.lectureGrande' => 'القراءة بنص كبير',
			'compte.lectureGrandeDetail' => 'يعرض القرآن بحجم أكبر افتراضيًا',
			'compte.profilsTitre' => 'ملفات الأسرة',
			'compte.profilsIntro' => 'الأطفال المرتبطون بأسرتك.',
			'compte.erreurProfils' => 'تعذّرت قراءة الملفات.',
			'compte.reessayer' => 'إعادة المحاولة',
			'compte.aucunProfil' => 'لا ملفات حتى الآن',
			'compte.aucunProfilDetail' => 'أضف طفلًا للبدء',
			'compte.ajouterEnfant' => 'إضافة طفل',
			'compte.ouvrirProfil' => 'فتح الملف',
			'compte.modeEnfant' => 'وضع إمكانية الوصول',
			'compte.modeStandard' => 'الوضع العادي',
			'compte.cameraLabel' => 'الكاميرا',
			'compte.cameraAutorisee' => 'مسموح بها',
			'compte.cameraInterdite' => 'ممنوعة',
			'compte.accesSansFin' => 'وصول دون تاريخ انتهاء',
			'compte.accesJusqua' => ({required Object date}) => 'وصول حتى ⁨${date}⁩',
			'compte.statutActif' => 'مفعَّل',
			'compte.statutProvisoire' => 'مفعَّل مؤقتًا',
			'compte.profilEnfant' => ({required Object prenom}) => 'ملف ⁨${prenom}⁩',
			'compte.identifiantEnfant' => ({required Object identifiant}) => 'المعرّف: ⁨${identifiant}⁩',
			'compte.roles.admin' => 'مدير',
			'compte.roles.accountant' => 'محاسب',
			'compte.roles.controller' => 'مراقب',
			'compte.roles.teacher' => 'معلم',
			'compte.roles.guardian' => 'وليّ أمر',
			'compte.roles.student' => 'طالب',
			'compte.roleDetail.admin' => 'يدير ملفات الأكاديمية والإسناد والسجل',
			'compte.roleDetail.accountant' => 'يدير المدفوعات والفواتير',
			'compte.roleDetail.controller' => 'يتابع الحصص من أجل الجودة التعليمية',
			'compte.roleDetail.teacher' => 'يقدّم الدروس ويتابع مواعيده',
			'compte.roleDetail.guardian' => 'يتابع الأسرة وأطفالها',
			'compte.roleDetail.student' => 'يتابع دروسه وقراءته للقرآن',
			'compte.tuteur.preferences' => 'التفضيلات',
			'compte.tuteur.dateLongue' => ({required Object jour, required Object mois, required Object annee}) => '⁨${jour}⁩ ⁨${mois}⁩ ⁨${annee}⁩',
			'compte.tuteur.identite.statutValide' => 'الحساب معتمَد',
			'compte.tuteur.identite.statutProvisoire' => 'الملف للإكمال',
			'compte.tuteur.identite.nomInconnu' => 'صاحب الحساب',
			'compte.tuteur.identite.courrielAbsent' => 'عنوان الدخول غير متوفر',
			'compte.tuteur.identite.connexionLien' => 'الدخول برابط يصل بالبريد الإلكتروني',
			'compte.tuteur.identite.connexionGoogle' => 'الدخول بحساب Google',
			'compte.tuteur.identite.connexionInconnue' => 'طريقة الدخول غير محددة',
			'compte.tuteur.acces.titre' => 'الوصول والمدفوعات',
			'compte.tuteur.acces.resume' => 'حالة كل ملف طالب وموعد انتهائه',
			'compte.tuteur.acces.pastilleActif' => 'الوصول ساري',
			'compte.tuteur.acces.pastilleExpire' => 'انتهى الوصول',
			'compte.tuteur.acces.ligne' => 'وصول ملفات الطلاب',
			'compte.tuteur.acces.paiements' => 'المدفوعات والإيصالات',
			'compte.tuteur.securite.titre' => 'الدخول والأمان',
			'compte.tuteur.securite.methode' => 'طريقة الدخول',
			'compte.tuteur.securite.methodeLien' => 'رابط بالبريد الإلكتروني',
			'compte.tuteur.securite.methodeGoogle' => 'Google',
			'compte.tuteur.informations.titre' => 'المعلومات الشخصية',
			'compte.tuteur.informations.resume' => 'الاسم وعنوان الدخول واللغة والمنطقة الزمنية',
			'compte.tuteur.informations.langueFuseau' => ({required Object ville}) => 'العربية · ⁨${ville}⁩',
			'compte.tuteur.informations.consulter' => 'عرض معلوماتي',
			'compte.tuteur.foyer.titre' => 'أسرتي',
			'compte.tuteur.foyer.aucun' => 'لا ملف طالب حتى الآن',
			'compte.tuteur.foyer.un' => 'ملف طالب واحد',
			'compte.tuteur.foyer.plusieurs' => ({required Object nombre}) => '⁨${nombre}⁩ ملفات طلاب',
			'compte.tuteur.foyer.legende' => 'ملفات الطلاب وأجهزة الأسرة',
			'compte.tuteur.foyer.creerMonProfil' => 'إنشاء ملفي كطالب',
			'compte.tuteur.aide.titre' => 'المساعدة والدعم',
			'compte.tuteur.aide.ligne' => 'المساعدة والتواصل',
			'compte.tuteur.aide.legal' => 'المعلومات القانونية',
			'compte.tuteur.deconnexion.question' => 'تسجيل الخروج من Rewayah؟',
			'compte.tuteur.deconnexion.consequence' => 'ستحتاج إلى تسجيل الدخول من جديد للعودة إلى هذا الجهاز. تبقى أجهزتك الأخرى متصلة.',
			'compte.tuteur.deconnexion.confirmer' => 'تسجيل خروجي',
			'compte.tuteur.deconnexion.echec' => 'لم يكتمل تسجيل الخروج. تحقّق من اتصالك، ثم أعد المحاولة.',
			'compte.tuteur.pageInformations.titre' => 'المعلومات الشخصية',
			'compte.tuteur.pageInformations.prenom' => 'الاسم',
			'compte.tuteur.pageInformations.nom' => 'اللقب',
			'compte.tuteur.pageInformations.courriel' => 'عنوان الدخول',
			'compte.tuteur.pageInformations.langue' => 'لغة الواجهة',
			'compte.tuteur.pageInformations.fuseau' => 'المنطقة الزمنية للحصص',
			'compte.tuteur.pageInformations.fuseauIndisponible' => 'غير متاح الآن',
			'compte.tuteur.pageInformations.note' => 'تحتفظ الأكاديمية بهذه المعلومات. لا تُعدَّل من التطبيق بعد.',
			'compte.tuteur.pageSecurite.titre' => 'الدخول والأمان',
			'compte.tuteur.pageSecurite.sousTitre' => 'كيف تدخل إلى حسابك.',
			'compte.tuteur.pageSecurite.methode' => 'طريقة الدخول',
			'compte.tuteur.pageSecurite.adresse' => 'عنوان الدخول',
			'compte.tuteur.pageSecurite.appareils' => 'الأجهزة المتصلة بحسابك لا تُعرض في التطبيق بعد.',
			'compte.tuteur.pageSecurite.deconnexion' => 'لإغلاق جلسة هذا الجهاز، استخدم «تسجيل الخروج» أسفل «حسابي».',
			'compte.tuteur.pageAcces.titre' => 'وصول ملفات الطلاب',
			'compte.tuteur.pageAcces.sousTitre' => 'حالة وصول كل ملف طالب.',
			'compte.tuteur.pageAcces.sansEcheance' => 'دون تاريخ انتهاء',
			'compte.tuteur.pageAcces.jusqua' => ({required Object date}) => 'مفتوح حتى ⁨${date}⁩',
			'compte.tuteur.pageAcces.expire' => ({required Object date}) => 'انتهى في ⁨${date}⁩',
			'compte.tuteur.pageAcces.pastilleActif' => 'ساري',
			'compte.tuteur.pageAcces.pastilleExpire' => 'منتهٍ',
			'compte.tuteur.pageAcces.aucunTitre' => 'لا ملف طالب',
			'compte.tuteur.pageAcces.aucunePhrase' => 'سيظهر هنا وصول كل ملف طالب.',
			'compte.tuteur.pageAcces.titulaire' => 'حسابك الرئيسي ليس له موعد انتهاء خاص: يُضبط الوصول لكل ملف على حدة.',
			'compte.tuteur.pagePaiements.titre' => 'المدفوعات والإيصالات',
			'compte.tuteur.pagePaiements.indisponibleTitre' => 'المدفوعات غير قابلة للاطلاع بعد',
			'compte.tuteur.pagePaiements.indisponiblePhrase' => 'سجل المدفوعات والإيصالات ووسائل الدفع غير متاحة في التطبيق بعد. لا يُطلب منك أي دفع هنا.',
			'compte.tuteur.pagePaiements.aucunTitre' => 'لا دفعة مسجَّلة',
			'compte.tuteur.pagePaiements.aucunePhrase' => 'ستظهر هنا المدفوعات التي تسجّلها الأكاديمية.',
			'compte.tuteur.pagePaiements.paiementDu' => ({required Object date}) => 'دفعة ⁨${date}⁩',
			'compte.tuteur.pagePaiements.justificatif' => 'الإيصال متاح',
			'compte.tuteur.pagePreferences.titre' => 'التفضيلات',
			'compte.tuteur.pagePreferences.sousTitre' => 'خصّص تجربتك على هذا الجهاز.',
			'compte.tuteur.pagePreferences.apparence' => 'المظهر',
			'compte.tuteur.pagePreferences.apparenceDetail' => 'المظهر والراحة البصرية',
			'compte.tuteur.pagePreferences.langue' => 'اللغة والمنطقة',
			'compte.tuteur.pagePreferences.notifications' => 'الإشعارات',
			'compte.tuteur.pagePreferences.notificationsDetail' => 'غير متاحة في التطبيق بعد',
			'compte.tuteur.pageApparence.titre' => 'المظهر',
			'compte.tuteur.pageApparence.sousTitre' => 'مطبَّق على هذا الجهاز.',
			'compte.tuteur.pageApparence.theme' => 'مظهر التطبيق',
			'compte.tuteur.pageApparence.themeDetail' => 'خصّص مظهر Rewayah.',
			'compte.tuteur.pageApparence.confort' => 'الراحة البصرية',
			'compte.tuteur.pageApparence.animations' => 'الحركة',
			'compte.tuteur.pageApparence.animationsDetail' => 'تقلّ حين يطلب جهازك ذلك',
			'compte.tuteur.pageApparence.texte' => 'حجم النص',
			'compte.tuteur.pageApparence.texteDetail' => 'يتبع حجم النظام',
			'compte.tuteur.pageAide.titre' => 'المساعدة والدعم',
			'compte.tuteur.pageAide.indisponibleTitre' => 'المساعدة غير متاحة بعد',
			'compte.tuteur.pageAide.indisponiblePhrase' => 'الأسئلة الشائعة والتواصل مع الأكاديمية غير مفتوحة في التطبيق بعد.',
			'compte.tuteur.pageAide.canalCourriel' => 'بريد الأكاديمية الإلكتروني',
			'compte.tuteur.pageAide.canalLien' => 'صفحة مساعدة الأكاديمية',
			'compte.tuteur.pageAide.aucunCanal' => 'لا قناة مساعدة منشورة الآن.',
			'compte.tuteur.pageLegal.titre' => 'المعلومات القانونية',
			'compte.tuteur.pageLegal.documents' => 'الوثائق المقبولة',
			'compte.tuteur.pageLegal.conditionsTuteur' => 'شروط وليّ الأمر',
			'compte.tuteur.pageLegal.contratEnseignant' => 'عقد المعلم',
			'compte.tuteur.pageLegal.accuseEnregistrement' => 'الإقرار بتسجيل الدروس',
			'compte.tuteur.pageLegal.acceptation' => ({required Object version, required Object date}) => 'الإصدار ⁨${version}⁩، مقبول في ⁨${date}⁩',
			'compte.tuteur.pageLegal.aucunTitre' => 'لا وثيقة مقبولة',
			'compte.tuteur.pageLegal.aucun' => 'لا وثيقة مقبولة مسجَّلة لهذا الحساب.',
			'compte.tuteur.pageLegal.lectureSeule' => 'الوثيقة المقبولة لا تُعدَّل.',
			'compte.tuteur.pageLegal.textes' => 'الشروط والخصوصية',
			'compte.tuteur.pageLegal.textesIndisponibles' => 'الشروط العامة وسياسة الخصوصية والإشعارات القانونية غير قابلة للاطلاع في التطبيق بعد.',
			'tc.bibliotheque.sections.groupe' => 'المواد المعروضة',
			'tc.bibliotheque.sections.continuer' => 'متابعة',
			'tc.bibliotheque.sections.pourCeGroupe' => 'لهذا الفصل',
			'tc.bibliotheque.sections.recents' => 'المستخدمة مؤخرًا',
			'tc.bibliotheque.sections.tousLesSupports' => 'كل المواد',
			'tc.bibliotheque.sections.resultats' => 'النتائج',
			'tc.bibliotheque.titre' => 'المكتبة',
			'tc.bibliotheque.rechercheIndication' => 'العنوان أو المستوى أو السورة أو الصفحة',
			'tc.bibliotheque.rechercheLibelle' => 'البحث عن مادة',
			'tc.bibliotheque.effacerRecherche' => 'عرض الكل',
			'tc.bibliotheque.filtre.type' => 'النوع',
			'tc.bibliotheque.filtre.disponibilite' => 'التوفر',
			'tc.bibliotheque.vide.message' => 'لا مادة منشورة حتى الآن',
			'tc.bibliotheque.vide.invitation' => 'سيضع معلموك هنا مواد دروسك.',
			'tc.bibliotheque.aucunResultat.message' => 'لا مادة مطابقة',
			'tc.bibliotheque.aucunResultat.invitation' => 'جرّب كلمة أخرى، أو خفّف عوامل التصفية.',
			'tc.bibliotheque.indisponible.message' => 'المكتبة غير متاحة مؤقتًا',
			'tc.bibliotheque.indisponible.action' => 'إعادة المحاولة',
			'tc.bibliotheque.introuvable.message' => 'هذه المادة غير مفتوحة لك',
			'tc.bibliotheque.introuvable.invitation' => 'ربما سُحبت، أو هي مخصصة لفصل آخر. يمكن لمعلمك أن يعيد فتحها لك.',
			'tc.bibliotheque.offline.aTelecharger' => 'للتنزيل',
			'tc.bibliotheque.offline.enCours' => 'جارٍ التنزيل',
			'tc.bibliotheque.offline.enCache' => 'في الذاكرة المؤقتة',
			'tc.bibliotheque.offline.telecharge' => 'تم التنزيل',
			'tc.bibliotheque.offline.indisponible' => 'غير متاحة دون اتصال',
			'tc.bibliotheque.type.quran' => 'القرآن',
			'tc.bibliotheque.type.texteStructure' => 'نص',
			'tc.bibliotheque.type.pdf' => 'PDF',
			'tc.bibliotheque.type.image' => 'صورة',
			'tc.bibliotheque.type.lecon' => 'درس',
			'tc.bibliotheque.detail.titre' => 'المادة',
			'tc.bibliotheque.detail.capacites' => 'ما تتيحه هذه المادة',
			'tc.bibliotheque.detail.niveaux' => 'المستويات',
			'tc.bibliotheque.detail.sansVersion' => 'لا نسخة منشورة: لا شيء للفتح الآن.',
			'tc.bibliotheque.detail.apercuIndisponible' => 'معاينة هذا التنسيق غير متاحة بعد في التطبيق. يمكنك حفظ نسخة منه.',
			'tc.bibliotheque.detail.renduCoran' => 'يُفتح القرآن في القارئ المخصص له.',
			'tc.bibliotheque.action.telecharger' => 'إتاحتها دون اتصال',
			'tc.bibliotheque.action.liberer' => 'تحرير المساحة',
			'tc.bibliotheque.action.enregistrerCopie' => 'حفظ نسخة',
			'tc.bibliotheque.message.copieEnregistree' => 'حُفظت النسخة',
			'tc.bibliotheque.message.copieImpossible' => 'هذه النسخة غير متاحة الآن',
			'tc.bibliotheque.message.telechargementImpossible' => 'هذه المادة غير متاحة دون اتصال بعد',
			'tc.bibliotheque.message.horsLigneNonTelecharge' => 'تتاح بعد تنزيلها أو عند عودة الاتصال',
			'tc.bibliotheque.message.aucunTelechargement' => 'لا ملف للتنزيل في هذه النسخة.',
			'tc.bibliotheque.classe.titre' => 'اختيار مادة',
			'tc.bibliotheque.classe.sousTitre' => 'المادة المختارة تحل محل المعروضة. يستمر الدرس.',
			'tc.groupe.enseignant.sayyid' => 'سيد',
			'tc.groupe.enseignant.sayyida' => 'سيدة',
			'tc.groupe.enseignant.photoManquante' => 'الصورة مطلوبة',
			'tc.groupe.enseignant.photoManquanteDetail' => 'لم تُسجَّل صورة المعلم بعد.',
			'tc.groupe.mesGroupes.titre' => 'فصولي',
			'tc.groupe.mesGroupes.aucun' => 'لا فصل حتى الآن',
			'tc.groupe.mesGroupes.aucunDetail' => 'ستضعك الأكاديمية في فصل حين يتوفر موعد يناسبك.',
			'tc.groupe.commun.erreur' => 'تعذّرت قراءة فصولك',
			'tc.groupe.commun.reessayer' => 'إعادة المحاولة',
			'tc.groupe.carte.ouvrir' => ({required Object libelle}) => 'فتح الفصل ⁨${libelle}⁩',
			'tc.groupe.carte.capacite' => ({required Object membres, required Object seuil}) => '⁨${membres}⁩ من ⁨${seuil}⁩',
			'tc.groupe.carte.capacitePhrase' => ({required Object membres, required Object seuil}) => '⁨${membres}⁩ طلاب من ⁨${seuil}⁩ مقاعد',
			'tc.groupe.carte.complet' => 'مكتمل',
			'tc.groupe.carte.prochainCours' => 'الدرس القادم',
			'tc.groupe.carte.aucuneSeance' => 'لا حصة مقررة',
			'tc.groupe.carte.aucuneSeanceDetail' => 'لم يُحدَّد جدول هذا الفصل بعد.',
			'tc.groupe.carte.duree' => ({required Object valeur}) => 'المدة ⁨${valeur}⁩',
			'tc.groupe.carte.dureeLibelle' => 'المدة',
			'tc.groupe.carte.rejoindre' => 'انضمام',
			'tc.groupe.cours.coursEtNiveau' => ({required Object cours, required Object niveau}) => '⁨${cours}⁩ · ⁨${niveau}⁩',
			'tc.groupe.temps.dansMinutes' => ({required Object minutes}) => 'الدرس بعد ⁨${minutes}⁩ دقيقة',
			'tc.groupe.temps.dansHeures' => ({required Object heures, required Object minutes}) => 'الدرس بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'tc.groupe.temps.imminent' => 'الدرس وشيك',
			'tc.groupe.temps.salleOuverte' => ({required Object reste}) => 'القاعة مفتوحة · ⁨${reste}⁩',
			'tc.groupe.temps.salleOuverteCourt' => 'القاعة مفتوحة',
			'tc.groupe.temps.attente' => 'أنت في القاعة. لم يبدأ الدرس بعد.',
			'tc.groupe.temps.attenteDetail' => 'وقت الانتظار هذا لا يُحتسب في حضورك.',
			'tc.groupe.temps.enSalle' => 'في القاعة',
			'tc.groupe.temps.resteMinutes' => ({required Object minutes}) => 'المتبقي ⁨${minutes}⁩ د',
			'tc.groupe.temps.resteHeures' => ({required Object heures, required Object minutes}) => 'المتبقي ⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'tc.groupe.temps.enCours' => ({required Object reste}) => 'حصة مباشرة · ⁨${reste}⁩',
			'tc.groupe.temps.enDirect' => 'مباشر',
			'tc.groupe.temps.prolongee' => 'الحصة ما زالت مباشرة',
			'tc.groupe.temps.depassement' => 'تجاوز الوقت',
			'tc.groupe.temps.terminee' => 'انتهى الدرس',
			'tc.groupe.duree.minutes' => ({required Object minutes}) => '⁨${minutes}⁩ د',
			'tc.groupe.duree.heures' => ({required Object heures}) => '⁨${heures}⁩ س',
			'tc.groupe.duree.heuresMinutes' => ({required Object heures, required Object minutes}) => '⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'tc.groupe.horloges.votreHeure' => 'توقيتك',
			'tc.groupe.horloges.chezEnseignant' => ({required Object nomme}) => 'عند ⁨${nomme}⁩',
			'tc.groupe.horloges.heureGroupe' => 'توقيت الفصل',
			'tc.groupe.horloges.heureEtVille' => ({required Object heure, required Object ville}) => '⁨${heure}⁩ ⁨${ville}⁩',
			'tc.groupe.dst.j30' => 'تغيير التوقيت بعد شهر',
			'tc.groupe.dst.j7' => 'تغيير التوقيت الأسبوع القادم',
			'tc.groupe.dst.j1' => 'تغيير التوقيت غدًا',
			'tc.groupe.dst.detail' => ({required Object avant, required Object apres}) => 'سينتقل درسك من ⁨${avant}⁩ إلى ⁨${apres}⁩.',
			'tc.groupe.session.conseilAppareil' => 'يُنصح بجهاز لوحي أو حاسوب للدرس. الهاتف مدعوم أيضًا.',
			'tc.groupe.espace.retour' => 'فصولي',
			'tc.groupe.espace.avantProchainCours' => 'قبل الدرس القادم',
			'tc.groupe.espace.aucuneAction' => 'لا شيء للتحضير الآن',
			'tc.groupe.espace.bibliotheque' => 'المكتبة',
			'tc.groupe.espace.bibliothequeVoirTout' => 'عرض الكل',
			'tc.groupe.espace.progression' => 'التقدم',
			'tc.groupe.espace.roster' => 'طلاب الفصل',
			'tc.groupe.espace.reprendreLeCours' => 'استئناف الدرس',
			'tc.groupe.espace.introuvable' => 'هذا الفصل غير مفتوح لك',
			'tc.groupe.espace.introuvableDetail' => 'ربما أُغلق، أو يخص ملفًا آخر.',
			'tc.groupe.emplacement.nonBranche' => 'قريبًا',
			'tc.groupe.emplacement.nonBrancheDetail' => 'سيُربط هذا المحتوى بهذه المساحة قريبًا.',
			'tc.coran.modes.mushaf' => 'صفحة المصحف',
			'tc.coran.modes.verset' => 'قراءة مكبَّرة',
			'tc.coran.modes.focus' => 'التركيز',
			'tc.coran.modes.choisir' => 'طريقة القراءة',
			'tc.coran.mushaf.coteDroite' => 'الصفحة اليمنى',
			'tc.coran.mushaf.coteGauche' => 'الصفحة اليسرى',
			'tc.coran.mushaf.ouverture' => ({required Object droite, required Object gauche}) => 'الصفحتان المفتوحتان ⁨${droite}⁩ و⁨${gauche}⁩',
			'tc.coran.fidelite.approchee' => 'تنسيق تقريبي',
			'tc.coran.fidelite.approcheeDetail' => 'آيات هذه الصفحة هي بالضبط آيات صفحة مصحف المدينة. أما توزيعها على الأسطر فهو توزيع هذه الشاشة: لم يُستورد بعد تقسيم الأسطر في الطبعة.',
			'tc.coran.fidelite.fidele' => 'تنسيق الطبعة',
			'tc.coran.zoom.bride' => 'التكبير محدود بالعرض: ما زاد عليه يقطع الكلمات.',
			'tc.coran.zoom.valeur' => ({required Object pourcent}) => '⁨${pourcent}⁩ ٪',
			'tc.coran.zoom.renvoiLectureAgrandie' => 'لتكبير النص، انتقل إلى القراءة المكبَّرة: صفحة المصحف تحافظ على هيئتها.',
			'tc.coran.navigation.titre' => 'الانتقال إلى',
			'tc.coran.navigation.ouvrir' => 'الانتقال إلى صفحة',
			'tc.coran.navigation.champ' => 'صفحة أو سورة أو جزء أو مرجع',
			'tc.coran.navigation.indice' => 'مثلًا 18، الكهف، الجزء 15، 2:255',
			'tc.coran.navigation.limite' => 'يشمل البحث أرقام الصفحات والمراجع وأسماء السور. البحث في نص القرآن غير متاح بعد.',
			'tc.coran.navigation.aucunResultat' => 'لم يُعثر على مرجع',
			'tc.coran.navigation.aucunResultatDetail' => 'جرّب رقم صفحة، أو اسم سورة، أو مرجعًا مثل 2:255.',
			'tc.coran.navigation.pageNumero' => ({required Object page}) => 'الصفحة ⁨${page}⁩',
			'tc.coran.reprise.groupe' => 'استئناف الدرس',
			'tc.coran.reprise.groupeDetail' => ({required Object page}) => 'كان الفصل في الصفحة ⁨${page}⁩',
			'tc.coran.focus.aucunePlage' => 'لا مقطع مُبرَز',
			'tc.coran.focus.aucunePlageDetail' => 'يتبع التركيز المقطع الذي يحدده المعلم. خارج الفصل، يتمركز على الصفحة المفتوحة.',
			'tc.coran.focus.quitter' => 'الخروج من التركيز',
			'tc.outils.dock.titre' => 'الأدوات',
			'tc.outils.dock.deplacer' => 'نقل الأدوات',
			'tc.outils.dock.position.bas' => 'في الأسفل',
			'tc.outils.dock.position.gauche' => 'في جهة البداية',
			'tc.outils.dock.position.droite' => 'في جهة النهاية',
			'tc.outils.dock.bibliotheque' => 'المكتبة',
			'tc.outils.dock.focus' => 'التركيز',
			'tc.outils.dock.marquer' => 'وضع علامة',
			'tc.outils.dock.masquer' => 'إخفاء',
			'tc.outils.dock.stylet' => 'القلم',
			'tc.outils.dock.pointeur' => 'المؤشر',
			'tc.outils.dock.revision' => 'المراجعة',
			'tc.outils.intention.aApprendre' => 'للحفظ',
			'tc.outils.intention.aRevoir' => 'للمراجعة',
			'tc.outils.intention.aRenforcer' => 'للتثبيت',
			'tc.outils.intention.aEntretenir' => 'للتعاهد',
			'tc.outils.intention.pourEvaluation' => 'للتقييم',
			'tc.outils.trait.stylet' => 'القلم',
			'tc.outils.trait.surligneur' => 'تظليل',
			'tc.outils.trait.gomme' => 'الممحاة',
			'tc.outils.trait.annuler' => 'تراجع',
			'tc.outils.trait.plus' => 'المزيد',
			'tc.outils.trait.ardoise' => 'لوح الملاحظات، اختياري: يبقى الدرس مقروءًا دونه',
			'tc.outils.trait.effacerDernier' => 'مسح آخر خط لي',
			'tc.outils.portee.temporaire' => 'وقت الشرح',
			'tc.outils.portee.seance' => 'حتى نهاية الدرس',
			'tc.outils.portee.enregistree' => 'الاحتفاظ بها دائمًا',
			'tc.outils.portee.aide' => 'إلى متى نحتفظ بهذه الملاحظات؟',
			'tc.outils.marquer.titre' => 'وضع علامة على هذا المقطع',
			'tc.outils.marquer.aide' => 'اختر ما يحتاجه هذا المقطع.',
			'tc.outils.marquer.retirer' => 'إزالة العلامة',
			'tc.outils.revision.titre' => 'للتحضير',
			'tc.outils.revision.aide' => 'يصبح المقطع المحدد عملًا للتحضير.',
			'tc.outils.revision.groupeEntier' => 'الفصل كله',
			'tc.outils.revision.consigne' => 'تعليمة قصيرة (اختياري)',
			'tc.outils.revision.creer' => 'تكليف بالعمل',
			'tc.outils.revision.posee' => 'تم التكليف بعمل للتحضير',
			'tc.outils.masquer.reveler' => 'إظهار',
			'tc.outils.masquer.refermer' => 'إخفاء من جديد',
			'tc.outils.masquer.tout' => 'إظهار الكل',
			'tc.outils.focus.quitter' => 'الخروج من التركيز',
			'tc.outils.annotation.ancrageDegrade' => 'لا مرجع نصيًا لهذا المقطع: ستتبع الملاحظة الصفحة لا الكلمات.',
			'tc.outils.annotation.horsPage' => 'الملاحظات مخفية: مقطعها ليس على الشاشة.',
			'tc.outils.annotation.aucuneSelection' => 'حدّد مقطعًا أولًا.',
			'tc.classe.entete.titreEnseignant.sayyid' => 'سيد',
			'tc.classe.entete.titreEnseignant.sayyida' => 'سيدة',
			'tc.classe.entete.resteMinutes' => ({required Object minutes}) => 'المتبقي ⁨${minutes}⁩ د',
			'tc.classe.entete.resteHeuresMinutes' => ({required Object heures, required Object minutes}) => 'المتبقي ⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'tc.classe.entete.coursEnCours' => 'الحصة ما زالت مباشرة',
			'tc.classe.entete.photoManquante' => 'صورة المعلم غير موجودة',
			'tc.classe.roster.titre' => 'الطلاب',
			'tc.classe.roster.compteur' => ({required Object presents, required Object attendus}) => 'الحاضرون: ⁨${presents}⁩ من أصل ⁨${attendus}⁩',
			'tc.classe.roster.indisponible' => 'قائمة الطلاب غير متاحة',
			'tc.classe.roster.indisponibleDetail' => 'تعذّرت قراءة حالات طلابك. يستمر الدرس.',
			'tc.classe.roster.vide' => 'لا طالب مسجَّل',
			'tc.classe.roster.videDetail' => 'لا طالب مسجَّل في هذه الحصة.',
			'tc.classe.roster.ouvrirFiche' => ({required Object prenom}) => 'فتح بطاقة ⁨${prenom}⁩',
			'tc.classe.roster.places' => ({required Object inscrits, required Object plafond}) => 'المقاعد: ⁨${inscrits}⁩ من ⁨${plafond}⁩',
			'tc.classe.etat.inconnu' => 'حالة غير معروفة',
			'tc.classe.etat.attendu' => 'منتظَر',
			'tc.classe.etat.enConnexion' => 'جارٍ الاتصال',
			'tc.classe.etat.present' => 'حاضر',
			'tc.classe.etat.enRetard' => 'متأخر',
			'tc.classe.etat.deconnecte' => 'غير متصل',
			'tc.classe.etat.enReconnexion' => 'جارٍ إعادة الاتصال',
			'tc.classe.etat.sorti' => 'خرج',
			'tc.classe.etat.absent' => 'غائب',
			'tc.classe.fiche.niveau' => 'المستوى',
			'tc.classe.fiche.objectif' => 'الهدف الحالي',
			'tc.classe.fiche.derniereSeance' => 'آخر حصة',
			'tc.classe.fiche.page' => ({required Object page}) => 'الصفحة ⁨${page}⁩',
			'tc.classe.fiche.travailEnCours' => ({required Object nombre}) => 'العناصر: ⁨${nombre}⁩',
			'tc.classe.fiche.aReprendre' => 'للاستئناف',
			'tc.classe.fiche.presenceRecente' => 'الحضور الأخير',
			'tc.classe.fiche.assiduite' => ({required Object presences, required Object total}) => 'الدروس: ⁨${presences}⁩ من ⁨${total}⁩',
			'tc.classe.fiche.travailActuel' => 'العمل الحالي',
			'tc.classe.fiche.interfaceGuidee' => 'وضع إمكانية الوصول',
			'tc.classe.fiche.sansPedagogie' => 'المتابعة التعليمية غير متاحة',
			'tc.classe.fiche.sansPedagogieDetail' => 'المسار والأهداف والعمل الجاري غير مفتوحة للمعلم بعد.',
			'tc.classe.action.rappel' => 'نداء هادئ',
			'tc.classe.action.reciter' => 'اختيار للتلاوة',
			'tc.classe.action.noter' => 'تدوين ملاحظة',
			'tc.classe.action.signaler' => 'الإبلاغ عن حاجة',
			'tc.classe.action.contexte' => 'فتح السياق',
			'tc.classe.rappel.recu' => 'المعلم يناديك',
			'tc.classe.rappel.echec' => 'تعذّر إرسال النداء',
			'tc.classe.rappel.echecDroit' => 'دخولك إلى هذه الحصة لا يسمح بنداء طالب',
			'tc.classe.rappel.cooldown' => ({required Object secondes}) => 'تم النداء. مجددًا بعد ⁨${secondes}⁩ ث',
			'tc.classe.recitation.titre' => 'التلاوة',
			'tc.classe.recitation.actif' => ({required Object prenom}) => 'التلاوة: ⁨${prenom}⁩',
			'tc.classe.recitation.pastille' => 'في التلاوة',
			'tc.classe.recitation.suivants' => 'بعد ذلك',
			'tc.classe.recitation.personne' => 'لا أحد يتلو',
			'tc.classe.recitation.arreter' => 'إيقاف التلاوة',
			'tc.classe.support.aucun' => 'لا مادة معروضة',
			'tc.classe.support.aucunDetail' => 'افتح المكتبة لعرض مادة على الفصل.',
			'tc.classe.support.bibliotheque' => 'المكتبة',
			'tc.classe.support.bibliothequeAbsente' => 'المكتبة غير موصولة',
			'tc.classe.support.bibliothequeAbsenteDetail' => 'سيتاح اختيار المادة بمجرد دمج الفهرس.',
			'tc.classe.commandes.micro' => 'فتح الميكروفون',
			'tc.classe.commandes.microFermer' => 'إغلاق الميكروفون',
			'tc.classe.commandes.camera' => 'فتح الكاميرا',
			'tc.classe.commandes.cameraFermer' => 'إغلاق الكاميرا',
			'tc.classe.commandes.microCoupe' => 'الميكروفون مغلق',
			'tc.classe.commandes.quitter' => 'مغادرة',
			'tc.classe.commandes.quitterQuestion' => 'مغادرة الدرس؟',
			'tc.classe.commandes.quitterConsequence' => 'سيُسجَّل خروجك. يمكنك العودة ما دامت الحصة مفتوحة.',
			'tc.classe.commandes.fermerBibliotheque' => 'إغلاق المكتبة',
			'tc.classe.scene.vide' => 'أنت وحدك في القاعة الآن',
			'tc.classe.scene.sansImage' => 'دون صورة',
			'tc.classe.reseau.bon' => 'الشبكة جيدة',
			'tc.classe.reseau.mediocre' => 'الشبكة غير مستقرة',
			'tc.classe.reseau.perdu' => 'انقطعت الشبكة',
			'tc.classe.attente.materiel' => 'جارٍ التحقق من الميكروفون',
			'tc.classe.attente.ouverture' => 'جارٍ فتح الدرس',
			'tc.classe.attente.connexion' => 'جارٍ الاتصال بالدرس',
			'tc.classe.attente.refus' => 'الدرس غير متاح الآن',
			'tc.classe.lien.instable' => 'الاتصال غير مستقر',
			'tc.classe.lien.reconnexion' => 'جارٍ إعادة الاتصال',
			'tc.classe.lien.retabli' => 'عاد الاتصال',
			'tc.classe.lien.echec' => 'انقطع الاتصال',
			'tc.classe.lien.retourDeSuspension' => 'أوقف النظام الدرس مؤقتًا. جارٍ التحقق من الاتصال.',
			'tc.classe.barre.titre' => 'حصة مباشرة',
			'tc.classe.barre.revenir' => ({required Object groupe}) => 'العودة إلى درس ⁨${groupe}⁩',
			'tc.classe.prevol.titre' => 'قبل فتح الدرس',
			'tc.classe.prevol.microOk' => 'تم العثور على ميكروفون',
			'tc.classe.prevol.microAbsent' => 'لا ميكروفون صالح',
			'tc.classe.prevol.cameraOk' => 'تم العثور على كاميرا',
			'tc.classe.prevol.cameraAbsente' => 'لا كاميرا. يبقى الدرس ممكنًا.',
			'tc.classe.prevol.permissionRefusee' => 'رُفض الوصول إلى الميكروفون. اسمح به لفتح الدرس.',
			'tc.classe.prevol.reessayer' => 'التحقق من جديد',
			'tc.classe.observation.restant' => ({required Object secondes}) => 'بقيت ⁨${secondes}⁩ ث',
			'tc.realtime.transport.partage_indisponible' => 'مشاركة المادة غير متاحة على هذا الخادم. يستمر الدرس، لكن الأجهزة الأخرى لن تتبع الصفحة.',
			'tc.realtime.etat.restauration_impossible' => 'تعذّر استرجاع المادة الجارية. اطلب من المعلم أن يعرضها من جديد.',
			'tc.observation.entree.titre' => 'متابعة الحصة',
			'tc.observation.entree.tuteurIntro' => 'يمكنك مشاهدة درس طفلك لوقت قصير. يبقى الميكروفون والكاميرا مغلقين.',
			'tc.observation.entree.adminIntro' => 'اختر طريقتك قبل الدخول. لن تتغير بعد ذلك.',
			'tc.observation.entree.controleurIntro' => 'تدخل في مراقبة غير مرئية. لا ميكروفون ولا كاميرا.',
			'tc.observation.entree.entrer' => 'دخول',
			'tc.observation.entree.modeDiscret' => 'المتابعة دون ظهور',
			'tc.observation.entree.modeDiscretDetail' => 'غير مرئي للمشاركين. دون ميكروفون ولا كاميرا، ودون إعلان.',
			'tc.observation.entree.modeVisible' => 'الانضمام إلى الفصل',
			'tc.observation.entree.modeVisibleDetail' => 'مرئي للجميع باسم إدارة Rewayah. الميكروفون والكاميرا مسموحان، ويُعلَن عن الدخول.',
			'tc.observation.entree.nomInstitutionnel' => 'إدارة Rewayah',
			'tc.observation.entree.visiteJournalisee' => 'زيارة مقيَّدة في السجل: الهوية، والحصة، والدخول، والخروج، والمدة.',
			'tc.observation.entree.roleSansObservation' => 'حسابك لا يتابع الحصص.',
			'tc.observation.entree.retourClasse' => 'العودة إلى الفصل',
			'tc.observation.explication.titre' => 'لمحة عن تعلّمه',
			'tc.observation.explication.regleUne' => ({required Object n, required Object duree}) => '⁨${n}⁩ زيارة مدتها ⁨${duree}⁩',
			'tc.observation.explication.regle' => ({required Object n, required Object duree}) => '⁨${n}⁩ زيارات مدة كل منها ⁨${duree}⁩',
			'tc.observation.explication.regleDetail' => 'لكل حصة ولكل وليّ أمر، حتى لو كان أكثر من طفل من أطفالك في الفصل.',
			_ => null,
		} ?? switch (path) {
			'tc.observation.explication.ecoute' => 'استمع إلى المعلم والطلاب',
			'tc.observation.explication.ecouteDetail' => 'تسمع المعلم والطلاب الذين يتكلمون، ومنهم طفلك.',
			'tc.observation.explication.sansMedia' => 'دون ميكروفون ولا كاميرا',
			'tc.observation.explication.sansMediaDetail' => 'يبقى الميكروفون والكاميرا معطَّلين حتى لا يُقاطَع الفصل.',
			'tc.observation.explication.revenir' => 'إن كان طالب آخر يتلو في زيارتك الأولى، يمكنك العودة لاحقًا للاستماع إلى طفلك.',
			'tc.observation.explication.ecourtee' => 'الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.',
			'tc.observation.explication.sansIntervenir' => 'حفاظًا على التركيز، تتابع دون أن تتدخل.',
			'tc.observation.explication.informes' => 'طفلك ومعلمه على علم.',
			'tc.observation.explication.observer' => 'المتابعة الآن',
			'tc.observation.explication.pasMaintenant' => 'ليس الآن',
			'tc.observation.explication.restanteUne' => ({required Object restantes, required Object max}) => 'الزيارات المتبقية لهذه الحصة: ⁨${restantes}⁩ من ⁨${max}⁩',
			'tc.observation.explication.restantes' => ({required Object restantes, required Object max}) => 'الزيارات المتبقية لهذه الحصة: ⁨${restantes}⁩ من ⁨${max}⁩',
			'tc.observation.explication.aucuneRestante' => 'لا زيارة متبقية لهذه الحصة',
			'tc.observation.disponibilite.visitesEpuiseesTitre' => 'لا زيارة متبقية لهذه الحصة',
			'tc.observation.disponibilite.visitesEpuisees' => 'استخدمت زياراتك. يمكنك متابعة الحصة القادمة.',
			'tc.observation.disponibilite.tempsEpuiseTitre' => 'انتهى وقت المتابعة',
			'tc.observation.disponibilite.tempsEpuise' => 'استُخدم وقت متابعتك لهذه الحصة. يمكنك متابعة الحصة القادمة.',
			'tc.observation.disponibilite.seanceNonCommenceeTitre' => 'لم تبدأ الحصة بعد',
			'tc.observation.disponibilite.seanceNonCommencee' => 'تُفتح المتابعة أثناء الحصة.',
			'tc.observation.disponibilite.seanceTermineeTitre' => 'انتهت الحصة',
			'tc.observation.disponibilite.seanceTerminee' => 'يمكنك متابعة الحصة القادمة.',
			'tc.observation.disponibilite.seanceNonTenueTitre' => 'هذه الحصة لا تُعقد',
			'tc.observation.disponibilite.seanceNonTenue' => 'أُلغيت أو أُجّلت أو لم تُعقد.',
			'tc.observation.disponibilite.horsFenetreTitre' => 'الحصة غير مفتوحة الآن',
			'tc.observation.disponibilite.horsFenetre' => 'المتابعة ممكنة أثناء الحصة فقط.',
			'tc.observation.disponibilite.desactiveeTitre' => 'المتابعة مغلقة لهذا الفصل',
			'tc.observation.disponibilite.desactivee' => 'أغلقت الإدارة متابعة هذا الفصل.',
			'tc.observation.disponibilite.lienAbsentTitre' => 'لا أحد من أطفالك في هذه الحصة',
			'tc.observation.disponibilite.lienAbsent' => 'المتابعة مخصصة لأولياء أمور طلاب الحصة.',
			'tc.observation.disponibilite.enfantAbsentTitre' => 'طفلك ليس في الحصة',
			'tc.observation.disponibilite.enfantAbsent' => 'تُفتح المتابعة حين يكون طفلك حاضرًا.',
			'tc.observation.disponibilite.presenceTitre' => 'جارٍ التحقق من الحضور',
			'tc.observation.disponibilite.presence' => 'تُفتح المتابعة بمجرد تأكيد حضور طفلك.',
			'tc.observation.disponibilite.visiteOuverteTitre' => 'زيارة مفتوحة بالفعل',
			'tc.observation.disponibilite.visiteOuverte' => 'إحدى زياراتك ما زالت مفتوحة لهذه الحصة، على هذا الجهاز أو على غيره. وهي تُحتسب من زياراتك.',
			'tc.observation.disponibilite.fermeeTitre' => 'المتابعة غير مفتوحة بعد',
			'tc.observation.disponibilite.fermee' => 'متابعة أولياء الأمور للحصص غير مفتوحة بعد. ستُقترح هنا بمجرد فتحها.',
			'tc.observation.disponibilite.reseauTitre' => 'تعذّر التحقق',
			'tc.observation.disponibilite.reseau' => 'تعذّر التحقق من توفر المتابعة. لم تبدأ أي زيارة.',
			'tc.observation.disponibilite.capaciteTitre' => 'المتابعة غير متاحة',
			'tc.observation.disponibilite.capacite' => 'المتابعة غير متاحة الآن.',
			'tc.observation.connexion.titre' => 'الاتصال والتحقق',
			'tc.observation.connexion.phrase' => 'يجري التحقق من زياراتك المتبقية. تبدأ الزيارة بمجرد قبول الدخول، بما في ذلك اتصال الفيديو.',
			'tc.observation.connexion.enCours' => 'جارٍ الاتصال والتحقق',
			'tc.observation.connexion.prolongee' => 'ابقَ على هذه الصفحة: التحقق مستمر.',
			'tc.observation.connexion.impossibleTitre' => 'تعذّر الاتصال',
			'tc.observation.connexion.impossible' => 'لم يتم الدخول إلى الحصة. تحقّق من اتصالك ثم أعد المحاولة: سيُعاد التحقق من زياراتك المتبقية.',
			'tc.observation.duree.secondeUne' => ({required Object n}) => '⁨${n}⁩ ثانية',
			'tc.observation.duree.secondes' => ({required Object n}) => '⁨${n}⁩ ثوانٍ',
			'tc.observation.duree.minuteUne' => ({required Object n}) => '⁨${n}⁩ دقيقة',
			'tc.observation.duree.minutes' => ({required Object n}) => '⁨${n}⁩ دقائق',
			'tc.observation.duree.minutesSecondes' => ({required Object m, required Object s}) => '⁨${m}⁩ د ⁨${s}⁩ ث',
			'tc.observation.refus.politiqueDesactivee' => 'المتابعة معطَّلة لهذا الفصل.',
			'tc.observation.refus.quotaVisites' => 'استخدمت زياراتك لهذه الحصة بالفعل.',
			'tc.observation.refus.tempsEpuise' => 'نفد وقت متابعتك لهذه الحصة.',
			'tc.observation.refus.lienTuteur' => 'لست مرتبطًا بأي طالب في هذه الحصة.',
			'tc.observation.refus.seanceNonActive' => 'الحصة ليست جارية.',
			'tc.observation.refus.horsFenetre' => 'القاعة غير مفتوحة في هذا الوقت.',
			'tc.observation.refus.indisponible' => 'المتابعة غير متاحة الآن.',
			'tc.observation.refus.capaciteAbsente' => 'المتابعة غير مفعَّلة بعد في هذا التثبيت.',
			'tc.observation.visite.titre' => 'المتابعة جارية',
			'tc.observation.visite.quitter' => 'مغادرة',
			'tc.observation.visite.supportIndisponible' => 'تظهر هنا المادة التي يشاركها المعلم.',
			'tc.observation.visite.enseignant' => 'المعلم',
			'tc.observation.visite.monEnfant' => 'طفلك',
			'tc.observation.visite.budgetIncertain' => 'الوقت المتبقي غير مؤكَّد من الخادم.',
			'tc.observation.visite.videoIndisponible' => 'تعذّر فتح فيديو الحصة. يستمر احتساب وقت متابعتك.',
			'tc.observation.visite.sortieNonConfirmee' => 'تعذّر تأكيد نهاية زيارتك. سيغلقها الخادم.',
			'tc.observation.visite.restantes' => 'متبقية',
			'tc.observation.visite.decompteLu' => ({required Object duree}) => 'الوقت المتبقي: ⁨${duree}⁩',
			'tc.observation.visite.enDirect' => 'مباشر',
			'tc.observation.visite.connexion' => 'الاتصال',
			'tc.observation.visite.reconnexion' => 'إعادة الاتصال',
			'tc.observation.visite.videoCoupee' => 'الفيديو غير متاح',
			'tc.observation.visite.reconnexionDetail' => 'انقطع الاتصال، جارٍ إعادة الاتصال. يستمر احتساب وقت متابعتك.',
			'tc.observation.visite.sonRecu' => 'الصوت يصل',
			'tc.observation.visite.sonInterrompu' => 'الصوت منقطع',
			'tc.observation.visite.agrandir' => 'تكبير',
			'tc.observation.visite.reduire' => 'تصغير',
			'tc.observation.visite.cameraFermee' => 'الكاميرا مغلقة',
			'tc.observation.visite.pasEncoreLa' => 'ليس في القاعة بعد',
			'tc.observation.visite.parle' => ({required Object nom}) => 'الكلمة الآن لـ⁨${nom}⁩',
			'tc.observation.visite.quitterQuestion' => 'مغادرة الزيارة؟',
			'tc.observation.visite.quitterConsequence' => ({required Object duree}) => 'بقي لك ⁨${duree}⁩. الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.',
			'tc.observation.visite.quitterConsequenceSansTemps' => 'الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.',
			'tc.observation.visite.quitterConfirmer' => 'مغادرة الزيارة',
			'tc.observation.fin.sortieVolontaire' => 'غادرت المتابعة.',
			'tc.observation.fin.quotaAtteint' => 'انتهى وقت متابعتك.',
			'tc.observation.fin.seanceTerminee' => 'انتهت الحصة.',
			'tc.observation.fin.revocationServeur' => 'قُطعت متابعتك.',
			'tc.observation.fin.deconnexion' => 'انقطع الاتصال.',
			'tc.observation.resultat.premiereTerminee' => 'انتهت زيارتك الأولى',
			'tc.observation.resultat.derniereTerminee' => 'انتهت زيارتك الأخيرة',
			'tc.observation.resultat.terminee' => 'انتهت زيارتك',
			'tc.observation.resultat.dureeAtteinte' => 'بلغت الزيارة مدتها',
			'tc.observation.resultat.interrompue' => 'قُطعت المتابعة',
			'tc.observation.resultat.continuePour' => ({required Object prenom}) => 'تستمر الحصة لـ⁨${prenom}⁩.',
			'tc.observation.resultat.continueSansPrenom' => 'تستمر الحصة.',
			'tc.observation.resultat.resteUne' => ({required Object duree}) => 'بقيت لك زيارة واحدة مدتها ⁨${duree}⁩. عد لاحقًا للاستماع إلى طفلك.',
			'tc.observation.resultat.restent' => ({required Object n, required Object duree}) => 'بقيت لك ⁨${n}⁩ زيارات مدة كل منها ⁨${duree}⁩. عد لاحقًا للاستماع إلى طفلك.',
			'tc.observation.resultat.resteUneSansDuree' => 'بقيت لك زيارة واحدة. عد لاحقًا للاستماع إلى طفلك.',
			'tc.observation.resultat.restentSansDuree' => ({required Object n}) => 'بقيت لك ⁨${n}⁩ زيارات. عد لاحقًا للاستماع إلى طفلك.',
			'tc.observation.resultat.aucune' => 'استخدمت زياراتك لهذه الحصة. يمكنك متابعة الحصة القادمة.',
			'tc.observation.resultat.prochaineSeance' => 'يمكنك متابعة الحصة القادمة.',
			'tc.observation.resultat.verification' => 'جارٍ التحقق من زياراتك المتبقية',
			'tc.observation.resultat.inconnues' => 'تعذّر التحقق من زياراتك المتبقية. سيُعاد التحقق منها في الفصل.',
			'tc.observation.resultat.voirObservations' => 'عرض متابعاتي',
			'tc.observation.annonce.tuteurObserve' => ({required Object prenomEnfant}) => 'وليّ أمر ⁨${prenomEnfant}⁩ يتابع',
			'tc.observation.annonce.restant' => ({required Object secondes}) => '⁨${secondes}⁩ ث',
			'tc.observation.annonce.enfantIndicateur' => 'وليّ أمرك يشاهد الدرس',
			'tc.observation.annonce.tuteursObservent' => ({required Object nombre}) => '⁨${nombre}⁩ من أولياء الأمور يتابعون',
			'tc.observation.reglages.titre' => 'متابعة أولياء الأمور',
			'tc.observation.reglages.intro' => 'يمكن لوليّ الأمر مشاهدة درس طفله لوقت قصير، دون ميكروفون ولا كاميرا. يحدد هذا الإعداد ما ينطبق على هذا الفصل.',
			'tc.observation.reglages.heriter' => 'اتباع إعداد الأكاديمية',
			'tc.observation.reglages.personnaliser' => 'تخصيص لهذا الفصل',
			'tc.observation.reglages.desactiver' => 'تعطيل لهذا الفصل',
			'tc.observation.reglages.maxVisites' => 'الزيارات لكل حصة',
			'tc.observation.reglages.tempsTotal' => 'الوقت الكلي لكل حصة',
			'tc.observation.reglages.plafondVisite' => 'أقصى مدة للزيارة',
			'tc.observation.reglages.diminuer' => 'إنقاص',
			'tc.observation.reglages.augmenter' => 'زيادة',
			'tc.observation.reglages.enregistrer' => 'حفظ',
			'tc.observation.reglages.invalideVisites' => 'زيارة واحدة على الأقل لكل حصة.',
			'tc.observation.reglages.invalideTemps' => 'ثلاثون ثانية على الأقل لكل حصة.',
			'tc.observation.reglages.valeurHeritee' => ({required Object valeur}) => 'الأكاديمية: ⁨${valeur}⁩',
			'tc.observation.reglages.uniteVisiteUne' => ({required Object n}) => '⁨${n}⁩ زيارة',
			'tc.observation.reglages.uniteVisites' => ({required Object n}) => '⁨${n}⁩ زيارات',
			'tc.observation.reglages.uniteSecondes' => ({required Object n}) => '⁨${n}⁩ ث',
			'tc.observation.reglages.versionPolitique' => ({required Object version}) => 'الإصدار ⁨${version}⁩',
			'tc.parcours.avant.titre' => 'قبل الدرس القادم',
			'tc.parcours.avant.rien' => 'لا شيء للتحضير للدرس القادم.',
			'tc.parcours.avant.rienDetail' => 'سيقترح معلمك العمل في نهاية الحصة القادمة.',
			'tc.parcours.avant.nonBranche' => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.',
			'tc.parcours.avant.nonBrancheDetail' => 'هذا لا يعني أنه لا شيء للتحضير: هذه الشاشة لا تعرف قراءته بعد.',
			'tc.parcours.avant.reprendre' => 'استئناف الدرس',
			'tc.parcours.avant.reprendreDepuis' => ({required Object position}) => 'استئناف الدرس من ⁨${position}⁩',
			'tc.parcours.intention.apprendre' => 'للحفظ',
			'tc.parcours.intention.revoir' => 'للمراجعة',
			'tc.parcours.intention.renforcer' => 'للتثبيت',
			'tc.parcours.intention.entretenir' => 'للتعاهد',
			'tc.parcours.intention.evaluation' => 'للتقييم',
			'tc.parcours.plage.versets' => ({required Object sourate, required Object premier, required Object dernier}) => 'سورة ⁨${sourate}⁩، الآيات ⁨${premier}⁩ إلى ⁨${dernier}⁩',
			'tc.parcours.plage.versetUnique' => ({required Object sourate, required Object premier}) => 'سورة ⁨${sourate}⁩، الآية ⁨${premier}⁩',
			'tc.parcours.plage.versetsCroisee' => ({required Object sourateDebut, required Object versetDebut, required Object sourateFin, required Object versetFin}) => 'سورة ⁨${sourateDebut}⁩، الآية ⁨${versetDebut}⁩ إلى سورة ⁨${sourateFin}⁩، الآية ⁨${versetFin}⁩',
			'tc.parcours.plage.pages' => ({required Object premiere, required Object derniere}) => 'الصفحات ⁨${premiere}⁩ إلى ⁨${derniere}⁩',
			'tc.parcours.plage.pageUnique' => ({required Object premiere}) => 'الصفحة ⁨${premiere}⁩',
			'tc.parcours.plage.section' => ({required Object section}) => 'القسم ⁨${section}⁩',
			'tc.parcours.plage.ressource' => 'المادة كلها',
			'tc.parcours.feedback.cours.intitule' => 'كيف كان الدرس اليوم؟',
			'tc.parcours.feedback.cours.difficile' => 'صعب',
			'tc.parcours.feedback.cours.bien' => 'جيد',
			'tc.parcours.feedback.cours.tresBien' => 'جيد جدًا',
			'tc.parcours.feedback.comprehension.intitule' => 'هل فهمت ما تم العمل عليه؟',
			'tc.parcours.feedback.comprehension.difficile' => 'ليس تمامًا',
			'tc.parcours.feedback.comprehension.bien' => 'نعم، إلى حدٍّ ما',
			'tc.parcours.feedback.comprehension.tresBien' => 'تمامًا',
			'tc.parcours.feedback.rythme.intitule' => 'هل ناسبك إيقاع الدرس؟',
			'tc.parcours.feedback.rythme.difficile' => 'سريع جدًا',
			'tc.parcours.feedback.rythme.bien' => 'مناسب',
			'tc.parcours.feedback.rythme.tresBien' => 'مريح جدًا',
			'tc.parcours.feedback.technique.intitule' => 'هل كان الصوت والصورة مريحين؟',
			'tc.parcours.feedback.technique.difficile' => 'مزعجان',
			'tc.parcours.feedback.technique.bien' => 'مقبولان',
			'tc.parcours.feedback.technique.tresBien' => 'جيدان جدًا',
			'tc.parcours.feedback.confiance.intitule' => 'هل تشعر أنك مستعد للدرس القادم؟',
			'tc.parcours.feedback.confiance.difficile' => 'ليس بعد',
			'tc.parcours.feedback.confiance.bien' => 'إلى حدٍّ ما',
			'tc.parcours.feedback.confiance.tresBien' => 'تمامًا',
			'tc.parcours.feedback.merci' => 'شكرًا.',
			'tc.parcours.feedback.tendance.titre' => 'آراء الطلاب',
			'tc.parcours.feedback.tendance.sousSeuil' => 'لا تكفي الآراء بعد لاستخلاص اتجاه.',
			'tc.parcours.feedback.tendance.anonyme' => 'الآراء مجهولة الهوية ومجمَّعة. لا تكفي وحدها أبدًا لاتخاذ قرار.',
			'tc.parcours.signalement.titre' => 'الإبلاغ عن حاجة',
			'tc.parcours.signalement.categorie' => 'بماذا يتعلق الأمر؟',
			'tc.parcours.signalement.categorieValeur.pedagogique' => 'تعليمي',
			'tc.parcours.signalement.categorieValeur.presence' => 'الحضور',
			'tc.parcours.signalement.categorieValeur.technique' => 'تقني',
			'tc.parcours.signalement.categorieValeur.changement' => 'تغيير',
			'tc.parcours.signalement.categorieValeur.autre' => 'آخر',
			'tc.parcours.signalement.interne' => 'ملاحظة داخلية',
			'tc.parcours.signalement.interneAide' => 'تقرؤها الإدارة وحدها. لا تُرسل أبدًا تلقائيًا إلى الأسرة.',
			'tc.parcours.signalement.famille' => 'رسالة إلى الأسرة',
			'tc.parcours.signalement.familleAide' => 'اختيارية. الإدارة وحدها تقرر إرسالها بنقرة واحدة.',
			'tc.parcours.signalement.contexte' => ({required Object eleve}) => 'بخصوص ⁨${eleve}⁩. الحصة والفصل واسمك مرفقة بالفعل.',
			'tc.parcours.signalement.envoyer' => 'إرسال البلاغ',
			'tc.parcours.signalement.envoye' => 'أُرسل البلاغ إلى الإدارة.',
			'tc.parcours.signalement.interneRequis' => 'اكتب على الأقل ما يجب أن تعرفه الإدارة.',
			'tc.parcours.signalement.echec' => 'تعذّر إرسال البلاغ. أعد المحاولة.',
			'tc.parcours.postCours.titre' => 'بعد الدرس',
			'tc.parcours.postCours.duree' => ({required Object minutes}) => 'المدة الفعلية ⁨${minutes}⁩ دقيقة',
			'tc.parcours.postCours.exceptions' => 'للتأكيد',
			'tc.parcours.postCours.toutEstNominal' => 'لا شيء يتطلب انتباهك.',
			'tc.parcours.postCours.reprise' => 'الاستئناف المقترح',
			'tc.parcours.postCours.repriseInconnue' => 'لا موضع استئناف معروف لهذه الحصة.',
			'tc.parcours.postCours.travail' => 'العمل المقترح',
			'tc.parcours.postCours.travailAucun' => 'لا عمل مقترح حتى الآن.',
			'tc.parcours.postCours.valider' => 'تأكيد',
			'tc.parcours.postCours.enFile' => 'تم الحفظ. سيُرسل بمجرد عودة الشبكة.',
			'tc.parcours.postCours.envoye' => 'أُغلق الدرس.',
			'nav.eleve.accueil' => 'الرئيسية',
			'nav.eleve.maClasse' => 'فصلي',
			'nav.eleve.coran' => 'القرآن',
			'nav.eleve.monEspace' => 'مساحتي',
			'nav.eleve.suivi' => 'المتابعة',
			'nav.eleve.compte' => 'الحساب',
			'nav.tuteur.accueil' => 'الرئيسية',
			'nav.tuteur.foyer' => 'الأسرة',
			'nav.tuteur.disponibilites' => 'أوقات التوفر',
			'nav.tuteur.reglages' => 'الإعدادات',
			'nav.tuteur.suivi' => 'المتابعة',
			'nav.tuteur.historique' => 'السجل',
			'nav.tuteur.compte' => 'الحساب',
			'nav.enseignant.journee' => 'اليوم',
			'nav.enseignant.classes' => 'الفصول',
			'nav.enseignant.creneaux' => 'أوقات التوفر',
			'nav.enseignant.profil' => 'الملف الشخصي',
			'nav.controleur.planning' => 'الجدول',
			'nav.controleur.controle' => 'المراقبة',
			'nav.controleur.historique' => 'السجل',
			'nav.controleur.echanges' => 'المراسلات',
			'nav.controleur.compte' => 'الحساب',
			'nav.admin.tableauDeBord' => 'لوحة التحكم',
			'nav.admin.dossiers' => 'الملفات',
			'nav.admin.demandes' => 'الطلبات',
			'nav.admin.attribution' => 'الإسناد',
			'nav.admin.journal' => 'السجل',
			'nav.admin.comptes' => 'الحسابات',
			'nav.admin.accesAgents' => 'صلاحيات الموظفين',
			'nav.admin.accueil' => 'الرئيسية',
			'nav.admin.operations' => 'العمليات',
			'nav.admin.personnes' => 'الأشخاص',
			'nav.admin.pedagogie' => 'التعليم',
			'nav.admin.finance' => 'المالية',
			'nav.admin.configuration' => 'الإعدادات العامة',
			'nav.admin.securite' => 'الأمان والتدقيق',
			'nav.admin.direction' => 'الإدارة',
			'nav.admin.recherche' => 'البحث',
			'nav.admin.rechercheIndication' => 'البحث عن شاشة',
			'nav.admin.notificationsTitre' => 'الإشعارات',
			'nav.admin.menu' => 'القائمة',
			'nav.compte' => 'حسابي',
			'nav.principale' => 'التنقل الرئيسي',
			'nav.motSymbole' => 'Rewayah',
			'nav.replier' => 'طي شريط التنقل',
			'nav.deplier' => 'فتح شريط التنقل',
			'accessibilite.demo.titre' => 'عرض تجريبي لوضع إمكانية الوصول',
			'accessibilite.demo.mention' => 'بيانات وهمية، لا إرسال.',
			'accessibilite.demo.intro' => 'اختر طالبًا ولحظة من الحصة.',
			'accessibilite.demo.eleveMineure' => 'مريم، طالبة قاصر',
			'accessibilite.demo.eleveAdulte' => 'إدريس، طالب بالغ',
			'accessibilite.demo.etatAvant' => 'قبل الحصة',
			'accessibilite.demo.etatFenetre' => 'قبيل الحصة، الدخول مفتوح',
			'accessibilite.demo.etatPendant' => 'أثناء الحصة',
			'accessibilite.demo.etatApres' => 'بعد الحصة',
			'accessibilite.accueil.salutation' => ({required Object prenom}) => 'السلام عليكم، ⁨${prenom}⁩.',
			'accessibilite.accueil.prochaineSeance' => 'الحصة القادمة',
			'accessibilite.accueil.avec' => ({required Object nomme}) => 'مع ⁨${nomme}⁩',
			'accessibilite.accueil.voirMaClasse' => 'عرض فصلي',
			'accessibilite.accueil.lireCoran' => 'قراءة القرآن',
			'accessibilite.accueil.lireCoranDetail' => 'فتح المصحف',
			'accessibilite.accueil.aide' => 'تحتاج إلى مساعدة؟',
			'accessibilite.accueil.erreurTitre' => 'لم تُحمَّل الحصة القادمة',
			'accessibilite.accueil.erreurPhrase' => 'تعذّرت قراءة الحصة والعمل المطلوب، غالبًا بسبب الاتصال. يكفي أن تعيد المحاولة بعد لحظة.',
			'accessibilite.accueil.indisponibleTitre' => 'الحصة القادمة لا تظهر هنا بعد',
			'accessibilite.accueil.indisponiblePhrase' => 'الصفحة الرئيسية لا تستقبل حصة الفصل بعد. تجدها في «فصلي».',
			'accessibilite.accueil.videTitre' => 'لا فصل بعد',
			'accessibilite.accueil.videPhrase' => 'لم يُسند أي فصل بعد. يُختار الفصل مع الأكاديمية. وإلى ذلك الحين، يبقى القرآن والمساعدة متاحين أدناه.',
			'accessibilite.coran.ouvrir' => 'فتح القرآن',
			'accessibilite.coran.reprendre' => 'المتابعة من آخر صفحة',
			'accessibilite.coran.reprendreVous' => 'المتابعة من آخر صفحة',
			'accessibilite.coran.reprendreDetail' => ({required Object page}) => 'كنت في الصفحة ⁨${page}⁩.',
			'accessibilite.coran.reprendreDetailVous' => ({required Object page}) => 'كنت في الصفحة ⁨${page}⁩.',
			'accessibilite.coran.repriseRecherche' => 'جارٍ البحث عن آخر صفحة…',
			'accessibilite.coran.repriseRechercheVous' => 'جارٍ البحث عن آخر صفحة…',
			'accessibilite.coran.repriseErreur' => 'تعذّر العثور على آخر صفحة، غالبًا بسبب الاتصال. افتح القرآن واختر صفحتك في القارئ. إعدادات القراءة تبقى محفوظة.',
			'accessibilite.coran.repriseErreurVous' => 'تعذّر العثور على آخر صفحة، غالبًا بسبب الاتصال. افتح القرآن واختر صفحتك في القارئ. إعدادات القراءة تبقى محفوظة.',
			'accessibilite.coran.lectureGrande' => 'يُفتح القرآن في قراءة مكبَّرة، آية آية.',
			'accessibilite.coran.retour' => 'العودة إلى مدخل القرآن',
			'accessibilite.coran.demoSansTexte' => 'نص القرآن غير محمَّل في العرض التجريبي',
			'accessibilite.coran.demoSansTexteDetail' => 'ليس هذا عطلًا: العرض التجريبي لا يحتوي على النص. لا شيء عليك فعله. في التطبيق، يُفتح القرآن هنا على صفحتك، وتبقى إعدادات القراءة محفوظة.',
			'accessibilite.coran.demoSansTexteDetailVous' => 'ليس هذا عطلًا: العرض التجريبي لا يحتوي على النص. لا شيء عليك فعله. في التطبيق، يُفتح القرآن هنا على صفحتك، وتبقى إعدادات القراءة محفوظة.',
			'accessibilite.maClasse.titre' => 'فصلي',
			'accessibilite.maClasse.suivi' => 'متابعتي',
			'accessibilite.maClasse.suiviDetail' => 'الحصص الماضية والحضور',
			'accessibilite.tutoiement.tonHeure' => 'توقيتك',
			'accessibilite.tutoiement.attenteDetail' => 'وقت الانتظار هذا لا يُحتسب في حضورك.',
			'accessibilite.tutoiement.attente' => ({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ⁨${duree}⁩.',
			'accessibilite.tutoiement.attenteImminent' => 'أنت في القاعة. تبدأ الحصة بعد أقل من دقيقة.',
			'accessibilite.tutoiement.annonceAttente' => 'أنت في القاعة',
			'accessibilite.tutoiement.horsLigne' => 'أنت غير متصل. تحتاج الحصة إلى اتصال.',
			'accessibilite.tutoiement.finPhrase' => 'تجد عملك في فصلك.',
			'accessibilite.apres.revoirSupport' => 'مراجعة مادة الدرس',
			'accessibilite.apres.revoirSupportDetail' => 'تبقى المادة في فصلك.',
			'accessibilite.apres.revoirSupportDetailVous' => 'تبقى المادة في فصلك.',
			'accessibilite.monEspace.titre' => 'مساحتي',
			'accessibilite.monEspace.mode' => 'وضع إمكانية الوصول',
			'accessibilite.monEspace.modeDetail' => 'واجهة مبسطة ومكيَّفة لتعلم أكثر طمأنينة.',
			'accessibilite.monEspace.modeActif' => 'مفعَّل',
			'accessibilite.monEspace.presentationStandard' => 'العرض العادي',
			'accessibilite.monEspace.demanderDetail' => 'اطلب من وليّ أمرك الانتقال إلى العرض العادي.',
			'accessibilite.monEspace.demandeEnCours' => 'جارٍ إرسال طلبك.',
			'accessibilite.monEspace.demandeEnvoyee' => 'أُرسل طلبك إلى وليّ أمرك.',
			'accessibilite.monEspace.demandeNonConfirmee' => 'لم يُؤكَّد الإرسال، غالبًا بسبب الاتصال. تحقّق من اتصالك، ثم المس السطر لإعادة المحاولة. لم يتغير شيء في الأثناء: يبقى العرض كما هو.',
			'reseau.horsLigne' => 'لا شبكة. ما هو معروض يبقى قابلًا للاطلاع.',
			'reseau.enAttenteEnvoi' => 'سيُرسل بمجرد عودة الشبكة',
			'reseau.retabli' => 'عادت الشبكة',
			'reseau.syncImpossible' => 'تعذّرت المزامنة',
			'vide.aucunCours' => 'لا دروس اليوم',
			'vide.aucunCoursDetail' => 'سيظهر درسك القادم هنا.',
			'vide.aucunCreneau' => 'لا موعد متاح الآن',
			'vide.aucunRapport' => 'لا دفتر متابعة حتى الآن',
			'vide.aucunAppareil' => 'لا جهاز مقترن',
			'notifications.titre' => 'الإشعارات',
			'notifications.indisponibleTitre' => 'الإشعارات غير متاحة بعد',
			'notifications.indisponiblePhrase' => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية بمجرد فتحها.',
			'notifications.videTitre' => 'لا إشعارات',
			'notifications.videPhrase' => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية.',
			'notifications.ligne' => ({required Object titre, required Object date, required Object heure}) => '⁨${titre}⁩، في ⁨${date}⁩ الساعة ⁨${heure}⁩',
			'choix.autre' => 'أخرى',
			'choix.autreInvite' => 'حدّد',
			'choix.selectionMultiple' => 'يمكن اختيار عدة إجابات',
			'accuse.titre' => 'ما يجب معرفته قبل البدء',
			'accuse.compris' => 'فهمت',
			'aConstruire.titre' => 'شاشة قيد الإنشاء',
			'aConstruire.detail' => 'تأتي هذه الشاشة في المرحلة 3.',
			'destructif.irreversible' => 'لا يمكن التراجع عن هذا الإجراء.',
			'avatar.sansPhoto' => 'لا صورة بعد',
			'pin.titre' => 'أدخل رمزك',
			'pin.erreur' => 'هذا الرمز غير مطابق',
			'pin.effacer' => 'مسح',
			'enfant.titre' => 'إضافة ملف طالب',
			'enfant.aucun' => 'لا ملف طالب في الأسرة',
			'enfant.aucunDetail' => 'أضف أولًا ملف طالب من «الأسرة».',
			'reglagesEnfant.titre' => 'الإعدادات حسب ملف الطالب',
			'reglagesEnfant.intro' => 'تُضبط صورة كل طالب وكاميرته وواجهته في بطاقته، من «الأسرة». أما الطلبات إلى الإدارة فتبقى هنا.',
			'reglagesEnfant.renvoi' => 'الصورة والكاميرا والواجهة',
			'reglagesEnfant.renvoiLegende' => ({required Object prenom}) => 'في بطاقة ⁨${prenom}⁩',
			'galerie.titre' => 'معرض المكونات',
			'galerie.avertissement' => 'منصة اختبار للتطوير. غير موجودة في إصدارات الإنتاج.',
			'galerie.paires' => 'أزواج الألوان',
			'galerie.elevation' => 'الارتفاع والزوايا',
			'galerie.typographie' => 'سلالم الخطوط',
			'galerie.polices' => 'الخطوط',
			'galerie.composants' => 'المكونات المشتركة',
			'galerie.modeEnfant' => 'وضع إمكانية الوصول',
			'galerie.modeStandard' => 'الوضع العادي',
			'ficheEleve.titreRepli' => 'ملف الطالب',
			'ficheEleve.parametres' => 'إعدادات الطالب',
			'ficheEleve.appareilsGroupe' => 'الأجهزة',
			'ficheEleve.introuvable.titre' => 'لم يُعثر على ملف الطالب هذا',
			'ficheEleve.introuvable.phrase' => 'ليس من أسرتك، أو الرابط ناقص.',
			'ficheEleve.introuvable.retour' => 'العودة إلى الأسرة',
			'ficheEleve.lignes.informations' => 'المعلومات',
			'ficheEleve.lignes.informationsLegende' => 'الاسم والصورة',
			'ficheEleve.lignes.inscription' => 'المسار والتسجيل',
			'ficheEleve.lignes.inscriptionLegende' => 'الاستبيان والفصل',
			'ficheEleve.lignes.interface' => 'الواجهة',
			'ficheEleve.lignes.camera' => 'الكاميرا أثناء الدرس',
			'ficheEleve.lignes.cameraAutorisee' => 'مسموح بها',
			'ficheEleve.lignes.cameraNonAutorisee' => 'غير مسموح بها',
			'ficheEleve.lignes.acces' => 'الوصول إلى Rewayah',
			'ficheEleve.lignes.appareils' => ({required Object prenom}) => 'أجهزة ⁨${prenom}⁩',
			'ficheEleve.lignes.appareilsLegende' => 'ربط جهاز، عرض الأجهزة المربوطة، إزالة أحدها',
			'ficheEleve.informations.titre' => 'معلومات الطالب',
			'ficheEleve.informations.identite' => 'الهوية',
			'ficheEleve.informations.prenom' => 'الاسم',
			'ficheEleve.informations.identiteNote' => 'لا يُعدَّل الاسم من هذه الصفحة بعد.',
			'ficheEleve.informations.ageNote' => 'العمر وتاريخ الميلاد غير مسجلين في الملف بعد.',
			'ficheEleve.informations.photo' => 'الصورة',
			'ficheEleve.informations.photoLegende' => ({required Object prenom}) => 'صورة لوجه ⁨${prenom}⁩. ليست وثيقة هوية.',
			'ficheEleve.informations.photoAucune' => 'لا صورة بعد',
			'ficheEleve.informations.photoPresente' => 'الصورة محفوظة',
			'ficheEleve.informations.choisir' => 'اختيار صورة',
			'ficheEleve.informations.changer' => 'تغيير الصورة',
			'ficheEleve.informations.apercuTitre' => 'معاينة',
			'ficheEleve.informations.apercuPhrase' => 'تحقّق من الصورة قبل إرسالها.',
			'ficheEleve.informations.apercuIllisible' => 'لا تظهر المعاينة على هذا الجهاز. يمكن مع ذلك إرسال الصورة.',
			'ficheEleve.informations.envoyer' => 'إرسال هذه الصورة',
			'ficheEleve.informations.autre' => 'اختيار صورة أخرى',
			'ficheEleve.informations.annuler' => 'إلغاء',
			'ficheEleve.informations.etapeEnvoi' => 'إرسال الصورة، الخطوة 1 من 2',
			'ficheEleve.informations.etapeEnregistrement' => 'الحفظ في الملف، الخطوة 2 من 2',
			'ficheEleve.informations.succes' => 'حُفظت الصورة.',
			'ficheEleve.informations.tropLourde' => ({required Object taille}) => 'هذه الصورة تتجاوز ⁨${taille}⁩ م.ب. اختر صورة أخف.',
			'ficheEleve.informations.echecEnvoi' => 'تعذّر إرسال الصورة. لم يتغير شيء في الملف.',
			'ficheEleve.informations.echecEnregistrement' => 'أُرسلت الصورة، لكن تعذّر حفظها في الملف.',
			'ficheEleve.informations.reprendre' => 'إعادة المحاولة',
			'ficheEleve.informations.selectionEchec' => 'تعذّر فتح الصورة. تحقّق من إذن الوصول إلى صور الجهاز، ثم أعد المحاولة.',
			'ficheEleve.informations.horsLigne' => 'أنت غير متصل. يمكن إرسال الصورة عند عودة الاتصال.',
			'ficheEleve.inscription.titre' => 'المسار والتسجيل',
			'ficheEleve.inscription.intro' => ({required Object prenom}) => 'أين وصل ⁨${prenom}⁩: الاستبيان والفصل.',
			'ficheEleve.inscription.questionnaire' => 'الاستبيان',
			'ficheEleve.inscription.classe' => 'الفصل',
			'ficheEleve.inscription.lecture' => 'جارٍ القراءة',
			'ficheEleve.inscription.etatInconnu' => 'حالة الاستبيان لا تظهر بعد.',
			'ficheEleve.inscription.aRemplir' => 'للتعبئة',
			'ficheEleve.inscription.horaireAChoisir' => 'مُعبّأ، الموعد للاختيار',
			'ficheEleve.inscription.horaireRetire' => 'سُحب الموعد، يجب اختياره من جديد',
			'ficheEleve.inscription.echangeAPrevoir' => 'التفضيل محفوظ، لقاء تحديد المستوى للبرمجة',
			'ficheEleve.inscription.echangePrevu' => 'لقاء تحديد المستوى مبرمج',
			'ficheEleve.inscription.classeEnConstitution' => 'الفصل قيد التكوين',
			'ficheEleve.inscription.classeConfirmee' => 'الفصل مؤكَّد',
			'ficheEleve.inscription.classeAucune' => 'لا فصل بعد. اختيار فصل',
			'ficheEleve.inscription.classeIndisponible' => 'الفصل لا يظهر هنا بعد. اختيار فصل',
			'ficheEleve.inscription.classeEchec' => 'تعذّرت قراءة الفصل.',
			'ficheEleve.inscription.relireClasse' => 'إعادة قراءة الفصل',
			'ficheEleve.interface.titre' => 'الواجهة',
			'ficheEleve.interface.intro' => ({required Object prenom}) => 'اختر كيف يظهر Rewayah على جهاز ⁨${prenom}⁩. يمكنك تغيير هذا الاختيار في أي وقت.',
			'ficheEleve.interface.guidee' => 'وضع إمكانية الوصول',
			'ficheEleve.interface.guideeDescription' => ({required Object prenom}) => 'حين يفضّل ⁨${prenom}⁩ شاشات خفيفة: نصوص أكبر، وإجراء واحد في كل مرة. الأقسام نفسها والصلاحيات نفسها.',
			'ficheEleve.interface.standard' => 'العرض العادي',
			'ficheEleve.interface.standardDescription' => ({required Object prenom}) => 'حين يرتاح ⁨${prenom}⁩ لشاشات أكثف: معلومات أكثر في كل شاشة. الأقسام نفسها والصلاحيات نفسها.',
			'ficheEleve.interface.politique' => 'أنت من يختار هذا الإعداد. لا يُطلب أي سبب، ولا يرى المعلم إلا اسم الوضع.',
			'ficheEleve.interface.application' => ({required Object prenom}) => 'يُطبَّق التغيير عند الفتح التالي لـRewayah على جهاز ⁨${prenom}⁩.',
			'ficheEleve.interface.demandeEleve' => 'طلب التغيير من الطالب نفسه غير متاح بعد.',
			'ficheEleve.interface.enCours' => 'جارٍ الحفظ',
			'ficheEleve.interface.echec' => ({required Object prenom}) => 'لم يُحفظ التغيير، غالبًا بسبب انقطاع الاتصال بـRewayah. تحقّق من اتصالك، ثم المس اختيارك من جديد. يبقى العرض الحالي لـ⁨${prenom}⁩ كما هو على جهازه.',
			'ficheEleve.interface.horsLigne' => 'أنت غير متصل. يمكن تغيير العرض عند عودة الاتصال.',
			'ficheEleve.camera.titre' => 'الكاميرا أثناء الدرس',
			'ficheEleve.camera.ligne' => 'الكاميرا أثناء الحصص',
			'ficheEleve.camera.autorisee' => ({required Object prenom}) => 'يمكن لـ⁨${prenom}⁩ تشغيل كاميرته أثناء الحصص.',
			'ficheEleve.camera.interdite' => ({required Object prenom}) => 'لن يظهر زر الكاميرا لـ⁨${prenom}⁩ أثناء الحصص.',
			'ficheEleve.camera.application' => ({required Object prenom}) => 'يُحتسب التغيير عند الدخول التالي لـ⁨${prenom}⁩ إلى حصة.',
			'ficheEleve.camera.distincte' => 'هذا الإعداد لا يغيّر إذن الكاميرا في الجهاز، الذي يطلبه الهاتف لقراءة رمز QR.',
			'ficheEleve.camera.echec' => 'لم يُحفظ التغيير. أعد المحاولة.',
			'ficheEleve.camera.horsLigne' => 'أنت غير متصل. يمكن ضبط الكاميرا عند عودة الاتصال.',
			'ficheEleve.acces.titre' => 'الوصول إلى Rewayah',
			'ficheEleve.acces.ligne' => ({required Object prenom}) => 'وصول ⁨${prenom}⁩',
			'ficheEleve.acces.pastilleSansEcheance' => 'دون موعد انتهاء',
			'ficheEleve.acces.pastilleEnCours' => 'ساري',
			'ficheEleve.acces.pastilleExpire' => 'منتهٍ',
			'ficheEleve.acces.sansEcheance' => 'لا تاريخ انتهاء مسجَّل.',
			'ficheEleve.acces.jusquau' => ({required Object date}) => 'حتى ⁨${date}⁩',
			'ficheEleve.acces.expireDepuis' => ({required Object date}) => 'منتهٍ منذ ⁨${date}⁩',
			'ficheEleve.acces.expirePhrase' => ({required Object prenom}) => 'منذ هذا التاريخ، لا يستطيع ⁨${prenom}⁩ الدخول إلى Rewayah.',
			'ficheEleve.acces.detailIndisponible' => 'بداية الوصول وسببه لا يظهران بعد.',
			'parcours.titre' => ({required Object prenom}) => 'مسار ⁨${prenom}⁩',
			'parcours.intro' => 'بعض الأسئلة لتخصيص مسارك. لن ترى بعدها إلا المواعيد والخيارات المناسبة لوضعك.',
			'parcours.reprendre' => 'استئناف',
			'parcours.commencer' => 'تخصيص المسار',
			'parcours.modifier' => 'تعديل إجاباتي',
			'parcours.erreur' => 'تعذّر حفظ هذه الإجابة. أعد المحاولة.',
			'parcours.chargement' => 'نحضّر خياراتك.',
			'parcours.pourPrenom' => ({required Object prenom}) => 'لـ⁨${prenom}⁩',
			'parcours.retourAccueil' => 'العودة إلى الرئيسية',
			'parcours.retourFoyer' => 'العودة إلى الأسرة',
			'parcours.reessayer' => 'إعادة المحاولة',
			'parcours.indisponibleTitre' => 'الاستبيان غير متاح بعد',
			'parcours.indisponibleDetail' => 'لم تفتح الأكاديمية هذه الخطوة بعد. لا شيء عليك فعله الآن: لم يضِع شيء، ويمكنك تعبئتها بمجرد فتحها.',
			'parcours.horsLigneTitre' => 'لا اتصال',
			'parcours.horsLigneDetail' => 'تحقّق من اتصالك، ثم أعد المحاولة. إجاباتك محفوظة.',
			'parcours.erreurChargement' => 'تعذّر عرض الاستبيان',
			'parcours.erreurChargementDetail' => 'حدث خطأ من جهتنا. أعد المحاولة بعد لحظة؛ إجاباتك محفوظة.',
			'parcours.introuvableTitre' => 'لم يُعثر على ملف الطالب هذا',
			'parcours.introuvableDetail' => 'ربما أُزيل من الأسرة. عد إلى «الأسرة» لاختيار ملف طالب.',
			'parcours.finTitre' => ({required Object prenom}) => 'حُفظ التفضيل لـ⁨${prenom}⁩',
			'parcours.finDetail' => 'سُجِّل هذا الموعد كتفضيل لك. لا يحجز مقعدًا بعد.',
			'parcours.finAjouterDetail' => 'هل يرغب شخص آخر من الأسرة في التعلم؟',
			'parcours.finAjouterProfil' => 'إضافة ملف طالب',
			'parcours.ageQuestion' => ({required Object prenom}) => 'كم عمر ⁨${prenom}⁩؟',
			'parcours.ageRaison' => 'العمر يحدد مدة الحصص وعدد الطلاب في الفصل. لا نطلب تاريخ الميلاد: تكفي الفئة العمرية.',
			'parcours.langueQuestion' => 'بأي لغة يُقدَّم الدرس؟',
			'parcours.langueRaison' => 'هي اللغة التي سيتكلمها المعلم أثناء الحصة. وهي مستقلة عن لغة التطبيق، التي يمكنك تغييرها في أي وقت من إعداداتك.',
			'parcours.lieuQuestion' => 'أين تقيم؟',
			'parcours.lieuRaison' => 'نستخدمها فقط لنعرض لك المواعيد بتوقيتك المحلي. لا نطلب أبدًا موقعك الدقيق، ولا تغادر هذه الإجابة ملفك.',
			'parcours.lieuSuggere' => 'مقترح حسب توقيت جهازك',
			'parcours.niveauQuestion' => ({required Object prenom}) => 'أين وصل ⁨${prenom}⁩ اليوم؟',
			'parcours.niveauRaison' => 'إجابتك توجّه المقترحات الأولى. لا تحدد المستوى الرسمي: تحدده الأكاديمية بعد لقاء مع معلم.',
			'parcours.niveauDebutLettres' => 'نبدأ بالحروف',
			'parcours.niveauLettresAvecAide' => 'الحروف معروفة، والقراءة تحتاج إلى مساعدة',
			'parcours.niveauLectureLente' => 'القراءة ممكنة، ببطء',
			'parcours.niveauLectureCourante' => 'يقرأ القرآن بطلاقة',
			'parcours.niveauMemorisationPartielle' => 'حفظ بعضه',
			'parcours.objectifQuestion' => 'ماذا تريد أولًا؟',
			'parcours.objectifRaison' => 'يمكنك تغيير الهدف لاحقًا: هو يوجّه عمل المعلم، ولا يُلزمك.',
			'parcours.objectifApprendreALire' => 'تعلّم القراءة',
			'parcours.objectifDevenirFluide' => 'القراءة بطلاقة أكبر',
			'parcours.objectifMemoriser' => 'الحفظ',
			'parcours.objectifIndecis' => 'لا أعرف بعد',
			'parcours.momentsQuestion' => 'أي أوقات اليوم تناسبك أكثر؟',
			'parcours.momentsRaison' => 'هذه الإجابة لا تنشئ أي موعد ولا تحجز شيئًا. تفيد فقط في إبراز المواعيد الأنسب لك من بين التي تقترحها الأكاديمية. سترى كل المواعيد الأخرى أدناه.',
			'parcours.momentMatin' => 'الصباح',
			'parcours.momentApresMidi' => 'بعد الظهر',
			'parcours.momentSoir' => 'المساء',
			'parcours.offresQuestion' => ({required Object prenom}) => 'هذه المواعيد المفتوحة لـ⁨${prenom}⁩',
			'parcours.offresRaison' => 'تُعرض هذه المواعيد بتوقيتك المحلي. اختيار موعد يحفظ تفضيلك: لا يحجز مقعدًا ولا يكوّن فصلًا بعد.',
			'parcours.offreRecommandee' => 'الأقرب إلى إجاباتك',
			'parcours.offresAutres' => 'مواعيد ممكنة أخرى',
			'parcours.offreRecurrence' => ({required Object seances, required Object duree}) => '⁨${seances}⁩ حصص في الأسبوع، ⁨${duree}⁩ دقيقة',
			'parcours.offreRecurrencePause' => ({required Object seances, required Object duree, required Object pause}) => '⁨${seances}⁩ حصص في الأسبوع، ⁨${duree}⁩ دقيقة منها ⁨${pause}⁩ دقيقة استراحة',
			'parcours.offreLangue' => ({required Object langue}) => 'الدرس بـ⁨${langue}⁩',
			'parcours.offreFuseau' => ({required Object fuseau}) => 'التوقيت المعروض لـ⁨${fuseau}⁩',
			'parcours.offreTraduite' => 'معروض بتوقيتك المحلي',
			'parcours.offreJours' => ({required Object jours}) => '⁨${jours}⁩',
			'parcours.offreChoisir' => 'اختيار هذا الموعد',
			'parcours.offreChoisie' => 'الموعد المختار',
			'parcours.aucuneOffre' => 'لا موعد مفتوح يناسب بعد',
			'parcours.aucuneOffreDetail' => 'تفتح الأكاديمية مواعيد جديدة مع توالي التسجيلات. يمكنك إبلاغنا بحاجتك: هذا يساعدنا على تحديد ما نفتحه.',
			'parcours.refusAucun' => 'لا يناسبني أي من هذه المواعيد',
			'parcours.refusPrevenir' => 'إعلامي إن فُتحت مواعيد جديدة',
			'parcours.refusEffet' => 'نسجّل أن الطلب موجود. هذا لا ينشئ فصلًا، ولا يبحث عن معلم، ولا يعد بأي موعد مستقبلي.',
			'parcours.refusEnregistre' => 'تم التسجيل. سنعلمك إن فُتح موعد مناسب.',
			'parcours.etatAPersonnaliser' => 'مسار للتخصيص',
			'parcours.etatAPersonnaliserDetail' => ({required Object prenom}) => 'بعض الأسئلة، ولن نعرض لك إلا ما يناسب ⁨${prenom}⁩.',
			'parcours.etatHoraireAChoisir' => 'موعد للاختيار',
			'parcours.etatHoraireAChoisirDetail' => ({required Object prenom}) => 'المواعيد المفتوحة لـ⁨${prenom}⁩ بانتظارك.',
			'parcours.etatOffreIndisponible' => 'هذا الموعد لم يعد مقترحًا',
			'parcours.etatOffreIndisponibleDetail' => ({required Object prenom}) => 'سُحب الموعد المختار لـ⁨${prenom}⁩ قبل تكوين فصل. اختر موعدًا آخر: لم يضِع شيء.',
			'parcours.etatDiagnosticRequis' => 'التفضيل محفوظ',
			'parcours.etatDiagnosticRequisDetail' => ({required Object prenom}) => 'بقي لقاء مع معلم لتحديد مستوى ⁨${prenom}⁩. ستقترح عليك الأكاديمية موعدًا.',
			'parcours.etatDiagnosticEnAttente' => 'الموعد مبرمج',
			'parcours.etatDiagnosticEnAttenteDetail' => ({required Object prenom}) => 'لقاء مبرمج لتحديد مستوى ⁨${prenom}⁩.',
			_ => null,
		} ?? switch (path) {
			'parcours.etatClasseEnFormation' => 'الفصل قيد التكوين',
			'parcours.etatClasseEnFormationDetail' => ({required Object minimum}) => 'يبدأ الفصل ابتداءً من ⁨${minimum}⁩ طلاب. سنعلمك بمجرد تأكيده.',
			'parcours.etatClasseEnFormationDetailSansMinimum' => 'يبدأ الفصل ابتداءً من عدد معين من الطلاب. سنعلمك بمجرد تأكيده.',
			'parcours.etatClasseConfirmee' => 'الفصل مؤكَّد',
			'parcours.etatClasseConfirmeeDetail' => ({required Object prenom}) => 'تكوّن فصل ⁨${prenom}⁩. ستجد حصصه في مساحته.',
			'parcours.fuseauChange' => 'تغيّر مكانك منذ هذا الاختيار',
			'parcours.fuseauChangeDetail' => 'الموعد نفسه عند الأكاديمية، لكنه لم يعد يقع في الساعة نفسها عندك. تحقّق من أنه ما زال يناسبك.',
			'parcours.voirHoraires' => 'عرض المواعيد',
			'parcours.changerHoraire' => 'تغيير الموعد',
			'parcours.renoncerMotif' => 'غيّرت الأسرة موعدها بعد اختيار المسار',
			'eleveConnexion.entrerCode' => 'لدي رمز',
			'eleveConnexion.scanner' => 'مسح المربع',
			'eleveConnexion.choisirProfil' => 'من أنت؟',
			'eleveConnexion.profils.phrase' => 'المس اسمك للمتابعة.',
			'eleveConnexion.profils.ajouter' => 'إضافة ملف على هذا الجهاز',
			'eleveConnexion.profils.ajouterLegende' => 'بالرمز الذي يعرضه وليّ الأمر',
			'eleveConnexion.profils.profilLibelle' => ({required Object prenom}) => 'المتابعة باسم ⁨${prenom}⁩',
			'eleveConnexion.profils.videTitre' => 'لا ملف على هذا الجهاز',
			'eleveConnexion.profils.vide' => 'لاستخدام هذا الجهاز، يجب أن يعرض وليّ الأمر رمزًا جديدًا على جهازه.',
			'eleveConnexion.profils.videAction' => 'إدخال رمز',
			'eleveConnexion.profils.retire' => ({required Object prenom}) => 'أُزيل هذا الجهاز لـ⁨${prenom}⁩. اطلب من وليّ الأمر إعادة ربطه برمز جديد.',
			'eleveConnexion.profils.jetonAbsent' => ({required Object prenom}) => 'لم يعد هذا الجهاز يجد اتصال ⁨${prenom}⁩. اطلب من وليّ الأمر عرض رمز جديد، ثم أدخله هنا.',
			'eleveConnexion.pin.bonjour' => ({required Object prenom}) => 'مرحبًا ⁨${prenom}⁩',
			'eleveConnexion.pin.creer' => 'اختر رمزك الشخصي',
			'eleveConnexion.pin.creerPhrase' => 'أربعة أرقام، لك وحدك. يبقى على هذا الجهاز.',
			'eleveConnexion.pin.confirmer' => 'أدخله مرة أخرى',
			'eleveConnexion.pin.different' => 'الرمزان غير متطابقين. اختر رمزك من جديد.',
			'eleveConnexion.pin.ouverture' => 'جارٍ الاتصال',
			'eleveConnexion.pin.horsLigne' => 'لا اتصال بالإنترنت. رمزك صحيح: أعد المحاولة عند عودة الإنترنت.',
			'eleveConnexion.pin.tropDEssais' => 'محاولات كثيرة. انتظر قليلًا قبل إعادة المحاولة.',
			'eleveConnexion.pin.echec' => 'لم يكتمل الاتصال. أعد المحاولة بعد لحظة.',
			'eleveConnexion.pin.changerProfil' => 'تغيير الملف',
			'eleveConnexion.pin.oublie' => 'نسيت الرمز؟',
			'eleveConnexion.pin.oubliePhrase' => 'اطلب من وليّ الأمر عرض رمز جديد على جهازه، ثم أدخله هنا. ستختار حينها رمزًا شخصيًا جديدًا.',
			'eleveConnexion.pin.oublieAction' => 'إدخال رمز جديد',
			'eleveConnexion.saisie.titre' => 'ربط هذا الجهاز',
			'eleveConnexion.saisie.phrase' => 'أدخل الرمز المكوَّن من ستة أحرف المعروض تحت رمز QR، على جهاز وليّ الأمر.',
			'eleveConnexion.saisie.champ' => 'الرمز',
			'eleveConnexion.saisie.aide' => 'أرقام من 2 إلى 9 وحروف لاتينية، دون I ولا O.',
			'eleveConnexion.saisie.valider' => 'ربط الجهاز',
			'eleveConnexion.saisie.scanner' => 'مسح رمز QR',
			'eleveConnexion.saisie.horsLigne' => 'لا اتصال بالإنترنت. يمكن التحقق من الرمز عند عودة الشبكة.',
			'eleveConnexion.lecteur.titre' => 'مسح رمز QR',
			'eleveConnexion.lecteur.consigne' => 'وجّه الكاميرا نحو رمز QR المعروض على جهاز وليّ الأمر.',
			'eleveConnexion.lecteur.demarrage' => 'اسمح بالكاميرا إن طلب الجهاز ذلك.',
			'eleveConnexion.lecteur.libelleApercu' => 'عرض الكاميرا',
			'eleveConnexion.lecteur.contenuInvalide' => 'رمز QR هذا ليس رمز ربط من Rewayah. وجّه الكاميرا نحو الرمز الذي يعرضه وليّ الأمر.',
			'eleveConnexion.lecteur.saisir' => 'إدخال الرمز',
			'eleveConnexion.lecteur.scannerANouveau' => 'المسح من جديد',
			'eleveConnexion.lecteur.verificationTitre' => 'جارٍ التحقق من الرمز',
			'eleveConnexion.lecteur.verificationPhrase' => 'الكاميرا متوقفة أثناء التحقق.',
			'eleveConnexion.lecteur.refuseeTitre' => 'الكاميرا غير مسموح بها',
			'eleveConnexion.lecteur.refuseePhrase' => 'لقراءة رمز QR، اسمح بالكاميرا. يمكنك أيضًا إدخال الرمز المعروض تحت رمز QR.',
			'eleveConnexion.lecteur.refuseeAction' => 'السماح بالكاميرا',
			'eleveConnexion.lecteur.refuseeDurablementTitre' => 'الكاميرا محظورة',
			'eleveConnexion.lecteur.refuseeDurablementPhrase' => 'ما زالت الكاميرا مرفوضة لـRewayah. اسمح بها في إعدادات الجهاز أو المتصفح، أو أدخل الرمز.',
			'eleveConnexion.lecteur.occupeeTitre' => 'الكاميرا مشغولة',
			'eleveConnexion.lecteur.occupeePhrase' => 'تطبيق آخر يستخدم الكاميرا. أغلقه ثم أعد المحاولة، أو أدخل الرمز.',
			'eleveConnexion.lecteur.absenteTitre' => 'لا كاميرا',
			'eleveConnexion.lecteur.absentePhrase' => 'لا كاميرا متاحة على هذا الجهاز. أدخل الرمز المعروض تحت رمز QR.',
			'eleveConnexion.lecteur.nonSupporteeTitre' => 'القراءة غير ممكنة هنا',
			'eleveConnexion.lecteur.nonSupporteePhrase' => 'هذا الجهاز أو المتصفح لا يقرأ رموز QR. أدخل الرمز المعروض تحت رمز QR.',
			'eleveConnexion.lecteur.erreurTitre' => 'لم تبدأ الكاميرا',
			'eleveConnexion.lecteur.erreurPhrase' => 'أعد المحاولة، أو أدخل الرمز المعروض تحت رمز QR.',
			'eleveConnexion.refus.format' => 'الرمز ستة أحرف: أرقام من 2 إلى 9 وحروف لاتينية، دون I ولا O.',
			'eleveConnexion.refus.inconnuTitre' => 'رمز غير معروف',
			'eleveConnexion.refus.inconnu' => 'هذا الرمز غير موجود، أو حلّ محله رمز أحدث. تحقّق منه، أو اعرض رمزًا جديدًا على جهاز وليّ الأمر.',
			'eleveConnexion.refus.expireTitre' => 'رمز منتهي الصلاحية',
			'eleveConnexion.refus.expire' => 'هذا الرمز لم يعد صالحًا. اعرض رمزًا جديدًا على جهاز وليّ الأمر.',
			'eleveConnexion.refus.dejaUtiliseTitre' => 'رمز مستخدَم',
			'eleveConnexion.refus.dejaUtilise' => 'استُخدم هذا الرمز لربط جهاز من قبل. اعرض رمزًا جديدًا على جهاز وليّ الأمر.',
			'eleveConnexion.refus.revoqueTitre' => 'جهاز مُزال',
			'eleveConnexion.refus.revoque' => 'أزال وليّ الأمر هذا الجهاز. اطلب منه عرض رمز جديد.',
			'eleveConnexion.refus.plafondTitre' => 'بلغت حد الأجهزة',
			'eleveConnexion.refus.plafond' => 'بلغ ملف الطالب هذا عدد الأجهزة المسموح به. يمكن لوليّ الأمر إزالة أحدها من «الأسرة»، ثم عرض رمز جديد.',
			'eleveConnexion.refus.tropDEssaisTitre' => 'محاولات كثيرة',
			'eleveConnexion.refus.tropDEssais' => 'انتظر قليلًا قبل إعادة المحاولة.',
			'eleveConnexion.refus.horsLigneTitre' => 'لا اتصال',
			'eleveConnexion.refus.horsLigne' => 'تعذّر التحقق من الرمز. تحقّق من الاتصال بالإنترنت، ثم أعد المحاولة.',
			'eleveConnexion.refus.nonEnregistreTitre' => 'لم يُحفظ الربط',
			'eleveConnexion.refus.nonEnregistre' => 'لم يستطع هذا الجهاز الاحتفاظ بالربط. ربما استُخدم الرمز من قبل: اعرض رمزًا جديدًا على جهاز وليّ الأمر، ثم ابدأ من جديد.',
			'eleveConnexion.refus.generiqueTitre' => 'لم يكتمل الربط',
			'eleveConnexion.refus.generique' => 'لم يكتمل التحقق من الرمز. أعد المحاولة بعد لحظة.',
			'presence.titre' => 'الحضور',
			'presence.voir' => 'عرض الحضور',
			'presence.mienne' => 'حضورك',
			'presence.consolide' => 'مُوحَّد',
			'presence.planifiee' => 'درس قادم',
			'presence.enAttente' => 'لم يصل بعد',
			'presence.enConnexion' => 'جارٍ الاتصال',
			'presence.presente' => 'في القاعة',
			'presence.enRetard' => 'متأخر',
			'presence.deconnectee' => 'انقطع الاتصال',
			'presence.enReconnexion' => 'جارٍ إعادة الاتصال',
			'presence.reconnectee' => 'عاد',
			'presence.sortie' => 'غادر الدرس',
			'presence.absente' => 'غياب',
			'presence.excusee' => 'غياب بعذر',
			'presence.confirmationEnAttente' => 'للتأكيد',
			'presence.corrigeeManuel' => 'تصحيح يدوي',
			'presence.finalisee' => 'نهائي',
			'presence.inconnu' => 'حالة غير معروفة',
			'presence.entreeInstant' => 'دخل القاعة للتو',
			'presence.entreeMinutes' => ({required Object minutes}) => 'في القاعة منذ ⁨${minutes}⁩ دقيقة',
			'presence.retardMinutes' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة بعد الموعد',
			'presence.silenceInstant' => 'لا أخبار منذ بضع ثوانٍ',
			'presence.silenceMinutes' => ({required Object minutes}) => 'لا أخبار منذ ⁨${minutes}⁩ دقيقة',
			'presence.attenteInstant' => 'بدأ الدرس للتو',
			'presence.attenteMinutes' => ({required Object minutes}) => 'بدأ الدرس منذ ⁨${minutes}⁩ دقيقة',
			'priere.fajr' => 'الفجر',
			'priere.dhuhr' => 'الظهر',
			'priere.asr' => 'العصر',
			'priere.maghrib' => 'المغرب',
			'priere.isha' => 'العشاء',
			'priere.entree' => ({required Object priere, required Object minutes}) => '⁨${priere}⁩، ⁨${minutes}⁩ دقيقة',
			'priere.annonce' => ({required Object priere, required Object heure}) => 'سيتوقف هذا الدرس لصلاة ⁨${priere}⁩، نحو ⁨${heure}⁩.',
			'priere.annonceAucune' => 'لا توقف مقرر أثناء هذا الدرس.',
			'priere.alerte' => ({required Object priere, required Object minutes}) => '⁨${priere}⁩ بعد ⁨${minutes}⁩ دقيقة',
			'priere.alerteMaintenant' => ({required Object priere, required Object heure}) => 'استراحة لصلاة ⁨${priere}⁩، الاستئناف الساعة ⁨${heure}⁩',
			'priere.pause' => 'استراحة',
			'priere.lieu' => ({required Object lieu}) => 'أوقات محسوبة لـ⁨${lieu}⁩',
			'priere.lieuSansNom' => 'أوقات محسوبة لمكان المعلم',
			'priere.ajustee' => ({required Object priere, required Object minutes}) => 'عدّل المعلم ⁨${priere}⁩ بـ⁨${minutes}⁩ دقيقة',
			'priere.reglagesAbsents' => 'لم يضبط المعلم أوقات الصلاة بعد.',
			'tuteur.accueil.titre' => 'الرئيسية',
			'tuteur.accueil.voirLaClasse' => 'عرض الفصل',
			'tuteur.accueil.prochaineSeance' => 'الحصة القادمة',
			'tuteur.accueil.heureDe' => ({required Object ville}) => 'توقيت ⁨${ville}⁩',
			'tuteur.accueil.heureAppareil' => 'توقيت هذا الجهاز',
			'tuteur.accueil.dateEtFuseau' => ({required Object date, required Object fuseau}) => '⁨${date}⁩ · ⁨${fuseau}⁩',
			'tuteur.accueil.heureClasse' => ({required Object heure, required Object ville}) => 'توقيت الفصل: ⁨${heure}⁩ ⁨${ville}⁩',
			'tuteur.accueil.seanceEnDirect' => 'حصة مباشرة',
			'tuteur.accueil.seanceTerminee' => 'انتهت الحصة',
			'tuteur.accueil.seanceAnnulee' => 'لن تُعقد هذه الحصة.',
			'tuteur.accueil.seanceNonTenue' => 'تعذّر عقد هذه الحصة.',
			'tuteur.accueil.horaireIncertain' => 'فتح القاعة غير مؤكَّد الآن',
			'tuteur.accueil.pastilleAnnulee' => 'ملغاة',
			'tuteur.accueil.pastilleNonTenue' => 'لم تُعقد',
			'tuteur.accueil.pastilleTerminee' => 'منتهية',
			'tuteur.accueil.aucuneSeance' => 'لا حصة مقررة',
			'tuteur.accueil.aucuneSeanceDetail' => ({required Object prenom}) => 'ستظهر هنا الحصة القادمة لـ⁨${prenom}⁩ بمجرد جدولتها.',
			'tuteur.accueil.seanceIllisible' => 'تعذّرت قراءة الحصة القادمة.',
			'tuteur.accueil.classeIndisponible' => 'تفاصيل الفصل غير متاحة هنا بعد.',
			'tuteur.accueil.classeIllisible' => 'تعذّرت قراءة الفصل.',
			'tuteur.accueil.sansClasseTitre' => ({required Object prenom}) => 'لا فصل لـ⁨${prenom}⁩',
			'tuteur.accueil.sansClassePhrase' => ({required Object prenom}) => 'اختر فصلًا ليتمكن ⁨${prenom}⁩ من بدء الدروس.',
			'tuteur.accueil.foyerVideTitre' => 'لا ملف طالب حتى الآن',
			'tuteur.accueil.foyerVidePhrase' => 'أضف ملف طالب لاختيار فصل ومتابعة حصصه.',
			'tuteur.accueil.ajouterProfil' => 'إضافة ملف طالب',
			'tuteur.accueil.profilsIllisibles' => 'تعذّرت قراءة ملفات الأسرة.',
			'tuteur.accueil.blocageAppareilTitre' => ({required Object prenom}) => 'لا جهاز جاهز لـ⁨${prenom}⁩',
			'tuteur.accueil.blocageAppareilPhrase' => ({required Object prenom}) => 'دون جهاز مربوط، لن يستطيع ⁨${prenom}⁩ دخول الفصل.',
			'tuteur.accueil.connecterAppareil' => 'ربط جهاز',
			'tuteur.accueil.avantProchainCours' => 'قبل الدرس القادم',
			'tuteur.accueil.voirTout' => 'عرض الكل',
			'tuteur.accueil.travailIndisponible' => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.',
			'tuteur.accueil.travailIllisible' => 'تعذّرت قراءة العمل المطلوب تحضيره.',
			'tuteur.accueil.rienAPreparer' => 'لا شيء للتحضير الآن',
			'tuteur.accueil.derniereSeance' => 'آخر حصة',
			'tuteur.accueil.voirHistorique' => 'عرض السجل',
			'tuteur.accueil.detailsSeance' => 'تفاصيل الحصة',
			'tuteur.accueil.aucuneDerniere' => 'لا حصة ماضية حتى الآن',
			'tuteur.accueil.derniereIllisible' => 'تعذّرت قراءة آخر حصة.',
			'tuteur.accueil.dateEtDuree' => ({required Object date, required Object duree}) => '⁨${date}⁩ · ⁨${duree}⁩',
			'tuteur.accueil.etatCourt.enDirect' => 'مباشر',
			'tuteur.accueil.etatCourt.salleOuverte' => 'القاعة مفتوحة',
			'tuteur.accueil.etatCourt.dansMinutes' => ({required Object minutes}) => 'بعد ⁨${minutes}⁩ دقيقة',
			'tuteur.accueil.etatCourt.dansHeures' => ({required Object heures, required Object minutes}) => 'بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'tuteur.accueil.etatCourt.dansJours' => ({required Object jours}) => 'بعد ⁨${jours}⁩ ي',
			'tuteur.accueil.etatCourt.prevue' => 'حصة مقررة',
			'tuteur.accueil.etatCourt.annulee' => 'حصة ملغاة',
			'tuteur.accueil.etatCourt.nonTenue' => 'حصة لم تُعقد',
			'tuteur.accueil.etatCourt.terminee' => 'حصة منتهية',
			'tuteur.accueil.etatCourt.aucune' => 'لا حصة',
			'tuteur.accueil.etatCourt.illisible' => 'غير متاح',
			'tuteur.accueil.assister' => 'الحضور',
			'tuteur.accueil.assisterRefuse' => 'تعذّر الانضمام إلى الدرس. ربما انتهى للتو.',
			'tuteur.accueil.enCours' => ({required Object prenom}) => 'جارٍ مع ⁨${prenom}⁩',
			'tuteur.accueil.depuisMinutes' => ({required Object minutes}) => 'بدأ منذ ⁨${minutes}⁩ دقيقة',
			'tuteur.accueil.depuisInstant' => 'بدأ للتو',
			'tuteur.accueil.aujourdhui' => ({required Object heure, required Object prenom}) => 'اليوم الساعة ⁨${heure}⁩، مع ⁨${prenom}⁩',
			'tuteur.accueil.unAutreJour' => ({required Object jour, required Object heure, required Object prenom}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩، مع ⁨${prenom}⁩',
			'tuteur.accueil.rienAujourdhui' => 'لا شيء اليوم',
			'tuteur.accueil.aucunCoursPrevu' => 'لا درس مجدول حتى الآن',
			'tuteur.accueil.aucunCoursPrevuDetail' => 'تُحضَّر دروس الأسبوع مسبقًا. سيظهر هذا الدرس هنا.',
			'tuteur.accueil.enRecherche' => 'جارٍ البحث عن معلم',
			'tuteur.accueil.enRechercheDepuis' => ({required Object date}) => 'قُدِّم الطلب في ⁨${date}⁩',
			'tuteur.accueil.enRechercheSansDate' => ({required Object prenom}) => 'سيتولى معلم ⁨${prenom}⁩ من بين الساعات المقترحة.',
			'tuteur.accueil.sansCreneau' => ({required Object prenom}) => 'لا ساعة مقترحة لـ⁨${prenom}⁩',
			'tuteur.accueil.sansCreneauDetail' => ({required Object prenom}) => 'دون موعد، لا يستطيع أي معلم تولي ⁨${prenom}⁩.',
			'tuteur.accueil.poserDesHeures' => 'اقتراح ساعات',
			'tuteur.accueil.annulee' => ({required Object heure}) => 'لن يُعقد درس الساعة ⁨${heure}⁩',
			'tuteur.accueil.motifAnnulee' => 'حصة ملغاة',
			'tuteur.accueil.motifAnnuleeTard' => 'حصة ملغاة قبيل موعدها',
			'tuteur.accueil.proposeApres' => ({required Object jour, required Object heure}) => 'الدرس القادم ⁨${jour}⁩ الساعة ⁨${heure}⁩',
			'tuteur.accueil.proposeAucun' => 'سيُقترح عليك درس جديد.',
			'tuteur.accueil.gererLeFoyer' => 'إدارة الأسرة',
			'tuteur.accueil.blocAppareils' => 'أجهزة الأسرة',
			'tuteur.accueil.blocAppareilsDetail' => 'إضافة جهاز، أو إزالة أحدها.',
			'tuteur.accueil.blocReglages' => 'الإعدادات لكل طفل',
			'tuteur.accueil.blocReglagesDetail' => 'الصورة والكاميرا والعرض، طفلًا بطفل.',
			'tuteur.accueil.blocGroupesDetail' => 'الفصل والمعلم والدرس القادم لكل طفل.',
			'tuteur.accueil.acces' => 'الوصول',
			'tuteur.accueil.accesJusqua' => ({required Object prenom, required Object date}) => 'وصول ⁨${prenom}⁩ حتى ⁨${date}⁩',
			'tuteur.accueil.accesSansFin' => ({required Object prenom}) => 'وصول ⁨${prenom}⁩ دون تاريخ انتهاء',
			'tuteur.accueil.aucunEnfant' => 'لا طفل في الأسرة',
			'tuteur.accueil.aucunEnfantDetail' => 'أضف طفلك الأول للبدء.',
			'tuteur.accueil.erreur' => 'تعذّرت قراءة الأسرة كاملة. أعد المحاولة بعد لحظة.',
			'tuteur.reglages.titre' => 'الإعدادات لكل طفل',
			'tuteur.reglages.intro' => 'تُطبَّق هذه الإعدادات على الحصة التالية، وأبدًا أثناء درس.',
			'tuteur.reglages.photo' => 'الصورة',
			'tuteur.reglages.photoAucune' => ({required Object prenom}) => 'ليس لـ⁨${prenom}⁩ صورة بعد. تبقى مرئية للأسرة وحدها.',
			'tuteur.reglages.photoPresente' => ({required Object prenom}) => 'تبقى صورة ⁨${prenom}⁩ مرئية للأسرة وحدها، ولا يراها معلمه ولا الطلاب الآخرون.',
			'tuteur.reglages.photoAjouter' => 'إضافة صورة',
			'tuteur.reglages.photoChanger' => 'تغيير الصورة',
			'tuteur.reglages.photoTropLourde' => ({required Object taille}) => 'هذه الصورة تتجاوز ⁨${taille}⁩ م.ب. التقطها بجودة أقل.',
			'tuteur.reglages.camera' => 'الكاميرا',
			'tuteur.reglages.cameraAutorisee' => ({required Object prenom}) => 'يمكن لـ⁨${prenom}⁩ تشغيل كاميرته أثناء الدرس.',
			'tuteur.reglages.cameraInterdite' => ({required Object prenom}) => 'لن يظهر زر الكاميرا لـ⁨${prenom}⁩.',
			'tuteur.reglages.cameraAutoriser' => ({required Object prenom}) => 'السماح بكاميرا ⁨${prenom}⁩',
			'tuteur.reglages.cameraRetirer' => ({required Object prenom}) => 'إلغاء كاميرا ⁨${prenom}⁩',
			'tuteur.reglages.mode' => 'العرض',
			'tuteur.reglages.modeEnfant' => ({required Object prenom}) => 'عرض كبير، دون قراءة: يتعرف ⁨${prenom}⁩ على الصور ويستمع.',
			'tuteur.reglages.modeStandard' => ({required Object prenom}) => 'عرض عادي: يقرأ ⁨${prenom}⁩ شاشته.',
			'tuteur.reglages.modePasserEnfant' => ({required Object prenom}) => 'نقل ⁨${prenom}⁩ إلى العرض الكبير',
			'tuteur.reglages.modePasserStandard' => ({required Object prenom}) => 'نقل ⁨${prenom}⁩ إلى العرض العادي',
			'tuteur.reglages.demandes' => 'طلب تغيير',
			'tuteur.reglages.demandeReaffectation' => 'تغيير المعلم',
			'tuteur.reglages.demandeDuree' => 'تغيير مدة الدروس',
			'tuteur.reglages.demandeMinimum' => 'تغيير المدة الدنيا المدفوعة',
			'tuteur.reglages.demandeSansEnseignant' => ({required Object prenom}) => 'ليس لـ⁨${prenom}⁩ معلم بعد: لا شيء يُغيَّر.',
			'tuteur.reglages.demandeTitreReaffectation' => ({required Object prenom}) => 'تغيير معلم ⁨${prenom}⁩',
			'tuteur.reglages.demandeTitreDuree' => ({required Object prenom}) => 'مدة دروس ⁨${prenom}⁩',
			'tuteur.reglages.demandeTitreMinimum' => ({required Object prenom}) => 'المدة الدنيا المدفوعة لـ⁨${prenom}⁩',
			'tuteur.reglages.demandeActuelle' => ({required Object minutes}) => 'حاليًا: ⁨${minutes}⁩ دقيقة',
			'tuteur.reglages.demandeMinutes' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة',
			'tuteur.reglages.demandeMotif' => 'لماذا هذا التغيير؟',
			'tuteur.reglages.demandeMotifRequis' => 'السبب ضروري: هو الذي يسمح بالحسم.',
			'tuteur.reglages.demandeEnvoyer' => 'إرسال الطلب',
			'tuteur.reglages.demandeEnvoyee' => 'أُرسل الطلب. ستحسم فيه الإدارة.',
			'tuteur.reglages.aucunEnfant' => 'لا طفل في الأسرة',
			'tuteur.reglages.aucunEnfantDetail' => 'أضف طفلًا لتتمكن من ضبط عرضه وكاميرته.',
			'tuteur.reglages.erreur' => ({required Object message}) => 'لم يكتمل الحفظ: ⁨${message}⁩',
			'historique.titre' => 'السجل',
			'historique.detailSeance' => 'تفاصيل الحصة',
			'historique.segments.seances' => 'الحصص',
			'historique.segments.observations' => 'المتابعات',
			'historique.moisCourts.0' => 'يناير',
			'historique.moisCourts.1' => 'فبراير',
			'historique.moisCourts.2' => 'مارس',
			'historique.moisCourts.3' => 'أبريل',
			'historique.moisCourts.4' => 'مايو',
			'historique.moisCourts.5' => 'يونيو',
			'historique.moisCourts.6' => 'يوليو',
			'historique.moisCourts.7' => 'أغسطس',
			'historique.moisCourts.8' => 'سبتمبر',
			'historique.moisCourts.9' => 'أكتوبر',
			'historique.moisCourts.10' => 'نوفمبر',
			'historique.moisCourts.11' => 'ديسمبر',
			'historique.dateCourte' => ({required Object jour, required Object mois, required Object annee}) => '⁨${jour}⁩ ⁨${mois}⁩ ⁨${annee}⁩',
			'historique.dateLongue' => ({required Object jourSemaine, required Object jour, required Object mois, required Object annee}) => '⁨${jourSemaine}⁩ ⁨${jour}⁩ ⁨${mois}⁩ ⁨${annee}⁩',
			'historique.plage' => ({required Object debut, required Object fin}) => '⁨${debut}⁩ - ⁨${fin}⁩',
			'historique.duree.secondes' => ({required Object s}) => '⁨${s}⁩ ث',
			'historique.duree.minutes' => ({required Object m}) => '⁨${m}⁩ دقيقة',
			'historique.duree.minutesSecondes' => ({required Object m, required Object s}) => '⁨${m}⁩ د ⁨${s}⁩ ث',
			'historique.duree.heures' => ({required Object h}) => '⁨${h}⁩ س',
			'historique.duree.heuresMinutes' => ({required Object h, required Object m}) => '⁨${h}⁩ س ⁨${m}⁩ د',
			'historique.fuseauListe' => 'الساعات معروضة بتوقيت هذا الجهاز.',
			'historique.fuseauDetail' => ({required Object decalage}) => 'الساعات معروضة بتوقيت هذا الجهاز (UTC⁨${decalage}⁩).',
			'historique.classeInconnue' => 'الفصل غير متاح',
			'historique.selecteur.aucune' => 'لا حصة',
			'historique.selecteur.une' => 'حصة واحدة',
			'historique.selecteur.plusieurs' => ({required Object n}) => '⁨${n}⁩ حصص',
			'historique.filtres.classe' => 'الفصل',
			'historique.filtres.toutesClasses' => 'كل الفصول',
			'historique.filtres.periode' => 'الفترة',
			'historique.filtres.toutePeriode' => 'كامل الفترة',
			'historique.filtres.septJours' => 'آخر 7 أيام',
			'historique.filtres.trenteJours' => 'آخر 30 يومًا',
			'historique.filtres.troisMois' => 'آخر 3 أشهر',
			'historique.filtres.statut' => 'الحالة',
			'historique.filtres.tousStatuts' => 'كل الحالات',
			'historique.retour' => 'العودة إلى السجل',
			'historique.etat.presence' => 'حضور',
			'historique.etat.retard' => ({required Object minutes}) => 'تأخر ⁨${minutes}⁩ دقيقة',
			'historique.etat.retardSansDuree' => 'تأخر',
			'historique.etat.verification' => 'قيد التحقق',
			'historique.etat.annule' => 'درس ملغى',
			'historique.etat.nonTenu' => 'درس لم يُعقد',
			'historique.presenceIllisible' => 'تعذّرت قراءة الحضور: تبقى الحالات غير معروفة الآن.',
			'historique.seances.videTitre' => 'لا حصة ماضية',
			'historique.seances.videPhrase' => ({required Object prenom}) => 'ستظهر هنا الحصص الماضية لـ⁨${prenom}⁩.',
			'historique.seances.videPhraseFoyer' => 'ستظهر هنا الحصص الماضية لملفات الطلاب.',
			'historique.seances.filtreVideTitre' => 'لا حصة مطابقة',
			'historique.seances.filtreVidePhrase' => 'غيّر عوامل التصفية لتجد الحصص الأخرى.',
			'historique.seances.tronquee' => ({required Object nombre}) => 'تُعرض أحدث ⁨${nombre}⁩ حصة.',
			'historique.seances.ouvrir' => ({required Object date, required Object classe, required Object etat}) => 'حصة ⁨${date}⁩، ⁨${classe}⁩، ⁨${etat}⁩',
			'historique.observations.indisponibleTitre' => 'سجل المتابعات غير متاح',
			'historique.observations.indisponiblePhrase' => 'لا يمكن بعد قراءة الزيارات المسجَّلة في التطبيق.',
			'historique.observations.videTitre' => 'لا متابعة',
			'historique.observations.videPhrase' => ({required Object prenom}) => 'ستظهر هنا الزيارات التي تقوم بها أثناء حصص ⁨${prenom}⁩.',
			'historique.observations.videPhraseFoyer' => 'ستظهر هنا زياراتك أثناء الحصص.',
			'historique.observations.filtreVideTitre' => 'لا متابعة مطابقة',
			'historique.observations.filtreVidePhrase' => 'غيّر عوامل التصفية لتجد الزيارات الأخرى.',
			'historique.observations.visiteUne' => 'زيارة واحدة',
			'historique.observations.visites' => ({required Object n}) => '⁨${n}⁩ زيارات',
			'historique.observations.dureeNonConfirmee' => 'المدة غير مؤكَّدة',
			'historique.observations.terminee' => 'منتهية',
			'historique.observations.nonRefermee' => 'الخروج غير مسجَّل',
			'historique.observations.eleveInconnu' => 'طالب',
			'historique.observations.tronquee' => 'تُعرض أحدث الزيارات فقط.',
			'historique.observations.ouvrir' => ({required Object date, required Object classe, required Object etat}) => 'متابعات ⁨${date}⁩، ⁨${classe}⁩، ⁨${etat}⁩',
			'historique.seance.titreSansClasse' => ({required Object date}) => 'حصة ⁨${date}⁩',
			'historique.seance.blocSeance' => 'الحصة',
			'historique.seance.blocPresence' => ({required Object prenom}) => 'حضور ⁨${prenom}⁩',
			'historique.seance.date' => 'التاريخ',
			'historique.seance.horaire' => 'الموعد',
			'historique.seance.dureePrevue' => 'المدة المقررة',
			'historique.seance.classe' => 'الفصل',
			'historique.seance.enseignant' => 'المعلم',
			'historique.seance.presence' => 'الحضور',
			'historique.seance.arrivee' => 'الوصول',
			'historique.seance.interruption' => 'الانقطاع',
			'historique.seance.verificationPhrase' => 'لم يُؤكَّد الحضور بعد لهذه الحصة.',
			'historique.seance.nonTenuPhrase' => 'لم تُعقد الحصة: ليس الأمر من فعل الطالب.',
			'historique.seance.annulePhrase' => 'أُلغيت الحصة.',
			'historique.seance.introuvableTitre' => 'لم يُعثر على الحصة',
			'historique.seance.introuvablePhrase' => 'هذه الحصة ليست في سجل أسرتك.',
			'historique.observation.titreSansClasse' => ({required Object date}) => 'متابعات ⁨${date}⁩',
			'historique.observation.blocResume' => 'الملخص',
			'historique.observation.blocVisites' => 'الزيارات',
			'historique.observation.observateur' => 'المتابِع',
			'historique.observation.vous' => 'أنت',
			'historique.observation.eleve' => 'الطالب',
			'historique.observation.enseignant' => 'المعلم',
			'historique.observation.dureeTotale' => 'المدة الكلية',
			'historique.observation.visite' => ({required Object n}) => 'الزيارة ⁨${n}⁩',
			'historique.observation.plageOuverte' => ({required Object debut}) => 'الدخول الساعة ⁨${debut}⁩',
			'historique.observation.terminee' => 'انتهت الزيارة',
			'historique.observation.introuvableTitre' => 'لا زيارة لهذه الحصة',
			'historique.observation.introuvablePhrase' => 'لا زيارة مسجَّلة تطابق هذه الحصة.',
			'appareils.titre' => 'الأجهزة',
			'appareils.foyer.titre' => 'أجهزة الأسرة',
			'appareils.foyer.phrase' => 'لكل ملف طالب أجهزته. المس ملفًا لترى أجهزته، أو تزيل أحدها، أو تربط جهازًا جديدًا.',
			'appareils.foyer.groupeProfils' => 'ملفات الطلاب',
			'appareils.foyer.aucunAppareil' => 'لا جهاز مربوط',
			'appareils.foyer.unAppareil' => ({required Object nom}) => 'جهاز واحد مربوط: ⁨${nom}⁩',
			'appareils.foyer.plusieursAppareils' => ({required Object nombre, required Object noms}) => '⁨${nombre}⁩ أجهزة مربوطة: ⁨${noms}⁩',
			'appareils.foyer.partageTitre' => 'جهاز مشترك',
			'appareils.foyer.partage' => 'على جهاز مشترك، يختار كل طالب ملفه ثم يدخل رمزه الشخصي. يظهر هذا الجهاز حينها تحت كل ملف يستخدمه.',
			'appareils.foyer.videTitre' => 'لا ملف طالب',
			'appareils.foyer.vide' => 'أضف ملف طالب لتربط به جهازًا لوحيًا أو هاتفًا أو حاسوبًا.',
			'appareils.foyer.videAction' => 'إضافة ملف طالب',
			'appareils.eleve.sousTitre' => ({required Object prenom}) => 'أدر الأجهزة المسموح بها لـ⁨${prenom}⁩.',
			'appareils.eleve.groupe' => 'الأجهزة المربوطة',
			'appareils.eleve.connecter' => 'ربط جهاز',
			'appareils.eleve.videTitre' => 'لا جهاز مربوط',
			'appareils.eleve.vide' => ({required Object prenom}) => 'اربط الجهاز اللوحي أو الهاتف أو الحاسوب الخاص بـ⁨${prenom}⁩ بالرمز الذي يعرضه الزر أدناه.',
			'appareils.eleve.introuvableTitre' => 'لم يُعثر على ملف الطالب',
			'appareils.eleve.introuvable' => 'ملف الطالب هذا غير مرتبط بأسرتك.',
			'appareils.eleve.introuvableAction' => 'عرض أجهزة الأسرة',
			'appareils.eleve.connecteLe' => ({required Object date}) => 'رُبط في ⁨${date}⁩',
			'appareils.eleve.utiliseLe' => ({required Object date}) => 'آخر استخدام: ⁨${date}⁩',
			'appareils.eleve.jamaisUtilise' => 'لم يُستخدم بعد',
			'appareils.eleve.retirerLibelle' => ({required Object appareil}) => 'إزالة ⁨${appareil}⁩',
			'appareils.eleve.horsLigne' => 'إزالة جهاز أو ربطه يتطلب اتصالًا بالإنترنت.',
			'appareils.eleve.partageTitre' => 'اختيار الملف والرمز الشخصي',
			'appareils.eleve.partage' => 'على جهاز مشترك، يختار كل طالب ملفه ثم يدخل رمزه الشخصي، المحفوظ على هذا الجهاز.',
			'appareils.eleve.retraitTitre' => 'إزالة جهاز',
			'appareils.eleve.retrait' => 'الجهاز المُزال لا يستطيع إعادة الاتصال. إن كان متصلًا الآن، يبقى كذلك حتى انقطاعه التالي.',
			'appareils.plateforme.android' => 'هاتف أو جهاز لوحي Android',
			'appareils.plateforme.ios' => 'iPhone أو iPad',
			'appareils.plateforme.web' => 'متصفح ويب',
			'appareils.plateforme.windows' => 'حاسوب',
			'appareils.plateforme.inconnue' => 'جهاز',
			'appareils.retrait.question' => 'إزالة هذا الجهاز؟',
			'appareils.retrait.consequence' => ({required Object appareil, required Object prenom}) => 'لن يستطيع ⁨${appareil}⁩ الاتصال بملف ⁨${prenom}⁩. إن كان متصلًا الآن، يبقى كذلك حتى انقطاعه التالي.',
			'appareils.retrait.confirmer' => 'إزالة الجهاز',
			'appareils.retrait.enCours' => 'جارٍ الإزالة',
			'appareils.retrait.reussi' => 'أُزيل الجهاز. إن كان متصلًا الآن، يبقى كذلك حتى انقطاعه التالي.',
			'appareils.retrait.echec' => 'لم تكتمل الإزالة. ما زال الجهاز مسموحًا به. أعد المحاولة بعد لحظة.',
			'appareils.retrait.horsLigne' => 'لا اتصال بالإنترنت: لم يُزل الجهاز.',
			'appareils.emetteur.titre' => 'ربط جهاز',
			'appareils.emetteur.pourEleve' => ({required Object prenom}) => 'لـ⁨${prenom}⁩',
			'appareils.emetteur.consigneTitre' => 'على الجهاز الآخر',
			'appareils.emetteur.consigne' => 'افتح Rewayah، والمس «ربط جهاز طالب»، ثم امسح رمز QR هذا أو أدخل الرمز.',
			'appareils.emetteur.libelleQr' => 'رمز QR للربط. الرمز نفسه مكتوب أيضًا على هذه الشاشة، لإدخاله إن لم يقرأ الجهاز رمز QR.',
			'appareils.emetteur.codeManuel' => 'الرمز للإدخال',
			'appareils.emetteur.codeLu' => ({required Object code}) => 'الرمز للإدخال: ⁨${code}⁩',
			'appareils.emetteur.valableJusqua' => ({required Object heure}) => 'صالح حتى ⁨${heure}⁩',
			'appareils.emetteur.restant' => ({required Object temps}) => 'بقي ⁨${temps}⁩',
			'appareils.emetteur.sortie' => ({required Object heure}) => 'مغادرة هذه الشاشة لا تلغي الرمز: يبقى صالحًا حتى ⁨${heure}⁩.',
			'appareils.emetteur.suiviIndisponible' => 'لا تستطيع هذه الشاشة تأكيد الربط. تحقّق على جهاز الطالب.',
			'appareils.emetteur.preparation' => 'جارٍ تحضير الرمز',
			'appareils.emetteur.verification.titre' => 'جارٍ التحقق من الرمز',
			'appareils.emetteur.verification.phrase' => 'الرمز مخفي ريثما يُتحقق من أنه ما زال صالحًا.',
			'appareils.emetteur.confirme.titre' => 'الجهاز مربوط',
			'appareils.emetteur.confirme.phrase' => ({required Object prenom}) => 'جهاز ⁨${prenom}⁩ جاهز. لم يعد الرمز معروضًا ولا يمكن استخدامه.',
			'appareils.emetteur.confirme.phraseSansPrenom' => 'جهاز الطالب جاهز. لم يعد الرمز معروضًا ولا يمكن استخدامه.',
			'appareils.emetteur.confirme.action' => 'تم',
			'appareils.emetteur.expire.titre' => 'انتهت صلاحية هذا الرمز',
			'appareils.emetteur.expire.phrase' => 'لم يعد صالحًا. أنشئ رمزًا جديدًا حين يكون الجهاز الآخر جاهزًا.',
			'appareils.emetteur.remplace.titre' => 'استُبدل هذا الرمز',
			'appareils.emetteur.remplace.phrase' => 'طُلب رمز جديد لهذا الطالب، هنا أو على جهاز آخر. هذا الرمز لم يعد يعمل.',
			'appareils.emetteur.dejaActif.titre' => 'رمز صالح بالفعل',
			'appareils.emetteur.dejaActif.phrase' => ({required Object heure}) => 'رمز أُنشئ لهذا الطالب صالح حتى ⁨${heure}⁩. لا يمكن عرضه من جديد: إنشاء رمز جديد يُبطل القديم.',
			'appareils.emetteur.horsLigne.titre' => 'انقطع الاتصال',
			'appareils.emetteur.horsLigne.phraseAvecCode' => ({required Object heure}) => 'الرمز مخفي حتى عودة الاتصال. يبقى صالحًا حتى ⁨${heure}⁩.',
			'appareils.emetteur.horsLigne.phraseSansCode' => 'تعذّر تحضير الرمز. سيُحضَّر بمجرد عودة الاتصال.',
			'appareils.emetteur.erreur.plafondTitre' => 'بلغت حد الأجهزة',
			'appareils.emetteur.erreur.plafondPhrase' => 'لدى هذا الطالب الحد الأقصى من الأجهزة. أزل أحدها لربط جهاز آخر.',
			'appareils.emetteur.erreur.plafondAction' => 'عرض الأجهزة',
			'appareils.emetteur.erreur.horsFoyerTitre' => 'لم يُعثر على ملف الطالب',
			'appareils.emetteur.erreur.horsFoyerPhrase' => 'ملف الطالب هذا غير مرتبط بأسرتك. عد إلى «الأسرة» لاختيار ملف.',
			'appareils.emetteur.erreur.compteTitre' => 'ربط الأجهزة غير مفتوح بعد',
			'appareils.emetteur.erreur.comptePhrase' => 'يجب فتح حسابك قبل ربط جهاز طالب.',
			'appareils.emetteur.erreur.generiqueTitre' => 'تعذّر تحضير الرمز',
			'appareils.emetteur.erreur.generiquePhrase' => 'لم يكتمل الطلب. أعد المحاولة بعد لحظة.',
			'appareils.regenerer' => 'إنشاء رمز جديد',
			'appareils.revoquer' => 'إزالة',
			'appareils.revoquerConfirmation' => 'إزالة هذا الجهاز؟ لن يستطيع الاتصال ما لم يُعد وليّ الأمر ربطه برمز جديد.',
			'connexion.titre' => 'تسجيل الدخول',
			'connexion.intro' => 'نرسل لك رابطًا بالبريد الإلكتروني. لا كلمة مرور تحفظها، ولا كلمة مرور تضيع.',
			'connexion.courriel' => 'بريدك الإلكتروني',
			'connexion.courrielIndice' => 'name@example.com',
			'connexion.motDePasseDemo' => 'كلمة مرور العرض التجريبي',
			'connexion.envoyerLien' => 'استلام الرابط',
			'connexion.avecGoogle' => 'المتابعة بحساب Google',
			'connexion.ou' => 'أو',
			'connexion.lienEnvoye' => 'أُرسل الرابط',
			'connexion.lienEnvoyeDetail' => ({required Object courriel}) => 'افتح الرسالة المرسلة إلى ⁨${courriel}⁩، ثم اتبع الرابط. يمكنك ترك هذه الصفحة مفتوحة.',
			'connexion.changerAdresse' => 'استخدام عنوان آخر',
			'connexion.erreurCourriel' => 'يبدو أن هذا العنوان غير صالح.',
			'connexion.erreurEnvoi' => 'لم يكتمل الإرسال. أعد المحاولة بعد لحظة.',
			'connexion.appareilEleveAide' => 'أنت وليّ أمر وتجهّز جهاز طالب؟',
			'connexion.appareilEleve' => 'ربط جهاز طالب',
			'connexion.renvoyer' => 'إعادة إرسال الرابط',
			'connexion.renvoye' => ({required Object courriel}) => 'أُرسل رابط جديد إلى ⁨${courriel}⁩. استخدم رابط أحدث رسالة.',
			'connexion.erreurTropTot' => 'أُرسل رابط للتو. انتظر قليلًا قبل طلب رابط آخر.',
			'connexion.horsLigne' => 'أنت غير متصل: لا يمكن إرسال الرابط الآن.',
			'connexion.probleme' => 'انتهت صلاحية الرابط أو لم يصل؟',
			'connexion.decouvrir' => 'اكتشف Rewayah Academy',
			'connexion.recuperation.titre' => 'استعادة الوصول',
			'connexion.recuperation.intro' => 'لا كلمة مرور لإعادة تعيينها: أدخل عنوانك، ونرسل لك رابط دخول جديدًا.',
			'connexion.recuperation.lienExpireTitre' => 'هذا الرابط لم يعد صالحًا',
			'connexion.recuperation.lienExpire' => 'رابط الدخول يُستخدم مرة واحدة وتنتهي صلاحيته بعد مدة. اطلب رابطًا جديدًا أدناه.',
			'connexion.recuperation.lienRefuseTitre' => 'لم يكتمل الدخول',
			'connexion.recuperation.lienRefuse' => 'تعذّر الدخول بهذا الرابط. اطلب رابطًا جديدًا أدناه.',
			'connexion.recuperation.envoyer' => 'استلام رابط جديد',
			'connexion.recuperation.envoyeTitre' => 'أُرسل رابط جديد',
			'connexion.recuperation.envoye' => ({required Object courriel}) => 'افتح الرسالة المرسلة إلى ⁨${courriel}⁩، ثم اتبع الرابط.',
			'connexion.recuperation.envoyeEncart' => 'قد تستغرق الرسالة بضع دقائق لتصل. تذكّر أن تنظر في البريد غير المرغوب فيه.',
			'connexion.recuperation.autreAdresse' => 'استخدام عنوان آخر',
			'connexion.recuperation.revenirConnexion' => 'العودة إلى تسجيل الدخول',
			'connexion.feuilleAppareil.pourQui' => 'مخصص لأولياء الأمور المسجلين. تمنح هذه الشاشة طالبًا من أسرتك وصوله الخاص، على جهازه اللوحي أو هاتفه، دون أن تسلّمه حسابك.',
			'connexion.feuilleAppareil.etapesTitre' => 'أين تجد الرمز',
			'connexion.feuilleAppareil.etape1' => 'على جهازك، افتح «الأسرة»، ثم «أجهزة الأسرة».',
			'connexion.feuilleAppareil.etape2' => 'المس ملف الطالب، ثم «ربط جهاز».',
			'connexion.feuilleAppareil.etape3' => 'يظهر رمز QR ورمز من ستة أحرف، مع وقت انتهائهما.',
			'connexion.feuilleAppareil.etape4' => 'على جهاز الطالب، امسح رمز QR أو أدخل الرمز.',
			'connexion.feuilleAppareil.plafond' => 'عدد الأجهزة لكل طالب محدود. إن بلغت الحد، أزل أحدها من «الأسرة»، «أجهزة الأسرة».',
			'connexion.feuilleAppareil.saisir' => 'إدخال الرمز',
			'connexion.feuilleAppareil.fermer' => 'إغلاق',
			'attente.titre' => 'ملفك قيد التحقق',
			'attente.dossierIncomplet' => 'ما زالت تنقص ملفك بعض الوثائق.',
			'attente.enVerification' => 'نتحقق من ملفك.',
			'attente.refuse' => 'رُفض الملف',
			'attente.suspendu' => 'حسابك موقوف.',
			'attente.contacterAcademie' => 'التواصل مع الأكاديمية',
			'attente.deposeLe' => ({required Object date}) => 'أُودع في ⁨${date}⁩',
			'attente.delai' => 'يستغرق التحقق عادة أقل من 48 ساعة.',
			'attente.aFournir' => 'للتقديم',
			'attente.pieceIdentite' => 'وثيقة هوية',
			'attente.signatureContrat' => 'توقيع العقد',
			'attente.carteAccuse' => 'ما يجب أن تعرفه',
			'attente.deposerLaPiece' => 'إيداع وثيقتي',
			'attente.signerLeContrat' => 'القراءة والتوقيع',
			'attente.lireLaCarte' => 'قراءة',
			'attente.toutEstDepose' => 'كل شيء مودَع.',
			'attente.corriger' => 'تصحيح',
			'attente.correctionImpossible' => 'لا يمكن تعديل هذا الملف الآن.',
			'attente.actualiser' => 'تحديث حالة الملف',
			'attente.suspenduDetail' => 'يمكنك التواصل مع الأكاديمية لمعرفة الخطوات المطلوبة.',
			'attente.seDeconnecter' => 'تسجيل الخروج',
			'attente.titreDossier' => 'ملفك',
			'attente.titreCompte' => 'حسابك',
			'attente.accordsARelire' => 'بقي عليك قراءة شروطنا وقبولها.',
			'attente.accesTitre' => 'أُنشئ حسابك',
			'attente.accesEnPreparation' => 'فتح حسابك ليس تلقائيًا بعد.',
			'attente.aucunDocument' => 'ليس عليك إرسال أي وثيقة.',
			'attente.accesContact' => 'يمكن للأكاديمية فتحه لك: تواصل معها.',
			'attente.actualiserCompte' => 'تحديث',
			'attente.reste' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لم يبق أي عنصر للتقديم.', one: 'بقي عنصر واحد للتقديم.', two: 'بقي عنصران للتقديم.', few: 'بقيت ⁨${n}⁩ عناصر للتقديم.', many: 'بقي ⁨${n}⁩ عنصرًا للتقديم.', other: 'بقي ⁨${n}⁩ عنصر للتقديم.', ), 
			'attente.etatAFournir' => 'للتقديم',
			'attente.prochaineEtape' => ({required Object etape}) => 'الخطوة التالية: ⁨${etape}⁩',
			'attente.refuseDetail' => ({required Object element}) => 'لطلب التحقق من جديد، ابدأ بهذا العنصر: ⁨${element}⁩.',
			'attente.refuseSansElement' => 'يمكنك التواصل مع الأكاديمية لمعرفة الخطوات المطلوبة.',
			'attente.illisible' => 'حالة ملفك لا تظهر الآن.',
			'attente.horsLigne' => 'أنت غير متصل. ستظهر حالة ملفك بمجرد عودة الشبكة.',
			'inscription.titre' => 'إنشاء حسابك',
			'inscription.etapeSur' => ({required Object n, required Object total}) => 'الخطوة ⁨${n}⁩ من ⁨${total}⁩',
			'inscription.tempsRestant' => ({required Object minutes}) => 'نحو ⁨${minutes}⁩ دقيقة',
			'inscription.roleQuestion' => 'هل تسجّل كوليّ أمر أم كمعلم؟',
			'inscription.roleTuteur' => 'وليّ أمر',
			'inscription.roleEleveAdulte' => 'طالب بالغ، لنفسي',
			'inscription.roleEnseignant' => 'معلم',
			'inscription.autreAide' => 'راسل الأكاديمية وسننشئ لك وصولك. لا تستطيع هذه الصفحة فعل ذلك عنك.',
			'inscription.identiteQuestion' => 'ما اسمك؟',
			'inscription.identiteRaison' => 'يجب أن يكون هذا الاسم هو الاسم الموجود في وثيقة هويتك.',
			'inscription.prenom' => 'الاسم',
			'inscription.nom' => 'اللقب',
			'inscription.genreQuestion' => 'أنت',
			_ => null,
		} ?? switch (path) {
			'inscription.genreHomme' => 'رجل',
			'inscription.genreFemme' => 'امرأة',
			'inscription.genreRaison' => 'تُستخدم هذه الإجابة فقط لتسليم وثيقة هويتك إلى موظف من الجنس نفسه.',
			'inscription.recapitulatif' => 'قبل المتابعة',
			'inscription.creer' => 'إنشاء حسابي',
			'inscription.erreur' => 'لم يكتمل إنشاء الحساب. أعد المحاولة بعد لحظة.',
			'inscription.champRequis' => 'هذه الإجابة ضرورية للمتابعة.',
			'inscription.etapeCourte' => ({required Object n, required Object total}) => '⁨${n}⁩ من ⁨${total}⁩',
			'inscription.retourEtape' => 'العودة إلى الخطوة السابقة',
			'inscription.seDeconnecter' => 'تسجيل الخروج',
			'inscription.modifier' => 'تعديل',
			'inscription.reessayer' => 'إعادة المحاولة',
			'inscription.erreurActualisation' => 'أُنشئ حسابك، لكن تعذّر تحديث الاتصال. أعد المحاولة، أو سجّل الخروج ثم الدخول من جديد.',
			'inscription.usage.question' => 'أي نوع من الحسابات تريد إنشاءه؟',
			'inscription.usage.moiTitre' => 'أنا فقط',
			'inscription.usage.moiDescription' => 'أريد متابعة الدروس بملفي الخاص كطالب.',
			'inscription.usage.familleTitre' => 'أنا وأسرتي',
			'inscription.usage.familleDescription' => 'سجّل أطفالك أو أقاربك، معك أو دونك. يمكنك إنشاء ملفك الخاص كطالب في أي وقت.',
			'inscription.usage.enseignant' => 'أنا معلم',
			'inscription.recap.usage' => 'نوع الحساب',
			'inscription.recap.identite' => 'الاسم',
			'inscription.recap.genre' => 'الجنس',
			'inscription.recap.enseignant' => 'معلم',
			'consentement.titre' => 'الموافقات',
			'consentement.texte.titre' => 'زيارات أولياء الأمور',
			'consentement.texte.quiResponsable' => 'يمكن لأولياء أمور الطلاب الحاضرين متابعة الحصة لوقت قصير.',
			'consentement.texte.quiResponsableDetail' => 'يسمعون المعلم والطلاب الذين يتكلمون، ومنهم طفلك. يبقى ميكروفونهم وكاميرتهم معطَّلين: لا يستطيعون الكلام ولا الكتابة ولا الظهور على الشاشة.',
			'consentement.texte.quiAdulte' => 'يمكن لأولياء أمور الطلاب الآخرين الحاضرين متابعة الحصة لوقت قصير.',
			'consentement.texte.quiAdulteDetail' => 'يسمعون المعلم والطلاب الذين يتكلمون، ومنهم أنت. يبقى ميكروفونهم وكاميرتهم معطَّلين: لا يستطيعون الكلام ولا الكتابة ولا الظهور على الشاشة.',
			'consentement.texte.pourquoi' => 'لمتابعة التعلم دون مقاطعة الفصل.',
			'consentement.texte.pourquoiDetail' => 'يأتي وليّ الأمر ليرى إن كان طفله يشارك، ثم ينصرف. تذكّر القاعة باستمرار بأن الزيارة ممكنة.',
			'consentement.texte.limites' => 'زيارات قصيرة، بعدد محدود.',
			'consentement.texte.limitesDetail' => 'لكل وليّ أمر عدد قليل من الزيارات في كل حصة، تحدده الأكاديمية ويُذكَّر به في «كيف يعمل ذلك؟». الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة.',
			'consentement.texte.caseResponsable' => 'أوافق على هذه الشروط لطفلي',
			'consentement.texte.caseAdulte' => 'أوافق على هذه الشروط',
			'consentement.texte.continuer' => 'متابعة',
			'consentement.texte.retour' => 'رجوع',
			'consentement.comment.titre' => 'كيف يعمل ذلك؟',
			'consentement.comment.visites' => ({required num n, required Object minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لا زيارة في الحصة.', one: 'زيارة واحدة مدتها ⁨${minutes}⁩ دقيقة في كل حصة.', two: 'زيارتان مدة كل منهما ⁨${minutes}⁩ دقيقة في كل حصة.', few: '⁨${n}⁩ زيارات مدة كل منها ⁨${minutes}⁩ دقيقة في كل حصة.', many: '⁨${n}⁩ زيارةً مدة كل منها ⁨${minutes}⁩ دقيقة في كل حصة.', other: '⁨${n}⁩ زيارة مدة كل منها ⁨${minutes}⁩ دقيقة في كل حصة.', ), 
			'consentement.comment.visitesSansDuree' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لا زيارة في الحصة.', one: 'زيارة قصيرة واحدة في كل حصة.', two: 'زيارتان قصيرتان في كل حصة.', few: '⁨${n}⁩ زيارات قصيرة في كل حصة.', many: '⁨${n}⁩ زيارةً قصيرة في كل حصة.', other: '⁨${n}⁩ زيارة قصيرة في كل حصة.', ), 
			'consentement.comment.parParent' => 'يسري هذا العدد على كل وليّ أمر، سواء جمعت الحصة طفلًا واحدًا من أطفاله أو أكثر.',
			'consentement.comment.ecourtee' => 'الزيارة التي تُغادَر قبل نهايتها تُحتسب: لا يبقى إلا التالية، حتى الأخيرة.',
			'consentement.comment.ecouter' => 'تسمع المعلم والطلاب الذين يتكلمون، ومنهم طفلك.',
			'consentement.comment.sansMicro' => 'يبقى الميكروفون والكاميرا معطَّلين أثناء الزيارة.',
			'consentement.comment.valeursIndisponibles' => 'يظهر عدد الزيارات ومدتها من فصل طفلك، حسب قواعد فصله.',
			'consentement.comment.fermee' => 'زيارات المتابعة غير مفتوحة لهذا الفصل.',
			'consentement.compte.intro' => 'أضافت الأكاديمية إلى شروطها فقرة عن زيارات أولياء الأمور. لا يُعدّ شيء مقبولًا ما لم تقبله أنت.',
			'consentement.compte.accepteLe' => ({required Object date}) => 'قبلت هذه الشروط في ⁨${date}⁩.',
			'consentement.compte.merci' => 'شكرًا، حُفظت موافقتك.',
			'consentement.compte.chargement' => 'جارٍ قراءة موافقاتك',
			'consentement.compte.erreur' => 'موافقاتك لا تظهر الآن.',
			'consentement.compte.horsLigne' => 'أنت غير متصل. ستظهر موافقاتك بمجرد عودة الشبكة.',
			'consentement.compte.sansProfil' => 'لا حساب متصل: سجّل الدخول من جديد لقراءة موافقاتك.',
			'consentement.compte.invite' => 'نسخة جديدة للقراءة: زيارات أولياء الأمور',
			'consentement.compte.inviteAction' => 'قراءة',
			'foyer.titre' => 'الأسرة',
			'foyer.ajouterProfil' => 'إضافة ملف طالب',
			'foyer.sousTitre' => 'ملفات الطلاب في أسرتك',
			'foyer.membres' => 'ملفات الطلاب',
			'foyer.vide.titre' => 'لا ملف طالب حتى الآن',
			'foyer.vide.phrase' => 'أضف ملف طالب لتسجيله في فصل وربط جهازه.',
			'foyer.membre.sansClasse' => 'لا فصل بعد',
			'foyer.membre.classeEchec' => 'تعذّرت قراءة الفصل',
			'foyer.membre.accesSansEcheance' => 'وصول دون موعد انتهاء',
			'foyer.membre.accesJusquau' => ({required Object date}) => 'وصول حتى ⁨${date}⁩',
			'foyer.membre.accesExpire' => ({required Object date}) => 'انتهى الوصول منذ ⁨${date}⁩',
			'foyer.membre.date' => ({required Object jour, required Object mois, required Object annee}) => '⁨${jour}⁩ ⁨${mois}⁩ ⁨${annee}⁩',
			'foyer.classesIndisponibles' => 'فصل كل طالب لا يظهر في هذه الصفحة بعد.',
			'foyer.classesEchec' => 'تعذّرت قراءة فصل بعض الطلاب.',
			'foyer.relireClasses' => 'إعادة قراءة الفصول',
			'foyer.inscriptionIllisible' => 'التسجيل الجاري لكل طالب لا يظهر في هذه الصفحة بعد.',
			'foyer.appareilsPartages' => 'الأجهزة المشتركة',
			'foyer.appareilsFoyer' => 'أجهزة الأسرة',
			'foyer.appareilsFoyerLegende' => 'ربط جهاز، عرض الأجهزة المربوطة، إزالة أحدها',
			'foyer.creerMonProfil' => 'إنشاء ملفي كطالب',
			'foyer.monProfil.titre' => 'إنشاء ملفي كطالب',
			'foyer.monProfil.indisponibleTitre' => 'غير ممكن بعد',
			'foyer.monProfil.indisponiblePhrase' => 'متابعة الدروس بنفسك بملفك الخاص كطالب ستُقترح قريبًا. يبقى حسابك كوليّ أمر كما هو.',
			'foyer.monProfil.retour' => 'العودة إلى الأسرة',
			'foyer.ajout.suivant' => 'التالي',
			'foyer.ajout.creer' => 'إنشاء الملف',
			'foyer.ajout.porte.illisibleTitre' => 'تعذّرت قراءة حسابك',
			'foyer.ajout.porte.illisiblePhrase' => 'لا نعرف بعد أي الملفات يمكنك إضافتها. أعد المحاولة بعد لحظة.',
			'foyer.ajout.pourQui.question' => 'لمن ملف الطالب هذا؟',
			'foyer.ajout.pourQui.sousTitre' => 'اختر الشخص الذي سيتابع الدروس.',
			'foyer.ajout.pourQui.requis' => 'اختر لمن هذا الملف للمتابعة.',
			'foyer.ajout.pourQui.indisponible' => 'غير متاح',
			'foyer.ajout.pourQui.enfantTitre' => 'طفل أو قاصر',
			'foyer.ajout.pourQui.enfantDescription' => 'ملف مرتبط بأسرتك، تديره نيابة عنه.',
			'foyer.ajout.pourQui.enfantAttente' => 'ممكن بمجرد فتح وصولك.',
			'foyer.ajout.pourQui.moiTitre' => 'أنا',
			'foyer.ajout.pourQui.moiDescription' => 'غير ممكن بعد: متابعة الدروس بنفسك بملفك الخاص كطالب ستُقترح قريبًا.',
			'foyer.ajout.identite.question' => 'من هو الطالب؟',
			'foyer.ajout.identite.sousTitre' => 'اسمه ولقبه وعمره.',
			'foyer.ajout.identite.prenom' => 'الاسم',
			'foyer.ajout.identite.nom' => 'اللقب',
			'foyer.ajout.identite.nomAide' => 'لا يُعرض لقب العائلة على المعلم أبدًا.',
			'foyer.ajout.identite.age' => 'العمر',
			'foyer.ajout.identite.ageSuffixe' => 'سنة',
			'foyer.ajout.identite.ageAide' => 'العمر يحدد العرض والكاميرا في البداية. يمكنك تغييرهما بعد ذلك.',
			'foyer.ajout.erreurs.prenomRequis' => 'أدخل اسم الطالب.',
			'foyer.ajout.erreurs.nomRequis' => 'أدخل لقب الطالب.',
			'foyer.ajout.erreurs.ageRequis' => 'أدخل العمر، بالأرقام.',
			'foyer.ajout.erreurs.ageHorsBornes' => ({required Object min, required Object max}) => 'أدخل عمرًا بين ⁨${min}⁩ و⁨${max}⁩ سنة.',
			'foyer.ajout.refus.compteNonValide' => 'يجب فتح وصولك قبل إضافة ملف طالب.',
			'foyer.ajout.refus.ageHorsBornes' => 'هذا العمر غير مقبول. تحقّق منه ثم أعد المحاولة.',
			'foyer.ajout.refus.refuse' => 'لم يُقبل الإنشاء. تحقّق من المعلومات ثم أعد المحاولة.',
			'foyer.ajout.incertaine.titre' => 'ربما أُنشئ الملف',
			'foyer.ajout.incertaine.phrase' => 'لم يصلنا الرد. تحقّق من الأسرة قبل إعادة المحاولة، كي لا يُنشأ الملف مرتين.',
			'foyer.ajout.incertaine.voirFoyer' => 'عرض الأسرة',
			'foyer.ajout.incertaine.reessayer' => 'إعادة المحاولة على أي حال',
			'foyer.ajout.horsLigne' => 'أنت غير متصل. يمكن إنشاء الملف عند عودة الاتصال.',
			'adulte.nav.accueil' => 'الرئيسية',
			'adulte.nav.maClasse' => 'فصلي',
			'adulte.nav.coran' => 'القرآن',
			'adulte.nav.monEspace' => 'مساحتي',
			'adulte.accueil.salutation' => ({required Object prenom}) => 'مرحبًا ⁨${prenom}⁩',
			'adulte.accueil.prochaineSeance' => 'الحصة القادمة',
			'adulte.accueil.parcours' => 'مساري',
			'adulte.accueil.dernieresSeances' => 'آخر الحصص',
			'adulte.accueil.ressources' => 'موارد الفصل',
			'adulte.accueil.absence' => 'الغياب',
			'adulte.accueil.aucuneClasse' => 'لا فصل حتى الآن.',
			'adulte.accueil.aucuneClasseDetail' => 'ستظهر حصتك القادمة هنا بمجرد فتح فصلك.',
			'adulte.accueil.echec' => 'تعذّر تحميل حصتك القادمة وآخر حصصك: لم يستجب الخادم. أعد المحاولة بعد لحظة.',
			'adulte.historique.titre' => 'حصصي الماضية',
			'adulte.historique.echec' => 'تعذّر تحميل حصصك الماضية: لم يستجب الخادم. أعد المحاولة بعد لحظة.',
			'adulte.historique.vide' => 'لا حصة ماضية حتى الآن.',
			'adulte.historique.videDetail' => 'ستظهر حصصك هنا بعد درسك الأول.',
			'adulte.maClasse.aPropos' => 'عن هذا الفصل',
			'adulte.maClasse.participants' => 'المشاركون',
			'adulte.maClasse.vous' => ({required Object prenom}) => '⁨${prenom}⁩ (أنت)',
			'adulte.maClasse.progression' => 'تقدمي في هذا الفصل',
			'adulte.maClasse.aucuneClasseDetail' => 'سيظهر فصلك ومشاركوه وموارده هنا بمجرد فتحه.',
			'adulte.monEspace.role' => 'طالب بالغ',
			'adulte.monEspace.monCompte' => 'حسابي',
			'adulte.monEspace.informations' => 'معلوماتي',
			'adulte.monEspace.coursAcces' => 'الدروس والوصول',
			'adulte.monEspace.coursAccesLegende' => 'الفصل والحصص والوصول',
			'adulte.monEspace.paiements' => 'المدفوعات',
			'adulte.monEspace.paiementsLegende' => 'السجل والإيصالات',
			'adulte.monEspace.accords' => 'موافقاتي',
			'adulte.monEspace.accordsLegende' => 'الموافقات الممنوحة للأكاديمية',
			'adulte.monEspace.securiteLegende' => 'طريقة الدخول وعنوانه',
			'adulte.monEspace.pageAccords.indisponibleTitre' => 'موافقاتك غير قابلة للاطلاع بعد',
			'adulte.monEspace.pageAccords.indisponiblePhrase' => 'قبول كل موافقة أو رفضها أو سحبها غير ممكن في التطبيق بعد. لا تُطلب منك أي موافقة هنا.',
			'adulte.monEspace.pageCoursAcces.indisponibleTitre' => 'الدروس والوصول غير قابلة للاطلاع بعد',
			'adulte.monEspace.pageCoursAcces.indisponiblePhrase' => 'تفاصيل دروسك وحصصك ووصولك غير متاحة في التطبيق بعد.',
			'adulte.coranDemo.titre' => 'متاح بعد تسجيل الدخول',
			'adulte.coranDemo.phrase' => 'ليس هذا عطلًا: العرض التجريبي لا يحتوي على نص القرآن. بعد الدخول إلى مساحتك كطالب، يُفتح هنا.',
			'adulte.recharge.titre' => 'شحن جديد',
			'adulte.recharge.phrase' => 'اختر مستفيدًا أو أكثر، ثم اختر عرضًا لكل واحد.',
			'adulte.recharge.toutSelectionner' => 'تحديد الكل',
			'adulte.recharge.toutDeselectionner' => 'إلغاء تحديد الكل',
			'adulte.recharge.offrePour' => ({required Object prenom}) => 'عرض لـ⁨${prenom}⁩',
			'adulte.recharge.verifier' => 'مراجعة الشحن',
			'adulte.recharge.raisonAucun' => 'اختر مستفيدًا واحدًا على الأقل للمتابعة.',
			'adulte.recharge.raisonOffre' => 'اختر عرضًا لكل مستفيد محدد.',
			'adulte.recharge.horsLigneVerifier' => 'أنت غير متصل. يمكنك مراجعة الشحن عند عودة الاتصال.',
			'adulte.recharge.indisponibleTitre' => 'الشحن غير متاح بعد',
			'adulte.recharge.indisponiblePhrase' => 'عروض الشحن غير متاحة في التطبيق بعد. لا دفع ممكن هنا الآن.',
			'adulte.recharge.verificationEchecTitre' => 'لم تكتمل المراجعة.',
			'adulte.recharge.verificationEchecPhrase' => 'اختياراتك محفوظة. يمكنك إعادة المحاولة.',
			'adulte.recharge.verifierTitre' => 'مراجعة الشحن',
			'adulte.recharge.verifierPhrase' => 'راجع التفاصيل قبل الدفع.',
			'adulte.recharge.recapitulatif' => 'الملخص حسب المستفيد',
			'adulte.recharge.montantPaye' => 'المبلغ المدفوع',
			'adulte.recharge.soldeAttribue' => 'الرصيد المخصص',
			'adulte.recharge.statut' => 'حالة التخصيص',
			'adulte.recharge.modifier' => 'تعديل',
			'adulte.recharge.total' => 'المجموع المستحق',
			'adulte.recharge.payer' => ({required Object montant}) => 'دفع ⁨${montant}⁩',
			'adulte.recharge.horsLignePayer' => 'أنت غير متصل. يمكنك الدفع عند عودة الاتصال.',
			'adulte.recharge.paiementEchecTitre' => 'لم يُؤكَّد الدفع.',
			'adulte.recharge.paiementEchecPhrase' => 'تحقّق قبل إعادة المحاولة.',
			'adulte.recharge.paiementIndisponibleTitre' => 'الدفع غير متاح بعد',
			'adulte.recharge.paiementIndisponiblePhrase' => 'لم يُجرَ أي دفع. الدفع عبر الإنترنت غير مفتوح في التطبيق بعد.',
			'adulte.recharge.revenirPaiements' => 'العودة إلى مدفوعات الأسرة',
			'adulte.paiements.beneficiaires' => 'المستفيدون',
			'adulte.paiements.recharger' => 'شحن',
			'adulte.paiements.recapitulatif' => ({required Object valeur}) => 'ملخص الأسرة: ⁨${valeur}⁩. يبقى كل رصيد خاصًا بمستفيده.',
			'adulte.paiements.bientotEpuise' => 'على وشك النفاد',
			'adulte.paiements.inactif' => 'غير نشط',
			'adulte.paiements.historique' => 'سجل المدفوعات',
			'adulte.paiements.soldesIndisponiblesTitre' => 'الأرصدة غير قابلة للاطلاع بعد',
			'adulte.paiements.soldesIndisponiblesPhrase' => 'رصيد كل مستفيد غير متاح في التطبيق بعد. لا شحن ممكن هنا الآن.',
			'adulte.paiements.aucunBeneficiaireTitre' => 'لا مستفيد',
			'adulte.paiements.aucunBeneficiairePhrase' => 'لا ملف طالب في أسرتك له رصيد للشحن الآن.',
			'adulte.famille.ajouter' => 'إضافة أسرتي',
			'adulte.famille.ajouterLegende' => 'سجّل أطفالك وادعُ زوجك أو زوجتك للانضمام إلى باقة الأسرة.',
			'adulte.famille.ajouterPhrase' => 'يمكنك إضافة أطفالك ودعوة زوجك أو زوجتك للانضمام إلى باقة الأسرة. تبقى مساحتك كطالب كما هي.',
			'adulte.famille.inscrireEnfant' => 'تسجيل طفل',
			'adulte.famille.maFamille' => 'أسرتي',
			'adulte.famille.forfaitFamille' => 'باقة الأسرة',
			'adulte.famille.retourMonEspace' => 'العودة إلى مساحتي',
			'adulte.famille.titulaire' => 'أنت صاحب حساب الأسرة',
			'adulte.famille.paiementsFoyer' => 'مدفوعات الأسرة',
			'adulte.famille.aProposForfait' => 'عن باقة الأسرة',
			'adulte.famille.aProposForfaitPhrase' => 'تضم باقة الأسرة صاحب الحساب، وزوجًا أو زوجة بالغًا، والأطفال أو المراهقين الذين في رعاية صاحب الحساب. يحتفظ كل بالغ بحسابه الخاص.',
			'adulte.famille.profilNonCreeTitre' => 'عرض تجريبي: لم يُنشأ أي ملف',
			'adulte.famille.profilNonCreePhrase' => 'في العرض التجريبي، لا يُرسل شيء. تبقى «أسرتي» كما كانت.',
			'adulte.famille.profilNonCreePhraseSeul' => 'في العرض التجريبي، لا يُرسل شيء. تبقى مساحتك كطالب كما كانت.',
			'adulte.famille.monProfilIndisponibleTitre' => 'غير متاح بعد',
			'adulte.famille.monProfilIndisponiblePhrase' => 'إنشاء ملف طالب منفصل غير متاح بعد. تبقى دروسك و«أسرتي» كما هي.',
			'adulte.famille.indisponibleTitre' => 'قسم الأسرة غير متاح بعد',
			'adulte.famille.indisponiblePhrase' => 'ستظهر أسرتك أو باقة أسرتك هنا بمجرد إتاحتها.',
			'adulte.famille.place.ajouterConjointe' => 'إضافة زوجة',
			'adulte.famille.place.ajouterConjoint' => 'إضافة زوج',
			'adulte.famille.place.inviterConjointe' => 'ادعُ زوجتك للانضمام إلى Rewayah بحسابها الخاص.',
			'adulte.famille.place.inviterConjoint' => 'ادعُ زوجك للانضمام إلى Rewayah بحسابه الخاص.',
			'adulte.famille.place.invitationEnvoyee' => 'أُرسلت الدعوة',
			'adulte.famille.place.maConjointe' => ({required Object prenom}) => '⁨${prenom}⁩، زوجتك',
			'adulte.famille.place.monConjoint' => ({required Object prenom}) => '⁨${prenom}⁩، زوجك',
			'adulte.famille.place.validationEnAttente' => 'بانتظار الاعتماد الإداري',
			'adulte.famille.place.validationRefusee' => 'رفضت الإدارة الاعتماد',
			'adulte.famille.place.nouvelleDemande' => 'تقديم طلب جديد',
			'adulte.famille.place.nouvelleInvitation' => ({required Object date}) => 'دعوة جديدة ممكنة ابتداءً من ⁨${date}⁩',
			'adulte.famille.place.envoyeeA' => ({required Object courriel}) => 'أُرسلت إلى ⁨${courriel}⁩',
			'adulte.famille.place.expiree' => 'انتهت صلاحية الدعوة السابقة. يمكنك إرسال دعوة جديدة.',
			'adulte.famille.place.annulee' => 'أُلغيت الدعوة ولم يعد ممكنًا قبولها. يمكنك إرسال دعوة جديدة.',
			'adulte.invitation.titreElle' => 'دعوة زوجتي',
			'adulte.invitation.titreLui' => 'دعوة زوجي',
			'adulte.invitation.enteteElle' => 'حساب شخصي لها',
			'adulte.invitation.enteteLui' => 'حساب شخصي له',
			'adulte.invitation.phraseElle' => 'ستستخدم زوجتك حسابها الخاص. لن تستطيع إدارة أسرتك ولا ملفات الطلاب التي أنشأتها.',
			'adulte.invitation.phraseLui' => 'سيستخدم زوجك حسابه الخاص. لن يستطيع إدارة أسرتك ولا ملفات الطلاب التي أنشأتها.',
			'adulte.invitation.prenom' => 'الاسم',
			'adulte.invitation.nom' => 'اللقب',
			'adulte.invitation.nomAide' => 'اختياري.',
			'adulte.invitation.courriel' => 'البريد الإلكتروني',
			'adulte.invitation.courrielAideElle' => 'سيُستخدم البريد الإلكتروني لإرسال دعوة الانضمام إلى Rewayah إلى زوجتك.',
			'adulte.invitation.courrielAideLui' => 'سيُستخدم البريد الإلكتروني لإرسال دعوة الانضمام إلى Rewayah إلى زوجك.',
			'adulte.invitation.prenomRequis' => 'أدخل الاسم.',
			'adulte.invitation.courrielRequis' => 'أدخل البريد الإلكتروني.',
			'adulte.invitation.courrielInvalide' => 'تحقّق من البريد الإلكتروني: يجب أن يشبه ⁦name@example.com⁩.',
			'adulte.invitation.verifier' => 'متابعة',
			'adulte.invitation.verifierTitre' => 'المراجعة والإرسال',
			'adulte.invitation.verifierPhrase' => 'أعد قراءة هذه المعلومات. ستُرسل الدعوة إلى هذا العنوان.',
			'adulte.invitation.nonRenseigne' => 'غير محدد',
			'adulte.invitation.modifier' => 'تعديل',
			'adulte.invitation.envoyer' => 'إرسال الدعوة',
			'adulte.invitation.horsLigne' => 'أنت غير متصل. لم يُرسل شيء. يمكنك إرسال الدعوة بنفسك عند عودة الاتصال.',
			'adulte.invitation.echecTitre' => 'لم يُؤكَّد الإرسال.',
			'adulte.invitation.echecPhrase' => 'تحقّق قبل إعادة المحاولة. معلوماتك محفوظة.',
			'adulte.invitation.refusTitre' => 'لا يمكن إرسال هذه الدعوة',
			'adulte.invitation.refusPhrase' => 'تعرض «أسرتي» الحالة الحالية للمقعد.',
			'adulte.invitation.envoyeeTitre' => 'أُرسلت الدعوة',
			'adulte.invitation.envoyeePhrase' => ({required Object courriel}) => 'أُرسلت الدعوة إلى ⁨${courriel}⁩.',
			'adulte.invitation.revenirMaFamille' => 'العودة إلى أسرتي',
			'adulte.invitation.detailPhrase' => 'الدعوة بانتظار الرد. يمكنك إلغاؤها ما لم تُقبل.',
			'adulte.invitation.annuler' => 'إلغاء الدعوة',
			'adulte.invitation.annulerQuestion' => ({required Object prenom}) => 'إلغاء دعوة ⁨${prenom}⁩؟',
			'adulte.invitation.annulerQuestionSansPrenom' => 'إلغاء هذه الدعوة؟',
			'adulte.invitation.annulerHorsLigne' => 'أنت غير متصل. لم يُلغَ شيء. يمكنك إلغاء الدعوة بنفسك عند عودة الاتصال.',
			'adulte.invitation.annulerConsequence' => 'لن يعود ممكنًا قبول الدعوة. يمكنك إرسال دعوة جديدة متى شئت.',
			'adulte.invitation.garder' => 'الإبقاء على الدعوة',
			'adulte.invitation.annulationEchecTitre' => 'لم يُؤكَّد الإلغاء.',
			'adulte.invitation.annulationEchecPhrase' => 'تحقّق قبل إعادة المحاولة.',
			'adulte.acceptation.notification' => ({required Object prenom}) => 'يدعوك ⁨${prenom}⁩ للانضمام إلى باقة أسرته.',
			'adulte.acceptation.titre' => ({required Object prenom}) => 'الانضمام إلى باقة أسرة ⁨${prenom}⁩',
			'adulte.acceptation.faisonsTitre' => 'ما نفعله',
			'adulte.acceptation.faisons' => ({required Object prenom}) => 'يدعوك ⁨${prenom}⁩ إلى باقة أسرته. إن قبلت، يُربط حسابك بأسرته. يبقى حسابك ملكك. لا يُدمج شيء.',
			'adulte.acceptation.pourquoiTitre' => 'لماذا',
			'adulte.acceptation.pourquoiElle' => ({required Object prenom}) => 'تدير ⁨${prenom}⁩ الأسرة وتدفع عن أفرادها. لتدفع عن دروسك، يجب أن ترى رصيدك.',
			'adulte.acceptation.pourquoiLui' => ({required Object prenom}) => 'يدير ⁨${prenom}⁩ الأسرة ويدفع عن أفرادها. ليدفع عن دروسك، يجب أن يرى رصيدك.',
			'adulte.acceptation.verraTitre' => ({required Object prenom}) => 'ما سيراه ⁨${prenom}⁩',
			'adulte.acceptation.verraElle' => 'اسمك ولقبك. رصيدك، أو الحاجة إلى شحنه. العرض الذي يخصك. حالة وصولك، إن كانت تمنع الدفع. وستعرف أيضًا إن غادرت باقة الأسرة.',
			'adulte.acceptation.verraLui' => 'اسمك ولقبك. رصيدك، أو الحاجة إلى شحنه. العرض الذي يخصك. حالة وصولك، إن كانت تمنع الدفع. وسيعرف أيضًا إن غادرت باقة الأسرة.',
			'adulte.acceptation.verraPasTitre' => ({required Object prenom}) => 'ما لن يراه ⁨${prenom}⁩',
			'adulte.acceptation.verraPas' => 'فصلك. مستواك. حصصك وحضورك. تقدمك. رسائلك. إشعاراتك. وسائل دفعك الشخصية. وثائق هويتك.',
			'adulte.acceptation.vousTitre' => 'ما لن تراه أنت',
			'adulte.acceptation.vous' => ({required Object prenom}) => 'دروس ⁨${prenom}⁩ وتقدمه ورسائله، وكذلك أطفال الأسرة. لن تستطيع إضافة طفل، ولا دعوة أحد، ولا تعديل الأسرة.',
			'adulte.acceptation.autresTitre' => 'من يرى أيضًا',
			'adulte.acceptation.autres' => 'معلمك لا يرى شيئًا من أسرتك. يرى فريق الأكاديمية الربط، لإدارته واعتماده عند الحاجة.',
			'adulte.acceptation.dureeTitre' => 'إلى متى',
			'adulte.acceptation.duree' => ({required Object prenom}) => 'يستمر الربط حتى تغادر باقة الأسرة، أو ينهيه ⁨${prenom}⁩.',
			'adulte.acceptation.conservation' => ({required Object duree}) => 'نحتفظ بأثر الربط ⁨${duree}⁩.',
			'adulte.acceptation.partirTitre' => 'كيف تغادر',
			'adulte.acceptation.partir' => 'في «مساحتي»، «باقة الأسرة»، «مغادرة باقة الأسرة». لا تحتاج إلى موافقته. يبقى حسابك ودروسك وسجلك ورصيدك متاحة.',
			'adulte.acceptation.refusTitre' => 'إن رفضت',
			'adulte.acceptation.refus' => 'لا يتغير شيء في حسابك ولا دروسك ولا رصيدك.',
			'adulte.acceptation.validation' => 'يجب أن تعتمد إدارة الأكاديمية هذا الربط. وإلى ذلك الحين، يعمل حسابك ودروسك بشكل عادي.',
			'adulte.acceptation.refuser' => 'رفض الدعوة',
			'adulte.acceptation.accepter' => 'قبول الدعوة',
			'adulte.acceptation.horsLigne' => 'أنت غير متصل. لم يُرسل شيء. يمكنك الرد بنفسك عند عودة الاتصال.',
			'adulte.acceptation.acceptationEchecTitre' => 'لم يُؤكَّد القبول.',
			'adulte.acceptation.refusEchecTitre' => 'لم يُؤكَّد الرفض.',
			'adulte.acceptation.echecPhrase' => 'تحقّق قبل إعادة المحاولة.',
			'adulte.acceptation.accepteeTitre' => 'قُبلت الدعوة',
			'adulte.acceptation.rejoint' => ({required Object prenom}) => 'انضممت إلى باقة أسرة ⁨${prenom}⁩.',
			'adulte.acceptation.refuseeTitre' => 'رُفضت الدعوة',
			'adulte.acceptation.impossible' => 'لا يمكن لهذا الحساب الانضمام إلى هذه الباقة حاليًا.',
			'adulte.acceptation.perimee' => 'هذه الدعوة لم تعد صالحة.',
			'adulte.acceptation.monEspace' => 'الذهاب إلى مساحتي',
			'adulte.acceptation.recu' => ({required Object date}) => 'سُجِّل الرد في ⁨${date}⁩.',
			'adulte.acceptation.titreNeutre' => 'دعوة إلى باقة الأسرة',
			'adulte.acceptation.sansCompteTitre' => 'دعوة إلى باقة الأسرة',
			'adulte.acceptation.sansCompte' => 'للرد، سجّل الدخول إلى حسابك، أو أنشئ حسابًا. ستقرأ حينها ما سيراه الشخص الذي يدعوك وما لن يراه قبل أن تقرر.',
			'adulte.acceptation.sansCompteAction' => 'تسجيل الدخول أو إنشاء حسابي',
			'adulte.sortie.retirerElle' => 'إزالة زوجتي',
			'adulte.sortie.retirerLui' => 'إزالة زوجي',
			'adulte.sortie.retirerQuestionElle' => 'إزالة زوجتي؟',
			'adulte.sortie.retirerQuestionLui' => 'إزالة زوجي؟',
			'adulte.sortie.retirerConsequence' => 'لن يُحذف حسابه ولا دروسه ولا سجله ولا رصيده.',
			'adulte.sortie.placePhrase' => ({required Object prenom}) => '⁨${prenom}⁩ جزء من باقة أسرتك، بحسابه الخاص.',
			'adulte.sortie.quitter' => 'مغادرة باقة الأسرة',
			'adulte.sortie.quitterQuestion' => 'مغادرة باقة الأسرة؟',
			'adulte.sortie.quitterConfirmer' => 'مغادرة الباقة',
			'adulte.sortie.quitterConsequence' => 'يبقى حسابك ودروسك وسجلك ورصيدك متاحة. ينتهي الربط بباقة الأسرة.',
			'adulte.sortie.forfaitPhrase' => ({required Object prenom}) => 'أنت جزء من باقة أسرة ⁨${prenom}⁩.',
			'adulte.sortie.resultatTitre' => 'انتهى الربط بباقة الأسرة',
			'adulte.sortie.resultatTitulaire' => 'يبقى حسابه ودروسه وسجله ورصيده متاحة.',
			'adulte.sortie.resultatSecondAdulte' => 'يبقى حسابك ودروسك وسجلك ورصيدك متاحة.',
			'adulte.sortie.compris' => 'فهمت',
			'adulte.sortie.retraitEchecTitre' => 'لم تُؤكَّد الإزالة.',
			'adulte.sortie.departEchecTitre' => 'لم تُؤكَّد المغادرة.',
			'adulte.sortie.echecPhrase' => 'تحقّق قبل إعادة المحاولة.',
			'adulte.sortie.horsLigne' => 'أنت غير متصل. لم يُرسل شيء. يمكنك إعادة المحاولة بنفسك عند عودة الاتصال.',
			'adulte.sortie.notificationQuitte' => ({required Object prenom}) => 'غادر ⁨${prenom}⁩ باقة أسرتك.',
			'adulte.sortie.notificationRetiree' => ({required Object prenom}) => 'أُزلتِ من باقة أسرة ⁨${prenom}⁩.',
			'adulte.sortie.notificationRetire' => ({required Object prenom}) => 'أُزلتَ من باقة أسرة ⁨${prenom}⁩.',
			'adulte.sortie.delaiTitre' => 'دعوة جديدة غير متاحة',
			'adulte.sortie.delaiPhrase' => ({required Object date}) => 'يمكن تقديم طلب جديد ابتداءً من ⁨${date}⁩. ثم يجب أن تعتمده الإدارة.',
			'adulte.sortie.pourquoi' => 'لماذا هذا الانتظار؟',
			'adulte.sortie.pourquoiPhrase' => 'يضمن هذا الإجراء أمان الأسر وحسن إدارة وصول الأطفال.',
			'adulte.reprise.titre' => 'طلب استلام الأسرة',
			'adulte.reprise.explication' => 'استخدم هذا الإجراء إن توفي صاحب حساب الأسرة. سيُبلَّغ الحساب المعني بالطلب وستدرسه الإدارة.',
			'adulte.reprise.reprisTitre' => 'ما سيُستلم',
			'adulte.reprise.repris.profils' => 'ملفات القاصرين الموجودة',
			'adulte.reprise.repris.composition' => 'تكوين الأسرة مستقبلًا وفق القواعد السارية',
			'adulte.reprise.repris.paiements' => 'مدفوعات الأسرة المستقبلية',
			'adulte.reprise.repris.parcours' => 'مسارات وليّ الأمر المرتبطة بالقاصرين',
			'adulte.reprise.jamaisTitre' => 'ما لا يُستلم أبدًا',
			'adulte.reprise.jamais.identifiants' => 'بيانات دخول صاحب الحساب',
			'adulte.reprise.jamais.messages' => 'رسائله الخاصة',
			'adulte.reprise.jamais.conversations' => 'محادثاته',
			'adulte.reprise.jamais.historique' => 'سجله التعليمي الشخصي',
			'adulte.reprise.jamais.moyensPaiement' => 'وسائل الدفع المسجلة لديه',
			'adulte.reprise.jamais.pieces' => 'وثائق هويته',
			'adulte.reprise.jamais.donnees' => 'بياناته الخاصة التي لا علاقة لها بإدارة الأسرة',
			'adulte.reprise.succession' => 'الأمر انتقال لصفة صاحب حساب الأسرة، لا استيلاء على الحساب الشخصي.',
			'adulte.reprise.deposer' => 'تقديم الطلب',
			'adulte.reprise.deposerQuestion' => 'تقديم هذا الطلب؟',
			'adulte.reprise.deposerConsequence' => 'سيُبلَّغ صاحب حساب الأسرة ويمكنه رفضه. ثم تدرس الإدارة الطلب وتقرر.',
			'adulte.reprise.horsLigne' => 'أنت غير متصل. لم يُرسل شيء. يمكنك تقديم الطلب بنفسك عند عودة الاتصال.',
			'adulte.reprise.depotEchecTitre' => 'لم يُؤكَّد الطلب.',
			'adulte.reprise.echecPhrase' => 'تحقّق قبل إعادة المحاولة.',
			'adulte.reprise.motif' => 'السبب',
			'adulte.reprise.motifDeces' => 'وفاة صاحب الحساب المصرَّح بها',
			'adulte.reprise.deposeeLe' => 'قُدِّم في',
			'adulte.reprise.etat' => 'الحالة',
			'adulte.reprise.etats.deposee' => 'مقدَّم',
			'adulte.reprise.etats.refuseeParTitulaire' => 'رفضه صاحب الحساب',
			'adulte.reprise.etats.attenteAdministration' => 'بانتظار الإدارة',
			'adulte.reprise.etats.validee' => 'معتمَد',
			'adulte.reprise.etats.refusee' => 'مرفوض',
			'adulte.reprise.phrases.deposee' => 'أُبلغ صاحب حساب الأسرة. ستدرس الإدارة الطلب.',
			'adulte.reprise.phrases.examenLe' => ({required Object date}) => 'دون رد من صاحب الحساب، يمكن للإدارة دراسته ابتداءً من ⁨${date}⁩.',
			'adulte.reprise.phrases.refuseeParTitulaire' => 'رفض صاحب حساب الأسرة هذا الطلب. الإدارة على علم. لا تُنقل أي صلاحية من صلاحيات الأسرة.',
			'adulte.reprise.phrases.attenteAdministration' => 'لم يرد صاحب الحساب. لا يُنقل شيء تلقائيًا: ما زال على الإدارة دراسة الطلب.',
			'adulte.reprise.phrases.validee' => 'اعتمدت الإدارة الطلب. أصبحت الآن صاحب حساب الأسرة.',
			'adulte.reprise.phrases.refusee' => 'رفضت الإدارة الطلب. لا تُنقل أي صلاحية من صلاحيات الأسرة.',
			'adulte.reprise.titulaire.notification' => 'قُدِّم طلب لاستلام أسرتك بدعوى وفاتك.',
			'adulte.reprise.titulaire.consigne' => 'إن كان هذا الطلب خاطئًا، فارفضه.',
			'adulte.reprise.titulaire.refuser' => 'رفض الطلب',
			'adulte.reprise.titulaire.ligne' => 'قُدِّم طلب لاستلام أسرتك.',
			'adulte.reprise.titulaire.refusEchecTitre' => 'لم يُؤكَّد الرفض.',
			'adulte.reprise.titulaire.horsLigne' => 'أنت غير متصل. لم يُرسل شيء. يمكنك رفض الطلب بنفسك عند عودة الاتصال.',
			'adulte.reprise.titulaire.refusee' => 'رفضت هذا الطلب. الإدارة على علم. لا تُنقل أي صلاحية من صلاحيات أسرتك.',
			'adulte.reprise.notifications.refuseeParTitulaire' => 'رفض صاحب حساب الأسرة طلبك لاستلام الأسرة.',
			'adulte.reprise.notifications.attenteAdministration' => 'طلبك لاستلام الأسرة بانتظار الإدارة.',
			'adulte.reprise.notifications.validee' => 'اعتُمد طلبك لاستلام الأسرة.',
			'adulte.reprise.notifications.refusee' => 'رُفض طلبك لاستلام الأسرة.',
			'adulte.demo.titre' => 'عرض تجريبي للطالب البالغ',
			'adulte.demo.mention' => 'البيانات وهمية ولا يُرسل شيء.',
			'adulte.demo.intro' => 'اختر شاشة، ثم حالة من حالات أسرة ديالو.',
			'adulte.demo.ecrans' => 'الشاشات',
			'adulte.demo.situations' => 'حالات الأسرة',
			'adulte.demo.variantes' => 'المتغيرات',
			'adulte.demo.titulaireFemme' => 'صاحبة الحساب امرأة، وزوجها هو البالغ الثاني.',
			'adulte.demo.vueConjointe' => '«مساحتي» كما تراها الزوجة، البالغة الثانية في الأسرة.',
			'adulte.demo.vueConjoint' => '«مساحتي» كما يراها الزوج، البالغ الثاني في الأسرة.',
			'adulte.demo.invitationRecueConjointe' => 'الدعوة كما تستلمها الزوجة، في حسابها الخاص.',
			'adulte.demo.invitationRecueConjoint' => 'الدعوة كما يستلمها الزوج، في حسابه الخاص.',
			'adulte.demo.invitationSansCompte' => 'الدعوة مفتوحة دون حساب.',
			'adulte.demo.reseauCoupe' => 'الشبكة مقطوعة: الرئيسية و«فصلي» دون اتصال.',
			'adulte.demo.donnees.soldeTitulaire' => 'رصيد تجريبي 1',
			'adulte.demo.donnees.soldeSecondAdulte' => 'رصيد تجريبي 2',
			'adulte.demo.donnees.soldeAicha' => 'رصيد تجريبي 3',
			'adulte.demo.donnees.soldeOumar' => 'رصيد تجريبي 4',
			'adulte.demo.donnees.totalAvecSecondAdulte' => 'مجموع تجريبي A',
			'adulte.demo.donnees.totalSansSecondAdulte' => 'مجموع تجريبي B',
			'adulte.demo.donnees.prixOffreA' => '5,00 € (عرض تجريبي)',
			'adulte.demo.donnees.prixOffreB' => '10,00 € (عرض تجريبي)',
			'adulte.demo.donnees.detailOffreA' => 'رصيد تجريبي A',
			'adulte.demo.donnees.detailOffreB' => 'رصيد تجريبي B',
			'adulte.demo.donnees.totalRecharge5' => '5,00 € (عرض تجريبي)',
			'adulte.demo.donnees.totalRecharge10' => '10,00 € (عرض تجريبي)',
			'adulte.demo.donnees.totalRecharge15' => '15,00 € (عرض تجريبي)',
			'adulte.demo.donnees.totalRecharge20' => '20,00 € (عرض تجريبي)',
			'adulte.demo.donnees.totalRecharge25' => '25,00 € (عرض تجريبي)',
			'adulte.demo.donnees.totalRecharge30' => '30,00 € (عرض تجريبي)',
			'adulte.demo.donnees.totalRecharge35' => '35,00 € (عرض تجريبي)',
			'adulte.demo.donnees.totalRecharge40' => '40,00 € (عرض تجريبي)',
			'adulte.demo.etats.adulteSeul' => 'البالغ وحده، دون أسرة.',
			'adulte.demo.etats.titulaireSansConjoint' => 'ليس في الأسرة بالغ ثانٍ.',
			'adulte.demo.etats.invitationEnAttente' => 'دعوة البالغ الثاني بانتظار الرد.',
			'adulte.demo.etats.invitationExpiree' => 'انتهت صلاحية دعوة البالغ الثاني.',
			'adulte.demo.etats.invitationAnnulee' => 'أُلغيت دعوة البالغ الثاني.',
			'adulte.demo.etats.conjointActif' => 'البالغ الثاني جزء من الأسرة.',
			'adulte.demo.etats.conjointQuitte' => 'غادر البالغ الثاني الأسرة.',
			'adulte.demo.etats.conjointRetire' => 'أُزيل البالغ الثاني من الأسرة.',
			'adulte.demo.etats.delai60' => 'مهلة أولى جارية.',
			'adulte.demo.etats.nouvelleDemande' => 'دعوة جديدة ممكنة بعد المهلة الأولى.',
			'adulte.demo.etats.validationEnAttente' => 'الاعتماد الإداري بانتظار القرار.',
			'adulte.demo.etats.validationRefusee' => 'رُفض الاعتماد الإداري.',
			'adulte.demo.etats.secondDepart' => 'غادر البالغ الثاني للمرة الثانية.',
			'adulte.demo.etats.delai120' => 'مهلة تالية، أطول، جارية.',
			'adulte.demo.etats.departsSuivants' => 'بعد المغادرة الثالثة، تنطبق المهلة التالية دائمًا.',
			'adulte.demo.etats.repriseDemandee' => 'قُدِّم طلب لاستلام الأسرة.',
			'adulte.demo.etats.repriseRefuseeParTitulaire' => 'رفض صاحب الحساب طلب الاستلام.',
			'adulte.demo.etats.repriseSansReponse' => 'دون رد في المهلة، ينتظر الطلب الإدارة.',
			'adulte.demo.etats.repriseValidee' => 'اعتُمد استلام الأسرة.',
			'adulte.demo.etats.repriseRefusee' => 'رُفض استلام الأسرة.',
			'adulte.demo.etats.dejaDansUnAutreFoyer' => 'البالغ المدعو جزء من أسرة أخرى بالفعل.',
			'adulte.demo.etats.erreurReseau' => 'انقطعت الشبكة أثناء إجراء.',
			'adulte.demo.etats.doubleSoumission' => 'أُرسل الإجراء نفسه مرتين.',
			'adulte.demo.etats.notificationDansLApplication' => 'تعذّر إرسال الإشعار إلى الهاتف، ويبقى ظاهرًا في التطبيق.',
			'adulte.demo.etats.emancipation' => 'استقلال طالب بلغ سن الرشد: غير مبني في هذه المرحلة.',
			'dossiers.titre' => 'ملفات للاعتماد',
			'dossiers.sousTitre' => 'ادرس الملفات الجاهزة لاتخاذ قرار.',
			'dossiers.aucun' => 'لا ملف ينتظر الاعتماد.',
			'dossiers.aucunDetail' => 'ستظهر الملفات الجديدة هنا حين تصبح جاهزة.',
			'dossiers.file.chargement' => 'جارٍ تحميل الملفات…',
			'dossiers.file.erreur' => 'تعذّر تحميل الملفات.',
			'dossiers.file.horsLigne' => 'أنت غير متصل. لا يمكن تحديث الملفات.',
			'dossiers.file.accesRefuse' => 'ليس لديك إذن بالوصول إلى الملفات المطلوب اعتمادها.',
			'dossiers.file.actualisation' => 'جارٍ تحديث الملفات…',
			'dossiers.file.chargementProlonge' => 'التحميل يستغرق وقتًا أطول من المتوقع.',
			'dossiers.file.suivantsErreur' => 'تعذّر تحميل الملفات التالية.',
			'dossiers.file.indisponible' => 'الاطلاع على الملفات غير متاح الآن.',
			'dossiers.file.selectionRetiree' => 'هذا الملف لم يعد متاحًا في القائمة.',
			'dossiers.file.actualiser' => 'تحديث الملفات',
			'dossiers.file.aucuneSelection' => 'اختر ملفًا لدراسته.',
			'dossiers.file.suivants' => 'تحميل الملفات التالية',
			'dossiers.file.ouvrirDe' => ({required Object nom}) => 'فتح ملف ⁨${nom}⁩',
			'dossiers.file.ouvrirElide' => ({required Object nom}) => 'فتح ملف ⁨${nom}⁩',
			'dossiers.file.enVerification' => 'قيد التحقق',
			'dossiers.file.sansNom' => 'ملف دون اسم متاح',
			'dossiers.file.legende' => ({required Object type, required Object date}) => '⁨${type}⁩ · ⁨${date}⁩',
			'dossiers.file.dateHeure' => ({required Object date, required Object heure, required Object zone}) => '⁨${date}⁩ الساعة ⁨${heure}⁩ (⁨${zone}⁩)',
			'dossiers.file.dateChiffres' => ({required Object jour, required Object mois, required Object annee}) => '⁨${jour}⁩/⁨${mois}⁩/⁨${annee}⁩',
			'dossiers.file.heureChiffres' => ({required Object heures, required Object minutes}) => '⁨${heures}⁩:⁨${minutes}⁩',
			'dossiers.file.zoneUtc' => 'UTC',
			'dossiers.file.suivantAnnonce' => ({required Object nom}) => 'الملف التالي: ⁨${nom}⁩',
			'dossiers.detail.titreDe' => ({required Object nom}) => 'ملف ⁨${nom}⁩',
			'dossiers.detail.titreElide' => ({required Object nom}) => 'ملف ⁨${nom}⁩',
			'dossiers.visionneuse.chargement' => 'جارٍ تحميل الوثيقة…',
			'dossiers.visionneuse.erreur' => 'لا يمكن عرض الوثيقة.',
			'dossiers.visionneuse.expire' => 'انتهى الوصول إلى هذه الوثيقة.',
			'dossiers.visionneuse.recharger' => 'إعادة تحميل الوثيقة',
			'dossiers.visionneuse.formatNonPrisEnCharge' => 'لا يمكن عرض تنسيق هذه الوثيقة.',
			'dossiers.visionneuse.accesRetire' => 'لم يعد لديك وصول إلى هذه الوثيقة.',
			'dossiers.visionneuse.horsLigne' => 'أنت غير متصل. لا يمكن تحميل الوثيقة.',
			'dossiers.visionneuse.aucune' => 'لا وثيقة متاحة.',
			'dossiers.visionneuse.fermerPiece' => 'إغلاق الوثيقة',
			'dossiers.visionneuse.agrandir' => 'تكبير',
			'dossiers.visionneuse.reduire' => 'تصغير',
			'dossiers.visionneuse.ajuster' => 'ملاءمة الشاشة',
			'dossiers.visionneuse.infoBulle' => ({required Object action, required Object touche}) => '⁨${action}⁩ (المفتاح ⁨${touche}⁩)',
			'dossiers.visionneuse.documentFictif' => 'وثيقة وهمية',
			'dossiers.revue.identite' => 'الهوية والملف',
			'dossiers.revue.pieceNonTransmise' => 'لم تُرسل الوثيقة المطلوبة.',
			'dossiers.revue.piece' => 'وثيقة الهوية',
			'dossiers.revue.voirPiece' => 'عرض الوثيقة',
			'dossiers.revue.accords' => 'الموافقات والعناصر المقدَّمة',
			'dossiers.revue.nom' => 'اللقب',
			'dossiers.revue.prenom' => 'الاسم',
			'dossiers.revue.typeDossier' => 'نوع الملف',
			'dossiers.revue.dateDepot' => 'تاريخ الإيداع',
			'dossiers.revue.etatDossier' => 'حالة الملف',
			'dossiers.revue.dateIndisponible' => 'تاريخ الإيداع غير متاح',
			'dossiers.revue.pasPret' => 'هذا الملف ليس جاهزًا للاعتماد بعد.',
			'dossiers.revue.erreurChargement' => 'تعذّر تحميل هذا الملف.',
			'dossiers.revue.pieceIndisponible' => 'الاطلاع على الوثيقة غير متاح الآن.',
			'dossiers.revue.etats.chargement' => 'جارٍ تحميل الملف…',
			'dossiers.revue.etats.horsLigne' => 'أنت غير متصل. لا يمكن إرسال أي قرار.',
			'dossiers.revue.etats.accesPerdu' => 'لم يعد لديك وصول إلى هذا الملف.',
			'dossiers.revue.etats.retourDossiers' => 'العودة إلى الملفات',
			'dossiers.revue.etats.verificationsIncompletes' => 'أكمل عمليات التحقق المطلوبة.',
			'dossiers.revue.etats.accordManquant' => 'تنقص هذا الملف موافقة مطلوبة.',
			'dossiers.revue.etats.decisionIndisponible' => 'القرار غير متاح الآن.',
			'dossiers.revue.etats.modifie' => 'تغيّر هذا الملف منذ فتحه.',
			'dossiers.revue.etats.actualiserDossier' => 'تحديث الملف',
			'dossiers.revue.etats.refusNonAutorise' => 'لا يمكن رفض هذا الملف في حالته الحالية.',
			'dossiers.restantUn' => 'ملف واحد قيد الانتظار',
			'dossiers.restants' => ({required Object n}) => '⁨${n}⁩ ملفات قيد الانتظار',
			'dossiers.deposeLe' => ({required Object date}) => 'أُودع في ⁨${date}⁩',
			'dossiers.inscritAujourdhui' => 'مسجَّل اليوم',
			'dossiers.inscritDepuisUnJour' => 'مسجَّل منذ يوم',
			'dossiers.inscritDepuis' => ({required Object jours}) => 'مسجَّل منذ ⁨${jours}⁩ أيام',
			'dossiers.sansPiece' => 'لا وثيقة مودَعة',
			'dossiers.sansPieceDetail' => 'أنشأ هذا الشخص حسابه وقبل العقود، لكنه لم يرسل وثيقة هويته بعد. لا شيء للتحقق إذن: الخطوة عنده.',
			'dossiers.pieceNonVisible' => 'وثيقة خارج صلاحيتك',
			'dossiers.pieceNonVisibleDetail' => 'أُودعت وثيقة بالفعل، لكن قاعدة الجنس تمنعك من الاطلاع عليها. يجب أن يتحقق منها موظف من جنس هذا الشخص.',
			'dossiers.rienATrancher' => 'لا شيء للحسم الآن',
			'dossiers.apercu' => 'الوثيقة المودَعة',
			'dossiers.apercuIndisponible' => 'المعاينة غير متاحة',
			'dossiers.verifications' => 'عمليات التحقق',
			'dossiers.pointLisible' => 'الوثيقة مقروءة',
			'dossiers.pointNom' => 'الاسم يطابق اسم الحساب',
			'dossiers.pointValidite' => 'الوثيقة غير منتهية الصلاحية',
			_ => null,
		} ?? switch (path) {
			'dossiers.verdict' => 'القرار',
			'dossiers.approuver' => 'اعتماد الملف',
			'dossiers.refuser' => 'رفض الملف',
			'dossiers.profilACompleter.titre' => 'الملف الشخصي للإكمال',
			'dossiers.profilACompleter.texte' => 'يجب إكمال ملفك الشخصي قبل الاطلاع على الملفات التي تسمح بها هذه القاعدة.',
			'dossiers.refus.titre' => 'رفض الملف',
			'dossiers.refus.nomType' => ({required Object nom, required Object type}) => '⁨${nom}⁩ · ⁨${type}⁩',
			'dossiers.refus.corps' => 'حدّد السبب الذي سيُعرض على الشخص المعني.',
			'dossiers.refus.champ' => 'سبب الرفض',
			'dossiers.refus.aide' => 'اشرح ما يجب تصحيحه، دون بيانات داخلية ولا تعليق شخصي.',
			'dossiers.refus.erreurVide' => 'حدّد سبب الرفض.',
			'dossiers.refus.tropLong' => 'السبب يتجاوز الطول المسموح.',
			'dossiers.refus.envoi' => 'جارٍ الرفض…',
			'dossiers.refus.erreur' => 'تعذّر رفض الملف.',
			'dossiers.refus.horsLigne' => 'أنت غير متصل. لم يُرسل الرفض.',
			'dossiers.refus.inconnu' => 'نتيجة الرفض غير مؤكَّدة بعد.',
			'dossiers.refus.interdit' => 'لم يعد بإمكانك رفض هذا الملف.',
			'dossiers.refus.indisponible' => 'الرفض غير متاح الآن.',
			'dossiers.refus.succes' => 'رُفض الملف.',
			'dossiers.refus.abandonQuestion' => 'التخلي عن السبب المكتوب؟',
			'dossiers.refus.continuerSaisie' => 'متابعة الكتابة',
			'dossiers.refus.abandonner' => 'تخلٍّ',
			'dossiers.validation.titre' => 'اعتماد هذا الملف؟',
			'dossiers.validation.corpsActivation' => ({required Object nom}) => 'سيُعتمد ملف ⁨${nom}⁩. سيتمكن حسابه من الوصول إلى مساحته.',
			'dossiers.validation.corpsDocumentaire' => ({required Object nom}) => 'سيُعتمد ملف ⁨${nom}⁩. تبقى شروط الوصول الأخرى سارية.',
			'dossiers.validation.indisponible' => 'الاعتماد غير متاح الآن.',
			'dossiers.validation.envoi' => 'جارٍ الاعتماد…',
			'dossiers.validation.erreur' => 'تعذّر اعتماد الملف.',
			'dossiers.validation.horsLigne' => 'أنت غير متصل. لم يُرسل الاعتماد.',
			'dossiers.validation.inconnu' => 'نتيجة الاعتماد غير مؤكَّدة بعد.',
			'dossiers.validation.plusPret' => 'هذا الملف لم يعد جاهزًا للاعتماد.',
			'dossiers.validation.interdit' => 'لم يعد بإمكانك اعتماد هذا الملف.',
			'dossiers.validation.succes' => 'اعتُمد الملف.',
			'dossiers.decision.verifierResultat' => 'التحقق من النتيجة',
			'dossiers.decision.dejaTraite' => 'عولج هذا الملف من قبل.',
			'dossiers.decision.conflit' => 'عالج هذا الملف عضو آخر في الفريق.',
			'dossiers.decision.nomComplet' => ({required Object prenom, required Object nom}) => '⁨${prenom}⁩ ⁨${nom}⁩',
			'kyc.titre' => 'وثيقة هويتك',
			'kyc.intro' => 'تكفي صورة مقروءة. تُحفظ مدة التحقق، ثم تُحذف.',
			'kyc.confidentialite' => 'تُودَع وثيقة هويتك كما هي: ليست عامة أبدًا، ولا يطلع عليها إلا الإدارة، وتشترطها قوانين حماية الطفولة.',
			'kyc.typeQuestion' => 'أي وثيقة تودع؟',
			'kyc.carteIdentite' => 'بطاقة هوية',
			'kyc.passeport' => 'جواز سفر',
			'kyc.titreSejour' => 'بطاقة إقامة',
			'kyc.choisirFichier' => 'اختيار الصورة',
			'kyc.fichierChoisi' => 'الصورة جاهزة للإرسال',
			'kyc.envoyer' => 'إرسال وثيقتي',
			'kyc.envoiEnCours' => 'جارٍ الإرسال',
			'kyc.deposee' => 'استُلمت الوثيقة',
			'kyc.erreur' => 'لم يكتمل الإرسال. أعد المحاولة بعد لحظة.',
			'kyc.tropVolumineux' => ({required Object taille}) => 'هذه الصورة تتجاوز ⁨${taille}⁩ م.ب. التقطها بجودة أقل.',
			'contrat.titre' => 'ما توقّع عليه',
			'contrat.intro' => 'نقطتان أهم من غيرهما. هما مكتوبتان هنا بوضوح بدل أن تكونا وسط نص طويل.',
			'contrat.pointEnregistrement' => 'يُسجَّل كل درس صوتيًا، ويُحفظ ثلاثين يومًا، ثم يُحذف. كل استماع يُدوَّن في السجل، مع اسم المستمع.',
			'contrat.pointControle' => 'يمكن لمراقب جودة أن يحضر درسًا دون أن يُرى. تذكّر القاعة بذلك باستمرار، سواء جرت الزيارة أم لا.',
			'contrat.pointCoordonnees' => 'لا ترى أبدًا بيانات اتصال أسرة: لا الاسم الكامل، ولا البريد الإلكتروني، ولا الهاتف.',
			'contrat.lireTexte' => 'قراءة النص كاملًا',
			'contrat.accepter' => 'قرأت وأوافق',
			'contrat.accepteLe' => ({required Object date}) => 'مقبول في ⁨${date}⁩',
			'contrat.erreur' => 'لم يكتمل التوقيع. أعد المحاولة بعد لحظة.',
			'contrat.horsLigne' => 'أنت غير متصل. ستُحفظ موافقتك بمجرد عودة الشبكة، بالضغط من جديد.',
			'contrat.caseRequise' => 'حدّد المربع للمتابعة.',
			'bienvenue.titre' => 'مرحبًا',
			'bienvenue.accroche' => 'تعلّم القرآن في فصل، مع معلم ثابت',
			'bienvenue.phrase' => 'حصص عبر الفيديو، في موعد ثابت، لك أو لطلاب أسرتك.',
			'bienvenue.pointsTitre' => 'كيف تجري الأمور',
			'bienvenue.pointClasseTitre' => 'فصل ثابت',
			'bienvenue.pointClasse' => 'الزملاء أنفسهم والموعد نفسه، كل أسبوع.',
			'bienvenue.pointEnseignantTitre' => 'معلم ثابت',
			'bienvenue.pointEnseignant' => 'سيد أو سيدة يتابع كل طالب من حصة إلى أخرى.',
			'bienvenue.pointFoyerTitre' => 'حساب واحد للأسرة',
			'bienvenue.pointFoyer' => 'تُتابَع حصص كل طالب في الأسرة من حسابك.',
			'bienvenue.commencer' => 'ابدأ',
			'bienvenue.dejaCompte' => 'لدي حساب بالفعل',
			'creneaux.titre' => 'المواعيد',
			'creneaux.ongletHeures' => 'ساعاتي',
			'creneaux.ongletEleves' => 'طلاب في الانتظار',
			'creneaux.mesEleves' => ({required Object nombre, required Object plafond}) => 'تتابع ⁨${nombre}⁩ طلاب من ⁨${plafond}⁩ ممكنين.',
			'creneaux.aucunEleve' => 'لا طالب في الانتظار في ساعاتك',
			'creneaux.aucunEleveDetail' => 'اقترح ساعات أخرى لترى أسرًا أكثر.',
			'creneaux.attendDepuis' => ({required Object jours}) => 'ينتظر منذ ⁨${jours}⁩ أيام',
			'creneaux.attendUnJour' => 'ينتظر منذ يوم',
			'creneaux.attendAujourdhui' => 'قُدِّم الطلب اليوم',
			'creneaux.niveau' => ({required Object niveau}) => 'المستوى ⁨${niveau}⁩',
			'creneaux.prendre' => ({required Object jour, required Object heure}) => 'قبول ⁨${jour}⁩ الساعة ⁨${heure}⁩',
			'creneaux.priseEnCours' => 'جارٍ الحفظ',
			'creneaux.plafondAtteint' => ({required Object nombre}) => 'تتابع بالفعل ⁨${nombre}⁩ طلاب، وهو حدك الأقصى. قبول طالب التزام دائم، لا حجز.',
			'creneaux.plafondDemander' => 'طلب متابعة طلاب أكثر',
			'creneaux.demandeTitre' => 'كم طالبًا يمكنك أن تتابع؟',
			'creneaux.demandeMotif' => 'لماذا هذا التغيير؟',
			'creneaux.demandeMotifRequis' => 'السبب ضروري: هو الذي يسمح بالحسم.',
			'creneaux.demandeEnvoyer' => 'إرسال الطلب',
			'creneaux.demandeEnvoyee' => 'أُرسل الطلب. ستحسم فيه الإدارة.',
			'creneaux.eleves' => ({required Object nombre}) => '⁨${nombre}⁩ طلاب',
			'creneaux.erreur' => ({required Object message}) => 'لم تكتمل العملية: ⁨${message}⁩',
			'disponibilites.titre' => 'متى يستطيع أطفالك متابعة درس؟',
			'disponibilites.titreEnseignant' => 'متى تستطيع التدريس؟',
			'disponibilites.consigne' => ({required Object prenom}) => 'المس الساعات الممكنة لـ⁨${prenom}⁩.',
			'disponibilites.consigneEnseignant' => 'المس الساعات التي تكون فيها متاحًا.',
			'disponibilites.effet' => 'سيختار معلم من بين هذه الساعات. كلما اقترحت أكثر، بدأ الدرس أسرع.',
			'disponibilites.effetEnseignant' => 'لن ترى إلا الطلاب الذين تتقاطع ساعاتهم مع ساعاتك.',
			'disponibilites.fuseau' => ({required Object fuseau}) => 'الساعات معروضة بتوقيت ⁨${fuseau}⁩',
			'disponibilites.aucune' => ({required Object prenom}) => 'لا ساعة مقترحة لـ⁨${prenom}⁩',
			'disponibilites.aucuneDetail' => ({required Object prenom}) => 'دون موعد، لا يستطيع أي معلم تولي ⁨${prenom}⁩.',
			'disponibilites.posees' => ({required Object nombre}) => '⁨${nombre}⁩ ساعات مقترحة',
			'disponibilites.poseeUne' => 'ساعة واحدة مقترحة',
			'disponibilites.cellulePosee' => ({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩، مقترحة. المس للإزالة',
			'disponibilites.celluleLibre' => ({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩، شاغرة. المس للاقتراح',
			'disponibilites.erreur' => 'تعذّر حفظ هذا الموعد. أعد المحاولة.',
			'disponibilites.joursCourts.0' => 'اثن',
			'disponibilites.joursCourts.1' => 'ثلا',
			'disponibilites.joursCourts.2' => 'أرب',
			'disponibilites.joursCourts.3' => 'خمي',
			'disponibilites.joursCourts.4' => 'جمع',
			'disponibilites.joursCourts.5' => 'سبت',
			'disponibilites.joursCourts.6' => 'أحد',
			'disponibilites.joursLongs.0' => 'الاثنين',
			'disponibilites.joursLongs.1' => 'الثلاثاء',
			'disponibilites.joursLongs.2' => 'الأربعاء',
			'disponibilites.joursLongs.3' => 'الخميس',
			'disponibilites.joursLongs.4' => 'الجمعة',
			'disponibilites.joursLongs.5' => 'السبت',
			'disponibilites.joursLongs.6' => 'الأحد',
			'controleur.historique.titre' => 'السجل',
			'controleur.historique.provisoire' => 'هذه الشاشة قيد التحضير.',
			'controleur.historique.envoye' => 'أُرسل',
			'controleur.historique.complementAjoute' => 'أُضيفت تكملة',
			'controleur.historique.aTerminer' => 'للإنهاء',
			'controleur.historique.filtreEtat' => 'الحالة',
			'controleur.historique.tousEtats' => 'كل الحالات',
			'controleur.historique.duree' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة من المتابعة',
			'controleur.historique.meta' => ({required Object heure, required Object duree}) => '⁨${heure}⁩ · ⁨${duree}⁩',
			'controleur.historique.dateHeure' => ({required Object date, required Object heure}) => '⁨${date}⁩، ⁨${heure}⁩',
			'controleur.historique.dateHeureAuteur' => ({required Object date, required Object heure, required Object auteur}) => '⁨${date}⁩، ⁨${heure}⁩ · ⁨${auteur}⁩',
			'controleur.historique.ligne' => ({required Object date, required Object classe, required Object enseignant, required Object duree, required Object statut}) => '⁨${date}⁩، ⁨${classe}⁩، ⁨${enseignant}⁩، ⁨${duree}⁩، ⁨${statut}⁩',
			'controleur.historique.vide' => 'لا مراقبة حتى الآن.',
			'controleur.historique.videFiltres' => 'لا مراقبة تطابق هذه المعايير.',
			'controleur.historique.resultats' => ({required Object n}) => 'عمليات المراقبة المعروضة: ⁨${n}⁩',
			'controleur.historique.titreDetail' => ({required Object classe, required Object date}) => '⁨${classe}⁩ · ⁨${date}⁩',
			'controleur.historique.sectionMission' => 'الفصل المراقَب',
			'controleur.historique.sectionObservation' => 'ملاحظة المراقب',
			'controleur.historique.sectionComplements' => 'التكملات',
			'controleur.historique.sectionEchanges' => 'المراسلات مع الإدارة',
			'controleur.historique.cleClasse' => 'الفصل',
			'controleur.historique.cleEnseignant' => 'المعلم',
			'controleur.historique.cleDate' => 'التاريخ',
			'controleur.historique.cleDuree' => 'مدة المتابعة',
			'controleur.historique.cleElevesPresents' => 'الحاضرون',
			'controleur.historique.cleReponse' => 'الرد',
			'controleur.historique.sansComplement' => 'لا تكملة.',
			'controleur.historique.faitsIndisponibles' => 'السجل التلقائي لهذه الزيارة (الساعات، الطلاب الحاضرون، إعادة الاتصال) لم يصل بعد: انتهت الحصة للتو أو انقطع الاتصال. سيظهر هنا بمجرد وصوله. باقي التقرير موثوق.',
			'controleur.historique.motif' => ({required Object motif}) => 'السبب: ⁨${motif}⁩',
			'controleur.historique.ajouterComplement' => 'إضافة تكملة',
			'controleur.complement.bandeau' => 'ستُضاف هذه التكملة إلى التقرير الموجود.',
			'controleur.complement.questionMotif' => 'لماذا تضيف هذه التكملة؟',
			'controleur.complement.contexteMotif' => 'اختياري: السبب يساعد الإدارة على قراءة التكملة. التقرير الأصلي لا يتغير.',
			'controleur.complement.precision' => 'توضيح',
			'controleur.complement.precisionAide' => 'حين تنقص تفصيلة · يكمّل التقرير دون أن يغيّر فيه شيئًا',
			'controleur.complement.correction' => 'تصحيح',
			'controleur.complement.correctionAide' => 'حين تكون معلومة في التقرير غير دقيقة · يبقى الأصل مقروءًا، ويظهر التصحيح تحته',
			'controleur.complement.faitNouveau' => 'معلومة جديدة',
			'controleur.complement.faitNouveauAide' => 'حين تعرفها بعد الزيارة · تحمل تاريخ يوم الإضافة',
			'controleur.complement.questionTexte' => 'ماذا تضيف إلى التقرير؟',
			'controleur.complement.texteObligatoire' => 'إلزامي: ما لاحظته، في جمل قليلة.',
			'controleur.complement.libelleTexte' => 'التكملة',
			'controleur.complement.aideTexte' => 'ما لاحظته أو عرفته منذ الزيارة.',
			'controleur.complement.texteRequis' => 'اكتب التكملة للمتابعة.',
			'controleur.complement.questionRecap' => 'راجع قبل الإرسال',
			'controleur.complement.cleRapport' => 'التقرير الأصلي',
			'controleur.complement.rapportInchange' => ({required Object classe, required Object date}) => '⁨${classe}⁩ · ⁨${date}⁩، دون تغيير',
			'controleur.complement.cleMotif' => 'السبب',
			'controleur.complement.sansMotif' => 'لا سبب',
			'controleur.complement.cleTexte' => 'التكملة',
			'controleur.complement.envoyer' => 'إرسال التكملة',
			'controleur.complement.echec' => 'لم يُؤكَّد الإرسال: لم يستجب الاتصال أو الخادم. نصك محفوظ هنا، أعد المحاولة بعد لحظة. يبقى التقرير الأصلي سليمًا.',
			'controleur.complement.envoyeTitre' => 'أُضيفت التكملة',
			'controleur.complement.envoyePhrase' => 'تظهر تحت التقرير الأصلي، الذي يبقى دون تغيير.',
			'controleur.complement.revenir' => 'العودة إلى التقرير',
			'controleur.compteRendu.titre' => 'التقرير',
			'controleur.compteRendu.provisoire' => 'هذه الشاشة قيد التحضير.',
			'controleur.compteRendu.revenir' => 'العودة إلى المراقبة',
			'controleur.compteRendu.sousTitre' => ({required Object classe, required Object heure}) => '⁨${classe}⁩ · ⁨${heure}⁩',
			'controleur.compteRendu.faits' => 'السجل التلقائي للحصة',
			'controleur.compteRendu.faitsReplies' => 'السجل التلقائي للحصة، مطوي',
			'controleur.compteRendu.faitsDeplies' => 'السجل التلقائي للحصة، مفتوح',
			'controleur.compteRendu.faitsChargement' => 'جارٍ قراءة السجل التلقائي للحصة: الساعات، الطلاب الحاضرون، إعادة الاتصال.',
			'controleur.compteRendu.faitsAbsents' => 'السجل التلقائي للحصة (الساعات، الطلاب الحاضرون، إعادة الاتصال) لم يصل بعد: انتهت الحصة للتو أو انقطع الاتصال. يمكنك الرد دونه؛ وسيُرفق بالتقرير بمجرد وصوله.',
			'controleur.compteRendu.cleHoraire' => 'الموعد المقرر',
			'controleur.compteRendu.horaire' => ({required Object debut, required Object fin}) => '⁨${debut}⁩ إلى ⁨${fin}⁩',
			'controleur.compteRendu.cleDebutReel' => 'البداية الفعلية',
			'controleur.compteRendu.debutRetard' => ({required Object heure, required Object minutes}) => '⁨${heure}⁩، تأخر ⁨${minutes}⁩ دقيقة',
			'controleur.compteRendu.debutALHeure' => ({required Object heure}) => '⁨${heure}⁩، في الموعد',
			'controleur.compteRendu.cleFin' => 'النهاية',
			'controleur.compteRendu.enCours' => 'جارية',
			'controleur.compteRendu.clePresents' => 'الطلاب الحاضرون',
			'controleur.compteRendu.presents' => ({required Object presents, required Object attendus}) => '⁨${presents}⁩ من ⁨${attendus}⁩',
			'controleur.compteRendu.cleReconnexions' => 'إعادات الاتصال',
			'controleur.compteRendu.question' => 'هل لديك ما تبلغ عنه؟',
			'controleur.compteRendu.contexte' => 'يُضاف ردك إلى السجل التلقائي للحصة: الساعات، الحاضرون، إعادات الاتصال.',
			'controleur.compteRendu.rienASignaler' => 'لا شيء يُذكر',
			'controleur.compteRendu.rienASignalerAide' => 'حين جرت الحصة بشكل عادي · يُرسل التقرير بإجراء واحد؛ ويمكنك إضافة تكملة بعد ذلك',
			'controleur.compteRendu.ajouterObservation' => 'إضافة ملاحظة',
			'controleur.compteRendu.ajouterObservationAide' => 'حين تريد تدوين ما رأيته · بعض الأسئلة القصيرة، واحد في كل مرة',
			'controleur.compteRendu.pointImportant' => 'الإبلاغ عن نقطة مهمة',
			'controleur.compteRendu.pointImportantAide' => 'حين يتطلب ما رأيته انتباه الإدارة · سيُطلب نصك',
			'controleur.compteRendu.envoyer' => 'إرسال التقرير',
			'controleur.compteRendu.plusTard' => 'لاحقًا',
			'controleur.compteRendu.notice' => 'يُرسل هذا التقرير تلقائيًا إلى الإدارة.',
			'controleur.compteRendu.echec' => 'لم يُؤكَّد الإرسال: لم يستجب الاتصال أو الخادم. نصك محفوظ هنا؛ أعد المحاولة بعد لحظة. إن استمرت المشكلة، راسل الإدارة.',
			'controleur.compteRendu.echecRien' => 'لم يُؤكَّد الإرسال: لم يستجب الاتصال أو الخادم. يبقى اختيارك محددًا؛ أعد المحاولة بعد لحظة. إن استمرت المشكلة، راسل الإدارة.',
			'controleur.compteRendu.envoyeTitre' => 'أُرسل التقرير',
			'controleur.compteRendu.envoyePhrase' => 'أُرسل إلى الإدارة. للعودة إليه، افتحه في «السجل» واختر «إضافة تكملة».',
			'controleur.compteRendu.ecrireAdmin' => 'مراسلة الإدارة',
			'controleur.compteRendu.visiteEnCours' => 'جارٍ إرسال الزيارة إلى الإدارة.',
			'controleur.compteRendu.visiteTransmise' => 'أُرسلت الزيارة وسجلها التلقائي إلى الإدارة.',
			'controleur.compteRendu.visiteEchec' => 'لم يُؤكَّد إرسال الزيارة: لم يستجب الاتصال أو الخادم. أعد المحاولة؛ يبقى سجل الزيارة محفوظًا على الخادم.',
			'controleur.compteRendu.aTerminer' => 'تقرير للإنهاء',
			'controleur.compteRendu.reprendre' => 'استئناف التقرير',
			'controleur.observation.important' => 'أنت تبلغ عن نقطة مهمة: سيُطلب نصك.',
			'controleur.observation.questionNature' => 'ما طبيعة ملاحظتك؟',
			'controleur.observation.contexteNature' => 'تنضم ملاحظتك إلى تقرير هذه الزيارة، المرسل إلى الإدارة.',
			'controleur.observation.pointPositif' => 'نقطة إيجابية',
			'controleur.observation.pointPositifAide' => 'حين تستحق ممارسة أن تُذكر · تظهر في التقرير كنقطة إيجابية',
			'controleur.observation.aSuivre' => 'للمتابعة',
			'controleur.observation.aSuivreAide' => 'حين يجب مراجعة نقطة في زيارة قادمة · تظهر في التقرير كنقطة للمتابعة',
			'controleur.observation.interventionAdmin' => 'تدخل الإدارة مطلوب',
			'controleur.observation.interventionAdminAide' => 'حين يجب أن تتصرف الإدارة · سيُطلب نصك، وتستلمه مع التقرير',
			'controleur.observation.questionDomaine' => 'أي مجال تخص؟',
			'controleur.observation.contexteDomaine' => 'يساعد المجال الإدارة على قراءة ملاحظتك.',
			'controleur.observation.pedagogie' => 'التعليم',
			'controleur.observation.pedagogieAide' => 'حين يتعلق الأمر بالتدريس: الشرح، التدرج، المواد',
			'controleur.observation.interaction' => 'التفاعل مع الطلاب',
			'controleur.observation.interactionAide' => 'حين يتعلق الأمر بالتواصل بين المعلم والطلاب',
			'controleur.observation.gestionClasse' => 'إدارة الفصل',
			'controleur.observation.gestionClasseAide' => 'حين يتعلق الأمر بتنظيم الحصة: الوقت، التعليمات، السير',
			'controleur.observation.respectCadre' => 'احترام الإطار',
			'controleur.observation.respectCadreAide' => 'حين يتعلق الأمر بقواعد الأكاديمية والحصة',
			'controleur.observation.climat' => 'السلوك / الجو العام',
			'controleur.observation.climatAide' => 'حين يتعلق الأمر بسلوك الفصل أو جوه العام',
			'controleur.observation.autre' => 'آخر',
			'controleur.observation.autreAide' => 'حين لا يناسب أي مجال آخر · حدّده في نصك',
			'controleur.observation.questionPersonne' => 'من المعني؟',
			'controleur.observation.contextePersonne' => 'حدّد من تخصه الملاحظة. يُختار الطالب من قائمة الفصل، بالاسم فقط.',
			'controleur.observation.enseignant' => 'المعلم',
			'controleur.observation.enseignantAide' => 'حين تخص الملاحظة معلم الحصة',
			'controleur.observation.classeEntiere' => 'الفصل كله',
			'controleur.observation.classeEntiereAide' => 'حين تخص مجموع الطلاب الحاضرين',
			'controleur.observation.elevePrecis' => 'طالب محدد',
			'controleur.observation.elevePrecisAide' => 'حين يكون طالب واحد معنيًا · تختاره من القائمة، بالاسم فقط',
			'controleur.observation.aucun' => 'لا مشارك محدد',
			'controleur.observation.aucunAide' => 'حين لا تستهدف أحدًا بعينه، مثل سير الحصة',
			'controleur.observation.questionEleve' => 'اختر الطالب من قائمة الفصل.',
			'controleur.observation.rosterChargement' => 'جارٍ قراءة قائمة الطلاب الحاضرين.',
			'controleur.observation.rosterIndisponible' => 'لم تصل قائمة الطلاب الحاضرين، غالبًا بسبب الاتصال. أعد المحاولة، أو اختر «الفصل كله» أو «لا مشارك محدد». إجاباتك الأخرى محفوظة.',
			'controleur.observation.rosterVide' => 'لا طالب حاضر في قائمة هذه الزيارة. اختر «الفصل كله» أو «لا مشارك محدد».',
			'controleur.observation.questionTexte' => 'ماذا لاحظت؟',
			'controleur.observation.texteObligatoire' => 'نصك ضروري لهذه الملاحظة.',
			'controleur.observation.texteFacultatif' => 'هذا النص اختياري.',
			'controleur.observation.libelleTexte' => 'ملاحظتك',
			'controleur.observation.aideTexte' => 'صف فقط ما لاحظته.',
			'controleur.observation.texteRequis' => 'اكتب ما لاحظته للمتابعة.',
			'controleur.observation.questionRecap' => 'راجع ملاحظتك قبل الإرسال.',
			'controleur.observation.cleNature' => 'الطبيعة',
			'controleur.observation.cleDomaine' => 'المجال',
			'controleur.observation.clePersonne' => 'الشخص المعني',
			'controleur.observation.cleTexte' => 'الملاحظة',
			'controleur.observation.sansTexte' => 'لا نص',
			'controleur.observation.echec' => 'لم يُؤكَّد الإرسال: لم يستجب الاتصال أو الخادم. نصك محفوظ هنا؛ أعد المحاولة بعد لحظة. إن استمرت المشكلة، راسل الإدارة.',
			'controleur.echanges.titre' => 'المراسلات',
			'controleur.echanges.titreFil' => ({required Object classe, required Object date}) => '⁨${classe}⁩ · ⁨${date}⁩',
			'controleur.echanges.derniereActivite' => ({required Object date}) => 'آخر نشاط: ⁨${date}⁩',
			'controleur.echanges.reponseRecue' => 'وصل رد',
			'controleur.echanges.enAttente' => 'قيد الانتظار',
			'controleur.echanges.vide' => 'لا مراسلات مع الإدارة حتى الآن.',
			'controleur.echanges.contexte' => 'سياق الزيارة، مرفق تلقائيًا',
			'controleur.echanges.cleClasse' => 'الفصل',
			'controleur.echanges.cleDate' => 'التاريخ',
			'controleur.echanges.cleHeure' => 'الساعة',
			'controleur.echanges.auteurVous' => 'أنت',
			'controleur.echanges.auteurAdmin' => 'الإدارة',
			'controleur.echanges.champ' => 'الرد على الإدارة…',
			'controleur.echanges.champLibelle' => 'الرد على الإدارة',
			'controleur.echanges.envoyer' => 'إرسال',
			'controleur.echanges.champVide' => 'اكتب رسالة لتتمكن من إرسالها.',
			'controleur.echanges.enCours' => 'جارٍ الإرسال.',
			'controleur.echanges.envoye' => 'أُرسل.',
			'controleur.echanges.echec' => 'لم يُؤكَّد الإرسال: لم يستجب الاتصال أو الخادم. نصك محفوظ هنا؛ أعد المحاولة بعد لحظة. إن استمرت المشكلة، راسل الإدارة.',
			'controleur.echanges.reessayer' => 'إعادة المحاولة',
			'controleur.echanges.nouveauMessage' => ({required Object auteur, required Object texte}) => 'رسالة جديدة من ⁨${auteur}⁩: ⁨${texte}⁩',
			'controleur.demo.titre' => 'عرض تجريبي للمراقب',
			'controleur.demo.mention' => 'بيانات وهمية، لا إرسال.',
			'controleur.demo.intro' => 'اختر شاشة من شاشات المراقبة وحالة زيارة.',
			'controleur.demo.etatAucune' => 'لا زيارة',
			'controleur.demo.etatPasEncoreEnDirect' => 'الحصة لم تبدأ مباشرة بعد',
			'controleur.demo.etatEnDirect' => 'حصة مباشرة',
			'controleur.demo.etatIndisponible' => 'الزيارة لم تعد مقترحة',
			'controleur.demo.etatDejaControlee' => 'الفصل مراقَب بالفعل',
			'controleur.demo.espaces' => 'المساحات والوصول',
			'controleur.demo.espacesIntro' => 'الحساب نفسه، عدة مساحات: ينتقل المعلم أو المدير إلى «المراقبة» من «الحساب»، ثم «المساحات».',
			'controleur.demo.enseignantControle' => 'معلم مراقب، مساحة المراقبة',
			'controleur.demo.enseignantPrincipal' => 'معلم مراقب، مساحة المعلم',
			'controleur.demo.adminControle' => 'مدير مراقب، مساحة المراقبة',
			'controleur.demo.adminPrincipal' => 'مدير مراقب، مساحة الإدارة',
			'controleur.demo.missionEnCours' => 'زيارة جارية، العودة إلى المساحة الرئيسية',
			'controleur.demo.accesRevoque' => 'سُحب الوصول أثناء التصفح',
			'controleur.demo.sansCapacite' => 'معلم دون صلاحية المراقبة',
			'controleur.demo.compteRenduIndisponible' => 'التقرير، الزيارة لم تعد مقترحة',
			'controleur.acces.revoque' => 'وصولك إلى المراقبة لم يعد ساريًا.',
			'controleur.acces.revenir' => 'العودة إلى مساحتي',
			'controleur.controle.titre' => 'المراقبة',
			'controleur.controle.mission' => 'فصلك القادم للمراقبة',
			'controleur.controle.missionEnDirect' => 'فصل للمراقبة الآن',
			'controleur.controle.commencer' => 'بدء المراقبة',
			'controleur.controle.vide' => 'لا مراقبة مطلوبة الآن.',
			'controleur.controle.videAide' => 'سيقترح عليك Rewayah فصلًا للمراقبة حين تتوفر حصة مناسبة.',
			'controleur.controle.indisponible' => 'هذه الزيارة لم تعد مقترحة: أُلغيت الحصة أو أُسندت إلى مراقب آخر.',
			'controleur.controle.attente' => 'تُفتح المراقبة بمجرد أن تصبح الحصة مباشرة.',
			'controleur.controle.dejaEnCours' => 'مراقبة جارية بالفعل في هذا الفصل.',
			'controleur.controle.dejaEnCoursAide' => 'مراقبة واحدة في كل مرة لكل فصل. اختر حصة أخرى، أو عد لاحقًا: يمكنك البدء حين تنتهي هذه المراقبة.',
			'controleur.controle.incognito' => 'لا يُعلَن عن حضورك في الوقت الفعلي.',
			'controleur.controle.horaire' => ({required Object debut, required Object fin}) => '⁨${debut}⁩ إلى ⁨${fin}⁩',
			'controleur.controle.duree' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة مقررة',
			'controleur.controle.eleves' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لا طالب', one: 'طالب واحد', two: 'طالبان', few: '⁨${n}⁩ طلاب', many: '⁨${n}⁩ طالبًا', other: '⁨${n}⁩ طالب', ), 
			'controleur.controle.chargement' => 'جارٍ قراءة زيارتك القادمة.',
			'controleur.controle.erreur' => 'تعذّرت قراءة زيارتك القادمة، غالبًا بسبب الاتصال أو خدمة غير متاحة مؤقتًا. أعد المحاولة بعد لحظة.',
			'agent.titre' => 'دخول موظف',
			'agent.intro' => 'تفتح هذه الصفحة التطبيق للقراءة فقط، بالرمز الذي سلّمته الأكاديمية.',
			'agent.jeton' => 'رمز المتابعة',
			'agent.jetonExemple' => 'rag_...',
			'agent.entrer' => 'فتح التطبيق',
			'agent.ouverture' => 'جارٍ الفتح',
			'agent.refus' => 'رُفض الرمز',
			'agent.refusDetail' => 'هذا الرمز غير معروف أو ملغى أو منتهي الصلاحية. اطلب رمزًا جديدًا من الأكاديمية.',
			'agent.indisponible' => 'الخدمة غير متاحة',
			'agent.indisponibleDetail' => 'لم تستجب عملية فتح الجلسة. أعد المحاولة بعد لحظة.',
			'agent.reessayer' => 'إعادة المحاولة',
			'agent.bandeau' => 'متابعة، للقراءة فقط',
			'agent.bandeauMasque' => 'الأسماء مخفية',
			'agent.bandeauExpire' => ({required Object heure}) => 'حتى ⁨${heure}⁩',
			'admin.tableau.titre' => 'مركز القيادة',
			'admin.tableau.dossiers' => 'ملفات للاعتماد',
			'admin.tableau.dossiersDetail' => 'فتح القائمة، الأقدم أولًا.',
			'admin.tableau.demandesDetail' => 'أسر ومعلمون ينتظرون ردًا.',
			'admin.tableau.foyers' => 'طلاب دون معلم',
			'admin.tableau.rapports' => 'دفاتر ناقصة',
			'admin.tableau.incidents' => 'حوادث (24 س)',
			'admin.tableau.comptes' => 'وصول منتهٍ',
			'admin.tableau.incidentsEtAcces' => 'الحوادث والوصول',
			'admin.tableau.demandes' => 'طلبات للحسم',
			'admin.tableau.compteursErreur' => 'تعذّرت قراءة العدادات. أعد المحاولة بعد لحظة.',
			'admin.tableau.calme' => 'لا شيء ينتظر قرارًا اليوم.',
			'admin.tableau.apercuErreur' => 'تعذّرت قراءة القائمة.',
			'admin.tableau.outils' => 'الأدوات',
			'admin.tableau.outilsComptes' => 'الحسابات',
			'admin.tableau.outilsComptesDetail' => 'كل الأشخاص المسجلين، والذين ينتظرون قرارًا أولًا. بمن فيهم من لم يودع وثيقته بعد.',
			'admin.tableau.outilsAccesAgents' => 'وصول الوكلاء الآليين',
			'admin.tableau.outilsAccesAgentsDetail' => 'فتح وصول للقراءة فقط، محدود زمنيًا، على مسار شخص.',
			'admin.tableau.outilsGroupesDetail' => 'الفصول وطلابها ومعلمها.',
			'admin.tableau.ligneDossier' => ({required Object prenom}) => 'ملف هوية ⁨${prenom}⁩',
			'admin.tableau.ligneReaffectation' => ({required Object prenom}) => 'تغيير معلم ⁨${prenom}⁩',
			'admin.tableau.lignePlafond' => ({required Object prenom}) => 'الحد الأقصى لطلاب ⁨${prenom}⁩',
			'admin.tableau.ligneRegle' => ({required Object prenom}) => 'تغيير قاعدة لـ⁨${prenom}⁩',
			'admin.tableau.attenteAujourdhui' => 'أُودع اليوم',
			'admin.tableau.attenteUnJour' => 'ينتظر منذ يوم',
			'admin.tableau.attenteJours' => ({required Object jours}) => 'ينتظر منذ ⁨${jours}⁩ أيام',
			'admin.demandes.titre' => 'الطلبات والقواعد',
			'admin.demandes.restanteUne' => 'طلب واحد قيد الانتظار',
			'admin.demandes.restantes' => ({required Object n}) => '⁨${n}⁩ طلبات قيد الانتظار',
			'admin.demandes.aucune' => 'لا طلب قيد الانتظار',
			'admin.demandes.aucuneDetail' => 'تصل هنا طلبات الأسر والطلاب المستقلين والمعلمين، الأقدم أولًا.',
			'admin.demandes.faitePar' => ({required Object date, required Object role}) => 'طُلب في ⁨${date}⁩، من ⁨${role}⁩',
			'admin.demandes.roleGuardian' => 'وليّ أمر',
			'admin.demandes.roleTeacher' => 'معلم',
			'admin.demandes.roleStudent' => 'طالب مستقل',
			'admin.demandes.roleAdmin' => 'الإدارة',
			'admin.demandes.roleController' => 'مراقب',
			'admin.demandes.roleInconnu' => 'طرف في الملف',
			'admin.demandes.reclame' => 'المطلوب',
			'admin.demandes.reclameReaffectation' => ({required Object prenom}) => 'تغيير معلم ⁨${prenom}⁩',
			'admin.demandes.reclamePlafond' => ({required Object valeur}) => 'رفع الحد الأقصى إلى ⁨${valeur}⁩ طلاب',
			'admin.demandes.reclameRegle' => ({required Object regle, required Object valeur}) => 'جعل ⁨${regle}⁩ ⁨${valeur}⁩ دقيقة',
			'admin.demandes.reclameRegleSansValeur' => ({required Object regle}) => 'مراجعة ⁨${regle}⁩',
			'admin.demandes.motifDemande' => 'السبب المذكور',
			'admin.demandes.verdict' => 'القرار',
			'admin.demandes.accorder' => 'قبول',
			'admin.demandes.refuser' => 'رفض',
			'admin.demandes.motif' => 'ما يبرر هذا الرفض، في جملة واحدة',
			'admin.demandes.motifRequis' => 'يجب أن يقول الرفض السبب: إنها الجملة الوحيدة التي سيتلقاها الطرف.',
			'admin.demandes.effet' => 'القبول يطبّق الأثر في قاعدة البيانات: يُغلق الإسناد، أو تُوضع القاعدة. هذه الشاشة تصدر الحكم فقط.',
			'admin.demandes.journalisation' => 'يُدوَّن كل قرار وكل قاعدة موضوعة في سجل التدقيق، مع اسمك.',
			'admin.demandes.feuille' => ({required Object prenom}) => 'قواعد ⁨${prenom}⁩',
			'admin.demandes.feuilleIntro' => 'قيمة المنصة والقيمة المطبقة، جنبًا إلى جنب. تُغيَّر القاعدة هنا دون حاجة إلى طلب.',
			'admin.demandes.regleDuree' => 'مدة الحصة',
			'admin.demandes.regleMinimum' => 'المدة الدنيا المدفوعة',
			'admin.demandes.reglePause' => 'الاستراحة بين درسين',
			'admin.demandes.reglePlafond' => 'الحد الأقصى للطلاب',
			'admin.demandes.regleInconnue' => 'قاعدة غير معروفة',
			'admin.demandes.plateforme' => ({required Object valeur}) => 'المنصة: ⁨${valeur}⁩',
			'admin.demandes.effective' => ({required Object valeur}) => 'المطبقة: ⁨${valeur}⁩',
			'admin.demandes.minutes' => ({required Object valeur}) => '⁨${valeur}⁩ دقيقة',
			'admin.demandes.eleves' => ({required Object valeur}) => '⁨${valeur}⁩ طلاب',
			'admin.demandes.surchargeDepuis' => ({required Object date, required Object motif}) => 'وُضعت في ⁨${date}⁩: ⁨${motif}⁩',
			'admin.demandes.sansSurcharge' => 'يتبع هذا الطالب قاعدة المنصة.',
			'admin.demandes.changer' => 'تغيير',
			'admin.demandes.clore' => 'العودة إلى قاعدة المنصة',
			'admin.demandes.historique' => 'الاستثناءات المغلقة',
			'admin.demandes.historiqueLigne' => ({required Object valeur, required Object debut, required Object fin}) => '⁨${valeur}⁩، من ⁨${debut}⁩ إلى ⁨${fin}⁩',
			'admin.demandes.historiqueMotifs' => ({required Object motif, required Object cloture}) => 'وُضعت: ⁨${motif}⁩. أُغلقت: ⁨${cloture}⁩.',
			'admin.demandes.poserTitre' => ({required Object regle, required Object prenom}) => '⁨${regle}⁩، لـ⁨${prenom}⁩',
			'admin.demandes.cloreTitre' => ({required Object prenom}) => 'إغلاق استثناء ⁨${prenom}⁩',
			'admin.demandes.poserMotif' => 'لماذا هذا التغيير؟',
			'admin.demandes.poserMotifRequis' => 'قاعدة دون سبب لا تُفهم بعد ستة أشهر.',
			'admin.demandes.poserEnvoyer' => 'وضع القاعدة',
			'admin.demandes.cloreEnvoyer' => 'إغلاق الاستثناء',
			'admin.demandes.erreurFile' => 'تعذّر تحميل قائمة الطلبات. أعد المحاولة بعد لحظة.',
			'admin.attribution.titre' => 'الإسناد',
			'admin.attribution.intro' => 'حين لا يأخذ أي معلم طفلًا، هنا يُسند إليه معلم.',
			'admin.attribution.colonneEleves' => 'طلاب دون معلم',
			'admin.attribution.colonneEnseignants' => 'المعلمون',
			'admin.attribution.aucunEleve' => 'لكل طالب معلمه',
			'admin.attribution.aucunEleveDetail' => 'سيظهر هنا الأطفال الذين لم يأخذهم أحد بعد، الأطول انتظارًا أولًا.',
			'admin.attribution.erreurEleves' => 'تعذّرت قراءة القائمة. أعد المحاولة بعد لحظة.',
			'admin.attribution.erreurEnseignants' => 'تعذّرت قراءة المعلمين. أعد المحاولة بعد لحظة.',
			'admin.attribution.attendAujourdhui' => 'مسجَّل اليوم',
			'admin.attribution.attendUnJour' => 'ينتظر منذ يوم',
			'admin.attribution.attendJours' => ({required Object jours}) => 'ينتظر منذ ⁨${jours}⁩ أيام',
			'admin.attribution.niveau' => ({required Object niveau}) => 'المستوى ⁨${niveau}⁩',
			'admin.attribution.heuresProposees' => ({required Object nombre}) => '⁨${nombre}⁩ ساعات مقترحة',
			'admin.attribution.heureProposee' => 'ساعة واحدة مقترحة',
			'admin.attribution.sansHeure' => 'لا ساعة مقترحة',
			'admin.attribution.sansHeureDetail' => 'ما دامت الأسرة لم تحدد أي موعد، لا يستطيع أحد أن يسند إليها معلمًا، ولا أنت. الخطوة عندها، في أوقات توفرها.',
			'admin.attribution.changerEleve' => 'اختيار طالب آخر',
			'admin.attribution.choisirEleve' => 'اختر طالبًا',
			'admin.attribution.choisirEleveDetail' => 'سيظهر المعلمون هنا، والذين يشاركونه ساعة أولًا.',
			'admin.attribution.charge' => ({required Object actifs, required Object plafond}) => '⁨${actifs}⁩ طلاب من ⁨${plafond}⁩',
			'admin.attribution.complet' => 'بلغ الحد الأقصى',
			'admin.attribution.libreSur' => ({required Object jour, required Object heure}) => 'متاح ⁨${jour}⁩ الساعة ⁨${heure}⁩',
			'admin.attribution.libreSurPlusieurs' => ({required Object nombre}) => 'متاح في ⁨${nombre}⁩ من الساعات المقترحة',
			'admin.attribution.sansHeureCommune' => 'لا ساعة مشتركة',
			'admin.attribution.quelleHeure' => 'في أي ساعة؟',
			'admin.attribution.creneau' => ({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩',
			'admin.attribution.motif' => 'لماذا التجاوز؟',
			'admin.attribution.motifRequis' => ({required Object prenom}) => 'لم يحدد ⁨${prenom}⁩ هذه الساعة. قد يُبرَّر إسنادها مع ذلك، ويُدوَّن ذلك في السجل.',
			'admin.attribution.attribuer' => ({required Object eleve, required Object enseignant}) => 'إسناد ⁨${eleve}⁩ إلى ⁨${enseignant}⁩',
			'admin.attribution.journalisation' => 'يُدوَّن كل إسناد: من قرر، ومتى، وفي أي ساعة، والسبب إن لزم التجاوز.',
			'admin.attribution.effet' => 'يغادر الطالب هذه القائمة وتُوضع دروسه في الجدول فورًا.',
			'admin.attribution.erreur' => ({required Object message}) => 'لم يكتمل الإسناد: ⁨${message}⁩',
			'admin.groupes.titre' => 'الفصول',
			'admin.groupes.intro' => 'يجمع كل فصل معلمًا وطلابه حول موعد مشترك: هناك يُقدَّم الدرس.',
			'admin.groupes.colonneGroupe' => 'الفصل',
			'admin.groupes.colonneEnseignant' => 'المعلم',
			'admin.groupes.colonneType' => 'الفئة',
			'admin.groupes.colonneMembres' => 'الأعضاء',
			'admin.groupes.colonneCreneau' => 'الموعد',
			'admin.groupes.colonneEtat' => 'الحالة',
			'admin.groupes.typeEnfant' => 'أطفال',
			'admin.groupes.typeAdulte' => 'بالغون',
			'admin.groupes.filtreTousTypes' => 'كل الفئات',
			'admin.groupes.etatActif' => 'نشط',
			'admin.groupes.etatCloture' => 'مغلق',
			'admin.groupes.membresSur' => ({required Object actifs, required Object seuil}) => '⁨${actifs}⁩ / ⁨${seuil}⁩',
			'admin.groupes.aucun' => 'لا فصل منشأ',
			'admin.groupes.aucunDetail' => 'أنشئ فصلًا أول لتمنح موعدًا مشتركًا معلمًا وطلابًا.',
			'admin.groupes.aucunAvecCeFiltre' => 'لا فصل بهذا المعيار',
			'admin.groupes.aucunAvecCeFiltreDetail' => 'غيّر المعيار لترى الفصول الأخرى.',
			'admin.groupes.erreur' => 'تعذّرت قراءة الفصول. أعد المحاولة بعد لحظة.',
			'admin.groupes.creer' => 'إنشاء فصل',
			'admin.groupes.creerTitre' => 'إنشاء فصل',
			'admin.groupes.champLibelle' => 'اسم الفصل',
			'admin.groupes.champEnseignantId' => 'معرّف المعلم',
			'admin.groupes.champType' => 'الفئة',
			'admin.groupes.champJour' => 'اليوم',
			'admin.groupes.champHeure' => 'الساعة (0-23)',
			'admin.groupes.champSeuil' => 'الحد الأقصى',
			'admin.groupes.creerEnvoyer' => 'إنشاء الفصل',
			'admin.groupes.creerErreur' => ({required Object message}) => 'لم يكتمل الإنشاء: ⁨${message}⁩',
			'admin.groupes.detailTitre' => ({required Object libelle}) => 'الفصل ⁨${libelle}⁩',
			'admin.groupes.detailMembres' => 'الأعضاء',
			'admin.groupes.detailAucunMembre' => 'لا طالب في هذا الفصل حتى الآن.',
			'admin.groupes.actionAjouter' => 'إضافة طالب',
			'admin.groupes.actionRetirer' => 'إزالة',
			'admin.groupes.actionModifierSeuil' => 'تعديل الحد',
			'admin.groupes.actionObservation' => 'إعدادات المتابعة',
			'admin.groupes.actionCloturer' => 'إغلاق الفصل',
			'admin.groupes.ajouterTitre' => ({required Object libelle}) => 'إضافة طالب إلى ⁨${libelle}⁩',
			'admin.groupes.champEleveId' => 'معرّف الطالب',
			'admin.groupes.champMotif' => 'السبب',
			'admin.groupes.motifRequis' => 'السبب مطلوب، ويُدوَّن في سجل التدقيق.',
			'admin.groupes.ajouterEnvoyer' => 'إضافة',
			'admin.groupes.ajouterErreur' => ({required Object message}) => 'لم تكتمل الإضافة: ⁨${message}⁩',
			'admin.groupes.retirerTitre' => ({required Object prenom, required Object libelle}) => 'إزالة ⁨${prenom}⁩ من ⁨${libelle}⁩',
			'admin.groupes.retirerEnvoyer' => 'إزالة',
			'admin.groupes.retirerErreur' => ({required Object message}) => 'لم تكتمل الإزالة: ⁨${message}⁩',
			'admin.groupes.modifierSeuilTitre' => ({required Object libelle}) => 'الحد الأقصى لـ⁨${libelle}⁩',
			'admin.groupes.modifierSeuilEnvoyer' => 'حفظ',
			'admin.groupes.modifierSeuilErreur' => ({required Object message}) => 'لم يكتمل التعديل: ⁨${message}⁩',
			'admin.groupes.cloturerTitre' => ({required Object libelle}) => 'إغلاق ⁨${libelle}⁩',
			'admin.groupes.cloturerDetail' => 'سيُزال كل الأعضاء النشطين من الفصل. لا يمكن التراجع عن هذا الإجراء.',
			'admin.groupes.cloturerEnvoyer' => 'إغلاق',
			'admin.groupes.cloturerErreur' => ({required Object message}) => 'لم يكتمل الإغلاق: ⁨${message}⁩',
			'admin.groupes.journalisation' => 'يُدوَّن كل إنشاء وإضافة وإزالة وإغلاق في سجل التدقيق.',
			'admin.groupes.observationTitre' => ({required Object libelle}) => 'المتابعة: ⁨${libelle}⁩',
			'admin.groupes.observationErreur' => 'تعذّر حفظ الإعداد.',
			'admin.groupes.observationCapaciteAbsente' => 'هذا التثبيت لا يملك بعد تحديث الخادم الذي يتطلبه هذا الإعداد (الترحيل 0036). إعادة المحاولة لن تغيّر شيئًا: يجب تطبيقه أولًا على قاعدة البيانات.',
			'admin.diagnostics.titre' => 'تحديد المستوى',
			'admin.diagnostics.intro' => 'ينتظر كل طالب مسجَّل مستوى أول قبل الانضمام إلى فصل: هنا يُقرَّر هذا التوجيه.',
			'admin.diagnostics.aucunProgramme' => 'لا منهج منشور',
			'admin.diagnostics.aucunProgrammeDetail' => 'انشر إصدارًا أول من المنهج («التعليم» > «المناهج») قبل أن تتمكن من تقرير توجيه.',
			'admin.diagnostics.erreur' => 'تعذّرت قراءة القائمة. أعد المحاولة بعد لحظة.',
			'admin.diagnostics.restants' => ({required Object n}) => '⁨${n}⁩ طلاب متبقون',
			'admin.diagnostics.restantUn' => 'طالب واحد متبقٍ',
			'admin.diagnostics.inscritAujourdhui' => 'مسجَّل اليوم',
			_ => null,
		} ?? switch (path) {
			'admin.diagnostics.inscritDepuisUnJour' => 'مسجَّل منذ يوم',
			'admin.diagnostics.inscritDepuis' => ({required Object jours}) => 'مسجَّل منذ ⁨${jours}⁩ أيام',
			'admin.diagnostics.aucun' => 'لا طالب لتحديد مستواه',
			'admin.diagnostics.aucunDetail' => 'لكل الطلاب المسجلين مستوى مقرر بالفعل.',
			'admin.diagnostics.champNiveau' => 'مستوى التوجيه',
			'admin.diagnostics.champMotif' => 'السبب',
			'admin.diagnostics.motifRequis' => 'السبب مطلوب، ويُدوَّن في سجل التدقيق.',
			'admin.diagnostics.decider' => 'تقرير التوجيه',
			'admin.diagnostics.deciderErreur' => ({required Object message}) => 'لم يكتمل القرار: ⁨${message}⁩',
			'admin.diagnostics.journalisation' => 'يُدوَّن كل توجيه مقرر في سجل التدقيق.',
			'admin.qualite.titre' => 'الجودة',
			'admin.qualite.intro' => 'الخلل التعليمي المكتشف: تقارير ناقصة، عوائق دون متابعة، تقييمات متأخرة.',
			'admin.qualite.erreur' => 'تعذّرت قراءة حالات الخلل. أعد المحاولة بعد لحظة.',
			'admin.qualite.aucune' => 'لا خلل مكتشف',
			'admin.qualite.aucuneDetail' => 'كل شيء محدَّث: التقارير محررة، والعوائق متابَعة، والتقييمات في موعدها.',
			'admin.qualite.filtreToutes' => 'الكل',
			'admin.qualite.filtreOuvertes' => 'مفتوحة',
			'admin.qualite.filtreTraitees' => 'معالَجة',
			'admin.qualite.groupeRapportManquant' => 'تقارير حصص ناقصة',
			'admin.qualite.groupeBlocageSansSuivi' => 'عوائق دون متابعة',
			'admin.qualite.groupeEvaluationEnRetard' => 'تقييمات متأخرة',
			'admin.qualite.colonnePersonne' => 'يخص',
			'admin.qualite.colonneDepuis' => 'منذ',
			'admin.qualite.colonneStatut' => 'الحالة',
			'admin.qualite.statutOuvert' => 'مفتوحة',
			'admin.qualite.statutTraite' => 'معالَجة',
			'admin.qualite.depuisAujourdhui' => 'اليوم',
			'admin.qualite.depuisUnJour' => 'يوم واحد',
			'admin.qualite.depuisJours' => ({required Object jours}) => '⁨${jours}⁩ أيام',
			'admin.qualite.actionTraiter' => 'تعليم كمعالَج',
			'admin.qualite.traiterTitre' => ({required Object personne}) => 'تعليم كمعالَج: ⁨${personne}⁩',
			'admin.qualite.champNote' => 'ملاحظة (اختيارية)',
			'admin.qualite.traiterEnvoyer' => 'تعليم كمعالَج',
			'admin.qualite.traiterErreur' => ({required Object message}) => 'لم تكتمل المعالجة: ⁨${message}⁩',
			'admin.regles.titre' => 'القواعد',
			'admin.regles.intro' => 'القيم الافتراضية للمنصة كلها. يُوضع الاستثناء لملف محدد من «العمليات» > «القواعد الفردية»، وأبدًا من هنا.',
			'admin.regles.erreur' => 'تعذّرت قراءة القواعد. أعد المحاولة بعد لحظة.',
			'admin.regles.erreurEcriture' => ({required Object message}) => 'لم يكتمل الحفظ: ⁨${message}⁩',
			'admin.regles.valeurInvalide' => 'أدخل رقمًا صالحًا.',
			'admin.regles.envoyer' => 'حفظ',
			'admin.regles.champValeur' => 'القيمة',
			'admin.regles.absenceSeuil' => 'حد الغياب',
			'admin.regles.absenceSeuilDetail' => 'بعد هذا العدد من الدقائق دون الانضمام إلى الحصة، يُسجَّل الطالب غائبًا.',
			'admin.regles.dureeSeance' => 'مدة الحصة',
			'admin.regles.dureeSeanceDetail' => 'المدة الافتراضية للحصة، قبل أي استثناء فردي.',
			'admin.regles.dureeMinimalePayee' => 'المدة الدنيا المدفوعة',
			'admin.regles.dureeMinimalePayeeDetail' => 'دون هذه المدة، تبقى الحصة المختصرة مدفوعة كاملة.',
			'admin.regles.pauseEntreSeances' => 'الاستراحة بين حصتين',
			'admin.regles.pauseEntreSeancesDetail' => 'الوقت الأدنى المتروك للمعلم بين حصتين متتاليتين.',
			'admin.regles.elevesParEnseignant' => 'الطلاب لكل معلم',
			'admin.regles.elevesParEnseignantDetail' => 'العدد الأقصى للطلاب الذين يمكن لمعلم متابعتهم في آن واحد.',
			'admin.regles.horizonAffectation' => 'أفق الإسناد',
			'admin.regles.horizonAffectationDetail' => 'عدد الأسابيع مسبقًا التي يبحث فيها الإسناد عن معلم متاح.',
			'admin.regles.ageCameraAuto' => 'العمر الأدنى للكاميرا التلقائية',
			'admin.regles.ageCameraAutoDetail' => 'دون هذا العمر، يبقى تشغيل الكاميرا خاضعًا لموافقة وليّ الأمر.',
			'admin.regles.ageInterfaceEnfant' => 'العمر الأقصى لواجهة الطفل',
			'admin.regles.ageInterfaceEnfantDetail' => 'دون هذا العمر، ينتقل الملف إلى الواجهة المبسطة عند إنشائه.',
			'admin.regles.appareilsParEleve' => 'الأجهزة لكل طالب',
			'admin.regles.appareilsParEleveDetail' => 'عدد الأجهزة التي يمكن أن تكون نشطة لطالب في الوقت نفسه.',
			'admin.regles.seancesSimultanees' => 'الحصص المتزامنة لكل ملف',
			'admin.regles.seancesSimultaneesDetail' => 'عدد الحصص التي يمكن لملف واحد متابعتها في الوقت نفسه.',
			'admin.regles.uniteMinutes' => ({required Object n}) => '⁨${n}⁩ دقيقة',
			'admin.regles.uniteSemaines' => ({required Object n}) => '⁨${n}⁩ أسبوع',
			'admin.regles.uniteNombre' => ({required Object n}) => '⁨${n}⁩',
			'admin.fonctionnalites.titre' => 'الوظائف',
			'admin.fonctionnalites.intro' => 'الوظائف التي تغيّر سلوك المنصة كلها.',
			'admin.fonctionnalites.erreur' => 'تعذّرت قراءة الوظائف. أعد المحاولة بعد لحظة.',
			'admin.fonctionnalites.erreurEcriture' => ({required Object message}) => 'لم يكتمل الحفظ: ⁨${message}⁩',
			'admin.fonctionnalites.valeurInvalide' => 'أدخل رقمًا صالحًا.',
			'admin.fonctionnalites.envoyer' => 'حفظ',
			'admin.fonctionnalites.champValeur' => 'القيمة',
			'admin.fonctionnalites.multiParticipants' => 'حصص متعددة المشاركين',
			'admin.fonctionnalites.multiParticipantsDetail' => 'يسمح بعدة طلاب في حصة الفيديو نفسها.',
			'admin.fonctionnalites.participantsMax' => 'الحد الأقصى للمشاركين',
			'admin.fonctionnalites.participantsMaxDetail' => 'عدد المشاركين المسموح به حين تكون الحصص متعددة المشاركين مفعَّلة.',
			'admin.fonctionnalites.uniteNombre' => ({required Object n}) => '⁨${n}⁩',
			'admin.conservationDonnees.titre' => 'الاحتفاظ بالبيانات',
			'admin.conservationDonnees.intro' => 'المدة التي تبقى فيها هذه العناصر متاحة قبل حذفها التلقائي.',
			'admin.conservationDonnees.erreur' => 'تعذّرت قراءة مدد الاحتفاظ. أعد المحاولة بعد لحظة.',
			'admin.conservationDonnees.erreurEcriture' => ({required Object message}) => 'لم يكتمل الحفظ: ⁨${message}⁩',
			'admin.conservationDonnees.valeurInvalide' => 'أدخل رقمًا صالحًا.',
			'admin.conservationDonnees.envoyer' => 'حفظ',
			'admin.conservationDonnees.champValeur' => 'القيمة',
			'admin.conservationDonnees.enregistrements' => 'تسجيلات الحصص',
			'admin.conservationDonnees.enregistrementsDetail' => 'عدد الأيام التي يبقى فيها تسجيل الحصة متاحًا.',
			'admin.conservationDonnees.documentsIdentite' => 'وثائق الهوية',
			'admin.conservationDonnees.documentsIdentiteDetail' => 'عدد الأيام التي تبقى فيها وثيقة الهوية المودعة متاحة قبل حذفها.',
			'admin.conservationDonnees.uniteJours' => ({required Object n}) => '⁨${n}⁩ ي',
			'admin.politiqueRevueKyc.titre' => 'سياسة الجنس في مراجعة الهوية',
			'admin.politiqueRevueKyc.libelle' => 'حصر مراجعة الهوية حسب الجنس',
			'admin.politiqueRevueKyc.aide' => 'حين تُعطَّل هذه القاعدة، يمكن لكل عضو مخوَّل بمراجعة الملفات معالجة ملفات نطاقه، أيًا كان جنسه.',
			'admin.politiqueRevueKyc.echecEnregistrement' => _root.admin.groupes.observationErreur,
			'admin.evaluations.titre' => 'التقييمات',
			'admin.evaluations.intro' => 'ما هو مقرر، وما أُجري، والشهادات المحصَّلة.',
			'admin.evaluations.erreur' => 'تعذّرت قراءة التقييمات. أعد المحاولة بعد لحظة.',
			'admin.evaluations.aucune' => 'لا تقييم',
			'admin.evaluations.aucuneDetail' => 'برمج تقييمًا أول لطالب حُدِّد مستواه بالفعل.',
			'admin.evaluations.aucuneAvecCeFiltre' => 'لا تقييم بهذا المعيار',
			'admin.evaluations.aucuneAvecCeFiltreDetail' => 'غيّر المعيار لترى التقييمات الأخرى.',
			'admin.evaluations.filtreToutes' => 'الكل',
			'admin.evaluations.filtrePlanifiees' => 'مبرمجة',
			'admin.evaluations.filtreRealisees' => 'منجزة',
			'admin.evaluations.filtreAnnulees' => 'ملغاة',
			'admin.evaluations.filtreCertifications' => 'الشهادات',
			'admin.evaluations.colonneEleve' => 'الطالب',
			'admin.evaluations.colonneNiveau' => 'المستوى',
			'admin.evaluations.colonneType' => 'النوع',
			'admin.evaluations.colonneDatePrevue' => 'مقرر في',
			'admin.evaluations.colonneStatut' => 'الحالة',
			'admin.evaluations.colonneResultat' => 'النتيجة',
			'admin.evaluations.typeInitiale' => 'أولي',
			'admin.evaluations.typePeriodique' => 'دوري',
			'admin.evaluations.typeReevaluation' => 'إعادة تقييم',
			'admin.evaluations.typeCertification' => 'شهادة',
			'admin.evaluations.statutPlanifiee' => 'مبرمج',
			'admin.evaluations.statutRealisee' => 'منجز',
			'admin.evaluations.statutAnnulee' => 'ملغى',
			'admin.evaluations.resultatReussi' => 'ناجح',
			'admin.evaluations.resultatEchec' => 'راسب',
			'admin.evaluations.resultatARevoir' => 'للمراجعة',
			'admin.evaluations.planifier' => 'برمجة تقييم',
			'admin.evaluations.planifierTitre' => 'برمجة تقييم',
			'admin.evaluations.champEleveId' => 'معرّف الطالب',
			'admin.evaluations.champNiveau' => 'المستوى المقيَّم',
			'admin.evaluations.champType' => 'النوع',
			'admin.evaluations.champDatePrevue' => 'التاريخ المقرر (يوم/شهر/سنة)',
			'admin.evaluations.planifierEnvoyer' => 'برمجة',
			'admin.evaluations.planifierErreur' => ({required Object message}) => 'لم تكتمل البرمجة: ⁨${message}⁩',
			'admin.evaluations.actionEnregistrerResultat' => 'حفظ النتيجة',
			'admin.evaluations.actionAnnuler' => 'إلغاء التقييم',
			'admin.evaluations.resultatTitre' => ({required Object eleve}) => 'نتيجة ⁨${eleve}⁩',
			'admin.evaluations.champNotes' => 'ملاحظات (اختيارية)',
			'admin.evaluations.resultatEnvoyer' => 'حفظ',
			'admin.evaluations.resultatErreur' => ({required Object message}) => 'لم يكتمل الحفظ: ⁨${message}⁩',
			'admin.evaluations.annulerTitre' => ({required Object eleve}) => 'إلغاء تقييم ⁨${eleve}⁩',
			'admin.evaluations.annulerEnvoyer' => 'إلغاء',
			'admin.evaluations.annulerErreur' => ({required Object message}) => 'لم يكتمل الإلغاء: ⁨${message}⁩',
			'admin.evaluations.champMotif' => 'السبب',
			'admin.evaluations.motifRequis' => 'السبب مطلوب، ويُدوَّن في سجل التدقيق.',
			'admin.evaluations.journalisation' => 'تُدوَّن كل برمجة ونتيجة وإلغاء في سجل التدقيق.',
			'admin.progression.titre' => 'التقدم',
			'admin.progression.intro' => 'المستوى الحالي لكل طالب، وفصله، والعوائق أو الاستثناءات الجارية.',
			'admin.progression.erreur' => 'تعذّرت قراءة التقدم. أعد المحاولة بعد لحظة.',
			'admin.progression.aucun' => 'لا طالب نشط',
			'admin.progression.aucunDetail' => 'سيظهر الطلاب هنا بمجرد أول تحديد لمستواهم.',
			'admin.progression.colonneEleve' => 'الطالب',
			'admin.progression.colonneGroupe' => 'الفصل',
			'admin.progression.colonneNiveau' => 'المستوى',
			'admin.progression.colonneDepuis' => 'منذ',
			'admin.progression.colonneException' => 'الاستثناء',
			'admin.progression.sansGroupe' => 'دون فصل',
			'admin.progression.sansNiveau' => 'لم يُحدَّد مستواه',
			'admin.progression.filtreTousCycles' => 'كل المراحل',
			'admin.progression.depuisAujourdhui' => 'اليوم',
			'admin.progression.depuisUnJour' => 'يوم واحد',
			'admin.progression.depuisJours' => ({required Object jours}) => '⁨${jours}⁩ أيام',
			'admin.progression.typeBlocage' => 'عائق',
			'admin.progression.typeDerogation' => 'استثناء',
			'admin.progression.actionPoserBlocage' => 'وضع عائق',
			'admin.progression.actionPoserDerogation' => 'وضع استثناء',
			'admin.progression.actionCloreException' => 'إغلاق الاستثناء',
			'admin.progression.actionPromouvoir' => 'تغيير المستوى',
			'admin.progression.poserExceptionTitre' => ({required Object type, required Object eleve}) => '⁨${type}⁩ لـ⁨${eleve}⁩',
			'admin.progression.poserExceptionEnvoyer' => 'وضع الاستثناء',
			'admin.progression.poserExceptionErreur' => ({required Object message}) => 'لم يكتمل الوضع: ⁨${message}⁩',
			'admin.progression.clorerExceptionTitre' => ({required Object eleve}) => 'إغلاق استثناء ⁨${eleve}⁩',
			'admin.progression.clorerExceptionEnvoyer' => 'إغلاق',
			'admin.progression.clorerExceptionErreur' => ({required Object message}) => 'لم يكتمل الإغلاق: ⁨${message}⁩',
			'admin.progression.promouvoirTitre' => ({required Object eleve}) => 'تغيير مستوى ⁨${eleve}⁩',
			'admin.progression.promouvoirChampNiveau' => 'المستوى الجديد',
			'admin.progression.promouvoirEnvoyer' => 'حفظ',
			'admin.progression.promouvoirErreur' => ({required Object message}) => 'لم يكتمل التغيير: ⁨${message}⁩',
			'admin.progression.champMotif' => 'السبب',
			'admin.progression.motifRequis' => 'السبب مطلوب، ويُدوَّن في سجل التدقيق.',
			'admin.progression.journalisation' => 'يُدوَّن كل استثناء موضوع ومغلق، وكل تغيير مستوى، في سجل التدقيق.',
			'admin.programmes.titre' => 'المناهج',
			'admin.programmes.intro' => 'منهج Rewayah، بإصدارات: الإصدار المنشور لا يُعدَّل، وكل تطور أكاديمي ينشئ إصدارًا جديدًا.',
			'admin.programmes.aucuneVersion' => 'لا إصدار من المنهج',
			'admin.programmes.aucuneVersionDetail' => 'أنشئ الإصدار الأول، كمسودة، لتبدأ بإضافة المستويات إليه.',
			'admin.programmes.erreur' => 'تعذّرت قراءة المنهج. أعد المحاولة بعد لحظة.',
			'admin.programmes.statutBrouillon' => 'مسودة',
			'admin.programmes.statutPubliee' => 'منشور',
			'admin.programmes.statutArchivee' => 'مؤرشف',
			'admin.programmes.versionNumero' => ({required Object numero}) => 'الإصدار ⁨${numero}⁩',
			'admin.programmes.niveauxSur' => ({required Object nombre}) => '⁨${nombre}⁩ مستويات',
			'admin.programmes.creerVersion' => 'إنشاء إصدار',
			'admin.programmes.creerVersionVide' => 'إنشاء إصدار فارغ',
			'admin.programmes.enregistrerVersion' => 'حفظ الإصدار',
			'admin.programmes.creerVersionDepuisPubliee' => 'إنشاء إصدار جديد انطلاقًا من هذا',
			'admin.programmes.creerVersionErreur' => ({required Object message}) => 'لم يكتمل الإنشاء: ⁨${message}⁩',
			'admin.programmes.niveauxTitre' => 'المستويات',
			'admin.programmes.niveauAucun' => 'لا مستوى في هذا الإصدار',
			'admin.programmes.niveauAucunDetail' => 'أضف مستوى أول لتبدأ بتكوين هذا الإصدار.',
			'admin.programmes.codeTechnique' => ({required Object code}) => 'الرمز: ⁨${code}⁩',
			'admin.programmes.ajouterNiveau' => 'إضافة مستوى',
			'admin.programmes.ajouterNiveauTitre' => ({required Object version}) => 'إضافة مستوى إلى ⁨${version}⁩',
			'admin.programmes.ajouterNiveauEnvoyer' => 'إضافة',
			'admin.programmes.ajouterNiveauErreur' => ({required Object message}) => 'لم تكتمل الإضافة: ⁨${message}⁩',
			'admin.programmes.modifierNiveau' => 'تعديل',
			'admin.programmes.modifierNiveauTitre' => ({required Object nom}) => 'تعديل ⁨${nom}⁩',
			'admin.programmes.modifierNiveauEnvoyer' => 'حفظ',
			'admin.programmes.modifierNiveauErreur' => ({required Object message}) => 'لم يكتمل التعديل: ⁨${message}⁩',
			'admin.programmes.supprimerNiveau' => 'حذف',
			'admin.programmes.supprimerNiveauTitre' => ({required Object nom}) => 'حذف ⁨${nom}⁩',
			'admin.programmes.supprimerNiveauEnvoyer' => 'حذف',
			'admin.programmes.supprimerNiveauErreur' => ({required Object message}) => 'لم يكتمل الحذف: ⁨${message}⁩',
			'admin.programmes.publierVersion' => 'نشر الإصدار',
			'admin.programmes.publierVersionTitre' => ({required Object version}) => 'نشر ⁨${version}⁩',
			'admin.programmes.publierVersionDetail' => 'بعد نشره، لا يمكن تعديل هذا الإصدار. كل تطور أكاديمي سينشئ إصدارًا جديدًا.',
			'admin.programmes.publierVersionEnvoyer' => 'نشر',
			'admin.programmes.publierVersionErreur' => ({required Object message}) => 'لم يكتمل النشر: ⁨${message}⁩',
			'admin.programmes.champCodeTechnique' => 'الرمز التقني (استخدام داخلي، لا يُعرض للطالب أبدًا)',
			'admin.programmes.champNomHumain' => 'الاسم المعروض',
			'admin.programmes.champCycle' => 'المرحلة',
			'admin.programmes.champOrdre' => 'الترتيب',
			'admin.programmes.champDescription' => 'الوصف (اختياري)',
			'admin.programmes.champMotif' => 'السبب',
			'admin.programmes.motifRequis' => 'السبب مطلوب، ويُدوَّن في سجل التدقيق.',
			'admin.programmes.journalisation' => 'يُدوَّن كل إنشاء وتعديل وحذف ونشر في سجل التدقيق.',
			'admin.journal.titre' => 'السجل',
			'admin.journal.chaineIntacte' => 'السجل سليم',
			'admin.journal.chaineIntacteDetail' => ({required Object nombre}) => 'أُعيدت قراءة ⁨${nombre}⁩ مدخلًا واحدًا واحدًا: لم يُعدَّل أي منها ولم يُحذف منذ كتابته.',
			'admin.journal.chaineRompue' => 'السجل معدَّل',
			'admin.journal.chaineRompueUne' => ({required Object entree}) => 'مدخل لم يعد يطابق بصمته، رقم ⁨${entree}⁩. شيء ما مسّ قاعدة البيانات من خارج التطبيق.',
			'admin.journal.chaineRompueDetail' => ({required Object nombre, required Object entree}) => '⁨${nombre}⁩ مدخلات لم تعد تطابق بصمتها، ابتداءً من الرقم ⁨${entree}⁩. شيء ما مسّ قاعدة البيانات من خارج التطبيق.',
			'admin.journal.chaineInconnue' => 'السلامة غير معروفة',
			'admin.journal.chaineInconnueDetail' => 'لم يكتمل التحقق. تبقى المدخلات أدناه مقروءة، لكن لا شيء يضمن الآن أنها كاملة.',
			'admin.journal.chaineEnCours' => 'جارٍ التحقق',
			'admin.journal.chaineEnCoursDetail' => 'إعادة قراءة بصمة كل مدخل.',
			'admin.journal.periodeSemaine' => 'آخر 7 أيام',
			'admin.journal.periodeMois' => 'آخر 30 يومًا',
			'admin.journal.periodeTout' => 'منذ البداية',
			'admin.journal.tousTypes' => 'كل الأحداث',
			'admin.journal.tousActeurs' => 'الجميع',
			'admin.journal.colonneQuand' => 'متى',
			'admin.journal.colonneQui' => 'من',
			'admin.journal.colonneRole' => 'بأي صفة',
			'admin.journal.colonneQuoi' => 'ما الذي فُعل',
			'admin.journal.colonneCible' => 'على ماذا',
			'admin.journal.colonneDetail' => 'التفاصيل',
			'admin.journal.horodatage' => ({required Object date, required Object heure}) => '⁨${date}⁩ الساعة ⁨${heure}⁩',
			'admin.journal.acteurSysteme' => 'النظام',
			'admin.journal.acteurInconnu' => 'حساب محذوف',
			'admin.journal.roleAdmin' => 'الإدارة',
			'admin.journal.roleEnseignant' => 'معلم',
			'admin.journal.roleTuteur' => 'وليّ أمر',
			'admin.journal.roleEleve' => 'طالب',
			'admin.journal.roleControleur' => 'مراقب',
			'admin.journal.roleComptable' => 'محاسب',
			'admin.journal.roleAucun' => 'خارج الجلسة',
			'admin.journal.evtKycLu' => 'اطُّلع على ملف الهوية',
			'admin.journal.evtKycTranche' => 'حُسم ملف الهوية',
			'admin.journal.evtProfilCree' => 'أُنشئ ملف',
			'admin.journal.evtProfilEnfantCree' => 'أُنشئ ملف طفل',
			'admin.journal.evtCodeCree' => 'أُنشئ رمز ربط',
			'admin.journal.evtAppareilAppaire' => 'رُبط جهاز',
			'admin.journal.evtAppareilRevoque' => 'أُلغي جهاز',
			'admin.journal.evtPedagogie' => 'عُدِّلت الإعدادات التعليمية',
			'admin.journal.evtAffectationPrise' => 'قبل معلم طالبًا',
			'admin.journal.evtAffectationAttribuee' => 'أسندت الإدارة طالبًا',
			'admin.journal.evtDemandeCreee' => 'قُدِّم طلب',
			'admin.journal.evtDemandeTranchee' => 'حُسم طلب',
			'admin.journal.evtReglePosee' => 'وُضعت قاعدة',
			'admin.journal.evtRegleClose' => 'أُغلقت قاعدة',
			'admin.journal.filtreEvenement' => 'الحدث',
			'admin.journal.filtreActeur' => 'الفاعل',
			'admin.journal.evtAgentJetonEmis' => 'صدر وصول وكيل آلي',
			'admin.journal.evtAgentJetonRevoque' => 'أُلغي وصول وكيل آلي',
			'admin.journal.evtAgentSessionOuverte' => 'فُتحت جلسة وكيل آلي',
			'admin.journal.evtObservationControleur' => 'بدأت زيارة مراقبة',
			'admin.journal.evtJetonVideo' => 'سُمح بالدخول إلى القاعة',
			'admin.journal.vide' => 'لا حدث مسجَّل',
			'admin.journal.videDetail' => 'ستُدوَّن هنا كل قراءة لملف، وكل قرار، وكل إسناد.',
			'admin.journal.videFiltre' => 'لا حدث مطابق',
			'admin.journal.videFiltreDetail' => 'وسّع الفترة، أو خفّف أحد المعايير.',
			'admin.journal.effacerFiltres' => 'مسح المعايير',
			'admin.journal.erreur' => 'تعذّرت قراءة السجل. أعد المحاولة بعد لحظة.',
			'admin.journal.erreurSuite' => 'تعذّرت قراءة المدخلات الأقدم.',
			'admin.journal.chargerSuite' => 'تحميل المدخلات الأقدم',
			'admin.journal.fin' => 'وصلت إلى أول مدخل في السجل.',
			'admin.journal.evenements.observationEntree' => 'بدأت زيارة متابعة',
			'admin.journal.evenements.observationSortie' => 'انتهت زيارة متابعة',
			'admin.journal.evenements.observationPolitiqueGroupeModifiee' => 'عُدِّلت قواعد متابعة الفصل',
			'admin.observations.titre' => 'المتابعات',
			'admin.observations.titrePage' => 'سجل المتابعات',
			'admin.observations.sousTitre' => 'الإدارة',
			'admin.observations.recherche' => 'البحث عن وليّ أمر أو طالب',
			'admin.observations.rechercheCourte' => 'أدخل حرفين على الأقل.',
			'admin.observations.rechercheAucune' => 'لا وليّ أمر ولا طالب بهذا الاسم.',
			'admin.observations.rechercheErreur' => 'لم يكتمل البحث. أعد المحاولة.',
			'admin.observations.roleTuteur' => 'وليّ أمر',
			'admin.observations.roleEleve' => 'طالب',
			'admin.observations.filtreTuteur' => ({required Object nom}) => 'وليّ الأمر: ⁨${nom}⁩',
			'admin.observations.filtreEleve' => ({required Object nom}) => 'الطالب: ⁨${nom}⁩',
			'admin.observations.retirerFiltre' => ({required Object filtre}) => 'إزالة المعيار ⁨${filtre}⁩',
			'admin.observations.classe' => 'الفصل',
			'admin.observations.toutesClasses' => 'كل الفصول',
			'admin.observations.periode' => 'الفترة',
			'admin.observations.statut' => 'الحالة',
			'admin.observations.tousStatuts' => 'كل الحالات',
			'admin.observations.colonneDate' => 'التاريخ',
			'admin.observations.colonneTuteur' => 'وليّ الأمر',
			'admin.observations.colonneEleve' => 'الطالب',
			'admin.observations.colonneClasse' => 'الفصل',
			'admin.observations.colonneEntree' => 'الدخول',
			'admin.observations.colonneSortie' => 'الخروج',
			'admin.observations.colonneDuree' => 'المدة',
			'admin.observations.colonneStatut' => 'الحالة',
			'admin.observations.terminee' => 'منتهية',
			'admin.observations.ouverte' => 'الخروج غير مسجَّل',
			'admin.observations.sortieAbsente' => 'غير مسجَّل',
			'admin.observations.dureeNonConfirmee' => 'غير مؤكَّدة',
			'admin.observations.nomInconnu' => 'الاسم غير متاح',
			'admin.observations.classeInconnue' => 'الفصل غير متاح',
			'admin.observations.plage' => ({required Object entree, required Object sortie}) => '⁨${entree}⁩ - ⁨${sortie}⁩',
			'admin.observations.ligne' => ({required Object rang, required Object date, required Object tuteur, required Object eleve, required Object classe, required Object entree, required Object sortie, required Object duree, required Object statut}) => 'الزيارة ⁨${rang}⁩ في ⁨${date}⁩، ⁨${tuteur}⁩ لـ⁨${eleve}⁩، ⁨${classe}⁩، الدخول ⁨${entree}⁩، الخروج ⁨${sortie}⁩، المدة ⁨${duree}⁩، ⁨${statut}⁩',
			'admin.observations.fuseau' => ({required Object decalage}) => 'الساعات معروضة بتوقيت هذا الجهاز (UTC⁨${decalage}⁩).',
			'admin.observations.indisponibleTitre' => 'سجل المتابعات غير متاح',
			'admin.observations.indisponiblePhrase' => 'قراءة زيارات المتابعة غير مفتوحة في التطبيق بعد.',
			'admin.observations.videTitre' => 'لا زيارة مسجَّلة',
			'admin.observations.videPhrase' => 'ستظهر هنا زيارات متابعة أولياء الأمور.',
			'admin.observations.videFiltreTitre' => 'لا زيارة مطابقة',
			'admin.observations.videFiltrePhrase' => 'وسّع الفترة أو أزل أحد المعايير.',
			'admin.observations.effacerFiltres' => 'مسح المعايير',
			'admin.observations.chargerSuite' => 'تحميل الزيارات الأقدم',
			'admin.observations.erreurSuite' => 'تعذّرت قراءة الزيارات الأقدم.',
			'admin.observations.fin' => 'كل الزيارات معروضة.',
			'admin.comptes.titre' => 'الحسابات',
			'admin.comptes.intro' => 'كل الأشخاص المسجلين، والذين ينتظرون قرارًا أولًا. المعلم الذي لم يودع وثيقة هويته يبقى ظاهرًا هنا: إنه المكان الوحيد الذي يُظهره.',
			'admin.comptes.attenteUneAujourdhui' => 'شخص واحد ينتظر قرارًا، مسجَّل اليوم.',
			'admin.comptes.attenteUneUnJour' => 'شخص واحد ينتظر قرارًا منذ يوم.',
			'admin.comptes.attenteUne' => ({required Object jours}) => 'شخص واحد ينتظر قرارًا منذ ⁨${jours}⁩ أيام.',
			'admin.comptes.attentePlusieurs' => ({required Object nombre}) => '⁨${nombre}⁩ أشخاص ينتظرون قرارًا.',
			'admin.comptes.filtreTousEtats' => 'الكل',
			'admin.comptes.filtreTousRoles' => 'كل الأدوار',
			'admin.comptes.filtreRole' => 'الدور',
			'admin.comptes.aucunAvecCeFiltre' => 'لا حساب بهذا المعيار',
			'admin.comptes.aucunAvecCeFiltreDetail' => 'أزل أحد المعايير لتوسيع القائمة.',
			'admin.comptes.erreur' => 'تعذّرت قراءة الحسابات. أعد المحاولة بعد لحظة.',
			'admin.comptes.colonnePersonne' => 'الشخص',
			'admin.comptes.colonneIdentifiant' => 'المعرّف',
			'admin.comptes.colonneRole' => 'الدور',
			'admin.comptes.colonneEtat' => 'الحالة',
			'admin.comptes.colonnePiece' => 'وثيقة الهوية',
			'admin.comptes.colonneAttente' => 'مسجَّل منذ',
			'admin.comptes.colonneContrats' => 'العقود',
			'admin.comptes.etatEnAttente' => 'قيد الانتظار',
			'admin.comptes.etatActif' => 'نشط',
			'admin.comptes.etatProvisoire' => 'مؤقت',
			'admin.comptes.etatSuspendu' => 'موقوف',
			'admin.comptes.etatInconnu' => 'حالة غير معروفة',
			'admin.comptes.roleAdmin' => 'الإدارة',
			'admin.comptes.roleComptable' => 'محاسب',
			'admin.comptes.roleControleur' => 'مراقب',
			'admin.comptes.roleEnseignant' => 'معلم',
			'admin.comptes.roleTuteur' => 'وليّ أمر',
			'admin.comptes.roleEleve' => 'طالب',
			'admin.comptes.roleInconnu' => 'دور غير معروف',
			'admin.comptes.pieceAucune' => 'لا وثيقة مودَعة',
			'admin.comptes.pieceAVerifier' => 'للتحقق',
			'admin.comptes.pieceValidee' => 'معتمَدة',
			'admin.comptes.pieceRefusee' => 'مرفوضة',
			'admin.comptes.pieceNonVisible' => 'خارج صلاحيتك',
			'admin.comptes.pieceSansObjet' => 'لا ينطبق',
			'admin.comptes.attendAujourdhui' => 'اليوم',
			'admin.comptes.attendUnJour' => 'يوم واحد',
			'admin.comptes.attendJours' => ({required Object jours}) => '⁨${jours}⁩ أيام',
			'admin.agents.titre' => 'وصول الوكلاء الآليين',
			'admin.agents.intro' => 'يسمح الرمز لوكيل آلي بفتح التطبيق وقراءة ما يقرؤه شخص فيه. لا يستطيع كتابة شيء ولا إلغاء شيء ولا تعديل شيء: قاعدة البيانات تمنعه، لا الواجهة.',
			'admin.agents.emettre' => 'إصدار رمز',
			'admin.agents.libelle' => 'الغرض من هذا الرمز',
			'admin.agents.libelleAide' => 'إلزامي. الرمز دون اسم رمز لا يجرؤ أحد على إلغائه.',
			'admin.agents.libelleExemple' => 'مراجعة متابعة مريم',
			'admin.agents.qui' => 'من يتابعه الوكيل',
			'admin.agents.quiAide' => 'سيرى الوكيل شاشة هذا الشخص تمامًا، وسيكون مساره مساره.',
			'admin.agents.quiVide' => 'اختيار شخص',
			'admin.agents.chercher' => 'البحث عن اسم أو معرّف',
			'admin.agents.duree' => 'لكم من الوقت',
			'admin.agents.dureeHeure' => ({required Object nombre}) => '⁨${nombre}⁩ س',
			'admin.agents.dureePlafond' => 'أربع وعشرون ساعة على الأكثر، وقاعدة البيانات تتحقق من ذلك بنفسها.',
			'admin.agents.identite' => 'الأسماء',
			'admin.agents.identiteMasquee' => 'مخفية',
			'admin.agents.identiteMasqueeDetail' => 'يقرأ الوكيل المعرّفات (ELV-0042) بدل الأسماء. قاعدة البيانات هي التي تستبدلها: الاسم لا يخرج.',
			'admin.agents.identiteVisible' => 'ظاهرة',
			'admin.agents.identiteVisibleDetail' => 'يقرأ الوكيل الأسماء، كما يراها الشخص المتابَع.',
			'admin.agents.pourra' => 'سيستطيع',
			'admin.agents.pourraDetail' => 'فتح التطبيق والتنقل فيه وقراءة كل ما يقرؤه هذا الشخص.',
			'admin.agents.nePourraPas' => 'لن يستطيع',
			'admin.agents.nePourraPasDetail' => 'كتابة أي شيء، ولا رؤية وثيقة هوية، ولا جهاز، ولا سجل التدقيق، ولا الخروج من نطاق هذا الشخص.',
			'admin.agents.emissionEnCours' => 'جارٍ الإصدار',
			'admin.agents.emis' => 'صدر الرمز',
			'admin.agents.emisDetail' => 'سلّم هذا الرابط للوكيل. لن يظهر بعد ذلك: لا هذه الشاشة ولا قاعدة البيانات تستطيعان استعادته.',
			'admin.agents.copier' => 'نسخ الرابط',
			'admin.agents.copie' => 'نُسخ الرابط',
			'admin.agents.termine' => 'نسخت الرابط',
			'admin.agents.erreurEmission' => 'تعذّر إصدار الرمز. أعد المحاولة بعد لحظة.',
			'admin.agents.colonneLibelle' => 'الرمز',
			'admin.agents.colonneQui' => 'يتابع',
			'admin.agents.colonneParcours' => 'المسار',
			'admin.agents.colonneIdentite' => 'الأسماء',
			'admin.agents.colonneExpire' => 'حتى',
			'admin.agents.colonneUsage' => 'مرات الفتح',
			'admin.agents.colonneEtat' => 'الحالة',
			'admin.agents.parcoursEleve' => 'طالب',
			'admin.agents.parcoursTuteur' => 'وليّ أمر',
			'admin.agents.parcoursEnseignant' => 'معلم',
			'admin.agents.parcoursControleur' => 'مراقبة الجودة',
			'admin.agents.parcoursAdmin' => 'الإدارة',
			'admin.agents.parcoursComptable' => 'محاسب',
			'admin.agents.parcoursInconnu' => 'مسار غير معروف',
			'admin.agents.etatActif' => 'نشط',
			'admin.agents.etatRevoque' => 'ملغى',
			'admin.agents.etatExpire' => 'منتهي الصلاحية',
			'admin.agents.jamaisServi' => 'لم يُستخدم قط',
			'admin.agents.usage' => ({required Object nombre, required Object quand}) => '⁨${nombre}⁩ مرات، آخرها ⁨${quand}⁩',
			'admin.agents.revoquer' => 'إلغاء',
			'admin.agents.revoquerTitre' => 'إلغاء هذا الرمز؟',
			'admin.agents.revoquerDetail' => 'سيفقد الوكيل الوصول عند طلبه التالي. هذا نهائي: الرمز الملغى لا يُعاد تفعيله.',
			'admin.agents.revoquerConfirmer' => 'إلغاء',
			'admin.agents.annuler' => 'تراجع',
			'admin.agents.revoque' => 'أُلغي الرمز',
			'admin.agents.erreurRevocation' => 'لم يكتمل الإلغاء. أعد المحاولة.',
			'admin.agents.vide' => 'لا رمز متابعة',
			'admin.agents.videDetail' => 'لا وكيل آلي لديه وصول إلى التطبيق الآن.',
			'admin.agents.erreur' => 'تعذّرت قراءة قائمة الرموز.',
			'admin.notifications.titre' => 'الإشعارات',
			'admin.notifications.vide' => 'لا إشعارات',
			'admin.notifications.videDetail' => 'لا شيء يُذكر الآن.',
			_ => null,
		};
	}
}
