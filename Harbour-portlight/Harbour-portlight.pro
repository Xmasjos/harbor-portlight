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

SOURCES += src/main.cpp \
    src/vaultbackend.cpp

HEADERS += src/vaultbackend.h

DISTFILES += qml/Harbour-portlight.qml \
    qml/cover/CoverPage.qml \
    qml/pages/NotesPage.qml \
    qml/pages/NotePage.qml \
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
