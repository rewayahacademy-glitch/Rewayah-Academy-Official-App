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
	@override late final _Traductions$com$ar com = _Traductions$com$ar._(_root);
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
	@override String get fermer => 'إغلاق البحث';
	@override String get effacer => 'مسح البحث';
	@override String get aucunTitre => 'لم يتم العثور على أي محادثة';
	@override String aucun({required Object texte}) => 'لا توجد محادثة تطابق « ${texte} ». جرّب اسمًا آخر أو فصلًا آخر.';
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
	@override String avecFonction({required Object nom, required Object fonction}) => '${nom}، ${fonction}';
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
	@override String semantique({required Object noms, required Object objets}) => 'محادثة مع ${noms}، بخصوص ${objets}';
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
	@override String get autre => 'عنصر مرتبط';
}

// Path: com.messages.panneau
class _Traductions$com$messages$panneau$ar extends Traductions$com$messages$panneau$fr {
	_Traductions$com$messages$panneau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get objets => 'العناصر المرتبطة';
	@override String get participants => 'المشاركون';
	@override String get fichiers => _root.com.socle.lexique.fichiersPartages;
	@override String ouvrir({required Object objet}) => 'فتح ${objet}';
	@override String get inaccessible => 'لم يعد بإمكانك الوصول إلى هذا العنصر. تبقى المحادثة قابلة للقراءة.';
	@override String get vous => 'أنت';
}

// Path: com.messages.fil
class _Traductions$com$messages$fil$ar extends Traductions$com$messages$fil$fr {
	_Traductions$com$messages$fil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String auteurEtMoment({required Object auteur, required Object moment}) => '${auteur} · ${moment}';
	@override String get lectureSeule => 'يمكنك قراءة هذه المحادثة. الرد فيها غير متاح لك.';
	@override String pieceJointe({required Object nom}) => 'مرفق: ${nom}';
	@override String vocal({required Object duree}) => 'رسالة صوتية مدتها ${duree}';
	@override String get vocalSansDuree => 'رسالة صوتية';
	@override String horodatage({required Object date, required Object heure}) => '${date}، ${heure}';
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
	@override String libelleAuteur({required Object auteur, required Object duree}) => 'رسالة صوتية من ${auteur}، ${duree}';
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
	@override String get auteurEnseignante => 'الأستاذة مريم، معلمة';
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
	@override String pieceJointe({required Object nom}) => 'مرفق: ${nom}';
	@override String vocal({required Object duree}) => 'رسالة صوتية مدتها ${duree}';
	@override String get vocalSansDuree => 'رسالة صوتية';
	@override String horodatage({required Object date, required Object heure}) => '${date}، ${heure}';
	@override String auteurEtMoment({required Object auteur, required Object moment}) => '${auteur} · ${moment}';
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
	@override String sansDestination({required Object type}) => '${type}، لم يعد يُفتح من هنا';
	@override late final _Traductions$com$studio$enregistres$types$ar types = _Traductions$com$studio$enregistres$types$ar._(_root);
}

// Path: com.studio.recherche
class _Traductions$com$studio$recherche$ar extends Traductions$com$studio$recherche$fr {
	_Traductions$com$studio$recherche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get champ => 'البحث في الاستوديو';
	@override String get aide => 'قناة أو رسالة أو ملف';
	@override String get fermer => 'إغلاق البحث';
	@override String get effacer => 'مسح البحث';
	@override String get aucunTitre => 'لا توجد نتائج';
	@override String aucun({required Object texte}) => 'لا شيء يطابق «${texte}» في قنواتك. جرّب كلمة أخرى.';
	@override String get aucunDansFiltre => 'لا شيء من هذا النوع يطابق البحث. اختر الكل لرؤية النتائج الأخرى.';
	@override String get resultatUn => 'نتيجة واحدة';
	@override String resultats({required Object nombre}) => '${nombre} نتائج';
	@override String get filtre => 'نوع النتيجة';
	@override String get tout => 'الكل';
	@override String get canaux => 'القنوات';
	@override String get messages => 'الرسائل';
	@override String get fichiers => 'الملفات';
	@override String dansCanal({required Object canal}) => 'في ${canal}';
	@override String messageDe({required Object auteur, required Object canal}) => '${auteur}، في ${canal}';
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

// Path: com.communaute.signalement.politique
class _Traductions$com$communaute$signalement$politique$ar extends Traductions$com$communaute$signalement$politique$fr {
	_Traductions$com$communaute$signalement$politique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get publicite => 'الإعلانات التجارية غير مسموح بها في مجتمع المعلّمين.';
	@override String get sollicitation => 'الاستدراج التجاري غير مسموح به في هذه المساحة.';
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
			'com.messages.recherche.fermer' => 'إغلاق البحث',
			'com.messages.recherche.effacer' => 'مسح البحث',
			'com.messages.recherche.aucunTitre' => 'لم يتم العثور على أي محادثة',
			'com.messages.recherche.aucun' => ({required Object texte}) => 'لا توجد محادثة تطابق « ${texte} ». جرّب اسمًا آخر أو فصلًا آخر.',
			'com.messages.recherche.resultatUn' => 'تم العثور على محادثة واحدة',
			'com.messages.recherche.resultats' => ({required Object nombre}) => 'تم العثور على ${nombre} محادثات',
			'com.messages.ligne.legende' => ({required Object objet, required Object apercu}) => '${objet} · ${apercu}',
			'com.messages.ligne.sansApercu' => 'لا توجد رسائل حاليًا',
			'com.messages.ligne.dateCourte' => ({required Object numero, required Object mois}) => '${numero} ${mois}',
			'com.messages.noms.avecFonction' => ({required Object nom, required Object fonction}) => '${nom}، ${fonction}',
			'com.messages.noms.deux' => ({required Object premier, required Object second}) => '${premier} و${second}',
			'com.messages.noms.plusieurs' => ({required Object premier, required Object nombre}) => '${premier} و${nombre} أشخاص آخرين',
			'com.messages.noms.surObjet' => ({required Object objet}) => 'محادثة بخصوص ${objet}',
			'com.messages.noms.sansObjet' => 'محادثة',
			'com.messages.entete.avecAttention' => ({required Object entete, required Object attention}) => '${entete}. ${attention}',
			'com.messages.entete.deuxObjets' => ({required Object premier, required Object second}) => '${premier} · ${second}',
			'com.messages.entete.semantique' => ({required Object noms, required Object objets}) => 'محادثة مع ${noms}، بخصوص ${objets}',
			'com.messages.entete.semantiqueSansNoms' => ({required Object objets}) => 'محادثة بخصوص ${objets}',
			'com.messages.types.classe' => 'الفصل',
			'com.messages.types.eleve' => 'الطالب',
			'com.messages.types.dossier' => 'الملف',
			'com.messages.types.mission' => 'مهمة المراقبة',
			'com.messages.types.remplacement' => 'الاستبدال',
			'com.messages.types.autre' => 'عنصر مرتبط',
			'com.messages.panneau.objets' => 'العناصر المرتبطة',
			'com.messages.panneau.participants' => 'المشاركون',
			'com.messages.panneau.fichiers' => _root.com.socle.lexique.fichiersPartages,
			'com.messages.panneau.ouvrir' => ({required Object objet}) => 'فتح ${objet}',
			'com.messages.panneau.inaccessible' => 'لم يعد بإمكانك الوصول إلى هذا العنصر. تبقى المحادثة قابلة للقراءة.',
			'com.messages.panneau.vous' => 'أنت',
			'com.messages.fil.auteurEtMoment' => ({required Object auteur, required Object moment}) => '${auteur} · ${moment}',
			'com.messages.fil.lectureSeule' => 'يمكنك قراءة هذه المحادثة. الرد فيها غير متاح لك.',
			'com.messages.fil.pieceJointe' => ({required Object nom}) => 'مرفق: ${nom}',
			'com.messages.fil.vocal' => ({required Object duree}) => 'رسالة صوتية مدتها ${duree}',
			'com.messages.fil.vocalSansDuree' => 'رسالة صوتية',
			'com.messages.fil.horodatage' => ({required Object date, required Object heure}) => '${date}، ${heure}',
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
			'com.vocal.lecteur.libelleAuteur' => ({required Object auteur, required Object duree}) => 'رسالة صوتية من ${auteur}، ${duree}',
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
			'com.vocal.demo.auteurEnseignante' => 'الأستاذة مريم، معلمة',
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
			_ => null,
		} ?? switch (path) {
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
			'com.studio.canal.pieceJointe' => ({required Object nom}) => 'مرفق: ${nom}',
			'com.studio.canal.vocal' => ({required Object duree}) => 'رسالة صوتية مدتها ${duree}',
			'com.studio.canal.vocalSansDuree' => 'رسالة صوتية',
			'com.studio.canal.horodatage' => ({required Object date, required Object heure}) => '${date}، ${heure}',
			'com.studio.canal.auteurEtMoment' => ({required Object auteur, required Object moment}) => '${auteur} · ${moment}',
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
			'com.studio.enregistres.sansDestination' => ({required Object type}) => '${type}، لم يعد يُفتح من هنا',
			'com.studio.enregistres.types.canal' => 'قناة',
			'com.studio.enregistres.types.publication' => 'منشور',
			'com.studio.enregistres.types.message' => 'رسالة',
			'com.studio.enregistres.types.element' => 'عنصر من الاستوديو',
			'com.studio.recherche.champ' => 'البحث في الاستوديو',
			'com.studio.recherche.aide' => 'قناة أو رسالة أو ملف',
			'com.studio.recherche.fermer' => 'إغلاق البحث',
			'com.studio.recherche.effacer' => 'مسح البحث',
			'com.studio.recherche.aucunTitre' => 'لا توجد نتائج',
			'com.studio.recherche.aucun' => ({required Object texte}) => 'لا شيء يطابق «${texte}» في قنواتك. جرّب كلمة أخرى.',
			'com.studio.recherche.aucunDansFiltre' => 'لا شيء من هذا النوع يطابق البحث. اختر الكل لرؤية النتائج الأخرى.',
			'com.studio.recherche.resultatUn' => 'نتيجة واحدة',
			'com.studio.recherche.resultats' => ({required Object nombre}) => '${nombre} نتائج',
			'com.studio.recherche.filtre' => 'نوع النتيجة',
			'com.studio.recherche.tout' => 'الكل',
			'com.studio.recherche.canaux' => 'القنوات',
			'com.studio.recherche.messages' => 'الرسائل',
			'com.studio.recherche.fichiers' => 'الملفات',
			'com.studio.recherche.dansCanal' => ({required Object canal}) => 'في ${canal}',
			'com.studio.recherche.messageDe' => ({required Object auteur, required Object canal}) => '${auteur}، في ${canal}',
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
			'com.studio.titre' => _root.com.socle.lexique.studio,
			'com.studio.vide' => 'لا يوجد نشاط للمعالجة هنا.',
			'com.annonces.titre' => 'الإعلانات',
			_ => null,
		};
	}
}
