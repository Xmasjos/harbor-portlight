# Build policy

Do not run project builds after making changes unless the user explicitly asks for a build. Build outputs are not used in this workflow.

# SailfishOS, Silica, and Qt

- Sailfish apps here use Qt Quick/QML and Sailfish Silica, with Qt/C++ for native code. Start with the [Sailfish app development docs](https://docs.sailfishos.org/Develop/Apps/) for SDK, Qt Quick, Silica, and platform APIs; use the [Silica API docs](https://sailfishos.org/develop/docs/silica) for Sailfish UI components.
- Treat Qt 5 as the SailfishOS baseline and use the [Qt 5 documentation archive](https://doc.qt.io/archives/qt-5.15/) by default. When an API may vary by Qt 5 minor version, check `qmake -query QT_VERSION` in the active Sailfish SDK build target (not the host Qt); if the device/runtime is the concern, verify its OS and installed Qt version too. Update this baseline if SailfishOS moves to another Qt major version.
- A QML import version such as `import QtQuick 2.0` or `import Sailfish.Silica 1.0` is a module API version, not the Qt framework version. Check the project's imports and RPM dependencies alongside the active SDK target; don't infer the framework version from imports alone.
