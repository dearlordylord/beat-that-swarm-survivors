# Сетевые часы, prediction и reconciliation: готовые паттерны

Проверено 25 октября 2026. Исследование первичных документов и исходников; код игры не менялся. Документация библиотек на `latest`/`main` со временем меняется: это обзор архитектур, не предложение установить непроверенные версии.

## Ответ

Да. Большая часть наших ошибок относится к давно описанным паттернам: **fixed timestep**, **client-side prediction + server reconciliation**, **input history с подтверждением исполненного ввода**, **predicted spawning / spawn matching**, **разделение simulation и presentation timelines**. Готовые сетевые стеки реализуют значительную часть этого, но требуют включить игру в их модель времени и идентичности. Транспорт сам по себе этих правил не задаёт.

Прямое совпадение: Gambetta показывает персонажа, который после серверных ответов скачет назад и вперёд. Решение — номер каждого запроса, номер последнего **обработанного** ввода в ответе и повтор ещё не обработанного остатка. Это тот контракт, которого не хватало нашему первоначальному счётчику длительностей heartbeat. [Оригинальная глава Gambetta](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html).

> Статус реализации: описание ниже фиксирует причину ошибки до исправления. Старые `coop-weapon-*` модули удалены; текущий кандидат `coop-combat-prediction.bend` прогнозирует известных врагов и снаряды вместе и пересчитывает их от свежего авторитетного состояния. Результаты проверок записываются в `coop-projectile-visibility.md`.

## Приоритетное дополнение: снаряды попадают рядом с монстрами

После предыдущего исправления пользователь наблюдает следующий класс ошибки: собственный снаряд выглядит плавно, но попадание не совпадает с видимым монстром. Это нельзя считать закрытым проверкой плавности.

В исходной ошибочной версии `coop-browser.mjs` собственное оружие прогнозируется вперёд, а монстры остаются в полученных/interpolated наблюдениях. `coop-weapon-reconcile.bend` сохраняет старую видимую траекторию уже известного выстрела. Таким образом, видимый снаряд, видимый монстр и авторитетное решение о попадании могут относиться к разным состояниям мира. Это вывод из реализации; для конкретного кадра нужно сопоставить shot ID, target ID, серверный tick и показанные координаты.

Этот класс проблем описан в Unity NFE: если при повторной симуляции обновляются одни объекты, а взаимодействующие с ними объекты остаются заморожены в другом времени, столкновения расходятся. Документация предлагает группировку взаимодействующих ghosts, согласованную симуляцию, anticipation и последующее исправление расхождений. [Prediction edge cases / partial snapshots](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/prediction-details.html#possible-mitigations).

Важно различать **prediction correction** и сохранение красивой истории. Unity smoothing уменьшает ошибку между пересчитанным и ранее предсказанным состоянием; сохранение старой траектории навсегда такой сходимости не обеспечивает. [Prediction smoothing](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/prediction-smoothing.html). Для взаимодействий разных временных представлений Unity также имеет историю collision worlds для server-side lag compensation; это дополнительный механизм, а не автоматическое следствие interpolation. [Physics / lag compensation](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/physics.html#using-lag-compensation-predicted-collision-worlds).

**Архитектурная рекомендация для нас:** сперва выбрать согласованную модель контактов. Практически есть два направления:

1. Прогнозировать релевантную группу взаимодействий в Bend: снаряды и состояния противников, от которых зависит полёт/попадание, должны оцениваться на одном прогнозируемом тике. Затем сопоставлять и исправлять прогноз по хосту. Неизвестный будущий ввод другого игрока всё равно может дать misprediction; нужен путь коррекции.
2. Показывать физический бой на согласованном authoritative playback timeline, а немедленную реакцию игрока делать явно косметической anticipation. Это проще по истине попаданий, но требует продуктового решения о видимой задержке оружия.

Авторитетные события попаданий с идентичностью выстрела, цели, тика и контакта полезны в обоих вариантах: по ним можно ровно один раз показать подтверждённый урон на нужной цели. **Одни события не исправят траекторию**, которая визуально летит в стороне. Полный rollback всего ECS — возможное расширение, но не единственный способ задать согласованный локальный collision world.

### Какие законы нужны для этой ошибки

Это предложенные контракты для будущего дизайна, не утверждение, что они уже доказаны:

- **Общее время взаимодействия:** вычисление контакта получает снаряд и цель из одного collision world/tick. Нельзя незаметно смешать predicted future и interpolated past.
- **Авторитетная связь события:** подтверждённый damage/impact относится к конкретной жизни shot/target, конкретному tick и результату того же collision resolver; повторная доставка не дублирует отображение. Для повторного урона ауры нужны различимые hit events, а не дедупликация только по паре shot/target.
- **Сходимость коррекции:** после достаточных свежих снимков и без новых расхождений прогноз сближается с authoritative состоянием на выбранном общем presentation tick. Правило «известный выстрел всегда оставляет старый путь» допускает постоянную ошибку и не удовлетворяет этому требованию.
- **Честная видимая геометрия:** в согласованном визуальном мире collision/hit feedback использует те же радиусы и положения, что и показанная цель; косметический прогноз не объявляется подтверждённым попаданием.

Нужен red-тест контакта: движущиеся цели, пересечение траекторий, смена цели homing, задержка/пакетная доставка, reuse слотов и piercing/периодический урон. Он должен связывать событие хоста с той же целью и проверять геометрию общего состояния, а не только скорость пули и близость её рождения к персонажу. Законы способны закрепить такой контракт; они не восстанавливают отсутствующие сведения о будущем и не выбирают модель времени вместо нас.

## Соответствие нашим сбоям

| Наш сбой | Известный паттерн | Что следует перенять |
| --- | --- | --- |
| Клиент считал тики между отправками, хост — между получениями; одинаковое направление всё равно давало рывки | Numbered input commands + authoritative reconciliation | ACK должен обозначать исполненный префикс одной и той же истории. Длительности доставки не являются длительностями исполнения. [Gambetta](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html) |
| Смешивание timestamp rAF и более свежего `performance.now()` перематывало аккумулятор | Monotonic time source + один владелец fixed-step accumulator | Отделить счётчик игровых тиков от времени измерения и времени кадра. Монотонность источника не доказывает монотонность произвольного смешивания уже взятых образцов. [High Resolution Time](https://www.w3.org/TR/hr-time-3/#now-method), [HTML animation callbacks](https://html.spec.whatwg.org/multipage/imagebitmap-and-animations.html#run-the-animation-frame-callbacks) |
| Персонаж предсказан, его оружие остаётся в серверном прошлом | Predicted spawning, общая логика стрельбы | Предсказывать собственные выстрелы по тому же вводу и сопоставлять их с серверными объектами. [Unity NFE: spawning](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/ghost-spawning.html#implement-predicted-spawning-for-player-spawned-objects) |
| Повторное использование физического слота смешивало жизни разных снарядов | Stable predicted-spawn identity / classification | Идентифицировать логический выстрел отдельно от слота хранения; одного типа и тика может быть недостаточно. [Unity: classification](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/ghost-spawning.html#ghost-classification-and-entity-matching), [Lightyear PreSpawned](https://docs.rs/lightyear_replication/latest/lightyear_replication/#pre-spawning) |
| Новый снимок заново выбирал цель для прошлого выстрела и дополнительно старил видимую пулю | Simulation history и presentation history; replay-safe effects | Сопоставление объекта, повтор симуляции и видимый ход времени должны иметь отдельные контракты. В Source отдельно различаются повторное исполнение команды и первый запуск её звука/эффекта. [Valve HL `HUD_PostRunCmd`](https://github.com/ValveSoftware/halflife/blob/master/cl_dll/hl/hl_weapons.cpp#L983-L1001) |

Последняя строка — сопоставление архитектур, не утверждение, что Source использует нашу конкретную политику сохранения видимой траектории. Наш `WeaponReconcile.rebase` — ограниченный визуальный прогноз, а не полный rollback всех взаимодействующих объектов.

## Что читать: короткий порядок

1. **Glenn Fiedler, Fix Your Timestep!** — фиксированный шаг, аккумулятор, отделение rendering от simulation, предел догоняющих шагов и «spiral of death». Непосредственная основа нашего 60 Hz цикла. Это не руководство по ACK или идентичности снарядов. [Оригинал](https://gafferongames.com/post/fix_your_timestep/).
2. **Gabriel Gambetta, Fast-Paced Multiplayer**, особенно часть II — минимальная понятная модель prediction/reconciliation. Она прямо показывает наши исходные рывки и нужную историю ввода. Далее полезно читать entity interpolation и lag compensation как отдельные задачи. [Серия](https://www.gabrielgambetta.com/client-server-game-architecture.html), [часть II](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html).
3. **Unity Netcode for Entities: prediction и ghost spawning** — самый точный справочник для нашего ECS-примера: owner-predicted объекты, spawning, matching, smoothing и известные edge cases. Особенно важен раздел classification: документация предупреждает, что несколько пуль одного типа в одном тике нельзя надёжно различить по одному spawn tick; tick batching также может сместить применение ввода. [Обзор prediction](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/prediction.html), [spawning/classification](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/ghost-spawning.html#ghost-classification-and-entity-matching).
4. **Lightyear book + API/reference + примеры** — современная открытая реализация для Bevy. Книга автора сама обозначена как неполный набор заметок; для текущего поведения надо сверять её с API и исходниками. [Книга](https://cbournhonesque.github.io/lightyear/book/), [исходники и примеры](https://github.com/cBournhonesque/lightyear), [replication / PreSpawned API](https://docs.rs/lightyear_replication/latest/lightyear_replication/).
5. **Valve Half-Life / Source SDK** — полезны как исходники уже работающей реализации. Есть prediction оружия, история команд и различение первого проигрывания эффектов. Это материал для чтения и сверки архитектуры; перенос кода требует отдельной проверки лицензий. [HL weapon prediction](https://github.com/ValveSoftware/halflife/blob/master/cl_dll/hl/hl_weapons.cpp), [Source prediction](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/prediction.cpp).

## Что дают библиотеки

| Средство | Что действительно берёт на себя | Что остаётся нашей ответственностью |
| --- | --- | --- |
| **Lightyear** | Буферизует ввод по тикам, синхронизирует input timeline, даёт prediction/rollback, interpolation и сопоставление predicted spawns. Его README прямо обещает применение ввода тика N на серверном тике N. [README](https://github.com/cBournhonesque/lightyear#features), [PreSpawned](https://docs.rs/lightyear_replication/latest/lightyear_replication/#pre-spawning) | Интеграция Bevy-систем, предсказываемые компоненты, идентичность и одинаковые правила симуляции. Это Bevy/Rust стек, не подключаемая функция к нашему Bend World. |
| **Bevy Replicon** | Server-authoritative replication ECS, события, visibility и сериализация. I/O отсутствует намеренно; prediction/interpolation/rollback перечислены как экосистемные расширения. [README](https://github.com/simgine/bevy_replicon#features), [ecosystem](https://github.com/simgine/bevy_replicon#ecosystem) | Выбор prediction-слоя и правила игровых часов. Установка одного Replicon не является защитой от наших ошибок. |
| **Unity Netcode for Entities** | Планирует predicted simulation, authoritative snapshots и predicted spawning/classification. Есть default matching, но его ограничения перечислены явно. [Prediction](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/prediction.html), [classification](https://docs.unity3d.com/Packages/com.unity.netcode@1.10/manual/ghost-spawning.html#ghost-classification-and-entity-matching) | Игра должна работать в Unity ECS и использовать нужные группы/компоненты. Не drop-in для Bend; очень полезен как handbook и архитектурный эталон. |
| **GGPO / GGRS** | P2P rollback: прогноз удалённого ввода, scheduling, resimulation; GGRS требует сохранение, загрузку и продвижение игры на один кадр. [GGPO](https://github.com/pond3r/ggpo), [GGRS API](https://docs.rs/ggrs/latest/ggrs/#how-it-works) | Детерминированная повторяемая игровая симуляция и правильное save/load; replay-safe эффекты. Это иной объём интеграции, чем наш authoritative host плюс локальный прогноз. |
| **Iroh** | Шифрованные QUIC-соединения; прикладной протокол определяет поведение поверх них. Документация прямо разделяет connection pool и application protocols. [Iroh protocols](https://docs.iroh.computer/concepts/protocols) | Номера ввода, ACK исполнения, игровые тики, prediction, spawn identity и rendering timeline. Заменять Iroh ради этих ошибок оснований нет. |

**Вывод для нашего проекта (архитектурная оценка):** брать готовые понятия, инварианты и проверочные сценарии стоит сейчас. Подключение Lightyear/NFE целиком потребовало бы отдельного интеграционного слоя или переноса исполнения в другой ECS; это противоречит текущей цели показывать Bend/Bendvy. GGPO/GGRS имеет смысл оценивать, когда появится задача полного rollback/save-load и детерминированного мира, а не как средство исправить один аккумулятор времени.

## Часы: важная тонкость

Наш сбой не был переводом системного времени через NTP. `performance.now()` уже относится к монотонным часам. rAF callback получает timestamp, переданный алгоритмом запуска кадра; выполнение callback может происходить позже другого обработчика, который уже взял более свежий `performance.now()`. Следовательно, присваивание общего `lastTime` из обоих источников без контракта порядка может уменьшить `lastTime`. Это вывод из спецификаций и нашего кода, а не нарушение браузером HR Time. Window и Worker также имеют собственные time origins; сравнение относительных чисел без преобразования не создаёт общий timeline. [HR Time `now`](https://www.w3.org/TR/hr-time-3/#now-method), [time origins](https://www.w3.org/TR/hr-time-3/#sec-time-origin), [HTML rAF](https://html.spec.whatwg.org/multipage/imagebitmap-and-animations.html#run-the-animation-frame-callbacks).

## Что закрепить у нас

Это рекомендации по нашей реализации, а не гарантии перечисленных библиотек:

- Вынести единый небольшой контракт часов/accumulator: измеренные моменты, игровые тики, подтверждённый ввод и визуальный возраст — разные значения. Переходы между ними явные; у аккумулятора один владелец. Проверять старый rAF timestamp после нового сетевого callback и пакетные обновления после паузы.
- Сохранить уже выбранный numbered-input ledger: один локальный input tick, один authoritative consumption, точный cumulative ACK, повтор только suffix. Никогда не восстанавливать длительность исполнения из времени отправки/доставки.
- Описывать каждый вид сущности как predicted, interpolated или authoritative-only. Игрок и собственное оружие должны использовать согласованную временную модель; урон/XP остаются решениями хоста.
- Держать логический ShotId отдельно от physical pool slot и от возраста анимации. Проигрывание эффекта должно быть связано с событием/первым показом, а не с числом replay.
- Зафиксировать реальные playback-проверки в handbook: длинное удержание, разворот, отпускание, потеря/пакетная доставка, pause/resume, reuse слотов, новый снимок с другой целью, ACK с большим скачком world tick. Проверять путь и события, не только первый отклик и финальный endpoint.
- Измерять фактическую задержку обоих направлений. Оверхед тестового транспорта/сериализации не равен намеренно добавленной сетевой задержке; библиотека prediction не исправит неверный измеритель.

Связь с файлами кандидата: `coop-browser.mjs` владеет monotonic accumulator и browser IO; `coop-input-queue.bend` задаёт исполнение и ACK; `coop-prediction-replay.bend` — replay/guards/идентичность; `coop-combat-prediction.bend` пересчитывает известных боевых участников от свежего anchor. Старое сохранение траектории удалено. Это отдельные механизмы примера; корректность временного назначения ввода и переходов между anchor требует самостоятельных проверок. Дальнейшее обобщение в переиспользуемое ядро Bend имеет смысл делать по этим контрактам и законам, сохраняя игровую логику в Bend и Iroh как транспорт.
