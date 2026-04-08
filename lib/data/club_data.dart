class ClubInfo {
  final String nameRu;
  final String logoPath;
  final int? color1;
  final int? color2;

  const ClubInfo({
    required this.nameRu,
    required this.logoPath,
    this.color1,
    this.color2,
  });
}

// Map of Team ID to ClubInfo
// IDs are from football-data.org
const Map<int, ClubInfo> clubData = {
  42: ClubInfo(
    nameRu: 'Арсенал',
    logoPath: 'assets/icons/arsenal.svg',
    color1: 0xFFEF0107,
    color2: 0xFF023474,
  ),
  66: ClubInfo(
    nameRu: 'Астон Вилла',
    logoPath: 'assets/icons/aston-villa.svg',
    color1: 0xFF670E36,
  ),
  49: ClubInfo(
    nameRu: 'Челси',
    logoPath: 'assets/icons/chelsea.svg',
    color1: 0xFF034694,
  ),
  45: ClubInfo(
    nameRu: 'Эвертон',
    logoPath: 'assets/icons/everton.svg',
    color1: 0xFF00009E,
    color2: 0xFFFFFFFF,
  ),
  36: ClubInfo(
    nameRu: 'Фулхэм',
    logoPath: 'assets/icons/fulham.svg',
    color1: 0xFF000000,
    color2: 0xFFFFFFFF,
  ),
  40: ClubInfo(
    nameRu: 'Ливерпуль',
    logoPath: 'assets/icons/liverpool.svg',
    color1: 0xFFD00027,
    color2: 0xFFB40027,
  ),
  50: ClubInfo(
    nameRu: 'Манчестер Сити',
    logoPath: 'assets/icons/man-city.svg',
    color1: 0xFF6CABDD,
  ),
  33: ClubInfo(
    nameRu: 'Манчестер Юнайтед',
    logoPath: 'assets/icons/man-utd.svg',
    color1: 0xFFDA291C,
  ),
  34: ClubInfo(
    nameRu: 'Ньюкасл',
    logoPath: 'assets/icons/newcastle.svg',
    color1: 0xFF241F20,
    color2: 0xFFFFFFFF,
  ),
  746: ClubInfo(
    nameRu: 'Сандерленд',
    logoPath: 'assets/icons/sunderland.svg',
    color1: 0xFFEE2737,
    color2: 0xFF000000,
  ),
  47: ClubInfo(
    nameRu: 'Тоттенхэм',
    logoPath: 'assets/icons/tottenham.svg',
    color1: 0xFF132257,
  ),
  39: ClubInfo(
    nameRu: 'Вулверхэмптон',
    logoPath: 'assets/icons/wolves.svg',
    color1: 0xFFFDB913,
    color2: 0xFF231F20,
  ),
  44: ClubInfo(
    nameRu: 'Бёрнли',
    logoPath: 'assets/icons/burnley.svg',
    color1: 0xFF6C1D45,
    color2: 0xFF99D6EA,
  ),
  338: ClubInfo(
    nameRu: 'Лестер',
    logoPath: 'assets/icons/leicester.svg',
    color1: 0xFF003090,
    color2: 0xFFFBDE11,
  ),
  340: ClubInfo(
    nameRu: 'Саутгемптон',
    logoPath: 'assets/icons/southampton.svg',
    color1: 0xFFD71920,
    color2: 0xFF130c0e,
  ),
  63: ClubInfo(
    nameRu: 'Лидс',
    logoPath: 'assets/icons/leeds.svg',
    color1: 0xFF1D428A,
    color2: 0xFFFFCD00,
  ),
  65: ClubInfo(
    nameRu: 'Ноттингем Форест',
    logoPath: 'assets/icons/nottingham.svg',
  ),
  52: ClubInfo(
    nameRu: 'Кристал Пэлас',
    logoPath: 'assets/icons/crystal-palace.svg',
  ),
  51: ClubInfo(
    nameRu: 'Брайтон',
    logoPath: 'assets/icons/brighton.svg',
    color1: 0xFF0057B8,
    color2: 0xFFFFCD00,
  ),
  55: ClubInfo(nameRu: 'Брентфорд', logoPath: 'assets/icons/brentford.svg'),
  48: ClubInfo(nameRu: 'Вест Хэм', logoPath: 'assets/icons/west-ham.svg'),
  35: ClubInfo(nameRu: 'Борнмут', logoPath: 'assets/icons/bournemouth.svg'),
  349: ClubInfo(nameRu: 'Ипсвич Таун', logoPath: 'assets/icons/ipswich.svg'),

  // La Liga
  541: ClubInfo(
    nameRu: 'Реал Мадрид',
    logoPath: 'assets/icons/La liga/Real Madrid.svg',
  ),
  529: ClubInfo(
    nameRu: 'Барселона',
    logoPath: 'assets/icons/La liga/Barcelona.svg',
  ),
  533: ClubInfo(
    nameRu: 'Вильярреал',
    logoPath: 'assets/icons/La liga/Villarreal CF.svg',
  ),
  530: ClubInfo(
    nameRu: 'Атлетико Мадрид',
    logoPath: 'assets/icons/La liga/Atlético Madrid.svg',
  ),
  543: ClubInfo(
    nameRu: 'Бетис',
    logoPath: 'assets/icons/La liga/Real Betis.svg',
  ),
  540: ClubInfo(
    nameRu: 'Эспаньол',
    logoPath: 'assets/icons/La liga/Espanyol.svg',
  ),
  546: ClubInfo(
    nameRu: 'Хетафе',
    logoPath: 'assets/icons/La liga/Getafe CF.svg',
  ),
  531: ClubInfo(
    nameRu: 'Атлетик Бильбао',
    logoPath: 'assets/icons/La liga/Athletic Bilbao.svg',
  ),
  548: ClubInfo(
    nameRu: 'Реал Сосьедад',
    logoPath: 'assets/icons/La liga/Real Sociedad.svg',
  ),
  797: ClubInfo(nameRu: 'Эльче', logoPath: 'assets/icons/La liga/Elche.svg'),
  536: ClubInfo(
    nameRu: 'Севилья',
    logoPath: 'assets/icons/La liga/Sevilla FC.svg',
  ),
  538: ClubInfo(
    nameRu: 'Сельта',
    logoPath: 'assets/icons/La liga/Celta de Vigo.svg',
  ),
  728: ClubInfo(
    nameRu: 'Райо Вальекано',
    logoPath: 'assets/icons/La liga/Rayo Vallecano.svg',
  ),
  542: ClubInfo(
    nameRu: 'Алавес',
    logoPath: 'assets/icons/La liga/Deportivo Alavés.svg',
  ),
  532: ClubInfo(
    nameRu: 'Валенсия',
    logoPath: 'assets/icons/La liga/Valencia CF.svg',
  ),
  798: ClubInfo(
    nameRu: 'Мальорка',
    logoPath: 'assets/icons/La liga/Mallorca.svg',
  ),
  727: ClubInfo(
    nameRu: 'Осасуна',
    logoPath: 'assets/icons/La liga/Osasuna.svg',
  ),
  547: ClubInfo(nameRu: 'Жирона', logoPath: 'assets/icons/La liga/Girona.svg'),
  539: ClubInfo(
    nameRu: 'Леванте',
    logoPath: 'assets/icons/La liga/Levante.svg',
  ),
  718: ClubInfo(
    nameRu: 'Овьедо',
    logoPath: 'assets/icons/La liga/Real Oviedo.svg',
  ),

  // Bundesliga
  157: ClubInfo(
    nameRu: 'Бавария',
    logoPath: 'assets/icons/Bundesliga/Bayern Munich.svg',
  ),
  173: ClubInfo(
    nameRu: 'РБ Лейпциг',
    logoPath: 'assets/icons/Bundesliga/RB Leipzig.svg',
  ),
  168: ClubInfo(
    nameRu: 'Байер',
    logoPath: 'assets/icons/Bundesliga/Bayer Leverkusen.svg',
  ),
  165: ClubInfo(
    nameRu: 'Боруссия Д',
    logoPath: 'assets/icons/Bundesliga/Borussia.svg',
  ),
  172: ClubInfo(
    nameRu: 'Штутгарт',
    logoPath: 'assets/icons/Bundesliga/VfB Stuttgart.svg',
  ),
  169: ClubInfo(
    nameRu: 'Айнтрахт',
    logoPath: 'assets/icons/Bundesliga/Eintracht.svg',
  ),
  167: ClubInfo(
    nameRu: 'Хоффенхайм',
    logoPath: 'assets/icons/Bundesliga/TSG 1899 Hoffenheim.svg',
  ),
  182: ClubInfo(nameRu: 'Унион', logoPath: 'assets/icons/Bundesliga/Union.svg'),
  162: ClubInfo(
    nameRu: 'Вердер',
    logoPath: 'assets/icons/Bundesliga/Werder.svg',
  ),
  192: ClubInfo(nameRu: 'Кёльн', logoPath: 'assets/icons/Bundesliga/Köln.svg'),
  160: ClubInfo(
    nameRu: 'Фрайбург',
    logoPath: 'assets/icons/Bundesliga/SC Freiburg.svg',
  ),
  163: ClubInfo(
    nameRu: 'Боруссия М',
    logoPath: 'assets/icons/Bundesliga/Borussia Mönchengladbach.svg',
  ),
  170: ClubInfo(
    nameRu: 'Аугсбург',
    logoPath: 'assets/icons/Bundesliga/Augsburg.svg',
  ),
  175: ClubInfo(
    nameRu: 'Гамбург',
    logoPath: 'assets/icons/Bundesliga/Hamburger SV.svg',
  ),
  161: ClubInfo(
    nameRu: 'Вольфсбург',
    logoPath: 'assets/icons/Bundesliga/VfL Wolfsburg.svg',
  ),
  186: ClubInfo(
    nameRu: 'Санкт-Паули',
    logoPath: 'assets/icons/Bundesliga/FC St. Pauli.svg',
  ),
  164: ClubInfo(
    nameRu: 'Майнц',
    logoPath: 'assets/icons/Bundesliga/Mainz 05.svg',
  ),
  180: ClubInfo(
    nameRu: 'Хайденхайм',
    logoPath: 'assets/icons/Bundesliga/Heidenheim.svg',
  ),

  // Ligue 1
  85: ClubInfo(
    nameRu: 'ПСЖ',
    logoPath: 'assets/icons/Ligue 1/Paris Saint-Germain.svg',
  ),
  81: ClubInfo(
    nameRu: 'Марсель',
    logoPath: 'assets/icons/Ligue 1/Marseille.svg',
  ),
  116: ClubInfo(nameRu: 'Ланс', logoPath: 'assets/icons/Ligue 1/RC Lens.png'),
  79: ClubInfo(nameRu: 'Лилль', logoPath: 'assets/icons/Ligue 1/Lille.svg'),
  95: ClubInfo(
    nameRu: 'Страсбур',
    logoPath: 'assets/icons/Ligue 1/RC Strasbourg Alsace.svg',
  ),
  94: ClubInfo(nameRu: 'Ренн', logoPath: 'assets/icons/Ligue 1/Rennes.svg'),
  80: ClubInfo(nameRu: 'Лион', logoPath: 'assets/icons/Ligue 1/Lyon.svg'),
  91: ClubInfo(
    nameRu: 'Монако',
    logoPath: 'assets/icons/Ligue 1/AS Monaco.svg',
  ),
  84: ClubInfo(nameRu: 'Ницца', logoPath: 'assets/icons/Ligue 1/Nice.svg'),
  96: ClubInfo(nameRu: 'Тулуза', logoPath: 'assets/icons/Ligue 1/Toulouse.svg'),
  77: ClubInfo(nameRu: 'Анже', logoPath: 'assets/icons/Ligue 1/Angers.svg'),
  114: ClubInfo(nameRu: 'Париж', logoPath: 'assets/icons/Ligue 1/Paris FC.svg'),
  111: ClubInfo(
    nameRu: 'Гавр',
    logoPath: 'assets/icons/Ligue 1/Le Havre AC.svg',
  ),
  106: ClubInfo(nameRu: 'Брест', logoPath: 'assets/icons/Ligue 1/Brest.svg'),
  83: ClubInfo(nameRu: 'Нант', logoPath: 'assets/icons/Ligue 1/Nantes.svg'),
  97: ClubInfo(nameRu: 'Лорьян', logoPath: 'assets/icons/Ligue 1/Lorient.svg'),
  112: ClubInfo(nameRu: 'Мец', logoPath: 'assets/icons/Ligue 1/FC Metz.svg'),
  108: ClubInfo(nameRu: 'Осер', logoPath: 'assets/icons/Ligue 1/Auxerre.svg'),

  // Serie A
  497: ClubInfo(nameRu: 'Рома', logoPath: 'assets/icons/Seria A/Roma.svg'),
  489: ClubInfo(nameRu: 'Милан', logoPath: 'assets/icons/Seria A/Milan.svg'),
  492: ClubInfo(nameRu: 'Наполи', logoPath: 'assets/icons/Seria A/Napoli.svg'),
  505: ClubInfo(nameRu: 'Интер', logoPath: 'assets/icons/Seria A/Inter.svg'),
  500: ClubInfo(
    nameRu: 'Болонья',
    logoPath: 'assets/icons/Seria A/Bologna.svg',
  ),
  895: ClubInfo(nameRu: 'Комо', logoPath: 'assets/icons/Seria A/Como.svg'),
  496: ClubInfo(
    nameRu: 'Ювентус',
    logoPath: 'assets/icons/Seria A/Juventus.svg',
  ),
  487: ClubInfo(nameRu: 'Лацио', logoPath: 'assets/icons/Seria A/Lazio.svg'),
  488: ClubInfo(
    nameRu: 'Сассуоло',
    logoPath: 'assets/icons/Seria A/Sassuolo.svg',
  ),
  494: ClubInfo(
    nameRu: 'Удинезе',
    logoPath: 'assets/icons/Seria A/Udinese.svg',
  ),
  520: ClubInfo(
    nameRu: 'Кремонезе',
    logoPath: 'assets/icons/Seria A/Cremonese.svg',
  ),
  503: ClubInfo(nameRu: 'Торино', logoPath: 'assets/icons/Seria A/Torino.svg'),
  499: ClubInfo(
    nameRu: 'Аталанта',
    logoPath: 'assets/icons/Seria A/Atalanta.svg',
  ),
  490: ClubInfo(
    nameRu: 'Кальяри',
    logoPath: 'assets/icons/Seria A/Cagliari.svg',
  ),
  523: ClubInfo(nameRu: 'Парма', logoPath: 'assets/icons/Seria A/Parma.svg'),
  801: ClubInfo(nameRu: 'Пиза', logoPath: 'assets/icons/Seria A/Pisa.svg'),
  867: ClubInfo(nameRu: 'Лечче', logoPath: 'assets/icons/Seria A/Lecce.svg'),
  495: ClubInfo(nameRu: 'Дженоа', logoPath: 'assets/icons/Seria A/Genoa.svg'),
  502: ClubInfo(
    nameRu: 'Фиорентина',
    logoPath: 'assets/icons/Seria A/Fiorentina.svg',
  ),
  504: ClubInfo(nameRu: 'Верона', logoPath: 'assets/icons/Seria A/Verona.svg'),

  // Others
  645: ClubInfo(
    nameRu: 'Галатасарай',
    logoPath: 'assets/icons/Others/Galatasaray.png',
  ),
  228: ClubInfo(
    nameRu: 'Спортинг',
    logoPath: 'assets/icons/Others/Sporting.svg',
  ),
  556: ClubInfo(nameRu: 'Карабах', logoPath: 'assets/icons/Others/Qarabag.svg'),
  1393: ClubInfo(
    nameRu: 'Юнион',
    logoPath: 'assets/icons/Others/Union Saint-Gilloise.svg',
  ),
  197: ClubInfo(
    nameRu: 'ПСВ',
    logoPath: 'assets/icons/Others/PSV Eindhoven.svg',
  ),
  3403: ClubInfo(nameRu: 'Пафос', logoPath: 'assets/icons/Others/Pafos.png'),
  569: ClubInfo(
    nameRu: 'Брюгге',
    logoPath: 'assets/icons/Others/Club Brugge.svg',
  ),
  211: ClubInfo(nameRu: 'Бенфика', logoPath: 'assets/icons/Others/Benfica.png'),
  560: ClubInfo(
    nameRu: 'Славия Прага',
    logoPath: 'assets/icons/Others/SK Slavia Praha.svg',
  ),
  327: ClubInfo(
    nameRu: 'Будё-Глимт',
    logoPath: 'assets/icons/Others/Bodø-Glimt.svg',
  ),
  553: ClubInfo(
    nameRu: 'Олимпиакос',
    logoPath: 'assets/icons/Others/Olympiacos.png',
  ),
  400: ClubInfo(
    nameRu: 'Копенгаген',
    logoPath: 'assets/icons/Others/F.C. Copenhagen.svg',
  ),
  664: ClubInfo(nameRu: 'Кайрат', logoPath: 'assets/icons/Others/Kairat.png'),
  194: ClubInfo(nameRu: 'Аякс', logoPath: 'assets/icons/Others/Ajax.svg'),
  209: ClubInfo(nameRu: 'Фейеноорд', logoPath: ''),
  247: ClubInfo(nameRu: 'Селтик', logoPath: ''),
  619: ClubInfo(nameRu: 'ПАОК', logoPath: ''),
  319: ClubInfo(nameRu: 'Бранн', logoPath: ''),
  566: ClubInfo(nameRu: 'Лудогорец', logoPath: ''),
  611: ClubInfo(nameRu: 'Фенербахче', logoPath: ''),
  651: ClubInfo(nameRu: 'Ференцварош', logoPath: ''),
  397: ClubInfo(nameRu: 'Мидтьюлланн', logoPath: ''),
  620: ClubInfo(nameRu: 'Динамо Загреб', logoPath: ''),
  567: ClubInfo(nameRu: 'Виктория Пльзень', logoPath: ''),
  212: ClubInfo(nameRu: 'Порту', logoPath: ''),
  565: ClubInfo(nameRu: 'Янг Бойз', logoPath: ''),
  571: ClubInfo(nameRu: 'Зальцбург', logoPath: ''),
  257: ClubInfo(nameRu: 'Рейнджерс', logoPath: ''),
  217: ClubInfo(nameRu: 'Брага', logoPath: ''),
  410: ClubInfo(nameRu: 'Гоу Эхед Иглс', logoPath: ''),
  598: ClubInfo(nameRu: 'Црвена Звезда', logoPath: ''),
  559: ClubInfo(nameRu: 'ФКСБ', logoPath: ''),
  207: ClubInfo(nameRu: 'Утрехт', logoPath: ''),
  617: ClubInfo(nameRu: 'Панатинаикос', logoPath: ''),
  637: ClubInfo(nameRu: 'Штурм', logoPath: ''),
  375: ClubInfo(nameRu: 'Мальмё', logoPath: ''),
  742: ClubInfo(nameRu: 'Генк', logoPath: ''),
  551: ClubInfo(nameRu: 'Базель', logoPath: ''),
  604: ClubInfo(nameRu: 'Маккаби Тель-Авив', logoPath: ''),

  // Conference League additions
  588: ClubInfo(nameRu: 'Зриньски', logoPath: ''),
  367: ClubInfo(nameRu: 'Хеккен', logoPath: ''),
  201: ClubInfo(nameRu: 'АЗ Алкмар', logoPath: ''),
  3854: ClubInfo(nameRu: 'Шелбурн', logoPath: ''),
  632: ClubInfo(nameRu: 'Университатя Крайова', logoPath: ''),
  656: ClubInfo(nameRu: 'Слован Братислава', logoPath: ''),
  347: ClubInfo(nameRu: 'Лех', logoPath: ''),
  1014: ClubInfo(nameRu: 'Лозанна', logoPath: ''),
  3402: ClubInfo(nameRu: 'Омония', logoPath: ''),
  572: ClubInfo(nameRu: 'Динамо Киев', logoPath: ''),
  4626: ClubInfo(nameRu: 'Хамрун Спартанс', logoPath: ''),
  667: ClubInfo(nameRu: 'Линкольн Ред Импс', logoPath: ''),
  2250: ClubInfo(nameRu: 'Сигма', logoPath: ''),
  4360: ClubInfo(nameRu: 'Целе', logoPath: ''),
  3491: ClubInfo(nameRu: 'Ракув', logoPath: ''),
  781: ClubInfo(nameRu: 'Рапид Вена', logoPath: ''),
  14281: ClubInfo(nameRu: 'Дрита', logoPath: ''),
  609: ClubInfo(nameRu: 'Шкендия', logoPath: ''),
  652: ClubInfo(nameRu: 'Шемрок Роверс', logoPath: ''),
  550: ClubInfo(nameRu: 'Шахтер Донецк', logoPath: ''),
  339: ClubInfo(nameRu: 'Легия', logoPath: ''),
  628: ClubInfo(nameRu: 'Спарта Прага', logoPath: ''),
  575: ClubInfo(nameRu: 'АЕК', logoPath: ''),
  561: ClubInfo(nameRu: 'Риека', logoPath: ''),
  614: ClubInfo(nameRu: 'АЕК Ларнака', logoPath: ''),
  252: ClubInfo(nameRu: 'Абердин', logoPath: ''),
  3684: ClubInfo(nameRu: 'Ноа', logoPath: 'assets/icons/Others/Noah.svg'),
  276: ClubInfo(nameRu: 'Брейдаблик', logoPath: ''),
  3603: ClubInfo(nameRu: 'Самсунспор', logoPath: ''),
  336: ClubInfo(nameRu: 'Ягеллония', logoPath: ''),
  1165: ClubInfo(nameRu: 'КуПС', logoPath: ''),
};

// Helper to get club info safely
ClubInfo getClubInfo(int id, String defaultName) {
  return clubData[id] ?? ClubInfo(nameRu: defaultName, logoPath: '');
}
