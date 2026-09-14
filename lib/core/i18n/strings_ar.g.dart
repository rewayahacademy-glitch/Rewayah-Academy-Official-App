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
	@override late final _Traductions$eleve$ar eleve = _Traductions$eleve$ar._(_root);
}

// Path: eleve
class _Traductions$eleve$ar extends Traductions$eleve$fr {
	_Traductions$eleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$eleve$suivi$ar suivi = _Traductions$eleve$suivi$ar._(_root);
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

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TraductionsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
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
			_ => null,
		};
	}
}
