import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/recrutement/port_invitations_enseignant.dart';

/// Lot F2 : le code de comptable verifie, conserve pour l'inscription
/// (`inscrire_comptable_invite`, BF1-03). Distinct du code enseignant : un
/// code de comptable ne sert jamais a creer un enseignant, ni l'inverse.
/// Jamais ecrit sur disque, jamais journalise.
final NotifierProvider<CodeInvitationRetenu, String?>
codeComptableRetenuProvider = NotifierProvider<CodeInvitationRetenu, String?>(
  CodeInvitationRetenu.new,
);
