#ifndef AppVersion
#define AppVersion "2.9.1"
#endif

[Setup]
AppName=Orama Admin
AppVersion={#AppVersion}
AppPublisher=Rikelmy Roberto
AppPublisherURL=https://github.com/rikelmyso7
AppSupportURL=mailto:rikelmyroberto1@gmail.com
AppUpdatesURL=https://github.com/rikelmyso7/orama_admin/releases
DefaultDirName={autopf}\Orama Admin
DefaultGroupName=Orama Admin
AllowNoIcons=yes
SourceDir=..
OutputDir=installer
OutputBaseFilename=orama_admin_setup_{#AppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
CloseApplicationsFilter=orama_admin.exe
UninstallDisplayIcon={app}\orama_admin.exe

[Languages]
Name: "portuguesebr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Orama Admin"; Filename: "{app}\orama_admin.exe"
Name: "{group}\{cm:UninstallProgram,Orama Admin}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Orama Admin"; Filename: "{app}\orama_admin.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\orama_admin.exe"; Description: "{cm:LaunchProgram,Orama Admin}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
