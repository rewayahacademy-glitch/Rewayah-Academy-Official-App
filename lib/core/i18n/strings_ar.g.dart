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
	@override late final _Traductions$commun$ar commun = _Traductions$commun$ar._(_root);
	@override late final _Traductions$etat$ar etat = _Traductions$etat$ar._(_root);
	@override late final _Traductions$classe$ar classe = _Traductions$classe$ar._(_root);
	@override late final _Traductions$salle$ar salle = _Traductions$salle$ar._(_root);
	@override late final _Traductions$eleve$ar eleve = _Traductions$eleve$ar._(_root);
	@override late final _Traductions$enseignant$ar enseignant = _Traductions$enseignant$ar._(_root);
	@override late final _Traductions$compte$ar compte = _Traductions$compte$ar._(_root);
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
	@override String ligne({required Object titre, required Object date, required Object heure}) => '${titre}، يوم ${date} الساعة ${heure}';
	@override late final _Traductions$notifications$filtres$ar filtres = _Traductions$notifications$filtres$ar._(_root);
	@override String get filtreVideTitre => 'لا توجد إشعارات في هذا التصنيف';
	@override String get filtreVidePhrase => 'اختر « الكل » لرؤية جميع إشعاراتك من جديد.';
	@override String get voirToutes => 'عرض كل الإشعارات';
	@override String get nonLue => 'غير مقروء';
	@override String get nonLueSemantique => 'غير مقروء';
	@override String get lectureNonConfirmee => 'لم تُؤكَّد القراءة بعد. أعد المحاولة بعد قليل.';
	@override late final _Traductions$notifications$detail$ar detail = _Traductions$notifications$detail$ar._(_root);
	@override late final _Traductions$notifications$types$ar types = _Traductions$notifications$types$ar._(_root);
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
	@override String get reponseFil => 'رد على محادثة';
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
	@override String get titre => _root.com.socle.lexique.messagesMetier;
	@override String get vide => 'لا توجد محادثات حاليًا.';
}

// Path: com.vocal
class _Traductions$com$vocal$ar extends Traductions$com$vocal$fr {
	_Traductions$com$vocal$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
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
	@override String auteurDate({required Object auteur, required Object date, required Object heure}) => '${auteur}، يوم ${date} الساعة ${heure}';
	@override String date({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}';
	@override String get lire => 'قراءة الإعلان كاملًا';
	@override String get ouvrirClasse => 'فتح الفصل';
	@override String ouvrirClasseSemantique({required Object classe}) => 'فتح ${classe}';
	@override String get marquerLue => 'تحديد كمقروء';
	@override String get lue => 'مقروء';
	@override String carteSemantique({required Object classe, required Object titre}) => 'إعلان ${classe} : ${titre}';
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

// Path: com.socle.composants
class _Traductions$com$socle$composants$ar extends Traductions$com$socle$composants$fr {
	_Traductions$com$socle$composants$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
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
	@override String semantique({required Object adresse, required Object etat}) => '${adresse}، ${etat}';
}

// Path: com.communaute.flux
class _Traductions$com$communaute$flux$ar extends Traductions$com$communaute$flux$fr {
	_Traductions$com$communaute$flux$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String ouvrir({required Object titre}) => 'فتح المنشور ${titre}';
	@override String get reponseUne => 'ردّ واحد';
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
	@override String get fermer => 'إغلاق البحث';
}

// Path: com.communaute.moment
class _Traductions$com$communaute$moment$ar extends Traductions$com$communaute$moment$fr {
	_Traductions$com$communaute$moment$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get instant => 'الآن';
	@override String minutes({required Object nombre}) => 'منذ ${nombre} دقيقة';
	@override String heures({required Object nombre}) => 'منذ ${nombre} ساعة';
	@override String jours({required Object nombre}) => 'منذ ${nombre} يوم';
	@override String date({required Object jour, required Object mois}) => 'في ${jour}/${mois}';
}

// Path: com.communaute.publication
class _Traductions$com$communaute$publication$ar extends Traductions$com$communaute$publication$fr {
	_Traductions$com$communaute$publication$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String auteur({required Object fonction, required Object moment}) => '${fonction}، ${moment}';
	@override String get enregistrer => 'حفظ المنشور';
	@override String get enregistree => 'منشور محفوظ';
	@override String get retirer => 'إزالة من العناصر المحفوظة';
	@override String menu({required Object titre}) => 'إجراءات على المنشور ${titre}';
	@override String get signaler => 'الإبلاغ عن المنشور';
	@override String get signalee => 'تم الإبلاغ عن المحتوى إلى فريق الإشراف.';
	@override String get choisirTitre => 'لا يوجد منشور مفتوح';
	@override String get choisir => 'اختر منشورًا من القائمة لقراءته والردّ عليه.';
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
	@override String get champ => 'ردّك';
	@override String get aide => 'اكتب ردًّا';
	@override String get envoyer => 'إرسال الردّ';
	@override String get champVide => 'اكتب ردًّا لإرساله.';
	@override String get enCours => 'جارٍ الإرسال';
	@override String get nonConfirmee => 'لم يُؤكَّد هذا الردّ بعد.';
	@override String get reessayer => 'إعادة إرسال الردّ';
	@override String get indisponible => 'الردود غير متاحة هنا بعد.';
	@override String menu({required Object nom}) => 'إجراءات على ردّ ${nom}';
	@override String get signaler => 'الإبلاغ عن الردّ';
	@override String get signalee => 'لقد أبلغت عن هذا الردّ.';
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
	@override String get choisir => 'اختر حالة لتجربتها داخل واجهة المعلّم.';
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
	@override String get programmer => 'برمجة الإعلان';
	@override String get reessayer => 'إعادة محاولة النشر';
	@override String get terminer => 'إنهاء';
	@override String get manqueContenu => 'اكتب عنوانًا ونصًا للمتابعة.';
	@override String get manqueAudience => 'اختر جمهورًا للمتابعة.';
	@override String get enCours => 'النشر جارٍ. انتظر التأكيد.';
	@override String get publiee => 'نُشر الإعلان. يستلمه المستلمون.';
	@override String planifiee({required Object date, required Object heure}) => 'بُرمج الإعلان ليوم ${date} الساعة ${heure}.';
	@override String get nonConfirmee => 'لم يُؤكَّد هذا الإعلان بعد. تحقق من الاتصال ثم أعد المحاولة : لن يُرسل إلا مرة واحدة.';
	@override String get horsLigne => 'أنت غير متصل : لم يُؤكَّد هذا الإعلان بعد. أعد الاتصال ثم أعد المحاولة.';
	@override String get indisponible => 'نشر الإعلانات غير متاح بعد. عد لاحقًا.';
	@override String get aucuneCibleTitre => 'لا يوجد جمهور متاح';
	@override String get aucuneCible => 'لا يمكنك النشر لأي جمهور حاليًا. اطلب الإذن من الإدارة.';
}

// Path: com.annonces.administration
class _Traductions$com$annonces$administration$ar extends Traductions$com$annonces$administration$fr {
	_Traductions$com$annonces$administration$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nouvelle => 'إعلان جديد';
	@override String get demo => 'عرض تجريبي';
	@override String get demoDetail => 'بيانات تجريبية : لا رقم حقيقي.';
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
	@override String get toutes => 'المدرسة كلها';
	@override String get familles => 'الأسر';
	@override String get enseignants => 'المعلمون';
	@override String get eleves => 'الطلاب';
	@override String get controleurs => 'المراقبون';
	@override String get direction => 'الإدارة';
	@override String get audiencesDirection => 'المدرسة كلها، أو جمهور، أو فصل';
	@override String get audiencesEnseignant => 'فصله فقط';
	@override String get vacancesTitre => 'تقويم عطلة الشتاء';
	@override String get vacancesTexte => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.';
	@override String get reunionTitre => 'اجتماع المعلمين يوم الخميس';
	@override String get reunionTexte => 'يبدأ الاجتماع التربوي يوم الخميس الساعة 18، عبر الاتصال المرئي. جدول الأعمال في الاستوديو.';
	@override String get recitationTitre => 'تلاوة نهاية الفصل الدراسي';
	@override String get recitationTexte => 'سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت الساعة 10، عبر الاتصال المرئي.';
	@override String get rentreeTitre => 'استئناف الدروس بعد العطلة';
	@override String get rentreeTexte => 'تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.';
	@override String get signalementAffilie => 'منشور « بطاقات تجويد للطباعة »';
	@override String get extraitAffilie => 'تجدون بطاقاتي عبر هذا الرابط الشريك، خصم 20 % برمزي.';
	@override String get signalementVente => 'منشور « دروس خصوصية متاحة »';
	@override String get extraitVente => 'أقدم دروسًا خصوصية مدفوعة في عطلة نهاية الأسبوع، راسلوني.';
	@override String get signalementHorsSujet => 'رد تحت « تنظيم مراجعة جماعية »';
}

// Path: com.annonces.demo
class _Traductions$com$annonces$demo$ar extends Traductions$com$annonces$demo$fr {
	_Traductions$com$annonces$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get detail => 'عرض تجريبي خارج الإنتاج : بيانات وهمية، ولا يُرسل شيء.';
	@override String get choisirRole => 'اختر الدور المراد عرضه';
	@override late final _Traductions$com$annonces$demo$roles$ar roles = _Traductions$com$annonces$demo$roles$ar._(_root);
	@override String get classeNour => 'فصل النور';
	@override String get classeFajr => 'فصل الفجر';
	@override String get enseignante => 'معلمة الفصل';
	@override late final _Traductions$com$annonces$demo$f$ar f = _Traductions$com$annonces$demo$f$ar._(_root);
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
	@override String get administrationTitre => 'الاتصالات';
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

// Path: com.communaute.signalement.politique
class _Traductions$com$communaute$signalement$politique$ar extends Traductions$com$communaute$signalement$politique$fr {
	_Traductions$com$communaute$signalement$politique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get publicite => 'الإعلانات التجارية غير مسموح بها في مجتمع المعلّمين.';
	@override String get sollicitation => 'الاستدراج التجاري غير مسموح به في هذه المساحة.';
}

// Path: com.annonces.publieur.etapes
class _Traductions$com$annonces$publieur$etapes$ar extends Traductions$com$annonces$publieur$etapes$fr {
	_Traductions$com$annonces$publieur$etapes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get contenu => 'محتوى الإعلان';
	@override String get audience => 'جمهور الإعلان';
	@override String get programmation => 'تاريخ النشر';
	@override String get previsualisation => 'معاينة الإعلان';
	@override String get publication => 'نشر الإعلان';
}

// Path: com.annonces.publieur.contexte
class _Traductions$com$annonces$publieur$contexte$ar extends Traductions$com$annonces$publieur$contexte$fr {
	_Traductions$com$annonces$publieur$contexte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get contenu => 'اكتب ما يجب أن يعرفه المستلمون. الإعلان في اتجاه واحد : لا أحد يرد عليه.';
	@override String get audience => 'اختر من يستلم الإعلان. لا تُعرض إلا الجماهير التي يمكنك استهدافها.';
	@override String audienceFixee({required Object cible}) => 'يُرسل هذا الإعلان إلى ${cible}. أنت تنشر لفصلك فقط.';
	@override String get programmation => 'اختر متى يُرسل الإعلان. الإعلان المبرمج ينتظر تاريخه.';
	@override String get previsualisation => 'هذا هو الإعلان كما سيقرؤه المستلمون.';
	@override String get publication => 'راجع الجمهور والتاريخ، ثم انشر. لا يُنشر شيء قبل التأكيد.';
}

// Path: com.annonces.publieur.nature
class _Traductions$com$annonces$publieur$nature$ar extends Traductions$com$annonces$publieur$nature$fr {
	_Traductions$com$annonces$publieur$nature$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get classe => 'تستلمه أسر هذا الفصل وطلابه فقط.';
	@override String get public => 'يستلمه كل أفراد هذا الجمهور.';
	@override String get toutes => 'تستلمه المدرسة كلها. خصصه لما يهم الجميع.';
}

// Path: com.annonces.publieur.quand
class _Traductions$com$annonces$publieur$quand$ar extends Traductions$com$annonces$publieur$quand$fr {
	_Traductions$com$annonces$publieur$quand$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get maintenant => 'فور التأكيد';
	@override String get maintenantDetail => 'يُرسل الإعلان فور تأكيد النشر.';
	@override String creneau({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}';
	@override String get creneauDetail => 'ينتظر الإعلان هذا التاريخ. ستجده في الإعلانات المبرمجة.';
}

// Path: com.annonces.publieur.apercu
class _Traductions$com$annonces$publieur$apercu$ar extends Traductions$com$annonces$publieur$apercu$fr {
	_Traductions$com$annonces$publieur$apercu$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String a({required Object cible}) => 'إلى : ${cible}';
	@override String get diffusionMaintenant => 'النشر : فور التأكيد';
	@override String diffusionLe({required Object date, required Object heure}) => 'النشر المقرر يوم ${date} الساعة ${heure}';
}

// Path: com.annonces.administration.indicateurs
class _Traductions$com$annonces$administration$indicateurs$ar extends Traductions$com$annonces$administration$indicateurs$fr {
	_Traductions$com$annonces$administration$indicateurs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مؤشرات التواصل';
	@override String get publiees => 'الإعلانات المنشورة';
	@override String get planifiees => 'الإعلانات المبرمجة';
	@override String get moderation => 'محتويات قيد الإشراف';
	@override String get regles => 'قواعد النطاق';
	@override String indisponible({required Object libelle}) => '${libelle} : غير متاح بعد';
	@override String echec({required Object libelle}) => '${libelle} : تعذرت القراءة، حدّث الصفحة';
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
	@override String get titre => 'الإعلانات المبرمجة';
	@override String get vide => 'لا توجد إعلانات مبرمجة.';
	@override String get pastille => 'مبرمج';
	@override String legende({required Object cible, required Object date, required Object heure}) => '${cible} · مقرر يوم ${date} الساعة ${heure}';
}

// Path: com.annonces.administration.matrice
class _Traductions$com$annonces$administration$matrice$ar extends Traductions$com$annonces$administration$matrice$fr {
	_Traductions$com$annonces$administration$matrice$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'قواعد النطاق والصلاحيات';
	@override String get detail => 'قاعدة المدرسة، تُطبق على كل نشر.';
	@override String get auteurs => 'من ينشر';
	@override String get peutPublier => 'يمكنه النشر';
	@override String get audiences => 'الجماهير';
	@override String get validation => 'يتطلب موافقة';
	@override String get oui => 'نعم';
	@override String get non => 'لا';
	@override String get aucune => 'لا شيء';
	@override String get vide => 'لا توجد قواعد نطاق مُعدّة.';
}

// Path: com.annonces.administration.moderation
class _Traductions$com$annonces$administration$moderation$ar extends Traductions$com$annonces$administration$moderation$fr {
	_Traductions$com$annonces$administration$moderation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'قائمة الإشراف';
	@override String legende({required Object date, required Object heure}) => 'أُبلغ عنه يوم ${date} الساعة ${heure}';
	@override String motif({required Object motif}) => 'السبب : ${motif}';
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
	@override String ouvrirSemantique({required Object objet, required Object motif}) => 'فحص ${objet}، السبب ${motif}';
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
	@override String get adminStudioMention => 'الاستوديو : نقاش في قناة البرامج يشير إليك';
	@override String get adminStudioReponse => 'الاستوديو : رد جديد على رسالتك بشأن برنامج الربيع';
	@override String get adminStudioDecision => 'الاستوديو : مطلوب قرار بشأن دعامة الدرس 4';
	@override String get adminStudioAssigne => 'الاستوديو : أُسندت إليك مراجعة دعامة التجويد';
	@override String get adminStudioInterne => 'إعلان داخلي لفريق الاستوديو : اجتماع الفريق يوم الخميس الساعة 18';
	@override String get adminStudioContexte => 'الاستوديو : دعامة جاهزة لفصل النور';
	@override String get annonceNourTitre => 'تلاوة نهاية الفصل الدراسي أمام الأسر';
	@override String get annonceNourTexte => 'أسرنا الكريمة، سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت 14 ديسمبر الساعة 10، عبر الاتصال المرئي. سيتلو كل طالب السورة التي عمل عليها هذا الفصل. يرجى تجهيز اتصال مستقر ومكان هادئ. يمكن للطلاب الراغبين التدرب خلال حصة الأربعاء السابقة. يمكن للأسر الحضور بصمت مع كتم الميكروفون. سيُشارك تقرير بعد الحصة.';
	@override String get annonceFajrTitre => 'مراجعة قبل تقييم يوم الخميس';
	@override String get annonceFajrTexte => 'راجعوا الآيات العشر الأخيرة من سورة الملك قبل يوم الخميس.';
	@override String get tuteurUrgent => 'حصة هذا المساء ملغاة';
	@override String get tuteurUrgentTexte => 'المعلمة غائبة هذا المساء. أُجّلت الحصة إلى يوم الخميس في الوقت نفسه. لا شيء عليك فعله.';
	@override String get tuteurReponse => 'رد منتظر : الموافقة على تلاوة ياسمين';
	@override String get tuteurReponseTexte => 'تنتظر المعلمة موافقتك لتتلو ياسمين أمام الأسر. أجبها من فضاء الفصل.';
	@override String get tuteurMessage => 'رسالة جديدة من معلمة فصل النور';
	@override String get tuteurDossier => 'تم قبول ملف التسجيل الخاص بك';
	@override String get adulteSeance => 'نُقلت حصتك يوم الثلاثاء إلى الساعة 19';
	@override String get adulteMessage => 'رسالة جديدة من معلمتك';
	@override String get enseignantFamille => 'رسالة من أسرة ياسمين، فصل النور';
	@override String get enseignantDirection => 'إعلان من الإدارة : جدول عطلة الشتاء';
	@override String get enseignantDirectionTexte => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.';
	@override String get enseignantPlanning => 'تغيّر جدولك للأسبوع القادم';
	@override String get enseignantMention => 'منشور في مجتمع المعلمين يشير إليك';
	@override String get enseignantReponse => 'رد جديد على منشورك';
	@override String get enseignantAdministration => 'رسالة من الإدارة : وثائق مطلوبة';
	@override String get adminDossiers => 'ثلاثة ملفات تسجيل في انتظار المعالجة';
	@override String get adminSignalement => 'تم الإبلاغ عن منشور في مجتمع المعلمين';
	@override String get adminReponse => 'رد أسرة بلال على رسالتك';
	@override String get adminPlanifiee => 'إعلان مجدول يحتاج إلى مراجعة قبل النشر';
	@override String get adminOperationnel => 'فصل النور : العدد مكتمل';
	@override String get controleurMission => 'مهمة جديدة : زيارة فصل النور';
	@override String get controleurChangement => 'نُقلت مهمتك يوم الخميس إلى الساعة 18';
	@override String get controleurReponse => 'رد الإدارة على تقريرك';
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
			'notifications.ligne' => ({required Object titre, required Object date, required Object heure}) => '${titre}، يوم ${date} الساعة ${heure}',
			'notifications.filtres.libelle' => 'تصفية الإشعارات',
			'notifications.filtres.toutes' => 'الكل',
			'notifications.filtres.nonLues' => 'غير المقروءة',
			'notifications.filtres.mentions' => 'الإشارات',
			'notifications.filtres.actionRequise' => 'إجراء مطلوب',
			'notifications.filtreVideTitre' => 'لا توجد إشعارات في هذا التصنيف',
			'notifications.filtreVidePhrase' => 'اختر « الكل » لرؤية جميع إشعاراتك من جديد.',
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
			'notifications.types.reponseFil' => 'رد على محادثة',
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
			'com.socle.composants.etats.chargement' => 'جارٍ التحميل',
			'com.socle.composants.etats.videTitre' => 'لا شيء هنا حاليًا',
			'com.socle.composants.etats.erreurTitre' => 'تعذّر تحميل هذا المحتوى.',
			'com.socle.composants.etats.erreur' => 'تحقّق من اتصالك ثم أعد المحاولة.',
			'com.socle.composants.etats.reessayer' => 'إعادة المحاولة',
			'com.socle.composants.etats.horsLigne' => 'أنت غير متصل. لا يمكن تحديث الرسائل الجديدة.',
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
			'com.socle.navigation.provisoire.administrationTitre' => 'الاتصالات',
			'com.socle.navigation.provisoire.administrationDetail' => 'ستُدار الإعلانات والإشراف والرسائل من هنا قريبًا.',
			'com.socle.navigation.provisoire.publierAnnonceTitre' => 'نشر إعلان',
			'com.socle.navigation.provisoire.publierAnnonceDetail' => 'سيصل نشر إعلان لفصل ما إلى هنا قريبًا.',
			'com.socle.navigation.demo.titre' => 'عرض توضيحي للاتصالات',
			'com.socle.navigation.demo.detail' => 'بيانات وهمية، غير موجودة في نسخ الإنتاج.',
			'com.socle.navigation.demo.choisir' => 'اختر مساحة لتجربتها.',
			'com.messages.titre' => _root.com.socle.lexique.messagesMetier,
			'com.messages.vide' => 'لا توجد محادثات حاليًا.',
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
			'com.communaute.lien.interne' => 'رابط داخلي في رواية',
			'com.communaute.lien.ressourceExterne' => 'مورد تعليمي خارجي',
			'com.communaute.lien.commercialInterdit' => 'رابط تجاري ممنوع',
			'com.communaute.lien.nonVerifie' => 'رابط غير مُتحقَّق منه',
			'com.communaute.lien.semantique' => ({required Object adresse, required Object etat}) => '${adresse}، ${etat}',
			'com.communaute.sousTitre' => 'تبادل وتعاون بين المعلّمين',
			'com.communaute.sections' => 'فئات مجتمع المعلّمين',
			'com.communaute.toutes' => 'الكل',
			'com.communaute.videTitre' => 'لا توجد منشورات',
			'com.communaute.rechercheVideTitre' => 'لا توجد نتائج',
			'com.communaute.rechercheVide' => 'لا يوجد منشور يطابق بحثك. جرّب كلمة أخرى.',
			'com.communaute.videToutes' => 'لا توجد منشورات حاليًا.',
			'com.communaute.flux.ouvrir' => ({required Object titre}) => 'فتح المنشور ${titre}',
			'com.communaute.flux.reponseUne' => 'ردّ واحد',
			'com.communaute.flux.reponses' => ({required Object nombre}) => '${nombre} ردود',
			'com.communaute.flux.aucuneReponse' => 'لا توجد ردود',
			'com.communaute.flux.categorie' => ({required Object categorie}) => 'الفئة ${categorie}',
			'com.communaute.recherche.ouvrir' => 'البحث عن منشور',
			'com.communaute.recherche.champ' => 'البحث عن منشور',
			'com.communaute.recherche.aide' => 'كلمة من العنوان أو النص',
			'com.communaute.recherche.fermer' => 'إغلاق البحث',
			'com.communaute.moment.instant' => 'الآن',
			'com.communaute.moment.minutes' => ({required Object nombre}) => 'منذ ${nombre} دقيقة',
			'com.communaute.moment.heures' => ({required Object nombre}) => 'منذ ${nombre} ساعة',
			'com.communaute.moment.jours' => ({required Object nombre}) => 'منذ ${nombre} يوم',
			'com.communaute.moment.date' => ({required Object jour, required Object mois}) => 'في ${jour}/${mois}',
			'com.communaute.publication.auteur' => ({required Object fonction, required Object moment}) => '${fonction}، ${moment}',
			'com.communaute.publication.enregistrer' => 'حفظ المنشور',
			'com.communaute.publication.enregistree' => 'منشور محفوظ',
			'com.communaute.publication.retirer' => 'إزالة من العناصر المحفوظة',
			'com.communaute.publication.menu' => ({required Object titre}) => 'إجراءات على المنشور ${titre}',
			'com.communaute.publication.signaler' => 'الإبلاغ عن المنشور',
			'com.communaute.publication.signalee' => 'تم الإبلاغ عن المحتوى إلى فريق الإشراف.',
			'com.communaute.publication.choisirTitre' => 'لا يوجد منشور مفتوح',
			'com.communaute.publication.choisir' => 'اختر منشورًا من القائمة لقراءته والردّ عليه.',
			'com.communaute.publication.introuvableTitre' => 'المنشور غير متاح',
			'com.communaute.publication.introuvable' => 'تمت إزالة هذا المنشور أو لم يعد متاحًا لك. عد إلى المنشورات لاختيار منشور آخر.',
			'com.communaute.publication.revenir' => 'العودة إلى المنشورات',
			'com.communaute.reponses.titre' => ({required Object nombre}) => 'الردود (${nombre})',
			'com.communaute.reponses.vide' => 'لا توجد ردود حاليًا.',
			'com.communaute.reponses.erreurTitre' => 'تعذّر تحميل الردود.',
			'com.communaute.reponses.champ' => 'ردّك',
			'com.communaute.reponses.aide' => 'اكتب ردًّا',
			'com.communaute.reponses.envoyer' => 'إرسال الردّ',
			'com.communaute.reponses.champVide' => 'اكتب ردًّا لإرساله.',
			'com.communaute.reponses.enCours' => 'جارٍ الإرسال',
			'com.communaute.reponses.nonConfirmee' => 'لم يُؤكَّد هذا الردّ بعد.',
			'com.communaute.reponses.reessayer' => 'إعادة إرسال الردّ',
			'com.communaute.reponses.indisponible' => 'الردود غير متاحة هنا بعد.',
			'com.communaute.reponses.menu' => ({required Object nom}) => 'إجراءات على ردّ ${nom}',
			'com.communaute.reponses.signaler' => 'الإبلاغ عن الردّ',
			'com.communaute.reponses.signalee' => 'لقد أبلغت عن هذا الردّ.',
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
			'com.communaute.demo.choisir' => 'اختر حالة لتجربتها داخل واجهة المعلّم.',
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
			'com.communaute.titre' => _root.com.socle.lexique.communaute,
			'com.communaute.vide' => 'لا توجد منشورات في هذه الفئة.',
			'com.studio.titre' => _root.com.socle.lexique.studio,
			'com.studio.vide' => 'لا يوجد نشاط للمعالجة هنا.',
			'com.annonces.publieur.titre' => 'إعلان جديد',
			'com.annonces.publieur.etapes.contenu' => 'محتوى الإعلان',
			'com.annonces.publieur.etapes.audience' => 'جمهور الإعلان',
			'com.annonces.publieur.etapes.programmation' => 'تاريخ النشر',
			'com.annonces.publieur.etapes.previsualisation' => 'معاينة الإعلان',
			'com.annonces.publieur.etapes.publication' => 'نشر الإعلان',
			'com.annonces.publieur.contexte.contenu' => 'اكتب ما يجب أن يعرفه المستلمون. الإعلان في اتجاه واحد : لا أحد يرد عليه.',
			'com.annonces.publieur.contexte.audience' => 'اختر من يستلم الإعلان. لا تُعرض إلا الجماهير التي يمكنك استهدافها.',
			'com.annonces.publieur.contexte.audienceFixee' => ({required Object cible}) => 'يُرسل هذا الإعلان إلى ${cible}. أنت تنشر لفصلك فقط.',
			'com.annonces.publieur.contexte.programmation' => 'اختر متى يُرسل الإعلان. الإعلان المبرمج ينتظر تاريخه.',
			'com.annonces.publieur.contexte.previsualisation' => 'هذا هو الإعلان كما سيقرؤه المستلمون.',
			'com.annonces.publieur.contexte.publication' => 'راجع الجمهور والتاريخ، ثم انشر. لا يُنشر شيء قبل التأكيد.',
			'com.annonces.publieur.champTitre' => 'عنوان الإعلان',
			'com.annonces.publieur.champTexte' => 'نص الإعلان',
			'com.annonces.publieur.nature.classe' => 'تستلمه أسر هذا الفصل وطلابه فقط.',
			'com.annonces.publieur.nature.public' => 'يستلمه كل أفراد هذا الجمهور.',
			'com.annonces.publieur.nature.toutes' => 'تستلمه المدرسة كلها. خصصه لما يهم الجميع.',
			'com.annonces.publieur.quand.maintenant' => 'فور التأكيد',
			'com.annonces.publieur.quand.maintenantDetail' => 'يُرسل الإعلان فور تأكيد النشر.',
			'com.annonces.publieur.quand.creneau' => ({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}',
			'com.annonces.publieur.quand.creneauDetail' => 'ينتظر الإعلان هذا التاريخ. ستجده في الإعلانات المبرمجة.',
			'com.annonces.publieur.apercu.a' => ({required Object cible}) => 'إلى : ${cible}',
			'com.annonces.publieur.apercu.diffusionMaintenant' => 'النشر : فور التأكيد',
			'com.annonces.publieur.apercu.diffusionLe' => ({required Object date, required Object heure}) => 'النشر المقرر يوم ${date} الساعة ${heure}',
			'com.annonces.publieur.continuer' => 'متابعة',
			'com.annonces.publieur.publier' => 'نشر الإعلان',
			'com.annonces.publieur.programmer' => 'برمجة الإعلان',
			'com.annonces.publieur.reessayer' => 'إعادة محاولة النشر',
			'com.annonces.publieur.terminer' => 'إنهاء',
			'com.annonces.publieur.manqueContenu' => 'اكتب عنوانًا ونصًا للمتابعة.',
			'com.annonces.publieur.manqueAudience' => 'اختر جمهورًا للمتابعة.',
			'com.annonces.publieur.enCours' => 'النشر جارٍ. انتظر التأكيد.',
			'com.annonces.publieur.publiee' => 'نُشر الإعلان. يستلمه المستلمون.',
			'com.annonces.publieur.planifiee' => ({required Object date, required Object heure}) => 'بُرمج الإعلان ليوم ${date} الساعة ${heure}.',
			'com.annonces.publieur.nonConfirmee' => 'لم يُؤكَّد هذا الإعلان بعد. تحقق من الاتصال ثم أعد المحاولة : لن يُرسل إلا مرة واحدة.',
			'com.annonces.publieur.horsLigne' => 'أنت غير متصل : لم يُؤكَّد هذا الإعلان بعد. أعد الاتصال ثم أعد المحاولة.',
			'com.annonces.publieur.indisponible' => 'نشر الإعلانات غير متاح بعد. عد لاحقًا.',
			'com.annonces.publieur.aucuneCibleTitre' => 'لا يوجد جمهور متاح',
			'com.annonces.publieur.aucuneCible' => 'لا يمكنك النشر لأي جمهور حاليًا. اطلب الإذن من الإدارة.',
			'com.annonces.administration.nouvelle' => 'إعلان جديد',
			'com.annonces.administration.demo' => 'عرض تجريبي',
			'com.annonces.administration.demoDetail' => 'بيانات تجريبية : لا رقم حقيقي.',
			'com.annonces.administration.indicateurs.titre' => 'مؤشرات التواصل',
			'com.annonces.administration.indicateurs.publiees' => 'الإعلانات المنشورة',
			'com.annonces.administration.indicateurs.planifiees' => 'الإعلانات المبرمجة',
			'com.annonces.administration.indicateurs.moderation' => 'محتويات قيد الإشراف',
			'com.annonces.administration.indicateurs.regles' => 'قواعد النطاق',
			'com.annonces.administration.indicateurs.indisponible' => ({required Object libelle}) => '${libelle} : غير متاح بعد',
			'com.annonces.administration.indicateurs.echec' => ({required Object libelle}) => '${libelle} : تعذرت القراءة، حدّث الصفحة',
			'com.annonces.administration.publiees.titre' => 'الإعلانات المنشورة',
			'com.annonces.administration.publiees.vide' => 'لا توجد إعلانات منشورة في هذه الفترة.',
			'com.annonces.administration.publiees.pastille' => 'منشور',
			'com.annonces.administration.publiees.legende' => ({required Object cible, required Object date, required Object heure}) => '${cible} · يوم ${date} الساعة ${heure}',
			'com.annonces.administration.planifiees.titre' => 'الإعلانات المبرمجة',
			'com.annonces.administration.planifiees.vide' => 'لا توجد إعلانات مبرمجة.',
			'com.annonces.administration.planifiees.pastille' => 'مبرمج',
			'com.annonces.administration.planifiees.legende' => ({required Object cible, required Object date, required Object heure}) => '${cible} · مقرر يوم ${date} الساعة ${heure}',
			'com.annonces.administration.matrice.titre' => 'قواعد النطاق والصلاحيات',
			'com.annonces.administration.matrice.detail' => 'قاعدة المدرسة، تُطبق على كل نشر.',
			'com.annonces.administration.matrice.auteurs' => 'من ينشر',
			'com.annonces.administration.matrice.peutPublier' => 'يمكنه النشر',
			'com.annonces.administration.matrice.audiences' => 'الجماهير',
			'com.annonces.administration.matrice.validation' => 'يتطلب موافقة',
			'com.annonces.administration.matrice.oui' => 'نعم',
			'com.annonces.administration.matrice.non' => 'لا',
			'com.annonces.administration.matrice.aucune' => 'لا شيء',
			'com.annonces.administration.matrice.vide' => 'لا توجد قواعد نطاق مُعدّة.',
			'com.annonces.administration.moderation.titre' => 'قائمة الإشراف',
			'com.annonces.administration.moderation.legende' => ({required Object date, required Object heure}) => 'أُبلغ عنه يوم ${date} الساعة ${heure}',
			'com.annonces.administration.moderation.motif' => ({required Object motif}) => 'السبب : ${motif}',
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
			'com.annonces.administration.moderation.ouvrirSemantique' => ({required Object objet, required Object motif}) => 'فحص ${objet}، السبب ${motif}',
			'com.annonces.demoPublication.lienAdministration' => 'إدارة التواصل (الإدارة)',
			'com.annonces.demoPublication.lienPublier' => 'نشر إعلان لفصل (المعلم)',
			'com.annonces.demoPublication.toutes' => 'المدرسة كلها',
			'com.annonces.demoPublication.familles' => 'الأسر',
			'com.annonces.demoPublication.enseignants' => 'المعلمون',
			'com.annonces.demoPublication.eleves' => 'الطلاب',
			'com.annonces.demoPublication.controleurs' => 'المراقبون',
			'com.annonces.demoPublication.direction' => 'الإدارة',
			'com.annonces.demoPublication.audiencesDirection' => 'المدرسة كلها، أو جمهور، أو فصل',
			'com.annonces.demoPublication.audiencesEnseignant' => 'فصله فقط',
			'com.annonces.demoPublication.vacancesTitre' => 'تقويم عطلة الشتاء',
			'com.annonces.demoPublication.vacancesTexte' => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.',
			'com.annonces.demoPublication.reunionTitre' => 'اجتماع المعلمين يوم الخميس',
			'com.annonces.demoPublication.reunionTexte' => 'يبدأ الاجتماع التربوي يوم الخميس الساعة 18، عبر الاتصال المرئي. جدول الأعمال في الاستوديو.',
			'com.annonces.demoPublication.recitationTitre' => 'تلاوة نهاية الفصل الدراسي',
			'com.annonces.demoPublication.recitationTexte' => 'سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت الساعة 10، عبر الاتصال المرئي.',
			'com.annonces.demoPublication.rentreeTitre' => 'استئناف الدروس بعد العطلة',
			'com.annonces.demoPublication.rentreeTexte' => 'تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.',
			'com.annonces.demoPublication.signalementAffilie' => 'منشور « بطاقات تجويد للطباعة »',
			'com.annonces.demoPublication.extraitAffilie' => 'تجدون بطاقاتي عبر هذا الرابط الشريك، خصم 20 % برمزي.',
			'com.annonces.demoPublication.signalementVente' => 'منشور « دروس خصوصية متاحة »',
			'com.annonces.demoPublication.extraitVente' => 'أقدم دروسًا خصوصية مدفوعة في عطلة نهاية الأسبوع، راسلوني.',
			'com.annonces.demoPublication.signalementHorsSujet' => 'رد تحت « تنظيم مراجعة جماعية »',
			'com.annonces.section' => 'إعلانات الفصل',
			'com.annonces.annonce' => 'إعلان',
			'com.annonces.publier' => 'نشر إعلان',
			'com.annonces.videPublier' => 'لا توجد إعلانات لهذا الفصل. انشر أول إعلان للفصل كله.',
			'com.annonces.auteurDate' => ({required Object auteur, required Object date, required Object heure}) => '${auteur}، يوم ${date} الساعة ${heure}',
			'com.annonces.date' => ({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}',
			'com.annonces.lire' => 'قراءة الإعلان كاملًا',
			_ => null,
		} ?? switch (path) {
			'com.annonces.ouvrirClasse' => 'فتح الفصل',
			'com.annonces.ouvrirClasseSemantique' => ({required Object classe}) => 'فتح ${classe}',
			'com.annonces.marquerLue' => 'تحديد كمقروء',
			'com.annonces.lue' => 'مقروء',
			'com.annonces.carteSemantique' => ({required Object classe, required Object titre}) => 'إعلان ${classe} : ${titre}',
			'com.annonces.introuvableTitre' => 'هذا الإعلان لم يعد متاحًا',
			'com.annonces.introuvablePhrase' => 'ربما سُحب من الفصل. عد إلى إشعاراتك.',
			'com.annonces.demo.detail' => 'عرض تجريبي خارج الإنتاج : بيانات وهمية، ولا يُرسل شيء.',
			'com.annonces.demo.choisirRole' => 'اختر الدور المراد عرضه',
			'com.annonces.demo.roles.tuteur' => 'الأسرة',
			'com.annonces.demo.roles.enseignant' => 'المعلم',
			'com.annonces.demo.roles.adulte' => 'الطالب البالغ',
			'com.annonces.demo.roles.admin' => 'الإدارة',
			'com.annonces.demo.roles.controleur' => 'المراقب',
			'com.annonces.demo.classeNour' => 'فصل النور',
			'com.annonces.demo.classeFajr' => 'فصل الفجر',
			'com.annonces.demo.enseignante' => 'معلمة الفصل',
			'com.annonces.demo.f.adminStudioMention' => 'الاستوديو : نقاش في قناة البرامج يشير إليك',
			'com.annonces.demo.f.adminStudioReponse' => 'الاستوديو : رد جديد على رسالتك بشأن برنامج الربيع',
			'com.annonces.demo.f.adminStudioDecision' => 'الاستوديو : مطلوب قرار بشأن دعامة الدرس 4',
			'com.annonces.demo.f.adminStudioAssigne' => 'الاستوديو : أُسندت إليك مراجعة دعامة التجويد',
			'com.annonces.demo.f.adminStudioInterne' => 'إعلان داخلي لفريق الاستوديو : اجتماع الفريق يوم الخميس الساعة 18',
			'com.annonces.demo.f.adminStudioContexte' => 'الاستوديو : دعامة جاهزة لفصل النور',
			'com.annonces.demo.f.annonceNourTitre' => 'تلاوة نهاية الفصل الدراسي أمام الأسر',
			'com.annonces.demo.f.annonceNourTexte' => 'أسرنا الكريمة، سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت 14 ديسمبر الساعة 10، عبر الاتصال المرئي. سيتلو كل طالب السورة التي عمل عليها هذا الفصل. يرجى تجهيز اتصال مستقر ومكان هادئ. يمكن للطلاب الراغبين التدرب خلال حصة الأربعاء السابقة. يمكن للأسر الحضور بصمت مع كتم الميكروفون. سيُشارك تقرير بعد الحصة.',
			'com.annonces.demo.f.annonceFajrTitre' => 'مراجعة قبل تقييم يوم الخميس',
			'com.annonces.demo.f.annonceFajrTexte' => 'راجعوا الآيات العشر الأخيرة من سورة الملك قبل يوم الخميس.',
			'com.annonces.demo.f.tuteurUrgent' => 'حصة هذا المساء ملغاة',
			'com.annonces.demo.f.tuteurUrgentTexte' => 'المعلمة غائبة هذا المساء. أُجّلت الحصة إلى يوم الخميس في الوقت نفسه. لا شيء عليك فعله.',
			'com.annonces.demo.f.tuteurReponse' => 'رد منتظر : الموافقة على تلاوة ياسمين',
			'com.annonces.demo.f.tuteurReponseTexte' => 'تنتظر المعلمة موافقتك لتتلو ياسمين أمام الأسر. أجبها من فضاء الفصل.',
			'com.annonces.demo.f.tuteurMessage' => 'رسالة جديدة من معلمة فصل النور',
			'com.annonces.demo.f.tuteurDossier' => 'تم قبول ملف التسجيل الخاص بك',
			'com.annonces.demo.f.adulteSeance' => 'نُقلت حصتك يوم الثلاثاء إلى الساعة 19',
			'com.annonces.demo.f.adulteMessage' => 'رسالة جديدة من معلمتك',
			'com.annonces.demo.f.enseignantFamille' => 'رسالة من أسرة ياسمين، فصل النور',
			'com.annonces.demo.f.enseignantDirection' => 'إعلان من الإدارة : جدول عطلة الشتاء',
			'com.annonces.demo.f.enseignantDirectionTexte' => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.',
			'com.annonces.demo.f.enseignantPlanning' => 'تغيّر جدولك للأسبوع القادم',
			'com.annonces.demo.f.enseignantMention' => 'منشور في مجتمع المعلمين يشير إليك',
			'com.annonces.demo.f.enseignantReponse' => 'رد جديد على منشورك',
			'com.annonces.demo.f.enseignantAdministration' => 'رسالة من الإدارة : وثائق مطلوبة',
			'com.annonces.demo.f.adminDossiers' => 'ثلاثة ملفات تسجيل في انتظار المعالجة',
			'com.annonces.demo.f.adminSignalement' => 'تم الإبلاغ عن منشور في مجتمع المعلمين',
			'com.annonces.demo.f.adminReponse' => 'رد أسرة بلال على رسالتك',
			'com.annonces.demo.f.adminPlanifiee' => 'إعلان مجدول يحتاج إلى مراجعة قبل النشر',
			'com.annonces.demo.f.adminOperationnel' => 'فصل النور : العدد مكتمل',
			'com.annonces.demo.f.controleurMission' => 'مهمة جديدة : زيارة فصل النور',
			'com.annonces.demo.f.controleurChangement' => 'نُقلت مهمتك يوم الخميس إلى الساعة 18',
			'com.annonces.demo.f.controleurReponse' => 'رد الإدارة على تقريرك',
			'com.annonces.titre' => 'الإعلانات',
			_ => null,
		};
	}
}
