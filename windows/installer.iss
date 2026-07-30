#ifndef MyAppVersion
#define MyAppVersion "1.0.9"
#endif

[Setup]
AppId={{D1AF8581-A85B-4A76-B6D7-8336298E3F03}
AppName=Han1me+
AppVersion={#MyAppVersion}
AppPublisher=Han1me+
DefaultDirName={autopf}\Han1me+
DefaultGroupName=Han1me+
DisableProgramGroupPage=yes
OutputDir=..\build
OutputBaseFilename=Han1mePlus-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\han1me_plus.exe
CloseApplications=yes
RestartApplications=no

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Han1me+"; Filename: "{app}\han1me_plus.exe"
Name: "{autodesktop}\Han1me+"; Filename: "{app}\han1me_plus.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\han1me_plus.exe"; Description: "Launch Han1me+"; Flags: nowait postinstall skipifsilent

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"
