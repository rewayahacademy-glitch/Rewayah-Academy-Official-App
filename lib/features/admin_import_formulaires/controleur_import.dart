// Le controleur de l'import des formulaires (`ADM-23`) : ou en est la direction
// dans les huit pas, ce qu'elle a choisi, et ce que le serveur a repondu. Un
// controleur sans regle metier : il garde des choix, appelle le port, et dit ce
// qui manque pour avancer. L'analyse, les issues, les groupes de doublons et les
// compteurs sont ceux du serveur ; rien n'est dit importe avant sa reponse.
//
// Les huit pas (`CONS` 3.2) : deposer le fichier, apercu, colonnes, doublons,
// erreurs, comptes, confirmation, rapport.
//
// Idempotence : la cle de la confirmation est tiree a la premiere tentative et
// gardee tant que rien ne change (fichier, noms, mappage, choix). Une coupure
// qui laisse l'import non confirme se rejoue avec la meme cle : la meme demande
// ne s'enregistre qu'une fois.
library;

import 'package:flutter/foundation.dart';

import '../../core/candidature/fichier_formulaires.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/candidature/port_ma_candidature.dart'
    show nouvelleCleIdempotence;

/// Les huit pas, dans l'ordre.
enum PasImport {
  /// Deposer le fichier.
  depot,

  /// Ce que le fichier contient.
  apercu,

  /// Quelle colonne dit quoi.
  colonnes,

  /// Les doublons probables.
  doublons,

  /// Les lignes a corriger et les avertissements.
  erreurs,

  /// Les quatre compteurs et l'ecart.
  comptes,

  /// La confirmation.
  confirmation,

  /// Le rapport final.
  rapport,
}

/// Ce que le controleur est en train de faire.
enum PhaseImport {
  /// Il attend un geste.
  repos,

  /// L'essai a blanc est parti.
  analyse,

  /// La confirmation est partie.
  envoi,
}

/// Pourquoi un fichier n'est pas lisible, en mots que l'ecran dit.
enum CauseFichier {
  /// Un guillemet ouvert n'est jamais referme.
  guillemetNonFerme,

  /// Plus de 5 Mo.
  tropVolumineux,

  /// La mise en forme n'est pas celle d'un export CSV.
  malForme,

  /// Aucune cause connue du client.
  inconnue,
}

/// Un fichier que l'on n'envoie pas, ou que le serveur n'a pas pu lire : sa
/// cause, et la ligne quand le client la connait.
@immutable
class ProblemeFichier {
  /// Cree le probleme.
  const ProblemeFichier(this.cause, {this.ligne});

  /// Traduit la cause rendue par le serveur (`fichier_illisible`).
  factory ProblemeFichier.depuisServeur(String cause) {
    final String c = cause.toLowerCase();
    if (c.contains('5 mo')) {
      return const ProblemeFichier(CauseFichier.tropVolumineux);
    }
    if (c.contains('guillemet non ferm')) {
      return const ProblemeFichier(CauseFichier.guillemetNonFerme);
    }
    if (c.contains('mal form')) {
      return const ProblemeFichier(CauseFichier.malForme);
    }
    return const ProblemeFichier(CauseFichier.inconnue);
  }

  /// La cause.
  final CauseFichier cause;

  /// Le numero de la ligne (l'en-tete est la ligne 1), quand le client la
  /// connait.
  final int? ligne;
}

/// Ce que la direction a decide d'un groupe de doublons.
sealed class ChoixGroupe {
  const ChoixGroupe();
}

/// Aucun choix : le serveur applique sa regle (la plus recente l'emporte) ou
/// garde le choix d'un import precedent. Rien n'est envoye pour ce groupe.
final class ParDefaut extends ChoixGroupe {
  /// Cree le choix.
  const ParDefaut();
}

/// Garder la ligne [ligne] du fichier ; les autres passent en historique.
final class GardeLigne extends ChoixGroupe {
  /// Cree le choix.
  const GardeLigne(this.ligne);

  /// Le numero de la ligne gardee.
  final int ligne;

  @override
  bool operator ==(Object other) => other is GardeLigne && other.ligne == ligne;

  @override
  int get hashCode => ligne.hashCode;
}

/// Ces lignes sont des personnes distinctes : chacune garde sa reponse.
final class PersonnesDistinctes extends ChoixGroupe {
  /// Cree le choix.
  const PersonnesDistinctes();
}

/// Les nombres que la direction attendait.
@immutable
class ComptesAttendus {
  /// Cree les nombres attendus.
  const ComptesAttendus({this.lignes, this.personnes});

  /// Le fichier du 21/10/2026 : 440 lignes, 409 personnes une fois les doublons
  /// rapproches (`MAPPAGE_IMPORT_FORMULAIRES.md`, section 6 ;
  /// `SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md`, 3.2). Le serveur ne rend
  /// aucun nombre de reference : ces deux valeurs viennent du decompte relevé
  /// dans le classeur ce jour-la.
  static const ComptesAttendus fichierDu2110 = ComptesAttendus(
    lignes: 440,
    personnes: 409,
  );

  /// Les lignes attendues, ou `null`.
  final int? lignes;

  /// Les personnes attendues, ou `null`.
  final int? personnes;
}

/// Ce que la direction a repondu a « Quel decompte attendiez-vous ? ».
enum ReponseAttendus {
  /// Le decompte du fichier du 21 octobre.
  fichierDu2110,

  /// D'autres nombres, saisis.
  autres,

  /// Aucun decompte a comparer.
  aucun,
}

/// Un ecart entre un nombre attendu et le nombre lu.
@immutable
class EcartCompte {
  /// Cree l'ecart.
  const EcartCompte({
    required this.nature,
    required this.attendu,
    required this.lu,
  });

  /// Ce qui est compte.
  final NatureCompte nature;

  /// Le nombre attendu.
  final int attendu;

  /// Le nombre lu par le serveur.
  final int lu;
}

/// Ce que l'on compte pour comparer.
enum NatureCompte {
  /// Les lignes lues.
  lignes,

  /// Les personnes, doublons rapproches.
  personnes,
}

/// Le fuseau des horodatages. Le serveur le prend en parametre ; l'ecran ne le
/// propose pas encore : UTC, valeur par defaut du serveur.
const String fuseauImport = 'UTC';

/// Le controleur.
class ControleurImportCandidatures extends ChangeNotifier {
  /// Cree le controleur sur [port]. [horsLigne] dit si l'appareil est hors
  /// ligne ; [cleIdempotence] tire une cle (remplacee par un test).
  ControleurImportCandidatures({
    required this.port,
    required this.horsLigne,
    String Function()? cleIdempotence,
  }) : _nouvelleCle = cleIdempotence ?? _cleParDefaut;

  bool _detruit = false;

  @override
  void dispose() {
    _detruit = true;
    super.dispose();
  }

  // Une reponse du serveur peut arriver apres la fermeture de la page.
  @override
  void notifyListeners() {
    if (_detruit) return;
    super.notifyListeners();
  }

  static String _cleParDefaut() => 'import-${nouvelleCleIdempotence()}';

  /// Le port de l'import.
  final PortImportCandidatures port;

  /// Dit si l'appareil est hors ligne : une analyse ou une confirmation n'est
  /// alors pas envoyee.
  final bool Function() horsLigne;

  final String Function() _nouvelleCle;

  PasImport _pas = PasImport.depot;
  PhaseImport _phase = PhaseImport.repos;
  FichierFormulaires? _fichier;
  NomsClasseur _noms = const NomsClasseur(classeur: '', onglet: '');
  MappageColonnes _mappage = MappageColonnes.aucun;
  ApercuImport? _apercu;
  List<ColonneLue> _colonnesServeur = const <ColonneLue>[];
  ProblemeFichier? _problemeFichier;
  bool _fichierSansLigne = false;
  Object? _erreurAnalyse;
  Object? _erreurConfirmation;
  final Map<String, ChoixGroupe> _choix = <String, ChoixGroupe>{};
  ReponseAttendus? _reponseAttendus;
  int? _attenduLignes;
  int? _attenduPersonnes;
  RapportImport? _rapport;
  String? _cle;
  bool _apercuAJour = false;

  /// Le pas courant.
  PasImport get pas => _pas;

  /// Le numero du pas courant, a partir de 1.
  int get numeroPas => _pas.index + 1;

  /// Ce que le controleur fait.
  PhaseImport get phase => _phase;

  /// Vrai pendant l'essai a blanc ou la confirmation.
  bool get occupe => _phase != PhaseImport.repos;

  /// Le fichier choisi, ou `null`.
  FichierFormulaires? get fichier => _fichier;

  /// Le classeur et l'onglet.
  NomsClasseur get noms => _noms;

  /// Le mappage corrige a la main.
  MappageColonnes get mappage => _mappage;

  /// L'apercu du serveur, ou `null`.
  ApercuImport? get apercu => _apercu;

  /// Pourquoi le fichier n'est pas envoye, ou `null`.
  ProblemeFichier? get problemeFichier => _problemeFichier;

  /// Vrai quand le fichier choisi n'a aucune ligne de donnees.
  bool get fichierSansLigne => _fichierSansLigne;

  /// L'echec du dernier essai a blanc : une [ErreurImportCandidatures], ou
  /// une autre erreur (lecture, reseau...). `null` sans echec.
  Object? get erreurAnalyse => _erreurAnalyse;

  /// L'echec de la derniere confirmation, ou `null`.
  Object? get erreurConfirmation => _erreurConfirmation;

  /// Le rapport du serveur, ou `null` tant que rien n'est ecrit.
  RapportImport? get rapport => _rapport;

  /// Les nombres attendus, ou `null`.
  ReponseAttendus? get reponseAttendus => _reponseAttendus;

  /// Les lignes attendues, quand la direction les a saisies.
  int? get attenduLignes => _attenduLignes;

  /// Les personnes attendues, quand la direction les a saisies.
  int? get attenduPersonnes => _attenduPersonnes;

  /// Les colonnes telles que le serveur les a lues, avec les corrections de la
  /// direction.
  List<ColonneLue> get colonnes => _mappage.appliquerA(_colonnesServeur);

  /// Les champs obligatoires sans colonne, apres les corrections.
  List<ChampManquant> get manquants => champsManquants(colonnes);

  /// Vrai quand le serveur a dit que deux colonnes portent le meme champ et
  /// que la direction n'a encore rien confirme.
  bool get ambigu {
    final Object? e = _erreurAnalyse;
    if (e is! EntetesAmbigus) return false;
    // Une association touchee ailleurs ne tranche rien : le serveur garderait
    // la premiere colonne reconnue. Chaque champ double attend SON choix.
    final Set<ChampFormulaire?> choisis = _mappage.surcharges.values.toSet();
    return e.champs.any((ChampFormulaire c) => !choisis.contains(c));
  }

  /// Les champs reconnus deux fois, ou une liste vide.
  List<ChampFormulaire> get champsAmbigus => switch (_erreurAnalyse) {
    final EntetesAmbigus e => e.champs,
    _ => const <ChampFormulaire>[],
  };

  /// Ce que la direction a decide de chaque groupe.
  ChoixGroupe choixDuGroupe(String groupe) =>
      _choix[groupe] ?? const ParDefaut();

  /// Le nombre de groupes sur lesquels la direction a decide quelque chose.
  int get groupesTranches => <GroupeDoublons>[
    for (final GroupeDoublons g in _apercu?.groupes ?? const <GroupeDoublons>[])
      if (choixDuGroupe(g.id) is! ParDefaut) g,
  ].length;

  /// Les nombres attendus effectifs, ou `null` quand rien n'est a comparer.
  ComptesAttendus? get attendus => switch (_reponseAttendus) {
    ReponseAttendus.fichierDu2110 => ComptesAttendus.fichierDu2110,
    ReponseAttendus.autres => ComptesAttendus(
      lignes: _attenduLignes,
      personnes: _attenduPersonnes,
    ),
    _ => null,
  };

  /// Les ecarts entre les nombres attendus et les nombres lus.
  List<EcartCompte> get ecarts {
    final ComptesAttendus? a = attendus;
    final ApercuImport? ap = _apercu;
    if (a == null || ap == null) return const <EcartCompte>[];
    return <EcartCompte>[
      if (a.lignes != null && a.lignes != ap.compteurs.lignesLues)
        EcartCompte(
          nature: NatureCompte.lignes,
          attendu: a.lignes!,
          lu: ap.compteurs.lignesLues,
        ),
      if (a.personnes != null && a.personnes != ap.compteurs.personnes)
        EcartCompte(
          nature: NatureCompte.personnes,
          attendu: a.personnes!,
          lu: ap.compteurs.personnes,
        ),
    ];
  }

  /// Vrai quand la direction a repondu a la question des comptes.
  bool get comptesRepondus => switch (_reponseAttendus) {
    null => false,
    ReponseAttendus.autres =>
      _attenduLignes != null || _attenduPersonnes != null,
    _ => true,
  };

  /// Vrai quand les noms et le fichier suffisent pour analyser.
  bool get peutAnalyser =>
      _fichier != null &&
      _problemeFichier == null &&
      !_fichierSansLigne &&
      _noms.valides;

  /// Vrai quand les colonnes demandent une nouvelle lecture du fichier par le
  /// serveur avant de passer au pas des doublons (une association corrigee, ou
  /// aucun apercu en main).
  bool get colonnesAReLire => _apercu == null || !_apercuAJour;

  /// Vrai quand rien n'empeche de passer au pas des doublons : les champs
  /// obligatoires ont une colonne et aucune ambiguite ne reste.
  bool get colonnesCompletes => manquants.isEmpty && !ambigu;

  // --- pas 1 : deposer ---

  /// Retient le fichier [nom] dont le texte decode est [texte]. Rien n'est
  /// envoye.
  void deposer({required String nom, required String texte}) {
    if (occupe) return;
    final FichierFormulaires f = FichierFormulaires.lire(
      nom: nom,
      texte: texte,
    );
    _reinitialiserAnalyse();
    _fichier = f;
    _noms = deduireNoms(nom);
    _fichierSansLigne = f.sansLigne;
    _problemeFichier = f.tropVolumineux
        ? const ProblemeFichier(CauseFichier.tropVolumineux)
        : f.guillemetNonFerme
        ? ProblemeFichier(
            CauseFichier.guillemetNonFerme,
            ligne: f.table.lignes.isEmpty ? 1 : f.table.lignes.last.numero,
          )
        : null;
    notifyListeners();
  }

  /// Corrige le classeur ou l'onglet. Une autre reference source : l'apercu ne
  /// vaut plus.
  void corrigerNoms({String? classeur, String? onglet}) {
    if (occupe) return;
    final NomsClasseur suivants = _noms.avec(
      classeur: classeur,
      onglet: onglet,
    );
    if (suivants == _noms) return;
    _noms = suivants;
    _apercu = null;
    _apercuAJour = false;
    _cle = null;
    notifyListeners();
  }

  /// Oublie tout et revient au premier pas.
  void recommencer() {
    if (occupe) return;
    _reinitialiserAnalyse();
    _fichier = null;
    _noms = const NomsClasseur(classeur: '', onglet: '');
    _problemeFichier = null;
    _fichierSansLigne = false;
    _choix.clear();
    _reponseAttendus = null;
    _attenduLignes = null;
    _attenduPersonnes = null;
    _rapport = null;
    _erreurConfirmation = null;
    _pas = PasImport.depot;
    notifyListeners();
  }

  void _reinitialiserAnalyse() {
    _apercu = null;
    _apercuAJour = false;
    _colonnesServeur = const <ColonneLue>[];
    _mappage = MappageColonnes.aucun;
    _erreurAnalyse = null;
    _erreurConfirmation = null;
    _cle = null;
    _choix.clear();
    _pas = PasImport.depot;
  }

  /// Lance l'essai a blanc du fichier (pas 1 vers le pas 2). Un apercu deja lu
  /// pour ce fichier, ces noms et ce mappage n'est pas redemande.
  Future<void> analyser() async {
    if (occupe || !peutAnalyser) return;
    if (_apercu != null && _apercuAJour) {
      _erreurAnalyse = null;
      _pas = PasImport.apercu;
      notifyListeners();
      return;
    }
    if (horsLigne()) {
      _erreurAnalyse = const ImportHorsLigne();
      notifyListeners();
      return;
    }
    await _lancerApercu();
    final Object? e = _erreurAnalyse;
    // Tant que les colonnes ne sont pas associees, le serveur ne dit rien des
    // lignes : l'apercu dit ce qu'il sait et mene au pas des colonnes.
    if ((_apercu != null && !_fichierSansLigne) ||
        e is MappageIncomplet ||
        e is EntetesAmbigus) {
      _pas = PasImport.apercu;
      notifyListeners();
    }
  }

  /// Appelle l'essai a blanc. Vrai quand le serveur a repondu quelque chose
  /// (apercu ou refus nomme), faux quand la reponse manque.
  Future<bool> _lancerApercu() async {
    final FichierFormulaires f = _fichier!;
    _phase = PhaseImport.analyse;
    _erreurAnalyse = null;
    notifyListeners();
    try {
      final ApercuImport a = await port.apercu(
        csv: f.csv,
        classeur: sansEspaces(_noms.classeur),
        onglet: sansEspaces(_noms.onglet),
        mappage: _mappage,
        fuseau: fuseauImport,
      );
      _apercu = a;
      _apercuAJour = true;
      _colonnesServeur = a.colonnes;
      _fichierSansLigne = a.compteurs.lignesLues == 0;
      // Un groupe disparu du fichier perd son choix ; les autres le gardent.
      final Set<String> presents = <String>{
        for (final GroupeDoublons g in a.groupes) g.id,
      };
      _choix.removeWhere((String id, ChoixGroupe _) => !presents.contains(id));
      return true;
    } on ErreurImportCandidatures catch (e) {
      _apercu = null;
      _apercuAJour = false;
      _erreurAnalyse = e;
      switch (e) {
        case MappageIncomplet(:final List<ColonneLue> colonnes):
          _colonnesServeur = colonnes;
        case EntetesAmbigus(:final List<ColonneLue> colonnes):
          _colonnesServeur = colonnes;
        case FichierIllisible(:final String cause):
          _problemeFichier = ProblemeFichier.depuisServeur(cause);
        case FichierVide():
          _fichierSansLigne = true;
        default:
          break;
      }
      return true;
    } on Object catch (e) {
      _apercu = null;
      _apercuAJour = false;
      _erreurAnalyse = e;
      return false;
    } finally {
      _phase = PhaseImport.repos;
      notifyListeners();
    }
  }

  // --- navigation ---

  /// Revient au pas precedent. Les choix faits sont gardes.
  void precedent() {
    if (occupe || _pas == PasImport.depot || _pas == PasImport.rapport) return;
    if (_pas == PasImport.apercu) _erreurAnalyse = null;
    _erreurConfirmation = null;
    _pas = PasImport.values[_pas.index - 1];
    notifyListeners();
  }

  /// Passe au pas suivant quand rien ne l'empeche. Le pas des colonnes relance
  /// l'essai a blanc si les associations ont change ; la confirmation passe par
  /// [confirmer].
  Future<void> suivant() async {
    if (occupe) return;
    switch (_pas) {
      case PasImport.depot:
        return analyser();
      case PasImport.apercu:
        _pas = PasImport.colonnes;
      case PasImport.colonnes:
        if (!colonnesCompletes) return;
        if (!_apercuAJour || _apercu == null) {
          if (horsLigne()) {
            _erreurAnalyse = const ImportHorsLigne();
            notifyListeners();
            return;
          }
          final bool repondu = await _lancerApercu();
          if (!repondu || _erreurAnalyse != null || _apercu == null) return;
        }
        _pas = PasImport.doublons;
      case PasImport.doublons:
        _pas = PasImport.erreurs;
      case PasImport.erreurs:
        _pas = PasImport.comptes;
      case PasImport.comptes:
        if (!comptesRepondus) return;
        _pas = PasImport.confirmation;
      case PasImport.confirmation:
        return confirmer();
      case PasImport.rapport:
        return;
    }
    _erreurConfirmation = null;
    notifyListeners();
  }

  // --- pas 3 : colonnes ---

  /// Lit la colonne [position] comme [champ] (`null` : ne pas la lire). Un
  /// champ n'a qu'une colonne.
  void associer(int position, ChampFormulaire? champ) {
    if (occupe) return;
    _mappage = _mappage.avec(position, champ);
    _apercuAJour = false;
    _cle = null;
    notifyListeners();
  }

  // --- pas 4 : doublons ---

  /// Retient ce que la direction decide du groupe [groupe].
  void choisir(String groupe, ChoixGroupe choix) {
    if (occupe) return;
    if (choix is ParDefaut) {
      _choix.remove(groupe);
    } else {
      _choix[groupe] = choix;
    }
    _cle = null;
    notifyListeners();
  }

  // --- pas 6 : comptes ---

  /// Retient la reponse a « Quel decompte attendiez-vous ? ».
  void repondreAttendus(
    ReponseAttendus reponse, {
    int? lignes,
    int? personnes,
  }) {
    _reponseAttendus = reponse;
    _attenduLignes = reponse == ReponseAttendus.autres ? lignes : null;
    _attenduPersonnes = reponse == ReponseAttendus.autres ? personnes : null;
    notifyListeners();
  }

  // --- pas 7 : confirmation ---

  /// Les choix de doublons tels que le serveur les lit : la reference source de
  /// la ligne gardee, ou « distinctes ». Un groupe laisse par defaut n'envoie
  /// rien.
  List<ChoixDoublon> choixPourLeServeur() {
    final FichierFormulaires? f = _fichier;
    final ApercuImport? a = _apercu;
    if (f == null || a == null) return const <ChoixDoublon>[];
    final List<ColonneLue> cols = colonnes;
    return <ChoixDoublon>[
      for (final GroupeDoublons g in a.groupes)
        ...switch (choixDuGroupe(g.id)) {
          ParDefaut() => const <ChoixDoublon>[],
          PersonnesDistinctes() => <ChoixDoublon>[
            ChoixDoublon(groupe: g.id, retenue: retenueDistinctes),
          ],
          GardeLigne(:final int ligne) => <ChoixDoublon>[
            ?_choixDeLigne(f, cols, g, ligne),
          ],
        },
    ];
  }

  ChoixDoublon? _choixDeLigne(
    FichierFormulaires f,
    List<ColonneLue> cols,
    GroupeDoublons g,
    int ligne,
  ) {
    final String? h = f.horodatageDeLigne(ligne, cols);
    if (h == null) return null;
    return ChoixDoublon(
      groupe: g.id,
      retenue: referenceSource(
        classeur: _noms.classeur,
        onglet: _noms.onglet,
        horodatage: h,
      ),
    );
  }

  /// Envoie la confirmation. Rien n'est dit importe avant la reponse du serveur ;
  /// une reponse perdue laisse l'import non confirme, et la meme cle
  /// d'idempotence le rejoue sans doublon.
  Future<void> confirmer() async {
    if (occupe || _fichier == null || _apercu == null) return;
    if (_pas != PasImport.confirmation) return;
    if (horsLigne()) {
      _erreurConfirmation = const ImportHorsLigne();
      notifyListeners();
      return;
    }
    final String cle = _cle ??= _nouvelleCle();
    _phase = PhaseImport.envoi;
    _erreurConfirmation = null;
    notifyListeners();
    try {
      final RapportImport r = await port.confirmer(
        csv: _fichier!.csv,
        classeur: sansEspaces(_noms.classeur),
        onglet: sansEspaces(_noms.onglet),
        jeton: _apercu!.jeton,
        choix: choixPourLeServeur(),
        cleIdempotence: cle,
        mappage: _mappage,
        fuseau: fuseauImport,
      );
      _rapport = r;
      _cle = null;
      _pas = PasImport.rapport;
    } on Object catch (e) {
      _erreurConfirmation = e;
    } finally {
      _phase = PhaseImport.repos;
      notifyListeners();
    }
  }

  /// Relance l'essai a blanc du meme fichier (apres un jeton perime ou un choix
  /// que le serveur ne reconnait plus) et revient au pas des doublons.
  Future<void> relireLeFichier() async {
    if (occupe || _fichier == null) return;
    _cle = null;
    _erreurConfirmation = null;
    final bool repondu = await _lancerApercu();
    if (repondu && _erreurAnalyse == null && _apercu != null) {
      _pas = PasImport.doublons;
    } else {
      _pas = PasImport.apercu;
    }
    notifyListeners();
  }

  /// Oublie l'echec de la derniere confirmation (la direction l'a lu).
  void effacerErreurConfirmation() {
    if (_erreurConfirmation == null) return;
    _erreurConfirmation = null;
    notifyListeners();
  }
}
