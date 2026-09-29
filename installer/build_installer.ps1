$ErrorActionPreference = 'Stop'

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$issFile = Join-Path $projectRoot 'installer\orama_admin.iss'

Push-Location $projectRoot
try {
  $versionLine = Get-Content 'pubspec.yaml' | Where-Object { $_ -match '^version:\s*(.+)$' } | Select-Object -First 1
  if (-not $versionLine) {
    throw 'Versão não encontrada no pubspec.yaml.'
  }

  $appVersion = ($versionLine -replace '^version:\s*', '') -replace '\+.*$', ''

  flutter build windows

  $iscc = Get-Command iscc -ErrorAction SilentlyContinue
  $isccPath = if ($iscc) { $iscc.Source } else { Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe' }

  if (-not (Test-Path $isccPath)) {
    throw 'Inno Setup Compiler (iscc) não encontrado no PATH. Instale o Inno Setup e tente novamente.'
  }

  & $isccPath "/DAppVersion=$appVersion" $issFile
}
finally {
  Pop-Location
}
