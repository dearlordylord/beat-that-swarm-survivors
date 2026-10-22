# Выбор игры для демонстрации Bendvy ECS

Исследование: 2026-10-21 00:33:48–01:33:52 UTC, 1 час 00 минут 04 секунды до фиксации итоговой сводки. Запрошенный минимум в один час соблюдён.

Статус: завершено. Все 10 первичных отчётов, перекрёстные проверки и сводная рекомендация готовы.

Все исследовательские файлы находятся в `bend-games`; исходный `bendvy` читается без изменений. Десять отдельных исследователей Luna с максимальным reasoning запускаются двумя волнами: среда допускает пять рабочих агентов одновременно плюс координатора.

## Исследовательские гипотезы

| № | Гипотеза | Файл | Волна |
|---|---|---|---|
| 1 | Vampire Survivors / Brotato: массовый бой и композиция оружия | [01-survivors.md](01-survivors.md) | 1 |
| 2 | Factorio / Mindustry / shapez: производство и транспорт | [02-factory.md](02-factory.md) | 1 |
| 3 | RimWorld / Dwarf Fortress / Oxygen Not Included: колония и агенты | [03-colony.md](03-colony.md) | 1 |
| 4 | Noita / Magicka: системные заклинания и взаимодействия | [04-systemic-sandbox.md](04-systemic-sandbox.md) | 1 |
| 5 | Supreme Commander / BAR / StarCraft: RTS | [05-rts.md](05-rts.md) | 1 |
| 6 | Caves of Qud / CDDA: предметы, эффекты и системный roguelike | [06-systemic-roguelike.md](06-systemic-roguelike.md) | 2 |
| 7 | Space Station 13 / 14: системная станция | [07-space-station.md](07-space-station.md) | 2 |
| 8 | FTL / Cosmoteer: корабли из подсистем | [08-modular-ships.md](08-modular-ships.md) | 2 |
| 9 | Plants vs. Zombies / Dungeon Defenders: защита и композиция башен | [09-tower-defense.md](09-tower-defense.md) | 2 |
| 10 | Opus Magnum / The Incredible Machine / Baba Is You: правила и композиция | [10-rule-puzzles.md](10-rule-puzzles.md) | 2 |

## Общая методика

1. Первичные источники: официальные страницы игр, материалы разработчиков, открытый исходный код. Источник о механике игры не доказывает архитектуру её движка.
2. Различать привлекательность игры, пригодность ECS и пригодность именно текущего Bendvy.
3. Оценивать причинную пользу ECS: независимые комбинации компонентов и пересекающиеся системные запросы; отношения и жизненные циклы; события и независимые читатели; фазы и структурные барьеры; наблюдаемость и сохранение мира.
4. Массовость сама по себе не доказывает пользу ECS. Клеточные автоматы, графовые решатели, pathfinding, физика и рендеринг требуют собственной архитектуры.
5. Не заявлять масштаб, FPS, ускорение или детерминизм без исполняемого подтверждения. В этом исследовании не запускаются кампании производительности и не меняется ECS.
6. Для каждого направления: наиболее сильная версия гипотезы, опровергающие аргументы, реальный первый игровой срез, зависимости от host, критерий отказа от рекомендации.
7. После первичных отчётов: сопоставление по единой шкале, перекрёстная критика, проверка спорных источников, итоговый выбор с альтернативами.

## Исходные факты проекта

Прочитаны `bendvy/README.md`, `docs/next-core-checkpoint.md`, `docs/agent-workflow.md`, `docs/SPEC.md`, `examples/arena/README.md` и начало актуального parity index.

- Bendvy предоставляет ECS, но не полноценный игровой движок: renderer, физика, audio и asset pipeline не входят в заявленный scope.
- Есть компоненты, запросы, ресурсы, события, расписания, deferred commands, отношения, состояния, инспекция, снимки с ограниченным контрактом. Наличие API не доказывает пригодность на масштабе выбранной игры.
- Browser arena уже показывает enemies, pickups, bolts, pulses и chains, но хранит составной `Body` и использует direct query orchestration. Следующая игра должна доказывать пользу независимой композиции компонентов и нескольких систем, если цель — раскрыть ECS глубже текущей демки.
- Количественная оптимизация отложена текущим SPEC; исследование выбора игры не возобновляет её.

Итоговый документ и журнал контроля будут добавлены по завершении проверки гипотез.


## Проверки и сводка

- [REPORT.md](REPORT.md) — сводная рекомендация, альтернативы и ограничения. Итог зафиксирован после часовой границы. Ранние ревью сохраняют статус и время их проведения.
- [11-coordination-log.md](11-coordination-log.md) — время, контроль исследователей и исправленные ошибки.
- [12-cross-entity-access-audit.md](12-cross-entity-access-audit.md), [18-api-audit-review.md](18-api-audit-review.md), [19-recommendation-risk-review.md](19-recommendation-risk-review.md) — выразимость текущего Bendvy и независимая проверка.
- [13-clone-scope-audit.md](13-clone-scope-audit.md) — где остаётся узнаваемый клон, а где уже original inspired game.
- [14-singleplayer-immersive-sim.md](14-singleplayer-immersive-sim.md) — дополнительная проверка Streets of Rogue, Spelunky, Don't Starve и Rain World.
- [15-finalists-gameplay-traces.md](15-finalists-gameplay-traces.md) — придуманные и вручную рассчитанные игровые сценарии; не runtime evidence.
- [16-station-vs-streets-review.md](16-station-vs-streets-review.md), [17-independent-ranking.md](17-independent-ranking.md) — независимые сравнения финалистов.
- [20-synthesis-skeptical-review.md](20-synthesis-skeptical-review.md), [21-synthesis-factual-review.md](21-synthesis-factual-review.md) — критика аргументации и фактическая проверка сводки.
- [22-data-oriented-counterargument.md](22-data-oriented-counterargument.md) — альтернативное прочтение ECS как массовых регулярных queries, без измерений.
- [23-component-granularity-audit.md](23-component-granularity-audit.md) — почему marker count и отсутствие любых enum веток не являются мерой качества ECS.

Сводка отражает исправления поздних проверок. Первичные гипотезы, независимые возражения и результаты опровержений сохраняются раздельно, чтобы было видно основания решения.

- [24a — станционный interaction](24a-station-matched-interaction.md) и [24b — колониальный interaction](24b-colony-matched-interaction.md) — сопоставление по одинаковому учёту query/solver границ.
- [25 — host interface](25-host-interface-audit.md) — input, удержание App/World, render DTO и внешние эффекты.
- [26 — source links](26-source-link-audit.md) — доступность cited URL; не semantic validation.

- [27 — исследовательская литература](27-ecs-literature-calibration.md) — композиция, форма queries и конфликты доступов как разные оси.

- [28 — миссионный interaction](28-mission-matched-interaction.md) — Streets of Rogue рядом со станцией и колонией, с тем же учётом solver boundaries.

- [29 — видимость композиции игроку](29-player-visible-composition.md) — ширина модели и наглядная игровая демонстрация как разные задачи.

**Актуальное ограничение пользователя:** только одиночная игра, мультиплеер исключён. Основная рекомендация обновлена на Streets of Rogue; SS14 остаётся справочником. Ранние исследования отражают условия до этого уточнения.
