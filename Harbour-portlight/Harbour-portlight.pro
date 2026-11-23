# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = Harbour-portlight

CONFIG += sailfishapp

CODEMIRROR_BUNDLE = qml/editor/assets/codemirror.bundle.js
!exists($$CODEMIRROR_BUNDLE): error("Missing $$CODEMIRROR_BUNDLE. Run npm ci && npm run build from ../portlight-codemirror-editor.")

SOURCES += src/main.cpp \
    src/editorprocess.cpp \
    src/vaultbackend.cpp

HEADERS += src/editorprocess.h \
    src/vaultbackend.h

DISTFILES += qml/Harbour-portlight.qml \
    qml/EditorHelper.qml \
    qml/cover/CoverPage.qml \
    qml/components/VaultEntryDelegate.qml \
    qml/components/SourceNoteEditor.qml \
    qml/components/WebNoteEditor.qml \
    qml/pages/VaultBrowserPage.qml \
    qml/pages/NotePage.qml \
    qml/pages/ImagePage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/QuickCaptureErrorPage.qml \
    qml/editor/index.html \
    qml/editor/frame.js \
    $$CODEMIRROR_BUNDLE \
    qml/editor/assets/codemirror.LICENSE.txt \
    rpm/Harbour-portlight.changes.in \
    rpm/Harbour-portlight.changes.run.in \
    rpm/Harbour-portlight.spec \
    translations/*.ts \
    assets/portlight.svg \
    assets/openharbor/portlight.png \
    Harbour-portlight.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

PKGCONFIG += qt5embedwidget

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/Harbour-portlight-de.ts
