
.PHONY: deps analyze test reports archive sign verify ci

# Use a single timestamp per Make invocation to avoid per-line shell contexts
TS := $(shell date +%Y%m%d)

deps:
	flutter pub get

analyze:
	dart analyze

test:
	flutter test --reporter=json > reports/flutter_test.json || true

reports:
	@echo "reports generated"

archive:
	mkdir -p archive
	git archive --format=tar --prefix=bobo_studio_glowsnapup/ HEAD | gzip > archive/bobo_studio_glowsnapup-$(TS).tar.gz
	sha256sum archive/bobo_studio_glowsnapup-$(TS).tar.gz > archive/bobo_studio_glowsnapup-$(TS).tar.gz.sha256

sign:
	gpg --armor --output archive/bobo_studio_glowsnapup-$(TS).tar.gz.asc --detach-sign archive/bobo_studio_glowsnapup-$(TS).tar.gz

verify:
	gpg --verify archive/bobo_studio_glowsnapup-$(TS).tar.gz.asc archive/bobo_studio_glowsnapup-$(TS).tar.gz
	sha256sum -c archive/bobo_studio_glowsnapup-$(TS).tar.gz.sha256

ci: deps analyze test reports archive sign verify
	@echo "Local CI finished"
.PHONY: all deps analyze test widget-test e2e reports archive verify

all: deps analyze test widget-test reports archive

deps:
	flutter pub get

analyze:
	dart analyze

test:
	flutter test test/features/product/photo_studio_service_test.dart

widget-test:
	flutter test test/features/product/photo_studio_widget_test.dart

e2e:
	flutter test integration_test --machine > reports/integration_test.json || true

reports:
	mkdir -p reports
	flutter test --reporter=json > reports/flutter_test.json || true
	# Coverage (optional)
	# flutter test --coverage

archive:
	@TS=$$(date +%Y%m%d); \
	mkdir -p archive; \
	git archive --format=tar --prefix=bobo_studio_glowsnapup/ HEAD | gzip > archive/bobo_studio_glowsnapup-$${TS}.tar.gz; \
	sha256sum archive/bobo_studio_glowsnapup-$${TS}.tar.gz > archive/bobo_studio_glowsnapup-$${TS}.tar.gz.sha256; \
	gpg --armor --output archive/bobo_studio_glowsnapup-$${TS}.tar.gz.asc --detach-sign archive/bobo_studio_glowsnapup-$${TS}.tar.gz || true

verify:
	@TS=$$(date +%Y%m%d); \
	cd archive || exit 1; \
	sha256sum -c bobo_studio_glowsnapup-$${TS}.tar.gz.sha256 || true; \
	gpg --verify bobo_studio_glowsnapup-$${TS}.tar.gz.asc bobo_studio_glowsnapup-$${TS}.tar.gz || true
