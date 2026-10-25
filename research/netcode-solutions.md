# Сетевые снаряды и AoE: существующие решения

Отдельное исследование Luna Max по первичным документам и исходникам. Оно не блокирует исправление игры. Каждый отчёт отделяет поведение библиотеки от выводов для Bend/Iroh и указывает ограничения поиска.

| Направление | Отчёт | Что смотреть |
| --- | --- | --- |
| Unity Netcode for Entities | [Unity](netcode-solutions-unity.md) | Ticked commands, partial rollback, GhostGroup, spawn matching, collision history |
| Unreal GAS | [Unreal](netcode-solutions-unreal-gas.md) | PredictionKey, серверный AoE, GameplayEffects/Cues, saved moves |
| Photon Fusion / FishNet | [Fusion и FishNet](netcode-solutions-fusion-fishnet.md) | Варианты представления снарядов, predicted spawning, lag compensation |
| Bevy / Lightyear / Avian | [Bevy](netcode-solutions-bevy-lightyear.md) | Буфер ввода, remote prediction, pre-spawn identity, физика и rollback |
| GGPO / GGRS | [Rollback](netcode-solutions-ggpo-ggrs.md) | Полный save/load/advance, input delay, prediction window, replay-safe effects |
| Source / Valve | [Source](netcode-solutions-source-valve.md) | Hitscan rewind против снарядов, radius damage, границы истории |
| Открытые сетевые игры | [SS14, Veloren, OpenRA](netcode-solutions-open-games.md) | Реальные пути projectile → contact → damage и сброс контактов при replay |
| Проверки | [Инструменты и сценарии](netcode-solutions-testing.md) | Сетевые симуляторы, SyncTest, временные контракты, стоимость наблюдения |
| AoE и spatial queries | [AoE-запросы](netcode-solutions-aoe-queries.md) | Box2D, Rapier, Unity: broad phase, точный resolver, порядок получателей |
| Часы и буферы | [Синхронизация времени](netcode-solutions-clocks.md) | Tick lead, jitter buffers, плавная коррекция часов, пауза и перегрузка |

Это обзор механизмов, а не предложение переносить пример на другой движок. Готовый транспорт не задаёт правила времени, урона или предсказания игры.
