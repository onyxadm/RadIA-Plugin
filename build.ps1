# Script de Build Automatizado do RadIA para Windows PowerShell
$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "         Iniciando Build do RadIA            " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Obter a versão do compilador dcc32
Write-Host "Detectando versão do compilador Delphi..." -ForegroundColor Yellow
$dccOut = (dcc32 2>&1 | Out-String)
$compilerVersion = 0.0

if ($dccOut -match "version (\d+\.\d+)") {
    $compilerVersion = [double]$Matches[1]
    Write-Host "Compilador DCC32 Versão: $compilerVersion" -ForegroundColor Green
} else {
    Write-Error "Compilador dcc32 não encontrado no PATH ou versão inválida."
}

# 2. Mapear versão do compilador para a versão do Delphi (DelphiVer)
$delphiVer = ""
switch ($compilerVersion) {
    37.0 { $delphiVer = "23.0" } # Delphi 12 Athens
    36.0 { $delphiVer = "22.0" } # Delphi 11 Alexandria (Updates)
    35.0 { $delphiVer = "22.0" } # Delphi 11 Alexandria
    34.0 { $delphiVer = "21.0" } # Delphi 10.4 Sydney
    33.0 { $delphiVer = "20.0" } # Delphi 10.3 Rio
    32.0 { $delphiVer = "19.0" } # Delphi 10.2 Tokyo
    31.0 { $delphiVer = "18.0" } # Delphi 10.1 Berlin
    30.0 { $delphiVer = "17.0" } # Delphi 10 Seattle
    29.0 { $delphiVer = "16.0" } # Delphi XE8
    default {
        # Cálculo aproximado para outras versões
        $calc = $compilerVersion - 14.0
        $delphiVer = "{0:N1}" -f $calc
    }
}

Write-Host "Versão do Delphi correspondente (DelphiVer): $delphiVer" -ForegroundColor Green

# 3. Definir caminhos de Output
$outputRoot = ".\Output\$delphiVer"
$dcuPath = "$outputRoot\dcu\Win32\Debug"
$binPath = "$outputRoot\bin\Win32\Debug"
$bplPath = "$outputRoot\bpl"
$dcpPath = "$outputRoot\dcp"

# 4. Criar estrutura de pastas
Write-Host "Criando diretórios de output..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $dcuPath, $binPath, $bplPath, $dcpPath | Out-Null

# 5. Limpeza de arquivos temporários de compilação em pastas de fontes
Write-Host "Limpando diretórios de código-fonte de compilações antigas..." -ForegroundColor Yellow
Get-ChildItem -Path . -Recurse -Include *.dcu, *.exe, *.bpl, *.dcp, *.identcache, *.local | Where-Object { $_.FullName -notmatch "Output" } | Remove-Item -Force

# 6. Compilar Pacote Principal (RadIA.dpk)
Write-Host "Compilando RadIA.dpk..." -ForegroundColor Yellow
& dcc32 -Q -LUdesignide -LUvclie "-NU$dcuPath" "-LE$bplPath" "-LN$dcpPath" RadIA.dpk

# 7. Compilar Suite de Testes (Tests/RadIATests.dpr)
Write-Host "Compilando suite de testes RadIATests.dpr..." -ForegroundColor Yellow
Push-Location Tests
try {
    # DCU e Bin caminhos relativos de dentro da pasta Tests
    $testsDcuPath = "..\Output\$delphiVer\dcu\Win32\Debug"
    $testsBinPath = "..\Output\$delphiVer\bin\Win32\Debug"
    New-Item -ItemType Directory -Force -Path $testsDcuPath, $testsBinPath | Out-Null
    & dcc32 -Q -LUdesignide -LUvclie "-NU$testsDcuPath" "-E$testsBinPath" RadIATests.dpr
} finally {
    Pop-Location
}

# 8. Executar os Testes Unitários automaticamente
Write-Host "Executando suite de testes..." -ForegroundColor Yellow
$testsExe = ".\Output\$delphiVer\bin\Win32\Debug\RadIATests.exe"
if (Test-Path $testsExe) {
    & $testsExe
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "    Build e Testes Concluídos com Sucesso!   " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
} else {
    Write-Error "O executável de testes não foi gerado em: $testsExe"
}
