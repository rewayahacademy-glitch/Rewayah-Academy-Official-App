import 'dart:js_interop';

import '../observabilite/journal_dev.dart';
import '../theme/app_mouvement.dart';

@JS('navigator.vibrate')
external JSBoolean? _vibrer(JSNumber millisecondes);

@JS('AudioContext')
extension type _ContexteAudio._(JSObject _) implements JSObject {
  external factory _ContexteAudio();
  external String get state;
  external JSPromise<JSAny?> resume();
  external double get currentTime;
  external JSObject get destination;
  external _Oscillateur createOscillator();
  external _Volume createGain();
}

extension type _Parametre._(JSObject _) implements JSObject {
  external set value(double valeur);
  external void setValueAtTime(double valeur, double instant);
  external void linearRampToValueAtTime(double valeur, double instant);
}

extension type _Oscillateur._(JSObject _) implements JSObject {
  external _Parametre get frequency;
  external void connect(JSObject cible);
  external void start([double instant]);
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
  // GESTES-POINTEUR (11/11/2026) : deux notes qui montent. Une seule note
  // tres basse, d'un quart de seconde, se perdait dans la recitation.
  _jouer(const <double>[_frequence, _frequenceAppel]);
}

const double _frequenceAppel = 660;

/// CHRONO-ETAT (11/11/2026) : le signal du chrono de qui conduit la seance,
/// deux notes douces qui montent (la fin approche, ou la fin prevue est
/// atteinte). Pas de vibration : le chrono previent, il n'appelle pas.
void signalerChrono() => _jouer(const <double>[_frequenceChrono, _frequence]);

const double _frequenceChrono = 330;

/// Joue les notes l'une apres l'autre, chacune de [AppMouvement.sonRappel].
///
/// Constat de la salle, defaut G-1 (11/11/2026) : un `AudioContext` nait
/// « suspendu » dans un navigateur et le premier son etait donc muet. On le
/// reveille (`resume`) avant de jouer ; la personne a deja touche l'ecran
/// pour rejoindre la salle, le navigateur l'accepte. S'il refuse encore, le
/// visuel suffit.
void _jouer(List<double> notes) {
  try {
    final _ContexteAudio contexte = _contexte ??= _ContexteAudio();
    if (contexte.state != 'running') {
      contexte.resume().toDart.then((JSAny? _) {
        if (contexte.state == 'running') _programmer(contexte, notes);
      }, onError: (Object e) => journalDev('son indisponible : $e'));
      return;
    }
    _programmer(contexte, notes);
  } catch (e) {
    journalDev('son indisponible : $e');
  }
}

void _programmer(_ContexteAudio contexte, List<double> notes) {
  final double duree =
      AppMouvement.sonRappel.inMilliseconds / Duration.millisecondsPerSecond;
  double debut = contexte.currentTime;
  for (final double note in notes) {
    final double fin = debut + duree;
    final _Oscillateur son = contexte.createOscillator();
    final _Volume volume = contexte.createGain();
    son.frequency.value = note;
    volume.gain.setValueAtTime(_volume, debut);
    volume.gain.linearRampToValueAtTime(0, fin);
    son.connect(volume);
    volume.connect(contexte.destination);
    son.start(debut);
    son.stop(fin);
    debut = fin;
  }
}
