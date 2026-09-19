APP      := Baaapp
TARGET   := Baaa
DERIVED  := build/DerivedData
PRODUCT  := $(DERIVED)/Build/Products/Release/$(APP).app

.PHONY: all project build run icon papa install clean dmg site serve release deploy

all: build

project:
	xcodegen generate

build: project
	xcodebuild -project $(TARGET).xcodeproj -scheme $(TARGET) -configuration Release \
		-derivedDataPath $(DERIVED) build | grep -E "error:|warning: .*$(TARGET)/|BUILD" || true
	rm -rf build/$(APP).app && cp -R $(PRODUCT) build/$(APP).app
	@echo "-> build/$(APP).app"

run: build
	pkill -x $(APP) 2>/dev/null || true
	open build/$(APP).app

icon:
	swift Scripts/generate_icon.swift

papa:
	@for src in Assets/papa-*-source.png; do \
		e=$$(basename $$src -source.png | sed 's/^papa-//'); \
		mkdir -p Assets/cutouts; \
		swift Scripts/cutout_papa.swift $$src Assets/cutouts/papa-$$e.png; \
		swift Scripts/frame_papa.swift Assets/cutouts/papa-$$e.png Baaa/Resources/papa-$$e.png 0.66 560; \
	done

install: build
	pkill -x $(APP) 2>/dev/null || true
	rm -rf /Applications/$(APP).app && cp -R build/$(APP).app /Applications/$(APP).app
	@echo "-> /Applications/$(APP).app"

clean:
	rm -rf build $(TARGET).xcodeproj

# ---- Distribution -----------------------------------------------------------

DMG := build/$(APP).dmg

dmg: build
	rm -rf build/dmg $(DMG) && mkdir -p build/dmg
	cp -R build/$(APP).app build/dmg/
	ln -s /Applications build/dmg/Applications
	hdiutil create -volname "$(APP)" -srcfolder build/dmg -ov -format UDZO $(DMG) >/dev/null
	@echo "-> $(DMG) ($$(du -h $(DMG) | cut -f1))"

# Copies the DMG, Papa's faces and the icon into the landing page folder.
site: dmg
	mkdir -p site/assets site/downloads
	cp $(DMG) site/downloads/$(APP).dmg
	cp Baaa/Resources/papa-*.png site/assets/
	cp Baaa/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@1x.png site/assets/icon.png
	@echo "-> site/ ready. Serve locally with: make serve"

serve:
	python3 -m http.server -d site 8080

# Publish the DMG as a GitHub Release (the site's download button points at "latest").
release: dmg
	gh release create v$$(grep MARKETING_VERSION project.yml | sed 's/.*"\(.*\)"/\1/') $(DMG) --generate-notes

# Needs the Firebase project on the Blaze plan (Spark refuses .dmg files and has no Functions).
deploy: site
	cd functions && npm install --silent
	firebase deploy
