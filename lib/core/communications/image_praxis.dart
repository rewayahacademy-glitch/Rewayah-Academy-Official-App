// L'image de profil de Praxis (#Ra_Praxis), EN CODE (PRAXIS-IMAGE, 17/11/2026).
//
// Origine : l'image fournie par le directeur le 17/11/2026 (fichier plein
// format : `assets/brand/praxis/praxis-profil.png`, PR #616), reduite a
// 256 x 256 points et a 24 couleurs (3 Ko). Rangee en octets parce que
// `pubspec.yaml` est interdit aux agents : aucun asset a declarer. Ce n'est
// pas un dessin d'agent : ne pas la redessiner ni la remplacer.
//
// **Seul point d'affichage** : [ImagePraxis]. `AvatarParticipant` l'emploie
// pour le compte officiel dont le code serveur est `praxis`, jamais pour un
// autre compte officiel ni pour une personne.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'nom_officiel.dart';

/// Le code serveur (`compte_officiel`) du compte Praxis.
const String codeComptePraxis = 'praxis';

const String _octetsBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAMAAABrrFhUAAAASFBMVEXz6f7o1f/iz/7cyv3c'
    'yvzcyvvbyvvayfrZyPnZx/nKuueilbxmXXorJjwUESMTECISDyERDiERDiARDh8QDh8OCx0J'
    'BxgEAhLyObvmAAAMK0lEQVR42u2d6ZqjKhCGXRIRFyCOwP3f6VSBGk00saPYcab4dU5Pnpn+'
    'XqgFqiDR5T8fEQEgAASAABAAAkAACAABIAAEgAAQAAJAAAgAASAABIAAEAACQAAIAAEgAASA'
    'ABAAAkAACAABIAAEgAAQAAJAAAgAASAABIAAEAACQAAIAAEgAASAABAAAkAACAABIAAEgAAQ'
    'gE9HxhjL3PgvATCW+JGmKcAAGnnO7yPPGRsAZf8eAMbiuPAD1F7SJIlnxiMhvkDodABQflmJ'
    'P1IIUfejGkbZj4EQAHpFKGOnApCj/NpY3bStxmFw2IcBP9KNGBGqlgklSXYeAL18KZR4MaRU'
    'Sr0hpAdCRcJOAuAu/ybabqJRidZt2zRKSilWDiTUNB6QrTcugegXZr+xsqoGBwCKVKuf53ng'
    'o9vmNuUjGxgKB/yw2EYgOs71DfLbqvBe7MI497Y8mPZg7CM+skVTGLNpuqGErXn69QCm8huQ'
    'n2Agg98bwpz35rNePn3i08NpO/nG1mX87T5gLP+PvaF8PvzOLpa7qJ5PkyEM83c+HlEEIwEY'
    'Va3BBzQS5fON+oMD8HHfu77mUf7bjDljSOOC6hNelGgYbW8CyqD89LvzgLv8pl/8a+WjdpY6'
    '2+Bu1mtY8NboFvweBgFpKxanfHMqGB02++1a+fPSrUHpUt1Au4DAIGwV8x12ClFw+crN/ir5'
    'Trpb8DFD6dVEuvKeX6LrE6009fWbN0NT+fqdfJSee+mXsXQtXd7TDMPJL3ltZLs1AwgJ4C5f'
    'vZM/kp5OpGO6LDHTkZD3TuXHcWWFtGWcfyeAlfKdi89cgOul66l0oTTCEGIc93NwfXEJP0Qn'
    '8I0AVsrPvfSkKF5I1wJ2ghj3b2P5GUtK2AzZemsOEAIAy8fyl11f1kuvJ9JlL9046WXhkijM'
    'e5Rf/C7wZSmvtdRbs+AAAO7y3wS+LCm7nMbta7102Y6lXzD3g49Zg/5f6UE+/jvoBJQud1gC'
    'URD57wJfDkYM0n10c9K1l16jdOb2AjyLOcrv9n66jC5D3OcIQIAX5F8EwMvXqwKfE+ClN7ji'
    'e+ncScdNEL/E+V1+00zVIkDpvCD7FgBj+ept3HcAnHTb4IkXSE966bBLzHg6nn0PYOzzs6QQ'
    'GlIh2CRlX3Ek5j2/draP8ss3WR8IqE37KD1nTsyMfNz61cmEN6RCWsBOOUl//0ToPvvr5DsC'
    'aQm/vJOeDdIX5aMPGCd+LIlwCTW1NFV+uf4ugPvsq07+GsvMLjEs34n0qXzVTIc098QPYog/'
    'E9DNZk8Y7Tb7Pu1ZJ9+De1q7y/InTgBdoHVnIqoRYBrs9wBM056fyJ9bFC/kewDdX83i2vaf'
    'UbgnYr8EgPG77e8jv1qS7w6A+sSPJeAB72C22UC0g/zmB7b/oXwcbT/VPoj2vmHjliD6FvkF'
    'yNcv5I+megJgGh6OAsAgeE/lJ9tn/6X8sRd0u+FmJxuIts2+aq1x8nl2DSrfp0JZHwXuPmDs'
    'HQ8CwPzsQ8aP6w+rPGnqKvmvWx0W5Cfr5I/XOksKff/5bZsNRB/oLzr5uEethkI+S5cqPL7T'
    'IX3qdABYyXvbf06F3E5A7WQD0Qf6BS5+75iFMHq+kv/U6ZDNAVovf+QE8DzEqJ1s4McAJi64'
    'wcq2r+QvFvLVLKCu1idWy/dC8y4VHiUCG+PAZwA+KOTPATI/kD9OhdhkErbZwI8B4E52ppDv'
    'Ox3mf3E/pHzsgYD/7RNa/6fA6/aCwJ+mS4X4I4ANNvBzJ5glxVIhXzRt89MhhwYJh7FFi1Fv'
    'UqEHAJts4JMwmD75edjX+kp+rdUPxIPYpjv9Hii6/1dCqhdecJoJbbOB6KPcZVLIH3U6TGfm'
    'rXptbeuPgH0QvfDCV0iAQjs9EJmkQgwyITXrHn/tTNDnOnw9AInq66oscr+IMEu49l2TvKxq'
    'YY16sIVhqUMoVn+afWxg17qAO6xdJ99YUWHZI0lzPAftEmlMlTClwopRWevHIIGpEHvOhDbZ'
    'wK4Ann6xpcVvYPJRfc7Z3BYiYxzy7eQpTeidwDVl40Rgkw3sXRqb/mKL8svcbaBeOhrm8+RW'
    'POucHIngH0zPjH8PwAonIFqQf13V3MLcVkFYKe9ekKWP/47C6sq3rIDH+DQz/VZWPL7w68p4'
    'gwiMEQ8HgB0ALC21rrBU8a9wghifXvoAnP4CZv8nIRc237Xt0oLe2fkGAVdHVq66Eh+ZCL30'
    'gvxVKiTMrUqSH7Y2MR7zCpzh2AtmKebjWEf29cSEHbcZerdZrpcDocC+zg8a/HERSGcG0nZV'
    'AIg3mD8lPo7mh58JfuIFlbRg/R9Fa8iwYMbdCVTdZTyZK6tBTso29ortDmApFZItLN+Uf/z3'
    '8o5A3xSRuTry9rG7CRRidkcoNf7qnx/c8CTBloJ9miJCJkJpNpsKOf2bGjvZFaxL7tQaFhDA'
    'vBOQut08c1mOf/VO/aEHA/DzvznG5m4NbL0kFBjA41bd+f/G7GK5joDZpT80HIC5DaHcy3Nl'
    'eBq6sxPYvVM0Sx694I6OK7sm9S79oQEBPDkBt4fd6wowhNl6lybxkACmG0LYwvId3Rb89V8O'
    'AM/rRqkQ/Hexq9GyJL18tw94LNztnbrtfKF+/3b5fOwEthxYHzP2BzA5rtJ75y0nAMBG/Rv7'
    'G8AJAIxSIWHrL5//IHeGRqmQLuL/EMDgBPbfu54FgE+FTuABwwCAVKg9zQIIAeDqU6GtLZzn'
    'BdClQudYAEEA+CtR51gAgVYApEInWQBBAPhUSJ8gBAQC4FIhU8Vn0B8GAPeHl/w/BlAuvO/j'
    'HkVZ/4iK60PLzgcAUqFZF8gz3y29rj+CMf/phGen8wGQCj0f37ML9n5hW+AlvrD3sx/H/tN4'
    'C/dkAPBmY/HYtcSTpHQ35q3GJqE3mliKzw66VmRsKAtnB4EeUcmeji5did+4R/DwLYQ3J6U8'
    '4ZWx+ISKkNqKMmbZuQBcHvsWwC82tu9+lcLIl0HC0ep7yZXQ2A6enQvAc1wwetzhrl+FSSx/'
    'TNrBA56tHvScXly0elIwEy8OC67Xaz2tLqlwh4vHAABFRizeBZ7dTM1cGWOnBTDbPymWHkJy'
    'bTZq+fL4+QC4YpF8cR387QJowh2vRL+1APDO3eyqXmg5D+UFDlkByWzj1IKkhVZDaesg28sD'
    'AGC9eHRPZrgKsyBpjEspFdoGokMtwD8Z1rW/39s+H3DJts+XWq2FCGsDBwAYysVKWbw6is8k'
    'dDchZ97CuuPCazU1bAdE0DgQHkCW5r5hQLWmwodho7JLCmbndFRXqss8cr3yISvtBwDovbo0'
    'ZeRH7K18dk77a7Hwh92nK0/g/n7AyQDgJYpmoiiKimUAl9TREaYePu2JAIAsPSkAbwG6GCRF'
    'XuQMgL7DRprRp4V/UHCX9wOPB9A9eCFHU9pN6hIAkDvzaXdj6vqvAChfAYAVMLaXO4AAFnCQ'
    'D/BPQj6vgJko4O9EQpI0t17YKQF0jYMTq679opjZD/pEEPK+aIXHOFUYHK9qZwG3Vs7shrq0'
    'CVbHU8w4ayZ4uQ5hv1cktfJNtOnSXghT/8kCmM8bT7IX6HI7aSsUFVf+eGx+TfepMODxa6A7'
    'HpzfOZxsMySswVcibCuXdzdZfx4kjcG3ZqrGBO24OgDAuHFQGWu6G/FLUzo8ESOVe6Olla9P'
    '0E7gA8bdw3J4HWRpSse7ZzG8qCJ3vy11IIDZK9WLBxzX3mkeciJ21Knw8ynXsk3PHSEKWwdq'
    'ODoEAHPvID8pYosr5pGXDNdzeUxhxF0pVtM3L5YVuWeXxeQtqnD9JofVBqv7SxioX7wqDwOv'
    'dlRJFE3ArvujvmsMl7XBL8i5KSnUu/I4EBAWA8ZNKSFMyH6jowBkDE/3rNatNu7tdf5mxRQV'
    'pgz4aVuXAa/dHPd1e9w/ECXw3Yv3TS/u1dbu09f4dC0y85pS/OakAr86YkW3Az5ZzvAtynhF'
    'Q9E5AODbSP7JtJWPj7vvG01zfr38IwAu7rGwH+Qz14wF/95d+uZpAkAACAABIAAEgAAQAAJA'
    'AAgAASAABIAAEAACQAAIAAEgAASAABAAAkAACAABIAAEgAAQAAJAAAgAASAABIAAEAACQAAI'
    'AAEgAASAABAAAkAACAABIAAEgAAQAAJAAAgAASAABIAAEAACQAAIAAEgAASAAJx2/AWfjg26'
    'rkX2VgAAAABJRU5ErkJggg==';

/// Les octets du PNG, decodes une seule fois.
final Uint8List octetsImagePraxis = base64Decode(_octetsBase64);

/// L'image de Praxis dans un cercle de [diametre] points.
class ImagePraxis extends StatelessWidget {
  /// Cree l'image.
  const ImagePraxis({required this.diametre, super.key});

  /// Le diametre du cercle (jetons `AppAvatar`).
  final double diametre;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.memory(
        octetsImagePraxis,
        width: diametre,
        height: diametre,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: false,
        semanticLabel: nomOfficielMarque(),
      ),
    );
  }
}
