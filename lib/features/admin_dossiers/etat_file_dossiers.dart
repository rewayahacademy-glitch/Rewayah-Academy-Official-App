import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/session/session_controleur.dart';

/// Taille d'une page de la file (17.1).
const int limiteFileDossiers = 20;

/// La file cumulee des dossiers, lue par le port (K-09).
@immutable
class EtatFile {
  const EtatFile({
    required this.elements,
    this.curseurSuivant,
    this.total,
    this.chargeSuite = false,
    this.erreurSuite = false,
  });

  final List<DossierEnFile> elements;
  final String? curseurSuivant;

  /// Nul quand le serveur ne le garantit pas : aucun compteur n'est affiche.
  final int? total;
  final bool chargeSuite;
  final bool erreurSuite;

  bool get aSuite => curseurSuivant != null;

  EtatFile copie({
    List<DossierEnFile>? elements,
    String? curseurSuivant,
    bool effacerCurseur = false,
    bool? chargeSuite,
    bool? erreurSuite,
  }) => EtatFile(
    elements: elements ?? this.elements,
    curseurSuivant: effacerCurseur
        ? null
        : (curseurSuivant ?? this.curseurSuivant),
    total: total,
    chargeSuite: chargeSuite ?? this.chargeSuite,
    erreurSuite: erreurSuite ?? this.erreurSuite,
  );
}

/// La file : premiere page a la construction, pages suivantes a la demande.
class FileDossiersNotifier extends AsyncNotifier<EtatFile> {
  @override
  Future<EtatFile> build() async {
    final PageDossiers page = await ref
        .watch(portRevueDossiersProvider)
        .listerDossiers(limite: limiteFileDossiers);
    return EtatFile(
      elements: page.elements,
      curseurSuivant: page.curseurSuivant,
      total: page.total,
    );
  }

  /// Charge la page suivante ; en cas d'echec, les lignes deja la restent.
  Future<void> chargerSuivants() async {
    final EtatFile? courant = state.value;
    final String? curseur = courant?.curseurSuivant;
    if (courant == null || curseur == null || courant.chargeSuite) {
      return;
    }
    state = AsyncData<EtatFile>(
      courant.copie(chargeSuite: true, erreurSuite: false),
    );
    try {
      final PageDossiers page = await ref
          .read(portRevueDossiersProvider)
          .listerDossiers(curseur: curseur, limite: limiteFileDossiers);
      final EtatFile maintenant = state.value ?? courant;
      state = AsyncData<EtatFile>(
        maintenant.copie(
          elements: <DossierEnFile>[...maintenant.elements, ...page.elements],
          curseurSuivant: page.curseurSuivant,
          effacerCurseur: page.curseurSuivant == null,
          chargeSuite: false,
        ),
      );
    } on Object {
      final EtatFile maintenant = state.value ?? courant;
      state = AsyncData<EtatFile>(
        maintenant.copie(chargeSuite: false, erreurSuite: true),
      );
    }
  }

  /// Relit la file depuis le debut ; la liste affichee reste pendant la
  /// relecture (`hasValue && isLoading`).
  void actualiser() => ref.invalidateSelf();
}

/// La file employee par l'ecran.
final AsyncNotifierProvider<FileDossiersNotifier, EtatFile>
fileDossiersProvider = AsyncNotifierProvider<FileDossiersNotifier, EtatFile>(
  FileDossiersNotifier.new,
);

/// La selection de la file, pour la session : elle survit a la navigation
/// et se reinitialise a tout changement de profil (deconnexion comprise).
@immutable
class SelectionDossier {
  const SelectionDossier({
    this.dossierId,
    this.detailOuvert = false,
    this.autoFaite = false,
  });

  final String? dossierId;

  /// Panneau unique : l'ecran de detail est ouvert.
  final bool detailOuvert;

  /// La selection automatique (deux panneaux) a deja eu lieu.
  final bool autoFaite;
}

/// La selection courante.
class SelectionDossierNotifier extends Notifier<SelectionDossier> {
  @override
  SelectionDossier build() {
    // Se reinitialise a tout changement de profil, deconnexion comprise. Une
    // session illisible (hote de test sans Supabase) laisse la selection
    // vivre sans cette remise a zero : l'ecran n'en depend pas.
    try {
      ref.watch(sessionProvider.select((s) => s.profileId));
    } on Object {
      // Rien : la dependance reste enregistree, la selection repart vide.
    }
    return const SelectionDossier();
  }

  /// Choisit un dossier ; [ouvrir] ouvre le detail en panneau unique.
  void choisir(String id, {bool ouvrir = false}) => state = SelectionDossier(
    dossierId: id,
    detailOuvert: ouvrir,
    autoFaite: true,
  );

  /// Selection automatique du premier, une seule fois par session.
  void choisirAuto(String id) {
    if (state.autoFaite) {
      return;
    }
    state = SelectionDossier(dossierId: id, autoFaite: true);
  }

  /// Referme le detail en gardant la selection.
  void fermerDetail() => state = SelectionDossier(
    dossierId: state.dossierId,
    autoFaite: state.autoFaite,
  );

  /// Retire la selection (sans nouvelle selection automatique).
  void retirer() => state = const SelectionDossier(autoFaite: true);
}

/// La selection employee par l'ecran.
final NotifierProvider<SelectionDossierNotifier, SelectionDossier>
selectionDossierProvider =
    NotifierProvider<SelectionDossierNotifier, SelectionDossier>(
      SelectionDossierNotifier.new,
    );
