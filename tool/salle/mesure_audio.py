#!/usr/bin/env python3
"""Banc de la salle : mesure objective de ce que l'eleve entend.

Compare l'enregistrement recu par l'eleve a la recitation d'origine :
  - STOI etendu (Jensen et Taal, 2016) : intelligibilite objective, de 0 a 1 ;
  - mots reconnus : un modele de reconnaissance de la recitation du Coran
    (Whisper affine par Tarteel) transcrit l'original et le recu ; le taux
    d'erreur de mots (WER) du recu par rapport a l'original dit combien de
    mots ont ete perdus ou changes par le reseau ;
  - trous : part du temps ou le signal recu est muet alors que l'original
    ne l'est pas.

Usage : mesure_audio.py <original.wav> <recu.(wav|webm)>... [--sans-asr]
Sortie : une ligne JSON par enregistrement.
"""
import json
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
    """Cale le recu sur l'original ; rend (original cale, recu).

    Le micro factice lit l'original en boucle et l'enregistrement commence a
    un instant quelconque : on cherche donc le recu dans l'original double.
    Puis, par morceaux de 5 s, on rattrape la derive que le tampon de gigue
    cree en accelerant ou en ralentissant le son (plus ou moins 0,6 s).
    Rend (original cale, recu, decalage initial en secondes).
    """
    pas = 160  # 10 ms
    if len(recu) > len(ref):
        recu = recu[: len(ref)]
    double = np.concatenate([ref, ref])
    a, b = enveloppe(double, pas), enveloppe(recu, pas)
    c = correlate(a - a.mean(), b - b.mean(), mode="valid")
    depart = int(np.argmax(c)) * pas
    morceau, marge = 5 * FE, int(0.6 * FE)
    cale = np.zeros_like(recu)
    derive = 0
    for i in range(0, len(recu), morceau):
        r = recu[i : i + morceau]
        if len(r) < FE:
            break
        g = depart + i + derive - marge
        fenetre = double[max(0, g) : g + len(r) + 2 * marge]
        if len(fenetre) < len(r) or not np.any(r):
            cale[i : i + len(r)] = double[depart + i + derive : depart + i + derive + len(r)][: len(r)]
            continue
        cc = correlate(fenetre, r, mode="valid")
        k = int(np.argmax(cc))
        derive += k - (marge if g >= 0 else marge + g)
        j = max(0, g) + k
        cale[i : i + len(r)] = double[j : j + len(r)]
    return cale, recu


def trous(ref, recu):
    pas = 320  # 20 ms
    n = min(len(ref), len(recu)) // pas
    e = lambda x: np.sqrt((x[: n * pas].reshape(n, pas) ** 2).mean(axis=1))
    er, eu = e(ref), e(recu)
    parle = er > 0.1 * np.percentile(er, 95)
    muet = eu < 0.02 * max(1e-9, np.percentile(eu, 95))
    return float((parle & muet).sum() / max(1, parle.sum()))


def transcrire(x):
    import torch
    from transformers import pipeline
    global _asr
    try:
        _asr
    except NameError:
        torch.set_num_threads(4)
        _asr = pipeline("automatic-speech-recognition", model="tarteel-ai/whisper-base-ar-quran", device="cpu")
    r = _asr({"raw": x, "sampling_rate": FE}, chunk_length_s=30)
    return r["text"].strip()


def noter(original, chemin, sans_asr, texte_original=None):
    ref, recu = aligner(original, lire(chemin))
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
    if not sans_asr:
        import jiwer
        t_ref, t_recu = transcrire(ref), transcrire(recu)
        sortie["mots_original"] = len(t_ref.split())
        sortie["wer"] = round(float(jiwer.wer(t_ref, t_recu)), 3) if t_recu else 1.0
        sortie["texte_recu"] = t_recu
    return sortie


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    sans_asr = "--sans-asr" in sys.argv
    original = lire(args[0])
    # Plusieurs enregistrements : une ligne JSON chacun, le modele charge une fois.
    for chemin in args[1:]:
        try:
            print(json.dumps(noter(original, chemin, sans_asr), ensure_ascii=False), flush=True)
        except Exception as e:  # un enregistrement illisible n'arrete pas le lot
            print(json.dumps({"fichier": chemin, "erreur": str(e)[:200]}), flush=True)


if __name__ == "__main__":
    main()
