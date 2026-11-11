// NAV-REFONTE 2c (garde-cap, 11/11/2026) : `CarteSession` recoit son
// emplacement, calcule hors d'elle. Les tests qui la montent seule le
// calculent ici, par la meme fonction pure que la production
// (`CarteSession.emplacementPour`), avec les memes entrees que la carte.

import 'package:flutter/widgets.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

/// Une [CarteSession] dont l'emplacement est calcule par la fonction pure.
CarteSession carteSessionDeTest({
  required GroupHomeVM espace,
  Key? key,
  VoidCallback? onRejoindre,
  VoidCallback? onReessayer,
  bool horsLigne = false,
  bool annulee = false,
  bool lectureEchouee = false,
  Widget? identite,
  Widget? actionHorsEntree,
  bool tutoiement = false,
  bool entreeRetiree = false,
  String? attenteEntree,
  bool seanceParServeur = false,
  String? refusEntree,
}) => CarteSession(
  key: key,
  espace: espace,
  emplacement: CarteSession.emplacementPour(
    espace: espace,
    horsLigne: horsLigne,
    annulee: annulee,
    lectureEchouee: lectureEchouee,
    seanceParServeur: seanceParServeur,
    tutoiement: tutoiement,
  ),
  onRejoindre: onRejoindre,
  onReessayer: onReessayer,
  horsLigne: horsLigne,
  annulee: annulee,
  lectureEchouee: lectureEchouee,
  identite: identite,
  actionHorsEntree: actionHorsEntree,
  tutoiement: tutoiement,
  entreeRetiree: entreeRetiree,
  attenteEntree: attenteEntree,
  seanceParServeur: seanceParServeur,
  refusEntree: refusEntree,
);
