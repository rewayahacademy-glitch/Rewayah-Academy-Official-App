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
}

// Path: commun
class _Traductions$commun$ar extends Traductions$commun$fr {
	_Traductions$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$sections$ar sections = _Traductions$commun$sections$ar._(_root);
}

// Path: etat
class _Traductions$etat$ar extends Traductions$etat$fr {
	_Traductions$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enDirect => 'مباشر';
	@override String get seanceAnnulee => 'ملغاة';
	@override String annuleeValeur({required Object valeur}) => 'ملغاة : ${valeur}';
	@override String get motifNonCommunique => 'السبب غير متوفر';
	@override String get aucunRemplacantTrouve => 'لم يُعثر على بديل';
	@override String get seanceNonFacturee => 'الحصة غير مفوترة';
	@override String raisonEtSuite({required Object raison, required Object suite}) => '${raison} · ${suite}';
}

// Path: classe
class _Traductions$classe$ar extends Traductions$classe$fr {
	_Traductions$classe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$classe$entree$ar entree = _Traductions$classe$entree$ar._(_root);
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
}

// Path: enseignant
class _Traductions$enseignant$ar extends Traductions$enseignant$fr {
	_Traductions$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$enseignant$journee$ar journee = _Traductions$enseignant$journee$ar._(_root);
	@override late final _Traductions$enseignant$ficheGroupe$ar ficheGroupe = _Traductions$enseignant$ficheGroupe$ar._(_root);
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

// Path: commun.sections
class _Traductions$commun$sections$ar extends Traductions$commun$sections$fr {
	_Traductions$commun$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get page => 'أقسام الصفحة';
}

// Path: classe.entree
class _Traductions$classe$entree$ar extends Traductions$classe$entree$fr {
	_Traductions$classe$entree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String coursDans({required Object duree}) => 'الدرس بعد ${duree}';
	@override String get coursImminent => 'الدرس بعد أقل من دقيقة';
	@override String get rejoindre => 'انضمام';
	@override String rejoindreLecteur({required Object classe}) => 'الانضمام إلى حصة ${classe}';
	@override String salleOuverte({required Object duree}) => 'القاعة مفتوحة. تبدأ الحصة بعد ${duree}.';
	@override String get salleOuverteImminent => 'القاعة مفتوحة. تبدأ الحصة بعد أقل من دقيقة.';
	@override String get preparation => 'التحضير جارٍ';
	@override String attente({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ${duree}.';
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
	@override String progressionValeur({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage} %';
	@override String dst({required Object avant, required Object apres}) => 'تغيير التوقيت: سينتقل الدرس من ${avant} إلى ${apres}.';
	@override late final _Traductions$classe$entree$annonce$ar annonce = _Traductions$classe$entree$annonce$ar._(_root);
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
	@override String aujourdhui({required Object heure}) => 'اليوم، ${heure}';
	@override String hier({required Object heure}) => 'أمس، ${heure}';
	@override String date({required Object date, required Object heure}) => '${date}، ${heure}';
	@override String get annule => 'درس ملغى';
	@override String get nonTenu => 'درس لم يُعقد';
	@override String get vide => 'لا توجد دروس حتى الآن';
	@override String get videDetail => 'ستظهر دروسك هنا من الأحدث إلى الأقدم مع حالة حضورك.';
	@override String get erreur => 'تعذرت قراءة المتابعة. حاول مرة أخرى بعد قليل.';
	@override String tronquee({required Object nombre}) => 'تظهر أحدث ${nombre} دروس.';
	@override String fin({required Object nombre}) => 'عدد الدروس في المتابعة: ${nombre}.';
	@override String get finUn => 'درس واحد في المتابعة.';
}

// Path: enseignant.journee
class _Traductions$enseignant$journee$ar extends Traductions$enseignant$journee$fr {
	_Traductions$enseignant$journee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get derniereSeance => 'آخر حصة';
	@override String get rejoindreSalle => 'الدخول إلى القاعة';
	@override String rejoindreSalleLecteur({required Object classe}) => 'الدخول إلى قاعة الفصل ${classe}';
	@override String get remplirCahier => 'تعبئة دفتر المتابعة';
	@override String remplirCahierLecteur({required Object classe}) => 'تعبئة دفتر المتابعة للفصل ${classe}';
	@override String cahierObligatoire({required Object classe}) => 'إلزامي: يُعبَّأ دفتر ${classe} في نهاية كل حصة.';
	@override String voirCahier({required Object classe}) => 'عرض دفتر ${classe}';
	@override String voirCahierLecteur({required Object classe}) => 'عرض دفتر المتابعة للفصل ${classe}';
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
	@override String repriseEleve({required Object page}) => 'الاستئناف: ${page}';
	@override String dernierPoint({required Object texte}) => 'آخر ملاحظة: ${texte}';
	@override String get chargementClasse => 'جارٍ تحميل الفصل.';
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

// Path: classe.entree.annonce
class _Traductions$classe$entree$annonce$ar extends Traductions$classe$entree$annonce$fr {
	_Traductions$classe$entree$annonce$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aVenir => 'حصة قادمة';
	@override String get fenetreOuverte => 'القاعة مفتوحة';
	@override String get attente => 'أنت في القاعة';
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
	@override String get echec => 'تعذّر فتح هذه المادة.';
	@override String get echecDetail => 'تعذّر تحميل الملف. يبقى الفصل على المادة الحالية. أعد المحاولة، أو عد إلى المواد لاختيار مادة أخرى.';
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
			'etat.enDirect' => 'مباشر',
			'etat.seanceAnnulee' => 'ملغاة',
			'etat.annuleeValeur' => ({required Object valeur}) => 'ملغاة : ${valeur}',
			'etat.motifNonCommunique' => 'السبب غير متوفر',
			'etat.aucunRemplacantTrouve' => 'لم يُعثر على بديل',
			'etat.seanceNonFacturee' => 'الحصة غير مفوترة',
			'etat.raisonEtSuite' => ({required Object raison, required Object suite}) => '${raison} · ${suite}',
			'classe.entree.coursDans' => ({required Object duree}) => 'الدرس بعد ${duree}',
			'classe.entree.coursImminent' => 'الدرس بعد أقل من دقيقة',
			'classe.entree.rejoindre' => 'انضمام',
			'classe.entree.rejoindreLecteur' => ({required Object classe}) => 'الانضمام إلى حصة ${classe}',
			'classe.entree.salleOuverte' => ({required Object duree}) => 'القاعة مفتوحة. تبدأ الحصة بعد ${duree}.',
			'classe.entree.salleOuverteImminent' => 'القاعة مفتوحة. تبدأ الحصة بعد أقل من دقيقة.',
			'classe.entree.preparation' => 'التحضير جارٍ',
			'classe.entree.attente' => ({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ${duree}.',
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
			'classe.entree.progressionValeur' => ({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage} %',
			'classe.entree.dst' => ({required Object avant, required Object apres}) => 'تغيير التوقيت: سينتقل الدرس من ${avant} إلى ${apres}.',
			'classe.entree.annonce.aVenir' => 'حصة قادمة',
			'classe.entree.annonce.fenetreOuverte' => 'القاعة مفتوحة',
			'classe.entree.annonce.attente' => 'أنت في القاعة',
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
			'salle.seance.bibliotheque.echec' => 'تعذّر فتح هذه المادة.',
			'salle.seance.bibliotheque.echecDetail' => 'تعذّر تحميل الملف. يبقى الفصل على المادة الحالية. أعد المحاولة، أو عد إلى المواد لاختيار مادة أخرى.',
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
			'eleve.suivi.aujourdhui' => ({required Object heure}) => 'اليوم، ${heure}',
			'eleve.suivi.hier' => ({required Object heure}) => 'أمس، ${heure}',
			'eleve.suivi.date' => ({required Object date, required Object heure}) => '${date}، ${heure}',
			'eleve.suivi.annule' => 'درس ملغى',
			'eleve.suivi.nonTenu' => 'درس لم يُعقد',
			'eleve.suivi.vide' => 'لا توجد دروس حتى الآن',
			'eleve.suivi.videDetail' => 'ستظهر دروسك هنا من الأحدث إلى الأقدم مع حالة حضورك.',
			'eleve.suivi.erreur' => 'تعذرت قراءة المتابعة. حاول مرة أخرى بعد قليل.',
			'eleve.suivi.tronquee' => ({required Object nombre}) => 'تظهر أحدث ${nombre} دروس.',
			'eleve.suivi.fin' => ({required Object nombre}) => 'عدد الدروس في المتابعة: ${nombre}.',
			'eleve.suivi.finUn' => 'درس واحد في المتابعة.',
			'enseignant.journee.derniereSeance' => 'آخر حصة',
			'enseignant.journee.rejoindreSalle' => 'الدخول إلى القاعة',
			'enseignant.journee.rejoindreSalleLecteur' => ({required Object classe}) => 'الدخول إلى قاعة الفصل ${classe}',
			'enseignant.journee.remplirCahier' => 'تعبئة دفتر المتابعة',
			'enseignant.journee.remplirCahierLecteur' => ({required Object classe}) => 'تعبئة دفتر المتابعة للفصل ${classe}',
			'enseignant.journee.cahierObligatoire' => ({required Object classe}) => 'إلزامي: يُعبَّأ دفتر ${classe} في نهاية كل حصة.',
			'enseignant.journee.voirCahier' => ({required Object classe}) => 'عرض دفتر ${classe}',
			'enseignant.journee.voirCahierLecteur' => ({required Object classe}) => 'عرض دفتر المتابعة للفصل ${classe}',
			'enseignant.ficheGroupe.elevesTitre' => 'الطلاب',
			'enseignant.ficheGroupe.preparationTitre' => 'للتحضير',
			'enseignant.ficheGroupe.supportPrevu' => 'المادة المقررة',
			'enseignant.ficheGroupe.positionReprise' => 'موضع الاستئناف',
			'enseignant.ficheGroupe.objectif' => 'الهدف',
			'enseignant.ficheGroupe.preparationVide' => 'لم يُسجَّل أي تحضير لهذه الحصة.',
			'enseignant.ficheGroupe.supportsTitre' => 'أحدث المواد',
			'enseignant.ficheGroupe.repriseEleve' => ({required Object page}) => 'الاستئناف: ${page}',
			'enseignant.ficheGroupe.dernierPoint' => ({required Object texte}) => 'آخر ملاحظة: ${texte}',
			'enseignant.ficheGroupe.chargementClasse' => 'جارٍ تحميل الفصل.',
			'compte.themeContexte' => 'اختر مظهر التطبيق. يتم التغيير فورًا ويبقى على هذا الجهاز، ويمكنك تعديله في أي وقت.',
			'compte.themeSysteme' => 'النظام',
			'compte.themeSystemeDetail' => 'يتبع إعداد جهازك',
			'compte.themeClair' => 'فاتح',
			'compte.themeClairDetail' => 'خلفية فاتحة مهما كان إعداد جهازك',
			'compte.themeSombre' => 'داكن',
			'compte.themeSombreDetail' => 'خلفية داكنة مهما كان إعداد جهازك',
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
			_ => null,
		} ?? switch (path) {
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
			_ => null,
		};
	}
}
