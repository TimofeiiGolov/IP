#!/usr/bin/env bash
# Локальный CI-скрипт: сборка + unit tests + UI tests на iOS Simulator.
# Не требует Homebrew, CocoaPods и Apple Developer Account.
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="Pishi.xcodeproj"
SCHEME="Pishi"

echo "==> Проверка Xcode"
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "ОШИБКА: xcodebuild не найден. Установите Xcode и выполните:"
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi
xcodebuild -version
swift --version

echo "==> Поиск доступного iPhone Simulator"
# Берём первый доступный iPhone-симулятор из списка.
SIMULATOR=$(xcrun simctl list devices available \
  | grep -Eo "iPhone [^(]*\([A-F0-9-]{36}\)" \
  | head -n 1 || true)

if [ -z "$SIMULATOR" ]; then
  echo "ОШИБКА: не найден доступный iPhone Simulator."
  echo "Откройте Xcode -> Settings -> Platforms и установите iOS Simulator runtime."
  exit 1
fi

SIM_NAME=$(echo "$SIMULATOR" | sed -E 's/\(([A-F0-9-]{36})\)//' | xargs)
SIM_UDID=$(echo "$SIMULATOR" | grep -Eo '[A-F0-9-]{36}' | head -n 1)
echo "Выбран Simulator: $SIM_NAME ($SIM_UDID)"

DESTINATION="platform=iOS Simulator,id=$SIM_UDID"

echo "==> Сборка приложения"
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

echo "==> Unit-тесты (PishiTests)"
rm -rf build/UnitTests.xcresult
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath build/DerivedData \
  -only-testing:PishiTests \
  -resultBundlePath build/UnitTests.xcresult \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

echo "==> UI-тесты (PishiUITests)"
rm -rf build/UITests.xcresult
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath build/DerivedData \
  -only-testing:PishiUITests \
  -resultBundlePath build/UITests.xcresult \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

echo "==> Готово. Результаты: build/UnitTests.xcresult, build/UITests.xcresult"
