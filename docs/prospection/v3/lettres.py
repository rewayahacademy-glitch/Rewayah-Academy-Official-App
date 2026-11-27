# Les lettres de prospection, v3 (27/11/2026) : Rewayah Academy, complement en ligne des cours sur place,
# pour les eleves qui ne peuvent pas venir (place, horaires, distance). Une lettre par culture.
SIG = {
 'fr': "BarakAllahu fikum,\nAbdoulaye Mouhidine Sow\nDirecteur, Rewayah Academy",
 'en': "JazakAllahu khayran,\nAbdoulaye Mouhidine Sow\nDirector, Rewayah Academy",
 'ar': "بارك الله فيكم،\nعبد الله محي الدين صو\nمدير أكاديمية الرواية",
}
RAISON = {
 'fr': "Vous recevez ce message parce que votre organisation enseigne le Coran et l’annonce publiquement.",
 'en': "You are receiving this message because your organisation teaches the Qur’an and says so publicly.",
 'ar': "وصلكم هذا البريد لأن مؤسستكم تعلّم القرآن وتعلن ذلك.",
}
ALT = {
 'fr': "Pour vos élèves qui ne peuvent pas venir. « Celui qui indique le bien est comme celui qui le fait. » Hadith rapporté par at-Tirmidhî, n° 2670. Rewayah Academy.",
 'en': "For the students who cannot come. “The one who guides to good is like the one who does it.” Hadith narrated by at-Tirmidhi, no. 2670. Rewayah Academy.",
 'ar': "لطلابكم الذين لا يستطيعون الحضور. «الدال على الخير كفاعله» رواه الترمذي (2670). أكاديمية الرواية.",
}
# Segment -> (langue, [sujets], corps). {lien} = lien suivi de l'organisation.
SEG = {
 'fr': ('fr', ["Pour vos élèves qui ne peuvent pas venir", "Quand une famille ne peut pas suivre vos cours"],
  "Assalamu alaykum wa rahmatullah,\n\nVous enseignez le Coran sur place, et c’est le meilleur cadre quand il est possible. Mais certaines familles ne peuvent pas suivre : plus de place, des horaires impossibles, ou la mosquée trop loin.\n\nPour elles, Rewayah Academy propose des cours de Coran en direct, en ligne, en petite classe, avec le même enseignant trois fois par semaine. Nous ne remplaçons pas vos cours : nous allons là où ils ne peuvent pas aller.\n\nUne famille vous vient à l’esprit ? Transmettez-lui ce lien :\n{lien}\n\nLe Prophète ﷺ a dit : « Celui qui indique le bien est comme celui qui le fait. » (at-Tirmidhî)"),
 'fr_qc': ('fr', ["Pour vos élèves qui ne peuvent pas venir", "Quand une famille ne peut pas venir à vos cours de fin de semaine"],
  "Assalamu alaykum wa rahmatullah,\n\nVos cours de Coran de fin de semaine sont précieux. Mais certaines familles ne peuvent pas y venir : groupes complets, horaire qui ne convient pas, ou route trop longue l’hiver.\n\nPour elles, Rewayah Academy offre un complément en ligne : des cours de Coran en direct, en petite classe, avec le même enseignant trois fois par semaine. Nous ne remplaçons pas vos cours : nous rejoignons ceux qu’ils ne peuvent pas rejoindre.\n\nUne famille vous vient à l’esprit ? Transmettez-lui ce lien :\n{lien}\n\nLe Prophète ﷺ a dit : « Celui qui indique le bien est comme celui qui le fait. » (at-Tirmidhî)"),
 'en_uk': ('en', ["For the families who can’t make it to your madrasah", "When a child can’t get a place at your madrasah"],
  "Assalamu alaykum wa rahmatullah,\n\nYour madrasah teaches the Qur’an in person, and that is the best way whenever it is possible. But you will know families who can’t make it: the classes are full, the evening times clash with work or school, or they live too far away.\n\nRewayah Academy is there for them: live online Qur’an classes in small groups, with the same teacher three times a week. We don’t replace your madrasah; we reach the children it can’t.\n\nIf a family comes to mind, simply pass on this link:\n{lien}\n\nThe Prophet ﷺ said: “The one who guides to good is like the one who does it.” (at-Tirmidhi)"),
 'en_na': ('en', ["When a family can’t join your weekend school", "For the families your program can’t fit"],
  "Assalamu alaykum,\n\nYour center gives children something precious: learning the Qur’an together, in person. Still, some families can’t take part: the program is full, the schedule doesn’t work for them, or the drive is simply too long.\n\nThat’s where Rewayah Academy can help: live online Qur’an classes in small groups, with one dedicated teacher, three sessions a week. We complement what you do on site, for the families who can’t be there.\n\nIf a family comes to mind, just share this link with them:\n{lien}\n\nThe Prophet ﷺ said: “The one who guides to good is like the one who does it.” (at-Tirmidhi)"),
 'en_oc': ('en', ["For the families who can’t make it to your madrasa", "When a child misses out on a place"],
  "Assalamu alaykum wa rahmatullah,\n\nYour centre teaches the Qur’an face to face, and nothing beats that when it’s possible. But some families miss out: the classes are full, the times don’t suit, or they live too far out.\n\nRewayah Academy is there for them: live online Qur’an classes in small groups, with the same teacher three times a week. We don’t replace your classes; we reach the children who can’t get to them.\n\nIf a family comes to mind, simply pass on this link:\n{lien}\n\nThe Prophet ﷺ said: “The one who guides to good is like the one who does it.” (at-Tirmidhi)"),
 'en_eu': ('en', ["For the students who cannot come to your classes", "When a family cannot attend your Qur’an classes"],
  "Assalamu alaykum wa rahmatullah,\n\nYou teach the Qur’an in person, and that is the best way when it is possible. But some families in your community cannot attend: there are no places left, the times do not fit, or the mosque is too far.\n\nFor them, Rewayah Academy offers live online Qur’an classes, in small groups, with the same teacher three times a week. We do not replace your classes; we reach those who cannot come to them.\n\nIf a family comes to mind, you only need to send them this link:\n{lien}\n\nThe Prophet ﷺ said: “The one who guides to good is like the one who does it.” (at-Tirmidhi)"),
 'ar': ('ar', ["لطلابكم الذين لا يستطيعون الحضور", "حين لا تجد أسرةٌ مكانًا في حلقاتكم"],
  "السلام عليكم ورحمة الله وبركاته،\n\nجزاكم الله خيرًا على ما تبذلونه في تعليم أبناء الجالية كتاب الله، والتعليم الحضوري خير ما يكون إذا تيسّر. غير أنكم تعرفون أسرًا لا تستطيع الحضور: لامتلاء الأماكن، أو لتعارض المواعيد، أو لبعد المسافة.\n\nولهذه الأسر تقدّم أكاديمية الرواية دروسًا مباشرة في القرآن عن بُعد، في فصول صغيرة، مع المعلّم نفسه، ثلاث مرات في الأسبوع. لسنا بديلًا عن حلقاتكم، وإنما نصل إلى من لا تصل إليه.\n\nفإن خطرت ببالكم أسرة في هذه الحال، فيكفي أن ترسلوا إليها هذا الرابط:\n{lien}\n\nقال رسول الله ﷺ: «الدَّالُّ عَلَى الخَيْرِ كَفَاعِلِهِ» (رواه الترمذي)."),
}
RELANCE = {
 'fr': ("En une phrase", "Assalamu alaykum,\n\nJe vous ai écrit il y a quelques jours ; en une phrase : pour les familles de votre communauté qui ne peuvent pas suivre vos cours sur place, Rewayah Academy propose des cours de Coran en ligne, en complément. Le lien à leur transmettre :\n{lien}"),
 'en': ("In one sentence", "Assalamu alaykum,\n\nI wrote to you a few days ago; in one sentence: for the families in your community who can’t attend your classes in person, Rewayah Academy offers live online Qur’an classes as a complement. The link to pass on:\n{lien}"),
 'ar': ("في سطر واحد", "السلام عليكم ورحمة الله وبركاته،\n\nكتبت إليكم قبل أيام، وخلاصة رسالتي: للأسر التي لا تستطيع حضور حلقاتكم، تقدّم أكاديمية الرواية دروسًا في القرآن عن بُعد، مكمّلةً لما تقومون به. وهذا الرابط لمن أردتم أن ترسلوه إليه:\n{lien}"),
}
def segment(langue, fuseau):
    if langue == 'ar': return 'ar'
    if langue == 'fr': return 'fr_qc' if fuseau.startswith('America/') else 'fr'
    if fuseau.startswith('America/'): return 'en_na'
    if fuseau in ('Europe/London', 'Europe/Dublin'): return 'en_uk'
    if fuseau.startswith(('Australia/', 'Pacific/')): return 'en_oc'
    return 'en_eu'
def corps(langue, texte, lien):
    return f"{texte.replace('{lien}', lien)}\n\n{SIG[langue]}"
if __name__ == '__main__':
    import re
    for k,(lg,s,t) in SEG.items():
        print(k, len(re.findall(r"\S+", re.sub(r'https?://\S+','',corps(lg,t,'https://x')))))
