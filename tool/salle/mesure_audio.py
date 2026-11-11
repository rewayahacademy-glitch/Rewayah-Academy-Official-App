#!/usr/bin/env python3
"""Banc de la salle : mesure objective de ce que l'eleve entend.

Compare l'enregistrement recu par l'eleve a la recitation d'origine :
  - STOI etendu (Jensen et Taal, 2016) : intelligibilite objective, de 0 a 1 ;
  - mots reconnus : un modele de reconnaissance de la recitation du Coran
    (Whisper affine par Tarteel) transcrit l'original et le recu ; le taux
    d'erreur de mots (WER) du recu par rapport a l'original dit combien de
    mots ont ete perdus ou changes par le reseau. Ce n'est pas un jugement de
    tajwid : c'est une mesure repetable de ce qui reste des mots ;
  - trous : part du temps ou le signal recu est muet alors que l'original
    ne l'est pas.

Usage : mesure_audio.py <original.wav> <recu.(wav|webm)>... [--sans-asr]
Sortie : une ligne JSON par enregistrement.
"""
import json
import os
import subprocess
import sys
import tempfile

import numpy as np
import soundfile as sf
from scipy.signal import correlate

FE = 16000


def lire(chemin):
    """Tout fichier audio -> mono 16 kHz, flottant."""
    with tempfile.NamedTemporaryFile(suffix=".wav") as t:
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", chemin, "-ar", str(FE), "-ac", "1", t.name], check=True)
        x, fe = sf.read(t.name, dtype="float32")
    assert fe == FE
    return x


def enveloppe(x, pas=160):
    n = len(x) // pas
    return np.sqrt((x[: n * pas].reshape(n, pas) ** 2).mean(axis=1))


def aligner(ref, recu):
    """Cale le recu sur l'original.

    Le micro factice lit l'original en boucle et l'enregistrement commence a
    un instant quelconque : on cherche donc le recu dans l'original double.
    Puis, par morceaux de 5 s, on rattrape la derive que le tampon de gigue
    cree en accelerant ou en ralentissant le son (plus ou moins 0,6 s).

    Rend (original cale sur le recu, recu, recu repose sur l'original,
    couvert) : le troisieme a la longueur de l'original et commence a son
    debut ; `couvert` dit quels instants de l'original l'enregistrement a
    reellement entendus (un enregistrement plus court que l'original laisse un
    trou, qui n'est pas une perte du reseau).
    """
    pas = 160  # 10 ms
    n_ref = len(ref)
    if len(recu) > n_ref:
        recu = recu[:n_ref]
    double = np.concatenate([ref, ref])
    a, b = enveloppe(double, pas), enveloppe(recu, pas)
    c = correlate(a - a.mean(), b - b.mean(), mode="valid")
    depart = int(np.argmax(c)) * pas
    morceau, marge = 5 * FE, int(0.6 * FE)
    cale = np.zeros_like(recu)
    repose = np.zeros(n_ref, dtype=recu.dtype)
    couvert = np.zeros(n_ref, dtype=bool)
    derive = 0
    for i in range(0, len(recu), morceau):
        r = recu[i : i + morceau]
        if len(r) < FE:
            break
        g = depart + i + derive - marge
        fenetre = double[max(0, g) : g + len(r) + 2 * marge]
        if len(fenetre) < len(r) or not np.any(r):
            j = depart + i + derive
        else:
            cc = correlate(fenetre, r, mode="valid")
            k = int(np.argmax(cc))
            derive += k - (marge if g >= 0 else marge + g)
            j = max(0, g) + k
        cale[i : i + len(r)] = double[j : j + len(r)][: len(r)]
        debut = j % n_ref
        fin = min(n_ref, debut + len(r))
        repose[debut:fin] = r[: fin - debut]
        couvert[debut:fin] = True
        if fin - debut < len(r):  # le morceau passe la fin de l'original
            reste = len(r) - (fin - debut)
            repose[:reste] = r[fin - debut :]
            couvert[:reste] = True
    return cale, recu, repose, couvert


def trous(ref, recu):
    pas = 320  # 20 ms
    n = min(len(ref), len(recu)) // pas
    e = lambda x: np.sqrt((x[: n * pas].reshape(n, pas) ** 2).mean(axis=1))
    er, eu = e(ref), e(recu)
    parle = er > 0.1 * np.percentile(er, 95)
    muet = eu < 0.02 * max(1e-9, np.percentile(eu, 95))
    return float((parle & muet).sum() / max(1, parle.sum()))


MODELE = os.environ.get("BANC_MODELE", "/opt/banc-audio/whisper-quran-ct2")


def transcrire(x):
    """Les mots reconnus dans le signal `x` (mono, 16 kHz).

    Modele : Whisper affine sur la recitation du Coran par Tarteel
    (`tarteel-ai/whisper-base-ar-quran`), converti pour CTranslate2
    (`ct2-transformers-converter --quantization int8`), lu par faster-whisper :
    quelques secondes par enregistrement sur un processeur. Decodage glouton,
    sans contexte d'un passage a l'autre : le meme son donne toujours le meme
    texte, et un passage abime ne contamine pas le suivant.
    """
    global _asr
    try:
        _asr
    except NameError:
        from faster_whisper import WhisperModel
        _asr = WhisperModel(MODELE, device="cpu", compute_type="int8", cpu_threads=2)
    segments, _ = _asr.transcribe(x, language="ar", beam_size=1,
                                  condition_on_previous_text=False, vad_filter=False)
    return " ".join(s.text.strip() for s in segments).strip()


def versets_de(chemin_original):
    """Les bornes des versets de l'original (`<original>.json` a cote du WAV :
    `{"versets": [{"verset", "debut", "fin"}]}`, en secondes), ou `None`."""
    chemin = os.path.splitext(chemin_original)[0] + ".json"
    if not os.path.exists(chemin):
        return None
    with open(chemin, encoding="utf-8") as f:
        return json.load(f)["versets"]


_textes_versets = {}


def mots_par_verset(original, recu, versets):
    """Combien de mots arrivent intacts, verset par verset.

    Chaque verset de l'original est cherche dans l'enregistrement (l'original
    tourne en boucle ; le tampon de gigue etire ou resserre le son, on cale
    donc chaque verset a part, a plus ou moins 0,8 s). Le verset recu est
    transcrit seul et compare a la transcription du meme verset d'origine, par
    le meme modele : une difference vient donc du reseau, pas du modele. Un
    verset que l'enregistrement n'a pas entendu en entier n'est pas compte.

    Rend (mots compares, mots perdus ou changes, versets compares, versets
    abimes).
    """
    import jiwer
    pas = 160
    n_ref = len(original)
    double = np.concatenate([original, original])
    env_recu = enveloppe(recu, pas)
    env_double = enveloppe(double, pas)
    c = correlate(env_double - env_double.mean(), env_recu - env_recu.mean(), mode="valid")
    depart = int(np.argmax(c)) * pas  # l'instant de l'original ou l'enregistrement commence
    marge = int(0.8 * FE)
    mots = erreurs = compares = abimes = 0
    for v in versets:
        a, b = int(v["debut"] * FE), min(n_ref, int(v["fin"] * FE))
        if b - a < FE // 2:
            continue
        ref_v = original[a:b]
        for tour in (0, 1):
            pos = a + tour * n_ref - depart
            if pos < 0 or pos + (b - a) > len(recu):
                continue
            g = max(0, pos - marge)
            fenetre = recu[g : pos + (b - a) + marge]
            e_f, e_v = enveloppe(fenetre, pas), enveloppe(ref_v, pas)
            if len(e_f) < len(e_v):
                continue
            cc = correlate(e_f - e_f.mean(), e_v - e_v.mean(), mode="valid")
            k = g + int(np.argmax(cc)) * pas
            recu_v = recu[k : k + (b - a)]
            if v["verset"] not in _textes_versets:
                _textes_versets[v["verset"]] = transcrire(ref_v)
            t_ref = _textes_versets[v["verset"]]
            if not t_ref:
                continue
            t_recu = transcrire(recu_v)
            mesures = jiwer.process_words(t_ref, t_recu if t_recu else "x")
            n = len(t_ref.split())
            e = min(n, mesures.substitutions + mesures.deletions + mesures.insertions) if t_recu else n
            mots += n
            erreurs += e
            compares += 1
            abimes += 1 if e else 0
            break
    return mots, erreurs, compares, abimes


def noter(original, chemin, sans_asr, versets=None):
    ref, recu, _, _ = aligner(original, lire(chemin))
    from pystoi import stoi
    # Par morceaux de 10 s : la moyenne dit la qualite d'ensemble, le minimum
    # dit le pire passage (un verset abime suffit a fausser une recitation).
    dix = 10 * FE
    notes = [float(stoi(ref[i : i + dix], recu[i : i + dix], FE, extended=True))
             for i in range(0, len(recu) - dix + 1, dix)]
    sortie = {
        "fichier": chemin,
        "duree_s": round(len(ref) / FE, 1),
        "estoi": round(float(np.mean(notes)), 3),
        "estoi_pire": round(float(np.min(notes)), 3),
        "trous": round(trous(ref, recu), 4),
    }
    if not sans_asr and versets:
        mots, erreurs, compares, abimes = mots_par_verset(original, lire(chemin), versets)
        sortie["mots_compares"] = mots
        sortie["mots_perdus"] = erreurs
        sortie["wer"] = round(erreurs / mots, 3) if mots else None
        sortie["versets_compares"] = compares
        sortie["versets_abimes"] = abimes
    return sortie


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    sans_asr = "--sans-asr" in sys.argv
    original = lire(args[0])
    versets = versets_de(args[0])
    # Plusieurs enregistrements : une ligne JSON chacun, le modele charge une fois.
    for chemin in args[1:]:
        try:
            print(json.dumps(noter(original, chemin, sans_asr, versets), ensure_ascii=False), flush=True)
        except Exception as e:  # un enregistrement illisible n'arrete pas le lot
            print(json.dumps({"fichier": chemin, "erreur": str(e)[:200]}), flush=True)


if __name__ == "__main__":
    main()
