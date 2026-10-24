# Принятые звуки природы

Утверждённые автором записи входят в datafiles/weather_audio. У ясной погоды и одуванчиков общий набор времени суток. Все источники CC0; оригинальные публичные HQ-превью, первичные страницы лицензий и история обработки сохранены в .temp/experiments/nature-audio-v1/, v2/ и v3/. Для тумана оставлены F6/F7. ES2 и F8 отклонены и сохранены среди архивных записей.

| Набор | ID | Источник |
| --- | --- | --- |
| morning | M1 | [timothyd4y](https://freesound.org/people/timothyd4y/sounds/607192/) |
| morning | M2 | [priesjensen](https://freesound.org/people/priesjensen/sounds/488328/) |
| morning | M3 | [trezz77](https://freesound.org/people/trezz77/sounds/546521/) |
| day | D1 | [borralbi](https://freesound.org/people/borralbi/sounds/370809/) |
| day | D3 | [AbsynthFactory](https://freesound.org/people/AbsynthFactory/sounds/639670/) |
| day | DS3 | [AbsynthFactory](https://freesound.org/people/AbsynthFactory/sounds/639670/) |
| evening | E1 | [Prauchi](https://freesound.org/people/Prauchi/sounds/835724/) |
| evening | E2 | [Nox_Sound](https://freesound.org/people/Nox_Sound/sounds/482118/) |
| evening | ES3 | [Speziax](https://freesound.org/people/Speziax/sounds/645329/) |
| night | N1 | [sengjinn](https://freesound.org/people/sengjinn/sounds/175020/) |
| night | N2 | [KikeVilaplana](https://freesound.org/people/KikeVilaplana/sounds/436528/) |
| night | NS3 | [Nox_Sound](https://freesound.org/people/Nox_Sound/sounds/482118/) |
| night | N4 | [Nox_Sound](https://freesound.org/people/Nox_Sound/sounds/637083/) |
| night | N5 | [Patrick_Corra](https://freesound.org/people/Patrick_Corra/sounds/745208/) |
| fog | F6 | [Sadiquecat](https://freesound.org/people/Sadiquecat/sounds/825822/) |
| fog | F7 | [thom_cookes](https://freesound.org/people/thom_cookes/sounds/475376/) |
| rain | RAIN | [Rubaoliva](https://freesound.org/people/Rubaoliva/sounds/624645/) |
| storm | STORM | [Rubaoliva](https://freesound.org/people/Rubaoliva/sounds/624645/) |
| drips | DRIPS | [Yoyodaman234](https://freesound.org/people/Yoyodaman234/sounds/348830/) |

Дождь и капли сохранены побайтово с прежними пиковыми gain 0,09 / 0,12 / 0,09. Принятые природные Ogg скопированы без новой обработки из v2/v3. Утренний M2 и остальные очищенные записи используют исходный постоянный gain после спектральной очистки. Все добавленные подложки листвы отсутствуют. NS3 и E2 явно используют общий файл e2.ogg с разной утверждённой громкостью.

Система использует два потока максимум и 12-секундные S-образные переходы. Таймер устойчивого звучания приостанавливается во время перехода; смена ясной погоды на одуванчики, рестарт и телепорт на том же уровне не меняют запись. Мелкий дождь и ливень продолжают общий канал. Перед ожидаемой сменой погоды новая ротация природы откладывается, чтобы не совмещать два перехода. В случае быстрых принудительных переключений сохраняется только последняя ожидающая цель, без обрыва исходящего потока.
