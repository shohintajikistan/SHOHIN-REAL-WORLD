# SHOHIN REAL WORLD — Unity 6

**Единственный игровой движок проекта: Unity 6 + URP.** Three.js и Godot удалены из этой ветки.

## Игровой проект
Unity исходники находятся в `UnityProject/`. Открой эту папку в Unity Hub с Unity 6.0 LTS. Команда меню **SHOHIN → Create Cinematic Survival Prototype** создаёт тестовую сцену: два больших острова, океан, камеру, прототип персонажа и базовые системы выживания.

## WebGL для телефона
Цель проекта — браузерная сборка Unity WebGL, публикуемая через GitHub Pages. Workflow **Build Unity 6 WebGL** собирает проект и публикует результат. Для запуска сборки в настройках репозитория GitHub Actions нужны секреты Unity Personal:
- `UNITY_LICENSE` — содержимое файла лицензии Unity;
- `UNITY_EMAIL` — email аккаунта Unity;
- `UNITY_PASSWORD` — пароль аккаунта Unity.

Без этих секретов GitHub Actions не сможет запустить лицензированный Unity Editor. После успешной сборки страница игры будет доступна по адресу:
https://shohintajikistan.github.io/SHOHIN-REAL-WORLD/

## Текущее состояние
Это начальный Unity-прототип, а не готовая игра. Персонаж пока капсула, рельеф процедурный, а океан — базовая анимация волн. Нужны финальная humanoid-модель и анимации, детализированные материалы, растительность, затонувший корабль, мобильный HUD и оптимизация WebGL.

Проект SHOHIN TAJIKISTAN.
