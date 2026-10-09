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
	@override String get bandeauPermanent => 'الدرس مسجَّل، وزيارة مراقبة ممكنة.';
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
	@override String get quitter => 'خروج';
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
	@override String minutesRestantes({required Object minutes}) => 'بقيت ⁨${minutes}⁩ دقيقة';
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
	@override String get commandesAppel => 'أزرار المكالمة';
	@override String compteurEleves({required Object connectes, required Object inscrits}) => 'الطلاب ⁨${connectes}⁩/⁨${inscrits}⁩';
	@override String get parler => 'تحدّث';
	@override String get agrandir => 'تكبير';
	@override String get reduire => 'تصغير';
	@override String rienPartage({required Object nom}) => 'لم يشارك ⁨${nom}⁩ شيئًا بعد.';
	@override String videoDe({required Object nom}) => 'فيديو ⁨${nom}⁩';
	@override String page({required Object page, required Object pages}) => '⁨${page}⁩ / ⁨${pages}⁩';
	@override String pageSemantique({required Object page, required Object pages}) => 'الصفحة ⁨${page}⁩ من ⁨${pages}⁩';
	@override String get zoomLocal => 'تكبير محلي، لا يؤثر في الآخرين';
	@override String zoomValeur({required Object valeur}) => '⁨${valeur}⁩ %';
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
	@override String get rappeler => 'النداء بهدوء';
	@override String get faireReciter => 'طلب التلاوة';
	@override String get fileRecitation => 'دور التلاوة';
	@override String get aSuivre => 'التالي';
	@override String vousAppelle({required Object nom}) => '⁨${nom}⁩ يناديك';
	@override String get signalerBesoin => 'الإشارة إلى حاجة';
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
}

// Path: tc.groupe
class _Traductions$tc$groupe$ar extends Traductions$tc$groupe$fr {
	_Traductions$tc$groupe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$groupe$enseignant$ar enseignant = _Traductions$tc$groupe$enseignant$ar._(_root);
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
	@override String get marquer => 'تعليم';
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
	@override String get journee => 'اليوم';
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
	@override String get recents => 'الأحدث';
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
	@override String seancesSemaine({required Object nombre}) => '⁨${nombre}⁩ حصص هذا الأسبوع';
}

// Path: salle.seance.commandes
class _Traductions$salle$seance$commandes$ar extends Traductions$salle$seance$commandes$fr {
	_Traductions$salle$seance$commandes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get declencheur => 'الأوامر';
	@override String get declencheurSemantique => 'فتح أوامر المادة والسبورة';
	@override String get titre => 'الأوامر';
	@override String get reduire => 'تصغير';
	@override String get reduireSemantique => 'تصغير الأوامر';
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
	@override String get intro => 'المادة التي تختارها تُفتح لك وحدك. يبقى الفصل على المادة الحالية حتى «عرض».';
	@override String get apercu => 'معاينة خاصة';
	@override String get apercuClasse => 'ما زال الطلاب يرون المادة الحالية.';
	@override String get presenter => 'عرض';
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
	@override String connectes({required Object n}) => '⁨${n}⁩ طلاب متصلون';
	@override String unConnecte({required Object n}) => '⁨${n}⁩ طالب متصل';
	@override String inscrits({required Object n}) => 'من ⁨${n}⁩ مسجَّلين';
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
}

// Path: tc.groupe.enseignant
class _Traductions$tc$groupe$enseignant$ar extends Traductions$tc$groupe$enseignant$fr {
	_Traductions$tc$groupe$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sayyid => 'سيد';
	@override String get sayyida => 'سيدة';
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
	@override String get repos => 'سكون';
	@override String get visite => 'زيارة';
	@override String get rienPartage => 'لا شيء مُشارَك';
	@override String get appel => 'النداء بهدوء';
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
	@override String get cmd01 => 'CMD-01 الأوامر';
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
			'salle.secours.quitter' => 'خروج',
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
			'salle.bandeauPermanent' => 'الدرس مسجَّل، وزيارة مراقبة ممكنة.',
			'salle.seance.titre' => 'حصة مباشرة',
			'salle.seance.titreGuidee' => 'حصتي',
			'salle.seance.ligne' => ({required Object debut, required Object fin}) => '⁨${debut}⁩ · ⁨${fin}⁩',
			'salle.seance.minutesRestantes' => ({required Object minutes}) => 'بقيت ⁨${minutes}⁩ دقيقة',
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
			'salle.seance.commandesAppel' => 'أزرار المكالمة',
			'salle.seance.compteurEleves' => ({required Object connectes, required Object inscrits}) => 'الطلاب ⁨${connectes}⁩/⁨${inscrits}⁩',
			'salle.seance.parler' => 'تحدّث',
			'salle.seance.agrandir' => 'تكبير',
			'salle.seance.reduire' => 'تصغير',
			'salle.seance.rienPartage' => ({required Object nom}) => 'لم يشارك ⁨${nom}⁩ شيئًا بعد.',
			'salle.seance.videoDe' => ({required Object nom}) => 'فيديو ⁨${nom}⁩',
			'salle.seance.page' => ({required Object page, required Object pages}) => '⁨${page}⁩ / ⁨${pages}⁩',
			'salle.seance.pageSemantique' => ({required Object page, required Object pages}) => 'الصفحة ⁨${page}⁩ من ⁨${pages}⁩',
			'salle.seance.zoomLocal' => 'تكبير محلي، لا يؤثر في الآخرين',
			'salle.seance.zoomValeur' => ({required Object valeur}) => '⁨${valeur}⁩ %',
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
			'salle.seance.outils.marquer' => 'تعليم',
			'salle.seance.outils.masquer' => 'إخفاء',
			'salle.seance.outils.annoter' => 'كتابة ملاحظات',
			'salle.seance.rail.navigation' => 'التنقل',
			'salle.seance.rail.marque' => 'Rewayah',
			'salle.seance.rail.sousMarque' => 'Academy',
			'salle.seance.rail.journee' => 'اليوم',
			'salle.seance.rail.classes' => 'الفصول',
			'salle.seance.rail.ressources' => 'الموارد',
			'salle.seance.rail.profil' => 'الملف الشخصي',
			'salle.seance.fermerPanneau' => 'إغلاق اللوحة',
			'salle.seance.panneauSupports.reprendre' => 'استئناف',
			'salle.seance.panneauSupports.recents' => 'الأحدث',
			'salle.seance.panneauSupports.ressourcesClasse' => 'موارد الفصل',
			'salle.seance.panneauSupports.voirTout' => 'عرض الكل',
			'salle.seance.panneauSupports.ouvrir' => 'فتح',
			'salle.seance.panneauSupports.ouvrirSupport' => ({required Object titre}) => 'فتح ⁨${titre}⁩',
			'salle.seance.panneauSupports.voirBibliotheque' => 'عرض المكتبة كاملة',
			'salle.seance.eleves' => 'الطلاب',
			'salle.seance.rappeler' => 'النداء بهدوء',
			'salle.seance.faireReciter' => 'طلب التلاوة',
			'salle.seance.fileRecitation' => 'دور التلاوة',
			'salle.seance.aSuivre' => 'التالي',
			'salle.seance.vousAppelle' => ({required Object nom}) => '⁨${nom}⁩ يناديك',
			'salle.seance.signalerBesoin' => 'الإشارة إلى حاجة',
			'salle.seance.deplierFiche' => ({required Object prenom}) => 'عرض بطاقة ⁨${prenom}⁩',
			'salle.seance.replierFiche' => ({required Object prenom}) => 'إخفاء بطاقة ⁨${prenom}⁩',
			'salle.seance.fiche.aucuneSeanceSemaine' => 'لا حصص هذا الأسبوع',
			'salle.seance.fiche.uneSeanceSemaine' => 'حصة واحدة هذا الأسبوع',
			'salle.seance.fiche.seancesSemaine' => ({required Object nombre}) => '⁨${nombre}⁩ حصص هذا الأسبوع',
			'salle.seance.optionsPanneau' => ({required Object titre}) => 'خيارات لوحة ⁨${titre}⁩',
			'salle.seance.commandes.declencheur' => 'الأوامر',
			'salle.seance.commandes.declencheurSemantique' => 'فتح أوامر المادة والسبورة',
			'salle.seance.commandes.titre' => 'الأوامر',
			'salle.seance.commandes.reduire' => 'تصغير',
			'salle.seance.commandes.reduireSemantique' => 'تصغير الأوامر',
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
			'salle.seance.bibliotheque.intro' => 'المادة التي تختارها تُفتح لك وحدك. يبقى الفصل على المادة الحالية حتى «عرض».',
			'salle.seance.bibliotheque.apercu' => 'معاينة خاصة',
			'salle.seance.bibliotheque.apercuClasse' => 'ما زال الطلاب يرون المادة الحالية.',
			'salle.seance.bibliotheque.presenter' => 'عرض',
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
			'salle.seance.demo.etats.repos' => 'سكون',
			'salle.seance.demo.etats.visite' => 'زيارة',
			'salle.seance.demo.etats.rienPartage' => 'لا شيء مُشارَك',
			'salle.seance.demo.etats.appel' => 'النداء بهدوء',
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
			'salle.seance.demo.tb.cmd01' => 'CMD-01 الأوامر',
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
			'salle.fin.enseignant.connectes' => ({required Object n}) => '⁨${n}⁩ طلاب متصلون',
			'salle.fin.enseignant.unConnecte' => ({required Object n}) => '⁨${n}⁩ طالب متصل',
			'salle.fin.enseignant.inscrits' => ({required Object n}) => 'من ⁨${n}⁩ مسجَّلين',
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
			'tc.groupe.enseignant.sayyid' => 'سيد',
			'tc.groupe.enseignant.sayyida' => 'سيدة',
			_ => null,
		};
	}
}
