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
	@override late final _Traductions$notifications$ar notifications = _Traductions$notifications$ar._(_root);
	@override late final _Traductions$historique$ar historique = _Traductions$historique$ar._(_root);
	@override late final _Traductions$commun$ar commun = _Traductions$commun$ar._(_root);
	@override late final _Traductions$etat$ar etat = _Traductions$etat$ar._(_root);
	@override late final _Traductions$classe$ar classe = _Traductions$classe$ar._(_root);
	@override late final _Traductions$salle$ar salle = _Traductions$salle$ar._(_root);
	@override late final _Traductions$eleve$ar eleve = _Traductions$eleve$ar._(_root);
	@override late final _Traductions$enseignant$ar enseignant = _Traductions$enseignant$ar._(_root);
	@override late final _Traductions$compte$ar compte = _Traductions$compte$ar._(_root);
	@override late final _Traductions$tuteur$ar tuteur = _Traductions$tuteur$ar._(_root);
	@override late final _Traductions$nav$ar nav = _Traductions$nav$ar._(_root);
	@override late final _Traductions$tc$ar tc = _Traductions$tc$ar._(_root);
	@override late final _Traductions$com$ar com = _Traductions$com$ar._(_root);
}

// Path: notifications
class _Traductions$notifications$ar extends Traductions$notifications$fr {
	_Traductions$notifications$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإشعارات';
	@override String get indisponibleTitre => 'الإشعارات غير متاحة بعد';
	@override String get indisponiblePhrase => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية بمجرد تفعيلها.';
	@override String get videTitre => 'لا توجد إشعارات';
	@override String get videPhrase => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية.';
	@override String ligne({required Object titre, required Object date, required Object heure}) => '${titre}‏، يوم ${date} الساعة ${heure}';
	@override late final _Traductions$notifications$filtres$ar filtres = _Traductions$notifications$filtres$ar._(_root);
	@override String get filtreVideTitre => 'لا توجد إشعارات في هذا التصنيف';
	@override String get filtreVidePhrase => 'اختر »الكل« لرؤية جميع إشعاراتك من جديد.';
	@override String get voirToutes => 'عرض كل الإشعارات';
	@override String get nonLue => 'غير مقروء';
	@override String get nonLueSemantique => 'غير مقروء';
	@override String get lectureNonConfirmee => 'لم تُؤكَّد القراءة بعد. أعد المحاولة بعد قليل.';
	@override late final _Traductions$notifications$detail$ar detail = _Traductions$notifications$detail$ar._(_root);
	@override late final _Traductions$notifications$types$ar types = _Traductions$notifications$types$ar._(_root);
}

// Path: historique
class _Traductions$historique$ar extends Traductions$historique$fr {
	_Traductions$historique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
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
	@override String dateCourte({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}';
	@override String dateCourteSansAnnee({required Object jour, required Object mois}) => '${jour} ${mois}';
	@override String dateLongue({required Object jourSemaine, required Object jour, required Object mois, required Object annee}) => '${jourSemaine} ${jour} ${mois} ${annee}';
}

// Path: commun
class _Traductions$commun$ar extends Traductions$commun$fr {
	_Traductions$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$dates$ar dates = _Traductions$commun$dates$ar._(_root);
	@override late final _Traductions$commun$recherche$ar recherche = _Traductions$commun$recherche$ar._(_root);
	@override late final _Traductions$commun$sections$ar sections = _Traductions$commun$sections$ar._(_root);
}

// Path: etat
class _Traductions$etat$ar extends Traductions$etat$fr {
	_Traductions$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enDirect => 'مباشر';
	@override String get seanceAnnulee => 'ملغاة';
	@override String annuleeValeur({required Object valeur}) => 'ملغاة: ${valeur}';
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
	@override String get catalogue => 'اختيار فصل';
	@override String get planning => 'الجدول';
	@override String get travail => 'قبل الدرس القادم';
	@override String get ressources => 'المكتبة';
	@override String get progression => 'التقدم';
	@override String get observer => 'متابعة الحصة';
	@override String get titre => 'الفصل';
	@override String get historique => 'السجل';
	@override String sousTitre({required Object prenom, required Object enseignant}) => '${prenom} · ${enseignant}';
	@override String get indisponiblePhrase => 'تفاصيل الفصل غير متاحة هنا بعد.';
	@override String get introuvableTitre => 'هذا الفصل غير متاح لهذا الملف';
	@override String get introuvablePhrase => 'ربما انتهى، أو يخص طالبًا آخر من الأسرة.';
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

// Path: tuteur
class _Traductions$tuteur$ar extends Traductions$tuteur$fr {
	_Traductions$tuteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tuteur$accueil$ar accueil = _Traductions$tuteur$accueil$ar._(_root);
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
	@override String get replier => 'طي التنقل';
	@override String get deplier => 'توسيع التنقل';
}

// Path: tc
class _Traductions$tc$ar extends Traductions$tc$fr {
	_Traductions$tc$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$groupe$ar groupe = _Traductions$tc$groupe$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$ar bibliotheque = _Traductions$tc$bibliotheque$ar._(_root);
}

// Path: com
class _Traductions$com$ar extends Traductions$com$fr {
	_Traductions$com$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$socle$ar socle = _Traductions$com$socle$ar._(_root);
	@override late final _Traductions$com$messages$ar messages = _Traductions$com$messages$ar._(_root);
	@override late final _Traductions$com$vocal$ar vocal = _Traductions$com$vocal$ar._(_root);
	@override late final _Traductions$com$communaute$ar communaute = _Traductions$com$communaute$ar._(_root);
	@override late final _Traductions$com$studio$ar studio = _Traductions$com$studio$ar._(_root);
	@override late final _Traductions$com$annonces$ar annonces = _Traductions$com$annonces$ar._(_root);
}

// Path: notifications.filtres
class _Traductions$notifications$filtres$ar extends Traductions$notifications$filtres$fr {
	_Traductions$notifications$filtres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'تصفية الإشعارات';
	@override String get toutes => 'الكل';
	@override String get nonLues => 'غير المقروءة';
	@override String get mentions => 'الإشارات';
	@override String get actionRequise => 'إجراء مطلوب';
}

// Path: notifications.detail
class _Traductions$notifications$detail$ar extends Traductions$notifications$detail$fr {
	_Traductions$notifications$detail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get choisirTitre => 'اختر إشعارًا';
	@override String get choisirPhrase => 'تظهر تفاصيله هنا، بجانب القائمة.';
	@override String recue({required Object date, required Object heure}) => 'وصل يوم ${date} الساعة ${heure}';
	@override String get ouvrir => 'فتح الصفحة المعنية';
}

// Path: notifications.types
class _Traductions$notifications$types$ar extends Traductions$notifications$types$fr {
	_Traductions$notifications$types$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get annonceClasse => 'إعلان الفصل';
	@override String get changementSeance => 'تغيير في الحصة';
	@override String get decisionDossier => 'قرار بشأن ملف';
	@override String get messageMetier => 'رسالة';
	@override String get reponseAttendue => 'رد منتظر';
	@override String get accesFinance => 'الوصول والمدفوعات';
	@override String get observation => 'ملاحظة';
	@override String get travailRessource => 'واجب أو مورد';
	@override String get annonceDirection => 'إعلان من الإدارة';
	@override String get changementPlanning => 'تغيير في الجدول';
	@override String get remplacement => 'استخلاف';
	@override String get mentionCommunaute => 'إشارة في مجتمع المعلمين';
	@override String get reponseCommunaute => 'رد في مجتمع المعلمين';
	@override String get messageAdministration => 'رسالة من الإدارة';
	@override String get dossierATraiter => 'ملف للمعالجة';
	@override String get signalementCommunaute => 'بلاغ في مجتمع المعلمين';
	@override String get reponseFil => 'رد في محادثة';
	@override String get annoncePlanifiee => 'إعلان مجدول للنشر';
	@override String get evenementOperationnel => 'حدث في الأكاديمية';
	@override String get mission => 'مهمة';
	@override String get changementMission => 'تغيير في المهمة';
	@override String get reponseAdministration => 'رد من الإدارة';
	@override String get mentionStudio => 'إشارة في الاستوديو';
	@override String get reponseStudio => 'رد في الاستوديو';
	@override String get decisionDemandee => 'قرار مطلوب';
	@override String get elementAssigne => 'عنصر مُسند';
	@override String get annonceInterne => 'إعلان داخلي';
	@override String get evenementContextuel => 'حدث';
	@override String get autre => 'إشعار';
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
	@override String jourDate({required Object jour, required Object numero, required Object mois}) => '${jour} ${numero} ${mois}';
}

// Path: commun.recherche
class _Traductions$commun$recherche$ar extends Traductions$commun$recherche$fr {
	_Traductions$commun$recherche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get effacer => 'مسح البحث';
	@override String get fermer => 'إغلاق البحث';
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
	@override String get accesInverifiable => 'لا يمكن التحقق من الدخول إلى القاعة حاليًا.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get chargementSeance => 'جارٍ تحميل الحصة القادمة.';
	@override String progressionValeur({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage} %';
	@override String dst({required Object avant, required Object apres}) => 'تغيير التوقيت: سينتقل الدرس من ${avant} إلى ${apres}.';
	@override late final _Traductions$classe$entree$annonce$ar annonce = _Traductions$classe$entree$annonce$ar._(_root);
}

// Path: classe.seance
class _Traductions$classe$seance$ar extends Traductions$classe$seance$fr {
	_Traductions$classe$seance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucune => 'لا توجد حصة مجدولة';
	@override String aucuneDetail({required Object prenom}) => 'ستظهر هنا الحصة القادمة لـ${prenom} بمجرد جدولتها.';
	@override String get illisible => 'تعذّرت قراءة الحصة القادمة.';
	@override String presence({required Object prenom, required Object etat}) => '${prenom}: ${etat}';
}

// Path: classe.observation
class _Traductions$classe$observation$ar extends Traductions$classe$observation$fr {
	_Traductions$classe$observation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get commentCaMarche => 'كيف تعمل؟';
	@override String get uneVisite => 'زيارة واحدة متاحة';
	@override String visites({required Object nombre}) => 'الزيارات المتاحة: ${nombre}';
	@override String resume({required Object visites, required Object duree}) => '${visites} · ${duree} لكل زيارة';
	@override String get restanteAucune => 'لا زيارات متبقية لهذه الحصة';
	@override String get restanteUne => 'زيارة واحدة متبقية لهذه الحصة';
	@override String restantes({required Object nombre}) => 'الزيارات المتبقية لهذه الحصة: ${nombre}';
	@override String minutes({required Object minutes}) => '${minutes} د';
	@override String minutesSecondes({required Object minutes, required Object secondes}) => '${minutes} د ${secondes} ث';
	@override String secondes({required Object secondes}) => '${secondes} ث';
	@override late final _Traductions$classe$observation$motif$ar motif = _Traductions$classe$observation$motif$ar._(_root);
}

// Path: classe.pagePlanning
class _Traductions$classe$pagePlanning$ar extends Traductions$classe$pagePlanning$fr {
	_Traductions$classe$pagePlanning$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get prochaines => 'الحصص القادمة';
	@override String ligne({required Object heure, required Object duree}) => '${heure} · ${duree}';
	@override String ligneFuseau({required Object heure, required Object fuseau, required Object duree}) => '${heure} (${fuseau}) · ${duree}';
	@override String get aucune => 'لا توجد حصص قادمة حاليًا';
	@override String aucuneDetail({required Object prenom}) => 'ستظهر هنا الحصص القادمة لـ${prenom} بمجرد جدولتها.';
	@override String get habituelIndisponible => 'الأيام المعتادة للفصل لا تظهر هنا بعد: تظهر فقط الحصص المجدولة.';
	@override String get indisponible => 'جدول الفصل غير مربوط بهذه المساحة بعد.';
}

// Path: classe.pageTravail
class _Traductions$classe$pageTravail$ar extends Traductions$classe$pageTravail$fr {
	_Traductions$classe$pageTravail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucun => 'لا شيء للتحضير حاليًا';
	@override String get aucunDetail => 'سيظهر هنا العمل الذي يكلّف به المعلم.';
	@override String get indisponible => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.';
	@override String echeance({required Object date}) => 'الموعد النهائي: ${date}';
	@override String get nonCochable => 'لا يمكن بعد تحديد عمل على أنه منجز من هنا.';
	@override late final _Traductions$classe$pageTravail$statut$ar statut = _Traductions$classe$pageTravail$statut$ar._(_root);
}

// Path: classe.pageRessources
class _Traductions$classe$pageRessources$ar extends Traductions$classe$pageRessources$fr {
	_Traductions$classe$pageRessources$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucune => 'لا توجد موارد لهذا الفصل حاليًا';
	@override String get aucuneDetail => 'ستظهر هنا المواد التي يختارها المعلم.';
	@override String get indisponible => 'مكتبة الفصل غير مربوطة بهذه المساحة بعد.';
}

// Path: classe.pageProgression
class _Traductions$classe$pageProgression$ar extends Traductions$classe$pageProgression$fr {
	_Traductions$classe$pageProgression$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String indisponible({required Object prenom}) => 'تقدم ${prenom} غير مُشارك هنا بعد.';
	@override String get niveau => 'المستوى';
	@override String get jalons => 'المراحل المنجزة';
	@override String get aucune => 'لا توجد مراحل مُشاركة حاليًا';
	@override String get aucuneDetail => 'سيظهر هنا التقدم الذي يشاركه المعلم مع الأسرة.';
}

// Path: classe.pageCatalogue
class _Traductions$classe$pageCatalogue$ar extends Traductions$classe$pageCatalogue$fr {
	_Traductions$classe$pageCatalogue$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String pour({required Object prenom}) => 'لـ${prenom}';
	@override String get proposees => 'الفصول المقترحة';
	@override String get indisponible => 'اختيار الفصل عبر الإنترنت غير مفتوح بعد.';
	@override String get aucune => 'لا يوجد فصل مناسب حاليًا';
	@override String aucuneDetail({required Object prenom}) => 'لا يوجد فصل مفتوح يناسب ملف ${prenom} في الوقت الحالي.';
	@override String get eleveInconnuTitre => 'هذا الملف ليس ضمن أسرتك';
	@override String get eleveInconnuPhrase => 'عد إلى الصفحة الرئيسية واختر ملف الطالب المعني.';
	@override String get horairesAbsents => 'أيام هذا الفصل ومواعيده لا تظهر هنا بعد.';
	@override String seanceHebdo({required Object jour, required Object heure, required Object duree}) => '${jour} الساعة ${heure} · ${duree} د';
	@override String fuseauClasse({required Object fuseau}) => 'مواعيد الفصل (${fuseau})';
	@override String get placeUne => 'مقعد واحد متبقٍّ';
	@override String places({required Object nombre}) => 'المقاعد المتبقية: ${nombre}';
	@override late final _Traductions$classe$pageCatalogue$etat$ar etat = _Traductions$classe$pageCatalogue$etat$ar._(_root);
	@override String get choisir => 'اختيار هذا الفصل';
	@override String get rejoindreAttente => 'الانضمام إلى قائمة الانتظار';
	@override String get precisionsTitre => 'قبل الاختيار';
	@override String get precisionEnseignant => 'يحتفظ الفصل بالمعلم نفسه في كل حصصه.';
	@override String get precisionPlaces => 'المقاعد المعروضة هي مقاعد الأكاديمية لحظة القراءة.';
	@override String get precisionReserve => 'لا يُحجز شيء قبل تأكيدك.';
	@override String get confirmerTitre => 'تأكيد الفصل';
	@override String confirmerPhrase({required Object prenom}) => 'أنت تسجّل ${prenom} في هذا الفصل.';
	@override String confirmerAttentePhrase({required Object prenom}) => 'أنت تسجّل ${prenom} في قائمة انتظار هذا الفصل.';
	@override String memeEnseignant({required Object enseignant}) => 'الفصل نفسه والمعلم نفسه في كل حصص الأسبوع: ${enseignant}.';
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

// Path: tuteur.accueil
class _Traductions$tuteur$accueil$ar extends Traductions$tuteur$accueil$fr {
	_Traductions$tuteur$accueil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get prochaineSeance => 'الحصة القادمة';
	@override String heureDe({required Object ville}) => 'توقيت ${ville}';
	@override String get heureAppareil => 'توقيت هذا الجهاز';
	@override String heureClasse({required Object heure, required Object ville}) => 'توقيت الفصل: ${heure} ${ville}';
	@override String get seanceEnDirect => 'الحصة مباشرة';
	@override String get seanceTerminee => 'انتهت الحصة';
	@override String get seanceAnnulee => 'لن تُعقد هذه الحصة.';
	@override String get seanceNonTenue => 'تعذّر عقد هذه الحصة.';
	@override String get horaireIncertain => 'لم يُؤكَّد فتح القاعة بعد';
	@override String get pastilleAnnulee => 'ملغاة';
	@override String get pastilleNonTenue => 'لم تُعقد';
	@override String get pastilleTerminee => 'منتهية';
	@override late final _Traductions$tuteur$accueil$etatCourt$ar etatCourt = _Traductions$tuteur$accueil$etatCourt$ar._(_root);
	@override String get motifAnnuleeTard => 'أُلغيت الحصة قبل موعدها بقليل';
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
	@override String get disponibilites => 'الأوقات المتاحة';
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
	@override String get creneaux => 'الأوقات المتاحة';
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
	@override String get configuration => 'الإعدادات';
	@override String get securite => 'الأمان والتدقيق';
	@override String get direction => 'الإدارة';
	@override String get recherche => 'البحث';
	@override String get rechercheIndication => 'البحث عن شاشة';
	@override String get notificationsTitre => 'الإشعارات';
	@override String get menu => 'القائمة';
}

// Path: tc.groupe
class _Traductions$tc$groupe$ar extends Traductions$tc$groupe$fr {
	_Traductions$tc$groupe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$groupe$mesGroupes$ar mesGroupes = _Traductions$tc$groupe$mesGroupes$ar._(_root);
	@override late final _Traductions$tc$groupe$commun$ar commun = _Traductions$tc$groupe$commun$ar._(_root);
	@override late final _Traductions$tc$groupe$carte$ar carte = _Traductions$tc$groupe$carte$ar._(_root);
	@override late final _Traductions$tc$groupe$enseignant$ar enseignant = _Traductions$tc$groupe$enseignant$ar._(_root);
	@override late final _Traductions$tc$groupe$cours$ar cours = _Traductions$tc$groupe$cours$ar._(_root);
	@override late final _Traductions$tc$groupe$temps$ar temps = _Traductions$tc$groupe$temps$ar._(_root);
	@override late final _Traductions$tc$groupe$duree$ar duree = _Traductions$tc$groupe$duree$ar._(_root);
	@override late final _Traductions$tc$groupe$horloges$ar horloges = _Traductions$tc$groupe$horloges$ar._(_root);
	@override late final _Traductions$tc$groupe$dst$ar dst = _Traductions$tc$groupe$dst$ar._(_root);
	@override late final _Traductions$tc$groupe$session$ar session = _Traductions$tc$groupe$session$ar._(_root);
	@override late final _Traductions$tc$groupe$espace$ar espace = _Traductions$tc$groupe$espace$ar._(_root);
	@override late final _Traductions$tc$groupe$emplacement$ar emplacement = _Traductions$tc$groupe$emplacement$ar._(_root);
}

// Path: tc.bibliotheque
class _Traductions$tc$bibliotheque$ar extends Traductions$tc$bibliotheque$fr {
	_Traductions$tc$bibliotheque$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$bibliotheque$sections$ar sections = _Traductions$tc$bibliotheque$sections$ar._(_root);
}

// Path: com.socle
class _Traductions$com$socle$ar extends Traductions$com$socle$fr {
	_Traductions$com$socle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$socle$composants$ar composants = _Traductions$com$socle$composants$ar._(_root);
	@override late final _Traductions$com$socle$lexique$ar lexique = _Traductions$com$socle$lexique$ar._(_root);
	@override late final _Traductions$com$socle$motifs$ar motifs = _Traductions$com$socle$motifs$ar._(_root);
	@override late final _Traductions$com$socle$signalement$ar signalement = _Traductions$com$socle$signalement$ar._(_root);
	@override late final _Traductions$com$socle$enregistrement$ar enregistrement = _Traductions$com$socle$enregistrement$ar._(_root);
	@override late final _Traductions$com$socle$navigation$ar navigation = _Traductions$com$socle$navigation$ar._(_root);
}

// Path: com.messages
class _Traductions$com$messages$ar extends Traductions$com$messages$fr {
	_Traductions$com$messages$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$messages$entree$ar entree = _Traductions$com$messages$entree$ar._(_root);
	@override String get videDetail => 'تُفتح المحادثة من فصل أو طالب أو ملف.';
	@override String get choisirTitre => 'اختر محادثة';
	@override String get choisir => 'اختر محادثة من القائمة لقراءتها والرد عليها.';
	@override late final _Traductions$com$messages$recherche$ar recherche = _Traductions$com$messages$recherche$ar._(_root);
	@override late final _Traductions$com$messages$ligne$ar ligne = _Traductions$com$messages$ligne$ar._(_root);
	@override late final _Traductions$com$messages$noms$ar noms = _Traductions$com$messages$noms$ar._(_root);
	@override late final _Traductions$com$messages$entete$ar entete = _Traductions$com$messages$entete$ar._(_root);
	@override late final _Traductions$com$messages$types$ar types = _Traductions$com$messages$types$ar._(_root);
	@override late final _Traductions$com$messages$panneau$ar panneau = _Traductions$com$messages$panneau$ar._(_root);
	@override late final _Traductions$com$messages$fil$ar fil = _Traductions$com$messages$fil$ar._(_root);
	@override late final _Traductions$com$messages$demo$ar demo = _Traductions$com$messages$demo$ar._(_root);
	@override String get titre => _root.com.socle.lexique.messagesMetier;
	@override String get vide => 'لا توجد محادثات حاليًا.';
}

// Path: com.vocal
class _Traductions$com$vocal$ar extends Traductions$com$vocal$fr {
	_Traductions$com$vocal$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$vocal$composer$ar composer = _Traductions$com$vocal$composer$ar._(_root);
	@override late final _Traductions$com$vocal$lecteur$ar lecteur = _Traductions$com$vocal$lecteur$ar._(_root);
	@override late final _Traductions$com$vocal$demo$ar demo = _Traductions$com$vocal$demo$ar._(_root);
	@override String get titre => 'رسالة صوتية';
}

// Path: com.communaute
class _Traductions$com$communaute$ar extends Traductions$com$communaute$fr {
	_Traductions$com$communaute$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$communaute$garde$ar garde = _Traductions$com$communaute$garde$ar._(_root);
	@override late final _Traductions$com$communaute$lien$ar lien = _Traductions$com$communaute$lien$ar._(_root);
	@override String get sousTitre => 'تبادل وتعاون بين المعلّمين';
	@override String get sections => 'فئات مجتمع المعلّمين';
	@override String get toutes => 'الكل';
	@override String get videTitre => 'لا توجد منشورات';
	@override String get rechercheVideTitre => 'لا توجد نتائج';
	@override String get rechercheVide => 'لا يوجد منشور يطابق بحثك. جرّب كلمة أخرى.';
	@override String get videToutes => 'لا توجد منشورات حاليًا.';
	@override late final _Traductions$com$communaute$flux$ar flux = _Traductions$com$communaute$flux$ar._(_root);
	@override late final _Traductions$com$communaute$recherche$ar recherche = _Traductions$com$communaute$recherche$ar._(_root);
	@override late final _Traductions$com$communaute$moment$ar moment = _Traductions$com$communaute$moment$ar._(_root);
	@override late final _Traductions$com$communaute$publication$ar publication = _Traductions$com$communaute$publication$ar._(_root);
	@override late final _Traductions$com$communaute$reponses$ar reponses = _Traductions$com$communaute$reponses$ar._(_root);
	@override late final _Traductions$com$communaute$signalement$ar signalement = _Traductions$com$communaute$signalement$ar._(_root);
	@override late final _Traductions$com$communaute$composer$ar composer = _Traductions$com$communaute$composer$ar._(_root);
	@override late final _Traductions$com$communaute$regles$ar regles = _Traductions$com$communaute$regles$ar._(_root);
	@override late final _Traductions$com$communaute$entree$ar entree = _Traductions$com$communaute$entree$ar._(_root);
	@override late final _Traductions$com$communaute$demo$ar demo = _Traductions$com$communaute$demo$ar._(_root);
	@override String get titre => _root.com.socle.lexique.communaute;
	@override String get vide => 'لا توجد منشورات في هذه الفئة.';
}

// Path: com.studio
class _Traductions$com$studio$ar extends Traductions$com$studio$fr {
	_Traductions$com$studio$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$studio$focus$ar focus = _Traductions$com$studio$focus$ar._(_root);
	@override late final _Traductions$com$studio$aujourdhui$ar aujourdhui = _Traductions$com$studio$aujourdhui$ar._(_root);
	@override late final _Traductions$com$studio$brouillons$ar brouillons = _Traductions$com$studio$brouillons$ar._(_root);
	@override String get sousTitre => 'مساحة عمل الفريق';
	@override late final _Traductions$com$studio$navigation$ar navigation = _Traductions$com$studio$navigation$ar._(_root);
	@override String get choisirTitre => 'اختر قناة';
	@override String get choisir => 'اختر قناة من القائمة لقراءة النقاش والكتابة فيه.';
	@override String get aucunCanalTitre => 'لا توجد قنوات حاليًا';
	@override String get aucunCanal => 'ستظهر هنا القنوات المفتوحة لك.';
	@override late final _Traductions$com$studio$sections$ar sections = _Traductions$com$studio$sections$ar._(_root);
	@override late final _Traductions$com$studio$visibilite$ar visibilite = _Traductions$com$studio$visibilite$ar._(_root);
	@override late final _Traductions$com$studio$canal$ar canal = _Traductions$com$studio$canal$ar._(_root);
	@override late final _Traductions$com$studio$panneau$ar panneau = _Traductions$com$studio$panneau$ar._(_root);
	@override late final _Traductions$com$studio$enregistrer$ar enregistrer = _Traductions$com$studio$enregistrer$ar._(_root);
	@override late final _Traductions$com$studio$enregistres$ar enregistres = _Traductions$com$studio$enregistres$ar._(_root);
	@override late final _Traductions$com$studio$recherche$ar recherche = _Traductions$com$studio$recherche$ar._(_root);
	@override late final _Traductions$com$studio$demo$ar demo = _Traductions$com$studio$demo$ar._(_root);
	@override String get titre => _root.com.socle.lexique.studio;
	@override String get vide => 'لا يوجد نشاط للمعالجة هنا.';
}

// Path: com.annonces
class _Traductions$com$annonces$ar extends Traductions$com$annonces$fr {
	_Traductions$com$annonces$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$annonces$publieur$ar publieur = _Traductions$com$annonces$publieur$ar._(_root);
	@override late final _Traductions$com$annonces$administration$ar administration = _Traductions$com$annonces$administration$ar._(_root);
	@override late final _Traductions$com$annonces$demoPublication$ar demoPublication = _Traductions$com$annonces$demoPublication$ar._(_root);
	@override String get section => 'إعلانات الفصل';
	@override String get annonce => 'إعلان';
	@override String get publier => 'نشر إعلان';
	@override String get videPublier => 'لا توجد إعلانات لهذا الفصل. انشر أول إعلان للفصل كله.';
	@override String auteurDate({required Object auteur, required Object date, required Object heure}) => '${auteur}‏، يوم ${date} الساعة ${heure}';
	@override String date({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}';
	@override String get lire => 'قراءة الإعلان كاملًا';
	@override String get ouvrirClasse => 'فتح الفصل';
	@override String ouvrirClasseSemantique({required Object classe}) => 'فتح ${classe}';
	@override String get marquerLue => 'تحديد كمقروء';
	@override String get lue => 'مقروء';
	@override String carteSemantique({required Object classe, required Object titre}) => 'إعلان ${classe}: ${titre}';
	@override String get introuvableTitre => 'هذا الإعلان لم يعد متاحًا';
	@override String get introuvablePhrase => 'ربما سُحب من الفصل. عد إلى إشعاراتك.';
	@override late final _Traductions$com$annonces$demo$ar demo = _Traductions$com$annonces$demo$ar._(_root);
	@override String get titre => 'الإعلانات';
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

// Path: classe.observation.motif
class _Traductions$classe$observation$motif$ar extends Traductions$classe$observation$motif$fr {
	_Traductions$classe$observation$motif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get visitesEpuisees => 'استخدمت زياراتك لهذه الحصة.';
	@override String get tempsEpuise => 'انتهى وقت المتابعة المخصص لك في هذه الحصة.';
	@override String get seanceNonCommencee => 'تُفتح المتابعة عند بدء الحصة.';
	@override String get seanceTerminee => 'انتهت الحصة.';
	@override String get seanceNonTenue => 'هذه الحصة لن تُعقد، فلا شيء للمتابعة.';
	@override String get horsFenetre => 'القاعة غير مفتوحة في هذا الوقت.';
	@override String get observationDesactivee => 'المتابعة مغلقة لهذا الفصل.';
	@override String get lienAbsent => 'لا يوجد طالب من أسرتك مرتبط بهذه الحصة.';
	@override String enfantAbsent({required Object prenom}) => 'تنتظر المتابعة وصول ${prenom}.';
	@override String presenceEnVerification({required Object prenom}) => 'يجري التحقق من حضور ${prenom}.';
	@override String get visiteDejaOuverte => 'توجد زيارة مفتوحة بالفعل، على هذا الجهاز أو على جهاز آخر.';
	@override String get garantieServeurAbsente => 'متابعة الحصص غير مفتوحة بعد.';
	@override String get reseau => 'تعذّر التحقق من إتاحة المتابعة.';
	@override String get capaciteAbsente => 'المتابعة غير متاحة حاليًا.';
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
	@override String inscritPhrase({required Object prenom, required Object classe}) => 'انضم ${prenom} إلى ${classe}.';
	@override String get voirClasse => 'عرض الفصل';
	@override String get validationTitre => 'تم إرسال الطلب';
	@override String validationPhrase({required Object prenom, required Object classe}) => 'ما زال على الأكاديمية اعتماد تسجيل ${prenom} في ${classe}.';
	@override String get listeAttenteTitre => 'التسجيل في قائمة الانتظار';
	@override String listeAttentePhrase({required Object prenom, required Object classe}) => '${prenom} في قائمة انتظار ${classe}. لم يُحجز أي مقعد حاليًا.';
	@override String get refuseTitre => 'لم يُقبل التسجيل';
	@override String refusePhrase({required Object prenom}) => 'لم يُحجز أي مقعد لـ${prenom}. يمكنك اختيار فصل آخر.';
	@override String get autresClasses => 'عرض الفصول الأخرى';
	@override String get retourAccueil => 'العودة إلى الصفحة الرئيسية';
}

// Path: tuteur.accueil.etatCourt
class _Traductions$tuteur$accueil$etatCourt$ar extends Traductions$tuteur$accueil$etatCourt$fr {
	_Traductions$tuteur$accueil$etatCourt$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enDirect => 'مباشر';
	@override String get salleOuverte => 'القاعة مفتوحة';
	@override String dansMinutes({required Object minutes}) => 'بعد ${minutes} د';
	@override String dansHeures({required Object heures, required Object minutes}) => 'بعد ${heures} س ${minutes} د';
	@override String dansJours({required Object jours}) => 'بعد ${jours} يوم';
	@override String get prevue => 'حصة مقررة';
	@override String get annulee => 'حصة ملغاة';
	@override String get nonTenue => 'حصة لم تُعقد';
	@override String get terminee => 'حصة منتهية';
	@override String get aucune => 'لا توجد حصة';
	@override String get illisible => 'غير متاح';
}

// Path: tc.groupe.mesGroupes
class _Traductions$tc$groupe$mesGroupes$ar extends Traductions$tc$groupe$mesGroupes$fr {
	_Traductions$tc$groupe$mesGroupes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'فصولي';
	@override String get aucun => 'لا يوجد فصل حاليًا';
	@override String get aucunDetail => 'ستضعك الأكاديمية في فصل بمجرد توفر موعد يناسبك.';
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
	@override String ouvrir({required Object libelle}) => 'فتح الفصل ${libelle}';
	@override String capacite({required Object membres, required Object seuil}) => '${membres} / ${seuil}';
	@override String capacitePhrase({required Object membres, required Object seuil}) => '${membres} طلاب من أصل ${seuil} مقاعد';
	@override String get complet => 'مكتمل';
	@override String get prochainCours => 'الدرس القادم';
	@override String get aucuneSeance => 'لا توجد حصة مجدولة';
	@override String get aucuneSeanceDetail => 'لم يُحدَّد جدول هذا الفصل بعد.';
	@override String duree({required Object valeur}) => 'المدة ${valeur}';
	@override String get dureeLibelle => 'المدة';
	@override String get rejoindre => 'انضمام';
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

// Path: tc.groupe.cours
class _Traductions$tc$groupe$cours$ar extends Traductions$tc$groupe$cours$fr {
	_Traductions$tc$groupe$cours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String coursEtNiveau({required Object cours, required Object niveau}) => '${cours} · ${niveau}';
}

// Path: tc.groupe.temps
class _Traductions$tc$groupe$temps$ar extends Traductions$tc$groupe$temps$fr {
	_Traductions$tc$groupe$temps$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String dansMinutes({required Object minutes}) => 'الدرس بعد ${minutes} د';
	@override String dansHeures({required Object heures, required Object minutes}) => 'الدرس بعد ${heures} س ${minutes} د';
	@override String get imminent => 'الدرس وشيك';
	@override String salleOuverte({required Object reste}) => 'القاعة مفتوحة · ${reste}';
	@override String get salleOuverteCourt => 'القاعة مفتوحة';
	@override String get attente => 'أنت في القاعة. لم يبدأ الدرس بعد.';
	@override String get attenteDetail => 'وقت الانتظار هذا لا يُحتسب في حضورك.';
	@override String get enSalle => 'في القاعة';
	@override String resteMinutes({required Object minutes}) => 'متبقٍّ ${minutes} د';
	@override String resteHeures({required Object heures, required Object minutes}) => 'متبقٍّ ${heures} س ${minutes} د';
	@override String enCours({required Object reste}) => 'الحصة مباشرة · ${reste}';
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
	@override String minutes({required Object minutes}) => '${minutes} د';
	@override String heures({required Object heures}) => '${heures} س';
	@override String heuresMinutes({required Object heures, required Object minutes}) => '${heures} س ${minutes} د';
}

// Path: tc.groupe.horloges
class _Traductions$tc$groupe$horloges$ar extends Traductions$tc$groupe$horloges$fr {
	_Traductions$tc$groupe$horloges$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get votreHeure => 'توقيتك';
	@override String chezEnseignant({required Object nomme}) => 'توقيت ${nomme}';
	@override String get heureGroupe => 'توقيت الفصل';
	@override String heureEtVille({required Object heure, required Object ville}) => '${heure} ${ville}';
}

// Path: tc.groupe.dst
class _Traductions$tc$groupe$dst$ar extends Traductions$tc$groupe$dst$fr {
	_Traductions$tc$groupe$dst$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get j30 => 'تغيير التوقيت بعد شهر';
	@override String get j7 => 'تغيير التوقيت الأسبوع القادم';
	@override String get j1 => 'تغيير التوقيت غدًا';
	@override String detail({required Object avant, required Object apres}) => 'سينتقل درسك من ${avant} إلى ${apres}.';
}

// Path: tc.groupe.session
class _Traductions$tc$groupe$session$ar extends Traductions$tc$groupe$session$fr {
	_Traductions$tc$groupe$session$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get conseilAppareil => 'يُنصح بجهاز لوحي أو حاسوب للدرس. يبقى الهاتف مدعومًا.';
}

// Path: tc.groupe.espace
class _Traductions$tc$groupe$espace$ar extends Traductions$tc$groupe$espace$fr {
	_Traductions$tc$groupe$espace$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get retour => 'فصولي';
	@override String get avantProchainCours => 'قبل الدرس القادم';
	@override String get aucuneAction => 'لا شيء للتحضير حاليًا';
	@override String get bibliotheque => 'المكتبة';
	@override String get bibliothequeVoirTout => 'عرض الكل';
	@override String get progression => 'التقدم';
	@override String get roster => 'طلاب الفصل';
	@override String get reprendreLeCours => 'استئناف الدرس';
	@override String get introuvable => 'هذا الفصل غير متاح لك';
	@override String get introuvableDetail => 'ربما أُغلق، أو يخص ملفًا آخر.';
}

// Path: tc.groupe.emplacement
class _Traductions$tc$groupe$emplacement$ar extends Traductions$tc$groupe$emplacement$fr {
	_Traductions$tc$groupe$emplacement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nonBranche => 'متاح قريبًا';
	@override String get nonBrancheDetail => 'سيُربط هذا المحتوى بهذه المساحة قريبًا.';
}

// Path: tc.bibliotheque.sections
class _Traductions$tc$bibliotheque$sections$ar extends Traductions$tc$bibliotheque$sections$fr {
	_Traductions$tc$bibliotheque$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'المواد المعروضة';
}

// Path: com.socle.composants
class _Traductions$com$socle$composants$ar extends Traductions$com$socle$composants$fr {
	_Traductions$com$socle$composants$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$socle$composants$lecture$ar lecture = _Traductions$com$socle$composants$lecture$ar._(_root);
	@override late final _Traductions$com$socle$composants$badge$ar badge = _Traductions$com$socle$composants$badge$ar._(_root);
	@override late final _Traductions$com$socle$composants$pieceJointe$ar pieceJointe = _Traductions$com$socle$composants$pieceJointe$ar._(_root);
	@override late final _Traductions$com$socle$composants$composer$ar composer = _Traductions$com$socle$composants$composer$ar._(_root);
	@override late final _Traductions$com$socle$composants$etats$ar etats = _Traductions$com$socle$composants$etats$ar._(_root);
	@override late final _Traductions$com$socle$composants$espace$ar espace = _Traductions$com$socle$composants$espace$ar._(_root);
}

// Path: com.socle.lexique
class _Traductions$com$socle$lexique$ar extends Traductions$com$socle$lexique$fr {
	_Traductions$com$socle$lexique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get messages => 'الرسائل';
	@override String get messagesMetier => 'رسائل العمل';
	@override String get communaute => 'مجتمع المعلّمين';
	@override String get studio => 'الاستوديو';
	@override String get aujourdhui => 'اليوم';
	@override String get notifications => 'الإشعارات';
	@override String get annonce => 'إعلان';
	@override String get publication => 'منشور';
	@override String get reponse => 'رد';
	@override String get enregistrer => 'حفظ';
	@override String get signaler => 'إبلاغ';
	@override String get modeFocus => 'وضع التركيز';
	@override String get quitterFocus => 'الخروج من التركيز';
	@override String get aTraiter => 'للمعالجة';
	@override String get actionRequise => 'إجراء مطلوب';
	@override String get brouillon => 'مسودة';
	@override String get elementsEpingles => 'العناصر المثبّتة';
	@override String get fichiersPartages => 'الملفات المشتركة';
}

// Path: com.socle.motifs
class _Traductions$com$socle$motifs$ar extends Traductions$com$socle$motifs$fr {
	_Traductions$com$socle$motifs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'لماذا تبلّغ عن هذا المحتوى؟';
	@override String get publicite => 'إعلان تجاري';
	@override String get lienAffilie => 'رابط تسويق بالعمولة';
	@override String get venteNonAutorisee => 'بيع غير مسموح به';
	@override String get sollicitationCommerciale => 'استدراج تجاري';
	@override String get horsSujet => 'محتوى لا علاقة له بالمجتمع';
	@override String get harcelement => 'مضايقة أو لغة غير لائقة';
	@override String get donneesPersonnelles => 'بيانات شخصية لطالب أو لعائلة';
	@override String get autre => 'محتوى آخر يحتاج إلى فحص';
}

// Path: com.socle.signalement
class _Traductions$com$socle$signalement$ar extends Traductions$com$socle$signalement$fr {
	_Traductions$com$socle$signalement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإبلاغ عن هذا المحتوى';
	@override String get precision => 'توضيح اختياري';
	@override String get envoyer => 'إرسال البلاغ';
	@override String get confirme => 'تم الإبلاغ عن المحتوى. ستتم مراجعته.';
	@override String get erreur => 'لم يُؤكَّد البلاغ بعد. أعد المحاولة بعد قليل.';
	@override String get indisponible => 'الإبلاغ غير متاح هنا بعد.';
}

// Path: com.socle.enregistrement
class _Traductions$com$socle$enregistrement$ar extends Traductions$com$socle$enregistrement$fr {
	_Traductions$com$socle$enregistrement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enregistrer => _root.com.socle.lexique.enregistrer;
	@override String get retirer => 'إزالة من العناصر المحفوظة';
	@override String get enregistre => 'محفوظ';
	@override String get indisponible => 'الحفظ غير متاح هنا بعد.';
}

// Path: com.socle.navigation
class _Traductions$com$socle$navigation$ar extends Traductions$com$socle$navigation$fr {
	_Traductions$com$socle$navigation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get notifications => _root.com.socle.lexique.notifications;
	@override String get ouvrirNotifications => 'فتح الإشعارات';
	@override String get studio => _root.com.socle.lexique.studio;
	@override String get ouvrirStudio => 'فتح الاستوديو';
	@override String get quitterStudio => 'الخروج من الاستوديو';
	@override String get messages => _root.com.socle.lexique.messages;
	@override String get communaute => _root.com.socle.lexique.communaute;
	@override String get communications => 'الاتصالات';
	@override String get communicationsDetail => 'الإعلانات والإشراف ورسائل الصفوف';
	@override String get ongletAnnonces => 'الإعلانات';
	@override String get ongletModeration => 'الإشراف';
	@override String get ongletMessages => _root.com.socle.lexique.messages;
	@override String get bientot => 'متاح قريبًا';
	@override late final _Traductions$com$socle$navigation$provisoire$ar provisoire = _Traductions$com$socle$navigation$provisoire$ar._(_root);
	@override late final _Traductions$com$socle$navigation$demo$ar demo = _Traductions$com$socle$navigation$demo$ar._(_root);
}

// Path: com.messages.entree
class _Traductions$com$messages$entree$ar extends Traductions$com$messages$entree$fr {
	_Traductions$com$messages$entree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titreClasse => 'التواصل بشأن هذا الفصل';
	@override String get titreDossier => 'التواصل بشأن هذا الملف';
	@override String get titreObjet => 'التواصل بشأن هذا الموضوع';
	@override String get ecrireFamille => 'مراسلة الأسرة';
	@override String get ecrireAdministration => 'مراسلة الإدارة';
	@override String ecrireA({required Object nom}) => 'مراسلة ${nom}';
	@override String conversationAvec({required Object nom}) => 'محادثة مع ${nom}';
	@override String get voirTout => 'عرض كل المحادثات';
	@override String get toutes => 'كل محادثاتك';
	@override String get aLireUne => 'محادثة واحدة للقراءة';
	@override String aLire({required Object nombre}) => '${nombre} محادثات للقراءة';
	@override String get ouverture => 'جارٍ فتح المحادثة';
	@override String get inaccessibleTitre => 'محادثة غير متاحة';
	@override String get inaccessible => 'لم تعد هذه المحادثة متاحة لك. اختر شخصًا آخر من القائمة.';
	@override String get erreurOuvertureTitre => 'تعذّر فتح هذه المحادثة.';
	@override String get ouvertureEchouee => 'تحقّق من اتصالك ثم أعد المحاولة.';
}

// Path: com.messages.recherche
class _Traductions$com$messages$recherche$ar extends Traductions$com$messages$recherche$fr {
	_Traductions$com$messages$recherche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get champ => 'البحث عن محادثة';
	@override String get aide => 'الاسم أو الفصل أو الملف';
	@override String get aucunTitre => 'لم يتم العثور على أي محادثة';
	@override String aucun({required Object texte}) => 'لا توجد محادثة تطابق »${texte}«. جرّب اسمًا آخر أو فصلًا آخر.';
	@override String get resultatUn => 'تم العثور على محادثة واحدة';
	@override String resultats({required Object nombre}) => 'تم العثور على ${nombre} محادثات';
}

// Path: com.messages.ligne
class _Traductions$com$messages$ligne$ar extends Traductions$com$messages$ligne$fr {
	_Traductions$com$messages$ligne$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String legende({required Object objet, required Object apercu}) => '${objet} · ${apercu}';
	@override String get sansApercu => 'لا توجد رسائل حاليًا';
	@override String dateCourte({required Object numero, required Object mois}) => '${numero} ${mois}';
}

// Path: com.messages.noms
class _Traductions$com$messages$noms$ar extends Traductions$com$messages$noms$fr {
	_Traductions$com$messages$noms$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String avecFonction({required Object nom, required Object fonction}) => '${nom} · ${fonction}';
	@override String deux({required Object premier, required Object second}) => '${premier} و${second}';
	@override String plusieurs({required Object premier, required Object nombre}) => '${premier} و${nombre} أشخاص آخرين';
	@override String surObjet({required Object objet}) => 'محادثة بخصوص ${objet}';
	@override String get sansObjet => 'محادثة';
}

// Path: com.messages.entete
class _Traductions$com$messages$entete$ar extends Traductions$com$messages$entete$fr {
	_Traductions$com$messages$entete$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String avecAttention({required Object entete, required Object attention}) => '${entete}. ${attention}';
	@override String deuxObjets({required Object premier, required Object second}) => '${premier} · ${second}';
	@override String semantique({required Object noms, required Object objets}) => 'محادثة مع ${noms}‏، بخصوص ${objets}';
	@override String semantiqueSansNoms({required Object objets}) => 'محادثة بخصوص ${objets}';
}

// Path: com.messages.types
class _Traductions$com$messages$types$ar extends Traductions$com$messages$types$fr {
	_Traductions$com$messages$types$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get classe => 'الفصل';
	@override String get eleve => 'الطالب';
	@override String get dossier => 'الملف';
	@override String get mission => 'مهمة المراقبة';
	@override String get remplacement => 'الاستبدال';
	@override String get autre => 'موضوع آخر';
}

// Path: com.messages.panneau
class _Traductions$com$messages$panneau$ar extends Traductions$com$messages$panneau$fr {
	_Traductions$com$messages$panneau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get objets => 'بخصوص';
	@override String get participants => 'المشاركون';
	@override String get fichiers => _root.com.socle.lexique.fichiersPartages;
	@override String ouvrir({required Object objet}) => 'فتح ${objet}';
	@override String get inaccessible => 'لم يعد هذا الموضوع متاحًا لك. تبقى المحادثة متاحة للقراءة.';
	@override String get vous => 'أنت';
}

// Path: com.messages.fil
class _Traductions$com$messages$fil$ar extends Traductions$com$messages$fil$fr {
	_Traductions$com$messages$fil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get lectureSeule => 'يمكنك قراءة هذه المحادثة. الرد فيها غير متاح لك.';
}

// Path: com.messages.demo
class _Traductions$com$messages$demo$ar extends Traductions$com$messages$demo$fr {
	_Traductions$com$messages$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get choisirRole => 'اختر وجهة النظر في هذا العرض التوضيحي.';
	@override late final _Traductions$com$messages$demo$roles$ar roles = _Traductions$com$messages$demo$roles$ar._(_root);
	@override String get situations => 'حالات للتجربة';
	@override String get echec => 'إرسال غير مؤكد، من جهة المعلم';
	@override String get horsLigne => 'دون اتصال، من جهة الأسرة';
	@override String get refuse => 'محادثة أسرة أخرى، مرفوضة';
	@override String vue({required Object role}) => 'وجهة النظر: ${role}';
	@override late final _Traductions$com$messages$demo$f$ar f = _Traductions$com$messages$demo$f$ar._(_root);
}

// Path: com.vocal.composer
class _Traductions$com$vocal$composer$ar extends Traductions$com$vocal$composer$fr {
	_Traductions$com$vocal$composer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'رسالة صوتية';
	@override String get enregistrer => 'تسجيل رسالة صوتية';
	@override String get indisponible => 'الرسالة الصوتية غير متاحة هنا بعد. اكتب رسالتك في الحقل أعلاه.';
	@override String get erreurVerificationTitre => 'تعذّر التحقق من الميكروفون.';
	@override String get erreurVerificationAction => 'إعادة المحاولة';
	@override String get erreurDemarrage => 'تعذّر بدء التسجيل. تحقّق من أن الميكروفون لا يستخدمه تطبيق آخر، ثم أعد المحاولة.';
	@override String get erreurInterrompu => 'توقف التسجيل. تحقّق من الميكروفون، ثم أعد المحاولة.';
	@override String get permissionTitre => 'الميكروفون مطلوب';
	@override String get permissionPhrase => 'يحتاج رواية إلى الميكروفون لتسجيل رسالتك الصوتية. لا يُرسل شيء دون موافقتك.';
	@override String get autoriser => 'السماح باستخدام الميكروفون';
	@override String get annuler => 'إلغاء';
	@override String get refuse => 'الميكروفون غير مسموح به لتطبيق رواية.';
	@override String get refuseAide => 'لإرسال رسالة صوتية، اسمح باستخدام الميكروفون من إعدادات جهازك، ثم عد إلى هنا.';
	@override String get fermer => 'إغلاق';
	@override String get enregistrement => 'التسجيل جارٍ';
	@override String get pause => 'التسجيل متوقف مؤقتًا';
	@override String get reprise => 'استُؤنف التسجيل';
	@override String limiteProche({required Object seuil, required Object max}) => 'بقي أقل من ${seuil} قبل الحد الأقصى ${max}';
	@override String limiteAtteinte({required Object max}) => 'بلغت المدة القصوى (${max}). استمع إلى رسالتك، ثم أرسلها أو احذفها.';
	@override String ecoule({required Object ecoule, required Object max}) => '${ecoule} من ${max}';
	@override String get preEcoute => 'الاستماع قبل الإرسال';
	@override String get preEcouteAide => 'استمع إلى رسالتك قبل إرسالها. لا يُرسل شيء دون موافقتك.';
	@override String duree({required Object duree}) => 'المدة: ${duree}';
	@override String get actionPause => 'إيقاف مؤقت';
	@override String get actionReprendre => 'استئناف';
	@override String get actionArreter => 'إيقاف';
	@override String get actionSupprimer => 'حذف';
	@override String get actionEnvoyer => 'إرسال';
	@override String get confirmerTitre => 'حذف هذه الرسالة الصوتية؟';
	@override String get confirmerPhrase => 'ستُمحى من هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.';
	@override String get garder => 'الاحتفاظ بها';
	@override String get envoi => 'جارٍ إرسال الرسالة الصوتية';
	@override String get nonConfirme => 'لم يتم تأكيد هذه الرسالة الصوتية بعد.';
	@override String get nonConfirmeAide => 'تحقّق من اتصالك، ثم أعد المحاولة. الرسالة الصوتية محفوظة هنا.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get envoye => 'أُرسلت الرسالة الصوتية.';
	@override String get horsLigne => 'أنت غير متصل. الرسالة الصوتية محفوظة هنا: أرسلها عند عودة الاتصال.';
}

// Path: com.vocal.lecteur
class _Traductions$com$vocal$lecteur$ar extends Traductions$com$vocal$lecteur$fr {
	_Traductions$com$vocal$lecteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String libelleAuteur({required Object auteur, required Object duree}) => 'رسالة صوتية من ${auteur}‏، ${duree}';
	@override String libelle({required Object duree}) => 'رسالة صوتية، ${duree}';
	@override String get ecouter => 'استماع';
	@override String get pause => 'إيقاف مؤقت';
	@override String get reprendre => 'استئناف';
	@override String get reecouter => 'إعادة الاستماع';
	@override String get nonEcoute => 'لم يُستمع إليها بعد';
	@override String get lecture => 'التشغيل جارٍ';
	@override String get enPause => 'التشغيل متوقف مؤقتًا';
	@override String get fin => 'استُمع إليها كاملة';
	@override String position({required Object position, required Object duree}) => '${position} من ${duree}';
	@override String get indisponible => 'التشغيل غير متاح هنا بعد. تبقى الرسالة في المحادثة: عد لاحقًا للاستماع إليها.';
	@override String get erreurLectureTitre => 'تعذّر تشغيل هذه الرسالة الصوتية.';
	@override String get erreurLectureAction => 'إعادة المحاولة';
}

// Path: com.vocal.demo
class _Traductions$com$vocal$demo$ar extends Traductions$com$vocal$demo$fr {
	_Traductions$com$vocal$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get contexte => 'عرض توضيحي للرسالة الصوتية: لا يُستخدم ميكروفون حقيقي، والتسجيل محاكى.';
	@override String get situations => 'حالات العرض التوضيحي';
	@override String get autorise => 'الميكروفون مسموح';
	@override String get aDemander => 'يُطلب الإذن';
	@override String get refuse => 'الميكروفون مرفوض';
	@override String get nonConfirme => 'غير مؤكد';
	@override String get indisponible => 'غير متاح';
	@override String get recu => 'رسالة صوتية واردة';
	@override String get repondre => 'الرد في المحادثة';
	@override String get envoyes => 'الرسائل الصوتية المرسلة';
	@override String get auteurEnseignante => 'سيدة مريم، معلمة';
	@override String get auteurParent => 'أحمد، ولي أمر آدم';
	@override String get messageRecu => 'السلام عليكم، هذه ملاحظاتي على تلاوة هذا الأسبوع.';
	@override String get horodatage => 'اليوم، 10:28';
}

// Path: com.communaute.garde
class _Traductions$com$communaute$garde$ar extends Traductions$com$communaute$garde$fr {
	_Traductions$com$communaute$garde$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aide => 'لا إعلانات. لا روابط تسويق بالعمولة. لا بيع.';
	@override String get avertissement => 'يبدو أن هذا المنشور يتضمّن ترويجًا تجاريًا. أزِل الرابط أو الرمز أو العرض قبل النشر.';
	@override String get bloqueAffilie => 'روابط التسويق بالعمولة غير مسموح بها في مجتمع المعلّمين.';
	@override String get bloqueVente => 'بيع المنتجات أو الخدمات غير مسموح به في هذه المساحة.';
	@override String get titreAvertissement => 'منشور يحتاج إلى مراجعة';
	@override String get titreBlocage => 'منشور محظور';
	@override String motif({required Object motif}) => 'السبب: ${motif}';
	@override String get liensTitre => 'روابط المنشور';
	@override String get consigneBlocage => 'عدِّل المنشور ثم انشره من جديد.';
	@override String get panne => 'لم يُؤكَّد التحقق من هذا المحتوى، على الأرجح بسبب الاتصال؛ لم يُنشر شيء. تحقّق من الاتصال ثم أعد المحاولة.';
	@override late final _Traductions$com$communaute$garde$reponse$ar reponse = _Traductions$com$communaute$garde$reponse$ar._(_root);
}

// Path: com.communaute.lien
class _Traductions$com$communaute$lien$ar extends Traductions$com$communaute$lien$fr {
	_Traductions$com$communaute$lien$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get interne => 'رابط داخلي في رواية';
	@override String get ressourceExterne => 'مورد تعليمي خارجي';
	@override String get commercialInterdit => 'رابط تجاري ممنوع';
	@override String get nonVerifie => 'رابط غير مُتحقَّق منه';
	@override String semantique({required Object adresse, required Object etat}) => '${adresse}‏، ${etat}';
}

// Path: com.communaute.flux
class _Traductions$com$communaute$flux$ar extends Traductions$com$communaute$flux$fr {
	_Traductions$com$communaute$flux$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String ouvrir({required Object titre}) => 'فتح المنشور ${titre}';
	@override String get reponseUne => 'رد واحد';
	@override String reponses({required Object nombre}) => '${nombre} ردود';
	@override String get aucuneReponse => 'لا توجد ردود';
	@override String categorie({required Object categorie}) => 'الفئة ${categorie}';
}

// Path: com.communaute.recherche
class _Traductions$com$communaute$recherche$ar extends Traductions$com$communaute$recherche$fr {
	_Traductions$com$communaute$recherche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouvrir => 'البحث عن منشور';
	@override String get champ => 'البحث عن منشور';
	@override String get aide => 'كلمة من العنوان أو النص';
}

// Path: com.communaute.moment
class _Traductions$com$communaute$moment$ar extends Traductions$com$communaute$moment$fr {
	_Traductions$com$communaute$moment$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get instant => 'الآن';
	@override String minutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'منذ دقيقة',
		two: 'منذ دقيقتين',
		few: 'منذ ${n} دقائق',
		many: 'منذ ${n} دقيقة',
		other: 'منذ ${n} دقيقة',
	);
	@override String heures({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'منذ ساعة',
		two: 'منذ ساعتين',
		few: 'منذ ${n} ساعات',
		many: 'منذ ${n} ساعة',
		other: 'منذ ${n} ساعة',
	);
	@override String jours({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'منذ يوم',
		two: 'منذ يومين',
		few: 'منذ ${n} أيام',
		many: 'منذ ${n} يومًا',
		other: 'منذ ${n} يوم',
	);
	@override String date({required Object jour, required Object mois}) => 'في ${jour}/${mois}';
}

// Path: com.communaute.publication
class _Traductions$com$communaute$publication$ar extends Traductions$com$communaute$publication$fr {
	_Traductions$com$communaute$publication$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String auteur({required Object fonction, required Object moment}) => '${fonction} · ${moment}';
	@override String get enregistrer => 'حفظ المنشور';
	@override String get enregistree => 'منشور محفوظ';
	@override String get retirer => 'إزالة من العناصر المحفوظة';
	@override String menu({required Object titre}) => 'إجراءات على المنشور ${titre}';
	@override String get signaler => 'الإبلاغ عن المنشور';
	@override String get signalee => 'تم الإبلاغ عن المحتوى إلى فريق الإشراف.';
	@override String get choisirTitre => 'لا يوجد منشور مفتوح';
	@override String get choisir => 'اختر منشورًا من القائمة لقراءته والرد عليه.';
	@override String get introuvableTitre => 'المنشور غير متاح';
	@override String get introuvable => 'تمت إزالة هذا المنشور أو لم يعد متاحًا لك. عد إلى المنشورات لاختيار منشور آخر.';
	@override String get revenir => 'العودة إلى المنشورات';
}

// Path: com.communaute.reponses
class _Traductions$com$communaute$reponses$ar extends Traductions$com$communaute$reponses$fr {
	_Traductions$com$communaute$reponses$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String titre({required Object nombre}) => 'الردود (${nombre})';
	@override String get vide => 'لا توجد ردود حاليًا.';
	@override String get erreurTitre => 'تعذّر تحميل الردود.';
	@override String get champ => 'ردك';
	@override String get aide => 'اكتب ردًا';
	@override String get envoyer => 'إرسال الرد';
	@override String get champVide => 'اكتب ردًا لإرساله.';
	@override String get enCours => 'جارٍ الإرسال';
	@override String get nonConfirmee => 'لم يُؤكَّد هذا الرد بعد. تحقّق من اتصالك ثم أعد إرساله.';
	@override String get refusee => 'رفضته سياسة المجتمع';
	@override String get reessayer => 'إعادة إرسال الرد';
	@override String get indisponible => 'الردود غير متاحة هنا بعد.';
	@override String menu({required Object nom}) => 'إجراءات على رد ${nom}';
	@override String get signaler => 'الإبلاغ عن الرد';
	@override String get signalee => 'لقد أبلغت عن هذا الرد.';
}

// Path: com.communaute.signalement
class _Traductions$com$communaute$signalement$ar extends Traductions$com$communaute$signalement$fr {
	_Traductions$com$communaute$signalement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$communaute$signalement$politique$ar politique = _Traductions$com$communaute$signalement$politique$ar._(_root);
	@override String get motifManquant => 'اختر سببًا لإرسال البلاغ.';
}

// Path: com.communaute.composer
class _Traductions$com$communaute$composer$ar extends Traductions$com$communaute$composer$fr {
	_Traductions$com$communaute$composer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nouvelle => 'منشور جديد';
	@override String get contexte => 'شارك سؤالًا أو طريقة أو موردًا مفيدًا للتعليم.';
	@override String get categorie => 'الفئة';
	@override String get categorieManquante => 'اختر فئة للنشر.';
	@override String get champTitre => 'العنوان';
	@override String get aideTitre => 'الموضوع في كلمات قليلة';
	@override String get titreManquant => 'اكتب عنوانًا للنشر.';
	@override String get champTexte => 'النص';
	@override String get aideTexte => 'سؤالك أو خبرتك';
	@override String get texteManquant => 'اكتب نص المنشور للنشر.';
	@override String get pieces => 'المرفقات';
	@override String get pieceRefusee => 'أزل الملفات المرفوضة قبل النشر.';
	@override String get choixIndisponible => 'اختيار ملف غير متاح هنا بعد.';
	@override String get publier => 'نشر';
	@override String get fermer => 'إغلاق المنشور الجديد';
	@override String get confirmee => 'منشورك متاح الآن.';
	@override String get erreurEnvoi => 'لم يُؤكَّد منشورك بعد. تحقّق من اتصالك ثم أعد المحاولة.';
	@override String get indisponible => 'النشر غير متاح هنا بعد.';
}

// Path: com.communaute.regles
class _Traductions$com$communaute$regles$ar extends Traductions$com$communaute$regles$fr {
	_Traductions$com$communaute$regles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get panneau => 'المساعدة والقواعد';
	@override String get aProposTitre => 'حول هذه المساحة';
	@override String get aPropos => 'مساحة تعاون بين المعلّمين لطرح الأسئلة وتبادل الطرق والموارد التعليمية.';
	@override String get titre => 'مشاركة تعليمية فقط';
	@override String get corps => 'هذا المجتمع مخصّص للتبادل المهني بين المعلّمين.';
	@override String get reglesTitre => 'قواعد النشر';
	@override String get pasPublicite => 'لا إعلانات';
	@override String get pasAffilie => 'لا روابط تسويق بالعمولة';
	@override String get pasVente => 'لا بيع لمنتج أو خدمة';
	@override String get pasSollicitation => 'لا التماس تجاري';
	@override String get pasDonnees => 'لا بيانات شخصية لطالب أو عائلة';
	@override String get signaler => 'يُبلَّغ عن المحتوى غير المناسب من قائمة المنشور.';
	@override String get voir => 'عرض القواعد';
}

// Path: com.communaute.entree
class _Traductions$com$communaute$entree$ar extends Traductions$com$communaute$entree$fr {
	_Traductions$com$communaute$entree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get lecteur => 'فتح مجتمع المعلّمين';
	@override String get detail => 'أسئلة وطرق وموارد بين المعلّمين';
}

// Path: com.communaute.demo
class _Traductions$com$communaute$demo$ar extends Traductions$com$communaute$demo$fr {
	_Traductions$com$communaute$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get avertissement => 'منشور يحتاج إلى مراجعة: إعلان تجاري';
	@override String get lienAffilie => 'رابط تسويق بالعمولة محظور';
	@override String get vente => 'بيع محظور';
	@override String get signalementNonConfirme => 'إبلاغ غير مؤكَّد';
	@override String get choisir => 'اختر حالة لتجربتها كما يراها معلّم.';
	@override String get aujourdhui => 'اليوم، مع الاختصار';
	@override String get nominal => 'ستة منشورات';
	@override String get publication => 'منشور مفتوح';
	@override String get vide => 'لا توجد منشورات';
	@override String get lectureEchouee => 'فشل القراءة';
	@override String get indisponible => 'الخدمة غير متاحة بعد';
	@override String get horsLigne => 'غير متصل';
	@override String get envoiNonConfirme => 'إرسال غير مؤكَّد';
	@override String get moderationIndisponible => 'الإشراف غير متاح';
	@override String get lecteurSeul => 'قراءة فقط، دون نشر';
	@override late final _Traductions$com$communaute$demo$f$ar f = _Traductions$com$communaute$demo$f$ar._(_root);
}

// Path: com.studio.focus
class _Traductions$com$studio$focus$ar extends Traductions$com$studio$focus$fr {
	_Traductions$com$studio$focus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get entrer => _root.com.socle.lexique.modeFocus;
	@override String get quitter => _root.com.socle.lexique.quitterFocus;
	@override String get actif => 'التركيز مفعّل';
	@override String get actifAvecEchap => 'التركيز مفعّل. اضغط Esc للخروج.';
	@override String get aide => 'أخفِ اللوحات الثانوية للتركيز على هذه المحادثة.';
}

// Path: com.studio.aujourdhui
class _Traductions$com$studio$aujourdhui$ar extends Traductions$com$studio$aujourdhui$fr {
	_Traductions$com$studio$aujourdhui$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => _root.com.socle.lexique.aujourdhui;
	@override String get sousTitre => 'ما يستحق انتباهك في الاستوديو';
	@override late final _Traductions$com$studio$aujourdhui$indicateurs$ar indicateurs = _Traductions$com$studio$aujourdhui$indicateurs$ar._(_root);
	@override late final _Traductions$com$studio$aujourdhui$blocs$ar blocs = _Traductions$com$studio$aujourdhui$blocs$ar._(_root);
	@override late final _Traductions$com$studio$aujourdhui$videsBlocs$ar videsBlocs = _Traductions$com$studio$aujourdhui$videsBlocs$ar._(_root);
	@override String get videTitre => 'لا شيء للمعالجة حاليًا';
	@override String dansCanal({required Object nom}) => 'في ${nom}';
	@override String echeance({required Object date}) => 'الموعد ${date}';
	@override String seTraiteDans({required Object module}) => 'يُعالَج في ${module}';
	@override String ouvrirDans({required Object module, required Object libelle}) => 'فتح في ${module}: ${libelle}';
	@override late final _Traductions$com$studio$aujourdhui$modules$ar modules = _Traductions$com$studio$aujourdhui$modules$ar._(_root);
	@override late final _Traductions$com$studio$aujourdhui$acces$ar acces = _Traductions$com$studio$aujourdhui$acces$ar._(_root);
}

// Path: com.studio.brouillons
class _Traductions$com$studio$brouillons$ar extends Traductions$com$studio$brouillons$fr {
	_Traductions$com$studio$brouillons$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المسودات';
	@override String get detail => 'الرسائل التي بدأتها في قناة ولم تُرسل بعد. تبقى على هذا الجهاز طوال الجلسة، دون مزامنة.';
	@override String dansCanal({required Object nom}) => 'مسودة في ${nom}';
	@override String get canalInconnu => 'مسودة في قناة';
	@override String get canalIndisponible => 'مسودة في قناة لم تعد متاحة';
	@override String modifie({required Object moment}) => 'عُدّلت في ${moment}';
	@override String reprendre({required Object nom}) => 'متابعة المسودة في ${nom}';
	@override String get videTitre => 'لا توجد مسودات';
	@override String get vide => 'ستظهر هنا أي رسالة بدأتها في قناة ولم تُرسل بعد.';
	@override String tous({required Object nombre}) => 'عرض كل المسودات (${nombre})';
	@override String get restaure => 'استُعيدت المسودة. يمكنك متابعة رسالتك.';
}

// Path: com.studio.navigation
class _Traductions$com$studio$navigation$ar extends Traductions$com$studio$navigation$fr {
	_Traductions$com$studio$navigation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aujourdhui => _root.com.socle.lexique.aujourdhui;
	@override String get brouillons => 'المسودات';
	@override String get canaux => 'القنوات';
	@override String get enregistres => 'العناصر المحفوظة';
}

// Path: com.studio.sections
class _Traductions$com$studio$sections$ar extends Traductions$com$studio$sections$fr {
	_Traductions$com$studio$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get organisation => 'التنظيم';
	@override String get admissionsFamilles => 'القبول والأسر';
	@override String get pedagogieQualite => 'التعليم والجودة';
	@override String get planningRemplacements => 'الجدولة والاستبدال';
	@override String get finance => 'المالية';
	@override String get support => 'الدعم';
	@override String get produitTechnique => 'المنتج والتقنية';
	@override String get direction => 'الإدارة العليا';
}

// Path: com.studio.visibilite
class _Traductions$com$studio$visibilite$ar extends Traductions$com$studio$visibilite$fr {
	_Traductions$com$studio$visibilite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get restreint => 'محدودة';
	@override String get prive => 'خاصة';
	@override String get visibleDetail => 'مفتوحة لكل الفريق.';
	@override String get restreintDetail => 'مفتوحة لجزء من الفريق، وأنت منهم.';
	@override String get priveDetail => 'قناة خاصة، مفتوحة لأعضائها فقط. وأنت منهم.';
}

// Path: com.studio.canal
class _Traductions$com$studio$canal$ar extends Traductions$com$studio$canal$fr {
	_Traductions$com$studio$canal$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get membresUn => 'عضو واحد';
	@override String membres({required Object nombre}) => '${nombre} أعضاء';
	@override String aide({required Object nom}) => 'اكتب في ${nom}';
	@override String get lectureSeule => 'يمكنك قراءة هذه القناة. الكتابة فيها غير مفتوحة لك.';
	@override String get aucunMessageTitre => 'لا توجد رسائل حاليًا';
	@override String get aucunMessage => 'ستظهر رسائل هذه القناة هنا فور نشرها.';
	@override String get indisponibleTitre => 'القناة غير متاحة';
	@override String get indisponible => 'هذه القناة غير متاحة لك. اختر قناة أخرى من القائمة.';
}

// Path: com.studio.panneau
class _Traductions$com$studio$panneau$ar extends Traductions$com$studio$panneau$fr {
	_Traductions$com$studio$panneau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'حول القناة';
	@override String get aPropos => 'حول';
	@override String get section => 'القسم';
	@override String get visibilite => 'الظهور';
	@override String get epingles => _root.com.socle.lexique.elementsEpingles;
	@override String get fichiers => 'الملفات الأخيرة';
	@override String get liens => 'روابط مفيدة';
	@override String get vous => 'أنت';
	@override String get parametres => 'إعدادات القناة';
	@override String get parametresDetail => 'سيتاح تعديل الإعدادات مع خدمة الاستوديو.';
	@override String ouvrir({required Object titre}) => 'فتح ${titre}';
	@override String lienExterne({required Object hote}) => 'موقع خارجي: ${hote}';
	@override String get aucunPartageTitre => 'لا شيء مشترك حاليًا';
	@override String get aucunPartage => 'ستظهر هنا العناصر المثبتة والملفات والروابط الخاصة بهذه القناة.';
}

// Path: com.studio.enregistrer
class _Traductions$com$studio$enregistrer$ar extends Traductions$com$studio$enregistrer$fr {
	_Traductions$com$studio$enregistrer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enregistrer => _root.com.socle.lexique.enregistrer;
	@override String get retirer => 'إزالة';
	@override String semantiqueEnregistrer({required Object titre}) => 'حفظ ${titre}';
	@override String semantiqueRetirer({required Object titre}) => 'إزالة ${titre} من العناصر المحفوظة';
	@override String ajoute({required Object titre}) => 'أضيف إلى العناصر المحفوظة: ${titre}.';
	@override String retire({required Object titre}) => 'أزيل من العناصر المحفوظة: ${titre}.';
	@override String get nonConfirme => 'لم يتأكد الحفظ بعد. أعد المحاولة بعد لحظة.';
}

// Path: com.studio.enregistres
class _Traductions$com$studio$enregistres$ar extends Traductions$com$studio$enregistres$fr {
	_Traductions$com$studio$enregistres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get detail => 'القنوات والعناصر التي تحتفظ بها في متناولك. يُفتح كل منها في مكانه الأصلي.';
	@override String get videTitre => 'لا توجد عناصر محفوظة';
	@override String get vide => 'اضغط على حفظ في لوحة قناة لتجد هنا قناة أو عنصرًا.';
	@override String ouvrir({required Object titre}) => 'فتح ${titre}';
	@override String sansDestination({required Object type}) => '${type}‏، لم يعد يُفتح من هنا';
	@override late final _Traductions$com$studio$enregistres$types$ar types = _Traductions$com$studio$enregistres$types$ar._(_root);
}

// Path: com.studio.recherche
class _Traductions$com$studio$recherche$ar extends Traductions$com$studio$recherche$fr {
	_Traductions$com$studio$recherche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get champ => 'البحث في الاستوديو';
	@override String get aide => 'قناة أو رسالة أو ملف';
	@override String get aucunTitre => 'لا توجد نتائج';
	@override String aucun({required Object texte}) => 'لا شيء يطابق »${texte}« في قنواتك. جرّب كلمة أخرى.';
	@override String get aucunDansFiltre => 'لا شيء من هذا النوع يطابق البحث. اختر الكل لرؤية النتائج الأخرى.';
	@override String get resultatUn => 'نتيجة واحدة';
	@override String resultats({required Object nombre}) => '${nombre} نتائج';
	@override String get filtre => 'نوع النتيجة';
	@override String get tout => 'الكل';
	@override String get canaux => 'القنوات';
	@override String get messages => 'الرسائل';
	@override String get fichiers => 'الملفات';
	@override String dansCanal({required Object canal}) => 'في ${canal}';
	@override String messageDe({required Object auteur, required Object canal}) => '${auteur}‏، في ${canal}';
}

// Path: com.studio.demo
class _Traductions$com$studio$demo$ar extends Traductions$com$studio$demo$fr {
	_Traductions$com$studio$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get focus => 'قناة في وضع التركيز';
	@override String get aujourdhuiVide => 'اليوم دون نشاط';
	@override String horsDemo({required Object module}) => 'في التطبيق، يفتح هذا السطر ${module}. يبقى العرض التجريبي على هذه الصفحة.';
	@override String get choisir => 'اختر حالة لتجربتها.';
	@override String get normale => 'الاستوديو وقنواته';
	@override String get echec => 'إرسال غير مؤكد';
	@override String get horsLigne => 'غير متصل';
	@override String get canalPrive => 'عنوان قناة خاصة غير مفتوحة لك';
	@override String get sansCanaux => 'لا توجد قناة مفتوحة';
	@override String vue({required Object situation}) => 'الحالة: ${situation}';
	@override late final _Traductions$com$studio$demo$f$ar f = _Traductions$com$studio$demo$f$ar._(_root);
}

// Path: com.annonces.publieur
class _Traductions$com$annonces$publieur$ar extends Traductions$com$annonces$publieur$fr {
	_Traductions$com$annonces$publieur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'إعلان جديد';
	@override late final _Traductions$com$annonces$publieur$etapes$ar etapes = _Traductions$com$annonces$publieur$etapes$ar._(_root);
	@override late final _Traductions$com$annonces$publieur$contexte$ar contexte = _Traductions$com$annonces$publieur$contexte$ar._(_root);
	@override String get champTitre => 'عنوان الإعلان';
	@override String get champTexte => 'نص الإعلان';
	@override late final _Traductions$com$annonces$publieur$nature$ar nature = _Traductions$com$annonces$publieur$nature$ar._(_root);
	@override late final _Traductions$com$annonces$publieur$quand$ar quand = _Traductions$com$annonces$publieur$quand$ar._(_root);
	@override late final _Traductions$com$annonces$publieur$apercu$ar apercu = _Traductions$com$annonces$publieur$apercu$ar._(_root);
	@override String get continuer => 'متابعة';
	@override String get publier => 'نشر الإعلان';
	@override String get programmer => 'جدولة الإعلان';
	@override String get reessayer => 'إعادة محاولة النشر';
	@override String get terminer => 'إنهاء';
	@override String get manqueContenu => 'اكتب عنوانًا ونصًا للمتابعة.';
	@override String get manqueAudience => 'اختر المستلمين للمتابعة.';
	@override String get enCours => 'النشر جارٍ. انتظر التأكيد.';
	@override String get publiee => 'نُشر الإعلان. يستلمه المستلمون.';
	@override String planifiee({required Object date, required Object heure}) => 'جُدول الإعلان ليوم ${date} الساعة ${heure}.';
	@override String get nonConfirmee => 'لم يُؤكَّد هذا الإعلان بعد. تحقّق من الاتصال ثم أعد المحاولة؛ لن يُرسل إلا مرة واحدة.';
	@override String get horsLigne => 'أنت غير متصل، ولم يُؤكَّد هذا الإعلان بعد. أعد المحاولة عند عودة الاتصال.';
	@override String get indisponible => 'نشر الإعلانات غير متاح بعد. عد لاحقًا.';
	@override String get aucuneCibleTitre => 'لا يوجد مستلم متاح';
	@override String get aucuneCible => 'لا يمكنك النشر لأي مستلم حاليًا. اطلب الإذن من الإدارة.';
	@override String get classeRefuseeTitre => 'النشر مقصور';
	@override String get classeRefusee => 'لا يمكنك نشر إعلان لهذا الفصل. اطلب الإذن من الإدارة.';
}

// Path: com.annonces.administration
class _Traductions$com$annonces$administration$ar extends Traductions$com$annonces$administration$fr {
	_Traductions$com$annonces$administration$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nouvelle => 'إعلان جديد';
	@override String get demo => 'عرض تجريبي';
	@override String get demoDetail => 'بيانات تجريبية: لا رقم حقيقي.';
	@override String get horsLigne => 'أنت غير متصل. لا يمكن تحديث الإعلانات.';
	@override late final _Traductions$com$annonces$administration$indicateurs$ar indicateurs = _Traductions$com$annonces$administration$indicateurs$ar._(_root);
	@override late final _Traductions$com$annonces$administration$publiees$ar publiees = _Traductions$com$annonces$administration$publiees$ar._(_root);
	@override late final _Traductions$com$annonces$administration$planifiees$ar planifiees = _Traductions$com$annonces$administration$planifiees$ar._(_root);
	@override late final _Traductions$com$annonces$administration$matrice$ar matrice = _Traductions$com$annonces$administration$matrice$ar._(_root);
	@override late final _Traductions$com$annonces$administration$moderation$ar moderation = _Traductions$com$annonces$administration$moderation$ar._(_root);
}

// Path: com.annonces.demoPublication
class _Traductions$com$annonces$demoPublication$ar extends Traductions$com$annonces$demoPublication$fr {
	_Traductions$com$annonces$demoPublication$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get lienAdministration => 'إدارة التواصل (الإدارة)';
	@override String get lienPublier => 'نشر إعلان لفصل (المعلم)';
	@override String get toutes => 'الأكاديمية كلها';
	@override String get familles => 'الأسر';
	@override String get enseignants => 'المعلمون';
	@override String get eleves => 'الطلاب';
	@override String get controleurs => 'المراقبون';
	@override String get direction => 'الإدارة';
	@override String get audiencesDirection => 'الأكاديمية كلها، أو جمهور، أو فصل';
	@override String get audiencesEnseignant => 'فصله فقط';
	@override String get vacancesTitre => 'تقويم عطلة الشتاء';
	@override String get vacancesTexte => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.';
	@override String get reunionTitre => 'اجتماع المعلمين يوم الخميس';
	@override String get reunionTexte => 'يبدأ الاجتماع التربوي يوم الخميس الساعة 18، عبر الاتصال المرئي. جدول الأعمال في الاستوديو.';
	@override String get recitationTitre => 'تلاوة نهاية الفصل الدراسي';
	@override String get recitationTexte => 'سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت الساعة 10، عبر الاتصال المرئي.';
	@override String get rentreeTitre => 'استئناف الدروس بعد العطلة';
	@override String get rentreeTexte => 'تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.';
	@override String get signalementAffilie => 'منشور »بطاقات تجويد للطباعة«';
	@override String get extraitAffilie => 'تجدون بطاقاتي عبر هذا الرابط الشريك، خصم 20 % برمزي.';
	@override String get signalementVente => 'منشور »دروس خصوصية متاحة«';
	@override String get extraitVente => 'أقدم دروسًا خصوصية مدفوعة في عطلة نهاية الأسبوع، راسلوني.';
	@override String get signalementHorsSujet => 'رد تحت »تنظيم مراجعة جماعية«';
}

// Path: com.annonces.demo
class _Traductions$com$annonces$demo$ar extends Traductions$com$annonces$demo$fr {
	_Traductions$com$annonces$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get detail => 'عرض تجريبي خارج الإنتاج: بيانات وهمية، ولا يُرسل شيء.';
	@override String get choisirRole => 'اختر الدور المراد عرضه';
	@override late final _Traductions$com$annonces$demo$roles$ar roles = _Traductions$com$annonces$demo$roles$ar._(_root);
	@override String get classeNour => 'فصل النور';
	@override String get classeFajr => 'فصل الفجر';
	@override String get enseignante => 'معلمة الفصل';
	@override late final _Traductions$com$annonces$demo$f$ar f = _Traductions$com$annonces$demo$f$ar._(_root);
}

// Path: com.socle.composants.lecture
class _Traductions$com$socle$composants$lecture$ar extends Traductions$com$socle$composants$lecture$fr {
	_Traductions$com$socle$composants$lecture$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String pieceJointe({required Object nom}) => 'مرفق: ${nom}';
	@override String vocal({required Object duree}) => 'رسالة صوتية مدتها ${duree}';
	@override String get vocalSansDuree => 'رسالة صوتية';
	@override String horodatage({required Object date, required Object heure}) => '${date} · ${heure}';
}

// Path: com.socle.composants.badge
class _Traductions$com$socle$composants$badge$ar extends Traductions$com$socle$composants$badge$fr {
	_Traductions$com$socle$composants$badge$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nonLuUn => '1 غير مقروء';
	@override String nonLus({required Object nombre}) => '${nombre} غير مقروءة';
	@override String nonLusSemantique({required Object nombre}) => '${nombre} عناصر غير مقروءة';
	@override String get nonLuUnSemantique => 'عنصر واحد غير مقروء';
	@override String get information => 'للعلم';
	@override String get aLire => 'للقراءة';
	@override String get actionRequise => _root.com.socle.lexique.actionRequise;
	@override String get urgent => 'عاجل';
	@override String get mention => 'إشارة';
	@override String get mentionSemantique => 'هناك إشارة تخصّك';
}

// Path: com.socle.composants.pieceJointe
class _Traductions$com$socle$composants$pieceJointe$ar extends Traductions$com$socle$composants$pieceJointe$fr {
	_Traductions$com$socle$composants$pieceJointe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get joindre => 'إرفاق ملف';
	@override String get joindreIndisponible => 'إرفاق الملفات غير متاح هنا بعد.';
	@override String get ouvrir => 'فتح';
	@override String ouvrirLecteur({required Object nom}) => 'فتح ${nom}';
	@override String get retirer => 'إزالة';
	@override String retirerLecteur({required Object nom}) => 'إزالة ${nom}';
	@override String tailleOctets({required Object taille}) => '${taille} بايت';
	@override String tailleKo({required Object taille}) => '${taille} كيلوبايت';
	@override String tailleMo({required Object taille}) => '${taille} ميغابايت';
	@override String get autorisee => 'جاهز للإرسال';
	@override String get tropVolumineuse => 'الملف كبير جدًا';
	@override String get tropVolumineuseDetail => 'هذا الملف يتجاوز الحجم المسموح به. اختر ملفًا أصغر.';
	@override String get typeInterdit => 'نوع الملف مرفوض';
	@override String get typeInterditDetail => 'هذا النوع من الملفات غير مقبول هنا. اختر صيغة أخرى.';
	@override String get enCours => 'جارٍ الإرسال';
	@override String get envoyee => 'أُرسل';
	@override String get echec => 'لم يُؤكَّد';
	@override String get erreurEnvoi => 'لم يُؤكَّد إرسال هذا الملف بعد. أعد المحاولة بعد قليل.';
	@override String get indisponible => 'المرفق غير متاح';
	@override String get indisponibleDetail => 'هذا الملف لم يعد متاحًا. اطلب من الشخص الذي شاركه أن يعيد إرساله.';
}

// Path: com.socle.composants.composer
class _Traductions$com$socle$composants$composer$ar extends Traductions$com$socle$composants$composer$fr {
	_Traductions$com$socle$composants$composer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'رسالة';
	@override String get aide => 'اكتب رسالة';
	@override String get envoyer => 'إرسال';
	@override String get champVide => 'اكتب رسالة لإرسالها.';
	@override String get vocal => 'رسالة صوتية';
	@override String get vocalAVenir => 'الرسالة الصوتية متاحة قريبًا';
	@override String get enCours => 'جارٍ الإرسال';
	@override String get envoye => 'أُرسلت';
	@override String get nonConfirme => 'لم يُؤكَّد إرسال هذه الرسالة بعد.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get auteurSoi => 'أنت';
	@override String annonce({required Object auteur, required Object texte}) => 'رسالة جديدة من ${auteur}: ${texte}';
	@override String get brouillon => _root.com.socle.lexique.brouillon;
	@override String get brouillonRestaure => 'تمت استعادة المسودة';
	@override String get enregistrerVocal => _root.com.vocal.composer.enregistrer;
	@override String get aucunMessageTitre => 'لا توجد رسائل حاليًا';
	@override String get aucunMessage => 'اكتب أول رسالة في هذه المحادثة، وستظهر هنا.';
}

// Path: com.socle.composants.etats
class _Traductions$com$socle$composants$etats$ar extends Traductions$com$socle$composants$etats$fr {
	_Traductions$com$socle$composants$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get chargement => 'جارٍ التحميل';
	@override String get videTitre => 'لا شيء هنا حاليًا';
	@override String get erreurTitre => 'تعذّر تحميل هذا المحتوى.';
	@override String get erreur => 'تحقّق من اتصالك ثم أعد المحاولة.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get horsLigne => 'أنت غير متصل. لا يمكن تحديث الرسائل الجديدة.';
	@override String get horsLigneBloc => 'أعد المحاولة عند عودة الاتصال.';
	@override String get indisponibleTitre => 'غير متاح بعد';
	@override String get indisponible => 'هذه الميزة غير متاحة هنا بعد. ستُفتح حين تصبح الخدمة جاهزة.';
	@override String get permissionRefusee => 'ليس لديك صلاحية الوصول إلى هذا المحتوى.';
}

// Path: com.socle.composants.espace
class _Traductions$com$socle$composants$espace$ar extends Traductions$com$socle$composants$espace$fr {
	_Traductions$com$socle$composants$espace$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouvrirPanneau => 'فتح لوحة السياق';
	@override String get fermerPanneau => 'إغلاق لوحة السياق';
	@override String get panneauContexte => 'السياق';
	@override String get retourListe => 'العودة إلى القائمة';
}

// Path: com.socle.navigation.provisoire
class _Traductions$com$socle$navigation$provisoire$ar extends Traductions$com$socle$navigation$provisoire$fr {
	_Traductions$com$socle$navigation$provisoire$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get messagesTitre => _root.com.socle.lexique.messages;
	@override String get messagesDetail => 'ستصل الرسائل المرتبطة بفصولك إلى هذه المساحة قريبًا.';
	@override String get communauteTitre => _root.com.socle.lexique.communaute;
	@override String get communauteDetail => 'ستصل مساحة التبادل بين المعلّمين إلى هنا قريبًا.';
	@override String get studioTitre => _root.com.socle.lexique.studio;
	@override String get studioDetail => 'ستصل مساحة عمل الفريق إلى هنا قريبًا.';
	@override String get administrationTitre => 'إدارة الاتصالات';
	@override String get administrationDetail => 'ستُدار الإعلانات والإشراف والرسائل من هنا قريبًا.';
	@override String get publierAnnonceTitre => 'نشر إعلان';
	@override String get publierAnnonceDetail => 'سيصل نشر إعلان لفصل ما إلى هنا قريبًا.';
}

// Path: com.socle.navigation.demo
class _Traductions$com$socle$navigation$demo$ar extends Traductions$com$socle$navigation$demo$fr {
	_Traductions$com$socle$navigation$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'عرض توضيحي للاتصالات';
	@override String get detail => 'بيانات وهمية، غير موجودة في نسخ الإنتاج.';
	@override String get choisir => 'اختر مساحة لتجربتها.';
}

// Path: com.messages.demo.roles
class _Traductions$com$messages$demo$roles$ar extends Traductions$com$messages$demo$roles$fr {
	_Traductions$com$messages$demo$roles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tuteur => 'الأسرة';
	@override String get enseignant => 'المعلم';
	@override String get adulte => 'طالب بالغ';
	@override String get admin => 'الإدارة';
	@override String get controleur => 'المراقب';
}

// Path: com.messages.demo.f
class _Traductions$com$messages$demo$f$ar extends Traductions$com$messages$demo$f$fr {
	_Traductions$com$messages$demo$f$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ahmed => 'أحمد';
	@override String get parentAdam => 'ولي أمر آدم';
	@override String get enseignanteNour => 'معلمة فصل النور';
	@override String get fatima => 'فاطمة';
	@override String get parentYasmine => 'ولية أمر ياسمين';
	@override String get karim => 'كريم';
	@override String get parentYusuf => 'ولي أمر يوسف';
	@override String get administration => 'الإدارة';
	@override String get directionRewayah => 'إدارة رواية';
	@override String get rachid => 'الأستاذ رشيد';
	@override String get controleurPedagogique => 'مراقب تربوي';
	@override String get youssef => 'يوسف';
	@override String get enseignantFajr => 'معلم فصل الفجر';
	@override String get khadija => 'خديجة';
	@override String get eleveFajr => 'طالبة في فصل الفجر';
	@override String get adam => 'آدم';
	@override String get yasmine => 'ياسمين';
	@override String get yusuf => 'يوسف';
	@override String get dossierAdam => 'ملف تسجيل آدم';
	@override String get missionNour => 'زيارة مراقبة، فصل النور';
	@override String get pieceDevoir => 'واجب_الأسبوع_3.pdf';
	@override String get pieceAttestation => 'الشهادة_القديمة.pdf';
	@override String get pieceVocal => 'رسالة_صوتية.m4a';
	@override String get typeAudio => 'صوت';
	@override String get adamQuestion => 'السلام عليكم، أردت أن أعرف كيف مرّت حصة اليوم بالنسبة إلى آدم. شكرًا جزيلًا.';
	@override String get adamReponse => 'وعليكم السلام، مرّت الحصة على أحسن وجه. كان آدم منتبهًا وشارك مشاركة جيدة.';
	@override String get adamDevoir => 'إليكم واجب الأسبوع القادم.';
	@override String get dossierManque => 'تنقص شهادة مستوى آدم لإتمام تسجيله. هل يمكنكم إيداعها في ملفه؟';
	@override String get missionRetard => 'بدأت الحصة متأخرة ثماني دقائق. أُودع التقرير.';
	@override String get missionSuite => 'شكرًا، سنتحدث في الأمر مع المعلمة هذا الأسبوع.';
	@override String get yasmineMerci => 'شكرًا جزيلًا على هذه التوضيحات.';
	@override String get affectation => 'ينتقل فصل النور إلى يوم الثلاثاء الساعة 18 ابتداءً من الشهر القادم. يرجى التأكيد.';
	@override String get khadijaRevision => 'تذكّري مراجعة سورة الملك قبل يوم الخميس.';
}

// Path: com.communaute.garde.reponse
class _Traductions$com$communaute$garde$reponse$ar extends Traductions$com$communaute$garde$reponse$fr {
	_Traductions$com$communaute$garde$reponse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get avertissement => 'يبدو أن هذا الرد يتضمن ترويجًا تجاريًا. احذف الرابط أو رمز الخصم أو العرض قبل إرساله.';
	@override String get liensTitre => 'روابط الرد';
	@override String get consigneBlocage => 'عدِّل الرد ثم أرسله من جديد.';
}

// Path: com.communaute.signalement.politique
class _Traductions$com$communaute$signalement$politique$ar extends Traductions$com$communaute$signalement$politique$fr {
	_Traductions$com$communaute$signalement$politique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get publicite => 'الإعلانات التجارية غير مسموح بها في مجتمع المعلّمين.';
	@override String get sollicitation => 'الاستدراج التجاري غير مسموح به في هذه المساحة.';
}

// Path: com.communaute.demo.f
class _Traductions$com$communaute$demo$f$ar extends Traductions$com$communaute$demo$f$fr {
	_Traductions$com$communaute$demo$f$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get categoriePedagogie => 'التربية';
	@override String get categorieRessources => 'الموارد';
	@override String get categorieGestion => 'التسيير';
	@override String get fonctionSoi => 'معلم، فصل الفاتحة';
	@override String get prenomSoi => 'إبراهيم';
	@override String get samira => 'سميرة بلقاسم';
	@override String get fonctionSamira => 'معلمة، فصل النور';
	@override String get nour => 'نور الإدريسي';
	@override String get fonctionNour => 'معلمة، فصل الفجر';
	@override String get yasmine => 'ياسمين حداد';
	@override String get fonctionYasmine => 'معلمة، فصل البدر';
	@override String get youssef => 'يوسف العمراني';
	@override String get fonctionYoussef => 'معلم، فصل الكوثر';
	@override String get mariam => 'مريم بن علي';
	@override String get fonctionMariam => 'معلمة، فصل الناس';
	@override String get hamza => 'حمزة والي';
	@override String get fonctionHamza => 'معلم، فصل الإخلاص';
	@override String get memorisationTitre => 'أفكار للمساعدة على الحفظ؟';
	@override String get memorisationTexte => 'ما العادات أو الأنشطة التي تنجح في مساعدة الطلاب على حفظ السور؟ أبحث عن تجارب عملية: ألعاب، ووسائل بصرية، وتكرار ثنائي. شكرًا على أفكاركم!';
	@override String get cartesTitre => 'تجربتي مع بطاقات التكرار';
	@override String get cartesTexte => 'أستخدم بطاقات التكرار منذ بداية العام الدراسي وهي تنجح كثيرًا، حتى مع الأصغر سنًّا. أرفقت النموذج الذي أملؤه قبل كل حصة.';
	@override String get cartesFichier => 'بطاقات_التكرار.pdf';
	@override String get niveauxTitre => 'كيف ندير المستويات المختلفة؟';
	@override String get niveauxTexte => 'كيف تديرون فصلًا تتفاوت فيه المستويات كثيرًا؟ أخشى أن يفقد المتقدمون اهتمامهم بينما أعيد الأساسيات مع الآخرين.';
	@override String get timidesTitre => 'تشجيع الطلاب الخجولين على التلاوة';
	@override String get timidesTexte => 'طالبة ترفض التلاوة أمام الآخرين. أقترح عليها أن تتلو أولًا، حين يكون الفصل لا يزال هادئًا. هل لديكم أفكار أخرى؟';
	@override String get ficheTitre => 'بطاقة لمتابعة المراجعات';
	@override String get ficheTexte => 'أدوّن كل أسبوع السور التي رُوجعت والنقاط التي تحتاج إلى إعادة. تكفي البطاقة صفحة واحدة وتساعد كثيرًا في التحضير للحصة التالية.';
	@override String get heureTitre => 'بدء الحصة في موعدها';
	@override String get heureTexte => 'كثيرًا ما تضيع الدقائق الأولى في التجهيز. صرت أطلب من الطلاب تحضير صفحتهم قبل الموعد. ما رأيكم؟';
	@override String get reponseMariam => 'أستخدم كثيرًا التكرار الثنائي والبطاقات المصوّرة. وهذا يحفّز الطلاب حقًّا.';
	@override String get reponseYoussef => 'يعيد الطلاب الاستماع إلى تلاوة الحصة في البيت، وهذا يساعد كثيرًا بين درسين.';
	@override String get reponseSamira => 'شكرًا على النموذج، سأجربه هذا الأسبوع.';
	@override String get reponseHamza => 'أترك الطالب أحيانًا يتلو على انفراد في نهاية الحصة، ثم أمام زميل واحد.';
	@override String get affilieTitre => 'مشغّلي الصوتي المفضل للمراجعة';
	@override String affilieTexte({required Object lien}) => 'أستخدم هذا المشغّل لإعادة الاستماع إلى السور. سعره مخفَّض هذا الأسبوع عبر رابطي: ${lien}';
	@override String get venteTitre => 'أبيع بطاقات الحفظ الخاصة بي';
	@override String get venteTexte => 'مجموعة من 30 بطاقة مغلَّفة، بـ 25 يورو، تُرسل بالبريد. راسلوني للطلب.';
	@override String get publiciteTitre => 'تطبيق للمراجعة';
	@override String publiciteTexte({required Object lienOffre, required Object lienInterne, required Object lienRessource}) => 'أنصح بتطبيق المراجعة هذا، مع الرمز PROF20 للاشتراك: ${lienOffre}. أما النص، فيكفي مورد المكتبة (${lienInterne}) و${lienRessource}.';
	@override String reponseAffilie({required Object lien}) => 'للمراجعة، أنصح بهذا المشغّل، بسعر مخفَّض عبر رابطي: ${lien}';
	@override String get fichierChoisi => 'بطاقة_الحصة.pdf';
}

// Path: com.studio.aujourdhui.indicateurs
class _Traductions$com$studio$aujourdhui$indicateurs$ar extends Traductions$com$studio$aujourdhui$indicateurs$fr {
	_Traductions$com$studio$aujourdhui$indicateurs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مؤشرات الانتباه';
	@override String get aTraiter => _root.com.socle.lexique.aTraiter;
	@override String get mentions => 'الإشارات والردود';
	@override String get decisions => 'قرارات معلّقة';
	@override String get nonLus => 'غير مقروءة';
}

// Path: com.studio.aujourdhui.blocs
class _Traductions$com$studio$aujourdhui$blocs$ar extends Traductions$com$studio$aujourdhui$blocs$fr {
	_Traductions$com$studio$aujourdhui$blocs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aTraiter => 'للمعالجة اليوم';
	@override String get mentions => 'الإشارات والردود';
	@override String get decisions => 'قرارات معلّقة';
	@override String get echeances => 'مواعيد قريبة';
	@override String get activite => 'النشاط الأخير';
	@override String get brouillons => 'المسودات';
	@override String get acces => 'وصول سريع';
}

// Path: com.studio.aujourdhui.videsBlocs
class _Traductions$com$studio$aujourdhui$videsBlocs$ar extends Traductions$com$studio$aujourdhui$videsBlocs$fr {
	_Traductions$com$studio$aujourdhui$videsBlocs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aTraiter => 'لا شيء للمعالجة اليوم.';
	@override String get mentions => 'لا توجد إشارات أو ردود في الانتظار.';
	@override String get decisions => 'لا توجد قرارات معلّقة.';
	@override String get echeances => 'لا توجد مواعيد قريبة.';
	@override String get activite => 'لا يوجد نشاط حديث.';
}

// Path: com.studio.aujourdhui.modules
class _Traductions$com$studio$aujourdhui$modules$ar extends Traductions$com$studio$aujourdhui$modules$fr {
	_Traductions$com$studio$aujourdhui$modules$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get studio => _root.com.socle.lexique.studio;
	@override String get finance => 'المالية';
	@override String get planning => 'الجدولة';
	@override String get dossiers => 'الملفات';
	@override String get classes => 'الفصول';
	@override String get admissions => 'القبول';
	@override String get demandes => 'الطلبات';
	@override String get communications => 'إدارة الاتصالات';
}

// Path: com.studio.aujourdhui.acces
class _Traductions$com$studio$aujourdhui$acces$ar extends Traductions$com$studio$aujourdhui$acces$fr {
	_Traductions$com$studio$aujourdhui$acces$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get messages => _root.com.socle.lexique.messagesMetier;
	@override String get messagesDetail => 'المحادثات مع الأسر والمعلّمين والمراقبين';
	@override String get annonces => 'الإعلانات';
	@override String get annoncesDetail => 'نشر الإعلانات ومتابعتها';
	@override String get dossiers => 'ملفات للتصديق';
	@override String get dossiersDetail => 'الملفات الجاهزة لاتخاذ قرار';
	@override String get classes => 'الفصول';
	@override String get classesDetail => 'الفصول ومواعيدها ومعلّموها';
	@override String get demandes => 'طلبات بانتظار القرار';
	@override String get demandesDetail => 'طلبات التغيير المنتظرة';
}

// Path: com.studio.enregistres.types
class _Traductions$com$studio$enregistres$types$ar extends Traductions$com$studio$enregistres$types$fr {
	_Traductions$com$studio$enregistres$types$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get canal => 'قناة';
	@override String get publication => 'منشور';
	@override String get message => 'رسالة';
	@override String get element => 'عنصر من الاستوديو';
}

// Path: com.studio.demo.f
class _Traductions$com$studio$demo$f$ar extends Traductions$com$studio$demo$f$fr {
	_Traductions$com$studio$demo$f$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nadia => 'نادية';
	@override String get fonctionDirection => 'الإدارة';
	@override String get mariam => 'مريم';
	@override String get fonctionCoordination => 'التنسيق العام';
	@override String get youssef => 'يوسف';
	@override String get fonctionProduit => 'المنتج والتقنية';
	@override String get amina => 'أمينة';
	@override String get fonctionPedagogie => 'الشؤون التربوية';
	@override String get samira => 'سميرة';
	@override String get fonctionAdmissions => 'القبول';
	@override String get ibrahim => 'إبراهيم';
	@override String get fonctionPlanning => 'الجدولة';
	@override String get pieceAudio => 'صوت';
	@override String get fichierPlanning => 'جدول_الفصل_الثالث.pdf';
	@override String get fichierModeration => 'دليل_الإشراف.pdf';
	@override String get fichierVocal => 'رسالة_صوتية_يوسف.m4a';
	@override String get fichierCompteRendu => 'تقرير_الزيارات.pdf';
	@override String get fichierBudget => 'الميزانية_السرية.pdf';
	@override String get canalOrganisation => 'التنظيم العام';
	@override String get canalOrganisationDetail => 'تنسيق عمل الفريق كله';
	@override String get canalAdmissions => 'القبول';
	@override String get canalAdmissionsDetail => 'متابعة طلبات التسجيل';
	@override String get canalQualite => 'متابعة الجودة';
	@override String get canalQualiteDetail => 'ملاحظات زيارات المراقبة';
	@override String get canalRemplacements => 'البدلاء';
	@override String get canalRemplacementsDetail => 'غيابات الأسبوع والمعلمون البدلاء';
	@override String get canalCloture => 'إقفال الشهر';
	@override String get canalClotureDetail => 'التحضير للإقفال الشهري';
	@override String get canalDirection => 'الإدارة الاستراتيجية';
	@override String get canalDirectionDetail => 'توجهات الإدارة';
	@override String get messagePlanning => 'السلام عليكم جميعًا. إليكم جدول الفصل الدراسي القادم، أخبروني إن كان فيه ما لا يناسب.';
	@override String get messageSupports => 'أحدّث مواد المستوى 2 ونراجع الأمر معًا غدًا.';
	@override String get messageMerci => 'شكرًا للجميع على هذا الأسبوع.';
	@override String get messageDossiers => 'ثلاثة ملفات تنتظر قرارًا قبل يوم الجمعة. نادية، هل يمكنك الاطلاع على ملف أسرة كريم؟';
	@override String get messageCompteRendu => 'تقرير زيارات هذا الشهر جاهز.';
	@override String get messageRemplacement => 'يوم الثلاثاء، يتولى معلم بديل فصل النور. الجدول محدَّث.';
	@override String get messageJustificatifs => 'جُمعت مستندات شهر سبتمبر.';
	@override String get messageBudget => 'الميزانية السرية لهذا الفصل الدراسي.';
	@override String get activiteBudget => 'الميزانية السرية لهذا الفصل الدراسي';
	@override String get partagePlanning => 'جدول الفصل الدراسي';
	@override String get partageModeration => 'دليل الإشراف';
	@override String epinglePar({required Object nom}) => 'ثبّته ${nom}';
	@override String partagePar({required Object nom}) => 'شاركه ${nom}';
	@override String get lienRemplacements => 'بدلاء الأسبوع';
	@override String get lienCharte => 'ميثاق الفريق';
	@override String get brouillon => 'سميرة، سأطّلع على ملف أسرة كريم هذا المساء وأخبرك صباح الغد';
	@override String get activitePaiement => 'دفعة سبتمبر غير مؤكدة لأسرة حداد';
	@override String get objetEcheancier => 'جدول أقساط أسرة حداد';
	@override String get activiteDossierKarim => 'ملف أسرة كريم جاهز لاتخاذ قرار';
	@override String get objetDossierKarim => 'ملف أسرة كريم';
	@override String get activiteMention => 'أشارت إليك سميرة';
	@override String get activiteReponse => 'ردت أمينة على رسالتك';
	@override String get activiteRemplacant => 'اختيار المعلم البديل ليوم الثلاثاء لفصل النور';
	@override String get objetRemplacement => 'البديل ليوم الثلاثاء';
	@override String get activiteOuverture => 'المصادقة على فتح فصل صباح يوم السبت';
	@override String get objetClasseSamedi => 'فصل صباح يوم السبت';
	@override String get activiteCloture => 'إقفال شهر سبتمبر';
	@override String get objetCloture => 'إقفال سبتمبر';
	@override String get activiteBilans => 'تقييمات منتصف الفصل للمراجعة';
	@override String get objetBilans => 'تقييمات منتصف الفصل';
	@override String get activiteMessages => 'رسالتان جديدتان';
	@override String get activiteAnnonce => 'نُشر إعلان: الأكاديمية مغلقة يوم 1 نوفمبر';
	@override String get objetFermeture => 'الإغلاق يوم 1 نوفمبر';
	@override String activiteFichier({required Object nom, required Object fichier}) => '${nom} شاركت ${fichier}';
	@override String get activiteInscription => 'وصل طلب تسجيل جديد';
	@override String get objetDossierBenali => 'ملف أسرة بن علي';
}

// Path: com.annonces.publieur.etapes
class _Traductions$com$annonces$publieur$etapes$ar extends Traductions$com$annonces$publieur$etapes$fr {
	_Traductions$com$annonces$publieur$etapes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get contenu => 'محتوى الإعلان';
	@override String get audience => 'مستلمو الإعلان';
	@override String get programmation => 'تاريخ النشر';
	@override String get previsualisation => 'معاينة الإعلان';
	@override String get publication => 'نشر الإعلان';
}

// Path: com.annonces.publieur.contexte
class _Traductions$com$annonces$publieur$contexte$ar extends Traductions$com$annonces$publieur$contexte$fr {
	_Traductions$com$annonces$publieur$contexte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get contenu => 'اكتب ما يجب أن يعرفه المستلمون. الإعلان في اتجاه واحد: لا أحد يرد عليه.';
	@override String get audience => 'اختر من يستلم الإعلان. لا يُعرض إلا المستلمون الذين يمكنك النشر لهم.';
	@override String audienceFixee({required Object cible}) => 'يُرسل هذا الإعلان إلى ${cible}. أنت تنشر لفصلك فقط.';
	@override String get programmation => 'اختر متى يُرسل الإعلان. الإعلان المجدول ينتظر تاريخه.';
	@override String get previsualisation => 'هذا هو الإعلان كما سيقرؤه المستلمون.';
	@override String get publication => 'راجع المستلمين والتاريخ، ثم انشر. لا يُنشر شيء قبل التأكيد.';
}

// Path: com.annonces.publieur.nature
class _Traductions$com$annonces$publieur$nature$ar extends Traductions$com$annonces$publieur$nature$fr {
	_Traductions$com$annonces$publieur$nature$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get classe => 'تستلمه أسر هذا الفصل وطلابه فقط.';
	@override String get public => 'يستلمه كل أفراد هذا الجمهور.';
	@override String get toutes => 'تستلمه الأكاديمية كلها. خصصه لما يهم الجميع.';
}

// Path: com.annonces.publieur.quand
class _Traductions$com$annonces$publieur$quand$ar extends Traductions$com$annonces$publieur$quand$fr {
	_Traductions$com$annonces$publieur$quand$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get maintenant => 'فور التأكيد';
	@override String get maintenantDetail => 'يُرسل الإعلان فور تأكيد النشر.';
	@override String creneau({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}';
	@override String get creneauDetail => 'ينتظر الإعلان هذا التاريخ. ستجده في الإعلانات المجدولة.';
}

// Path: com.annonces.publieur.apercu
class _Traductions$com$annonces$publieur$apercu$ar extends Traductions$com$annonces$publieur$apercu$fr {
	_Traductions$com$annonces$publieur$apercu$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String a({required Object cible}) => 'إلى: ${cible}';
	@override String get diffusionMaintenant => 'النشر: فور التأكيد';
	@override String diffusionLe({required Object date, required Object heure}) => 'النشر المقرر يوم ${date} الساعة ${heure}';
}

// Path: com.annonces.administration.indicateurs
class _Traductions$com$annonces$administration$indicateurs$ar extends Traductions$com$annonces$administration$indicateurs$fr {
	_Traductions$com$annonces$administration$indicateurs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مؤشرات التواصل';
	@override String get publiees => 'الإعلانات المنشورة';
	@override String get planifiees => 'الإعلانات المجدولة';
	@override String get moderation => 'محتويات قيد الإشراف';
	@override String get regles => 'صلاحيات النشر';
	@override String indisponible({required Object libelle}) => '${libelle}: غير متاح بعد';
	@override String echec({required Object libelle}) => '${libelle}: لم يُحمَّل. تحقّق من الاتصال ثم أعد تحميل الصفحة.';
	@override String reserve({required Object libelle}) => '${libelle}: خاص بالمكلفين بالإشراف';
}

// Path: com.annonces.administration.publiees
class _Traductions$com$annonces$administration$publiees$ar extends Traductions$com$annonces$administration$publiees$fr {
	_Traductions$com$annonces$administration$publiees$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإعلانات المنشورة';
	@override String get vide => 'لا توجد إعلانات منشورة في هذه الفترة.';
	@override String get pastille => 'منشور';
	@override String legende({required Object cible, required Object date, required Object heure}) => '${cible} · يوم ${date} الساعة ${heure}';
}

// Path: com.annonces.administration.planifiees
class _Traductions$com$annonces$administration$planifiees$ar extends Traductions$com$annonces$administration$planifiees$fr {
	_Traductions$com$annonces$administration$planifiees$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإعلانات المجدولة';
	@override String get vide => 'لا توجد إعلانات مجدولة.';
	@override String get pastille => 'مجدول';
	@override String legende({required Object cible, required Object date, required Object heure}) => '${cible} · مقرر يوم ${date} الساعة ${heure}';
}

// Path: com.annonces.administration.matrice
class _Traductions$com$annonces$administration$matrice$ar extends Traductions$com$annonces$administration$matrice$fr {
	_Traductions$com$annonces$administration$matrice$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'صلاحيات نشر الإعلانات';
	@override String get detail => 'قاعدة الأكاديمية، تُطبَّق على كل عملية نشر.';
	@override String get auteurs => 'من ينشر';
	@override String get peutPublier => 'يمكنه النشر';
	@override String get audiences => 'المستلمون';
	@override String get validation => 'يتطلب موافقة';
	@override String get oui => 'نعم';
	@override String get non => 'لا';
	@override String get aucune => 'لا شيء';
	@override String get vide => 'لم تُضبط أي صلاحية نشر.';
}

// Path: com.annonces.administration.moderation
class _Traductions$com$annonces$administration$moderation$ar extends Traductions$com$annonces$administration$moderation$fr {
	_Traductions$com$annonces$administration$moderation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'قائمة الإشراف';
	@override String legende({required Object date, required Object heure}) => 'أُبلغ عنه يوم ${date} الساعة ${heure}';
	@override String motif({required Object motif}) => 'السبب: ${motif}';
	@override String get extraitTitre => 'المحتوى المُبلغ عنه';
	@override String get extraitAbsent => 'مقتطف هذا المحتوى غير متاح.';
	@override String get regle => 'القاعدة المعنية';
	@override String get approuver => 'الموافقة بعد الفحص';
	@override String get masquer => 'إخفاء المحتوى';
	@override String get restaurer => 'استعادة المحتوى';
	@override String get rejeter => 'رفض البلاغ';
	@override String get contexte => 'فتح السياق';
	@override String get masque => 'مخفي';
	@override String get approuve => 'تمت الموافقة';
	@override String get rejete => 'رُفض البلاغ';
	@override String get restaure => 'مستعاد';
	@override String get enregistree => 'سُجل القرار.';
	@override String get nonConfirmee => 'لم يُؤكَّد هذا القرار بعد. تحقق من الاتصال ثم أعد المحاولة.';
	@override String get horsLigne => 'أنت غير متصل. لا يمكن تحديث قائمة الإشراف.';
	@override String get indisponible => 'الإشراف غير متاح بعد. عد لاحقًا.';
	@override String get videTitre => 'لا يوجد محتوى للفحص';
	@override String get vide => 'تصل هنا بلاغات مجتمع المعلمين.';
	@override String get refuseTitre => 'قائمة خاصة بالإشراف';
	@override String get refuse => 'لا يرى هذه القائمة إلا المكلفون بالإشراف.';
	@override String get choisirTitre => 'لا يوجد بلاغ مفتوح';
	@override String get choisir => 'اختر بلاغًا من القائمة لفحصه.';
	@override String get sansAction => 'لا يتاح لك أي إجراء إشراف على هذا المحتوى.';
	@override String get sansSanction => 'لا تُطبق أي عقوبة على الحساب تلقائيًا.';
	@override String get politique => 'سياسة منع الترويج';
	@override String ouvrirSemantique({required Object objet, required Object motif}) => 'فحص ${objet}‏، السبب ${motif}';
	@override late final _Traductions$com$annonces$administration$moderation$regleMotif$ar regleMotif = _Traductions$com$annonces$administration$moderation$regleMotif$ar._(_root);
	@override late final _Traductions$com$annonces$administration$moderation$regles$ar regles = _Traductions$com$annonces$administration$moderation$regles$ar._(_root);
}

// Path: com.annonces.demo.roles
class _Traductions$com$annonces$demo$roles$ar extends Traductions$com$annonces$demo$roles$fr {
	_Traductions$com$annonces$demo$roles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tuteur => 'الأسرة';
	@override String get enseignant => 'المعلم';
	@override String get adulte => 'الطالب البالغ';
	@override String get admin => 'الإدارة';
	@override String get controleur => 'المراقب';
}

// Path: com.annonces.demo.f
class _Traductions$com$annonces$demo$f$ar extends Traductions$com$annonces$demo$f$fr {
	_Traductions$com$annonces$demo$f$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get adminStudioMention => 'الاستوديو: نقاش في قناة البرامج يشير إليك';
	@override String get adminStudioReponse => 'الاستوديو: رد جديد على رسالتك بشأن برنامج الربيع';
	@override String get adminStudioDecision => 'الاستوديو: مطلوب قرار بشأن مادة الدرس 4';
	@override String get adminStudioAssigne => 'الاستوديو: أُسندت إليك مراجعة مادة التجويد';
	@override String get adminStudioInterne => 'إعلان داخلي لفريق الاستوديو: اجتماع الفريق يوم الخميس الساعة 18';
	@override String get adminStudioContexte => 'الاستوديو: مادة جاهزة لفصل النور';
	@override String get annonceNourTitre => 'تلاوة نهاية الفصل الدراسي أمام الأسر';
	@override String get annonceNourTexte => 'أسرنا الكريمة، سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت 14 ديسمبر الساعة 10، عبر الاتصال المرئي. سيتلو كل طالب السورة التي عمل عليها خلال هذا الفصل الدراسي. يرجى تجهيز اتصال مستقر ومكان هادئ. يمكن للطلاب الراغبين التدرب خلال حصة الأربعاء السابقة. يمكن للأسر الحضور بصمت مع كتم الميكروفون. سيُشارك تقرير بعد الحصة.';
	@override String get annonceFajrTitre => 'مراجعة قبل تقييم يوم الخميس';
	@override String get annonceFajrTexte => 'راجعوا الآيات العشر الأخيرة من سورة الملك قبل يوم الخميس.';
	@override String get tuteurUrgent => 'حصة هذا المساء ملغاة';
	@override String get tuteurUrgentTexte => 'المعلمة غائبة هذا المساء. أُجّلت الحصة إلى يوم الخميس في الوقت نفسه. لا شيء عليك فعله.';
	@override String get tuteurReponse => 'رد منتظر: الموافقة على تلاوة ياسمين';
	@override String get tuteurReponseTexte => 'تنتظر المعلمة موافقتك لتتلو ياسمين أمام الأسر. أجبها من فضاء الفصل.';
	@override String get tuteurMessage => 'رسالة جديدة من معلمة فصل النور';
	@override String get tuteurDossier => 'تم قبول ملف التسجيل الخاص بك';
	@override String get adulteSeance => 'نُقلت حصتك يوم الثلاثاء إلى الساعة 19';
	@override String get adulteMessage => 'رسالة جديدة من معلمتك';
	@override String get enseignantFamille => 'رسالة من أسرة ياسمين، فصل النور';
	@override String get enseignantDirection => 'إعلان من الإدارة: جدول عطلة الشتاء';
	@override String get enseignantDirectionTexte => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.';
	@override String get enseignantPlanning => 'تغيّر جدولك للأسبوع القادم';
	@override String get enseignantMention => 'منشور في مجتمع المعلمين يشير إليك';
	@override String get enseignantReponse => 'رد جديد على منشورك';
	@override String get enseignantAdministration => 'رسالة من الإدارة: وثائق مطلوبة';
	@override String get adminDossiers => 'ثلاثة ملفات تسجيل في انتظار المعالجة';
	@override String get adminSignalement => 'تم الإبلاغ عن منشور في مجتمع المعلمين';
	@override String get adminReponse => 'رد أسرة بلال على رسالتك';
	@override String get adminPlanifiee => 'إعلان مجدول يحتاج إلى مراجعة قبل النشر';
	@override String get adminOperationnel => 'فصل النور: العدد مكتمل';
	@override String get controleurMission => 'مهمة جديدة: زيارة فصل النور';
	@override String get controleurChangement => 'نُقلت مهمتك يوم الخميس إلى الساعة 18';
	@override String get controleurReponse => 'رد الإدارة على تقريرك';
}

// Path: com.annonces.administration.moderation.regleMotif
class _Traductions$com$annonces$administration$moderation$regleMotif$ar extends Traductions$com$annonces$administration$moderation$regleMotif$fr {
	_Traductions$com$annonces$administration$moderation$regleMotif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get publicite => 'الإعلانات التجارية غير مسموح بها في مجتمع المعلّمين.';
	@override String get lienAffilie => 'روابط التسويق بالعمولة غير مسموح بها في مجتمع المعلّمين.';
	@override String get vente => 'بيع المنتجات أو الخدمات غير مسموح به في هذه المساحة.';
	@override String get sollicitation => 'الاستدراج التجاري غير مسموح به في هذه المساحة.';
}

// Path: com.annonces.administration.moderation.regles
class _Traductions$com$annonces$administration$moderation$regles$ar extends Traductions$com$annonces$administration$moderation$regles$fr {
	_Traductions$com$annonces$administration$moderation$regles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مشاركة تعليمية فقط';
	@override String get corps => 'مجتمع المعلّمين مخصّص للتبادل المهني بين المعلّمين.';
	@override String get reglesTitre => 'قواعد النشر';
	@override String get pasPublicite => 'لا إعلانات';
	@override String get pasAffilie => 'لا روابط تسويق بالعمولة';
	@override String get pasVente => 'لا بيع لمنتج أو خدمة';
	@override String get pasSollicitation => 'لا التماس تجاري';
	@override String get pasDonnees => 'لا بيانات شخصية لطالب أو عائلة';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TraductionsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'notifications.titre' => 'الإشعارات',
			'notifications.indisponibleTitre' => 'الإشعارات غير متاحة بعد',
			'notifications.indisponiblePhrase' => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية بمجرد تفعيلها.',
			'notifications.videTitre' => 'لا توجد إشعارات',
			'notifications.videPhrase' => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية.',
			'notifications.ligne' => ({required Object titre, required Object date, required Object heure}) => '${titre}‏، يوم ${date} الساعة ${heure}',
			'notifications.filtres.libelle' => 'تصفية الإشعارات',
			'notifications.filtres.toutes' => 'الكل',
			'notifications.filtres.nonLues' => 'غير المقروءة',
			'notifications.filtres.mentions' => 'الإشارات',
			'notifications.filtres.actionRequise' => 'إجراء مطلوب',
			'notifications.filtreVideTitre' => 'لا توجد إشعارات في هذا التصنيف',
			'notifications.filtreVidePhrase' => 'اختر »الكل« لرؤية جميع إشعاراتك من جديد.',
			'notifications.voirToutes' => 'عرض كل الإشعارات',
			'notifications.nonLue' => 'غير مقروء',
			'notifications.nonLueSemantique' => 'غير مقروء',
			'notifications.lectureNonConfirmee' => 'لم تُؤكَّد القراءة بعد. أعد المحاولة بعد قليل.',
			'notifications.detail.choisirTitre' => 'اختر إشعارًا',
			'notifications.detail.choisirPhrase' => 'تظهر تفاصيله هنا، بجانب القائمة.',
			'notifications.detail.recue' => ({required Object date, required Object heure}) => 'وصل يوم ${date} الساعة ${heure}',
			'notifications.detail.ouvrir' => 'فتح الصفحة المعنية',
			'notifications.types.annonceClasse' => 'إعلان الفصل',
			'notifications.types.changementSeance' => 'تغيير في الحصة',
			'notifications.types.decisionDossier' => 'قرار بشأن ملف',
			'notifications.types.messageMetier' => 'رسالة',
			'notifications.types.reponseAttendue' => 'رد منتظر',
			'notifications.types.accesFinance' => 'الوصول والمدفوعات',
			'notifications.types.observation' => 'ملاحظة',
			'notifications.types.travailRessource' => 'واجب أو مورد',
			'notifications.types.annonceDirection' => 'إعلان من الإدارة',
			'notifications.types.changementPlanning' => 'تغيير في الجدول',
			'notifications.types.remplacement' => 'استخلاف',
			'notifications.types.mentionCommunaute' => 'إشارة في مجتمع المعلمين',
			'notifications.types.reponseCommunaute' => 'رد في مجتمع المعلمين',
			'notifications.types.messageAdministration' => 'رسالة من الإدارة',
			'notifications.types.dossierATraiter' => 'ملف للمعالجة',
			'notifications.types.signalementCommunaute' => 'بلاغ في مجتمع المعلمين',
			'notifications.types.reponseFil' => 'رد في محادثة',
			'notifications.types.annoncePlanifiee' => 'إعلان مجدول للنشر',
			'notifications.types.evenementOperationnel' => 'حدث في الأكاديمية',
			'notifications.types.mission' => 'مهمة',
			'notifications.types.changementMission' => 'تغيير في المهمة',
			'notifications.types.reponseAdministration' => 'رد من الإدارة',
			'notifications.types.mentionStudio' => 'إشارة في الاستوديو',
			'notifications.types.reponseStudio' => 'رد في الاستوديو',
			'notifications.types.decisionDemandee' => 'قرار مطلوب',
			'notifications.types.elementAssigne' => 'عنصر مُسند',
			'notifications.types.annonceInterne' => 'إعلان داخلي',
			'notifications.types.evenementContextuel' => 'حدث',
			'notifications.types.autre' => 'إشعار',
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
			'historique.dateCourte' => ({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}',
			'historique.dateCourteSansAnnee' => ({required Object jour, required Object mois}) => '${jour} ${mois}',
			'historique.dateLongue' => ({required Object jourSemaine, required Object jour, required Object mois, required Object annee}) => '${jourSemaine} ${jour} ${mois} ${annee}',
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
			'commun.recherche.effacer' => 'مسح البحث',
			'commun.recherche.fermer' => 'إغلاق البحث',
			'commun.sections.page' => 'أقسام الصفحة',
			'etat.enDirect' => 'مباشر',
			'etat.seanceAnnulee' => 'ملغاة',
			'etat.annuleeValeur' => ({required Object valeur}) => 'ملغاة: ${valeur}',
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
			'classe.entree.accesInverifiable' => 'لا يمكن التحقق من الدخول إلى القاعة حاليًا.',
			'classe.entree.reessayer' => 'إعادة المحاولة',
			'classe.entree.chargementSeance' => 'جارٍ تحميل الحصة القادمة.',
			'classe.entree.progressionValeur' => ({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage} %',
			'classe.entree.dst' => ({required Object avant, required Object apres}) => 'تغيير التوقيت: سينتقل الدرس من ${avant} إلى ${apres}.',
			'classe.entree.annonce.aVenir' => 'حصة قادمة',
			'classe.entree.annonce.fenetreOuverte' => 'القاعة مفتوحة',
			'classe.entree.annonce.attente' => 'أنت في القاعة',
			'classe.catalogue' => 'اختيار فصل',
			'classe.planning' => 'الجدول',
			'classe.travail' => 'قبل الدرس القادم',
			'classe.ressources' => 'المكتبة',
			'classe.progression' => 'التقدم',
			'classe.observer' => 'متابعة الحصة',
			'classe.titre' => 'الفصل',
			'classe.historique' => 'السجل',
			'classe.sousTitre' => ({required Object prenom, required Object enseignant}) => '${prenom} · ${enseignant}',
			'classe.indisponiblePhrase' => 'تفاصيل الفصل غير متاحة هنا بعد.',
			'classe.introuvableTitre' => 'هذا الفصل غير متاح لهذا الملف',
			'classe.introuvablePhrase' => 'ربما انتهى، أو يخص طالبًا آخر من الأسرة.',
			'classe.seance.aucune' => 'لا توجد حصة مجدولة',
			'classe.seance.aucuneDetail' => ({required Object prenom}) => 'ستظهر هنا الحصة القادمة لـ${prenom} بمجرد جدولتها.',
			'classe.seance.illisible' => 'تعذّرت قراءة الحصة القادمة.',
			'classe.seance.presence' => ({required Object prenom, required Object etat}) => '${prenom}: ${etat}',
			'classe.observation.commentCaMarche' => 'كيف تعمل؟',
			'classe.observation.uneVisite' => 'زيارة واحدة متاحة',
			'classe.observation.visites' => ({required Object nombre}) => 'الزيارات المتاحة: ${nombre}',
			'classe.observation.resume' => ({required Object visites, required Object duree}) => '${visites} · ${duree} لكل زيارة',
			'classe.observation.restanteAucune' => 'لا زيارات متبقية لهذه الحصة',
			'classe.observation.restanteUne' => 'زيارة واحدة متبقية لهذه الحصة',
			'classe.observation.restantes' => ({required Object nombre}) => 'الزيارات المتبقية لهذه الحصة: ${nombre}',
			'classe.observation.minutes' => ({required Object minutes}) => '${minutes} د',
			'classe.observation.minutesSecondes' => ({required Object minutes, required Object secondes}) => '${minutes} د ${secondes} ث',
			'classe.observation.secondes' => ({required Object secondes}) => '${secondes} ث',
			'classe.observation.motif.visitesEpuisees' => 'استخدمت زياراتك لهذه الحصة.',
			'classe.observation.motif.tempsEpuise' => 'انتهى وقت المتابعة المخصص لك في هذه الحصة.',
			'classe.observation.motif.seanceNonCommencee' => 'تُفتح المتابعة عند بدء الحصة.',
			'classe.observation.motif.seanceTerminee' => 'انتهت الحصة.',
			'classe.observation.motif.seanceNonTenue' => 'هذه الحصة لن تُعقد، فلا شيء للمتابعة.',
			'classe.observation.motif.horsFenetre' => 'القاعة غير مفتوحة في هذا الوقت.',
			'classe.observation.motif.observationDesactivee' => 'المتابعة مغلقة لهذا الفصل.',
			'classe.observation.motif.lienAbsent' => 'لا يوجد طالب من أسرتك مرتبط بهذه الحصة.',
			'classe.observation.motif.enfantAbsent' => ({required Object prenom}) => 'تنتظر المتابعة وصول ${prenom}.',
			'classe.observation.motif.presenceEnVerification' => ({required Object prenom}) => 'يجري التحقق من حضور ${prenom}.',
			'classe.observation.motif.visiteDejaOuverte' => 'توجد زيارة مفتوحة بالفعل، على هذا الجهاز أو على جهاز آخر.',
			'classe.observation.motif.garantieServeurAbsente' => 'متابعة الحصص غير مفتوحة بعد.',
			'classe.observation.motif.reseau' => 'تعذّر التحقق من إتاحة المتابعة.',
			'classe.observation.motif.capaciteAbsente' => 'المتابعة غير متاحة حاليًا.',
			'classe.pagePlanning.prochaines' => 'الحصص القادمة',
			'classe.pagePlanning.ligne' => ({required Object heure, required Object duree}) => '${heure} · ${duree}',
			'classe.pagePlanning.ligneFuseau' => ({required Object heure, required Object fuseau, required Object duree}) => '${heure} (${fuseau}) · ${duree}',
			'classe.pagePlanning.aucune' => 'لا توجد حصص قادمة حاليًا',
			'classe.pagePlanning.aucuneDetail' => ({required Object prenom}) => 'ستظهر هنا الحصص القادمة لـ${prenom} بمجرد جدولتها.',
			'classe.pagePlanning.habituelIndisponible' => 'الأيام المعتادة للفصل لا تظهر هنا بعد: تظهر فقط الحصص المجدولة.',
			'classe.pagePlanning.indisponible' => 'جدول الفصل غير مربوط بهذه المساحة بعد.',
			'classe.pageTravail.aucun' => 'لا شيء للتحضير حاليًا',
			'classe.pageTravail.aucunDetail' => 'سيظهر هنا العمل الذي يكلّف به المعلم.',
			'classe.pageTravail.indisponible' => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.',
			'classe.pageTravail.echeance' => ({required Object date}) => 'الموعد النهائي: ${date}',
			'classe.pageTravail.nonCochable' => 'لا يمكن بعد تحديد عمل على أنه منجز من هنا.',
			'classe.pageTravail.statut.aFaire' => 'للإنجاز',
			'classe.pageTravail.statut.enCours' => 'بدأ',
			'classe.pageTravail.statut.fait' => 'منجز',
			'classe.pageTravail.statut.expire' => 'فات الموعد',
			'classe.pageRessources.aucune' => 'لا توجد موارد لهذا الفصل حاليًا',
			'classe.pageRessources.aucuneDetail' => 'ستظهر هنا المواد التي يختارها المعلم.',
			'classe.pageRessources.indisponible' => 'مكتبة الفصل غير مربوطة بهذه المساحة بعد.',
			'classe.pageProgression.indisponible' => ({required Object prenom}) => 'تقدم ${prenom} غير مُشارك هنا بعد.',
			'classe.pageProgression.niveau' => 'المستوى',
			'classe.pageProgression.jalons' => 'المراحل المنجزة',
			'classe.pageProgression.aucune' => 'لا توجد مراحل مُشاركة حاليًا',
			'classe.pageProgression.aucuneDetail' => 'سيظهر هنا التقدم الذي يشاركه المعلم مع الأسرة.',
			'classe.pageCatalogue.pour' => ({required Object prenom}) => 'لـ${prenom}',
			'classe.pageCatalogue.proposees' => 'الفصول المقترحة',
			'classe.pageCatalogue.indisponible' => 'اختيار الفصل عبر الإنترنت غير مفتوح بعد.',
			'classe.pageCatalogue.aucune' => 'لا يوجد فصل مناسب حاليًا',
			'classe.pageCatalogue.aucuneDetail' => ({required Object prenom}) => 'لا يوجد فصل مفتوح يناسب ملف ${prenom} في الوقت الحالي.',
			'classe.pageCatalogue.eleveInconnuTitre' => 'هذا الملف ليس ضمن أسرتك',
			'classe.pageCatalogue.eleveInconnuPhrase' => 'عد إلى الصفحة الرئيسية واختر ملف الطالب المعني.',
			'classe.pageCatalogue.horairesAbsents' => 'أيام هذا الفصل ومواعيده لا تظهر هنا بعد.',
			'classe.pageCatalogue.seanceHebdo' => ({required Object jour, required Object heure, required Object duree}) => '${jour} الساعة ${heure} · ${duree} د',
			'classe.pageCatalogue.fuseauClasse' => ({required Object fuseau}) => 'مواعيد الفصل (${fuseau})',
			'classe.pageCatalogue.placeUne' => 'مقعد واحد متبقٍّ',
			'classe.pageCatalogue.places' => ({required Object nombre}) => 'المقاعد المتبقية: ${nombre}',
			'classe.pageCatalogue.etat.ouverte' => 'مفتوح',
			'classe.pageCatalogue.etat.complete' => 'مكتمل',
			'classe.pageCatalogue.etat.listeAttente' => 'قائمة الانتظار',
			'classe.pageCatalogue.choisir' => 'اختيار هذا الفصل',
			'classe.pageCatalogue.rejoindreAttente' => 'الانضمام إلى قائمة الانتظار',
			'classe.pageCatalogue.precisionsTitre' => 'قبل الاختيار',
			'classe.pageCatalogue.precisionEnseignant' => 'يحتفظ الفصل بالمعلم نفسه في كل حصصه.',
			'classe.pageCatalogue.precisionPlaces' => 'المقاعد المعروضة هي مقاعد الأكاديمية لحظة القراءة.',
			'classe.pageCatalogue.precisionReserve' => 'لا يُحجز شيء قبل تأكيدك.',
			'classe.pageCatalogue.confirmerTitre' => 'تأكيد الفصل',
			'classe.pageCatalogue.confirmerPhrase' => ({required Object prenom}) => 'أنت تسجّل ${prenom} في هذا الفصل.',
			'classe.pageCatalogue.confirmerAttentePhrase' => ({required Object prenom}) => 'أنت تسجّل ${prenom} في قائمة انتظار هذا الفصل.',
			'classe.pageCatalogue.memeEnseignant' => ({required Object enseignant}) => 'الفصل نفسه والمعلم نفسه في كل حصص الأسبوع: ${enseignant}.',
			'classe.pageCatalogue.confirmer' => 'تأكيد التسجيل',
			'classe.pageCatalogue.confirmerAttente' => 'تأكيد قائمة الانتظار',
			'classe.pageCatalogue.envoiIncertain' => 'لم يصل رد الأكاديمية. إعادة المحاولة لا تنشئ تسجيلًا ثانيًا.',
			'classe.pageCatalogue.envoiIndisponible' => 'التسجيل عبر الإنترنت غير مفتوح بعد: لم يُحجز أي مقعد.',
			'classe.pageCatalogue.resultat.inscritTitre' => 'تم تأكيد التسجيل',
			'classe.pageCatalogue.resultat.inscritPhrase' => ({required Object prenom, required Object classe}) => 'انضم ${prenom} إلى ${classe}.',
			'classe.pageCatalogue.resultat.voirClasse' => 'عرض الفصل',
			'classe.pageCatalogue.resultat.validationTitre' => 'تم إرسال الطلب',
			'classe.pageCatalogue.resultat.validationPhrase' => ({required Object prenom, required Object classe}) => 'ما زال على الأكاديمية اعتماد تسجيل ${prenom} في ${classe}.',
			'classe.pageCatalogue.resultat.listeAttenteTitre' => 'التسجيل في قائمة الانتظار',
			'classe.pageCatalogue.resultat.listeAttentePhrase' => ({required Object prenom, required Object classe}) => '${prenom} في قائمة انتظار ${classe}. لم يُحجز أي مقعد حاليًا.',
			'classe.pageCatalogue.resultat.refuseTitre' => 'لم يُقبل التسجيل',
			'classe.pageCatalogue.resultat.refusePhrase' => ({required Object prenom}) => 'لم يُحجز أي مقعد لـ${prenom}. يمكنك اختيار فصل آخر.',
			'classe.pageCatalogue.resultat.autresClasses' => 'عرض الفصول الأخرى',
			'classe.pageCatalogue.resultat.retourAccueil' => 'العودة إلى الصفحة الرئيسية',
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
			'tuteur.accueil.prochaineSeance' => 'الحصة القادمة',
			'tuteur.accueil.heureDe' => ({required Object ville}) => 'توقيت ${ville}',
			'tuteur.accueil.heureAppareil' => 'توقيت هذا الجهاز',
			'tuteur.accueil.heureClasse' => ({required Object heure, required Object ville}) => 'توقيت الفصل: ${heure} ${ville}',
			'tuteur.accueil.seanceEnDirect' => 'الحصة مباشرة',
			'tuteur.accueil.seanceTerminee' => 'انتهت الحصة',
			'tuteur.accueil.seanceAnnulee' => 'لن تُعقد هذه الحصة.',
			'tuteur.accueil.seanceNonTenue' => 'تعذّر عقد هذه الحصة.',
			'tuteur.accueil.horaireIncertain' => 'لم يُؤكَّد فتح القاعة بعد',
			'tuteur.accueil.pastilleAnnulee' => 'ملغاة',
			'tuteur.accueil.pastilleNonTenue' => 'لم تُعقد',
			'tuteur.accueil.pastilleTerminee' => 'منتهية',
			'tuteur.accueil.etatCourt.enDirect' => 'مباشر',
			'tuteur.accueil.etatCourt.salleOuverte' => 'القاعة مفتوحة',
			'tuteur.accueil.etatCourt.dansMinutes' => ({required Object minutes}) => 'بعد ${minutes} د',
			'tuteur.accueil.etatCourt.dansHeures' => ({required Object heures, required Object minutes}) => 'بعد ${heures} س ${minutes} د',
			'tuteur.accueil.etatCourt.dansJours' => ({required Object jours}) => 'بعد ${jours} يوم',
			'tuteur.accueil.etatCourt.prevue' => 'حصة مقررة',
			'tuteur.accueil.etatCourt.annulee' => 'حصة ملغاة',
			'tuteur.accueil.etatCourt.nonTenue' => 'حصة لم تُعقد',
			'tuteur.accueil.etatCourt.terminee' => 'حصة منتهية',
			'tuteur.accueil.etatCourt.aucune' => 'لا توجد حصة',
			'tuteur.accueil.etatCourt.illisible' => 'غير متاح',
			'tuteur.accueil.motifAnnuleeTard' => 'أُلغيت الحصة قبل موعدها بقليل',
			'nav.eleve.accueil' => 'الرئيسية',
			'nav.eleve.maClasse' => 'فصلي',
			'nav.eleve.coran' => 'القرآن',
			'nav.eleve.monEspace' => 'مساحتي',
			'nav.eleve.suivi' => 'المتابعة',
			'nav.eleve.compte' => 'الحساب',
			'nav.tuteur.accueil' => 'الرئيسية',
			'nav.tuteur.foyer' => 'الأسرة',
			'nav.tuteur.disponibilites' => 'الأوقات المتاحة',
			'nav.tuteur.reglages' => 'الإعدادات',
			'nav.tuteur.suivi' => 'المتابعة',
			'nav.tuteur.historique' => 'السجل',
			'nav.tuteur.compte' => 'الحساب',
			'nav.enseignant.journee' => 'اليوم',
			'nav.enseignant.classes' => 'الفصول',
			'nav.enseignant.creneaux' => 'الأوقات المتاحة',
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
			'nav.admin.configuration' => 'الإعدادات',
			'nav.admin.securite' => 'الأمان والتدقيق',
			'nav.admin.direction' => 'الإدارة',
			'nav.admin.recherche' => 'البحث',
			'nav.admin.rechercheIndication' => 'البحث عن شاشة',
			'nav.admin.notificationsTitre' => 'الإشعارات',
			'nav.admin.menu' => 'القائمة',
			'nav.compte' => 'حسابي',
			'nav.principale' => 'التنقل الرئيسي',
			'nav.motSymbole' => 'Rewayah',
			'nav.replier' => 'طي التنقل',
			'nav.deplier' => 'توسيع التنقل',
			'tc.groupe.mesGroupes.titre' => 'فصولي',
			'tc.groupe.mesGroupes.aucun' => 'لا يوجد فصل حاليًا',
			'tc.groupe.mesGroupes.aucunDetail' => 'ستضعك الأكاديمية في فصل بمجرد توفر موعد يناسبك.',
			'tc.groupe.commun.erreur' => 'تعذّرت قراءة فصولك',
			'tc.groupe.commun.reessayer' => 'إعادة المحاولة',
			'tc.groupe.carte.ouvrir' => ({required Object libelle}) => 'فتح الفصل ${libelle}',
			'tc.groupe.carte.capacite' => ({required Object membres, required Object seuil}) => '${membres} / ${seuil}',
			'tc.groupe.carte.capacitePhrase' => ({required Object membres, required Object seuil}) => '${membres} طلاب من أصل ${seuil} مقاعد',
			'tc.groupe.carte.complet' => 'مكتمل',
			'tc.groupe.carte.prochainCours' => 'الدرس القادم',
			'tc.groupe.carte.aucuneSeance' => 'لا توجد حصة مجدولة',
			'tc.groupe.carte.aucuneSeanceDetail' => 'لم يُحدَّد جدول هذا الفصل بعد.',
			'tc.groupe.carte.duree' => ({required Object valeur}) => 'المدة ${valeur}',
			'tc.groupe.carte.dureeLibelle' => 'المدة',
			'tc.groupe.carte.rejoindre' => 'انضمام',
			'tc.groupe.enseignant.sayyid' => 'سيد',
			'tc.groupe.enseignant.sayyida' => 'سيدة',
			'tc.groupe.enseignant.photoManquante' => 'الصورة مطلوبة',
			'tc.groupe.enseignant.photoManquanteDetail' => 'لم تُسجَّل صورة المعلم بعد.',
			'tc.groupe.cours.coursEtNiveau' => ({required Object cours, required Object niveau}) => '${cours} · ${niveau}',
			'tc.groupe.temps.dansMinutes' => ({required Object minutes}) => 'الدرس بعد ${minutes} د',
			'tc.groupe.temps.dansHeures' => ({required Object heures, required Object minutes}) => 'الدرس بعد ${heures} س ${minutes} د',
			'tc.groupe.temps.imminent' => 'الدرس وشيك',
			'tc.groupe.temps.salleOuverte' => ({required Object reste}) => 'القاعة مفتوحة · ${reste}',
			'tc.groupe.temps.salleOuverteCourt' => 'القاعة مفتوحة',
			'tc.groupe.temps.attente' => 'أنت في القاعة. لم يبدأ الدرس بعد.',
			'tc.groupe.temps.attenteDetail' => 'وقت الانتظار هذا لا يُحتسب في حضورك.',
			'tc.groupe.temps.enSalle' => 'في القاعة',
			'tc.groupe.temps.resteMinutes' => ({required Object minutes}) => 'متبقٍّ ${minutes} د',
			'tc.groupe.temps.resteHeures' => ({required Object heures, required Object minutes}) => 'متبقٍّ ${heures} س ${minutes} د',
			'tc.groupe.temps.enCours' => ({required Object reste}) => 'الحصة مباشرة · ${reste}',
			'tc.groupe.temps.enDirect' => 'مباشر',
			'tc.groupe.temps.prolongee' => 'الحصة ما زالت مباشرة',
			'tc.groupe.temps.depassement' => 'تجاوز الوقت',
			'tc.groupe.temps.terminee' => 'انتهى الدرس',
			'tc.groupe.duree.minutes' => ({required Object minutes}) => '${minutes} د',
			'tc.groupe.duree.heures' => ({required Object heures}) => '${heures} س',
			'tc.groupe.duree.heuresMinutes' => ({required Object heures, required Object minutes}) => '${heures} س ${minutes} د',
			'tc.groupe.horloges.votreHeure' => 'توقيتك',
			'tc.groupe.horloges.chezEnseignant' => ({required Object nomme}) => 'توقيت ${nomme}',
			'tc.groupe.horloges.heureGroupe' => 'توقيت الفصل',
			'tc.groupe.horloges.heureEtVille' => ({required Object heure, required Object ville}) => '${heure} ${ville}',
			'tc.groupe.dst.j30' => 'تغيير التوقيت بعد شهر',
			'tc.groupe.dst.j7' => 'تغيير التوقيت الأسبوع القادم',
			'tc.groupe.dst.j1' => 'تغيير التوقيت غدًا',
			'tc.groupe.dst.detail' => ({required Object avant, required Object apres}) => 'سينتقل درسك من ${avant} إلى ${apres}.',
			'tc.groupe.session.conseilAppareil' => 'يُنصح بجهاز لوحي أو حاسوب للدرس. يبقى الهاتف مدعومًا.',
			'tc.groupe.espace.retour' => 'فصولي',
			'tc.groupe.espace.avantProchainCours' => 'قبل الدرس القادم',
			'tc.groupe.espace.aucuneAction' => 'لا شيء للتحضير حاليًا',
			'tc.groupe.espace.bibliotheque' => 'المكتبة',
			'tc.groupe.espace.bibliothequeVoirTout' => 'عرض الكل',
			'tc.groupe.espace.progression' => 'التقدم',
			'tc.groupe.espace.roster' => 'طلاب الفصل',
			'tc.groupe.espace.reprendreLeCours' => 'استئناف الدرس',
			'tc.groupe.espace.introuvable' => 'هذا الفصل غير متاح لك',
			'tc.groupe.espace.introuvableDetail' => 'ربما أُغلق، أو يخص ملفًا آخر.',
			'tc.groupe.emplacement.nonBranche' => 'متاح قريبًا',
			'tc.groupe.emplacement.nonBrancheDetail' => 'سيُربط هذا المحتوى بهذه المساحة قريبًا.',
			'tc.bibliotheque.sections.groupe' => 'المواد المعروضة',
			'com.socle.composants.lecture.pieceJointe' => ({required Object nom}) => 'مرفق: ${nom}',
			'com.socle.composants.lecture.vocal' => ({required Object duree}) => 'رسالة صوتية مدتها ${duree}',
			'com.socle.composants.lecture.vocalSansDuree' => 'رسالة صوتية',
			'com.socle.composants.lecture.horodatage' => ({required Object date, required Object heure}) => '${date} · ${heure}',
			'com.socle.composants.badge.nonLuUn' => '1 غير مقروء',
			'com.socle.composants.badge.nonLus' => ({required Object nombre}) => '${nombre} غير مقروءة',
			'com.socle.composants.badge.nonLusSemantique' => ({required Object nombre}) => '${nombre} عناصر غير مقروءة',
			'com.socle.composants.badge.nonLuUnSemantique' => 'عنصر واحد غير مقروء',
			'com.socle.composants.badge.information' => 'للعلم',
			'com.socle.composants.badge.aLire' => 'للقراءة',
			'com.socle.composants.badge.actionRequise' => _root.com.socle.lexique.actionRequise,
			'com.socle.composants.badge.urgent' => 'عاجل',
			'com.socle.composants.badge.mention' => 'إشارة',
			'com.socle.composants.badge.mentionSemantique' => 'هناك إشارة تخصّك',
			'com.socle.composants.pieceJointe.joindre' => 'إرفاق ملف',
			'com.socle.composants.pieceJointe.joindreIndisponible' => 'إرفاق الملفات غير متاح هنا بعد.',
			'com.socle.composants.pieceJointe.ouvrir' => 'فتح',
			'com.socle.composants.pieceJointe.ouvrirLecteur' => ({required Object nom}) => 'فتح ${nom}',
			'com.socle.composants.pieceJointe.retirer' => 'إزالة',
			'com.socle.composants.pieceJointe.retirerLecteur' => ({required Object nom}) => 'إزالة ${nom}',
			'com.socle.composants.pieceJointe.tailleOctets' => ({required Object taille}) => '${taille} بايت',
			'com.socle.composants.pieceJointe.tailleKo' => ({required Object taille}) => '${taille} كيلوبايت',
			'com.socle.composants.pieceJointe.tailleMo' => ({required Object taille}) => '${taille} ميغابايت',
			'com.socle.composants.pieceJointe.autorisee' => 'جاهز للإرسال',
			'com.socle.composants.pieceJointe.tropVolumineuse' => 'الملف كبير جدًا',
			'com.socle.composants.pieceJointe.tropVolumineuseDetail' => 'هذا الملف يتجاوز الحجم المسموح به. اختر ملفًا أصغر.',
			'com.socle.composants.pieceJointe.typeInterdit' => 'نوع الملف مرفوض',
			'com.socle.composants.pieceJointe.typeInterditDetail' => 'هذا النوع من الملفات غير مقبول هنا. اختر صيغة أخرى.',
			'com.socle.composants.pieceJointe.enCours' => 'جارٍ الإرسال',
			'com.socle.composants.pieceJointe.envoyee' => 'أُرسل',
			'com.socle.composants.pieceJointe.echec' => 'لم يُؤكَّد',
			'com.socle.composants.pieceJointe.erreurEnvoi' => 'لم يُؤكَّد إرسال هذا الملف بعد. أعد المحاولة بعد قليل.',
			'com.socle.composants.pieceJointe.indisponible' => 'المرفق غير متاح',
			'com.socle.composants.pieceJointe.indisponibleDetail' => 'هذا الملف لم يعد متاحًا. اطلب من الشخص الذي شاركه أن يعيد إرساله.',
			'com.socle.composants.composer.message' => 'رسالة',
			'com.socle.composants.composer.aide' => 'اكتب رسالة',
			'com.socle.composants.composer.envoyer' => 'إرسال',
			'com.socle.composants.composer.champVide' => 'اكتب رسالة لإرسالها.',
			'com.socle.composants.composer.vocal' => 'رسالة صوتية',
			'com.socle.composants.composer.vocalAVenir' => 'الرسالة الصوتية متاحة قريبًا',
			'com.socle.composants.composer.enCours' => 'جارٍ الإرسال',
			'com.socle.composants.composer.envoye' => 'أُرسلت',
			'com.socle.composants.composer.nonConfirme' => 'لم يُؤكَّد إرسال هذه الرسالة بعد.',
			'com.socle.composants.composer.reessayer' => 'إعادة المحاولة',
			'com.socle.composants.composer.auteurSoi' => 'أنت',
			'com.socle.composants.composer.annonce' => ({required Object auteur, required Object texte}) => 'رسالة جديدة من ${auteur}: ${texte}',
			'com.socle.composants.composer.brouillon' => _root.com.socle.lexique.brouillon,
			'com.socle.composants.composer.brouillonRestaure' => 'تمت استعادة المسودة',
			'com.socle.composants.composer.enregistrerVocal' => _root.com.vocal.composer.enregistrer,
			'com.socle.composants.composer.aucunMessageTitre' => 'لا توجد رسائل حاليًا',
			'com.socle.composants.composer.aucunMessage' => 'اكتب أول رسالة في هذه المحادثة، وستظهر هنا.',
			'com.socle.composants.etats.chargement' => 'جارٍ التحميل',
			'com.socle.composants.etats.videTitre' => 'لا شيء هنا حاليًا',
			'com.socle.composants.etats.erreurTitre' => 'تعذّر تحميل هذا المحتوى.',
			'com.socle.composants.etats.erreur' => 'تحقّق من اتصالك ثم أعد المحاولة.',
			'com.socle.composants.etats.reessayer' => 'إعادة المحاولة',
			'com.socle.composants.etats.horsLigne' => 'أنت غير متصل. لا يمكن تحديث الرسائل الجديدة.',
			'com.socle.composants.etats.horsLigneBloc' => 'أعد المحاولة عند عودة الاتصال.',
			'com.socle.composants.etats.indisponibleTitre' => 'غير متاح بعد',
			'com.socle.composants.etats.indisponible' => 'هذه الميزة غير متاحة هنا بعد. ستُفتح حين تصبح الخدمة جاهزة.',
			'com.socle.composants.etats.permissionRefusee' => 'ليس لديك صلاحية الوصول إلى هذا المحتوى.',
			'com.socle.composants.espace.ouvrirPanneau' => 'فتح لوحة السياق',
			'com.socle.composants.espace.fermerPanneau' => 'إغلاق لوحة السياق',
			'com.socle.composants.espace.panneauContexte' => 'السياق',
			'com.socle.composants.espace.retourListe' => 'العودة إلى القائمة',
			'com.socle.lexique.messages' => 'الرسائل',
			'com.socle.lexique.messagesMetier' => 'رسائل العمل',
			'com.socle.lexique.communaute' => 'مجتمع المعلّمين',
			'com.socle.lexique.studio' => 'الاستوديو',
			'com.socle.lexique.aujourdhui' => 'اليوم',
			'com.socle.lexique.notifications' => 'الإشعارات',
			'com.socle.lexique.annonce' => 'إعلان',
			'com.socle.lexique.publication' => 'منشور',
			'com.socle.lexique.reponse' => 'رد',
			'com.socle.lexique.enregistrer' => 'حفظ',
			'com.socle.lexique.signaler' => 'إبلاغ',
			'com.socle.lexique.modeFocus' => 'وضع التركيز',
			'com.socle.lexique.quitterFocus' => 'الخروج من التركيز',
			'com.socle.lexique.aTraiter' => 'للمعالجة',
			'com.socle.lexique.actionRequise' => 'إجراء مطلوب',
			'com.socle.lexique.brouillon' => 'مسودة',
			'com.socle.lexique.elementsEpingles' => 'العناصر المثبّتة',
			'com.socle.lexique.fichiersPartages' => 'الملفات المشتركة',
			'com.socle.motifs.titre' => 'لماذا تبلّغ عن هذا المحتوى؟',
			'com.socle.motifs.publicite' => 'إعلان تجاري',
			'com.socle.motifs.lienAffilie' => 'رابط تسويق بالعمولة',
			'com.socle.motifs.venteNonAutorisee' => 'بيع غير مسموح به',
			'com.socle.motifs.sollicitationCommerciale' => 'استدراج تجاري',
			'com.socle.motifs.horsSujet' => 'محتوى لا علاقة له بالمجتمع',
			'com.socle.motifs.harcelement' => 'مضايقة أو لغة غير لائقة',
			'com.socle.motifs.donneesPersonnelles' => 'بيانات شخصية لطالب أو لعائلة',
			'com.socle.motifs.autre' => 'محتوى آخر يحتاج إلى فحص',
			'com.socle.signalement.titre' => 'الإبلاغ عن هذا المحتوى',
			'com.socle.signalement.precision' => 'توضيح اختياري',
			'com.socle.signalement.envoyer' => 'إرسال البلاغ',
			_ => null,
		} ?? switch (path) {
			'com.socle.signalement.confirme' => 'تم الإبلاغ عن المحتوى. ستتم مراجعته.',
			'com.socle.signalement.erreur' => 'لم يُؤكَّد البلاغ بعد. أعد المحاولة بعد قليل.',
			'com.socle.signalement.indisponible' => 'الإبلاغ غير متاح هنا بعد.',
			'com.socle.enregistrement.enregistrer' => _root.com.socle.lexique.enregistrer,
			'com.socle.enregistrement.retirer' => 'إزالة من العناصر المحفوظة',
			'com.socle.enregistrement.enregistre' => 'محفوظ',
			'com.socle.enregistrement.indisponible' => 'الحفظ غير متاح هنا بعد.',
			'com.socle.navigation.notifications' => _root.com.socle.lexique.notifications,
			'com.socle.navigation.ouvrirNotifications' => 'فتح الإشعارات',
			'com.socle.navigation.studio' => _root.com.socle.lexique.studio,
			'com.socle.navigation.ouvrirStudio' => 'فتح الاستوديو',
			'com.socle.navigation.quitterStudio' => 'الخروج من الاستوديو',
			'com.socle.navigation.messages' => _root.com.socle.lexique.messages,
			'com.socle.navigation.communaute' => _root.com.socle.lexique.communaute,
			'com.socle.navigation.communications' => 'الاتصالات',
			'com.socle.navigation.communicationsDetail' => 'الإعلانات والإشراف ورسائل الصفوف',
			'com.socle.navigation.ongletAnnonces' => 'الإعلانات',
			'com.socle.navigation.ongletModeration' => 'الإشراف',
			'com.socle.navigation.ongletMessages' => _root.com.socle.lexique.messages,
			'com.socle.navigation.bientot' => 'متاح قريبًا',
			'com.socle.navigation.provisoire.messagesTitre' => _root.com.socle.lexique.messages,
			'com.socle.navigation.provisoire.messagesDetail' => 'ستصل الرسائل المرتبطة بفصولك إلى هذه المساحة قريبًا.',
			'com.socle.navigation.provisoire.communauteTitre' => _root.com.socle.lexique.communaute,
			'com.socle.navigation.provisoire.communauteDetail' => 'ستصل مساحة التبادل بين المعلّمين إلى هنا قريبًا.',
			'com.socle.navigation.provisoire.studioTitre' => _root.com.socle.lexique.studio,
			'com.socle.navigation.provisoire.studioDetail' => 'ستصل مساحة عمل الفريق إلى هنا قريبًا.',
			'com.socle.navigation.provisoire.administrationTitre' => 'إدارة الاتصالات',
			'com.socle.navigation.provisoire.administrationDetail' => 'ستُدار الإعلانات والإشراف والرسائل من هنا قريبًا.',
			'com.socle.navigation.provisoire.publierAnnonceTitre' => 'نشر إعلان',
			'com.socle.navigation.provisoire.publierAnnonceDetail' => 'سيصل نشر إعلان لفصل ما إلى هنا قريبًا.',
			'com.socle.navigation.demo.titre' => 'عرض توضيحي للاتصالات',
			'com.socle.navigation.demo.detail' => 'بيانات وهمية، غير موجودة في نسخ الإنتاج.',
			'com.socle.navigation.demo.choisir' => 'اختر مساحة لتجربتها.',
			'com.messages.entree.titreClasse' => 'التواصل بشأن هذا الفصل',
			'com.messages.entree.titreDossier' => 'التواصل بشأن هذا الملف',
			'com.messages.entree.titreObjet' => 'التواصل بشأن هذا الموضوع',
			'com.messages.entree.ecrireFamille' => 'مراسلة الأسرة',
			'com.messages.entree.ecrireAdministration' => 'مراسلة الإدارة',
			'com.messages.entree.ecrireA' => ({required Object nom}) => 'مراسلة ${nom}',
			'com.messages.entree.conversationAvec' => ({required Object nom}) => 'محادثة مع ${nom}',
			'com.messages.entree.voirTout' => 'عرض كل المحادثات',
			'com.messages.entree.toutes' => 'كل محادثاتك',
			'com.messages.entree.aLireUne' => 'محادثة واحدة للقراءة',
			'com.messages.entree.aLire' => ({required Object nombre}) => '${nombre} محادثات للقراءة',
			'com.messages.entree.ouverture' => 'جارٍ فتح المحادثة',
			'com.messages.entree.inaccessibleTitre' => 'محادثة غير متاحة',
			'com.messages.entree.inaccessible' => 'لم تعد هذه المحادثة متاحة لك. اختر شخصًا آخر من القائمة.',
			'com.messages.entree.erreurOuvertureTitre' => 'تعذّر فتح هذه المحادثة.',
			'com.messages.entree.ouvertureEchouee' => 'تحقّق من اتصالك ثم أعد المحاولة.',
			'com.messages.videDetail' => 'تُفتح المحادثة من فصل أو طالب أو ملف.',
			'com.messages.choisirTitre' => 'اختر محادثة',
			'com.messages.choisir' => 'اختر محادثة من القائمة لقراءتها والرد عليها.',
			'com.messages.recherche.champ' => 'البحث عن محادثة',
			'com.messages.recherche.aide' => 'الاسم أو الفصل أو الملف',
			'com.messages.recherche.aucunTitre' => 'لم يتم العثور على أي محادثة',
			'com.messages.recherche.aucun' => ({required Object texte}) => 'لا توجد محادثة تطابق »${texte}«. جرّب اسمًا آخر أو فصلًا آخر.',
			'com.messages.recherche.resultatUn' => 'تم العثور على محادثة واحدة',
			'com.messages.recherche.resultats' => ({required Object nombre}) => 'تم العثور على ${nombre} محادثات',
			'com.messages.ligne.legende' => ({required Object objet, required Object apercu}) => '${objet} · ${apercu}',
			'com.messages.ligne.sansApercu' => 'لا توجد رسائل حاليًا',
			'com.messages.ligne.dateCourte' => ({required Object numero, required Object mois}) => '${numero} ${mois}',
			'com.messages.noms.avecFonction' => ({required Object nom, required Object fonction}) => '${nom} · ${fonction}',
			'com.messages.noms.deux' => ({required Object premier, required Object second}) => '${premier} و${second}',
			'com.messages.noms.plusieurs' => ({required Object premier, required Object nombre}) => '${premier} و${nombre} أشخاص آخرين',
			'com.messages.noms.surObjet' => ({required Object objet}) => 'محادثة بخصوص ${objet}',
			'com.messages.noms.sansObjet' => 'محادثة',
			'com.messages.entete.avecAttention' => ({required Object entete, required Object attention}) => '${entete}. ${attention}',
			'com.messages.entete.deuxObjets' => ({required Object premier, required Object second}) => '${premier} · ${second}',
			'com.messages.entete.semantique' => ({required Object noms, required Object objets}) => 'محادثة مع ${noms}‏، بخصوص ${objets}',
			'com.messages.entete.semantiqueSansNoms' => ({required Object objets}) => 'محادثة بخصوص ${objets}',
			'com.messages.types.classe' => 'الفصل',
			'com.messages.types.eleve' => 'الطالب',
			'com.messages.types.dossier' => 'الملف',
			'com.messages.types.mission' => 'مهمة المراقبة',
			'com.messages.types.remplacement' => 'الاستبدال',
			'com.messages.types.autre' => 'موضوع آخر',
			'com.messages.panneau.objets' => 'بخصوص',
			'com.messages.panneau.participants' => 'المشاركون',
			'com.messages.panneau.fichiers' => _root.com.socle.lexique.fichiersPartages,
			'com.messages.panneau.ouvrir' => ({required Object objet}) => 'فتح ${objet}',
			'com.messages.panneau.inaccessible' => 'لم يعد هذا الموضوع متاحًا لك. تبقى المحادثة متاحة للقراءة.',
			'com.messages.panneau.vous' => 'أنت',
			'com.messages.fil.lectureSeule' => 'يمكنك قراءة هذه المحادثة. الرد فيها غير متاح لك.',
			'com.messages.demo.choisirRole' => 'اختر وجهة النظر في هذا العرض التوضيحي.',
			'com.messages.demo.roles.tuteur' => 'الأسرة',
			'com.messages.demo.roles.enseignant' => 'المعلم',
			'com.messages.demo.roles.adulte' => 'طالب بالغ',
			'com.messages.demo.roles.admin' => 'الإدارة',
			'com.messages.demo.roles.controleur' => 'المراقب',
			'com.messages.demo.situations' => 'حالات للتجربة',
			'com.messages.demo.echec' => 'إرسال غير مؤكد، من جهة المعلم',
			'com.messages.demo.horsLigne' => 'دون اتصال، من جهة الأسرة',
			'com.messages.demo.refuse' => 'محادثة أسرة أخرى، مرفوضة',
			'com.messages.demo.vue' => ({required Object role}) => 'وجهة النظر: ${role}',
			'com.messages.demo.f.ahmed' => 'أحمد',
			'com.messages.demo.f.parentAdam' => 'ولي أمر آدم',
			'com.messages.demo.f.enseignanteNour' => 'معلمة فصل النور',
			'com.messages.demo.f.fatima' => 'فاطمة',
			'com.messages.demo.f.parentYasmine' => 'ولية أمر ياسمين',
			'com.messages.demo.f.karim' => 'كريم',
			'com.messages.demo.f.parentYusuf' => 'ولي أمر يوسف',
			'com.messages.demo.f.administration' => 'الإدارة',
			'com.messages.demo.f.directionRewayah' => 'إدارة رواية',
			'com.messages.demo.f.rachid' => 'الأستاذ رشيد',
			'com.messages.demo.f.controleurPedagogique' => 'مراقب تربوي',
			'com.messages.demo.f.youssef' => 'يوسف',
			'com.messages.demo.f.enseignantFajr' => 'معلم فصل الفجر',
			'com.messages.demo.f.khadija' => 'خديجة',
			'com.messages.demo.f.eleveFajr' => 'طالبة في فصل الفجر',
			'com.messages.demo.f.adam' => 'آدم',
			'com.messages.demo.f.yasmine' => 'ياسمين',
			'com.messages.demo.f.yusuf' => 'يوسف',
			'com.messages.demo.f.dossierAdam' => 'ملف تسجيل آدم',
			'com.messages.demo.f.missionNour' => 'زيارة مراقبة، فصل النور',
			'com.messages.demo.f.pieceDevoir' => 'واجب_الأسبوع_3.pdf',
			'com.messages.demo.f.pieceAttestation' => 'الشهادة_القديمة.pdf',
			'com.messages.demo.f.pieceVocal' => 'رسالة_صوتية.m4a',
			'com.messages.demo.f.typeAudio' => 'صوت',
			'com.messages.demo.f.adamQuestion' => 'السلام عليكم، أردت أن أعرف كيف مرّت حصة اليوم بالنسبة إلى آدم. شكرًا جزيلًا.',
			'com.messages.demo.f.adamReponse' => 'وعليكم السلام، مرّت الحصة على أحسن وجه. كان آدم منتبهًا وشارك مشاركة جيدة.',
			'com.messages.demo.f.adamDevoir' => 'إليكم واجب الأسبوع القادم.',
			'com.messages.demo.f.dossierManque' => 'تنقص شهادة مستوى آدم لإتمام تسجيله. هل يمكنكم إيداعها في ملفه؟',
			'com.messages.demo.f.missionRetard' => 'بدأت الحصة متأخرة ثماني دقائق. أُودع التقرير.',
			'com.messages.demo.f.missionSuite' => 'شكرًا، سنتحدث في الأمر مع المعلمة هذا الأسبوع.',
			'com.messages.demo.f.yasmineMerci' => 'شكرًا جزيلًا على هذه التوضيحات.',
			'com.messages.demo.f.affectation' => 'ينتقل فصل النور إلى يوم الثلاثاء الساعة 18 ابتداءً من الشهر القادم. يرجى التأكيد.',
			'com.messages.demo.f.khadijaRevision' => 'تذكّري مراجعة سورة الملك قبل يوم الخميس.',
			'com.messages.titre' => _root.com.socle.lexique.messagesMetier,
			'com.messages.vide' => 'لا توجد محادثات حاليًا.',
			'com.vocal.composer.libelle' => 'رسالة صوتية',
			'com.vocal.composer.enregistrer' => 'تسجيل رسالة صوتية',
			'com.vocal.composer.indisponible' => 'الرسالة الصوتية غير متاحة هنا بعد. اكتب رسالتك في الحقل أعلاه.',
			'com.vocal.composer.erreurVerificationTitre' => 'تعذّر التحقق من الميكروفون.',
			'com.vocal.composer.erreurVerificationAction' => 'إعادة المحاولة',
			'com.vocal.composer.erreurDemarrage' => 'تعذّر بدء التسجيل. تحقّق من أن الميكروفون لا يستخدمه تطبيق آخر، ثم أعد المحاولة.',
			'com.vocal.composer.erreurInterrompu' => 'توقف التسجيل. تحقّق من الميكروفون، ثم أعد المحاولة.',
			'com.vocal.composer.permissionTitre' => 'الميكروفون مطلوب',
			'com.vocal.composer.permissionPhrase' => 'يحتاج رواية إلى الميكروفون لتسجيل رسالتك الصوتية. لا يُرسل شيء دون موافقتك.',
			'com.vocal.composer.autoriser' => 'السماح باستخدام الميكروفون',
			'com.vocal.composer.annuler' => 'إلغاء',
			'com.vocal.composer.refuse' => 'الميكروفون غير مسموح به لتطبيق رواية.',
			'com.vocal.composer.refuseAide' => 'لإرسال رسالة صوتية، اسمح باستخدام الميكروفون من إعدادات جهازك، ثم عد إلى هنا.',
			'com.vocal.composer.fermer' => 'إغلاق',
			'com.vocal.composer.enregistrement' => 'التسجيل جارٍ',
			'com.vocal.composer.pause' => 'التسجيل متوقف مؤقتًا',
			'com.vocal.composer.reprise' => 'استُؤنف التسجيل',
			'com.vocal.composer.limiteProche' => ({required Object seuil, required Object max}) => 'بقي أقل من ${seuil} قبل الحد الأقصى ${max}',
			'com.vocal.composer.limiteAtteinte' => ({required Object max}) => 'بلغت المدة القصوى (${max}). استمع إلى رسالتك، ثم أرسلها أو احذفها.',
			'com.vocal.composer.ecoule' => ({required Object ecoule, required Object max}) => '${ecoule} من ${max}',
			'com.vocal.composer.preEcoute' => 'الاستماع قبل الإرسال',
			'com.vocal.composer.preEcouteAide' => 'استمع إلى رسالتك قبل إرسالها. لا يُرسل شيء دون موافقتك.',
			'com.vocal.composer.duree' => ({required Object duree}) => 'المدة: ${duree}',
			'com.vocal.composer.actionPause' => 'إيقاف مؤقت',
			'com.vocal.composer.actionReprendre' => 'استئناف',
			'com.vocal.composer.actionArreter' => 'إيقاف',
			'com.vocal.composer.actionSupprimer' => 'حذف',
			'com.vocal.composer.actionEnvoyer' => 'إرسال',
			'com.vocal.composer.confirmerTitre' => 'حذف هذه الرسالة الصوتية؟',
			'com.vocal.composer.confirmerPhrase' => 'ستُمحى من هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.',
			'com.vocal.composer.garder' => 'الاحتفاظ بها',
			'com.vocal.composer.envoi' => 'جارٍ إرسال الرسالة الصوتية',
			'com.vocal.composer.nonConfirme' => 'لم يتم تأكيد هذه الرسالة الصوتية بعد.',
			'com.vocal.composer.nonConfirmeAide' => 'تحقّق من اتصالك، ثم أعد المحاولة. الرسالة الصوتية محفوظة هنا.',
			'com.vocal.composer.reessayer' => 'إعادة المحاولة',
			'com.vocal.composer.envoye' => 'أُرسلت الرسالة الصوتية.',
			'com.vocal.composer.horsLigne' => 'أنت غير متصل. الرسالة الصوتية محفوظة هنا: أرسلها عند عودة الاتصال.',
			'com.vocal.lecteur.libelleAuteur' => ({required Object auteur, required Object duree}) => 'رسالة صوتية من ${auteur}‏، ${duree}',
			'com.vocal.lecteur.libelle' => ({required Object duree}) => 'رسالة صوتية، ${duree}',
			'com.vocal.lecteur.ecouter' => 'استماع',
			'com.vocal.lecteur.pause' => 'إيقاف مؤقت',
			'com.vocal.lecteur.reprendre' => 'استئناف',
			'com.vocal.lecteur.reecouter' => 'إعادة الاستماع',
			'com.vocal.lecteur.nonEcoute' => 'لم يُستمع إليها بعد',
			'com.vocal.lecteur.lecture' => 'التشغيل جارٍ',
			'com.vocal.lecteur.enPause' => 'التشغيل متوقف مؤقتًا',
			'com.vocal.lecteur.fin' => 'استُمع إليها كاملة',
			'com.vocal.lecteur.position' => ({required Object position, required Object duree}) => '${position} من ${duree}',
			'com.vocal.lecteur.indisponible' => 'التشغيل غير متاح هنا بعد. تبقى الرسالة في المحادثة: عد لاحقًا للاستماع إليها.',
			'com.vocal.lecteur.erreurLectureTitre' => 'تعذّر تشغيل هذه الرسالة الصوتية.',
			'com.vocal.lecteur.erreurLectureAction' => 'إعادة المحاولة',
			'com.vocal.demo.contexte' => 'عرض توضيحي للرسالة الصوتية: لا يُستخدم ميكروفون حقيقي، والتسجيل محاكى.',
			'com.vocal.demo.situations' => 'حالات العرض التوضيحي',
			'com.vocal.demo.autorise' => 'الميكروفون مسموح',
			'com.vocal.demo.aDemander' => 'يُطلب الإذن',
			'com.vocal.demo.refuse' => 'الميكروفون مرفوض',
			'com.vocal.demo.nonConfirme' => 'غير مؤكد',
			'com.vocal.demo.indisponible' => 'غير متاح',
			'com.vocal.demo.recu' => 'رسالة صوتية واردة',
			'com.vocal.demo.repondre' => 'الرد في المحادثة',
			'com.vocal.demo.envoyes' => 'الرسائل الصوتية المرسلة',
			'com.vocal.demo.auteurEnseignante' => 'سيدة مريم، معلمة',
			'com.vocal.demo.auteurParent' => 'أحمد، ولي أمر آدم',
			'com.vocal.demo.messageRecu' => 'السلام عليكم، هذه ملاحظاتي على تلاوة هذا الأسبوع.',
			'com.vocal.demo.horodatage' => 'اليوم، 10:28',
			'com.vocal.titre' => 'رسالة صوتية',
			'com.communaute.garde.aide' => 'لا إعلانات. لا روابط تسويق بالعمولة. لا بيع.',
			'com.communaute.garde.avertissement' => 'يبدو أن هذا المنشور يتضمّن ترويجًا تجاريًا. أزِل الرابط أو الرمز أو العرض قبل النشر.',
			'com.communaute.garde.bloqueAffilie' => 'روابط التسويق بالعمولة غير مسموح بها في مجتمع المعلّمين.',
			'com.communaute.garde.bloqueVente' => 'بيع المنتجات أو الخدمات غير مسموح به في هذه المساحة.',
			'com.communaute.garde.titreAvertissement' => 'منشور يحتاج إلى مراجعة',
			'com.communaute.garde.titreBlocage' => 'منشور محظور',
			'com.communaute.garde.motif' => ({required Object motif}) => 'السبب: ${motif}',
			'com.communaute.garde.liensTitre' => 'روابط المنشور',
			'com.communaute.garde.consigneBlocage' => 'عدِّل المنشور ثم انشره من جديد.',
			'com.communaute.garde.panne' => 'لم يُؤكَّد التحقق من هذا المحتوى، على الأرجح بسبب الاتصال؛ لم يُنشر شيء. تحقّق من الاتصال ثم أعد المحاولة.',
			'com.communaute.garde.reponse.avertissement' => 'يبدو أن هذا الرد يتضمن ترويجًا تجاريًا. احذف الرابط أو رمز الخصم أو العرض قبل إرساله.',
			'com.communaute.garde.reponse.liensTitre' => 'روابط الرد',
			'com.communaute.garde.reponse.consigneBlocage' => 'عدِّل الرد ثم أرسله من جديد.',
			'com.communaute.lien.interne' => 'رابط داخلي في رواية',
			'com.communaute.lien.ressourceExterne' => 'مورد تعليمي خارجي',
			'com.communaute.lien.commercialInterdit' => 'رابط تجاري ممنوع',
			'com.communaute.lien.nonVerifie' => 'رابط غير مُتحقَّق منه',
			'com.communaute.lien.semantique' => ({required Object adresse, required Object etat}) => '${adresse}‏، ${etat}',
			'com.communaute.sousTitre' => 'تبادل وتعاون بين المعلّمين',
			'com.communaute.sections' => 'فئات مجتمع المعلّمين',
			'com.communaute.toutes' => 'الكل',
			'com.communaute.videTitre' => 'لا توجد منشورات',
			'com.communaute.rechercheVideTitre' => 'لا توجد نتائج',
			'com.communaute.rechercheVide' => 'لا يوجد منشور يطابق بحثك. جرّب كلمة أخرى.',
			'com.communaute.videToutes' => 'لا توجد منشورات حاليًا.',
			'com.communaute.flux.ouvrir' => ({required Object titre}) => 'فتح المنشور ${titre}',
			'com.communaute.flux.reponseUne' => 'رد واحد',
			'com.communaute.flux.reponses' => ({required Object nombre}) => '${nombre} ردود',
			'com.communaute.flux.aucuneReponse' => 'لا توجد ردود',
			'com.communaute.flux.categorie' => ({required Object categorie}) => 'الفئة ${categorie}',
			'com.communaute.recherche.ouvrir' => 'البحث عن منشور',
			'com.communaute.recherche.champ' => 'البحث عن منشور',
			'com.communaute.recherche.aide' => 'كلمة من العنوان أو النص',
			'com.communaute.moment.instant' => 'الآن',
			'com.communaute.moment.minutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'منذ دقيقة', two: 'منذ دقيقتين', few: 'منذ ${n} دقائق', many: 'منذ ${n} دقيقة', other: 'منذ ${n} دقيقة', ), 
			'com.communaute.moment.heures' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'منذ ساعة', two: 'منذ ساعتين', few: 'منذ ${n} ساعات', many: 'منذ ${n} ساعة', other: 'منذ ${n} ساعة', ), 
			'com.communaute.moment.jours' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'منذ يوم', two: 'منذ يومين', few: 'منذ ${n} أيام', many: 'منذ ${n} يومًا', other: 'منذ ${n} يوم', ), 
			'com.communaute.moment.date' => ({required Object jour, required Object mois}) => 'في ${jour}/${mois}',
			'com.communaute.publication.auteur' => ({required Object fonction, required Object moment}) => '${fonction} · ${moment}',
			'com.communaute.publication.enregistrer' => 'حفظ المنشور',
			'com.communaute.publication.enregistree' => 'منشور محفوظ',
			'com.communaute.publication.retirer' => 'إزالة من العناصر المحفوظة',
			'com.communaute.publication.menu' => ({required Object titre}) => 'إجراءات على المنشور ${titre}',
			'com.communaute.publication.signaler' => 'الإبلاغ عن المنشور',
			'com.communaute.publication.signalee' => 'تم الإبلاغ عن المحتوى إلى فريق الإشراف.',
			'com.communaute.publication.choisirTitre' => 'لا يوجد منشور مفتوح',
			'com.communaute.publication.choisir' => 'اختر منشورًا من القائمة لقراءته والرد عليه.',
			'com.communaute.publication.introuvableTitre' => 'المنشور غير متاح',
			'com.communaute.publication.introuvable' => 'تمت إزالة هذا المنشور أو لم يعد متاحًا لك. عد إلى المنشورات لاختيار منشور آخر.',
			'com.communaute.publication.revenir' => 'العودة إلى المنشورات',
			'com.communaute.reponses.titre' => ({required Object nombre}) => 'الردود (${nombre})',
			'com.communaute.reponses.vide' => 'لا توجد ردود حاليًا.',
			'com.communaute.reponses.erreurTitre' => 'تعذّر تحميل الردود.',
			'com.communaute.reponses.champ' => 'ردك',
			'com.communaute.reponses.aide' => 'اكتب ردًا',
			'com.communaute.reponses.envoyer' => 'إرسال الرد',
			'com.communaute.reponses.champVide' => 'اكتب ردًا لإرساله.',
			'com.communaute.reponses.enCours' => 'جارٍ الإرسال',
			'com.communaute.reponses.nonConfirmee' => 'لم يُؤكَّد هذا الرد بعد. تحقّق من اتصالك ثم أعد إرساله.',
			'com.communaute.reponses.refusee' => 'رفضته سياسة المجتمع',
			'com.communaute.reponses.reessayer' => 'إعادة إرسال الرد',
			'com.communaute.reponses.indisponible' => 'الردود غير متاحة هنا بعد.',
			'com.communaute.reponses.menu' => ({required Object nom}) => 'إجراءات على رد ${nom}',
			'com.communaute.reponses.signaler' => 'الإبلاغ عن الرد',
			'com.communaute.reponses.signalee' => 'لقد أبلغت عن هذا الرد.',
			'com.communaute.signalement.politique.publicite' => 'الإعلانات التجارية غير مسموح بها في مجتمع المعلّمين.',
			'com.communaute.signalement.politique.sollicitation' => 'الاستدراج التجاري غير مسموح به في هذه المساحة.',
			'com.communaute.signalement.motifManquant' => 'اختر سببًا لإرسال البلاغ.',
			'com.communaute.composer.nouvelle' => 'منشور جديد',
			'com.communaute.composer.contexte' => 'شارك سؤالًا أو طريقة أو موردًا مفيدًا للتعليم.',
			'com.communaute.composer.categorie' => 'الفئة',
			'com.communaute.composer.categorieManquante' => 'اختر فئة للنشر.',
			'com.communaute.composer.champTitre' => 'العنوان',
			'com.communaute.composer.aideTitre' => 'الموضوع في كلمات قليلة',
			'com.communaute.composer.titreManquant' => 'اكتب عنوانًا للنشر.',
			'com.communaute.composer.champTexte' => 'النص',
			'com.communaute.composer.aideTexte' => 'سؤالك أو خبرتك',
			'com.communaute.composer.texteManquant' => 'اكتب نص المنشور للنشر.',
			'com.communaute.composer.pieces' => 'المرفقات',
			'com.communaute.composer.pieceRefusee' => 'أزل الملفات المرفوضة قبل النشر.',
			'com.communaute.composer.choixIndisponible' => 'اختيار ملف غير متاح هنا بعد.',
			'com.communaute.composer.publier' => 'نشر',
			'com.communaute.composer.fermer' => 'إغلاق المنشور الجديد',
			'com.communaute.composer.confirmee' => 'منشورك متاح الآن.',
			'com.communaute.composer.erreurEnvoi' => 'لم يُؤكَّد منشورك بعد. تحقّق من اتصالك ثم أعد المحاولة.',
			'com.communaute.composer.indisponible' => 'النشر غير متاح هنا بعد.',
			'com.communaute.regles.panneau' => 'المساعدة والقواعد',
			'com.communaute.regles.aProposTitre' => 'حول هذه المساحة',
			'com.communaute.regles.aPropos' => 'مساحة تعاون بين المعلّمين لطرح الأسئلة وتبادل الطرق والموارد التعليمية.',
			'com.communaute.regles.titre' => 'مشاركة تعليمية فقط',
			'com.communaute.regles.corps' => 'هذا المجتمع مخصّص للتبادل المهني بين المعلّمين.',
			'com.communaute.regles.reglesTitre' => 'قواعد النشر',
			'com.communaute.regles.pasPublicite' => 'لا إعلانات',
			'com.communaute.regles.pasAffilie' => 'لا روابط تسويق بالعمولة',
			'com.communaute.regles.pasVente' => 'لا بيع لمنتج أو خدمة',
			'com.communaute.regles.pasSollicitation' => 'لا التماس تجاري',
			'com.communaute.regles.pasDonnees' => 'لا بيانات شخصية لطالب أو عائلة',
			'com.communaute.regles.signaler' => 'يُبلَّغ عن المحتوى غير المناسب من قائمة المنشور.',
			'com.communaute.regles.voir' => 'عرض القواعد',
			'com.communaute.entree.lecteur' => 'فتح مجتمع المعلّمين',
			'com.communaute.entree.detail' => 'أسئلة وطرق وموارد بين المعلّمين',
			'com.communaute.demo.avertissement' => 'منشور يحتاج إلى مراجعة: إعلان تجاري',
			'com.communaute.demo.lienAffilie' => 'رابط تسويق بالعمولة محظور',
			'com.communaute.demo.vente' => 'بيع محظور',
			'com.communaute.demo.signalementNonConfirme' => 'إبلاغ غير مؤكَّد',
			'com.communaute.demo.choisir' => 'اختر حالة لتجربتها كما يراها معلّم.',
			'com.communaute.demo.aujourdhui' => 'اليوم، مع الاختصار',
			'com.communaute.demo.nominal' => 'ستة منشورات',
			'com.communaute.demo.publication' => 'منشور مفتوح',
			'com.communaute.demo.vide' => 'لا توجد منشورات',
			'com.communaute.demo.lectureEchouee' => 'فشل القراءة',
			'com.communaute.demo.indisponible' => 'الخدمة غير متاحة بعد',
			'com.communaute.demo.horsLigne' => 'غير متصل',
			'com.communaute.demo.envoiNonConfirme' => 'إرسال غير مؤكَّد',
			'com.communaute.demo.moderationIndisponible' => 'الإشراف غير متاح',
			'com.communaute.demo.lecteurSeul' => 'قراءة فقط، دون نشر',
			'com.communaute.demo.f.categoriePedagogie' => 'التربية',
			'com.communaute.demo.f.categorieRessources' => 'الموارد',
			'com.communaute.demo.f.categorieGestion' => 'التسيير',
			'com.communaute.demo.f.fonctionSoi' => 'معلم، فصل الفاتحة',
			'com.communaute.demo.f.prenomSoi' => 'إبراهيم',
			'com.communaute.demo.f.samira' => 'سميرة بلقاسم',
			'com.communaute.demo.f.fonctionSamira' => 'معلمة، فصل النور',
			'com.communaute.demo.f.nour' => 'نور الإدريسي',
			'com.communaute.demo.f.fonctionNour' => 'معلمة، فصل الفجر',
			'com.communaute.demo.f.yasmine' => 'ياسمين حداد',
			'com.communaute.demo.f.fonctionYasmine' => 'معلمة، فصل البدر',
			'com.communaute.demo.f.youssef' => 'يوسف العمراني',
			'com.communaute.demo.f.fonctionYoussef' => 'معلم، فصل الكوثر',
			'com.communaute.demo.f.mariam' => 'مريم بن علي',
			'com.communaute.demo.f.fonctionMariam' => 'معلمة، فصل الناس',
			'com.communaute.demo.f.hamza' => 'حمزة والي',
			'com.communaute.demo.f.fonctionHamza' => 'معلم، فصل الإخلاص',
			'com.communaute.demo.f.memorisationTitre' => 'أفكار للمساعدة على الحفظ؟',
			'com.communaute.demo.f.memorisationTexte' => 'ما العادات أو الأنشطة التي تنجح في مساعدة الطلاب على حفظ السور؟ أبحث عن تجارب عملية: ألعاب، ووسائل بصرية، وتكرار ثنائي. شكرًا على أفكاركم!',
			'com.communaute.demo.f.cartesTitre' => 'تجربتي مع بطاقات التكرار',
			'com.communaute.demo.f.cartesTexte' => 'أستخدم بطاقات التكرار منذ بداية العام الدراسي وهي تنجح كثيرًا، حتى مع الأصغر سنًّا. أرفقت النموذج الذي أملؤه قبل كل حصة.',
			'com.communaute.demo.f.cartesFichier' => 'بطاقات_التكرار.pdf',
			'com.communaute.demo.f.niveauxTitre' => 'كيف ندير المستويات المختلفة؟',
			'com.communaute.demo.f.niveauxTexte' => 'كيف تديرون فصلًا تتفاوت فيه المستويات كثيرًا؟ أخشى أن يفقد المتقدمون اهتمامهم بينما أعيد الأساسيات مع الآخرين.',
			'com.communaute.demo.f.timidesTitre' => 'تشجيع الطلاب الخجولين على التلاوة',
			'com.communaute.demo.f.timidesTexte' => 'طالبة ترفض التلاوة أمام الآخرين. أقترح عليها أن تتلو أولًا، حين يكون الفصل لا يزال هادئًا. هل لديكم أفكار أخرى؟',
			'com.communaute.demo.f.ficheTitre' => 'بطاقة لمتابعة المراجعات',
			'com.communaute.demo.f.ficheTexte' => 'أدوّن كل أسبوع السور التي رُوجعت والنقاط التي تحتاج إلى إعادة. تكفي البطاقة صفحة واحدة وتساعد كثيرًا في التحضير للحصة التالية.',
			'com.communaute.demo.f.heureTitre' => 'بدء الحصة في موعدها',
			'com.communaute.demo.f.heureTexte' => 'كثيرًا ما تضيع الدقائق الأولى في التجهيز. صرت أطلب من الطلاب تحضير صفحتهم قبل الموعد. ما رأيكم؟',
			'com.communaute.demo.f.reponseMariam' => 'أستخدم كثيرًا التكرار الثنائي والبطاقات المصوّرة. وهذا يحفّز الطلاب حقًّا.',
			'com.communaute.demo.f.reponseYoussef' => 'يعيد الطلاب الاستماع إلى تلاوة الحصة في البيت، وهذا يساعد كثيرًا بين درسين.',
			'com.communaute.demo.f.reponseSamira' => 'شكرًا على النموذج، سأجربه هذا الأسبوع.',
			'com.communaute.demo.f.reponseHamza' => 'أترك الطالب أحيانًا يتلو على انفراد في نهاية الحصة، ثم أمام زميل واحد.',
			'com.communaute.demo.f.affilieTitre' => 'مشغّلي الصوتي المفضل للمراجعة',
			'com.communaute.demo.f.affilieTexte' => ({required Object lien}) => 'أستخدم هذا المشغّل لإعادة الاستماع إلى السور. سعره مخفَّض هذا الأسبوع عبر رابطي: ${lien}',
			'com.communaute.demo.f.venteTitre' => 'أبيع بطاقات الحفظ الخاصة بي',
			'com.communaute.demo.f.venteTexte' => 'مجموعة من 30 بطاقة مغلَّفة، بـ 25 يورو، تُرسل بالبريد. راسلوني للطلب.',
			'com.communaute.demo.f.publiciteTitre' => 'تطبيق للمراجعة',
			'com.communaute.demo.f.publiciteTexte' => ({required Object lienOffre, required Object lienInterne, required Object lienRessource}) => 'أنصح بتطبيق المراجعة هذا، مع الرمز PROF20 للاشتراك: ${lienOffre}. أما النص، فيكفي مورد المكتبة (${lienInterne}) و${lienRessource}.',
			'com.communaute.demo.f.reponseAffilie' => ({required Object lien}) => 'للمراجعة، أنصح بهذا المشغّل، بسعر مخفَّض عبر رابطي: ${lien}',
			'com.communaute.demo.f.fichierChoisi' => 'بطاقة_الحصة.pdf',
			'com.communaute.titre' => _root.com.socle.lexique.communaute,
			'com.communaute.vide' => 'لا توجد منشورات في هذه الفئة.',
			'com.studio.focus.entrer' => _root.com.socle.lexique.modeFocus,
			'com.studio.focus.quitter' => _root.com.socle.lexique.quitterFocus,
			'com.studio.focus.actif' => 'التركيز مفعّل',
			'com.studio.focus.actifAvecEchap' => 'التركيز مفعّل. اضغط Esc للخروج.',
			'com.studio.focus.aide' => 'أخفِ اللوحات الثانوية للتركيز على هذه المحادثة.',
			'com.studio.aujourdhui.titre' => _root.com.socle.lexique.aujourdhui,
			'com.studio.aujourdhui.sousTitre' => 'ما يستحق انتباهك في الاستوديو',
			'com.studio.aujourdhui.indicateurs.titre' => 'مؤشرات الانتباه',
			'com.studio.aujourdhui.indicateurs.aTraiter' => _root.com.socle.lexique.aTraiter,
			'com.studio.aujourdhui.indicateurs.mentions' => 'الإشارات والردود',
			'com.studio.aujourdhui.indicateurs.decisions' => 'قرارات معلّقة',
			'com.studio.aujourdhui.indicateurs.nonLus' => 'غير مقروءة',
			'com.studio.aujourdhui.blocs.aTraiter' => 'للمعالجة اليوم',
			'com.studio.aujourdhui.blocs.mentions' => 'الإشارات والردود',
			'com.studio.aujourdhui.blocs.decisions' => 'قرارات معلّقة',
			'com.studio.aujourdhui.blocs.echeances' => 'مواعيد قريبة',
			'com.studio.aujourdhui.blocs.activite' => 'النشاط الأخير',
			'com.studio.aujourdhui.blocs.brouillons' => 'المسودات',
			'com.studio.aujourdhui.blocs.acces' => 'وصول سريع',
			'com.studio.aujourdhui.videsBlocs.aTraiter' => 'لا شيء للمعالجة اليوم.',
			'com.studio.aujourdhui.videsBlocs.mentions' => 'لا توجد إشارات أو ردود في الانتظار.',
			'com.studio.aujourdhui.videsBlocs.decisions' => 'لا توجد قرارات معلّقة.',
			'com.studio.aujourdhui.videsBlocs.echeances' => 'لا توجد مواعيد قريبة.',
			'com.studio.aujourdhui.videsBlocs.activite' => 'لا يوجد نشاط حديث.',
			'com.studio.aujourdhui.videTitre' => 'لا شيء للمعالجة حاليًا',
			'com.studio.aujourdhui.dansCanal' => ({required Object nom}) => 'في ${nom}',
			'com.studio.aujourdhui.echeance' => ({required Object date}) => 'الموعد ${date}',
			'com.studio.aujourdhui.seTraiteDans' => ({required Object module}) => 'يُعالَج في ${module}',
			'com.studio.aujourdhui.ouvrirDans' => ({required Object module, required Object libelle}) => 'فتح في ${module}: ${libelle}',
			'com.studio.aujourdhui.modules.studio' => _root.com.socle.lexique.studio,
			'com.studio.aujourdhui.modules.finance' => 'المالية',
			'com.studio.aujourdhui.modules.planning' => 'الجدولة',
			'com.studio.aujourdhui.modules.dossiers' => 'الملفات',
			'com.studio.aujourdhui.modules.classes' => 'الفصول',
			'com.studio.aujourdhui.modules.admissions' => 'القبول',
			'com.studio.aujourdhui.modules.demandes' => 'الطلبات',
			'com.studio.aujourdhui.modules.communications' => 'إدارة الاتصالات',
			'com.studio.aujourdhui.acces.messages' => _root.com.socle.lexique.messagesMetier,
			'com.studio.aujourdhui.acces.messagesDetail' => 'المحادثات مع الأسر والمعلّمين والمراقبين',
			'com.studio.aujourdhui.acces.annonces' => 'الإعلانات',
			'com.studio.aujourdhui.acces.annoncesDetail' => 'نشر الإعلانات ومتابعتها',
			'com.studio.aujourdhui.acces.dossiers' => 'ملفات للتصديق',
			'com.studio.aujourdhui.acces.dossiersDetail' => 'الملفات الجاهزة لاتخاذ قرار',
			'com.studio.aujourdhui.acces.classes' => 'الفصول',
			'com.studio.aujourdhui.acces.classesDetail' => 'الفصول ومواعيدها ومعلّموها',
			'com.studio.aujourdhui.acces.demandes' => 'طلبات بانتظار القرار',
			'com.studio.aujourdhui.acces.demandesDetail' => 'طلبات التغيير المنتظرة',
			'com.studio.brouillons.titre' => 'المسودات',
			'com.studio.brouillons.detail' => 'الرسائل التي بدأتها في قناة ولم تُرسل بعد. تبقى على هذا الجهاز طوال الجلسة، دون مزامنة.',
			'com.studio.brouillons.dansCanal' => ({required Object nom}) => 'مسودة في ${nom}',
			'com.studio.brouillons.canalInconnu' => 'مسودة في قناة',
			'com.studio.brouillons.canalIndisponible' => 'مسودة في قناة لم تعد متاحة',
			'com.studio.brouillons.modifie' => ({required Object moment}) => 'عُدّلت في ${moment}',
			'com.studio.brouillons.reprendre' => ({required Object nom}) => 'متابعة المسودة في ${nom}',
			'com.studio.brouillons.videTitre' => 'لا توجد مسودات',
			'com.studio.brouillons.vide' => 'ستظهر هنا أي رسالة بدأتها في قناة ولم تُرسل بعد.',
			'com.studio.brouillons.tous' => ({required Object nombre}) => 'عرض كل المسودات (${nombre})',
			'com.studio.brouillons.restaure' => 'استُعيدت المسودة. يمكنك متابعة رسالتك.',
			'com.studio.sousTitre' => 'مساحة عمل الفريق',
			'com.studio.navigation.aujourdhui' => _root.com.socle.lexique.aujourdhui,
			'com.studio.navigation.brouillons' => 'المسودات',
			'com.studio.navigation.canaux' => 'القنوات',
			'com.studio.navigation.enregistres' => 'العناصر المحفوظة',
			'com.studio.choisirTitre' => 'اختر قناة',
			'com.studio.choisir' => 'اختر قناة من القائمة لقراءة النقاش والكتابة فيه.',
			'com.studio.aucunCanalTitre' => 'لا توجد قنوات حاليًا',
			'com.studio.aucunCanal' => 'ستظهر هنا القنوات المفتوحة لك.',
			'com.studio.sections.organisation' => 'التنظيم',
			'com.studio.sections.admissionsFamilles' => 'القبول والأسر',
			'com.studio.sections.pedagogieQualite' => 'التعليم والجودة',
			'com.studio.sections.planningRemplacements' => 'الجدولة والاستبدال',
			'com.studio.sections.finance' => 'المالية',
			'com.studio.sections.support' => 'الدعم',
			'com.studio.sections.produitTechnique' => 'المنتج والتقنية',
			'com.studio.sections.direction' => 'الإدارة العليا',
			'com.studio.visibilite.restreint' => 'محدودة',
			'com.studio.visibilite.prive' => 'خاصة',
			'com.studio.visibilite.visibleDetail' => 'مفتوحة لكل الفريق.',
			'com.studio.visibilite.restreintDetail' => 'مفتوحة لجزء من الفريق، وأنت منهم.',
			'com.studio.visibilite.priveDetail' => 'قناة خاصة، مفتوحة لأعضائها فقط. وأنت منهم.',
			'com.studio.canal.membresUn' => 'عضو واحد',
			'com.studio.canal.membres' => ({required Object nombre}) => '${nombre} أعضاء',
			'com.studio.canal.aide' => ({required Object nom}) => 'اكتب في ${nom}',
			'com.studio.canal.lectureSeule' => 'يمكنك قراءة هذه القناة. الكتابة فيها غير مفتوحة لك.',
			'com.studio.canal.aucunMessageTitre' => 'لا توجد رسائل حاليًا',
			'com.studio.canal.aucunMessage' => 'ستظهر رسائل هذه القناة هنا فور نشرها.',
			'com.studio.canal.indisponibleTitre' => 'القناة غير متاحة',
			'com.studio.canal.indisponible' => 'هذه القناة غير متاحة لك. اختر قناة أخرى من القائمة.',
			'com.studio.panneau.titre' => 'حول القناة',
			'com.studio.panneau.aPropos' => 'حول',
			'com.studio.panneau.section' => 'القسم',
			'com.studio.panneau.visibilite' => 'الظهور',
			'com.studio.panneau.epingles' => _root.com.socle.lexique.elementsEpingles,
			'com.studio.panneau.fichiers' => 'الملفات الأخيرة',
			'com.studio.panneau.liens' => 'روابط مفيدة',
			'com.studio.panneau.vous' => 'أنت',
			'com.studio.panneau.parametres' => 'إعدادات القناة',
			'com.studio.panneau.parametresDetail' => 'سيتاح تعديل الإعدادات مع خدمة الاستوديو.',
			'com.studio.panneau.ouvrir' => ({required Object titre}) => 'فتح ${titre}',
			'com.studio.panneau.lienExterne' => ({required Object hote}) => 'موقع خارجي: ${hote}',
			'com.studio.panneau.aucunPartageTitre' => 'لا شيء مشترك حاليًا',
			'com.studio.panneau.aucunPartage' => 'ستظهر هنا العناصر المثبتة والملفات والروابط الخاصة بهذه القناة.',
			'com.studio.enregistrer.enregistrer' => _root.com.socle.lexique.enregistrer,
			'com.studio.enregistrer.retirer' => 'إزالة',
			'com.studio.enregistrer.semantiqueEnregistrer' => ({required Object titre}) => 'حفظ ${titre}',
			'com.studio.enregistrer.semantiqueRetirer' => ({required Object titre}) => 'إزالة ${titre} من العناصر المحفوظة',
			'com.studio.enregistrer.ajoute' => ({required Object titre}) => 'أضيف إلى العناصر المحفوظة: ${titre}.',
			'com.studio.enregistrer.retire' => ({required Object titre}) => 'أزيل من العناصر المحفوظة: ${titre}.',
			'com.studio.enregistrer.nonConfirme' => 'لم يتأكد الحفظ بعد. أعد المحاولة بعد لحظة.',
			'com.studio.enregistres.detail' => 'القنوات والعناصر التي تحتفظ بها في متناولك. يُفتح كل منها في مكانه الأصلي.',
			'com.studio.enregistres.videTitre' => 'لا توجد عناصر محفوظة',
			'com.studio.enregistres.vide' => 'اضغط على حفظ في لوحة قناة لتجد هنا قناة أو عنصرًا.',
			'com.studio.enregistres.ouvrir' => ({required Object titre}) => 'فتح ${titre}',
			'com.studio.enregistres.sansDestination' => ({required Object type}) => '${type}‏، لم يعد يُفتح من هنا',
			'com.studio.enregistres.types.canal' => 'قناة',
			'com.studio.enregistres.types.publication' => 'منشور',
			'com.studio.enregistres.types.message' => 'رسالة',
			'com.studio.enregistres.types.element' => 'عنصر من الاستوديو',
			'com.studio.recherche.champ' => 'البحث في الاستوديو',
			'com.studio.recherche.aide' => 'قناة أو رسالة أو ملف',
			'com.studio.recherche.aucunTitre' => 'لا توجد نتائج',
			'com.studio.recherche.aucun' => ({required Object texte}) => 'لا شيء يطابق »${texte}« في قنواتك. جرّب كلمة أخرى.',
			'com.studio.recherche.aucunDansFiltre' => 'لا شيء من هذا النوع يطابق البحث. اختر الكل لرؤية النتائج الأخرى.',
			'com.studio.recherche.resultatUn' => 'نتيجة واحدة',
			'com.studio.recherche.resultats' => ({required Object nombre}) => '${nombre} نتائج',
			'com.studio.recherche.filtre' => 'نوع النتيجة',
			'com.studio.recherche.tout' => 'الكل',
			'com.studio.recherche.canaux' => 'القنوات',
			'com.studio.recherche.messages' => 'الرسائل',
			'com.studio.recherche.fichiers' => 'الملفات',
			'com.studio.recherche.dansCanal' => ({required Object canal}) => 'في ${canal}',
			'com.studio.recherche.messageDe' => ({required Object auteur, required Object canal}) => '${auteur}‏، في ${canal}',
			'com.studio.demo.focus' => 'قناة في وضع التركيز',
			'com.studio.demo.aujourdhuiVide' => 'اليوم دون نشاط',
			'com.studio.demo.horsDemo' => ({required Object module}) => 'في التطبيق، يفتح هذا السطر ${module}. يبقى العرض التجريبي على هذه الصفحة.',
			'com.studio.demo.choisir' => 'اختر حالة لتجربتها.',
			'com.studio.demo.normale' => 'الاستوديو وقنواته',
			'com.studio.demo.echec' => 'إرسال غير مؤكد',
			'com.studio.demo.horsLigne' => 'غير متصل',
			'com.studio.demo.canalPrive' => 'عنوان قناة خاصة غير مفتوحة لك',
			'com.studio.demo.sansCanaux' => 'لا توجد قناة مفتوحة',
			'com.studio.demo.vue' => ({required Object situation}) => 'الحالة: ${situation}',
			'com.studio.demo.f.nadia' => 'نادية',
			'com.studio.demo.f.fonctionDirection' => 'الإدارة',
			'com.studio.demo.f.mariam' => 'مريم',
			'com.studio.demo.f.fonctionCoordination' => 'التنسيق العام',
			'com.studio.demo.f.youssef' => 'يوسف',
			'com.studio.demo.f.fonctionProduit' => 'المنتج والتقنية',
			'com.studio.demo.f.amina' => 'أمينة',
			'com.studio.demo.f.fonctionPedagogie' => 'الشؤون التربوية',
			'com.studio.demo.f.samira' => 'سميرة',
			'com.studio.demo.f.fonctionAdmissions' => 'القبول',
			'com.studio.demo.f.ibrahim' => 'إبراهيم',
			'com.studio.demo.f.fonctionPlanning' => 'الجدولة',
			'com.studio.demo.f.pieceAudio' => 'صوت',
			'com.studio.demo.f.fichierPlanning' => 'جدول_الفصل_الثالث.pdf',
			'com.studio.demo.f.fichierModeration' => 'دليل_الإشراف.pdf',
			_ => null,
		} ?? switch (path) {
			'com.studio.demo.f.fichierVocal' => 'رسالة_صوتية_يوسف.m4a',
			'com.studio.demo.f.fichierCompteRendu' => 'تقرير_الزيارات.pdf',
			'com.studio.demo.f.fichierBudget' => 'الميزانية_السرية.pdf',
			'com.studio.demo.f.canalOrganisation' => 'التنظيم العام',
			'com.studio.demo.f.canalOrganisationDetail' => 'تنسيق عمل الفريق كله',
			'com.studio.demo.f.canalAdmissions' => 'القبول',
			'com.studio.demo.f.canalAdmissionsDetail' => 'متابعة طلبات التسجيل',
			'com.studio.demo.f.canalQualite' => 'متابعة الجودة',
			'com.studio.demo.f.canalQualiteDetail' => 'ملاحظات زيارات المراقبة',
			'com.studio.demo.f.canalRemplacements' => 'البدلاء',
			'com.studio.demo.f.canalRemplacementsDetail' => 'غيابات الأسبوع والمعلمون البدلاء',
			'com.studio.demo.f.canalCloture' => 'إقفال الشهر',
			'com.studio.demo.f.canalClotureDetail' => 'التحضير للإقفال الشهري',
			'com.studio.demo.f.canalDirection' => 'الإدارة الاستراتيجية',
			'com.studio.demo.f.canalDirectionDetail' => 'توجهات الإدارة',
			'com.studio.demo.f.messagePlanning' => 'السلام عليكم جميعًا. إليكم جدول الفصل الدراسي القادم، أخبروني إن كان فيه ما لا يناسب.',
			'com.studio.demo.f.messageSupports' => 'أحدّث مواد المستوى 2 ونراجع الأمر معًا غدًا.',
			'com.studio.demo.f.messageMerci' => 'شكرًا للجميع على هذا الأسبوع.',
			'com.studio.demo.f.messageDossiers' => 'ثلاثة ملفات تنتظر قرارًا قبل يوم الجمعة. نادية، هل يمكنك الاطلاع على ملف أسرة كريم؟',
			'com.studio.demo.f.messageCompteRendu' => 'تقرير زيارات هذا الشهر جاهز.',
			'com.studio.demo.f.messageRemplacement' => 'يوم الثلاثاء، يتولى معلم بديل فصل النور. الجدول محدَّث.',
			'com.studio.demo.f.messageJustificatifs' => 'جُمعت مستندات شهر سبتمبر.',
			'com.studio.demo.f.messageBudget' => 'الميزانية السرية لهذا الفصل الدراسي.',
			'com.studio.demo.f.activiteBudget' => 'الميزانية السرية لهذا الفصل الدراسي',
			'com.studio.demo.f.partagePlanning' => 'جدول الفصل الدراسي',
			'com.studio.demo.f.partageModeration' => 'دليل الإشراف',
			'com.studio.demo.f.epinglePar' => ({required Object nom}) => 'ثبّته ${nom}',
			'com.studio.demo.f.partagePar' => ({required Object nom}) => 'شاركه ${nom}',
			'com.studio.demo.f.lienRemplacements' => 'بدلاء الأسبوع',
			'com.studio.demo.f.lienCharte' => 'ميثاق الفريق',
			'com.studio.demo.f.brouillon' => 'سميرة، سأطّلع على ملف أسرة كريم هذا المساء وأخبرك صباح الغد',
			'com.studio.demo.f.activitePaiement' => 'دفعة سبتمبر غير مؤكدة لأسرة حداد',
			'com.studio.demo.f.objetEcheancier' => 'جدول أقساط أسرة حداد',
			'com.studio.demo.f.activiteDossierKarim' => 'ملف أسرة كريم جاهز لاتخاذ قرار',
			'com.studio.demo.f.objetDossierKarim' => 'ملف أسرة كريم',
			'com.studio.demo.f.activiteMention' => 'أشارت إليك سميرة',
			'com.studio.demo.f.activiteReponse' => 'ردت أمينة على رسالتك',
			'com.studio.demo.f.activiteRemplacant' => 'اختيار المعلم البديل ليوم الثلاثاء لفصل النور',
			'com.studio.demo.f.objetRemplacement' => 'البديل ليوم الثلاثاء',
			'com.studio.demo.f.activiteOuverture' => 'المصادقة على فتح فصل صباح يوم السبت',
			'com.studio.demo.f.objetClasseSamedi' => 'فصل صباح يوم السبت',
			'com.studio.demo.f.activiteCloture' => 'إقفال شهر سبتمبر',
			'com.studio.demo.f.objetCloture' => 'إقفال سبتمبر',
			'com.studio.demo.f.activiteBilans' => 'تقييمات منتصف الفصل للمراجعة',
			'com.studio.demo.f.objetBilans' => 'تقييمات منتصف الفصل',
			'com.studio.demo.f.activiteMessages' => 'رسالتان جديدتان',
			'com.studio.demo.f.activiteAnnonce' => 'نُشر إعلان: الأكاديمية مغلقة يوم 1 نوفمبر',
			'com.studio.demo.f.objetFermeture' => 'الإغلاق يوم 1 نوفمبر',
			'com.studio.demo.f.activiteFichier' => ({required Object nom, required Object fichier}) => '${nom} شاركت ${fichier}',
			'com.studio.demo.f.activiteInscription' => 'وصل طلب تسجيل جديد',
			'com.studio.demo.f.objetDossierBenali' => 'ملف أسرة بن علي',
			'com.studio.titre' => _root.com.socle.lexique.studio,
			'com.studio.vide' => 'لا يوجد نشاط للمعالجة هنا.',
			'com.annonces.publieur.titre' => 'إعلان جديد',
			'com.annonces.publieur.etapes.contenu' => 'محتوى الإعلان',
			'com.annonces.publieur.etapes.audience' => 'مستلمو الإعلان',
			'com.annonces.publieur.etapes.programmation' => 'تاريخ النشر',
			'com.annonces.publieur.etapes.previsualisation' => 'معاينة الإعلان',
			'com.annonces.publieur.etapes.publication' => 'نشر الإعلان',
			'com.annonces.publieur.contexte.contenu' => 'اكتب ما يجب أن يعرفه المستلمون. الإعلان في اتجاه واحد: لا أحد يرد عليه.',
			'com.annonces.publieur.contexte.audience' => 'اختر من يستلم الإعلان. لا يُعرض إلا المستلمون الذين يمكنك النشر لهم.',
			'com.annonces.publieur.contexte.audienceFixee' => ({required Object cible}) => 'يُرسل هذا الإعلان إلى ${cible}. أنت تنشر لفصلك فقط.',
			'com.annonces.publieur.contexte.programmation' => 'اختر متى يُرسل الإعلان. الإعلان المجدول ينتظر تاريخه.',
			'com.annonces.publieur.contexte.previsualisation' => 'هذا هو الإعلان كما سيقرؤه المستلمون.',
			'com.annonces.publieur.contexte.publication' => 'راجع المستلمين والتاريخ، ثم انشر. لا يُنشر شيء قبل التأكيد.',
			'com.annonces.publieur.champTitre' => 'عنوان الإعلان',
			'com.annonces.publieur.champTexte' => 'نص الإعلان',
			'com.annonces.publieur.nature.classe' => 'تستلمه أسر هذا الفصل وطلابه فقط.',
			'com.annonces.publieur.nature.public' => 'يستلمه كل أفراد هذا الجمهور.',
			'com.annonces.publieur.nature.toutes' => 'تستلمه الأكاديمية كلها. خصصه لما يهم الجميع.',
			'com.annonces.publieur.quand.maintenant' => 'فور التأكيد',
			'com.annonces.publieur.quand.maintenantDetail' => 'يُرسل الإعلان فور تأكيد النشر.',
			'com.annonces.publieur.quand.creneau' => ({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}',
			'com.annonces.publieur.quand.creneauDetail' => 'ينتظر الإعلان هذا التاريخ. ستجده في الإعلانات المجدولة.',
			'com.annonces.publieur.apercu.a' => ({required Object cible}) => 'إلى: ${cible}',
			'com.annonces.publieur.apercu.diffusionMaintenant' => 'النشر: فور التأكيد',
			'com.annonces.publieur.apercu.diffusionLe' => ({required Object date, required Object heure}) => 'النشر المقرر يوم ${date} الساعة ${heure}',
			'com.annonces.publieur.continuer' => 'متابعة',
			'com.annonces.publieur.publier' => 'نشر الإعلان',
			'com.annonces.publieur.programmer' => 'جدولة الإعلان',
			'com.annonces.publieur.reessayer' => 'إعادة محاولة النشر',
			'com.annonces.publieur.terminer' => 'إنهاء',
			'com.annonces.publieur.manqueContenu' => 'اكتب عنوانًا ونصًا للمتابعة.',
			'com.annonces.publieur.manqueAudience' => 'اختر المستلمين للمتابعة.',
			'com.annonces.publieur.enCours' => 'النشر جارٍ. انتظر التأكيد.',
			'com.annonces.publieur.publiee' => 'نُشر الإعلان. يستلمه المستلمون.',
			'com.annonces.publieur.planifiee' => ({required Object date, required Object heure}) => 'جُدول الإعلان ليوم ${date} الساعة ${heure}.',
			'com.annonces.publieur.nonConfirmee' => 'لم يُؤكَّد هذا الإعلان بعد. تحقّق من الاتصال ثم أعد المحاولة؛ لن يُرسل إلا مرة واحدة.',
			'com.annonces.publieur.horsLigne' => 'أنت غير متصل، ولم يُؤكَّد هذا الإعلان بعد. أعد المحاولة عند عودة الاتصال.',
			'com.annonces.publieur.indisponible' => 'نشر الإعلانات غير متاح بعد. عد لاحقًا.',
			'com.annonces.publieur.aucuneCibleTitre' => 'لا يوجد مستلم متاح',
			'com.annonces.publieur.aucuneCible' => 'لا يمكنك النشر لأي مستلم حاليًا. اطلب الإذن من الإدارة.',
			'com.annonces.publieur.classeRefuseeTitre' => 'النشر مقصور',
			'com.annonces.publieur.classeRefusee' => 'لا يمكنك نشر إعلان لهذا الفصل. اطلب الإذن من الإدارة.',
			'com.annonces.administration.nouvelle' => 'إعلان جديد',
			'com.annonces.administration.demo' => 'عرض تجريبي',
			'com.annonces.administration.demoDetail' => 'بيانات تجريبية: لا رقم حقيقي.',
			'com.annonces.administration.horsLigne' => 'أنت غير متصل. لا يمكن تحديث الإعلانات.',
			'com.annonces.administration.indicateurs.titre' => 'مؤشرات التواصل',
			'com.annonces.administration.indicateurs.publiees' => 'الإعلانات المنشورة',
			'com.annonces.administration.indicateurs.planifiees' => 'الإعلانات المجدولة',
			'com.annonces.administration.indicateurs.moderation' => 'محتويات قيد الإشراف',
			'com.annonces.administration.indicateurs.regles' => 'صلاحيات النشر',
			'com.annonces.administration.indicateurs.indisponible' => ({required Object libelle}) => '${libelle}: غير متاح بعد',
			'com.annonces.administration.indicateurs.echec' => ({required Object libelle}) => '${libelle}: لم يُحمَّل. تحقّق من الاتصال ثم أعد تحميل الصفحة.',
			'com.annonces.administration.indicateurs.reserve' => ({required Object libelle}) => '${libelle}: خاص بالمكلفين بالإشراف',
			'com.annonces.administration.publiees.titre' => 'الإعلانات المنشورة',
			'com.annonces.administration.publiees.vide' => 'لا توجد إعلانات منشورة في هذه الفترة.',
			'com.annonces.administration.publiees.pastille' => 'منشور',
			'com.annonces.administration.publiees.legende' => ({required Object cible, required Object date, required Object heure}) => '${cible} · يوم ${date} الساعة ${heure}',
			'com.annonces.administration.planifiees.titre' => 'الإعلانات المجدولة',
			'com.annonces.administration.planifiees.vide' => 'لا توجد إعلانات مجدولة.',
			'com.annonces.administration.planifiees.pastille' => 'مجدول',
			'com.annonces.administration.planifiees.legende' => ({required Object cible, required Object date, required Object heure}) => '${cible} · مقرر يوم ${date} الساعة ${heure}',
			'com.annonces.administration.matrice.titre' => 'صلاحيات نشر الإعلانات',
			'com.annonces.administration.matrice.detail' => 'قاعدة الأكاديمية، تُطبَّق على كل عملية نشر.',
			'com.annonces.administration.matrice.auteurs' => 'من ينشر',
			'com.annonces.administration.matrice.peutPublier' => 'يمكنه النشر',
			'com.annonces.administration.matrice.audiences' => 'المستلمون',
			'com.annonces.administration.matrice.validation' => 'يتطلب موافقة',
			'com.annonces.administration.matrice.oui' => 'نعم',
			'com.annonces.administration.matrice.non' => 'لا',
			'com.annonces.administration.matrice.aucune' => 'لا شيء',
			'com.annonces.administration.matrice.vide' => 'لم تُضبط أي صلاحية نشر.',
			'com.annonces.administration.moderation.titre' => 'قائمة الإشراف',
			'com.annonces.administration.moderation.legende' => ({required Object date, required Object heure}) => 'أُبلغ عنه يوم ${date} الساعة ${heure}',
			'com.annonces.administration.moderation.motif' => ({required Object motif}) => 'السبب: ${motif}',
			'com.annonces.administration.moderation.extraitTitre' => 'المحتوى المُبلغ عنه',
			'com.annonces.administration.moderation.extraitAbsent' => 'مقتطف هذا المحتوى غير متاح.',
			'com.annonces.administration.moderation.regle' => 'القاعدة المعنية',
			'com.annonces.administration.moderation.approuver' => 'الموافقة بعد الفحص',
			'com.annonces.administration.moderation.masquer' => 'إخفاء المحتوى',
			'com.annonces.administration.moderation.restaurer' => 'استعادة المحتوى',
			'com.annonces.administration.moderation.rejeter' => 'رفض البلاغ',
			'com.annonces.administration.moderation.contexte' => 'فتح السياق',
			'com.annonces.administration.moderation.masque' => 'مخفي',
			'com.annonces.administration.moderation.approuve' => 'تمت الموافقة',
			'com.annonces.administration.moderation.rejete' => 'رُفض البلاغ',
			'com.annonces.administration.moderation.restaure' => 'مستعاد',
			'com.annonces.administration.moderation.enregistree' => 'سُجل القرار.',
			'com.annonces.administration.moderation.nonConfirmee' => 'لم يُؤكَّد هذا القرار بعد. تحقق من الاتصال ثم أعد المحاولة.',
			'com.annonces.administration.moderation.horsLigne' => 'أنت غير متصل. لا يمكن تحديث قائمة الإشراف.',
			'com.annonces.administration.moderation.indisponible' => 'الإشراف غير متاح بعد. عد لاحقًا.',
			'com.annonces.administration.moderation.videTitre' => 'لا يوجد محتوى للفحص',
			'com.annonces.administration.moderation.vide' => 'تصل هنا بلاغات مجتمع المعلمين.',
			'com.annonces.administration.moderation.refuseTitre' => 'قائمة خاصة بالإشراف',
			'com.annonces.administration.moderation.refuse' => 'لا يرى هذه القائمة إلا المكلفون بالإشراف.',
			'com.annonces.administration.moderation.choisirTitre' => 'لا يوجد بلاغ مفتوح',
			'com.annonces.administration.moderation.choisir' => 'اختر بلاغًا من القائمة لفحصه.',
			'com.annonces.administration.moderation.sansAction' => 'لا يتاح لك أي إجراء إشراف على هذا المحتوى.',
			'com.annonces.administration.moderation.sansSanction' => 'لا تُطبق أي عقوبة على الحساب تلقائيًا.',
			'com.annonces.administration.moderation.politique' => 'سياسة منع الترويج',
			'com.annonces.administration.moderation.ouvrirSemantique' => ({required Object objet, required Object motif}) => 'فحص ${objet}‏، السبب ${motif}',
			'com.annonces.administration.moderation.regleMotif.publicite' => 'الإعلانات التجارية غير مسموح بها في مجتمع المعلّمين.',
			'com.annonces.administration.moderation.regleMotif.lienAffilie' => 'روابط التسويق بالعمولة غير مسموح بها في مجتمع المعلّمين.',
			'com.annonces.administration.moderation.regleMotif.vente' => 'بيع المنتجات أو الخدمات غير مسموح به في هذه المساحة.',
			'com.annonces.administration.moderation.regleMotif.sollicitation' => 'الاستدراج التجاري غير مسموح به في هذه المساحة.',
			'com.annonces.administration.moderation.regles.titre' => 'مشاركة تعليمية فقط',
			'com.annonces.administration.moderation.regles.corps' => 'مجتمع المعلّمين مخصّص للتبادل المهني بين المعلّمين.',
			'com.annonces.administration.moderation.regles.reglesTitre' => 'قواعد النشر',
			'com.annonces.administration.moderation.regles.pasPublicite' => 'لا إعلانات',
			'com.annonces.administration.moderation.regles.pasAffilie' => 'لا روابط تسويق بالعمولة',
			'com.annonces.administration.moderation.regles.pasVente' => 'لا بيع لمنتج أو خدمة',
			'com.annonces.administration.moderation.regles.pasSollicitation' => 'لا التماس تجاري',
			'com.annonces.administration.moderation.regles.pasDonnees' => 'لا بيانات شخصية لطالب أو عائلة',
			'com.annonces.demoPublication.lienAdministration' => 'إدارة التواصل (الإدارة)',
			'com.annonces.demoPublication.lienPublier' => 'نشر إعلان لفصل (المعلم)',
			'com.annonces.demoPublication.toutes' => 'الأكاديمية كلها',
			'com.annonces.demoPublication.familles' => 'الأسر',
			'com.annonces.demoPublication.enseignants' => 'المعلمون',
			'com.annonces.demoPublication.eleves' => 'الطلاب',
			'com.annonces.demoPublication.controleurs' => 'المراقبون',
			'com.annonces.demoPublication.direction' => 'الإدارة',
			'com.annonces.demoPublication.audiencesDirection' => 'الأكاديمية كلها، أو جمهور، أو فصل',
			'com.annonces.demoPublication.audiencesEnseignant' => 'فصله فقط',
			'com.annonces.demoPublication.vacancesTitre' => 'تقويم عطلة الشتاء',
			'com.annonces.demoPublication.vacancesTexte' => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.',
			'com.annonces.demoPublication.reunionTitre' => 'اجتماع المعلمين يوم الخميس',
			'com.annonces.demoPublication.reunionTexte' => 'يبدأ الاجتماع التربوي يوم الخميس الساعة 18، عبر الاتصال المرئي. جدول الأعمال في الاستوديو.',
			'com.annonces.demoPublication.recitationTitre' => 'تلاوة نهاية الفصل الدراسي',
			'com.annonces.demoPublication.recitationTexte' => 'سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت الساعة 10، عبر الاتصال المرئي.',
			'com.annonces.demoPublication.rentreeTitre' => 'استئناف الدروس بعد العطلة',
			'com.annonces.demoPublication.rentreeTexte' => 'تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.',
			'com.annonces.demoPublication.signalementAffilie' => 'منشور »بطاقات تجويد للطباعة«',
			'com.annonces.demoPublication.extraitAffilie' => 'تجدون بطاقاتي عبر هذا الرابط الشريك، خصم 20 % برمزي.',
			'com.annonces.demoPublication.signalementVente' => 'منشور »دروس خصوصية متاحة«',
			'com.annonces.demoPublication.extraitVente' => 'أقدم دروسًا خصوصية مدفوعة في عطلة نهاية الأسبوع، راسلوني.',
			'com.annonces.demoPublication.signalementHorsSujet' => 'رد تحت »تنظيم مراجعة جماعية«',
			'com.annonces.section' => 'إعلانات الفصل',
			'com.annonces.annonce' => 'إعلان',
			'com.annonces.publier' => 'نشر إعلان',
			'com.annonces.videPublier' => 'لا توجد إعلانات لهذا الفصل. انشر أول إعلان للفصل كله.',
			'com.annonces.auteurDate' => ({required Object auteur, required Object date, required Object heure}) => '${auteur}‏، يوم ${date} الساعة ${heure}',
			'com.annonces.date' => ({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}',
			'com.annonces.lire' => 'قراءة الإعلان كاملًا',
			'com.annonces.ouvrirClasse' => 'فتح الفصل',
			'com.annonces.ouvrirClasseSemantique' => ({required Object classe}) => 'فتح ${classe}',
			'com.annonces.marquerLue' => 'تحديد كمقروء',
			'com.annonces.lue' => 'مقروء',
			'com.annonces.carteSemantique' => ({required Object classe, required Object titre}) => 'إعلان ${classe}: ${titre}',
			'com.annonces.introuvableTitre' => 'هذا الإعلان لم يعد متاحًا',
			'com.annonces.introuvablePhrase' => 'ربما سُحب من الفصل. عد إلى إشعاراتك.',
			'com.annonces.demo.detail' => 'عرض تجريبي خارج الإنتاج: بيانات وهمية، ولا يُرسل شيء.',
			'com.annonces.demo.choisirRole' => 'اختر الدور المراد عرضه',
			'com.annonces.demo.roles.tuteur' => 'الأسرة',
			'com.annonces.demo.roles.enseignant' => 'المعلم',
			'com.annonces.demo.roles.adulte' => 'الطالب البالغ',
			'com.annonces.demo.roles.admin' => 'الإدارة',
			'com.annonces.demo.roles.controleur' => 'المراقب',
			'com.annonces.demo.classeNour' => 'فصل النور',
			'com.annonces.demo.classeFajr' => 'فصل الفجر',
			'com.annonces.demo.enseignante' => 'معلمة الفصل',
			'com.annonces.demo.f.adminStudioMention' => 'الاستوديو: نقاش في قناة البرامج يشير إليك',
			'com.annonces.demo.f.adminStudioReponse' => 'الاستوديو: رد جديد على رسالتك بشأن برنامج الربيع',
			'com.annonces.demo.f.adminStudioDecision' => 'الاستوديو: مطلوب قرار بشأن مادة الدرس 4',
			'com.annonces.demo.f.adminStudioAssigne' => 'الاستوديو: أُسندت إليك مراجعة مادة التجويد',
			'com.annonces.demo.f.adminStudioInterne' => 'إعلان داخلي لفريق الاستوديو: اجتماع الفريق يوم الخميس الساعة 18',
			'com.annonces.demo.f.adminStudioContexte' => 'الاستوديو: مادة جاهزة لفصل النور',
			'com.annonces.demo.f.annonceNourTitre' => 'تلاوة نهاية الفصل الدراسي أمام الأسر',
			'com.annonces.demo.f.annonceNourTexte' => 'أسرنا الكريمة، سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت 14 ديسمبر الساعة 10، عبر الاتصال المرئي. سيتلو كل طالب السورة التي عمل عليها خلال هذا الفصل الدراسي. يرجى تجهيز اتصال مستقر ومكان هادئ. يمكن للطلاب الراغبين التدرب خلال حصة الأربعاء السابقة. يمكن للأسر الحضور بصمت مع كتم الميكروفون. سيُشارك تقرير بعد الحصة.',
			'com.annonces.demo.f.annonceFajrTitre' => 'مراجعة قبل تقييم يوم الخميس',
			'com.annonces.demo.f.annonceFajrTexte' => 'راجعوا الآيات العشر الأخيرة من سورة الملك قبل يوم الخميس.',
			'com.annonces.demo.f.tuteurUrgent' => 'حصة هذا المساء ملغاة',
			'com.annonces.demo.f.tuteurUrgentTexte' => 'المعلمة غائبة هذا المساء. أُجّلت الحصة إلى يوم الخميس في الوقت نفسه. لا شيء عليك فعله.',
			'com.annonces.demo.f.tuteurReponse' => 'رد منتظر: الموافقة على تلاوة ياسمين',
			'com.annonces.demo.f.tuteurReponseTexte' => 'تنتظر المعلمة موافقتك لتتلو ياسمين أمام الأسر. أجبها من فضاء الفصل.',
			'com.annonces.demo.f.tuteurMessage' => 'رسالة جديدة من معلمة فصل النور',
			'com.annonces.demo.f.tuteurDossier' => 'تم قبول ملف التسجيل الخاص بك',
			'com.annonces.demo.f.adulteSeance' => 'نُقلت حصتك يوم الثلاثاء إلى الساعة 19',
			'com.annonces.demo.f.adulteMessage' => 'رسالة جديدة من معلمتك',
			'com.annonces.demo.f.enseignantFamille' => 'رسالة من أسرة ياسمين، فصل النور',
			'com.annonces.demo.f.enseignantDirection' => 'إعلان من الإدارة: جدول عطلة الشتاء',
			'com.annonces.demo.f.enseignantDirectionTexte' => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.',
			'com.annonces.demo.f.enseignantPlanning' => 'تغيّر جدولك للأسبوع القادم',
			'com.annonces.demo.f.enseignantMention' => 'منشور في مجتمع المعلمين يشير إليك',
			'com.annonces.demo.f.enseignantReponse' => 'رد جديد على منشورك',
			'com.annonces.demo.f.enseignantAdministration' => 'رسالة من الإدارة: وثائق مطلوبة',
			'com.annonces.demo.f.adminDossiers' => 'ثلاثة ملفات تسجيل في انتظار المعالجة',
			'com.annonces.demo.f.adminSignalement' => 'تم الإبلاغ عن منشور في مجتمع المعلمين',
			'com.annonces.demo.f.adminReponse' => 'رد أسرة بلال على رسالتك',
			'com.annonces.demo.f.adminPlanifiee' => 'إعلان مجدول يحتاج إلى مراجعة قبل النشر',
			'com.annonces.demo.f.adminOperationnel' => 'فصل النور: العدد مكتمل',
			'com.annonces.demo.f.controleurMission' => 'مهمة جديدة: زيارة فصل النور',
			'com.annonces.demo.f.controleurChangement' => 'نُقلت مهمتك يوم الخميس إلى الساعة 18',
			'com.annonces.demo.f.controleurReponse' => 'رد الإدارة على تقريرك',
			'com.annonces.titre' => 'الإعلانات',
			_ => null,
		};
	}
}
