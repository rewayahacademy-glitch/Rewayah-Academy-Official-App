import 'dart:js_interop';

import '../observabilite/journal_dev.dart';
import '../theme/app_mouvement.dart';

@JS('navigator.vibrate')
external JSBoolean? _vibrer(JSNumber millisecondes);

@JS('AudioContext')
extension type _ContexteAudio._(JSObject _) implements JSObject {
  external factory _ContexteAudio();
  external String get state;
  external double get currentTime;
  external JSObject get destination;
  external _Oscillateur createOscillator();
  external _Volume createGain();
}

extension type _Parametre._(JSObject _) implements JSObject {
  external set value(double valeur);
  external void linearRampToValueAtTime(double valeur, double instant);
}

extension type _Oscillateur._(JSObject _) implements JSObject {
  external _Parametre get frequency;
  external void connect(JSObject cible);
  external void start();
  external void stop(double instant);
}

extension type _Volume._(JSObject _) implements JSObject {
  external _Parametre get gain;
  external void connect(JSObject cible);
}

/// Un seul contexte par page : le navigateur le laisse « suspendu » tant que
/// personne n'a touche la page, et c'est ce qui decide du son.
_ContexteAudio? _contexte;

/// Hauteur et volume du son doux : un la, tres bas.
const double _frequence = 440;
const double _volume = 0.08;

/// Dans un navigateur : vibration si elle existe, son si la page est active.
void signalerRappel() {
  try {
    _vibrer(AppMouvement.vibrationRappel.inMilliseconds.toJS);
  } catch (e) {
    journalDev('vibration du rappel indisponible : $e');
  }
  try {
    final _ContexteAudio contexte = _contexte ??= _ContexteAudio();
    // Sans geste prealable, le navigateur refuse le son : le visuel suffit.
    if (contexte.state != 'running') return;
    final double debut = contexte.currentTime;
    final double fin =
        debut +
        AppMouvement.sonRappel.inMilliseconds / Duration.millisecondsPerSecond;
    final _Oscillateur son = contexte.createOscillator();
    final _Volume volume = contexte.createGain();
    son.frequency.value = _frequence;
    volume.gain.value = _volume;
    volume.gain.linearRampToValueAtTime(0, fin);
    son.connect(volume);
    volume.connect(contexte.destination);
    son.start();
    son.stop(fin);
  } catch (e) {
    journalDev('son du rappel indisponible : $e');
  }
}
