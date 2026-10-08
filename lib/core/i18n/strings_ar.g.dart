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
	@override late final _Traductions$choix$ar choix = _Traductions$choix$ar._(_root);
	@override late final _Traductions$destructif$ar destructif = _Traductions$destructif$ar._(_root);
	@override late final _Traductions$reseau$ar reseau = _Traductions$reseau$ar._(_root);
	@override late final _Traductions$nav$ar nav = _Traductions$nav$ar._(_root);
	@override late final _Traductions$admin$ar admin = _Traductions$admin$ar._(_root);
	@override late final _Traductions$comptable$ar comptable = _Traductions$comptable$ar._(_root);
}

// Path: commun
class _Traductions$commun$ar extends Traductions$commun$fr {
	_Traductions$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$sections$ar sections = _Traductions$commun$sections$ar._(_root);
	@override late final _Traductions$commun$dates$ar dates = _Traductions$commun$dates$ar._(_root);
	@override String get reessayer => 'إعادة المحاولة';
	@override String get annuler => 'إلغاء';
	@override late final _Traductions$commun$choix$ar choix = _Traductions$commun$choix$ar._(_root);
	@override late final _Traductions$commun$etats$ar etats = _Traductions$commun$etats$ar._(_root);
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

// Path: choix
class _Traductions$choix$ar extends Traductions$choix$fr {
	_Traductions$choix$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get autre => 'آخر';
	@override String get autreInvite => 'حدّد';
	@override String get selectionMultiple => 'يمكن اختيار أكثر من إجابة';
}

// Path: destructif
class _Traductions$destructif$ar extends Traductions$destructif$fr {
	_Traductions$destructif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get irreversible => 'لا يمكن التراجع عن هذا الإجراء.';
}

// Path: reseau
class _Traductions$reseau$ar extends Traductions$reseau$fr {
	_Traductions$reseau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get horsLigne => 'لا توجد شبكة. يبقى كل شيء متاحًا للاطلاع، وسينتظر الإرسال.';
}

// Path: nav
class _Traductions$nav$ar extends Traductions$nav$fr {
	_Traductions$nav$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get principale => 'التنقل الرئيسي';
	@override String get replier => 'طيّ شريط التنقل';
	@override String get deplier => 'فتح شريط التنقل';
}

// Path: admin
class _Traductions$admin$ar extends Traductions$admin$fr {
	_Traductions$admin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$admin$finance$ar finance = _Traductions$admin$finance$ar._(_root);
}

// Path: comptable
class _Traductions$comptable$ar extends Traductions$comptable$fr {
	_Traductions$comptable$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$comptable$nav$ar nav = _Traductions$comptable$nav$ar._(_root);
	@override late final _Traductions$comptable$onglets$ar onglets = _Traductions$comptable$onglets$ar._(_root);
	@override late final _Traductions$comptable$commun$ar commun = _Traductions$comptable$commun$ar._(_root);
	@override late final _Traductions$comptable$coffres$ar coffres = _Traductions$comptable$coffres$ar._(_root);
	@override late final _Traductions$comptable$statuts$ar statuts = _Traductions$comptable$statuts$ar._(_root);
	@override late final _Traductions$comptable$alertes$ar alertes = _Traductions$comptable$alertes$ar._(_root);
	@override late final _Traductions$comptable$aujourdhui$ar aujourdhui = _Traductions$comptable$aujourdhui$ar._(_root);
	@override late final _Traductions$comptable$paiements$ar paiements = _Traductions$comptable$paiements$ar._(_root);
	@override late final _Traductions$comptable$tresorerie$ar tresorerie = _Traductions$comptable$tresorerie$ar._(_root);
	@override late final _Traductions$comptable$encaissements$ar encaissements = _Traductions$comptable$encaissements$ar._(_root);
	@override late final _Traductions$comptable$beneficiaires$ar beneficiaires = _Traductions$comptable$beneficiaires$ar._(_root);
	@override late final _Traductions$comptable$contractuels$ar contractuels = _Traductions$comptable$contractuels$ar._(_root);
	@override late final _Traductions$comptable$validation$ar validation = _Traductions$comptable$validation$ar._(_root);
	@override late final _Traductions$comptable$direction$ar direction = _Traductions$comptable$direction$ar._(_root);
	@override late final _Traductions$comptable$demo$ar demo = _Traductions$comptable$demo$ar._(_root);
}

// Path: commun.sections
class _Traductions$commun$sections$ar extends Traductions$commun$sections$fr {
	_Traductions$commun$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get page => 'أقسام الصفحة';
}

// Path: commun.dates
class _Traductions$commun$dates$ar extends Traductions$commun$dates$fr {
	_Traductions$commun$dates$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get premierJour => '1';
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
	@override String jourDate({required Object jour, required Object numero, required Object mois}) => '${jour} ${numero} ${mois}';
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
	@override String get reessaisEpuises => 'لا يزال دون رد. أعد المحاولة لاحقًا.';
	@override String get horsLigneDemarrage => 'تحتاج Rewayah إلى الإنترنت للتحقق من حسابك. أعد توصيل هذا الجهاز، ثم أعد المحاولة.';
	@override late final _Traductions$commun$etats$actions$ar actions = _Traductions$commun$etats$actions$ar._(_root);
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

// Path: admin.finance
class _Traductions$admin$finance$ar extends Traductions$admin$finance$fr {
	_Traductions$admin$finance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aValider => 'للمصادقة';
}

// Path: comptable.nav
class _Traductions$comptable$nav$ar extends Traductions$comptable$nav$fr {
	_Traductions$comptable$nav$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aujourdhui => 'اليوم';
	@override String get paiements => 'المدفوعات';
	@override String get tresorerie => 'الخزينة';
	@override String get compte => 'الحساب';
}

// Path: comptable.onglets
class _Traductions$comptable$onglets$ar extends Traductions$comptable$onglets$fr {
	_Traductions$comptable$onglets$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aEffectuer => 'للتنفيذ';
	@override String get contractuels => 'المتعاقدون';
	@override String get beneficiaires => 'المستفيدون';
	@override String get coffres => 'الصناديق';
	@override String get encaissements => 'المقبوضات';
	@override String get rapprochement => 'المطابقة';
}

// Path: comptable.commun
class _Traductions$comptable$commun$ar extends Traductions$comptable$commun$fr {
	_Traductions$comptable$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get montantMasque => 'مبلغ مخفي';
	@override String get afficherMontants => 'إظهار المبالغ';
	@override String get masquerMontants => 'إخفاء المبالغ';
	@override String get montantsMasques => 'المبالغ مخفية';
	@override String get montantsAffiches => 'المبالغ ظاهرة';
	@override String get enPreparationTitre => 'هذه الشاشة قيد الإعداد.';
	@override String get enPreparationPhrase => 'لا يُعرض هنا أي رقم في الوقت الحالي. لا يمكن تنفيذ أي دفعة من هذه الشاشة.';
	@override String get reserveStrategique => 'الاحتياطي الاستراتيجي';
	@override String get tresorerieLibre => 'الخزينة الحرة';
	@override String get tresorerieDetenue => 'الخزينة المحتفَظ بها';
	@override String get fondsProteges => 'الأموال المحمية';
	@override String get enTransit => 'قيد التحويل';
	@override String get tresorerieLibreDetail => 'ما يبقى متاحًا فعلًا بعد الأموال المحمية والالتزامات والمبالغ قيد التحويل.';
	@override String get objectifFixe => 'الهدف: مبلغ ثابت';
	@override String objectifMois({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'الهدف الحالي: شهر واحد من المصاريف الأساسية',
		two: 'الهدف الحالي: شهران من المصاريف الأساسية',
		few: 'الهدف الحالي: ${n} أشهر من المصاريف الأساسية',
		many: 'الهدف الحالي: ${n} شهرًا من المصاريف الأساسية',
		other: 'الهدف الحالي: ${n} شهر من المصاريف الأساسية',
	);
	@override String get montantActuel => 'المبلغ الحالي';
	@override String get manque => 'المتبقي لبلوغ الهدف';
	@override String atteint({required Object pourcent}) => 'تحقق ${pourcent} %';
	@override String get modeCalcul => 'طريقة الحساب';
	@override String get modeMontantFixe => 'مبلغ مستهدف ثابت';
	@override String get modeCouvertureMois => 'تغطية بعدد أشهر المصاريف الأساسية';
	@override String derniereAllocation({required Object date}) => 'آخر تخصيص: ${date}';
	@override String prochaineAllocation({required Object date}) => 'التخصيص القادم المقرر: ${date}';
	@override String get aucuneAllocation => 'لا يوجد أي تخصيص مسجل';
	@override String get destination => 'الوجهة';
	@override String destinationMasquee({required Object type, required Object suffixe}) => '${type} •••• ${suffixe}';
	@override String destinationMasqueeLecteur({required Object type, required Object suffixe}) => '${type}، الرقم مخفي، ينتهي بـ ${suffixe}';
	@override String get destinationAucune => 'لا توجد وسيلة دفع';
	@override String paysDevise({required Object pays, required Object devise}) => '${pays} · ${devise}';
	@override String get verification => 'التحقق';
	@override String activiteInitiateurDate({required Object initiateur, required Object date}) => '${initiateur} · ${date}';
	@override String activiteTransition({required Object avant, required Object apres}) => '${avant} ← ${apres}';
	@override String activiteReference({required Object reference}) => 'المرجع ${reference}';
	@override String get relancePreparee => 'تذكير جاهز (عرض توضيحي)';
	@override String prestataireDemonstration({required Object nom}) => '${nom} (عرض توضيحي)';
	@override String date({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}';
	@override String get aucuneValeur => 'غير محدد';
}

// Path: comptable.coffres
class _Traductions$comptable$coffres$ar extends Traductions$comptable$coffres$fr {
	_Traductions$comptable$coffres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get fondsClientsEngages => 'أموال العملاء الملتزَم بها';
	@override String get paieADecaisser => 'رواتب مستحقة الصرف';
	@override String get chargesEssentielles => 'المصاريف الأساسية';
	@override String get taxesObligations => 'الضرائب والالتزامات';
	@override String get reserveStrategique => 'الاحتياطي الاستراتيجي';
	@override String get enTransit => 'قيد التحويل';
	@override String get tresorerieLibre => 'الخزينة الحرة';
}

// Path: comptable.statuts
class _Traductions$comptable$statuts$ar extends Traductions$comptable$statuts$fr {
	_Traductions$comptable$statuts$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$comptable$statuts$paiement$ar paiement = _Traductions$comptable$statuts$paiement$ar._(_root);
	@override late final _Traductions$comptable$statuts$encaissement$ar encaissement = _Traductions$comptable$statuts$encaissement$ar._(_root);
	@override late final _Traductions$comptable$statuts$rapprochement$ar rapprochement = _Traductions$comptable$statuts$rapprochement$ar._(_root);
	@override late final _Traductions$comptable$statuts$profil$ar profil = _Traductions$comptable$statuts$profil$ar._(_root);
	@override late final _Traductions$comptable$statuts$capacite$ar capacite = _Traductions$comptable$statuts$capacite$ar._(_root);
	@override late final _Traductions$comptable$statuts$reserve$ar reserve = _Traductions$comptable$statuts$reserve$ar._(_root);
	@override late final _Traductions$comptable$statuts$obligation$ar obligation = _Traductions$comptable$statuts$obligation$ar._(_root);
	@override late final _Traductions$comptable$statuts$remboursement$ar remboursement = _Traductions$comptable$statuts$remboursement$ar._(_root);
	@override late final _Traductions$comptable$statuts$validation$ar validation = _Traductions$comptable$statuts$validation$ar._(_root);
	@override late final _Traductions$comptable$statuts$raison$ar raison = _Traductions$comptable$statuts$raison$ar._(_root);
}

// Path: comptable.alertes
class _Traductions$comptable$alertes$ar extends Traductions$comptable$alertes$fr {
	_Traductions$comptable$alertes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enseignantsAPayer => 'معلمون للدفع';
	@override String get contractuelsAEcheance => 'متعاقدون حان موعد استحقاقهم';
	@override String get infosManquantes => 'معلومات الدفع ناقصة';
	@override String get payoutEchoue => 'فشل صرف دفعة';
	@override String get paiementFamilleEchoue => 'فشل دفع أسرة';
	@override String get transactionNonRapprochee => 'معاملة غير مطابَقة';
	@override String get remboursementEnAttente => 'استرداد قيد الانتظار';
	@override String get reserveSousObjectif => 'الاحتياطي الاستراتيجي دون الهدف';
	@override String get soldePrestataireInsuffisant => 'رصيد مزوّد الدفع غير كافٍ';
	@override String get methodeModifieeRecemment => 'وسيلة دفع عُدّلت مؤخرًا';
	@override String get doublonPotentiel => 'تكرار محتمل';
	@override String get validationRequise => 'تلزم مصادقة إضافية';
}

// Path: comptable.aujourdhui
class _Traductions$comptable$aujourdhui$ar extends Traductions$comptable$aujourdhui$fr {
	_Traductions$comptable$aujourdhui$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get attentionSousTitre => 'ما ينتظر إجراءً منك، ثم المخاطر التي تجب مراقبتها.';
	@override String elementCompteur({required Object libelle, required Object n}) => '${libelle}: ${n}';
	@override String elementDepuis({required Object date}) => 'قيد الانتظار منذ ${date}';
	@override String get aTraiterVide => 'لا شيء للمعالجة اليوم.';
	@override String get aTraiterVideDetail => 'ستظهر هنا المدفوعات والتذكيرات والمطابقات المطلوبة.';
	@override String get alertesVide => 'لا توجد تنبيهات حاليًا.';
	@override String alertesResume({required Object n}) => 'تنبيهات للمراقبة: ${n}';
	@override String get paiementsAEffectuer => 'مدفوعات للتنفيذ';
	@override String get paiementsAEffectuerDetail => 'تُراجَع كل دفعة في قائمتها قبل دفعها.';
	@override String get paiementsVide => 'لا توجد مدفوعات للتنفيذ.';
	@override String get echeancesVide => 'لا توجد مواعيد استحقاق قريبة.';
	@override String get encaissementsVide => 'لا توجد مقبوضات حديثة.';
	@override String get activiteVide => 'لا يوجد نشاط حديث.';
	@override String get prestatairesVide => 'لا يوجد مزوّد دفع مفعّل.';
	@override String get prestatairesVideDetail => 'ستنطلق المدفوعات الصادرة عندما تفعّل الإدارة مزوّد دفع.';
	@override String get accesPaiements => 'عرض المدفوعات للتنفيذ';
	@override String get accesContractuels => 'إدارة التزامات المتعاقدين';
	@override String get accesEncaissements => 'عرض المقبوضات';
	@override String get accesTresorerie => 'عرض الخزينة والصناديق';
	@override String get accesAlimenter => 'تغذية الاحتياطي الاستراتيجي';
	@override String get titre => 'اليوم';
	@override String get sousTitre => 'ماذا عليّ أن أفعل الآن؟';
	@override String get attention => 'للمعالجة والتنبيهات';
	@override String get aTraiter => 'للمعالجة اليوم';
	@override String get aTraiterHorsPaiements => 'مهام أخرى';
	@override String get alertes => 'التنبيهات';
	@override String get echeances => 'مواعيد استحقاق قريبة';
	@override String get prestataires => 'مزوّدو الدفع';
	@override String get activiteRecente => 'النشاط الحديث';
	@override String get accesRapides => 'وصول سريع';
	@override String get encaissementsRecents => 'المقبوضات الحديثة';
	@override String get voirTout => 'عرض الكل';
}

// Path: comptable.paiements
class _Traductions$comptable$paiements$ar extends Traductions$comptable$paiements$fr {
	_Traductions$comptable$paiements$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$comptable$paiements$confirmation$ar confirmation = _Traductions$comptable$paiements$confirmation$ar._(_root);
	@override late final _Traductions$comptable$paiements$filtres$ar filtres = _Traductions$comptable$paiements$filtres$ar._(_root);
	@override late final _Traductions$comptable$paiements$colonnes$ar colonnes = _Traductions$comptable$paiements$colonnes$ar._(_root);
	@override late final _Traductions$comptable$paiements$types$ar types = _Traductions$comptable$paiements$types$ar._(_root);
	@override String compteur({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'دفعة واحدة',
		two: 'دفعتان',
		few: '${n} دفعات',
		other: '${n} دفعة',
	);
	@override late final _Traductions$comptable$paiements$actions$ar actions = _Traductions$comptable$paiements$actions$ar._(_root);
	@override String selection({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'دفعة واحدة محددة',
		two: 'دفعتان محددتان',
		few: '${n} دفعات محددة',
		other: '${n} دفعة محددة',
	);
	@override String get selectionPhrase => 'يُرجع الفحص الإجمالي والاستبعادات قبل أي إرسال.';
	@override String get horsLigneCourt => 'غير متصل: الدفع غير ممكن';
	@override late final _Traductions$comptable$paiements$vide$ar vide = _Traductions$comptable$paiements$vide$ar._(_root);
	@override String get horsLigne => 'غير متصل: لا تُرسَل أي دفعة دون شبكة. أعد الاتصال لتدفع.';
	@override late final _Traductions$comptable$paiements$detail$ar detail = _Traductions$comptable$paiements$detail$ar._(_root);
	@override late final _Traductions$comptable$paiements$ecart$ar ecart = _Traductions$comptable$paiements$ecart$ar._(_root);
	@override String get titre => 'مدفوعات للتنفيذ';
	@override String get sousTitre => 'مبالغ محسوبة في المصدر: هنا نراجع وندفع، ولا نعدّل شيئًا.';
	@override String get detailTitre => 'تفاصيل الدفعة';
	@override String get detailSousTitre => 'لكل سطر مصدره. يُبلَّغ عن الفرق ولا يُصحَّح هنا.';
}

// Path: comptable.tresorerie
class _Traductions$comptable$tresorerie$ar extends Traductions$comptable$tresorerie$fr {
	_Traductions$comptable$tresorerie$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get coffresTitre => 'الصناديق';
	@override String get coffresPhrase => 'حيث يُخصَّص المال. المبلغ المحمي لا يُحسب أبدًا ضمن الحر.';
	@override String get coffreProtege => 'محمي';
	@override String get coffreNonProtege => 'غير محمي';
	@override String partDetenue({required Object part}) => '${part} % من الخزينة المحتفَظ بها';
	@override String regleUsage({required Object regle}) => 'قاعدة الاستخدام: ${regle}';
	@override String get coffresVide => 'لم يُرجَع أي صندوق بعد.';
	@override String get coffresVidePhrase => 'ستظهر الصناديق السبعة هنا بمجرد أن يُرجعها المصدر.';
	@override late final _Traductions$comptable$tresorerie$descriptions$ar descriptions = _Traductions$comptable$tresorerie$descriptions$ar._(_root);
	@override String get politiqueTitre => 'سياسة الاحتياطي الاستراتيجي';
	@override String get politiquePhrase => 'تحددها الإدارة. أنت تطبّقها ولا تعدّلها.';
	@override String get alimentationAuto => 'التغذية التلقائية';
	@override late final _Traductions$comptable$tresorerie$regle$ar regle = _Traductions$comptable$tresorerie$regle$ar._(_root);
	@override String get cadence => 'الوتيرة';
	@override late final _Traductions$comptable$tresorerie$cadences$ar cadences = _Traductions$comptable$tresorerie$cadences$ar._(_root);
	@override String seuilAlerte({required Object pourcent}) => 'تنبيه دون ${pourcent} % من المبلغ المستهدف';
	@override String get retraitValidation => 'كل سحب يتطلب مصادقة إضافية.';
	@override String get retraitSansValidation => 'لا تشترط السياسة مصادقة للسحب؛ ويبقى معامَلًا كحركة حساسة.';
	@override String version({required Object version}) => 'الإصدار ${version}';
	@override String versionDepuis({required Object version, required Object date}) => 'الإصدار ${version}، ساري المفعول منذ ${date}';
	@override String get mouvementsTitre => 'الحركات بين الصناديق';
	@override String get mouvementsPhrase => 'نحو الحماية: حسب تفويضك. الخروج من صندوق محمي: تلزم مصادقة إضافية.';
	@override String get preparerMouvement => 'إعداد حركة';
	@override String get retirer => 'السحب من الاحتياطي الاستراتيجي';
	@override String retraitBloque({required Object raison}) => 'السحب من الاحتياطي الاستراتيجي: ${raison}.';
	@override String alimenterBloque({required Object raison}) => 'تغذية الاحتياطي الاستراتيجي: ${raison}.';
	@override String get aucunMouvement => 'لا تسمح السياسة لحسابك بأي حركة بين الصناديق.';
	@override String get mouvementsHorsLigne => 'غير متصل: تُستأنف الحركات بين الصناديق مع عودة الشبكة.';
	@override String get interdits => 'أموال العملاء الملتزَم بها والضرائب والالتزامات لا تموّل أبدًا مصروفًا عاديًا؛ والتخصيص السابق لا يُعدَّل.';
	@override String get previsionTitre => 'التوقعات';
	@override String get previsionPhrase => 'الداخل والخارج المتوقع، حسب التاريخ.';
	@override String get previsionVide => 'لا يوجد داخل ولا خارج متوقع حاليًا.';
	@override String get entree => 'داخل';
	@override String get sortie => 'خارج';
	@override String get historiqueTitre => 'سجل التخصيصات';
	@override String get historiquePhrase => 'كل حركة مسجلة في السجل؛ ولا يُعدَّل فيه شيء.';
	@override String get historiqueVide => 'لا توجد حركة مسجلة بين الصناديق.';
	@override late final _Traductions$comptable$tresorerie$transfert$ar transfert = _Traductions$comptable$tresorerie$transfert$ar._(_root);
	@override String get titre => 'الخزينة والصناديق';
	@override String get sousTitre => 'الخزينة الحرة هي الرقم الوحيد القابل للإنفاق.';
	@override String get alimenter => 'تغذية الاحتياطي الاستراتيجي';
}

// Path: comptable.encaissements
class _Traductions$comptable$encaissements$ar extends Traductions$comptable$encaissements$fr {
	_Traductions$comptable$encaissements$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get filtreTous => 'الكل';
	@override String get filtreConfirmes => 'مؤكَّدة';
	@override String get filtreEnAttente => 'قيد الانتظار';
	@override String get filtreEchoues => 'فاشلة';
	@override String get filtreRembourses => 'مُسترَدة';
	@override String get filtreContestes => 'متنازَع عليها';
	@override String get filtreARapprocher => 'للمطابقة';
	@override String get recherche => 'البحث عن أسرة أو مرجع';
	@override String get colDate => 'التاريخ';
	@override String get colFamille => 'الأسرة';
	@override String get colReference => 'المرجع';
	@override String get colBrut => 'الإجمالي';
	@override String get colFrais => 'الرسوم';
	@override String get colNet => 'الصافي';
	@override String get colMoyen => 'الوسيلة';
	@override String get colEtat => 'الحالة';
	@override String profilsPour({required Object prenoms}) => 'لـ ${prenoms}';
	@override String moyenPrestataire({required Object moyen, required Object prestataire}) => '${moyen} · ${prestataire}';
	@override String get videTitre => 'لا توجد مقبوضات حاليًا.';
	@override String get videPhrase => 'ستظهر هنا مدفوعات الأسر بمجرد أن يرسلها مزوّد الدفع.';
	@override String get videFiltreTitre => 'لا يوجد مقبوض مطابق.';
	@override String get videFiltrePhrase => 'اختر «الكل» أو امسح البحث لرؤية القائمة كاملة.';
	@override String get voirTous => 'عرض كل المقبوضات';
	@override String ouvrirDetailLecteur({required Object famille}) => 'فتح تفاصيل مقبوض ${famille}';
	@override String get fermerDetail => 'إغلاق التفاصيل';
	@override String get brut => 'المبلغ الإجمالي';
	@override String get frais => 'رسوم مزوّد الدفع';
	@override String get net => 'الصافي المستلَم';
	@override String get fraisSource => 'الرسوم والصرف كما أبلغ بها مزوّد الدفع، ولا يُعاد حسابها هنا أبدًا.';
	@override String get reference => 'المرجع';
	@override String get prestataire => 'مزوّد الدفع';
	@override String get moyen => 'وسيلة الدفع';
	@override String get foyer => 'الأسرة';
	@override String get date => 'التاريخ';
	@override String get etat => 'الحالة';
	@override String get devise => 'العملة';
	@override String get affectation => 'التوزيع حسب الملف';
	@override String get affectationAucune => 'لم يُرجع المصدر أي توزيع لهذا المقبوض.';
	@override String get rapprochement => 'المطابقة';
	@override String get rapprochementAucun => 'لم تتم المطابقة بعد';
	@override String get ouvrirRapprochement => 'فتح المطابقة';
	@override String get confirmeNote => 'لا تظهر «مؤكَّد» إلا بعد تأكيد مزوّد الدفع.';
	@override String get enAttenteNote => 'بانتظار تأكيد مزوّد الدفع: لم يُكتسب شيء بعد.';
	@override String get journal => 'سجل المقبوض';
	@override String get journalVide => 'لا توجد عملية مسجلة لهذا المقبوض.';
	@override late final _Traductions$comptable$encaissements$rap$ar rap = _Traductions$comptable$encaissements$rap$ar._(_root);
	@override String get titre => 'المقبوضات';
	@override String get sousTitre => 'لا تُؤكَّد الدفعة إلا بعد مزوّد الدفع.';
	@override String get detailTitre => 'تفاصيل المقبوض';
	@override String get rapprochementTitre => 'المطابقة';
	@override String get rapprochementSousTitre => 'ربط كل معاملة بما كان ينتظرها.';
}

// Path: comptable.beneficiaires
class _Traductions$comptable$beneficiaires$ar extends Traductions$comptable$beneficiaires$fr {
	_Traductions$comptable$beneficiaires$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'ملف الدفع لكل معلم ولكل متعاقد. المستفيد وحده يُدخل بياناته أو يعدّلها: يمكنك تذكيره، أو طلب تحديث منه، أو إيقاف مدفوعاته.';
	@override String get filtreTous => 'الكل';
	@override String get filtreInfos => 'معلومات ناقصة';
	@override String get filtreVerification => 'قيد التحقق';
	@override String get filtreSuspendus => 'موقوفة';
	@override String get filtreInvitations => 'دعوات مُرسَلة';
	@override String get colonneBeneficiaire => 'المستفيد';
	@override String get colonneType => 'النوع';
	@override String get colonneDestination => 'الوجهة';
	@override String get colonneEtat => 'حالة الملف';
	@override String get colonneEnAttente => 'مدفوعات قيد الانتظار';
	@override String get typeEnseignant => 'معلم';
	@override String get typeContractuel => 'متعاقد';
	@override String enAttente({required Object n}) => '${n} قيد الانتظار';
	@override String get aucunEnAttente => 'لا شيء';
	@override String get vide => 'لا يوجد مستفيد حاليًا.';
	@override String get videDetail => 'يظهر المعلمون والمتعاقدون هنا بمجرد وجود دفعة تخصهم.';
	@override String get videFiltre => 'لا يوجد مستفيد بعامل التصفية هذا.';
	@override String get videFiltreDetail => 'اختر «الكل» لرؤية القائمة كاملة.';
	@override late final _Traductions$comptable$beneficiaires$profil$ar profil = _Traductions$comptable$beneficiaires$profil$ar._(_root);
	@override String get titre => 'المستفيدون';
	@override String get sousTitre => 'البيانات مخفية: المستفيد وحده يعدّل بياناته.';
	@override String get profilTitre => 'ملف الدفع';
	@override late final _Traductions$comptable$beneficiaires$recevoir$ar recevoir = _Traductions$comptable$beneficiaires$recevoir$ar._(_root);
}

// Path: comptable.contractuels
class _Traductions$comptable$contractuels$ar extends Traductions$comptable$contractuels$fr {
	_Traductions$comptable$contractuels$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ongletObligations => 'الالتزامات';
	@override String get ongletAApprouver => 'للاعتماد';
	@override String get ongletAPayer => 'للدفع';
	@override String get ongletHistorique => 'السجل';
	@override String get ongletsLecteur => 'عرض الالتزامات';
	@override String get colonneBeneficiaire => 'المستفيد';
	@override String get colonneObjet => 'الموضوع';
	@override String get colonneMontant => 'المبلغ';
	@override String get colonneEcheance => 'الاستحقاق';
	@override String get colonneStatut => 'الحالة';
	@override String get typeRecurrente => 'متكرر';
	@override String get typePonctuelle => 'لمرة واحدة';
	@override String echeanceLe({required Object date}) => 'الاستحقاق: ${date}';
	@override String get payer => 'دفع';
	@override String payerLecteur({required Object objet}) => 'دفع الالتزام ${objet}';
	@override String get approuver => 'اعتماد';
	@override String ouvrirLecteur({required Object objet}) => 'فتح الالتزام ${objet}';
	@override String creationBloquee({required Object raison}) => 'الالتزام الجديد غير متاح: ${raison}.';
	@override String get videObligations => 'لا يوجد التزام جارٍ';
	@override String get videObligationsDetail => 'تظهر هنا الالتزامات المنشأة، مع استحقاقها وحالتها.';
	@override String get videAApprouver => 'لا شيء للاعتماد';
	@override String get videAApprouverDetail => 'تظهر هنا الالتزامات التي تنتظر الاعتماد.';
	@override String get videAPayer => 'لا شيء للدفع';
	@override String get videAPayerDetail => 'يظهر هنا الالتزام المعتمَد، جاهزًا للدفع.';
	@override String get videHistorique => 'لا يوجد التزام منتهٍ';
	@override String get videHistoriqueDetail => 'تظهر هنا الالتزامات المدفوعة أو المرفوضة أو الملغاة.';
	@override String get montantDefini => 'مبلغ يُحدَّد عند الإنشاء، ويُثبَّت بعد الاعتماد.';
	@override String get montantFige => 'مبلغ ثُبّت عند الاعتماد: لم يعد يُعدَّل.';
	@override String get montantTitre => 'المبلغ';
	@override String get sectionLignes => 'تفاصيل المبلغ';
	@override String get sectionInfos => 'المعلومات';
	@override String get sectionHistorique => 'سجل الالتزام';
	@override String get historiqueVide => 'لا توجد عملية مسجلة لهذا الالتزام.';
	@override String get champBeneficiaire => 'المستفيد';
	@override String get champType => 'النوع';
	@override String get champEcheance => 'الاستحقاق';
	@override String get champJustificatif => 'المستند المؤيِّد';
	@override String get champCentreCout => 'مركز التكلفة';
	@override String get champAuteur => 'المُنشئ';
	@override String get champApprobateur => 'المعتمِد';
	@override String get champProfilPaiement => 'دفع المستفيد';
	@override String get champMotifRefus => 'سبب الرفض';
	@override String get aucunJustificatif => 'لا يوجد مستند مؤيِّد مرفق';
	@override String get nonRenseigne => 'غير محدد';
	@override String ligneSource({required Object source}) => 'المصدر: ${source}';
	@override String ligneAuteur({required Object auteur}) => 'أضافه ${auteur}';
	@override String ligneValidation({required Object validation}) => 'المصادقة: ${validation}';
	@override String get payerAide => 'يُفتح الدفع في تفاصيل الدفعة، بالمبلغ الدقيق.';
	@override String get approuverAide => 'بعد الاعتماد، يُثبَّت المبلغ ويصبح الالتزام قابلًا للدفع.';
	@override String get renvoyerInvitation => 'إعادة إرسال الدعوة';
	@override String get invitationAide => 'هذا المستفيد الخارجي يُدخل وسيلة الدفع بنفسه، من دعوته الآمنة.';
	@override String get invitationRenvoyee => 'أُعيد إرسال الدعوة';
	@override String get erreurApprobation => 'لا نعلم إن كان الاعتماد قد سُجّل. حدّث الالتزام قبل إعادة المحاولة.';
	@override String get erreurInvitation => 'لا نعلم إن كانت الدعوة قد أُعيد إرسالها. حدّث الالتزام قبل إعادة المحاولة.';
	@override String get formIntro => 'المستفيد والاستحقاق ومركز التكلفة مقترحة: غيّرها عند الحاجة، ثم أدخل الموضوع والمبلغ.';
	@override String get beneficiaireExterne => 'مستفيد خارجي جديد';
	@override String get beneficiaireExterneAide => 'يتلقى دعوة آمنة ليُدخل وسيلة الدفع بنفسه.';
	@override String get champNomExterne => 'اسم المستفيد الخارجي';
	@override String get changerEcheance => 'تغيير الاستحقاق';
	@override String deviseDe({required Object devise}) => 'العملة: ${devise}';
	@override String get champObjet => 'موضوع الالتزام';
	@override String get aideObjet => 'مثلًا: الفاتورة رقم 024';
	@override String get champRefJustificatif => 'مرجع المستند المؤيِّد (اختياري)';
	@override String get champMontantSaisi => 'المبلغ';
	@override String get aideMontant => 'يُدخل مرة واحدة: لا يُعدَّل بعد الاعتماد.';
	@override String get creer => 'إنشاء الالتزام';
	@override String get horsLigneCreation => 'أنت غير متصل. أعد الاتصال لإنشاء الالتزام.';
	@override String get erreurObjet => 'أدخل موضوع الالتزام.';
	@override String get erreurMontant => 'أدخل مبلغًا أكبر من صفر، مثلًا 350 أو 350,50.';
	@override String get erreurNomExterne => 'أدخل اسم المستفيد الخارجي.';
	@override String get erreurCreation => 'لا نعلم إن كان الالتزام قد أُنشئ. حدّث القائمة قبل إعادة المحاولة.';
	@override String get creationIndisponible => 'لا يستطيع حسابك إنشاء التزام.';
	@override String get retourListe => 'العودة إلى المتعاقدين';
	@override String get titre => 'المتعاقدون والالتزامات';
	@override String get sousTitre => 'تُحدَّد المبالغ عند إنشاء الالتزام، وتُثبَّت بعد الاعتماد.';
	@override String get nouvelle => 'التزام جديد';
	@override String get detailTitre => 'الالتزام';
}

// Path: comptable.validation
class _Traductions$comptable$validation$ar extends Traductions$comptable$validation$fr {
	_Traductions$comptable$validation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sousTitre => 'طلبات المحاسب التي تنتظر قرار شخص مخوَّل آخر. صاحب الطلب لا يصادق أبدًا على طلبه.';
	@override String get aDecider => 'للبتّ';
	@override String get decidees => 'بُتّ فيها مؤخرًا';
	@override String get videTitre => 'لا شيء للمصادقة';
	@override String get videPhrase => 'ستظهر هنا طلبات المحاسب القادمة.';
	@override late final _Traductions$comptable$validation$natures$ar natures = _Traductions$comptable$validation$natures$ar._(_root);
	@override String demandePar({required Object demandeur, required Object date}) => 'طلبه ${demandeur} في ${date}';
	@override String valideePar({required Object decideur, required Object date}) => 'صادق عليه ${decideur} في ${date}';
	@override String refuseePar({required Object decideur, required Object date}) => 'رفضه ${decideur} في ${date}';
	@override String motif({required Object motif}) => 'السبب: ${motif}';
	@override String ouvrir({required Object objet}) => 'عرض الطلب: ${objet}';
	@override String get votreDemandeTitre => 'طلبك أنت';
	@override String get votreDemandePhrase => 'سيبتّ فيه شخص مخوَّل آخر: لا تصادق أبدًا على طلب قدّمته.';
	@override late final _Traductions$comptable$validation$detail$ar detail = _Traductions$comptable$validation$detail$ar._(_root);
	@override String get valider => 'مصادقة';
	@override String get refuser => 'رفض';
	@override String get annuler => 'إلغاء';
	@override String get fermer => 'إغلاق';
	@override String get confirmerRefus => 'تأكيد الرفض';
	@override String get motifTitre => 'سبب الرفض';
	@override String get motifPhrase => 'سيقرأ المحاسب هذا السبب مع القرار. اختر واحدًا، أو حدّد سببك.';
	@override late final _Traductions$comptable$validation$motifs$ar motifs = _Traductions$comptable$validation$motifs$ar._(_root);
	@override String get motifAutreChamp => 'حدّد السبب';
	@override String get erreurMotif => 'اختر سببًا للرفض.';
	@override String get erreurMotifAutre => 'حدّد السبب للرفض.';
	@override String get decisionValidee => 'سُجّل قرارك: تمت المصادقة على الطلب.';
	@override String get decisionRefusee => 'سُجّل قرارك: رُفض الطلب، مع سببه.';
	@override String get refusTitre => 'لم يُسجَّل القرار';
	@override String get refusDemandeur => 'أنت من قدّم هذا الطلب: يجب أن يبتّ فيه شخص مخوَّل آخر. لم يتغير شيء.';
	@override String get refusMotif => 'الرفض يتطلب سببًا. اختر واحدًا، ثم أكّد.';
	@override String get refusDejaDecidee => 'سبق البتّ في هذا الطلب. أعد قراءة القائمة.';
	@override String get inconnuTitre => 'القرار غير مؤكد';
	@override String get inconnuPhrase => 'لا نعلم إن كان قرارك قد سُجّل. أعد قراءة القائمة قبل أن تقرر من جديد.';
	@override String get relireListe => 'إعادة قراءة القائمة';
	@override String get horsLigne => 'غير متصل: أعد الاتصال لتقرر.';
	@override String suiviEnAttente({required Object date}) => 'طُلب في ${date}. سيقرر شخص مخوَّل آخر؛ لا يُرسَل شيء قبل قراره.';
	@override String suiviValidee({required Object decideur, required Object date}) => 'صادق عليه ${decideur} في ${date}.';
	@override String suiviRefusee({required Object decideur, required Object date, required Object motif}) => 'رفضه ${decideur} في ${date}. السبب: ${motif}';
	@override String get erreurSuivi => 'تعذرت قراءة حالة طلب المصادقة. أعد المحاولة بعد قليل.';
	@override String get reessayer => 'إعادة المحاولة';
}

// Path: comptable.direction
class _Traductions$comptable$direction$ar extends Traductions$comptable$direction$fr {
	_Traductions$comptable$direction$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String versionDepuis({required Object version, required Object date}) => 'الإصدار ${version}، ساري المفعول منذ ${date}';
	@override String versionSansDate({required Object version}) => 'الإصدار ${version}';
	@override String auteur({required Object auteur}) => 'سجّله ${auteur}';
	@override String get enregistrer => 'تسجيل إصدار جديد';
	@override String get aucuneModification => 'لا يوجد تعديل للتسجيل.';
	@override String get corrigezChamps => 'صحّح الحقول المشار إليها للتسجيل.';
	@override String get enregistree => 'سُجّل الإصدار الجديد.';
	@override String get erreurEnregistrement => 'لا نعلم إن كان هذا الإصدار قد سُجّل. أعد قراءة الإصدار الساري، ثم أعد المحاولة.';
	@override String get enregistrementIndisponible => 'التسجيل غير متاح بعد. أعد المحاولة لاحقًا.';
	@override String get historique => 'سجل الإصدارات';
	@override String get historiqueVide => 'لا يوجد إصدار قبل هذا.';
	@override String get etatActuel => 'الحالة الحالية للاحتياطي';
	@override String get suffixeMois => 'أشهر';
	@override String get suffixeJours => 'أيام';
	@override String get suffixePourcent => '%';
	@override String get erreurNombre => 'أدخل عددًا صحيحًا أكبر من صفر.';
	@override String get erreurPourcentage => 'أدخل نسبة أكبر من صفر ولا تتجاوز 100، بمنزلة عشرية واحدة على الأكثر.';
	@override String get erreurMontant => 'أدخل مبلغًا أكبر من صفر.';
	@override late final _Traductions$comptable$direction$reservePanneau$ar reservePanneau = _Traductions$comptable$direction$reservePanneau$ar._(_root);
	@override late final _Traductions$comptable$direction$delegationPanneau$ar delegationPanneau = _Traductions$comptable$direction$delegationPanneau$ar._(_root);
	@override String get titre => 'الاحتياطي والتفويض';
	@override String get sousTitre => 'سياسة الاحتياطي الاستراتيجي وما يستطيع المحاسب تنفيذه وحده.';
	@override String get reserve => 'سياسة الاحتياطي الاستراتيجي';
	@override String get delegation => 'التفويض المالي';
}

// Path: comptable.demo
class _Traductions$comptable$demo$ar extends Traductions$comptable$demo$fr {
	_Traductions$comptable$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'عرض توضيحي للمحاسب';
	@override String get mention => 'بيانات وهمية، لا دفع، لا إرسال.';
	@override String get intro => 'اختر شاشة من شاشات المحاسب. المبالغ مخفية افتراضيًا؛ ونسخة «المبالغ ظاهرة» تكشفها طوال مدة الصفحة.';
	@override String get montantsMasques => 'المبالغ مخفية';
	@override String get montantsAffiches => 'المبالغ ظاهرة';
	@override String get groupeComptable => 'واجهة المحاسب';
	@override String get groupeCompte => 'الحساب والمستفيد';
	@override String get groupeDirection => 'الإدارة';
}

// Path: commun.etats.chargementProlonge
class _Traductions$commun$etats$chargementProlonge$ar extends Traductions$commun$etats$chargementProlonge$fr {
	_Traductions$commun$etats$chargementProlonge$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'يستغرق الاتصال وقتًا أطول من المتوقع';
	@override String get phrase => 'يمكنك الانتظار قليلًا أو إعادة المحاولة.';
}

// Path: commun.etats.horsLigne
class _Traductions$commun$etats$horsLigne$ar extends Traductions$commun$etats$horsLigne$fr {
	_Traductions$commun$etats$horsLigne$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'أنت غير متصل';
	@override String get phrase => 'تحقق من اتصالك. ما هو معروض يبقى متاحًا للاطلاع.';
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
	@override String get phrase => 'ربما يكون الرابط ناقصًا، أو لم تعد الصفحة موجودة.';
}

// Path: commun.etats.accesRefuse
class _Traductions$commun$etats$accesRefuse$ar extends Traductions$commun$etats$accesRefuse$fr {
	_Traductions$commun$etats$accesRefuse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ليس لديك وصول إلى هذه الصفحة';
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
	@override String get phrase => 'تبقى خطوة قبل فتح هذه المساحة.';
}

// Path: commun.etats.aucunResultat
class _Traductions$commun$etats$aucunResultat$ar extends Traductions$commun$etats$aucunResultat$fr {
	_Traductions$commun$etats$aucunResultat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'لا توجد نتائج';
	@override String get phrase => 'لا شيء مطابق حاليًا.';
}

// Path: commun.etats.permissionRefusee
class _Traductions$commun$etats$permissionRefusee$ar extends Traductions$commun$etats$permissionRefusee$fr {
	_Traductions$commun$etats$permissionRefusee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإذن مرفوض';
	@override String get phrase => 'دون هذا الإذن لا يمكن فتح هذه الوظيفة. يمكنك تعديله في إعدادات جهازك.';
}

// Path: commun.etats.ressourceExpiree
class _Traductions$commun$etats$ressourceExpiree$ar extends Traductions$commun$etats$ressourceExpiree$fr {
	_Traductions$commun$etats$ressourceExpiree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'هذا المحتوى لم يعد متاحًا';
	@override String get phrase => 'لقد سُحب، أو انتهى الوصول إليه.';
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

// Path: comptable.statuts.paiement
class _Traductions$comptable$statuts$paiement$ar extends Traductions$comptable$statuts$paiement$fr {
	_Traductions$comptable$statuts$paiement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aCalculer => 'قيد الحساب';
	@override String get calcule => 'محسوب';
	@override String get aVerifier => 'للتحقق';
	@override String get infosManquantes => 'معلومات الدفع ناقصة';
	@override String get verificationRequise => 'يلزم التحقق من الدفع';
	@override String get pretAPayer => 'جاهز للدفع';
	@override String get validationRequise => 'تلزم مصادقة إضافية';
	@override String get soumis => 'مُرسَل';
	@override String get enTransit => 'قيد التحويل';
	@override String get reussi => 'ناجح';
	@override String get echoue => 'فاشل';
	@override String get aRelancer => 'للتذكير';
	@override String get annule => 'ملغى';
	@override String get retourne => 'مُسترَد / مُعاد';
	@override String get indisponible => 'غير متاح';
}

// Path: comptable.statuts.encaissement
class _Traductions$comptable$statuts$encaissement$ar extends Traductions$comptable$statuts$encaissement$fr {
	_Traductions$comptable$statuts$encaissement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enAttente => 'قيد الانتظار';
	@override String get confirme => 'مؤكَّد';
	@override String get echoue => 'فاشل';
	@override String get rembourse => 'مُسترَد';
	@override String get partiellementRembourse => 'مُسترَد جزئيًا';
	@override String get conteste => 'متنازَع عليه';
	@override String get chargeback => 'استرجاع بنكي';
	@override String get aRapprocher => 'للمطابقة';
	@override String get rapproche => 'مطابَق';
}

// Path: comptable.statuts.rapprochement
class _Traductions$comptable$statuts$rapprochement$ar extends Traductions$comptable$statuts$rapprochement$fr {
	_Traductions$comptable$statuts$rapprochement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get automatique => 'تلقائي';
	@override String get aVerifier => 'للتحقق';
	@override String get rapproche => 'مطابَق';
	@override String get conflit => 'تعارض';
	@override String get sansCorrespondance => 'بلا مقابل';
	@override String get doublonPotentiel => 'تكرار محتمل';
}

// Path: comptable.statuts.profil
class _Traductions$comptable$statuts$profil$ar extends Traductions$comptable$statuts$profil$fr {
	_Traductions$comptable$statuts$profil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucunMoyen => 'لا توجد وسيلة';
	@override String get incomplet => 'غير مكتمل';
	@override String get enVerification => 'قيد التحقق';
	@override String get verifie => 'تم التحقق';
	@override String get suspendu => 'موقوف';
	@override String get actionRequise => 'يلزم إجراء';
	@override String get invitationEnvoyee => 'أُرسلت الدعوة';
}

// Path: comptable.statuts.capacite
class _Traductions$comptable$statuts$capacite$ar extends Traductions$comptable$statuts$capacite$fr {
	_Traductions$comptable$statuts$capacite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get prisEnCharge => 'مدعوم';
	@override String get nonPrisEnCharge => 'غير مدعوم';
	@override String get temporairementIndisponible => 'غير متاح مؤقتًا';
	@override String get verificationRequise => 'يلزم التحقق';
	@override String get soldePrestataireInsuffisant => 'رصيد مزوّد الدفع غير كافٍ';
}

// Path: comptable.statuts.reserve
class _Traductions$comptable$statuts$reserve$ar extends Traductions$comptable$statuts$reserve$fr {
	_Traductions$comptable$statuts$reserve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get atteint => 'تحقق الهدف';
	@override String get sousObjectif => 'دون الهدف';
	@override String get depassement => 'تجاوز الهدف';
	@override String get regleInactive => 'القاعدة غير مفعّلة';
	@override String get alimentationPrevue => 'تغذية مقررة';
	@override String get mouvementSensible => 'حركة حساسة';
}

// Path: comptable.statuts.obligation
class _Traductions$comptable$statuts$obligation$ar extends Traductions$comptable$statuts$obligation$fr {
	_Traductions$comptable$statuts$obligation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get brouillon => 'مسودة';
	@override String get aApprouver => 'للاعتماد';
	@override String get approuvee => 'معتمَد';
	@override String get refusee => 'مرفوض';
	@override String get payable => 'قابل للدفع';
	@override String get payee => 'مدفوع';
	@override String get annulee => 'ملغى';
}

// Path: comptable.statuts.remboursement
class _Traductions$comptable$statuts$remboursement$ar extends Traductions$comptable$statuts$remboursement$fr {
	_Traductions$comptable$statuts$remboursement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get demande => 'مطلوب';
	@override String get approbationRequise => 'يلزم الاعتماد';
	@override String get approuve => 'معتمَد';
	@override String get execute => 'منفَّذ';
	@override String get refuse => 'مرفوض';
}

// Path: comptable.statuts.validation
class _Traductions$comptable$statuts$validation$ar extends Traductions$comptable$statuts$validation$fr {
	_Traductions$comptable$statuts$validation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enAttente => 'طُلبت المصادقة';
	@override String get validee => 'تمت المصادقة';
	@override String get refusee => 'مرفوضة';
}

// Path: comptable.statuts.raison
class _Traductions$comptable$statuts$raison$ar extends Traductions$comptable$statuts$raison$fr {
	_Traductions$comptable$statuts$raison$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get autoPaiement => 'يلزم أن يعالجه مسؤول آخر';
	@override String get validationRequise => 'تلزم مصادقة إضافية';
	@override String get infosManquantes => 'معلومات الدفع ناقصة';
	@override String get verificationRequise => 'يلزم التحقق من الدفع';
	@override String get horsDelegation => 'خارج التفويض';
	@override String get fournisseurIndisponible => 'المزوّد غير متاح';
	@override String get fondsInsuffisants => 'الأموال غير كافية';
	@override String get doublonPotentiel => 'تكرار محتمل';
	@override String get nonApprouvee => 'التزام غير معتمَد';
	@override String get capaciteAbsente => 'القدرة غير متوفرة';
}

// Path: comptable.paiements.confirmation
class _Traductions$comptable$paiements$confirmation$ar extends Traductions$comptable$paiements$confirmation$fr {
	_Traductions$comptable$paiements$confirmation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titreUn => 'تأكيد الدفعة';
	@override String get titreLot => 'تأكيد الدفعة المجمّعة';
	@override String get titreValidation => 'طلب مصادقة';
	@override String get payerMaintenant => 'ادفع الآن';
	@override String get controleEchoueTitre => 'توقف الفحص';
	@override String get controleEchoue => 'لم يكتمل فحص التحديد. لم يُرسَل أي شيء. أعد تشغيل الفحص.';
	@override String get relancerControle => 'إعادة تشغيل الفحص';
	@override String get montant => 'المبلغ الدقيق';
	@override String get beneficiaire => 'المستفيد';
	@override String get devise => 'العملة';
	@override String get type => 'النوع';
	@override String get periode => 'الفترة / الموضوع';
	@override String get prestataire => 'مزوّد الدفع المقرر';
	@override String get prestataireAucun => 'لم يُرجعه المصدر';
	@override String get taux => 'سعر الصرف';
	@override String tauxDate({required Object taux, required Object date}) => '${taux}، بتاريخ ${date}';
	@override String get frais => 'رسوم مزوّد الدفع';
	@override String get change => 'تكلفة الصرف';
	@override String get montantEnvoye => 'إجمالي المُرسَل';
	@override String get montantRecu => 'المبلغ المتوقع استلامه';
	@override String get controlesTitre => 'الفحوص المجتازة';
	@override String get controlesPhrase => 'المبلغ محسوب، ووسيلة الدفع متحقَّق منها، والتفويض والتكرارات مفحوصة من المصدر. لن تُرسَل إلا المدفوعات الجاهزة.';
	@override String get sensiblePhrase => 'هذه الدفعة حساسة: يجب أن يصادق عليها شخص مخوَّل آخر. اطلب المصادقة، فهي لا تُرسَل قبلها.';
	@override String prets({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'دفعة جاهزة واحدة',
		two: 'دفعتان جاهزتان',
		few: '${n} دفعات جاهزة',
		other: '${n} دفعة جاهزة',
	);
	@override String exclus({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'دفعة مستبعدة واحدة',
		two: 'دفعتان مستبعدتان',
		few: '${n} دفعات مستبعدة',
		other: '${n} دفعة مستبعدة',
	);
	@override String get total => 'إجمالي المدفوعات الجاهزة';
	@override String get beneficiairesCle => 'المستفيدون';
	@override String beneficiaires({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'مستفيد واحد',
		two: 'مستفيدان',
		few: '${n} مستفيدين',
		other: '${n} مستفيدًا',
	);
	@override String get devises => 'العملات';
	@override String get prestataires => 'مزوّدو الدفع';
	@override String get plafond => 'التفويض المتبقي';
	@override String get exclusTitre => 'مستبعدة من هذه الدفعة المجمّعة: لن تُرسَل';
	@override String get aucunPretTitre => 'لا توجد دفعة جاهزة';
	@override String get aucunPret => 'لن يُرسَل أي شيء. افتح كل دفعة مستبعدة لإزالة سببها، ثم أعد تشغيل الفحص.';
	@override String get erreursTitre => 'أخطاء أرجعها الفحص';
	@override String confirmerUn({required Object montant}) => 'تأكيد دفع ${montant}';
	@override String confirmerLot({required num n, required Object montants}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'تأكيد الدفعة الجاهزة بمبلغ ${montants}',
		two: 'تأكيد الدفعتين الجاهزتين: ${montants}',
		few: 'تأكيد ${n} دفعات جاهزة: ${montants}',
		other: 'تأكيد ${n} دفعة جاهزة: ${montants}',
	);
	@override String get demanderValidation => 'طلب المصادقة';
	@override String get annuler => 'إلغاء';
	@override String get fermer => 'إغلاق';
	@override String get soumisTitre => 'أُرسلت إلى مزوّد الدفع';
	@override String get soumisPhrase => 'الدفعة المُرسَلة لم تُستلَم بعد: حالتها تأتي من متابعة مزوّد الدفع. حدّث المتابعة لترى تقدمها.';
	@override String get actualiser => 'تحديث المتابعة';
	@override String get suiviEchoue => 'تعذرت قراءة المتابعة. تبقى الدفعة مُرسَلة: حدّث مرة أخرى بعد قليل.';
	@override String get referenceCle => 'مرجع مزوّد الدفع';
	@override String get recalculeTitre => 'أُعيد حساب المبلغ';
	@override String get recalculePhrase => 'تغيّر حساب في المصدر منذ الفحص. لم يُرسَل أي شيء. أعد تشغيل الفحص لتأكيد المبلغ الجديد.';
	@override String nouveauMontant({required Object nom}) => 'المبلغ الجديد لـ ${nom}';
	@override String get refusTitre => 'رفض المصدر الدفعة';
	@override String get refusDejaSoumis => 'سبق إرسال هذه الدفعة: لن يُعاد إرسال أي شيء. تابعها من تبويب المدفوعات الجارية.';
	@override String get refusHorsDelegation => 'يتجاوز المجموع تفويضك، لكل مستفيد أو لكل فترة. لم يُرسَل أي شيء. أعد تشغيل الفحص: ستُستبعد المدفوعات المعنية.';
	@override String get refusPerime => 'انتهت صلاحية الفحص. لم يُرسَل أي شيء. أعد تشغيل الفحص قبل التأكيد.';
	@override String get refusFournisseur => 'أصبح مزوّد الدفع غير متاح. لم يُرسَل أي شيء. أعد تشغيل الفحص بعد قليل.';
	@override String get inconnuTitre => 'نتيجة غير معروفة';
	@override String get inconnuPhrase => 'لم يصلنا الرد: ربما أُرسلت الدفعة. أعد المحاولة: يُعاد إرسال الطلب نفسه ولن يُنفَّذ إلا مرة واحدة.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get validationDemandeeTitre => 'طُلبت المصادقة';
	@override String get validationDemandeePhrase => 'سيصادق شخص مخوَّل آخر على هذه الدفعة. لن تُرسَل قبل قراره.';
	@override String get validationEchouee => 'لم يكتمل طلب المصادقة. أعد المحاولة: لن يُسجَّل إلا مرة واحدة.';
}

// Path: comptable.paiements.filtres
class _Traductions$comptable$paiements$filtres$ar extends Traductions$comptable$paiements$filtres$fr {
	_Traductions$comptable$paiements$filtres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tous => 'الكل';
	@override String get enseignants => 'المعلمون';
	@override String get contractuels => 'المتعاقدون';
	@override String get statut => 'الحالة';
	@override String get tousStatuts => 'كل الحالات';
	@override String get prets => 'جاهزة';
	@override String get infos => 'معلومات ناقصة';
	@override String get verification => 'التحقق';
	@override String get validation => 'المصادقة';
	@override String get retard => 'متأخرة';
	@override String get classe => 'الفصل';
	@override String get toutesClasses => 'كل الفصول';
	@override String get periode => 'الفترة';
	@override String get toutesPeriodes => 'كل الفترات';
	@override String get effacer => 'مسح عوامل التصفية';
}

// Path: comptable.paiements.colonnes
class _Traductions$comptable$paiements$colonnes$ar extends Traductions$comptable$paiements$colonnes$fr {
	_Traductions$comptable$paiements$colonnes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get beneficiaire => 'المستفيد';
	@override String get type => 'النوع';
	@override String get periode => 'الفترة / الموضوع';
	@override String get montant => 'المبلغ';
	@override String get destination => 'الوجهة';
	@override String get echeance => 'الاستحقاق';
	@override String get statut => 'الحالة';
	@override String get action => 'الإجراء';
}

// Path: comptable.paiements.types
class _Traductions$comptable$paiements$types$ar extends Traductions$comptable$paiements$types$fr {
	_Traductions$comptable$paiements$types$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enseignant => 'معلم';
	@override String get contractuel => 'متعاقد';
}

// Path: comptable.paiements.actions
class _Traductions$comptable$paiements$actions$ar extends Traductions$comptable$paiements$actions$fr {
	_Traductions$comptable$paiements$actions$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get voir => 'عرض';
	@override String get payer => 'دفع';
	@override String get demanderValidation => 'طلب المصادقة';
	@override String get relancer => 'تذكير';
	@override String get signalerEcart => 'الإبلاغ عن فرق';
	@override String selectionner({required Object nom}) => 'تحديد دفعة ${nom}';
	@override String get selectionnerPrets => 'تحديد كل المدفوعات الجاهزة';
	@override String get payerSelection => 'دفع المحدد';
	@override String get viderSelection => 'إلغاء التحديد';
	@override String get voirProfil => 'عرض ملف الدفع';
}

// Path: comptable.paiements.vide
class _Traductions$comptable$paiements$vide$ar extends Traductions$comptable$paiements$vide$fr {
	_Traductions$comptable$paiements$vide$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'لا توجد مدفوعات للتنفيذ.';
	@override String get invitation => 'تظهر الالتزامات هنا بمجرد حسابها في المصدر.';
	@override String get filtreMessage => 'لا توجد دفعة تطابق عوامل التصفية هذه.';
	@override String get filtreInvitation => 'امسح عوامل التصفية لرؤية كل المدفوعات مجددًا.';
}

// Path: comptable.paiements.detail
class _Traductions$comptable$paiements$detail$ar extends Traductions$comptable$paiements$detail$fr {
	_Traductions$comptable$paiements$detail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get total => 'الإجمالي المستحق';
	@override String get lignes => 'تفاصيل الحساب';
	@override String get ligneTotal => 'الإجمالي';
	@override String source({required Object source}) => 'المصدر: ${source}';
	@override String auteur({required Object auteur}) => 'أضافه ${auteur}';
	@override String get voirSource => 'عرض المصدر';
	@override String get methode => 'وسيلة الدفع';
	@override String get informations => 'المعلومات';
	@override String get type => 'النوع';
	@override String get periode => 'الفترة / الموضوع';
	@override String get echeance => 'الاستحقاق';
	@override String get prestataire => 'مزوّد الدفع المقرر';
	@override String get preuve => 'الإثبات';
	@override String get classes => 'الفصول';
	@override String get version => 'إصدار الحساب';
	@override String get historique => 'السجل';
	@override String get historiqueVide => 'لا توجد عملية مسجلة لهذه الدفعة.';
	@override String get encart => 'لا يستطيع المحاسب تعديل المبلغ ولا بيانات الدفع الخاصة بالمستفيد.';
	@override String alerteMethodeRecente({required Object date}) => 'عُدّلت وسيلة الدفع في ${date}: تلزم مصادقة إضافية قبل أي دفع.';
	@override String get alerteLieeOperateur => 'المستفيد مرتبط بالمنفِّذ: تلزم مصادقة إضافية قبل أي دفع.';
	@override String get alerteEchec => 'فشل آخر إرسال لدى مزوّد الدفع. تحقق من وسيلة الدفع قبل محاولة جديدة.';
	@override String get alerteInfos => 'ليست لدى المستفيد بعد وسيلة دفع مكتملة. ذكّره من ملف الدفع الخاص به.';
	@override String get alerteTitre => 'ما يجب معرفته قبل الدفع';
	@override String get autoPaiementPhrase => 'هذه الدفعة تخصك: سيعالجها شخص مخوَّل آخر. لا يمكن لأحد تنفيذ دفعته بنفسه.';
	@override String get introuvableTitre => 'هذه الدفعة غير موجودة.';
	@override String get introuvablePhrase => 'عد إلى قائمة المدفوعات للتنفيذ لاختيار دفعة أخرى.';
}

// Path: comptable.paiements.ecart
class _Traductions$comptable$paiements$ecart$ar extends Traductions$comptable$paiements$ecart$fr {
	_Traductions$comptable$paiements$ecart$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإبلاغ عن فرق';
	@override String get phrase => 'اختر السطر وما الخطأ فيه. يتم التصحيح في المصدر، ثم يُعاد حساب المبلغ.';
	@override String get ligne => 'السطر المعني';
	@override String get motif => 'ما الخطأ';
	@override late final _Traductions$comptable$paiements$ecart$motifs$ar motifs = _Traductions$comptable$paiements$ecart$motifs$ar._(_root);
	@override String get envoyer => 'إرسال البلاغ';
	@override String get annuler => 'إلغاء';
	@override String envoye({required Object date}) => 'أُبلغ عن الفرق في ${date}. يبقى المبلغ كما في المصدر حتى إعادة الحساب.';
	@override String get erreurEnvoi => 'لم يكتمل البلاغ. أعد المحاولة: لن يُسجَّل إلا مرة واحدة.';
}

// Path: comptable.tresorerie.descriptions
class _Traductions$comptable$tresorerie$descriptions$ar extends Traductions$comptable$tresorerie$descriptions$fr {
	_Traductions$comptable$tresorerie$descriptions$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get fondsClientsEngages => 'أموال مقبوضة مرتبطة بخدمات لم تُستحق بعد.';
	@override String get paieADecaisser => 'أجور محسوبة ومستحقة.';
	@override String get chargesEssentielles => 'البنية التحتية والاشتراكات الضرورية والوظائف الثابتة.';
	@override String get taxesObligations => 'مخصص للالتزامات الضريبية أو الاجتماعية أو التنظيمية.';
	@override String get reserveStrategique => 'صندوق الاستمرارية والأمان.';
	@override String get enTransit => 'أموال ملتزَم بها في عملية لم تُؤكَّد بعد.';
	@override String get tresorerieLibre => 'ما يبقى متاحًا فعلًا بعد التخصيصات المحمية.';
}

// Path: comptable.tresorerie.regle
class _Traductions$comptable$tresorerie$regle$ar extends Traductions$comptable$tresorerie$regle$fr {
	_Traductions$comptable$tresorerie$regle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get desactivee => 'معطّلة';
	@override String get montantFixe => 'مبلغ ثابت في كل موعد';
	@override String pourcentage({required Object pourcent}) => '${pourcent} % من كل مقبوض مُثبَّت';
	@override String get jusquAObjectif => 'الإكمال حتى المبلغ المستهدف';
	@override String get proposee => 'اقتراح يتطلب تأكيدك';
}

// Path: comptable.tresorerie.cadences
class _Traductions$comptable$tresorerie$cadences$ar extends Traductions$comptable$tresorerie$cadences$fr {
	_Traductions$comptable$tresorerie$cadences$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get clotureCycle => 'عند كل إقفال دورة';
	@override String get hebdomadaire => 'كل أسبوع';
	@override String get mensuelle => 'كل شهر';
	@override String get apresEncaissementConsolide => 'بعد كل مقبوض مُثبَّت';
	@override String get manuelle => 'يدوية';
}

// Path: comptable.tresorerie.transfert
class _Traductions$comptable$tresorerie$transfert$ar extends Traductions$comptable$tresorerie$transfert$fr {
	_Traductions$comptable$tresorerie$transfert$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'حركة بين الصناديق';
	@override String get choix => 'حركة تسمح بها السياسة';
	@override String couple({required Object origine, required Object destination}) => '${origine} ← ${destination}';
	@override String get delegable => 'نحو الحماية: تُنفَّذ حسب تفويضك.';
	@override String get sensible => 'تلزم مصادقة إضافية: يقرر شخص آخر، ولا يخرج شيء من الصندوق قبل ذلك.';
	@override String get montant => 'المبلغ';
	@override String montantAide({required Object devise}) => 'بوحدات صحيحة، ${devise}.';
	@override String get montantPropose => 'المبلغ الذي تقترحه السياسة';
	@override String get utiliserPropose => 'استخدام المبلغ المقترح';
	@override String get erreurMontant => 'أدخل مبلغًا صحيحًا أكبر من صفر.';
	@override String get verifier => 'مراجعة الحركة';
	@override String get recapPhrase => 'راجع المبلغ الدقيق قبل الإرسال.';
	@override String get de => 'من';
	@override String get vers => 'إلى';
	@override String get confirmer => 'تأكيد الحركة';
	@override String get demanderValidation => 'طلب المصادقة';
	@override String get modifier => 'تعديل الحركة';
	@override String get fermer => 'إغلاق';
	@override String get executeTitre => 'نفّذ المصدر الحركة';
	@override String get executePhrase => 'سجّلها السجل. يُعاد قراءة الأرصدة المعروضة.';
	@override String reference({required Object reference}) => 'المرجع: ${reference}';
	@override String get validationTitre => 'طُلبت المصادقة';
	@override String get validationPhrase => 'يجب أن يقرر شخص آخر. يبقى الصندوق المصدر دون تغيير حتى ذلك الحين.';
	@override String get refusTitre => 'رفض المصدر الحركة';
	@override String refusPhrase({required Object raison}) => 'السبب: ${raison}. لم يُنقَل أي شيء.';
	@override String get erreurEnvoiTitre => 'لم يصل الرد';
	@override String get erreurEnvoi => 'لم يصل الرد. راجع السجل قبل إعادة المحاولة: لن تُحسب الحركة نفسها مرتين أبدًا.';
	@override String get indisponible => 'الحركات بين الصناديق غير مربوطة بالخادم بعد. لم يُنقَل أي شيء.';
	@override String get aucunCouple => 'لا تسمح السياسة بأي حركة لحسابك.';
}

// Path: comptable.encaissements.rap
class _Traductions$comptable$encaissements$rap$ar extends Traductions$comptable$encaissements$rap$fr {
	_Traductions$comptable$encaissements$rap$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get vueTransactions => 'للمطابقة';
	@override String get vueRemboursements => 'الاستردادات';
	@override String get natPaiementAttendu => 'دفعة متوقعة';
	@override String get natTransaction => 'معاملة مزوّد الدفع';
	@override String get natMensualite => 'رصيد أو قسط شهري';
	@override String get natFrais => 'رسوم';
	@override String get natRemboursement => 'استرداد';
	@override String get natPayout => 'صرف دفعة';
	@override String get natPreuve => 'إثبات';
	@override String natureDate({required Object nature, required Object date}) => '${nature} · ${date}';
	@override String get choisirTitre => 'اختر معاملة.';
	@override String get choisirPhrase => 'تُفتح هنا المطابقات المقترحة لها وحالتها وسجلها.';
	@override String get videTitre => 'لا شيء للمطابقة.';
	@override String get videPhrase => 'كل معاملة مستلَمة مرتبطة بالفعل بما كان ينتظرها.';
	@override String get videFiltreTitre => 'لا توجد معاملة بهذه الحالة.';
	@override String get videFiltrePhrase => 'اختر «الكل» لرؤية كل المعاملات.';
	@override String get voirToutes => 'عرض كل المعاملات';
	@override String ouvrirLecteur({required Object libelle}) => 'فتح مطابقة ${libelle}';
	@override String get candidats => 'المطابقات المقترحة';
	@override String get candidatsAucun => 'لا يقترح المصدر أي مطابقة لهذه المعاملة.';
	@override String relieA({required Object libelle}) => 'مرتبطة بـ: ${libelle}';
	@override String get rapprocher => 'مطابقة';
	@override String rapprocherLecteur({required Object libelle}) => 'المطابقة مع ${libelle}';
	@override String get doublonTitre => 'تكرار محتمل';
	@override String get doublonPhrase => 'تشبه هذه المعاملة معاملة أخرى مستلَمة سابقًا. تحقق قبل المطابقة: لا يُقبل التكرار أبدًا بصمت.';
	@override String get marquerDoublon => 'وضع علامة تكرار';
	@override String resultat({required Object etat}) => 'الحالة التي أرجعها المصدر: ${etat}';
	@override String get erreurEnvoi => 'لا نعلم إن كانت العملية قد سُجّلت. حدّث القائمة قبل إعادة المحاولة.';
	@override String get actualiser => 'تحديث';
	@override String get journal => 'سجل المعاملة';
	@override String get journalVide => 'لا توجد عملية مسجلة لهذه المعاملة.';
	@override String get beneficiaire => 'المستفيد';
	@override String get motif => 'السبب';
	@override String get montant => 'المبلغ';
	@override String get source => 'المصدر';
	@override String demandeLe({required Object date}) => 'طُلب في ${date}';
	@override String get approbationRequise => 'تشترط السياسة الاعتماد';
	@override String get approbationNon => 'دون اعتماد حسب السياسة';
	@override String get politiqueNote => 'قواعد الاسترداد جزء من سياسة المالية. هنا نطبّقها ولا نعيد كتابتها.';
	@override String get executer => 'تنفيذ الاسترداد';
	@override String executerLecteur({required Object beneficiaire}) => 'تنفيذ استرداد ${beneficiaire}';
	@override String get executerTitre => 'تنفيذ هذا الاسترداد؟';
	@override String get executerPhrase => 'المبلغ والشروط مصدرها سياسة المالية. سيؤكد مزوّد الدفع التنفيذ.';
	@override String get remboursementsVideTitre => 'لا يوجد استرداد ولا رصيد دائن جارٍ.';
	@override String get journalRemboursement => 'سجل الاسترداد';
	@override String get journalRemboursementVide => 'لا توجد عملية مسجلة لهذا الاسترداد.';
	@override String get erreurEnvoiTitre => 'عملية غير مؤكدة';
	@override String get remboursementsVidePhrase => 'ستظهر هنا طلبات الاسترداد مع سببها وحالتها.';
}

// Path: comptable.beneficiaires.profil
class _Traductions$comptable$beneficiaires$profil$ar extends Traductions$comptable$beneficiaires$profil$fr {
	_Traductions$comptable$beneficiaires$profil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String carteTitre({required Object nom}) => 'ملف الدفع الخاص بـ ${nom}';
	@override String get etat => 'حالة الملف';
	@override String get derniereModification => 'آخر تعديل';
	@override String get capacite => 'قدرة الدفع في هذا المسار';
	@override String get capaciteNonEvaluee => 'لم تُقيَّم بعد';
	@override String get enAttente => 'مدفوعات تنتظر هذا الملف';
	@override String proprietaire({required Object nom}) => 'وحده ${nom} يمكنه إدخال بيانات الدفع الخاصة به أو تعديلها. أنت ترى نسخة مخفية منها.';
	@override String get historiqueTitre => 'سجل المدفوعات';
	@override String get historiqueVide => 'لم تُصرف أي دفعة لهذا المستفيد حتى الآن.';
	@override String get journalTitre => 'سجل الملف';
	@override String get journalVide => 'لا يوجد أي تعديل مسجل على هذا الملف حتى الآن.';
	@override String get actionsTitre => 'ما العمل لهذا الملف';
	@override String relancer({required Object nom}) => 'تذكير ${nom}';
	@override String get relancerDetail => 'يفتح محادثة «ملف الدفع» برسالة معدّة مسبقًا، في رسائل العمل.';
	@override String demanderMiseAJour({required Object nom}) => 'طلب تحديث من ${nom}';
	@override String suspendre({required Object nom}) => 'إيقاف مدفوعات ${nom}';
	@override String reprendre({required Object nom}) => 'استئناف مدفوعات ${nom}';
	@override String get voirFil => 'عرض محادثة «ملف الدفع»';
	@override String externe({required Object nom}) => 'ليس لدى ${nom} حساب Rewayah: تتيح له دعوة آمنة إدخال وسيلته بنفسه. أعد إرسالها من التزامه، في المتعاقدين.';
	@override String get voirContractuels => 'عرض التزامات المتعاقدين';
	@override String get aucuneAction => 'لا يوجد أي إجراء مفتوح على هذا الملف: إنه محدَّث.';
	@override String get relanceTitre => 'رسالة جاهزة في محادثة «ملف الدفع»';
	@override String get relanceObjet => 'الموضوع: ملف الدفع';
	@override String get messageModele => 'يجب إكمال معلومات الدفع الخاصة بك قبل دفعتك القادمة. يمكنك إضافتها من مساحتك الشخصية.';
	@override String miseAJourDemandee({required Object nom}) => 'سُجّل طلب التحديث لـ ${nom}.';
	@override String suspendus({required Object nom}) => 'أُوقفت مدفوعات ${nom}: لن تُصرف أي دفعة ما لم تُستأنف.';
	@override String repris({required Object nom}) => 'استُؤنفت مدفوعات ${nom}.';
	@override String get erreurAction => 'لم يكتمل الإجراء. تحقق من اتصالك، ثم أعد المحاولة.';
	@override String get erreurIndisponible => 'هذا الإجراء غير مربوط بعد بالخدمة التي تعالجه. أعد المحاولة لاحقًا.';
	@override String suspensionTitre({required Object nom}) => 'إيقاف مدفوعات ${nom}؟';
	@override String get suspensionContexte => 'لن تُصرف أي دفعة لهذا المستفيد ما لم تستأنفها. لن تتغير بياناته. اختر السبب: سيُدوَّن في سجل الملف.';
	@override String get motifVerifier => 'بيانات تحتاج إلى تحقق';
	@override String get motifVerifierDetail => 'تبدو الوسيلة غير صحيحة أو تعذّر تأكيدها.';
	@override String get motifAnomalie => 'خلل مُبلَّغ عنه';
	@override String get motifAnomalieDetail => 'فشلت دفعة حديثة أو أُبلغ عن فرق.';
	@override String get motifDemande => 'طلب من المستفيد';
	@override String get motifDemandeDetail => 'طلب المستفيد عدم استلام أي دفعة حاليًا.';
	@override String get motifRequis => 'اختر سببًا للمتابعة.';
}

// Path: comptable.beneficiaires.recevoir
class _Traductions$comptable$beneficiaires$recevoir$ar extends Traductions$comptable$beneficiaires$recevoir$fr {
	_Traductions$comptable$beneficiaires$recevoir$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get rubrique => 'المدفوعات';
	@override String get ligneDetail => 'وسائل الدفع الخاصة بك، تديرها أنت وحدك.';
	@override String get noticeDetail => 'أضف وسيلة دفع لتتمكن الأكاديمية من صرف دفعتك القادمة.';
	@override String get phraseAucunMoyen => 'ليست لديك أي وسيلة دفع بعد. أضف واحدة لاستلام دفعاتك.';
	@override String get phraseIncomplet => 'وسيلة الدفع الخاصة بك غير مكتملة. أكملها لاستلام دفعتك القادمة.';
	@override String get phraseEnVerification => 'وسيلتك الجديدة قيد التحقق. تُحدَّث حالتها هنا.';
	@override String get phraseVerifie => 'تم التحقق من وسيلة الدفع الخاصة بك. ستُرسَل إليها دفعاتك القادمة.';
	@override String get phraseSuspendu => 'دفعاتك موقوفة. تواصل مع الأكاديمية لمعرفة السبب.';
	@override String get phraseActionRequise => 'مطلوب تحديث وسيلة الدفع الخاصة بك. استبدلها لاستلام دفعتك القادمة.';
	@override String get phraseInvitationEnvoyee => 'أُرسلت إليك دعوة آمنة. أضف وسيلة الدفع الخاصة بك لإكمالها.';
	@override String get suspenduTemporairement => 'دفعاتك موقوفة ريثما يتم التحقق من وسيلتك الجديدة: هذه حماية من الاحتيال.';
	@override String get mesMethodes => 'وسائل الدفع الخاصة بي';
	@override String get preferee => 'الوسيلة المفضلة';
	@override String get inactive => 'وسيلة سابقة، محفوظة غير مفعّلة';
	@override String choisirPreferee({required Object methode}) => 'جعل ${methode} وسيلتي المفضلة';
	@override String remplacer({required Object methode}) => 'استبدال ${methode}';
	@override String supprimer({required Object methode}) => 'حذف ${methode}';
	@override String supprimerQuestion({required Object methode}) => 'حذف ${methode}؟';
	@override String get supprimerConsequence => 'لن تستلم بعد الآن أي دفعة على هذه الوسيلة. إن كانت الوحيدة، فستنتظر دفعتك القادمة وسيلة جديدة.';
	@override String get ajouter => 'إضافة وسيلة دفع';
	@override String get ajoutTitre => 'إضافة وسيلة دفع';
	@override String remplacementTitre({required Object methode}) => 'استبدال ${methode}';
	@override String get ajoutContexte => 'اختر نوع الوسيلة. ستُدخل بعد ذلك بياناتك في مساحة آمنة: التطبيق لا يراها ولا يحتفظ بها.';
	@override String get continuerSaisie => 'المتابعة إلى الإدخال الآمن';
	@override String get typeRequis => 'اختر نوع وسيلة للمتابعة.';
	@override String get aucunType => 'لا يُقترح أي نوع وسيلة حاليًا. تواصل مع الأكاديمية لفتح نوع.';
	@override String get verificationAnnoncee => 'يُتحقَّق من كل تغيير قبل الدفعة القادمة.';
	@override String get ajoutee => 'أُضيفت الوسيلة: إنها قيد التحقق.';
	@override String get remplacee => 'سُجّلت الوسيلة الجديدة: إنها قيد التحقق.';
	@override String get supprimee => 'حُذفت الوسيلة.';
	@override String get prefereeChoisie => 'حُدّثت الوسيلة المفضلة.';
	@override String get erreurAction => 'لم يكتمل التغيير. تحقق من اتصالك، ثم أعد المحاولة.';
	@override String get erreurIndisponible => 'هذا التغيير غير مربوط بعد بخدمة الدفع. أعد المحاولة لاحقًا.';
	@override String get journalTitre => 'سجل تغييراتي';
	@override String get journalVide => 'لا يوجد أي تغيير مسجل حتى الآن.';
	@override String get seulVous => 'أنت وحدك يمكنك تعديل هذه المعلومات: لا المحاسبة ولا الإدارة تستطيع ذلك نيابة عنك.';
	@override String get titre => 'استلام مدفوعاتي';
	@override String get sousTitre => 'بيانات الدفع الخاصة بك، لا يعدّلها أحد سواك.';
	@override String get notice => 'معلومات دفع يجب إكمالها';
	@override String get configurer => 'إعداد مدفوعاتي';
}

// Path: comptable.validation.natures
class _Traductions$comptable$validation$natures$ar extends Traductions$comptable$validation$natures$fr {
	_Traductions$comptable$validation$natures$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get payoutSensible => 'دفعة حساسة';
	@override String get retraitReserve => 'السحب من الاحتياطي الاستراتيجي';
	@override String get obligationAApprouver => 'التزام لمرة واحدة';
	@override String get payoutDuComptable => 'أجر المحاسب';
	@override String get sortieCoffreProtege => 'الخروج من صندوق محمي';
}

// Path: comptable.validation.detail
class _Traductions$comptable$validation$detail$ar extends Traductions$comptable$validation$detail$fr {
	_Traductions$comptable$validation$detail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'طلب مصادقة';
	@override String get nature => 'النوع';
	@override String get objet => 'الموضوع';
	@override String get demandeur => 'طلبه';
	@override String get date => 'تاريخ الطلب';
	@override String get raison => 'السبب';
	@override String get montant => 'المبلغ الدقيق';
	@override String get etat => 'الحالة';
	@override String get historique => 'السجل';
	@override String get historiqueVide => 'لا يوجد أي إدخال حتى الآن.';
}

// Path: comptable.validation.motifs
class _Traductions$comptable$validation$motifs$ar extends Traductions$comptable$validation$motifs$fr {
	_Traductions$comptable$validation$motifs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get coordonnees => 'بيانات المستفيد تحتاج إلى تحقق';
	@override String get montant => 'المبلغ يحتاج إلى تحقق في المصدر';
	@override String get justificatif => 'المستند المؤيِّد ناقص أو غير مقروء';
	@override String get reserve => 'خارج سياسة الاحتياطي';
	@override String get reporter => 'يؤجَّل إلى الدورة القادمة';
	@override String get autre => 'آخر';
}

// Path: comptable.direction.reservePanneau
class _Traductions$comptable$direction$reservePanneau$ar extends Traductions$comptable$direction$reservePanneau$fr {
	_Traductions$comptable$direction$reservePanneau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'أنت تحدد السياسة؛ والمحاسب يقرؤها وينفّذها. كل تسجيل يُنشئ إصدارًا جديدًا يُحفظ في السجل.';
	@override String get objectifTitre => 'هدف الاحتياطي';
	@override String get objectifDetail => 'ما يجب أن يبلغه الاحتياطي الاستراتيجي.';
	@override String get modeFixe => 'مبلغ ثابت';
	@override String get modeFixeDetail => 'مبلغ محدد تختاره أنت.';
	@override String get modeMois => 'تغطية بالأشهر';
	@override String get modeMoisDetail => 'عدد من أشهر المصاريف الأساسية.';
	@override String get montantCible => 'المبلغ المستهدف';
	@override String get montantCibleDetail => 'المبلغ الذي يجب أن يبلغه الاحتياطي الاستراتيجي.';
	@override String get nombreMois => 'عدد أشهر التغطية';
	@override String get nombreMoisDetail => 'كم شهرًا من المصاريف الأساسية يجب أن يغطي الاحتياطي.';
	@override String get alimentationTitre => 'التغذية التلقائية';
	@override String get alimentationDetail => 'كيف يمتلئ الاحتياطي دون تدخل من المحاسب.';
	@override late final _Traductions$comptable$direction$reservePanneau$regle$ar regle = _Traductions$comptable$direction$reservePanneau$regle$ar._(_root);
	@override String get montantAuto => 'المبلغ المخصَّص';
	@override String get montantAutoDetail => 'المبلغ المخصَّص للاحتياطي في كل موعد.';
	@override String get pourcentageAuto => 'حصة المقبوض المُثبَّت';
	@override String get pourcentageAutoDetail => 'الحصة المخصَّصة للاحتياطي في كل موعد.';
	@override String get cadenceTitre => 'الوتيرة';
	@override String get cadenceDetail => 'متى تتم التغذية.';
	@override late final _Traductions$comptable$direction$reservePanneau$cadence$ar cadence = _Traductions$comptable$direction$reservePanneau$cadence$ar._(_root);
	@override String get seuilTitre => 'التنبيه';
	@override String get seuil => 'حد التنبيه';
	@override String get seuilDetail => 'دون هذه الحصة من الهدف، يُشار إلى الاحتياطي بأنه «دون الهدف». اتركه فارغًا لعدم تحديد أي حد.';
	@override String get seuilIndice => 'بلا حد';
	@override String get retraitTitre => 'السحب';
	@override String get retraitSwitch => 'السحب يتطلب مصادقة إضافية';
	@override String get retraitSwitchDetail => 'إخراج المال من الاحتياطي عملية حساسة: يصادق عليها شخص غير صاحب الطلب.';
}

// Path: comptable.direction.delegationPanneau
class _Traductions$comptable$direction$delegationPanneau$ar extends Traductions$comptable$direction$delegationPanneau$fr {
	_Traductions$comptable$direction$delegationPanneau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'تحدد مرة واحدة ما يستطيع المحاسب تنفيذه وحده. وكل ما عدا ذلك يعود إليك.';
	@override String get pouvoirsTitre => 'ما يستطيع المحاسب فعله وحده';
	@override String get paiementsStandards => 'دفع المدفوعات العادية';
	@override String get paiementsStandardsDetail => 'الدفعة بالمبلغ المحسوب، نحو وسيلة متحقَّق منها، تُرسَل دون مصادقة يومية.';
	@override String get remboursement => 'تنفيذ استرداد عادي';
	@override String get remboursementDetail => 'الاسترداد المطابق للقاعدة يُنفَّذ دون مصادقة.';
	@override String get alimentationReserve => 'تغذية الاحتياطي الاستراتيجي';
	@override String get alimentationReserveDetail => 'حركة نحو الاحتياطي، مطابقة لسياسته.';
	@override String get plafondsTitre => 'الحدود القصوى';
	@override String get plafondsDetail => 'بعد تجاوز الحد الأقصى، تتطلب الدفعة مصادقتك. اتركه فارغًا لعدم تحديد أي حد.';
	@override String get plafondTransaction => 'الحد الأقصى لكل معاملة';
	@override String get plafondTransactionDetail => 'أقصى مبلغ لدفعة واحدة.';
	@override String get plafondLot => 'الحد الأقصى لكل دفعة مجمّعة';
	@override String get plafondLotDetail => 'أقصى مبلغ لمجموعة مدفوعات.';
	@override String get plafondPeriode => 'الحد الأقصى التراكمي لكل فترة';
	@override String get plafondPeriodeDetail => 'أقصى إجمالي خلال الفترة؛ يمنع الالتفاف على الحد بالتجزئة.';
	@override String get plafondIndice => 'بلا حد';
	@override String get validationsTitre => 'متى تُشترط مصادقة ثانية';
	@override String get retraitReserve => 'السحب من الاحتياطي الاستراتيجي';
	@override String get retraitReserveDetail => 'ممنوع على المحاسب دون مصادقة.';
	@override String get premierPaiement => 'أول دفعة لمستفيد';
	@override String get premierPaiementDetail => 'أول دفعة لمستفيد تتطلب مصادقة ثانية.';
	@override String get coordonnees => 'بيانات عُدّلت مؤخرًا';
	@override String get coordonneesDetail => 'الدفعة نحو بيانات عُدّلت مؤخرًا تتطلب مصادقة ثانية.';
	@override String get joursRecents => 'مدة التعديل الحديث';
	@override String get joursRecentsDetail => 'خلال هذا العدد من الأيام بعد التعديل، تُعدّ البيانات حديثة.';
	@override String get toujoursTitre => 'ممنوع دائمًا على المحاسب';
	@override String get toujoursDetail => 'هذه القواعد الثلاث لا تُعدَّل.';
	@override String get autoPayout => 'أن يدفع لنفسه';
	@override String get autoPayoutDetail => 'دفعته الخاصة تمر دائمًا عبر شخص آخر.';
	@override String get montantManuel => 'إدخال مبلغ يدويًا عند الدفع';
	@override String get montantManuelDetail => 'مبلغ الدفعة هو دائمًا مبلغ الالتزام.';
	@override String get politiqueTarifaire => 'تعديل الأسعار';
	@override String get politiqueTarifaireDetail => 'سياسة الأسعار تبقى للإدارة.';
}

// Path: comptable.paiements.ecart.motifs
class _Traductions$comptable$paiements$ecart$motifs$ar extends Traductions$comptable$paiements$ecart$motifs$fr {
	_Traductions$comptable$paiements$ecart$motifs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get montantLigne => 'مبلغ هذا السطر غير مطابق';
	@override String get ligneManquante => 'سطر ناقص (حصة، استبدال، مكافأة)';
	@override String get ligneEnTrop => 'هذا السطر لا ينبغي أن يكون هنا';
	@override String get sourceErronee => 'المصدر المذكور غير صحيح';
}

// Path: comptable.direction.reservePanneau.regle
class _Traductions$comptable$direction$reservePanneau$regle$ar extends Traductions$comptable$direction$reservePanneau$regle$fr {
	_Traductions$comptable$direction$reservePanneau$regle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get desactivee => 'معطّلة';
	@override String get desactiveeDetail => 'لا توجد تغذية تلقائية.';
	@override String get montantFixe => 'مبلغ ثابت';
	@override String get montantFixeDetail => 'المبلغ نفسه في كل موعد.';
	@override String get pourcentage => 'نسبة مئوية';
	@override String get pourcentageDetail => 'حصة من المقبوض المُثبَّت.';
	@override String get jusquAObjectif => 'حتى بلوغ الهدف';
	@override String get jusquAObjectifDetail => 'إكمال ما ينقص لبلوغ الهدف.';
	@override String get proposee => 'مقترحة';
	@override String get proposeeDetail => 'اقتراح يؤكده المحاسب.';
}

// Path: comptable.direction.reservePanneau.cadence
class _Traductions$comptable$direction$reservePanneau$cadence$ar extends Traductions$comptable$direction$reservePanneau$cadence$fr {
	_Traductions$comptable$direction$reservePanneau$cadence$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get clotureCycle => 'عند كل إقفال دورة';
	@override String get hebdomadaire => 'كل أسبوع';
	@override String get mensuelle => 'كل شهر';
	@override String get apresEncaissementConsolide => 'بعد كل مقبوض مُثبَّت';
	@override String get manuelle => 'يدوية';
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
			'commun.dates.premierJour' => '1',
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
			'commun.dates.jourDate' => ({required Object jour, required Object numero, required Object mois}) => '${jour} ${numero} ${mois}',
			'commun.reessayer' => 'إعادة المحاولة',
			'commun.annuler' => 'إلغاء',
			'commun.choix.indisponible' => 'غير متاح',
			'commun.etats.chargementProlonge.titre' => 'يستغرق الاتصال وقتًا أطول من المتوقع',
			'commun.etats.chargementProlonge.phrase' => 'يمكنك الانتظار قليلًا أو إعادة المحاولة.',
			'commun.etats.horsLigne.titre' => 'أنت غير متصل',
			'commun.etats.horsLigne.phrase' => 'تحقق من اتصالك. ما هو معروض يبقى متاحًا للاطلاع.',
			'commun.etats.reconnexion.titre' => 'جارٍ إعادة الاتصال',
			'commun.etats.reconnexion.phrase' => 'محاولة اتصال جديدة جارية.',
			'commun.etats.echecServeur.titre' => 'تعذّر تحميل هذه المعلومات',
			'commun.etats.echecServeur.phrase' => 'لم يكتمل التحميل. أعد المحاولة بعد لحظة.',
			'commun.etats.introuvable.titre' => 'هذه الصفحة غير موجودة',
			'commun.etats.introuvable.phrase' => 'ربما يكون الرابط ناقصًا، أو لم تعد الصفحة موجودة.',
			'commun.etats.accesRefuse.titre' => 'ليس لديك وصول إلى هذه الصفحة',
			'commun.etats.accesRefuse.phrase' => 'هذا المحتوى غير مفتوح لحسابك.',
			'commun.etats.sessionExpiree.titre' => 'انتهت جلستك',
			'commun.etats.sessionExpiree.phrase' => 'سجّل الدخول من جديد للمتابعة.',
			'commun.etats.dossierEnAttente.titre' => 'ملفك قيد الانتظار',
			'commun.etats.dossierEnAttente.phrase' => 'تبقى خطوة قبل فتح هذه المساحة.',
			'commun.etats.aucunResultat.titre' => 'لا توجد نتائج',
			'commun.etats.aucunResultat.phrase' => 'لا شيء مطابق حاليًا.',
			'commun.etats.permissionRefusee.titre' => 'الإذن مرفوض',
			'commun.etats.permissionRefusee.phrase' => 'دون هذا الإذن لا يمكن فتح هذه الوظيفة. يمكنك تعديله في إعدادات جهازك.',
			'commun.etats.ressourceExpiree.titre' => 'هذا المحتوى لم يعد متاحًا',
			'commun.etats.ressourceExpiree.phrase' => 'لقد سُحب، أو انتهى الوصول إليه.',
			'commun.etats.indisponible.titre' => 'غير متاح بعد',
			'commun.etats.indisponible.phrase' => 'هذه الوظيفة غير مفتوحة بعد.',
			'commun.etats.reessaisEpuises' => 'لا يزال دون رد. أعد المحاولة لاحقًا.',
			'commun.etats.horsLigneDemarrage' => 'تحتاج Rewayah إلى الإنترنت للتحقق من حسابك. أعد توصيل هذا الجهاز، ثم أعد المحاولة.',
			'commun.etats.actions.reessayer' => 'إعادة المحاولة',
			'commun.etats.actions.retourAccueil' => 'العودة إلى الرئيسية',
			'commun.etats.actions.seConnecter' => 'تسجيل الدخول',
			'commun.etats.actions.seReconnecter' => 'تسجيل الدخول من جديد',
			'commun.etats.actions.voirDossier' => 'عرض ملفي',
			'commun.etats.actions.reinitialiserFiltres' => 'إعادة ضبط عوامل التصفية',
			'commun.etats.actions.revenir' => 'الرجوع',
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
			'choix.autre' => 'آخر',
			'choix.autreInvite' => 'حدّد',
			'choix.selectionMultiple' => 'يمكن اختيار أكثر من إجابة',
			'destructif.irreversible' => 'لا يمكن التراجع عن هذا الإجراء.',
			'reseau.horsLigne' => 'لا توجد شبكة. يبقى كل شيء متاحًا للاطلاع، وسينتظر الإرسال.',
			'nav.principale' => 'التنقل الرئيسي',
			'nav.replier' => 'طيّ شريط التنقل',
			'nav.deplier' => 'فتح شريط التنقل',
			'admin.finance.aValider' => 'للمصادقة',
			'comptable.nav.aujourdhui' => 'اليوم',
			'comptable.nav.paiements' => 'المدفوعات',
			'comptable.nav.tresorerie' => 'الخزينة',
			'comptable.nav.compte' => 'الحساب',
			'comptable.onglets.aEffectuer' => 'للتنفيذ',
			'comptable.onglets.contractuels' => 'المتعاقدون',
			'comptable.onglets.beneficiaires' => 'المستفيدون',
			'comptable.onglets.coffres' => 'الصناديق',
			'comptable.onglets.encaissements' => 'المقبوضات',
			'comptable.onglets.rapprochement' => 'المطابقة',
			'comptable.commun.montantMasque' => 'مبلغ مخفي',
			'comptable.commun.afficherMontants' => 'إظهار المبالغ',
			'comptable.commun.masquerMontants' => 'إخفاء المبالغ',
			'comptable.commun.montantsMasques' => 'المبالغ مخفية',
			'comptable.commun.montantsAffiches' => 'المبالغ ظاهرة',
			'comptable.commun.enPreparationTitre' => 'هذه الشاشة قيد الإعداد.',
			'comptable.commun.enPreparationPhrase' => 'لا يُعرض هنا أي رقم في الوقت الحالي. لا يمكن تنفيذ أي دفعة من هذه الشاشة.',
			'comptable.commun.reserveStrategique' => 'الاحتياطي الاستراتيجي',
			'comptable.commun.tresorerieLibre' => 'الخزينة الحرة',
			'comptable.commun.tresorerieDetenue' => 'الخزينة المحتفَظ بها',
			'comptable.commun.fondsProteges' => 'الأموال المحمية',
			'comptable.commun.enTransit' => 'قيد التحويل',
			'comptable.commun.tresorerieLibreDetail' => 'ما يبقى متاحًا فعلًا بعد الأموال المحمية والالتزامات والمبالغ قيد التحويل.',
			'comptable.commun.objectifFixe' => 'الهدف: مبلغ ثابت',
			'comptable.commun.objectifMois' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'الهدف الحالي: شهر واحد من المصاريف الأساسية', two: 'الهدف الحالي: شهران من المصاريف الأساسية', few: 'الهدف الحالي: ${n} أشهر من المصاريف الأساسية', many: 'الهدف الحالي: ${n} شهرًا من المصاريف الأساسية', other: 'الهدف الحالي: ${n} شهر من المصاريف الأساسية', ), 
			'comptable.commun.montantActuel' => 'المبلغ الحالي',
			'comptable.commun.manque' => 'المتبقي لبلوغ الهدف',
			'comptable.commun.atteint' => ({required Object pourcent}) => 'تحقق ${pourcent} %',
			'comptable.commun.modeCalcul' => 'طريقة الحساب',
			'comptable.commun.modeMontantFixe' => 'مبلغ مستهدف ثابت',
			'comptable.commun.modeCouvertureMois' => 'تغطية بعدد أشهر المصاريف الأساسية',
			'comptable.commun.derniereAllocation' => ({required Object date}) => 'آخر تخصيص: ${date}',
			'comptable.commun.prochaineAllocation' => ({required Object date}) => 'التخصيص القادم المقرر: ${date}',
			'comptable.commun.aucuneAllocation' => 'لا يوجد أي تخصيص مسجل',
			'comptable.commun.destination' => 'الوجهة',
			'comptable.commun.destinationMasquee' => ({required Object type, required Object suffixe}) => '${type} •••• ${suffixe}',
			'comptable.commun.destinationMasqueeLecteur' => ({required Object type, required Object suffixe}) => '${type}، الرقم مخفي، ينتهي بـ ${suffixe}',
			'comptable.commun.destinationAucune' => 'لا توجد وسيلة دفع',
			'comptable.commun.paysDevise' => ({required Object pays, required Object devise}) => '${pays} · ${devise}',
			'comptable.commun.verification' => 'التحقق',
			'comptable.commun.activiteInitiateurDate' => ({required Object initiateur, required Object date}) => '${initiateur} · ${date}',
			'comptable.commun.activiteTransition' => ({required Object avant, required Object apres}) => '${avant} ← ${apres}',
			'comptable.commun.activiteReference' => ({required Object reference}) => 'المرجع ${reference}',
			'comptable.commun.relancePreparee' => 'تذكير جاهز (عرض توضيحي)',
			'comptable.commun.prestataireDemonstration' => ({required Object nom}) => '${nom} (عرض توضيحي)',
			'comptable.commun.date' => ({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}',
			'comptable.commun.aucuneValeur' => 'غير محدد',
			'comptable.coffres.fondsClientsEngages' => 'أموال العملاء الملتزَم بها',
			'comptable.coffres.paieADecaisser' => 'رواتب مستحقة الصرف',
			'comptable.coffres.chargesEssentielles' => 'المصاريف الأساسية',
			'comptable.coffres.taxesObligations' => 'الضرائب والالتزامات',
			'comptable.coffres.reserveStrategique' => 'الاحتياطي الاستراتيجي',
			'comptable.coffres.enTransit' => 'قيد التحويل',
			'comptable.coffres.tresorerieLibre' => 'الخزينة الحرة',
			'comptable.statuts.paiement.aCalculer' => 'قيد الحساب',
			'comptable.statuts.paiement.calcule' => 'محسوب',
			'comptable.statuts.paiement.aVerifier' => 'للتحقق',
			'comptable.statuts.paiement.infosManquantes' => 'معلومات الدفع ناقصة',
			'comptable.statuts.paiement.verificationRequise' => 'يلزم التحقق من الدفع',
			'comptable.statuts.paiement.pretAPayer' => 'جاهز للدفع',
			'comptable.statuts.paiement.validationRequise' => 'تلزم مصادقة إضافية',
			'comptable.statuts.paiement.soumis' => 'مُرسَل',
			'comptable.statuts.paiement.enTransit' => 'قيد التحويل',
			'comptable.statuts.paiement.reussi' => 'ناجح',
			'comptable.statuts.paiement.echoue' => 'فاشل',
			'comptable.statuts.paiement.aRelancer' => 'للتذكير',
			'comptable.statuts.paiement.annule' => 'ملغى',
			'comptable.statuts.paiement.retourne' => 'مُسترَد / مُعاد',
			'comptable.statuts.paiement.indisponible' => 'غير متاح',
			'comptable.statuts.encaissement.enAttente' => 'قيد الانتظار',
			'comptable.statuts.encaissement.confirme' => 'مؤكَّد',
			'comptable.statuts.encaissement.echoue' => 'فاشل',
			'comptable.statuts.encaissement.rembourse' => 'مُسترَد',
			'comptable.statuts.encaissement.partiellementRembourse' => 'مُسترَد جزئيًا',
			'comptable.statuts.encaissement.conteste' => 'متنازَع عليه',
			'comptable.statuts.encaissement.chargeback' => 'استرجاع بنكي',
			'comptable.statuts.encaissement.aRapprocher' => 'للمطابقة',
			'comptable.statuts.encaissement.rapproche' => 'مطابَق',
			'comptable.statuts.rapprochement.automatique' => 'تلقائي',
			'comptable.statuts.rapprochement.aVerifier' => 'للتحقق',
			'comptable.statuts.rapprochement.rapproche' => 'مطابَق',
			'comptable.statuts.rapprochement.conflit' => 'تعارض',
			'comptable.statuts.rapprochement.sansCorrespondance' => 'بلا مقابل',
			'comptable.statuts.rapprochement.doublonPotentiel' => 'تكرار محتمل',
			'comptable.statuts.profil.aucunMoyen' => 'لا توجد وسيلة',
			'comptable.statuts.profil.incomplet' => 'غير مكتمل',
			'comptable.statuts.profil.enVerification' => 'قيد التحقق',
			'comptable.statuts.profil.verifie' => 'تم التحقق',
			'comptable.statuts.profil.suspendu' => 'موقوف',
			'comptable.statuts.profil.actionRequise' => 'يلزم إجراء',
			'comptable.statuts.profil.invitationEnvoyee' => 'أُرسلت الدعوة',
			'comptable.statuts.capacite.prisEnCharge' => 'مدعوم',
			'comptable.statuts.capacite.nonPrisEnCharge' => 'غير مدعوم',
			'comptable.statuts.capacite.temporairementIndisponible' => 'غير متاح مؤقتًا',
			'comptable.statuts.capacite.verificationRequise' => 'يلزم التحقق',
			'comptable.statuts.capacite.soldePrestataireInsuffisant' => 'رصيد مزوّد الدفع غير كافٍ',
			'comptable.statuts.reserve.atteint' => 'تحقق الهدف',
			'comptable.statuts.reserve.sousObjectif' => 'دون الهدف',
			'comptable.statuts.reserve.depassement' => 'تجاوز الهدف',
			'comptable.statuts.reserve.regleInactive' => 'القاعدة غير مفعّلة',
			'comptable.statuts.reserve.alimentationPrevue' => 'تغذية مقررة',
			'comptable.statuts.reserve.mouvementSensible' => 'حركة حساسة',
			'comptable.statuts.obligation.brouillon' => 'مسودة',
			'comptable.statuts.obligation.aApprouver' => 'للاعتماد',
			'comptable.statuts.obligation.approuvee' => 'معتمَد',
			'comptable.statuts.obligation.refusee' => 'مرفوض',
			'comptable.statuts.obligation.payable' => 'قابل للدفع',
			'comptable.statuts.obligation.payee' => 'مدفوع',
			'comptable.statuts.obligation.annulee' => 'ملغى',
			'comptable.statuts.remboursement.demande' => 'مطلوب',
			'comptable.statuts.remboursement.approbationRequise' => 'يلزم الاعتماد',
			'comptable.statuts.remboursement.approuve' => 'معتمَد',
			'comptable.statuts.remboursement.execute' => 'منفَّذ',
			'comptable.statuts.remboursement.refuse' => 'مرفوض',
			'comptable.statuts.validation.enAttente' => 'طُلبت المصادقة',
			'comptable.statuts.validation.validee' => 'تمت المصادقة',
			'comptable.statuts.validation.refusee' => 'مرفوضة',
			'comptable.statuts.raison.autoPaiement' => 'يلزم أن يعالجه مسؤول آخر',
			'comptable.statuts.raison.validationRequise' => 'تلزم مصادقة إضافية',
			'comptable.statuts.raison.infosManquantes' => 'معلومات الدفع ناقصة',
			'comptable.statuts.raison.verificationRequise' => 'يلزم التحقق من الدفع',
			'comptable.statuts.raison.horsDelegation' => 'خارج التفويض',
			'comptable.statuts.raison.fournisseurIndisponible' => 'المزوّد غير متاح',
			'comptable.statuts.raison.fondsInsuffisants' => 'الأموال غير كافية',
			'comptable.statuts.raison.doublonPotentiel' => 'تكرار محتمل',
			'comptable.statuts.raison.nonApprouvee' => 'التزام غير معتمَد',
			'comptable.statuts.raison.capaciteAbsente' => 'القدرة غير متوفرة',
			'comptable.alertes.enseignantsAPayer' => 'معلمون للدفع',
			'comptable.alertes.contractuelsAEcheance' => 'متعاقدون حان موعد استحقاقهم',
			'comptable.alertes.infosManquantes' => 'معلومات الدفع ناقصة',
			'comptable.alertes.payoutEchoue' => 'فشل صرف دفعة',
			'comptable.alertes.paiementFamilleEchoue' => 'فشل دفع أسرة',
			'comptable.alertes.transactionNonRapprochee' => 'معاملة غير مطابَقة',
			'comptable.alertes.remboursementEnAttente' => 'استرداد قيد الانتظار',
			'comptable.alertes.reserveSousObjectif' => 'الاحتياطي الاستراتيجي دون الهدف',
			'comptable.alertes.soldePrestataireInsuffisant' => 'رصيد مزوّد الدفع غير كافٍ',
			'comptable.alertes.methodeModifieeRecemment' => 'وسيلة دفع عُدّلت مؤخرًا',
			'comptable.alertes.doublonPotentiel' => 'تكرار محتمل',
			'comptable.alertes.validationRequise' => 'تلزم مصادقة إضافية',
			'comptable.aujourdhui.attentionSousTitre' => 'ما ينتظر إجراءً منك، ثم المخاطر التي تجب مراقبتها.',
			'comptable.aujourdhui.elementCompteur' => ({required Object libelle, required Object n}) => '${libelle}: ${n}',
			'comptable.aujourdhui.elementDepuis' => ({required Object date}) => 'قيد الانتظار منذ ${date}',
			'comptable.aujourdhui.aTraiterVide' => 'لا شيء للمعالجة اليوم.',
			'comptable.aujourdhui.aTraiterVideDetail' => 'ستظهر هنا المدفوعات والتذكيرات والمطابقات المطلوبة.',
			'comptable.aujourdhui.alertesVide' => 'لا توجد تنبيهات حاليًا.',
			'comptable.aujourdhui.alertesResume' => ({required Object n}) => 'تنبيهات للمراقبة: ${n}',
			'comptable.aujourdhui.paiementsAEffectuer' => 'مدفوعات للتنفيذ',
			'comptable.aujourdhui.paiementsAEffectuerDetail' => 'تُراجَع كل دفعة في قائمتها قبل دفعها.',
			'comptable.aujourdhui.paiementsVide' => 'لا توجد مدفوعات للتنفيذ.',
			'comptable.aujourdhui.echeancesVide' => 'لا توجد مواعيد استحقاق قريبة.',
			'comptable.aujourdhui.encaissementsVide' => 'لا توجد مقبوضات حديثة.',
			'comptable.aujourdhui.activiteVide' => 'لا يوجد نشاط حديث.',
			'comptable.aujourdhui.prestatairesVide' => 'لا يوجد مزوّد دفع مفعّل.',
			'comptable.aujourdhui.prestatairesVideDetail' => 'ستنطلق المدفوعات الصادرة عندما تفعّل الإدارة مزوّد دفع.',
			'comptable.aujourdhui.accesPaiements' => 'عرض المدفوعات للتنفيذ',
			'comptable.aujourdhui.accesContractuels' => 'إدارة التزامات المتعاقدين',
			'comptable.aujourdhui.accesEncaissements' => 'عرض المقبوضات',
			'comptable.aujourdhui.accesTresorerie' => 'عرض الخزينة والصناديق',
			'comptable.aujourdhui.accesAlimenter' => 'تغذية الاحتياطي الاستراتيجي',
			'comptable.aujourdhui.titre' => 'اليوم',
			'comptable.aujourdhui.sousTitre' => 'ماذا عليّ أن أفعل الآن؟',
			'comptable.aujourdhui.attention' => 'للمعالجة والتنبيهات',
			'comptable.aujourdhui.aTraiter' => 'للمعالجة اليوم',
			'comptable.aujourdhui.aTraiterHorsPaiements' => 'مهام أخرى',
			'comptable.aujourdhui.alertes' => 'التنبيهات',
			'comptable.aujourdhui.echeances' => 'مواعيد استحقاق قريبة',
			'comptable.aujourdhui.prestataires' => 'مزوّدو الدفع',
			'comptable.aujourdhui.activiteRecente' => 'النشاط الحديث',
			'comptable.aujourdhui.accesRapides' => 'وصول سريع',
			'comptable.aujourdhui.encaissementsRecents' => 'المقبوضات الحديثة',
			'comptable.aujourdhui.voirTout' => 'عرض الكل',
			'comptable.paiements.confirmation.titreUn' => 'تأكيد الدفعة',
			'comptable.paiements.confirmation.titreLot' => 'تأكيد الدفعة المجمّعة',
			'comptable.paiements.confirmation.titreValidation' => 'طلب مصادقة',
			'comptable.paiements.confirmation.payerMaintenant' => 'ادفع الآن',
			'comptable.paiements.confirmation.controleEchoueTitre' => 'توقف الفحص',
			'comptable.paiements.confirmation.controleEchoue' => 'لم يكتمل فحص التحديد. لم يُرسَل أي شيء. أعد تشغيل الفحص.',
			'comptable.paiements.confirmation.relancerControle' => 'إعادة تشغيل الفحص',
			'comptable.paiements.confirmation.montant' => 'المبلغ الدقيق',
			'comptable.paiements.confirmation.beneficiaire' => 'المستفيد',
			'comptable.paiements.confirmation.devise' => 'العملة',
			'comptable.paiements.confirmation.type' => 'النوع',
			'comptable.paiements.confirmation.periode' => 'الفترة / الموضوع',
			'comptable.paiements.confirmation.prestataire' => 'مزوّد الدفع المقرر',
			'comptable.paiements.confirmation.prestataireAucun' => 'لم يُرجعه المصدر',
			'comptable.paiements.confirmation.taux' => 'سعر الصرف',
			'comptable.paiements.confirmation.tauxDate' => ({required Object taux, required Object date}) => '${taux}، بتاريخ ${date}',
			'comptable.paiements.confirmation.frais' => 'رسوم مزوّد الدفع',
			'comptable.paiements.confirmation.change' => 'تكلفة الصرف',
			'comptable.paiements.confirmation.montantEnvoye' => 'إجمالي المُرسَل',
			'comptable.paiements.confirmation.montantRecu' => 'المبلغ المتوقع استلامه',
			'comptable.paiements.confirmation.controlesTitre' => 'الفحوص المجتازة',
			'comptable.paiements.confirmation.controlesPhrase' => 'المبلغ محسوب، ووسيلة الدفع متحقَّق منها، والتفويض والتكرارات مفحوصة من المصدر. لن تُرسَل إلا المدفوعات الجاهزة.',
			'comptable.paiements.confirmation.sensiblePhrase' => 'هذه الدفعة حساسة: يجب أن يصادق عليها شخص مخوَّل آخر. اطلب المصادقة، فهي لا تُرسَل قبلها.',
			'comptable.paiements.confirmation.prets' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'دفعة جاهزة واحدة', two: 'دفعتان جاهزتان', few: '${n} دفعات جاهزة', other: '${n} دفعة جاهزة', ), 
			'comptable.paiements.confirmation.exclus' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'دفعة مستبعدة واحدة', two: 'دفعتان مستبعدتان', few: '${n} دفعات مستبعدة', other: '${n} دفعة مستبعدة', ), 
			'comptable.paiements.confirmation.total' => 'إجمالي المدفوعات الجاهزة',
			'comptable.paiements.confirmation.beneficiairesCle' => 'المستفيدون',
			'comptable.paiements.confirmation.beneficiaires' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'مستفيد واحد', two: 'مستفيدان', few: '${n} مستفيدين', other: '${n} مستفيدًا', ), 
			'comptable.paiements.confirmation.devises' => 'العملات',
			'comptable.paiements.confirmation.prestataires' => 'مزوّدو الدفع',
			'comptable.paiements.confirmation.plafond' => 'التفويض المتبقي',
			'comptable.paiements.confirmation.exclusTitre' => 'مستبعدة من هذه الدفعة المجمّعة: لن تُرسَل',
			'comptable.paiements.confirmation.aucunPretTitre' => 'لا توجد دفعة جاهزة',
			'comptable.paiements.confirmation.aucunPret' => 'لن يُرسَل أي شيء. افتح كل دفعة مستبعدة لإزالة سببها، ثم أعد تشغيل الفحص.',
			'comptable.paiements.confirmation.erreursTitre' => 'أخطاء أرجعها الفحص',
			'comptable.paiements.confirmation.confirmerUn' => ({required Object montant}) => 'تأكيد دفع ${montant}',
			'comptable.paiements.confirmation.confirmerLot' => ({required num n, required Object montants}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'تأكيد الدفعة الجاهزة بمبلغ ${montants}', two: 'تأكيد الدفعتين الجاهزتين: ${montants}', few: 'تأكيد ${n} دفعات جاهزة: ${montants}', other: 'تأكيد ${n} دفعة جاهزة: ${montants}', ), 
			'comptable.paiements.confirmation.demanderValidation' => 'طلب المصادقة',
			'comptable.paiements.confirmation.annuler' => 'إلغاء',
			'comptable.paiements.confirmation.fermer' => 'إغلاق',
			'comptable.paiements.confirmation.soumisTitre' => 'أُرسلت إلى مزوّد الدفع',
			'comptable.paiements.confirmation.soumisPhrase' => 'الدفعة المُرسَلة لم تُستلَم بعد: حالتها تأتي من متابعة مزوّد الدفع. حدّث المتابعة لترى تقدمها.',
			'comptable.paiements.confirmation.actualiser' => 'تحديث المتابعة',
			'comptable.paiements.confirmation.suiviEchoue' => 'تعذرت قراءة المتابعة. تبقى الدفعة مُرسَلة: حدّث مرة أخرى بعد قليل.',
			'comptable.paiements.confirmation.referenceCle' => 'مرجع مزوّد الدفع',
			'comptable.paiements.confirmation.recalculeTitre' => 'أُعيد حساب المبلغ',
			'comptable.paiements.confirmation.recalculePhrase' => 'تغيّر حساب في المصدر منذ الفحص. لم يُرسَل أي شيء. أعد تشغيل الفحص لتأكيد المبلغ الجديد.',
			'comptable.paiements.confirmation.nouveauMontant' => ({required Object nom}) => 'المبلغ الجديد لـ ${nom}',
			'comptable.paiements.confirmation.refusTitre' => 'رفض المصدر الدفعة',
			'comptable.paiements.confirmation.refusDejaSoumis' => 'سبق إرسال هذه الدفعة: لن يُعاد إرسال أي شيء. تابعها من تبويب المدفوعات الجارية.',
			'comptable.paiements.confirmation.refusHorsDelegation' => 'يتجاوز المجموع تفويضك، لكل مستفيد أو لكل فترة. لم يُرسَل أي شيء. أعد تشغيل الفحص: ستُستبعد المدفوعات المعنية.',
			'comptable.paiements.confirmation.refusPerime' => 'انتهت صلاحية الفحص. لم يُرسَل أي شيء. أعد تشغيل الفحص قبل التأكيد.',
			'comptable.paiements.confirmation.refusFournisseur' => 'أصبح مزوّد الدفع غير متاح. لم يُرسَل أي شيء. أعد تشغيل الفحص بعد قليل.',
			'comptable.paiements.confirmation.inconnuTitre' => 'نتيجة غير معروفة',
			'comptable.paiements.confirmation.inconnuPhrase' => 'لم يصلنا الرد: ربما أُرسلت الدفعة. أعد المحاولة: يُعاد إرسال الطلب نفسه ولن يُنفَّذ إلا مرة واحدة.',
			'comptable.paiements.confirmation.reessayer' => 'إعادة المحاولة',
			'comptable.paiements.confirmation.validationDemandeeTitre' => 'طُلبت المصادقة',
			'comptable.paiements.confirmation.validationDemandeePhrase' => 'سيصادق شخص مخوَّل آخر على هذه الدفعة. لن تُرسَل قبل قراره.',
			'comptable.paiements.confirmation.validationEchouee' => 'لم يكتمل طلب المصادقة. أعد المحاولة: لن يُسجَّل إلا مرة واحدة.',
			'comptable.paiements.filtres.tous' => 'الكل',
			'comptable.paiements.filtres.enseignants' => 'المعلمون',
			'comptable.paiements.filtres.contractuels' => 'المتعاقدون',
			'comptable.paiements.filtres.statut' => 'الحالة',
			'comptable.paiements.filtres.tousStatuts' => 'كل الحالات',
			'comptable.paiements.filtres.prets' => 'جاهزة',
			'comptable.paiements.filtres.infos' => 'معلومات ناقصة',
			'comptable.paiements.filtres.verification' => 'التحقق',
			'comptable.paiements.filtres.validation' => 'المصادقة',
			'comptable.paiements.filtres.retard' => 'متأخرة',
			'comptable.paiements.filtres.classe' => 'الفصل',
			'comptable.paiements.filtres.toutesClasses' => 'كل الفصول',
			'comptable.paiements.filtres.periode' => 'الفترة',
			'comptable.paiements.filtres.toutesPeriodes' => 'كل الفترات',
			'comptable.paiements.filtres.effacer' => 'مسح عوامل التصفية',
			'comptable.paiements.colonnes.beneficiaire' => 'المستفيد',
			'comptable.paiements.colonnes.type' => 'النوع',
			'comptable.paiements.colonnes.periode' => 'الفترة / الموضوع',
			'comptable.paiements.colonnes.montant' => 'المبلغ',
			'comptable.paiements.colonnes.destination' => 'الوجهة',
			'comptable.paiements.colonnes.echeance' => 'الاستحقاق',
			'comptable.paiements.colonnes.statut' => 'الحالة',
			'comptable.paiements.colonnes.action' => 'الإجراء',
			'comptable.paiements.types.enseignant' => 'معلم',
			'comptable.paiements.types.contractuel' => 'متعاقد',
			'comptable.paiements.compteur' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'دفعة واحدة', two: 'دفعتان', few: '${n} دفعات', other: '${n} دفعة', ), 
			'comptable.paiements.actions.voir' => 'عرض',
			'comptable.paiements.actions.payer' => 'دفع',
			'comptable.paiements.actions.demanderValidation' => 'طلب المصادقة',
			'comptable.paiements.actions.relancer' => 'تذكير',
			'comptable.paiements.actions.signalerEcart' => 'الإبلاغ عن فرق',
			'comptable.paiements.actions.selectionner' => ({required Object nom}) => 'تحديد دفعة ${nom}',
			'comptable.paiements.actions.selectionnerPrets' => 'تحديد كل المدفوعات الجاهزة',
			'comptable.paiements.actions.payerSelection' => 'دفع المحدد',
			'comptable.paiements.actions.viderSelection' => 'إلغاء التحديد',
			'comptable.paiements.actions.voirProfil' => 'عرض ملف الدفع',
			'comptable.paiements.selection' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'دفعة واحدة محددة', two: 'دفعتان محددتان', few: '${n} دفعات محددة', other: '${n} دفعة محددة', ), 
			'comptable.paiements.selectionPhrase' => 'يُرجع الفحص الإجمالي والاستبعادات قبل أي إرسال.',
			'comptable.paiements.horsLigneCourt' => 'غير متصل: الدفع غير ممكن',
			'comptable.paiements.vide.message' => 'لا توجد مدفوعات للتنفيذ.',
			'comptable.paiements.vide.invitation' => 'تظهر الالتزامات هنا بمجرد حسابها في المصدر.',
			'comptable.paiements.vide.filtreMessage' => 'لا توجد دفعة تطابق عوامل التصفية هذه.',
			'comptable.paiements.vide.filtreInvitation' => 'امسح عوامل التصفية لرؤية كل المدفوعات مجددًا.',
			'comptable.paiements.horsLigne' => 'غير متصل: لا تُرسَل أي دفعة دون شبكة. أعد الاتصال لتدفع.',
			'comptable.paiements.detail.total' => 'الإجمالي المستحق',
			'comptable.paiements.detail.lignes' => 'تفاصيل الحساب',
			'comptable.paiements.detail.ligneTotal' => 'الإجمالي',
			'comptable.paiements.detail.source' => ({required Object source}) => 'المصدر: ${source}',
			'comptable.paiements.detail.auteur' => ({required Object auteur}) => 'أضافه ${auteur}',
			'comptable.paiements.detail.voirSource' => 'عرض المصدر',
			'comptable.paiements.detail.methode' => 'وسيلة الدفع',
			'comptable.paiements.detail.informations' => 'المعلومات',
			'comptable.paiements.detail.type' => 'النوع',
			'comptable.paiements.detail.periode' => 'الفترة / الموضوع',
			'comptable.paiements.detail.echeance' => 'الاستحقاق',
			'comptable.paiements.detail.prestataire' => 'مزوّد الدفع المقرر',
			'comptable.paiements.detail.preuve' => 'الإثبات',
			'comptable.paiements.detail.classes' => 'الفصول',
			'comptable.paiements.detail.version' => 'إصدار الحساب',
			'comptable.paiements.detail.historique' => 'السجل',
			'comptable.paiements.detail.historiqueVide' => 'لا توجد عملية مسجلة لهذه الدفعة.',
			'comptable.paiements.detail.encart' => 'لا يستطيع المحاسب تعديل المبلغ ولا بيانات الدفع الخاصة بالمستفيد.',
			'comptable.paiements.detail.alerteMethodeRecente' => ({required Object date}) => 'عُدّلت وسيلة الدفع في ${date}: تلزم مصادقة إضافية قبل أي دفع.',
			'comptable.paiements.detail.alerteLieeOperateur' => 'المستفيد مرتبط بالمنفِّذ: تلزم مصادقة إضافية قبل أي دفع.',
			'comptable.paiements.detail.alerteEchec' => 'فشل آخر إرسال لدى مزوّد الدفع. تحقق من وسيلة الدفع قبل محاولة جديدة.',
			'comptable.paiements.detail.alerteInfos' => 'ليست لدى المستفيد بعد وسيلة دفع مكتملة. ذكّره من ملف الدفع الخاص به.',
			'comptable.paiements.detail.alerteTitre' => 'ما يجب معرفته قبل الدفع',
			'comptable.paiements.detail.autoPaiementPhrase' => 'هذه الدفعة تخصك: سيعالجها شخص مخوَّل آخر. لا يمكن لأحد تنفيذ دفعته بنفسه.',
			'comptable.paiements.detail.introuvableTitre' => 'هذه الدفعة غير موجودة.',
			'comptable.paiements.detail.introuvablePhrase' => 'عد إلى قائمة المدفوعات للتنفيذ لاختيار دفعة أخرى.',
			'comptable.paiements.ecart.titre' => 'الإبلاغ عن فرق',
			'comptable.paiements.ecart.phrase' => 'اختر السطر وما الخطأ فيه. يتم التصحيح في المصدر، ثم يُعاد حساب المبلغ.',
			'comptable.paiements.ecart.ligne' => 'السطر المعني',
			'comptable.paiements.ecart.motif' => 'ما الخطأ',
			'comptable.paiements.ecart.motifs.montantLigne' => 'مبلغ هذا السطر غير مطابق',
			'comptable.paiements.ecart.motifs.ligneManquante' => 'سطر ناقص (حصة، استبدال، مكافأة)',
			'comptable.paiements.ecart.motifs.ligneEnTrop' => 'هذا السطر لا ينبغي أن يكون هنا',
			'comptable.paiements.ecart.motifs.sourceErronee' => 'المصدر المذكور غير صحيح',
			'comptable.paiements.ecart.envoyer' => 'إرسال البلاغ',
			'comptable.paiements.ecart.annuler' => 'إلغاء',
			'comptable.paiements.ecart.envoye' => ({required Object date}) => 'أُبلغ عن الفرق في ${date}. يبقى المبلغ كما في المصدر حتى إعادة الحساب.',
			'comptable.paiements.ecart.erreurEnvoi' => 'لم يكتمل البلاغ. أعد المحاولة: لن يُسجَّل إلا مرة واحدة.',
			'comptable.paiements.titre' => 'مدفوعات للتنفيذ',
			'comptable.paiements.sousTitre' => 'مبالغ محسوبة في المصدر: هنا نراجع وندفع، ولا نعدّل شيئًا.',
			'comptable.paiements.detailTitre' => 'تفاصيل الدفعة',
			'comptable.paiements.detailSousTitre' => 'لكل سطر مصدره. يُبلَّغ عن الفرق ولا يُصحَّح هنا.',
			'comptable.tresorerie.coffresTitre' => 'الصناديق',
			'comptable.tresorerie.coffresPhrase' => 'حيث يُخصَّص المال. المبلغ المحمي لا يُحسب أبدًا ضمن الحر.',
			'comptable.tresorerie.coffreProtege' => 'محمي',
			'comptable.tresorerie.coffreNonProtege' => 'غير محمي',
			'comptable.tresorerie.partDetenue' => ({required Object part}) => '${part} % من الخزينة المحتفَظ بها',
			'comptable.tresorerie.regleUsage' => ({required Object regle}) => 'قاعدة الاستخدام: ${regle}',
			'comptable.tresorerie.coffresVide' => 'لم يُرجَع أي صندوق بعد.',
			'comptable.tresorerie.coffresVidePhrase' => 'ستظهر الصناديق السبعة هنا بمجرد أن يُرجعها المصدر.',
			'comptable.tresorerie.descriptions.fondsClientsEngages' => 'أموال مقبوضة مرتبطة بخدمات لم تُستحق بعد.',
			'comptable.tresorerie.descriptions.paieADecaisser' => 'أجور محسوبة ومستحقة.',
			'comptable.tresorerie.descriptions.chargesEssentielles' => 'البنية التحتية والاشتراكات الضرورية والوظائف الثابتة.',
			'comptable.tresorerie.descriptions.taxesObligations' => 'مخصص للالتزامات الضريبية أو الاجتماعية أو التنظيمية.',
			'comptable.tresorerie.descriptions.reserveStrategique' => 'صندوق الاستمرارية والأمان.',
			'comptable.tresorerie.descriptions.enTransit' => 'أموال ملتزَم بها في عملية لم تُؤكَّد بعد.',
			'comptable.tresorerie.descriptions.tresorerieLibre' => 'ما يبقى متاحًا فعلًا بعد التخصيصات المحمية.',
			'comptable.tresorerie.politiqueTitre' => 'سياسة الاحتياطي الاستراتيجي',
			'comptable.tresorerie.politiquePhrase' => 'تحددها الإدارة. أنت تطبّقها ولا تعدّلها.',
			'comptable.tresorerie.alimentationAuto' => 'التغذية التلقائية',
			'comptable.tresorerie.regle.desactivee' => 'معطّلة',
			'comptable.tresorerie.regle.montantFixe' => 'مبلغ ثابت في كل موعد',
			'comptable.tresorerie.regle.pourcentage' => ({required Object pourcent}) => '${pourcent} % من كل مقبوض مُثبَّت',
			'comptable.tresorerie.regle.jusquAObjectif' => 'الإكمال حتى المبلغ المستهدف',
			'comptable.tresorerie.regle.proposee' => 'اقتراح يتطلب تأكيدك',
			'comptable.tresorerie.cadence' => 'الوتيرة',
			'comptable.tresorerie.cadences.clotureCycle' => 'عند كل إقفال دورة',
			'comptable.tresorerie.cadences.hebdomadaire' => 'كل أسبوع',
			'comptable.tresorerie.cadences.mensuelle' => 'كل شهر',
			'comptable.tresorerie.cadences.apresEncaissementConsolide' => 'بعد كل مقبوض مُثبَّت',
			'comptable.tresorerie.cadences.manuelle' => 'يدوية',
			'comptable.tresorerie.seuilAlerte' => ({required Object pourcent}) => 'تنبيه دون ${pourcent} % من المبلغ المستهدف',
			'comptable.tresorerie.retraitValidation' => 'كل سحب يتطلب مصادقة إضافية.',
			'comptable.tresorerie.retraitSansValidation' => 'لا تشترط السياسة مصادقة للسحب؛ ويبقى معامَلًا كحركة حساسة.',
			_ => null,
		} ?? switch (path) {
			'comptable.tresorerie.version' => ({required Object version}) => 'الإصدار ${version}',
			'comptable.tresorerie.versionDepuis' => ({required Object version, required Object date}) => 'الإصدار ${version}، ساري المفعول منذ ${date}',
			'comptable.tresorerie.mouvementsTitre' => 'الحركات بين الصناديق',
			'comptable.tresorerie.mouvementsPhrase' => 'نحو الحماية: حسب تفويضك. الخروج من صندوق محمي: تلزم مصادقة إضافية.',
			'comptable.tresorerie.preparerMouvement' => 'إعداد حركة',
			'comptable.tresorerie.retirer' => 'السحب من الاحتياطي الاستراتيجي',
			'comptable.tresorerie.retraitBloque' => ({required Object raison}) => 'السحب من الاحتياطي الاستراتيجي: ${raison}.',
			'comptable.tresorerie.alimenterBloque' => ({required Object raison}) => 'تغذية الاحتياطي الاستراتيجي: ${raison}.',
			'comptable.tresorerie.aucunMouvement' => 'لا تسمح السياسة لحسابك بأي حركة بين الصناديق.',
			'comptable.tresorerie.mouvementsHorsLigne' => 'غير متصل: تُستأنف الحركات بين الصناديق مع عودة الشبكة.',
			'comptable.tresorerie.interdits' => 'أموال العملاء الملتزَم بها والضرائب والالتزامات لا تموّل أبدًا مصروفًا عاديًا؛ والتخصيص السابق لا يُعدَّل.',
			'comptable.tresorerie.previsionTitre' => 'التوقعات',
			'comptable.tresorerie.previsionPhrase' => 'الداخل والخارج المتوقع، حسب التاريخ.',
			'comptable.tresorerie.previsionVide' => 'لا يوجد داخل ولا خارج متوقع حاليًا.',
			'comptable.tresorerie.entree' => 'داخل',
			'comptable.tresorerie.sortie' => 'خارج',
			'comptable.tresorerie.historiqueTitre' => 'سجل التخصيصات',
			'comptable.tresorerie.historiquePhrase' => 'كل حركة مسجلة في السجل؛ ولا يُعدَّل فيه شيء.',
			'comptable.tresorerie.historiqueVide' => 'لا توجد حركة مسجلة بين الصناديق.',
			'comptable.tresorerie.transfert.titre' => 'حركة بين الصناديق',
			'comptable.tresorerie.transfert.choix' => 'حركة تسمح بها السياسة',
			'comptable.tresorerie.transfert.couple' => ({required Object origine, required Object destination}) => '${origine} ← ${destination}',
			'comptable.tresorerie.transfert.delegable' => 'نحو الحماية: تُنفَّذ حسب تفويضك.',
			'comptable.tresorerie.transfert.sensible' => 'تلزم مصادقة إضافية: يقرر شخص آخر، ولا يخرج شيء من الصندوق قبل ذلك.',
			'comptable.tresorerie.transfert.montant' => 'المبلغ',
			'comptable.tresorerie.transfert.montantAide' => ({required Object devise}) => 'بوحدات صحيحة، ${devise}.',
			'comptable.tresorerie.transfert.montantPropose' => 'المبلغ الذي تقترحه السياسة',
			'comptable.tresorerie.transfert.utiliserPropose' => 'استخدام المبلغ المقترح',
			'comptable.tresorerie.transfert.erreurMontant' => 'أدخل مبلغًا صحيحًا أكبر من صفر.',
			'comptable.tresorerie.transfert.verifier' => 'مراجعة الحركة',
			'comptable.tresorerie.transfert.recapPhrase' => 'راجع المبلغ الدقيق قبل الإرسال.',
			'comptable.tresorerie.transfert.de' => 'من',
			'comptable.tresorerie.transfert.vers' => 'إلى',
			'comptable.tresorerie.transfert.confirmer' => 'تأكيد الحركة',
			'comptable.tresorerie.transfert.demanderValidation' => 'طلب المصادقة',
			'comptable.tresorerie.transfert.modifier' => 'تعديل الحركة',
			'comptable.tresorerie.transfert.fermer' => 'إغلاق',
			'comptable.tresorerie.transfert.executeTitre' => 'نفّذ المصدر الحركة',
			'comptable.tresorerie.transfert.executePhrase' => 'سجّلها السجل. يُعاد قراءة الأرصدة المعروضة.',
			'comptable.tresorerie.transfert.reference' => ({required Object reference}) => 'المرجع: ${reference}',
			'comptable.tresorerie.transfert.validationTitre' => 'طُلبت المصادقة',
			'comptable.tresorerie.transfert.validationPhrase' => 'يجب أن يقرر شخص آخر. يبقى الصندوق المصدر دون تغيير حتى ذلك الحين.',
			'comptable.tresorerie.transfert.refusTitre' => 'رفض المصدر الحركة',
			'comptable.tresorerie.transfert.refusPhrase' => ({required Object raison}) => 'السبب: ${raison}. لم يُنقَل أي شيء.',
			'comptable.tresorerie.transfert.erreurEnvoiTitre' => 'لم يصل الرد',
			'comptable.tresorerie.transfert.erreurEnvoi' => 'لم يصل الرد. راجع السجل قبل إعادة المحاولة: لن تُحسب الحركة نفسها مرتين أبدًا.',
			'comptable.tresorerie.transfert.indisponible' => 'الحركات بين الصناديق غير مربوطة بالخادم بعد. لم يُنقَل أي شيء.',
			'comptable.tresorerie.transfert.aucunCouple' => 'لا تسمح السياسة بأي حركة لحسابك.',
			'comptable.tresorerie.titre' => 'الخزينة والصناديق',
			'comptable.tresorerie.sousTitre' => 'الخزينة الحرة هي الرقم الوحيد القابل للإنفاق.',
			'comptable.tresorerie.alimenter' => 'تغذية الاحتياطي الاستراتيجي',
			'comptable.encaissements.filtreTous' => 'الكل',
			'comptable.encaissements.filtreConfirmes' => 'مؤكَّدة',
			'comptable.encaissements.filtreEnAttente' => 'قيد الانتظار',
			'comptable.encaissements.filtreEchoues' => 'فاشلة',
			'comptable.encaissements.filtreRembourses' => 'مُسترَدة',
			'comptable.encaissements.filtreContestes' => 'متنازَع عليها',
			'comptable.encaissements.filtreARapprocher' => 'للمطابقة',
			'comptable.encaissements.recherche' => 'البحث عن أسرة أو مرجع',
			'comptable.encaissements.colDate' => 'التاريخ',
			'comptable.encaissements.colFamille' => 'الأسرة',
			'comptable.encaissements.colReference' => 'المرجع',
			'comptable.encaissements.colBrut' => 'الإجمالي',
			'comptable.encaissements.colFrais' => 'الرسوم',
			'comptable.encaissements.colNet' => 'الصافي',
			'comptable.encaissements.colMoyen' => 'الوسيلة',
			'comptable.encaissements.colEtat' => 'الحالة',
			'comptable.encaissements.profilsPour' => ({required Object prenoms}) => 'لـ ${prenoms}',
			'comptable.encaissements.moyenPrestataire' => ({required Object moyen, required Object prestataire}) => '${moyen} · ${prestataire}',
			'comptable.encaissements.videTitre' => 'لا توجد مقبوضات حاليًا.',
			'comptable.encaissements.videPhrase' => 'ستظهر هنا مدفوعات الأسر بمجرد أن يرسلها مزوّد الدفع.',
			'comptable.encaissements.videFiltreTitre' => 'لا يوجد مقبوض مطابق.',
			'comptable.encaissements.videFiltrePhrase' => 'اختر «الكل» أو امسح البحث لرؤية القائمة كاملة.',
			'comptable.encaissements.voirTous' => 'عرض كل المقبوضات',
			'comptable.encaissements.ouvrirDetailLecteur' => ({required Object famille}) => 'فتح تفاصيل مقبوض ${famille}',
			'comptable.encaissements.fermerDetail' => 'إغلاق التفاصيل',
			'comptable.encaissements.brut' => 'المبلغ الإجمالي',
			'comptable.encaissements.frais' => 'رسوم مزوّد الدفع',
			'comptable.encaissements.net' => 'الصافي المستلَم',
			'comptable.encaissements.fraisSource' => 'الرسوم والصرف كما أبلغ بها مزوّد الدفع، ولا يُعاد حسابها هنا أبدًا.',
			'comptable.encaissements.reference' => 'المرجع',
			'comptable.encaissements.prestataire' => 'مزوّد الدفع',
			'comptable.encaissements.moyen' => 'وسيلة الدفع',
			'comptable.encaissements.foyer' => 'الأسرة',
			'comptable.encaissements.date' => 'التاريخ',
			'comptable.encaissements.etat' => 'الحالة',
			'comptable.encaissements.devise' => 'العملة',
			'comptable.encaissements.affectation' => 'التوزيع حسب الملف',
			'comptable.encaissements.affectationAucune' => 'لم يُرجع المصدر أي توزيع لهذا المقبوض.',
			'comptable.encaissements.rapprochement' => 'المطابقة',
			'comptable.encaissements.rapprochementAucun' => 'لم تتم المطابقة بعد',
			'comptable.encaissements.ouvrirRapprochement' => 'فتح المطابقة',
			'comptable.encaissements.confirmeNote' => 'لا تظهر «مؤكَّد» إلا بعد تأكيد مزوّد الدفع.',
			'comptable.encaissements.enAttenteNote' => 'بانتظار تأكيد مزوّد الدفع: لم يُكتسب شيء بعد.',
			'comptable.encaissements.journal' => 'سجل المقبوض',
			'comptable.encaissements.journalVide' => 'لا توجد عملية مسجلة لهذا المقبوض.',
			'comptable.encaissements.rap.vueTransactions' => 'للمطابقة',
			'comptable.encaissements.rap.vueRemboursements' => 'الاستردادات',
			'comptable.encaissements.rap.natPaiementAttendu' => 'دفعة متوقعة',
			'comptable.encaissements.rap.natTransaction' => 'معاملة مزوّد الدفع',
			'comptable.encaissements.rap.natMensualite' => 'رصيد أو قسط شهري',
			'comptable.encaissements.rap.natFrais' => 'رسوم',
			'comptable.encaissements.rap.natRemboursement' => 'استرداد',
			'comptable.encaissements.rap.natPayout' => 'صرف دفعة',
			'comptable.encaissements.rap.natPreuve' => 'إثبات',
			'comptable.encaissements.rap.natureDate' => ({required Object nature, required Object date}) => '${nature} · ${date}',
			'comptable.encaissements.rap.choisirTitre' => 'اختر معاملة.',
			'comptable.encaissements.rap.choisirPhrase' => 'تُفتح هنا المطابقات المقترحة لها وحالتها وسجلها.',
			'comptable.encaissements.rap.videTitre' => 'لا شيء للمطابقة.',
			'comptable.encaissements.rap.videPhrase' => 'كل معاملة مستلَمة مرتبطة بالفعل بما كان ينتظرها.',
			'comptable.encaissements.rap.videFiltreTitre' => 'لا توجد معاملة بهذه الحالة.',
			'comptable.encaissements.rap.videFiltrePhrase' => 'اختر «الكل» لرؤية كل المعاملات.',
			'comptable.encaissements.rap.voirToutes' => 'عرض كل المعاملات',
			'comptable.encaissements.rap.ouvrirLecteur' => ({required Object libelle}) => 'فتح مطابقة ${libelle}',
			'comptable.encaissements.rap.candidats' => 'المطابقات المقترحة',
			'comptable.encaissements.rap.candidatsAucun' => 'لا يقترح المصدر أي مطابقة لهذه المعاملة.',
			'comptable.encaissements.rap.relieA' => ({required Object libelle}) => 'مرتبطة بـ: ${libelle}',
			'comptable.encaissements.rap.rapprocher' => 'مطابقة',
			'comptable.encaissements.rap.rapprocherLecteur' => ({required Object libelle}) => 'المطابقة مع ${libelle}',
			'comptable.encaissements.rap.doublonTitre' => 'تكرار محتمل',
			'comptable.encaissements.rap.doublonPhrase' => 'تشبه هذه المعاملة معاملة أخرى مستلَمة سابقًا. تحقق قبل المطابقة: لا يُقبل التكرار أبدًا بصمت.',
			'comptable.encaissements.rap.marquerDoublon' => 'وضع علامة تكرار',
			'comptable.encaissements.rap.resultat' => ({required Object etat}) => 'الحالة التي أرجعها المصدر: ${etat}',
			'comptable.encaissements.rap.erreurEnvoi' => 'لا نعلم إن كانت العملية قد سُجّلت. حدّث القائمة قبل إعادة المحاولة.',
			'comptable.encaissements.rap.actualiser' => 'تحديث',
			'comptable.encaissements.rap.journal' => 'سجل المعاملة',
			'comptable.encaissements.rap.journalVide' => 'لا توجد عملية مسجلة لهذه المعاملة.',
			'comptable.encaissements.rap.beneficiaire' => 'المستفيد',
			'comptable.encaissements.rap.motif' => 'السبب',
			'comptable.encaissements.rap.montant' => 'المبلغ',
			'comptable.encaissements.rap.source' => 'المصدر',
			'comptable.encaissements.rap.demandeLe' => ({required Object date}) => 'طُلب في ${date}',
			'comptable.encaissements.rap.approbationRequise' => 'تشترط السياسة الاعتماد',
			'comptable.encaissements.rap.approbationNon' => 'دون اعتماد حسب السياسة',
			'comptable.encaissements.rap.politiqueNote' => 'قواعد الاسترداد جزء من سياسة المالية. هنا نطبّقها ولا نعيد كتابتها.',
			'comptable.encaissements.rap.executer' => 'تنفيذ الاسترداد',
			'comptable.encaissements.rap.executerLecteur' => ({required Object beneficiaire}) => 'تنفيذ استرداد ${beneficiaire}',
			'comptable.encaissements.rap.executerTitre' => 'تنفيذ هذا الاسترداد؟',
			'comptable.encaissements.rap.executerPhrase' => 'المبلغ والشروط مصدرها سياسة المالية. سيؤكد مزوّد الدفع التنفيذ.',
			'comptable.encaissements.rap.remboursementsVideTitre' => 'لا يوجد استرداد ولا رصيد دائن جارٍ.',
			'comptable.encaissements.rap.journalRemboursement' => 'سجل الاسترداد',
			'comptable.encaissements.rap.journalRemboursementVide' => 'لا توجد عملية مسجلة لهذا الاسترداد.',
			'comptable.encaissements.rap.erreurEnvoiTitre' => 'عملية غير مؤكدة',
			'comptable.encaissements.rap.remboursementsVidePhrase' => 'ستظهر هنا طلبات الاسترداد مع سببها وحالتها.',
			'comptable.encaissements.titre' => 'المقبوضات',
			'comptable.encaissements.sousTitre' => 'لا تُؤكَّد الدفعة إلا بعد مزوّد الدفع.',
			'comptable.encaissements.detailTitre' => 'تفاصيل المقبوض',
			'comptable.encaissements.rapprochementTitre' => 'المطابقة',
			'comptable.encaissements.rapprochementSousTitre' => 'ربط كل معاملة بما كان ينتظرها.',
			'comptable.beneficiaires.intro' => 'ملف الدفع لكل معلم ولكل متعاقد. المستفيد وحده يُدخل بياناته أو يعدّلها: يمكنك تذكيره، أو طلب تحديث منه، أو إيقاف مدفوعاته.',
			'comptable.beneficiaires.filtreTous' => 'الكل',
			'comptable.beneficiaires.filtreInfos' => 'معلومات ناقصة',
			'comptable.beneficiaires.filtreVerification' => 'قيد التحقق',
			'comptable.beneficiaires.filtreSuspendus' => 'موقوفة',
			'comptable.beneficiaires.filtreInvitations' => 'دعوات مُرسَلة',
			'comptable.beneficiaires.colonneBeneficiaire' => 'المستفيد',
			'comptable.beneficiaires.colonneType' => 'النوع',
			'comptable.beneficiaires.colonneDestination' => 'الوجهة',
			'comptable.beneficiaires.colonneEtat' => 'حالة الملف',
			'comptable.beneficiaires.colonneEnAttente' => 'مدفوعات قيد الانتظار',
			'comptable.beneficiaires.typeEnseignant' => 'معلم',
			'comptable.beneficiaires.typeContractuel' => 'متعاقد',
			'comptable.beneficiaires.enAttente' => ({required Object n}) => '${n} قيد الانتظار',
			'comptable.beneficiaires.aucunEnAttente' => 'لا شيء',
			'comptable.beneficiaires.vide' => 'لا يوجد مستفيد حاليًا.',
			'comptable.beneficiaires.videDetail' => 'يظهر المعلمون والمتعاقدون هنا بمجرد وجود دفعة تخصهم.',
			'comptable.beneficiaires.videFiltre' => 'لا يوجد مستفيد بعامل التصفية هذا.',
			'comptable.beneficiaires.videFiltreDetail' => 'اختر «الكل» لرؤية القائمة كاملة.',
			'comptable.beneficiaires.profil.carteTitre' => ({required Object nom}) => 'ملف الدفع الخاص بـ ${nom}',
			'comptable.beneficiaires.profil.etat' => 'حالة الملف',
			'comptable.beneficiaires.profil.derniereModification' => 'آخر تعديل',
			'comptable.beneficiaires.profil.capacite' => 'قدرة الدفع في هذا المسار',
			'comptable.beneficiaires.profil.capaciteNonEvaluee' => 'لم تُقيَّم بعد',
			'comptable.beneficiaires.profil.enAttente' => 'مدفوعات تنتظر هذا الملف',
			'comptable.beneficiaires.profil.proprietaire' => ({required Object nom}) => 'وحده ${nom} يمكنه إدخال بيانات الدفع الخاصة به أو تعديلها. أنت ترى نسخة مخفية منها.',
			'comptable.beneficiaires.profil.historiqueTitre' => 'سجل المدفوعات',
			'comptable.beneficiaires.profil.historiqueVide' => 'لم تُصرف أي دفعة لهذا المستفيد حتى الآن.',
			'comptable.beneficiaires.profil.journalTitre' => 'سجل الملف',
			'comptable.beneficiaires.profil.journalVide' => 'لا يوجد أي تعديل مسجل على هذا الملف حتى الآن.',
			'comptable.beneficiaires.profil.actionsTitre' => 'ما العمل لهذا الملف',
			'comptable.beneficiaires.profil.relancer' => ({required Object nom}) => 'تذكير ${nom}',
			'comptable.beneficiaires.profil.relancerDetail' => 'يفتح محادثة «ملف الدفع» برسالة معدّة مسبقًا، في رسائل العمل.',
			'comptable.beneficiaires.profil.demanderMiseAJour' => ({required Object nom}) => 'طلب تحديث من ${nom}',
			'comptable.beneficiaires.profil.suspendre' => ({required Object nom}) => 'إيقاف مدفوعات ${nom}',
			'comptable.beneficiaires.profil.reprendre' => ({required Object nom}) => 'استئناف مدفوعات ${nom}',
			'comptable.beneficiaires.profil.voirFil' => 'عرض محادثة «ملف الدفع»',
			'comptable.beneficiaires.profil.externe' => ({required Object nom}) => 'ليس لدى ${nom} حساب Rewayah: تتيح له دعوة آمنة إدخال وسيلته بنفسه. أعد إرسالها من التزامه، في المتعاقدين.',
			'comptable.beneficiaires.profil.voirContractuels' => 'عرض التزامات المتعاقدين',
			'comptable.beneficiaires.profil.aucuneAction' => 'لا يوجد أي إجراء مفتوح على هذا الملف: إنه محدَّث.',
			'comptable.beneficiaires.profil.relanceTitre' => 'رسالة جاهزة في محادثة «ملف الدفع»',
			'comptable.beneficiaires.profil.relanceObjet' => 'الموضوع: ملف الدفع',
			'comptable.beneficiaires.profil.messageModele' => 'يجب إكمال معلومات الدفع الخاصة بك قبل دفعتك القادمة. يمكنك إضافتها من مساحتك الشخصية.',
			'comptable.beneficiaires.profil.miseAJourDemandee' => ({required Object nom}) => 'سُجّل طلب التحديث لـ ${nom}.',
			'comptable.beneficiaires.profil.suspendus' => ({required Object nom}) => 'أُوقفت مدفوعات ${nom}: لن تُصرف أي دفعة ما لم تُستأنف.',
			'comptable.beneficiaires.profil.repris' => ({required Object nom}) => 'استُؤنفت مدفوعات ${nom}.',
			'comptable.beneficiaires.profil.erreurAction' => 'لم يكتمل الإجراء. تحقق من اتصالك، ثم أعد المحاولة.',
			'comptable.beneficiaires.profil.erreurIndisponible' => 'هذا الإجراء غير مربوط بعد بالخدمة التي تعالجه. أعد المحاولة لاحقًا.',
			'comptable.beneficiaires.profil.suspensionTitre' => ({required Object nom}) => 'إيقاف مدفوعات ${nom}؟',
			'comptable.beneficiaires.profil.suspensionContexte' => 'لن تُصرف أي دفعة لهذا المستفيد ما لم تستأنفها. لن تتغير بياناته. اختر السبب: سيُدوَّن في سجل الملف.',
			'comptable.beneficiaires.profil.motifVerifier' => 'بيانات تحتاج إلى تحقق',
			'comptable.beneficiaires.profil.motifVerifierDetail' => 'تبدو الوسيلة غير صحيحة أو تعذّر تأكيدها.',
			'comptable.beneficiaires.profil.motifAnomalie' => 'خلل مُبلَّغ عنه',
			'comptable.beneficiaires.profil.motifAnomalieDetail' => 'فشلت دفعة حديثة أو أُبلغ عن فرق.',
			'comptable.beneficiaires.profil.motifDemande' => 'طلب من المستفيد',
			'comptable.beneficiaires.profil.motifDemandeDetail' => 'طلب المستفيد عدم استلام أي دفعة حاليًا.',
			'comptable.beneficiaires.profil.motifRequis' => 'اختر سببًا للمتابعة.',
			'comptable.beneficiaires.titre' => 'المستفيدون',
			'comptable.beneficiaires.sousTitre' => 'البيانات مخفية: المستفيد وحده يعدّل بياناته.',
			'comptable.beneficiaires.profilTitre' => 'ملف الدفع',
			'comptable.beneficiaires.recevoir.rubrique' => 'المدفوعات',
			'comptable.beneficiaires.recevoir.ligneDetail' => 'وسائل الدفع الخاصة بك، تديرها أنت وحدك.',
			'comptable.beneficiaires.recevoir.noticeDetail' => 'أضف وسيلة دفع لتتمكن الأكاديمية من صرف دفعتك القادمة.',
			'comptable.beneficiaires.recevoir.phraseAucunMoyen' => 'ليست لديك أي وسيلة دفع بعد. أضف واحدة لاستلام دفعاتك.',
			'comptable.beneficiaires.recevoir.phraseIncomplet' => 'وسيلة الدفع الخاصة بك غير مكتملة. أكملها لاستلام دفعتك القادمة.',
			'comptable.beneficiaires.recevoir.phraseEnVerification' => 'وسيلتك الجديدة قيد التحقق. تُحدَّث حالتها هنا.',
			'comptable.beneficiaires.recevoir.phraseVerifie' => 'تم التحقق من وسيلة الدفع الخاصة بك. ستُرسَل إليها دفعاتك القادمة.',
			'comptable.beneficiaires.recevoir.phraseSuspendu' => 'دفعاتك موقوفة. تواصل مع الأكاديمية لمعرفة السبب.',
			'comptable.beneficiaires.recevoir.phraseActionRequise' => 'مطلوب تحديث وسيلة الدفع الخاصة بك. استبدلها لاستلام دفعتك القادمة.',
			'comptable.beneficiaires.recevoir.phraseInvitationEnvoyee' => 'أُرسلت إليك دعوة آمنة. أضف وسيلة الدفع الخاصة بك لإكمالها.',
			'comptable.beneficiaires.recevoir.suspenduTemporairement' => 'دفعاتك موقوفة ريثما يتم التحقق من وسيلتك الجديدة: هذه حماية من الاحتيال.',
			'comptable.beneficiaires.recevoir.mesMethodes' => 'وسائل الدفع الخاصة بي',
			'comptable.beneficiaires.recevoir.preferee' => 'الوسيلة المفضلة',
			'comptable.beneficiaires.recevoir.inactive' => 'وسيلة سابقة، محفوظة غير مفعّلة',
			'comptable.beneficiaires.recevoir.choisirPreferee' => ({required Object methode}) => 'جعل ${methode} وسيلتي المفضلة',
			'comptable.beneficiaires.recevoir.remplacer' => ({required Object methode}) => 'استبدال ${methode}',
			'comptable.beneficiaires.recevoir.supprimer' => ({required Object methode}) => 'حذف ${methode}',
			'comptable.beneficiaires.recevoir.supprimerQuestion' => ({required Object methode}) => 'حذف ${methode}؟',
			'comptable.beneficiaires.recevoir.supprimerConsequence' => 'لن تستلم بعد الآن أي دفعة على هذه الوسيلة. إن كانت الوحيدة، فستنتظر دفعتك القادمة وسيلة جديدة.',
			'comptable.beneficiaires.recevoir.ajouter' => 'إضافة وسيلة دفع',
			'comptable.beneficiaires.recevoir.ajoutTitre' => 'إضافة وسيلة دفع',
			'comptable.beneficiaires.recevoir.remplacementTitre' => ({required Object methode}) => 'استبدال ${methode}',
			'comptable.beneficiaires.recevoir.ajoutContexte' => 'اختر نوع الوسيلة. ستُدخل بعد ذلك بياناتك في مساحة آمنة: التطبيق لا يراها ولا يحتفظ بها.',
			'comptable.beneficiaires.recevoir.continuerSaisie' => 'المتابعة إلى الإدخال الآمن',
			'comptable.beneficiaires.recevoir.typeRequis' => 'اختر نوع وسيلة للمتابعة.',
			'comptable.beneficiaires.recevoir.aucunType' => 'لا يُقترح أي نوع وسيلة حاليًا. تواصل مع الأكاديمية لفتح نوع.',
			'comptable.beneficiaires.recevoir.verificationAnnoncee' => 'يُتحقَّق من كل تغيير قبل الدفعة القادمة.',
			'comptable.beneficiaires.recevoir.ajoutee' => 'أُضيفت الوسيلة: إنها قيد التحقق.',
			'comptable.beneficiaires.recevoir.remplacee' => 'سُجّلت الوسيلة الجديدة: إنها قيد التحقق.',
			'comptable.beneficiaires.recevoir.supprimee' => 'حُذفت الوسيلة.',
			'comptable.beneficiaires.recevoir.prefereeChoisie' => 'حُدّثت الوسيلة المفضلة.',
			'comptable.beneficiaires.recevoir.erreurAction' => 'لم يكتمل التغيير. تحقق من اتصالك، ثم أعد المحاولة.',
			'comptable.beneficiaires.recevoir.erreurIndisponible' => 'هذا التغيير غير مربوط بعد بخدمة الدفع. أعد المحاولة لاحقًا.',
			'comptable.beneficiaires.recevoir.journalTitre' => 'سجل تغييراتي',
			'comptable.beneficiaires.recevoir.journalVide' => 'لا يوجد أي تغيير مسجل حتى الآن.',
			'comptable.beneficiaires.recevoir.seulVous' => 'أنت وحدك يمكنك تعديل هذه المعلومات: لا المحاسبة ولا الإدارة تستطيع ذلك نيابة عنك.',
			'comptable.beneficiaires.recevoir.titre' => 'استلام مدفوعاتي',
			'comptable.beneficiaires.recevoir.sousTitre' => 'بيانات الدفع الخاصة بك، لا يعدّلها أحد سواك.',
			'comptable.beneficiaires.recevoir.notice' => 'معلومات دفع يجب إكمالها',
			'comptable.beneficiaires.recevoir.configurer' => 'إعداد مدفوعاتي',
			'comptable.contractuels.ongletObligations' => 'الالتزامات',
			'comptable.contractuels.ongletAApprouver' => 'للاعتماد',
			'comptable.contractuels.ongletAPayer' => 'للدفع',
			'comptable.contractuels.ongletHistorique' => 'السجل',
			'comptable.contractuels.ongletsLecteur' => 'عرض الالتزامات',
			'comptable.contractuels.colonneBeneficiaire' => 'المستفيد',
			'comptable.contractuels.colonneObjet' => 'الموضوع',
			'comptable.contractuels.colonneMontant' => 'المبلغ',
			'comptable.contractuels.colonneEcheance' => 'الاستحقاق',
			'comptable.contractuels.colonneStatut' => 'الحالة',
			'comptable.contractuels.typeRecurrente' => 'متكرر',
			'comptable.contractuels.typePonctuelle' => 'لمرة واحدة',
			'comptable.contractuels.echeanceLe' => ({required Object date}) => 'الاستحقاق: ${date}',
			'comptable.contractuels.payer' => 'دفع',
			'comptable.contractuels.payerLecteur' => ({required Object objet}) => 'دفع الالتزام ${objet}',
			'comptable.contractuels.approuver' => 'اعتماد',
			'comptable.contractuels.ouvrirLecteur' => ({required Object objet}) => 'فتح الالتزام ${objet}',
			'comptable.contractuels.creationBloquee' => ({required Object raison}) => 'الالتزام الجديد غير متاح: ${raison}.',
			'comptable.contractuels.videObligations' => 'لا يوجد التزام جارٍ',
			'comptable.contractuels.videObligationsDetail' => 'تظهر هنا الالتزامات المنشأة، مع استحقاقها وحالتها.',
			'comptable.contractuels.videAApprouver' => 'لا شيء للاعتماد',
			'comptable.contractuels.videAApprouverDetail' => 'تظهر هنا الالتزامات التي تنتظر الاعتماد.',
			'comptable.contractuels.videAPayer' => 'لا شيء للدفع',
			'comptable.contractuels.videAPayerDetail' => 'يظهر هنا الالتزام المعتمَد، جاهزًا للدفع.',
			'comptable.contractuels.videHistorique' => 'لا يوجد التزام منتهٍ',
			'comptable.contractuels.videHistoriqueDetail' => 'تظهر هنا الالتزامات المدفوعة أو المرفوضة أو الملغاة.',
			'comptable.contractuels.montantDefini' => 'مبلغ يُحدَّد عند الإنشاء، ويُثبَّت بعد الاعتماد.',
			'comptable.contractuels.montantFige' => 'مبلغ ثُبّت عند الاعتماد: لم يعد يُعدَّل.',
			'comptable.contractuels.montantTitre' => 'المبلغ',
			'comptable.contractuels.sectionLignes' => 'تفاصيل المبلغ',
			'comptable.contractuels.sectionInfos' => 'المعلومات',
			'comptable.contractuels.sectionHistorique' => 'سجل الالتزام',
			'comptable.contractuels.historiqueVide' => 'لا توجد عملية مسجلة لهذا الالتزام.',
			'comptable.contractuels.champBeneficiaire' => 'المستفيد',
			'comptable.contractuels.champType' => 'النوع',
			'comptable.contractuels.champEcheance' => 'الاستحقاق',
			'comptable.contractuels.champJustificatif' => 'المستند المؤيِّد',
			'comptable.contractuels.champCentreCout' => 'مركز التكلفة',
			'comptable.contractuels.champAuteur' => 'المُنشئ',
			'comptable.contractuels.champApprobateur' => 'المعتمِد',
			'comptable.contractuels.champProfilPaiement' => 'دفع المستفيد',
			'comptable.contractuels.champMotifRefus' => 'سبب الرفض',
			'comptable.contractuels.aucunJustificatif' => 'لا يوجد مستند مؤيِّد مرفق',
			'comptable.contractuels.nonRenseigne' => 'غير محدد',
			'comptable.contractuels.ligneSource' => ({required Object source}) => 'المصدر: ${source}',
			'comptable.contractuels.ligneAuteur' => ({required Object auteur}) => 'أضافه ${auteur}',
			'comptable.contractuels.ligneValidation' => ({required Object validation}) => 'المصادقة: ${validation}',
			'comptable.contractuels.payerAide' => 'يُفتح الدفع في تفاصيل الدفعة، بالمبلغ الدقيق.',
			'comptable.contractuels.approuverAide' => 'بعد الاعتماد، يُثبَّت المبلغ ويصبح الالتزام قابلًا للدفع.',
			'comptable.contractuels.renvoyerInvitation' => 'إعادة إرسال الدعوة',
			'comptable.contractuels.invitationAide' => 'هذا المستفيد الخارجي يُدخل وسيلة الدفع بنفسه، من دعوته الآمنة.',
			'comptable.contractuels.invitationRenvoyee' => 'أُعيد إرسال الدعوة',
			'comptable.contractuels.erreurApprobation' => 'لا نعلم إن كان الاعتماد قد سُجّل. حدّث الالتزام قبل إعادة المحاولة.',
			'comptable.contractuels.erreurInvitation' => 'لا نعلم إن كانت الدعوة قد أُعيد إرسالها. حدّث الالتزام قبل إعادة المحاولة.',
			'comptable.contractuels.formIntro' => 'المستفيد والاستحقاق ومركز التكلفة مقترحة: غيّرها عند الحاجة، ثم أدخل الموضوع والمبلغ.',
			'comptable.contractuels.beneficiaireExterne' => 'مستفيد خارجي جديد',
			'comptable.contractuels.beneficiaireExterneAide' => 'يتلقى دعوة آمنة ليُدخل وسيلة الدفع بنفسه.',
			'comptable.contractuels.champNomExterne' => 'اسم المستفيد الخارجي',
			'comptable.contractuels.changerEcheance' => 'تغيير الاستحقاق',
			'comptable.contractuels.deviseDe' => ({required Object devise}) => 'العملة: ${devise}',
			'comptable.contractuels.champObjet' => 'موضوع الالتزام',
			'comptable.contractuels.aideObjet' => 'مثلًا: الفاتورة رقم 024',
			'comptable.contractuels.champRefJustificatif' => 'مرجع المستند المؤيِّد (اختياري)',
			'comptable.contractuels.champMontantSaisi' => 'المبلغ',
			'comptable.contractuels.aideMontant' => 'يُدخل مرة واحدة: لا يُعدَّل بعد الاعتماد.',
			'comptable.contractuels.creer' => 'إنشاء الالتزام',
			'comptable.contractuels.horsLigneCreation' => 'أنت غير متصل. أعد الاتصال لإنشاء الالتزام.',
			'comptable.contractuels.erreurObjet' => 'أدخل موضوع الالتزام.',
			'comptable.contractuels.erreurMontant' => 'أدخل مبلغًا أكبر من صفر، مثلًا 350 أو 350,50.',
			'comptable.contractuels.erreurNomExterne' => 'أدخل اسم المستفيد الخارجي.',
			'comptable.contractuels.erreurCreation' => 'لا نعلم إن كان الالتزام قد أُنشئ. حدّث القائمة قبل إعادة المحاولة.',
			'comptable.contractuels.creationIndisponible' => 'لا يستطيع حسابك إنشاء التزام.',
			'comptable.contractuels.retourListe' => 'العودة إلى المتعاقدين',
			'comptable.contractuels.titre' => 'المتعاقدون والالتزامات',
			'comptable.contractuels.sousTitre' => 'تُحدَّد المبالغ عند إنشاء الالتزام، وتُثبَّت بعد الاعتماد.',
			'comptable.contractuels.nouvelle' => 'التزام جديد',
			'comptable.contractuels.detailTitre' => 'الالتزام',
			'comptable.validation.sousTitre' => 'طلبات المحاسب التي تنتظر قرار شخص مخوَّل آخر. صاحب الطلب لا يصادق أبدًا على طلبه.',
			'comptable.validation.aDecider' => 'للبتّ',
			'comptable.validation.decidees' => 'بُتّ فيها مؤخرًا',
			'comptable.validation.videTitre' => 'لا شيء للمصادقة',
			'comptable.validation.videPhrase' => 'ستظهر هنا طلبات المحاسب القادمة.',
			'comptable.validation.natures.payoutSensible' => 'دفعة حساسة',
			'comptable.validation.natures.retraitReserve' => 'السحب من الاحتياطي الاستراتيجي',
			'comptable.validation.natures.obligationAApprouver' => 'التزام لمرة واحدة',
			'comptable.validation.natures.payoutDuComptable' => 'أجر المحاسب',
			'comptable.validation.natures.sortieCoffreProtege' => 'الخروج من صندوق محمي',
			'comptable.validation.demandePar' => ({required Object demandeur, required Object date}) => 'طلبه ${demandeur} في ${date}',
			'comptable.validation.valideePar' => ({required Object decideur, required Object date}) => 'صادق عليه ${decideur} في ${date}',
			'comptable.validation.refuseePar' => ({required Object decideur, required Object date}) => 'رفضه ${decideur} في ${date}',
			'comptable.validation.motif' => ({required Object motif}) => 'السبب: ${motif}',
			'comptable.validation.ouvrir' => ({required Object objet}) => 'عرض الطلب: ${objet}',
			'comptable.validation.votreDemandeTitre' => 'طلبك أنت',
			'comptable.validation.votreDemandePhrase' => 'سيبتّ فيه شخص مخوَّل آخر: لا تصادق أبدًا على طلب قدّمته.',
			'comptable.validation.detail.titre' => 'طلب مصادقة',
			'comptable.validation.detail.nature' => 'النوع',
			'comptable.validation.detail.objet' => 'الموضوع',
			'comptable.validation.detail.demandeur' => 'طلبه',
			'comptable.validation.detail.date' => 'تاريخ الطلب',
			'comptable.validation.detail.raison' => 'السبب',
			'comptable.validation.detail.montant' => 'المبلغ الدقيق',
			'comptable.validation.detail.etat' => 'الحالة',
			'comptable.validation.detail.historique' => 'السجل',
			'comptable.validation.detail.historiqueVide' => 'لا يوجد أي إدخال حتى الآن.',
			'comptable.validation.valider' => 'مصادقة',
			'comptable.validation.refuser' => 'رفض',
			'comptable.validation.annuler' => 'إلغاء',
			'comptable.validation.fermer' => 'إغلاق',
			'comptable.validation.confirmerRefus' => 'تأكيد الرفض',
			'comptable.validation.motifTitre' => 'سبب الرفض',
			'comptable.validation.motifPhrase' => 'سيقرأ المحاسب هذا السبب مع القرار. اختر واحدًا، أو حدّد سببك.',
			'comptable.validation.motifs.coordonnees' => 'بيانات المستفيد تحتاج إلى تحقق',
			'comptable.validation.motifs.montant' => 'المبلغ يحتاج إلى تحقق في المصدر',
			'comptable.validation.motifs.justificatif' => 'المستند المؤيِّد ناقص أو غير مقروء',
			'comptable.validation.motifs.reserve' => 'خارج سياسة الاحتياطي',
			'comptable.validation.motifs.reporter' => 'يؤجَّل إلى الدورة القادمة',
			'comptable.validation.motifs.autre' => 'آخر',
			'comptable.validation.motifAutreChamp' => 'حدّد السبب',
			'comptable.validation.erreurMotif' => 'اختر سببًا للرفض.',
			'comptable.validation.erreurMotifAutre' => 'حدّد السبب للرفض.',
			'comptable.validation.decisionValidee' => 'سُجّل قرارك: تمت المصادقة على الطلب.',
			'comptable.validation.decisionRefusee' => 'سُجّل قرارك: رُفض الطلب، مع سببه.',
			'comptable.validation.refusTitre' => 'لم يُسجَّل القرار',
			'comptable.validation.refusDemandeur' => 'أنت من قدّم هذا الطلب: يجب أن يبتّ فيه شخص مخوَّل آخر. لم يتغير شيء.',
			'comptable.validation.refusMotif' => 'الرفض يتطلب سببًا. اختر واحدًا، ثم أكّد.',
			'comptable.validation.refusDejaDecidee' => 'سبق البتّ في هذا الطلب. أعد قراءة القائمة.',
			'comptable.validation.inconnuTitre' => 'القرار غير مؤكد',
			'comptable.validation.inconnuPhrase' => 'لا نعلم إن كان قرارك قد سُجّل. أعد قراءة القائمة قبل أن تقرر من جديد.',
			'comptable.validation.relireListe' => 'إعادة قراءة القائمة',
			'comptable.validation.horsLigne' => 'غير متصل: أعد الاتصال لتقرر.',
			'comptable.validation.suiviEnAttente' => ({required Object date}) => 'طُلب في ${date}. سيقرر شخص مخوَّل آخر؛ لا يُرسَل شيء قبل قراره.',
			'comptable.validation.suiviValidee' => ({required Object decideur, required Object date}) => 'صادق عليه ${decideur} في ${date}.',
			'comptable.validation.suiviRefusee' => ({required Object decideur, required Object date, required Object motif}) => 'رفضه ${decideur} في ${date}. السبب: ${motif}',
			'comptable.validation.erreurSuivi' => 'تعذرت قراءة حالة طلب المصادقة. أعد المحاولة بعد قليل.',
			'comptable.validation.reessayer' => 'إعادة المحاولة',
			'comptable.direction.versionDepuis' => ({required Object version, required Object date}) => 'الإصدار ${version}، ساري المفعول منذ ${date}',
			'comptable.direction.versionSansDate' => ({required Object version}) => 'الإصدار ${version}',
			'comptable.direction.auteur' => ({required Object auteur}) => 'سجّله ${auteur}',
			'comptable.direction.enregistrer' => 'تسجيل إصدار جديد',
			'comptable.direction.aucuneModification' => 'لا يوجد تعديل للتسجيل.',
			'comptable.direction.corrigezChamps' => 'صحّح الحقول المشار إليها للتسجيل.',
			'comptable.direction.enregistree' => 'سُجّل الإصدار الجديد.',
			'comptable.direction.erreurEnregistrement' => 'لا نعلم إن كان هذا الإصدار قد سُجّل. أعد قراءة الإصدار الساري، ثم أعد المحاولة.',
			'comptable.direction.enregistrementIndisponible' => 'التسجيل غير متاح بعد. أعد المحاولة لاحقًا.',
			'comptable.direction.historique' => 'سجل الإصدارات',
			'comptable.direction.historiqueVide' => 'لا يوجد إصدار قبل هذا.',
			'comptable.direction.etatActuel' => 'الحالة الحالية للاحتياطي',
			'comptable.direction.suffixeMois' => 'أشهر',
			'comptable.direction.suffixeJours' => 'أيام',
			'comptable.direction.suffixePourcent' => '%',
			'comptable.direction.erreurNombre' => 'أدخل عددًا صحيحًا أكبر من صفر.',
			'comptable.direction.erreurPourcentage' => 'أدخل نسبة أكبر من صفر ولا تتجاوز 100، بمنزلة عشرية واحدة على الأكثر.',
			'comptable.direction.erreurMontant' => 'أدخل مبلغًا أكبر من صفر.',
			'comptable.direction.reservePanneau.intro' => 'أنت تحدد السياسة؛ والمحاسب يقرؤها وينفّذها. كل تسجيل يُنشئ إصدارًا جديدًا يُحفظ في السجل.',
			'comptable.direction.reservePanneau.objectifTitre' => 'هدف الاحتياطي',
			'comptable.direction.reservePanneau.objectifDetail' => 'ما يجب أن يبلغه الاحتياطي الاستراتيجي.',
			'comptable.direction.reservePanneau.modeFixe' => 'مبلغ ثابت',
			'comptable.direction.reservePanneau.modeFixeDetail' => 'مبلغ محدد تختاره أنت.',
			'comptable.direction.reservePanneau.modeMois' => 'تغطية بالأشهر',
			'comptable.direction.reservePanneau.modeMoisDetail' => 'عدد من أشهر المصاريف الأساسية.',
			'comptable.direction.reservePanneau.montantCible' => 'المبلغ المستهدف',
			'comptable.direction.reservePanneau.montantCibleDetail' => 'المبلغ الذي يجب أن يبلغه الاحتياطي الاستراتيجي.',
			'comptable.direction.reservePanneau.nombreMois' => 'عدد أشهر التغطية',
			'comptable.direction.reservePanneau.nombreMoisDetail' => 'كم شهرًا من المصاريف الأساسية يجب أن يغطي الاحتياطي.',
			'comptable.direction.reservePanneau.alimentationTitre' => 'التغذية التلقائية',
			'comptable.direction.reservePanneau.alimentationDetail' => 'كيف يمتلئ الاحتياطي دون تدخل من المحاسب.',
			'comptable.direction.reservePanneau.regle.desactivee' => 'معطّلة',
			'comptable.direction.reservePanneau.regle.desactiveeDetail' => 'لا توجد تغذية تلقائية.',
			'comptable.direction.reservePanneau.regle.montantFixe' => 'مبلغ ثابت',
			'comptable.direction.reservePanneau.regle.montantFixeDetail' => 'المبلغ نفسه في كل موعد.',
			'comptable.direction.reservePanneau.regle.pourcentage' => 'نسبة مئوية',
			'comptable.direction.reservePanneau.regle.pourcentageDetail' => 'حصة من المقبوض المُثبَّت.',
			'comptable.direction.reservePanneau.regle.jusquAObjectif' => 'حتى بلوغ الهدف',
			'comptable.direction.reservePanneau.regle.jusquAObjectifDetail' => 'إكمال ما ينقص لبلوغ الهدف.',
			'comptable.direction.reservePanneau.regle.proposee' => 'مقترحة',
			'comptable.direction.reservePanneau.regle.proposeeDetail' => 'اقتراح يؤكده المحاسب.',
			'comptable.direction.reservePanneau.montantAuto' => 'المبلغ المخصَّص',
			'comptable.direction.reservePanneau.montantAutoDetail' => 'المبلغ المخصَّص للاحتياطي في كل موعد.',
			'comptable.direction.reservePanneau.pourcentageAuto' => 'حصة المقبوض المُثبَّت',
			'comptable.direction.reservePanneau.pourcentageAutoDetail' => 'الحصة المخصَّصة للاحتياطي في كل موعد.',
			'comptable.direction.reservePanneau.cadenceTitre' => 'الوتيرة',
			'comptable.direction.reservePanneau.cadenceDetail' => 'متى تتم التغذية.',
			'comptable.direction.reservePanneau.cadence.clotureCycle' => 'عند كل إقفال دورة',
			'comptable.direction.reservePanneau.cadence.hebdomadaire' => 'كل أسبوع',
			'comptable.direction.reservePanneau.cadence.mensuelle' => 'كل شهر',
			'comptable.direction.reservePanneau.cadence.apresEncaissementConsolide' => 'بعد كل مقبوض مُثبَّت',
			'comptable.direction.reservePanneau.cadence.manuelle' => 'يدوية',
			'comptable.direction.reservePanneau.seuilTitre' => 'التنبيه',
			'comptable.direction.reservePanneau.seuil' => 'حد التنبيه',
			'comptable.direction.reservePanneau.seuilDetail' => 'دون هذه الحصة من الهدف، يُشار إلى الاحتياطي بأنه «دون الهدف». اتركه فارغًا لعدم تحديد أي حد.',
			'comptable.direction.reservePanneau.seuilIndice' => 'بلا حد',
			'comptable.direction.reservePanneau.retraitTitre' => 'السحب',
			'comptable.direction.reservePanneau.retraitSwitch' => 'السحب يتطلب مصادقة إضافية',
			'comptable.direction.reservePanneau.retraitSwitchDetail' => 'إخراج المال من الاحتياطي عملية حساسة: يصادق عليها شخص غير صاحب الطلب.',
			'comptable.direction.delegationPanneau.intro' => 'تحدد مرة واحدة ما يستطيع المحاسب تنفيذه وحده. وكل ما عدا ذلك يعود إليك.',
			'comptable.direction.delegationPanneau.pouvoirsTitre' => 'ما يستطيع المحاسب فعله وحده',
			'comptable.direction.delegationPanneau.paiementsStandards' => 'دفع المدفوعات العادية',
			'comptable.direction.delegationPanneau.paiementsStandardsDetail' => 'الدفعة بالمبلغ المحسوب، نحو وسيلة متحقَّق منها، تُرسَل دون مصادقة يومية.',
			'comptable.direction.delegationPanneau.remboursement' => 'تنفيذ استرداد عادي',
			'comptable.direction.delegationPanneau.remboursementDetail' => 'الاسترداد المطابق للقاعدة يُنفَّذ دون مصادقة.',
			'comptable.direction.delegationPanneau.alimentationReserve' => 'تغذية الاحتياطي الاستراتيجي',
			'comptable.direction.delegationPanneau.alimentationReserveDetail' => 'حركة نحو الاحتياطي، مطابقة لسياسته.',
			'comptable.direction.delegationPanneau.plafondsTitre' => 'الحدود القصوى',
			'comptable.direction.delegationPanneau.plafondsDetail' => 'بعد تجاوز الحد الأقصى، تتطلب الدفعة مصادقتك. اتركه فارغًا لعدم تحديد أي حد.',
			'comptable.direction.delegationPanneau.plafondTransaction' => 'الحد الأقصى لكل معاملة',
			'comptable.direction.delegationPanneau.plafondTransactionDetail' => 'أقصى مبلغ لدفعة واحدة.',
			'comptable.direction.delegationPanneau.plafondLot' => 'الحد الأقصى لكل دفعة مجمّعة',
			'comptable.direction.delegationPanneau.plafondLotDetail' => 'أقصى مبلغ لمجموعة مدفوعات.',
			'comptable.direction.delegationPanneau.plafondPeriode' => 'الحد الأقصى التراكمي لكل فترة',
			'comptable.direction.delegationPanneau.plafondPeriodeDetail' => 'أقصى إجمالي خلال الفترة؛ يمنع الالتفاف على الحد بالتجزئة.',
			'comptable.direction.delegationPanneau.plafondIndice' => 'بلا حد',
			'comptable.direction.delegationPanneau.validationsTitre' => 'متى تُشترط مصادقة ثانية',
			'comptable.direction.delegationPanneau.retraitReserve' => 'السحب من الاحتياطي الاستراتيجي',
			'comptable.direction.delegationPanneau.retraitReserveDetail' => 'ممنوع على المحاسب دون مصادقة.',
			'comptable.direction.delegationPanneau.premierPaiement' => 'أول دفعة لمستفيد',
			'comptable.direction.delegationPanneau.premierPaiementDetail' => 'أول دفعة لمستفيد تتطلب مصادقة ثانية.',
			'comptable.direction.delegationPanneau.coordonnees' => 'بيانات عُدّلت مؤخرًا',
			'comptable.direction.delegationPanneau.coordonneesDetail' => 'الدفعة نحو بيانات عُدّلت مؤخرًا تتطلب مصادقة ثانية.',
			'comptable.direction.delegationPanneau.joursRecents' => 'مدة التعديل الحديث',
			'comptable.direction.delegationPanneau.joursRecentsDetail' => 'خلال هذا العدد من الأيام بعد التعديل، تُعدّ البيانات حديثة.',
			'comptable.direction.delegationPanneau.toujoursTitre' => 'ممنوع دائمًا على المحاسب',
			'comptable.direction.delegationPanneau.toujoursDetail' => 'هذه القواعد الثلاث لا تُعدَّل.',
			'comptable.direction.delegationPanneau.autoPayout' => 'أن يدفع لنفسه',
			'comptable.direction.delegationPanneau.autoPayoutDetail' => 'دفعته الخاصة تمر دائمًا عبر شخص آخر.',
			'comptable.direction.delegationPanneau.montantManuel' => 'إدخال مبلغ يدويًا عند الدفع',
			'comptable.direction.delegationPanneau.montantManuelDetail' => 'مبلغ الدفعة هو دائمًا مبلغ الالتزام.',
			'comptable.direction.delegationPanneau.politiqueTarifaire' => 'تعديل الأسعار',
			'comptable.direction.delegationPanneau.politiqueTarifaireDetail' => 'سياسة الأسعار تبقى للإدارة.',
			'comptable.direction.titre' => 'الاحتياطي والتفويض',
			'comptable.direction.sousTitre' => 'سياسة الاحتياطي الاستراتيجي وما يستطيع المحاسب تنفيذه وحده.',
			'comptable.direction.reserve' => 'سياسة الاحتياطي الاستراتيجي',
			'comptable.direction.delegation' => 'التفويض المالي',
			'comptable.demo.titre' => 'عرض توضيحي للمحاسب',
			'comptable.demo.mention' => 'بيانات وهمية، لا دفع، لا إرسال.',
			'comptable.demo.intro' => 'اختر شاشة من شاشات المحاسب. المبالغ مخفية افتراضيًا؛ ونسخة «المبالغ ظاهرة» تكشفها طوال مدة الصفحة.',
			'comptable.demo.montantsMasques' => 'المبالغ مخفية',
			'comptable.demo.montantsAffiches' => 'المبالغ ظاهرة',
			'comptable.demo.groupeComptable' => 'واجهة المحاسب',
			'comptable.demo.groupeCompte' => 'الحساب والمستفيد',
			'comptable.demo.groupeDirection' => 'الإدارة',
			_ => null,
		};
	}
}
