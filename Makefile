FLUTTER_SDK := $(shell awk -F= '$$1 == "flutter.sdk" { print $$2 }' android/local.properties)
FLUTTER ?= $(FLUTTER_SDK)/bin/flutter
DART ?= $(FLUTTER_SDK)/bin/dart

.PHONY: setup quick full release release-build format generate \
	development staging production

setup:
	"$(FLUTTER)" pub get

quick:
	./scripts/flutter_quality_gate.sh quick

full:
	./scripts/flutter_quality_gate.sh full

release:
	./scripts/flutter_quality_gate.sh release

release-build:
	./scripts/flutter_quality_gate.sh release --build

format:
	"$(DART)" format lib test integration_test tool packages

generate:
	"$(DART)" run build_runner build
	"$(DART)" run tool/generate_locale_keys.dart
	"$(DART)" format lib/src/config/language/locale_keys.g.dart

development:
	"$(FLUTTER)" run --flavor development -t lib/main_development.dart

staging:
	"$(FLUTTER)" run --flavor staging -t lib/main_staging.dart

production:
	"$(FLUTTER)" run --flavor production -t lib/main_production.dart
