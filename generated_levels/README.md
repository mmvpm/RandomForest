# Архив офлайн-генератора уровней

Перенесён из корня проекта после проверки: игра GameMaker и визуализатор используют готовые JSON в `RandomForest/datafiles/challenge_levels` и не импортируют этот Python-код.

Все исходники и тесты сохранены. Пути PROJECT_ROOT в пакетной генерации и backfill исправлены под новое расположение. Ручной запуск генератора по-прежнему добавляет карты в production-каталог, поэтому не используется для обычной сборки или проверки переноса.

Из корня проекта:

```sh
python3 .temp/generated_levels/validate_generated_level.py path/to/level.json
PYTHONPATH=.temp python3 -m unittest generated_levels.tests.test_level_format generated_levels.tests.test_challenge_batch generated_levels.tests.test_enemy_roster generated_levels.tests.test_moth_nests
```

Полный прогон тестов генерации может занимать значительное время.
