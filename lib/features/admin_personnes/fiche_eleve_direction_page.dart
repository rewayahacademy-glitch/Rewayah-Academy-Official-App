// FICHE-ELEVE-DIRECTION (directeur, 22/11/2026 : « la direction doit avoir une
// fiche eleve complete, car les inscriptions commencent »).
//
// La fiche d'un eleve, ouverte depuis « Personnes » (onglet Eleves, et depuis
// la famille vers chacun de ses eleves) : identite, famille, reponses de
// l'inscription, classe et horaire, presences, progression, compte. Tout vient
// d'une seule lecture serveur (`fiche_eleve_direction`) : aucune donnee
// inventee, une donnee absente cache sa ligne ou le dit. Elle reutilise les
// composants de la fiche du tuteur (`SurfaceFiche`, `ColonnesFiche`,
// `PhotoEleve`) et les mots de l'inscription (`reponses_admission.dart`).
//
// Sur ordinateur, deux colonnes bornees en largeur (jamais une colonne de
// telephone etiree) ; la page defile en entier, une seule barre de
// defilement. Etats : chargement, contenu, vide (sections sans donnee),
// erreur, hors ligne, introuvable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/fiche_eleve_direction.dart';
import '../../core/i18n/isolat_bidi.dart' show enTeteArabe, isolerSens;
import '../../core/i18n/strings.g.dart';
import '../../core/offres/offre_horaire.dart'
    show NiveauDeclare, ObjectifApprentissage;
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/creneau_chez_moi.dart';
import '../../core/tc_horloge/fuseaux_interlocuteurs.dart' show FuseauVu;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_admissions/ligne_whatsapp_direction.dart';
import '../admin_admissions/reponses_admission.dart';
import '../foyer/fiche_eleve_page.dart' show ColonnesFiche, SurfaceFiche;
import '../foyer/photo_eleve.dart';
import '../inscription/questionnaire/interludes_onboarding.dart'
    show libelleQuantite, nomLangue, nomSourate;
import '../inscription/questionnaire/onboarding_donnees.dart'
    show QuantiteMemorisee;
import '../parcours_offres/libelles_parcours.dart';
import 'section_paiement_fiche.dart';

/// La fiche d'un eleve, lue par la direction (`/admin/personnes/eleves/:id`).
class FicheEleveDirectionPage extends ConsumerWidget {
  /// Cree la page.
  const FicheEleveDirectionPage({required this.eleveId, super.key});

  /// L'eleve demande par le chemin : une demande, jamais une autorisation (le
  /// serveur decide de ce qu'il rend).
  final String eleveId;

  /// La page.
  static const Key clePage = ValueKey<String>('fiche-eleve-direction');

  /// La carte d'en-tete.
  static const Key cleEntete = ValueKey<String>('fiche-eleve-entete');

  /// Une section, par son nom (`identite`, `admission`, `classe`, ...).
  static Key cleSection(String nom) => ValueKey<String>('fiche-eleve-$nom');

  /// Le plus large qu'une colonne de la fiche s'etire : au-dela, un grand
  /// ecran laisse des marges au lieu de laisser une colonne de telephone
  /// etiree.
  static const double largeurMax = 1120;

  void _retour(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('${Routes.adminPersonnes}?onglet=eleves');
    }
  }

  void _relire(WidgetRef ref) =>
      ref.invalidate(ficheEleveDirectionProvider(eleveId));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FicheEleveDirection?> lecture = ref.watch(
      ficheEleveDirectionProvider(eleveId),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final FicheEleveDirection? fiche = lecture.value;
    final String titre = fiche == null
        ? t.admin.ficheEleve.identite.titre
        : (fiche.libelle.isEmpty ? isolerSens(fiche.matricule) : fiche.libelle);

    final Widget corps = sansDonneesHorsLigne(lecture, horsLigne: horsLigne)
        ? EtatSansDonnees(
            quoi: t.admin.ficheEleve.sansDonnees,
            onAction: () => _relire(ref),
          )
        : BlocAsynchrone<FicheEleveDirection?>(
            valeur: lecture,
            squelette: const Skeleton.texte(lignes: 8),
            onReessayer: () => _relire(ref),
            construire: (FicheEleveDirection? f) => f == null
                ? EtatSysteme(
                    nature: NatureEtat.introuvable,
                    portee: PorteeEtat.page,
                    titre: t.admin.ficheEleve.introuvable.titre,
                    phrase: t.admin.ficheEleve.introuvable.phrase,
                    libelleAction: t.admin.ficheEleve.introuvable.retour,
                    onAction: () => _retour(context),
                  )
                : _Corps(fiche: f),
          );

    return PageShell(
      key: clePage,
      titre: titre,
      sousTitre: fiche == null ? null : isolerSens(fiche.matricule),
      onRetour: () => _retour(context),
      child: corps,
    );
  }
}

/// Le corps : l'en-tete, puis deux colonnes (ordinateur) ou une pile.
class _Corps extends ConsumerWidget {
  const _Corps({required this.fiche});

  final FicheEleveDirection fiche;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FicheEleveDirection f = fiche;
    final Widget principal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _SectionIdentite(fiche: f),
        Ecart.vXxl,
        if (f.paiement case final PaiementFiche paiement) ...<Widget>[
          SectionPaiementFiche(
            eleveId: f.id,
            prenom: f.prenom ?? '',
            nom: f.libelle.isEmpty ? isolerSens(f.matricule) : f.libelle,
            paiement: paiement,
          ),
          Ecart.vXxl,
        ],
        _SectionAdmission(fiche: f),
        Ecart.vXxl,
        _SectionProgression(fiche: f),
      ],
    );
    final Widget annexe = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _SectionFamille(fiche: f),
        Ecart.vXxl,
        _SectionClasse(fiche: f),
        Ecart.vXxl,
        _SectionPresences(fiche: f),
        Ecart.vXxl,
        _SectionCompte(fiche: f),
      ],
    );
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: FicheEleveDirectionPage.largeurMax,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Entete(fiche: f),
            Ecart.vXxl,
            ColonnesFiche(principal: principal, annexe: annexe),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime d) =>
    enTeteArabe(
      t.commun.dates.jourDate(
        jour: t.commun.dates.jours[d.weekday - 1],
        numero: d.day,
        mois: t.commun.dates.mois[d.month - 1],
      ),
    ) +
    LibellesGroupe.insecable(' ${d.year}');

/// Une ligne cle / valeur d'une carte ; `null` ou vide : la ligne n'existe pas.
Widget? _ligne(String cle, String? valeur, {bool chiffres = false}) =>
    valeur == null || valeur.trim().isEmpty
    ? null
    : Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: LigneCleValeur(cle: cle, valeur: valeur, chiffres: chiffres),
      );

/// Une section : son titre, puis une seule carte a lignes fines.
class _Section extends StatelessWidget {
  const _Section({
    required this.nom,
    required this.titre,
    required this.lignes,
    this.vide,
    this.pied,
  });

  final String nom;
  final String titre;

  /// Les lignes ; les `null` sont ecartes.
  final List<Widget?> lignes;

  /// La phrase quand il n'y a aucune ligne.
  final String? vide;

  /// Ce qui suit la carte (un lien).
  final Widget? pied;

  @override
  Widget build(BuildContext context) {
    final List<Widget> visibles = <Widget>[for (final Widget? l in lignes) ?l];
    final TextTheme textes = Theme.of(context).textTheme;
    return KeyedSubtree(
      key: FicheEleveDirectionPage.cleSection(nom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SectionHeader(titre: titre),
          Ecart.vSm,
          if (visibles.isEmpty)
            Text(
              vide ?? t.admissions.reponses.nonRenseigne,
              style: AppPalette.of(context).inkMuted
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            )
          else
            CarteLignes(lignes: visibles),
          if (pied case final Widget p) ...<Widget>[Ecart.vMd, p],
        ],
      ),
    );
  }
}

class _Entete extends StatelessWidget {
  const _Entete({required this.fiche});

  final FicheEleveDirection fiche;

  @override
  Widget build(BuildContext context) {
    final FicheEleveDirection f = fiche;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String prenom = f.prenom ?? '';
    final String nom = f.libelle.isEmpty ? isolerSens(f.matricule) : f.libelle;
    final String? tranche = _libelleTranche(f);
    final (String, TonEtat) etat = _etatCompte(f.etatCompte);
    return KeyedSubtree(
      key: FicheEleveDirectionPage.cleEntete,
      child: SurfaceFiche(
        child: Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.lg,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            AvatarNom.enLigne(
              prenom: prenom,
              avatar: PhotoEleve(
                prenom: prenom,
                cleAvatar: null,
                personneId: f.id,
                diametre: AppAvatar.grand,
              ),
              nom: nom,
              role: tranche,
              diametre: AppAvatar.grand,
              ecart: AppSpacing.lg,
              styleNom: palette.inkStrong.applyTo(
                textes.titleLarge ?? const TextStyle(),
              ),
              styleRole: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            StatusPill(libelle: etat.$1, ton: etat.$2),
          ],
        ),
      ),
    );
  }
}

String? _libelleTranche(FicheEleveDirection f) {
  final int? age = f.admission?.age;
  return switch (f.tranche) {
    'enfant' =>
      age == null
          ? t.admin.comptes.trancheEnfant
          : LibellesGroupe.insecable(
              t.admin.ficheEleve.identite.ageEnfant(age: age),
            ),
    'adulte' => t.admin.comptes.trancheAdulte,
    _ => null,
  };
}

(String, TonEtat) _etatCompte(String etat) => switch (etat) {
  'active' => (t.admin.comptes.etatActif, TonEtat.succes),
  'pending_kyc' => (t.admin.comptes.etatEnAttente, TonEtat.avertissement),
  'provisional_active' => (t.admin.comptes.etatProvisoire, TonEtat.neutre),
  'disabled' => (t.admin.comptes.etatSuspendu, TonEtat.alerte),
  _ => (t.admin.comptes.etatInconnu, TonEtat.neutre),
};

class _SectionIdentite extends StatelessWidget {
  const _SectionIdentite({required this.fiche});

  final FicheEleveDirection fiche;

  @override
  Widget build(BuildContext context) {
    final FicheEleveDirection f = fiche;
    final k = t.admin.ficheEleve.identite;
    final bool masquee = f.prenom == null && f.nom == null;
    final bool adulte = f.tranche == 'adulte';
    return _Section(
      nom: 'identite',
      titre: k.titre,
      lignes: <Widget?>[
        _ligne(k.prenom, f.prenom),
        _ligne(k.nom, f.nom),
        _ligne(k.matricule, isolerSens(f.matricule), chiffres: true),
        _ligne(k.age, _libelleTranche(f)),
        _ligne(k.genre, libelleGenreReponse(f.genre, adulte: adulte)),
        _ligne(
          k.langueCours,
          f.langueCours == null
              ? null
              : libelleLangueDemandee(_codeLangue(f.langueCours!)),
        ),
        _ligne(k.langueCompte, _langueCompte(f.langueCommunication)),
        if (masquee)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(k.masquee),
          ),
      ],
    );
  }
}

/// Les codes de langue de cours du profil (`francais`, `english`) sont ceux de
/// l'onboarding ; `libelleLangueDemandee` lit `fr` et `en` pour la demande.
String _codeLangue(String code) => switch (code) {
  'francais' => 'fr',
  'english' => 'en',
  _ => code,
};

String? _langueCompte(String? code) => switch (code) {
  'fr' => nomLangue('francais'),
  'en' => nomLangue('english'),
  'ar' => nomLangue('ar'),
  _ => null,
};

class _SectionAdmission extends StatelessWidget {
  const _SectionAdmission({required this.fiche});

  final FicheEleveDirection fiche;

  @override
  Widget build(BuildContext context) {
    final AdmissionFiche? a = fiche.admission;
    final r = t.admissions.reponses;
    final k = t.admin.ficheEleve.admission;
    if (a == null || a.vide) {
      return _Section(
        nom: 'admission',
        titre: k.titre,
        lignes: const <Widget?>[],
        vide: k.aucune,
      );
    }
    final NiveauDeclare? niveau = NiveauDeclare.depuisSql(a.niveau);
    final bool lit =
        a.niveau == 'lecture_courante' || a.niveau == 'memorisation_partielle';
    final QuantiteMemorisee? quantite = QuantiteMemorisee.depuisSql(a.memorise);
    final bool priere = a.objectif == 'priere_invocations';
    final ObjectifApprentissage? objectif = ObjectifApprentissage.depuisSql(
      a.objectif,
    );
    final List<String> moments = <String>[
      for (final String m in a.moments)
        if (libelleMomentReponse(m) case final String l) l,
    ];
    return _Section(
      nom: 'admission',
      titre: k.titre,
      lignes: <Widget?>[
        _ligne(r.niveau, niveau == null ? null : libelleNiveau(niveau)),
        if (lit)
          _ligne(r.lecture, libelleLectureReponse(a.riwaya, a.riwayaAutre)),
        _ligne(r.memorise, quantite == null ? null : libelleQuantite(quantite)),
        _ligne(
          r.juz,
          a.juz.isEmpty
              ? null
              : (<int>[...a.juz]..sort())
                    .map((int n) => t.onboarding.detail.juz(n: n))
                    .join(', '),
        ),
        _ligne(
          r.sourates,
          a.sourates.isEmpty ? null : a.sourates.map(nomSourate).join(', '),
        ),
        _ligne(
          r.objectif,
          priere
              ? t.onboarding.recap.objectifs.priere
              : (objectif == null ? null : libelleObjectif(objectif)),
        ),
        _ligne(r.moments, moments.isEmpty ? null : moments.join(', ')),
        _ligne(r.langue, libelleLangueDemandee(a.langue)),
        _ligne(r.langueSecours, libelleLangueDemandee(a.langueSecours)),
        if (a.langueAutre case final String autre when autre.isNotEmpty)
          _ligne(r.langueAutre, isolerSens(autre)),
        _ligne(r.source, libelleSourceReponse(a.source)),
      ],
    );
  }
}

class _SectionProgression extends StatelessWidget {
  const _SectionProgression({required this.fiche});

  final FicheEleveDirection fiche;

  @override
  Widget build(BuildContext context) {
    final ProgressionFiche? p = fiche.progression;
    final k = t.admin.ficheEleve.progression;
    final String? rythme = switch (p?.rythme) {
      'dans_les_temps' => k.dansLesTemps,
      'au_dela_du_prevu' => k.auDelaDuPrevu,
      'date_limite_depassee' => t.suiviPedagogique.dateLimiteDepassee,
      _ => null,
    };
    return _Section(
      nom: 'progression',
      titre: k.titre,
      vide: k.aucune,
      lignes: p == null
          ? const <Widget?>[]
          : <Widget?>[
              _ligne(k.etape, p.etape),
              _ligne(k.depuis, p.depuis == null ? null : _date(p.depuis!)),
              _ligne(
                k.dateLimite,
                p.dateLimite == null ? null : _date(p.dateLimite!),
              ),
              _ligne(k.rythme, rythme),
            ],
    );
  }
}

class _SectionFamille extends StatelessWidget {
  const _SectionFamille({required this.fiche});

  final FicheEleveDirection fiche;

  @override
  Widget build(BuildContext context) {
    final TuteurFiche? tu = fiche.tuteur;
    final k = t.admin.ficheEleve.famille;
    if (tu == null) {
      return _Section(
        nom: 'famille',
        titre: k.titre,
        lignes: const <Widget?>[],
        vide: k.sansTuteur,
      );
    }
    final String? matricule = tu.matricule;
    return _Section(
      nom: 'famille',
      titre: k.titre,
      lignes: <Widget?>[
        _ligne(k.tuteur, tu.libelle.isEmpty ? k.tuteurMasque : tu.libelle),
        _ligne(
          k.courriel,
          tu.courriel == null ? null : isolerSens(tu.courriel!),
        ),
        _ligne(
          k.telephone,
          tu.telephone == null ? null : isolerSens(tu.telephone!),
          chiffres: true,
        ),
        LigneWhatsappDirection(cible: (candidatureId: null, profilId: tu.id)),
      ],
      pied: matricule == null
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                libelle: k.ouvrir,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                onPress: () => context.go(
                  Uri(
                    path: Routes.adminPersonnes,
                    queryParameters: <String, String>{
                      'onglet': 'familles',
                      'element': matricule,
                    },
                  ).toString(),
                ),
              ),
            ),
    );
  }
}

class _SectionClasse extends ConsumerWidget {
  const _SectionClasse({required this.fiche});

  final FicheEleveDirection fiche;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ClasseFiche> classes = fiche.classes;
    final k = t.admin.ficheEleve.classe;
    // HORLOGE-ET-LIEU : l'heure de la personne d'abord, « Heure de La Mecque »
    // en second, jamais l'heure enregistree brute.
    final Map<String, FuseauVu?> fuseaux = fuseauxDesCreneaux(
      ref,
      classes.map((ClasseFiche c) => c.fuseau),
    );
    final List<Widget?> lignes = <Widget?>[];
    for (final ClasseFiche c in classes) {
      lignes
        ..add(_ligne(k.titre, c.libelle))
        ..add(
          _ligne(
            k.enseignant,
            c.enseignantId == null
                ? k.sansEnseignant
                : (c.enseignant.isEmpty ? null : c.enseignant),
          ),
        );
      for (final CreneauFiche cr in c.creneaux) {
        lignes.add(
          _ligne(
            k.horaire,
            libelleCreneauLu(fuseaux, (
              jour: cr.jour.clamp(1, 7),
              heure: cr.heure,
              fuseau: c.fuseau,
            )),
            chiffres: true,
          ),
        );
      }
      if (c.depuis != null) {
        lignes.add(_ligne(k.depuis, _date(c.depuis!)));
      }
    }
    return _Section(
      nom: 'classe',
      titre: classes.length > 1 ? k.titrePlusieurs : k.titre,
      lignes: lignes,
      vide: k.aucune,
    );
  }
}

class _SectionPresences extends StatelessWidget {
  const _SectionPresences({required this.fiche});

  final FicheEleveDirection fiche;

  String _etat(String etat) {
    final k = t.admin.ficheEleve.presences;
    return switch (etat) {
      'presente' ||
      'reconnectee' ||
      'sortie' ||
      'finalisee' ||
      'corrigee_manuel' ||
      'deconnectee' ||
      'en_reconnexion' => k.presente,
      'en_retard' => k.enRetard,
      'absente' => k.absente,
      'excusee' => k.excusee,
      _ => k.inconnue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final PresencesFiche p = fiche.presences;
    final k = t.admin.ficheEleve.presences;
    if (p.total == 0) {
      return _Section(
        nom: 'presences',
        titre: k.titre,
        lignes: const <Widget?>[],
        vide: k.aucune,
      );
    }
    return _Section(
      nom: 'presences',
      titre: k.titre,
      lignes: <Widget?>[
        _ligne(k.seances, '${p.total}', chiffres: true),
        _ligne(k.presents, '${p.presents}', chiffres: true),
        _ligne(k.retards, '${p.retards}', chiffres: true),
        _ligne(k.absents, '${p.absents}', chiffres: true),
        _ligne(k.excuses, '${p.excuses}', chiffres: true),
        for (final SeanceFiche s in p.dernieres)
          _ligne(_date(s.debut), _etat(s.etat)),
      ],
    );
  }
}

class _SectionCompte extends StatelessWidget {
  const _SectionCompte({required this.fiche});

  final FicheEleveDirection fiche;

  @override
  Widget build(BuildContext context) {
    final FicheEleveDirection f = fiche;
    final k = t.admin.ficheEleve.compte;
    return _Section(
      nom: 'compte',
      titre: k.titre,
      lignes: <Widget?>[
        _ligne(k.etat, _etatCompte(f.etatCompte).$1),
        _ligne(k.inscritLe, f.inscritLe == null ? null : _date(f.inscritLe!)),
        _ligne(
          k.accesJusquAu,
          f.accesJusquAu == null ? null : _date(f.accesJusquAu!),
        ),
      ],
    );
  }
}
