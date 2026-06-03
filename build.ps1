param(
    [switch]$Install,
    [switch]$Release,
    [switch]$IDE64
)
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

# 2. Validar compatibilidade e mapear versão do compilador para a versão do Delphi (DelphiVer)
if ($compilerVersion -lt 34.0) {
    Write-Host ""
    Write-Host "=========================================================================" -ForegroundColor Red
    Write-Host "ERRO: A versão do compilador Delphi detectada ($compilerVersion) não é suportada." -ForegroundColor Red
    Write-Host "O RadIA exige obrigatoriamente o Delphi 10.4 Sydney ou superior (DCC32 >= 34.0)" -ForegroundColor Red
    Write-Host "devido ao uso de recursos nativos da API de WebView2 (TEdgeBrowser)." -ForegroundColor Red
    Write-Host "=========================================================================" -ForegroundColor Red
    Write-Host ""
    throw "Versão do Delphi não suportada."
}

$delphiVer = ""
switch ($compilerVersion) {
    37.0 { $delphiVer = "37.0" } # Delphi 13
    36.0 { $delphiVer = "23.0" } # Delphi 12 Athens
    35.0 { $delphiVer = "22.0" } # Delphi 11 Alexandria
    34.0 { $delphiVer = "21.0" } # Delphi 10.4 Sydney
    default {
        $delphiVer = "{0:N1}" -f $compilerVersion
    }
}

Write-Host "Versão do Delphi correspondente (DelphiVer): $delphiVer" -ForegroundColor Green

# 3. Definir plataforma e compilador do pacote
$platform = "Win32"
$compiler = "dcc32"

if ($IDE64) {
    $platform = "Win64"
    $compiler = "dcc64"
    Write-Host "Configurando compilação para IDE de 64 bits (Win64)..." -ForegroundColor Yellow
} else {
    Write-Host "Configurando compilação para IDE de 32 bits (Win32)..." -ForegroundColor Yellow
}

$configName = "Debug"
if ($Release) {
    $configName = "Release"
}

$outputRoot = ".\Output\$delphiVer"
$dcuPath = "$outputRoot\dcu\$platform\$configName"
$binPath = "$outputRoot\bin\$platform\$configName"
$bplPath = "$outputRoot\bpl\$platform"
$dcpPath = "$outputRoot\dcp\$platform"

# 4. Criar estrutura de pastas
Write-Host "Criando diretórios de output..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $dcuPath, $binPath, $bplPath, $dcpPath | Out-Null

# 5. Limpeza de arquivos temporários de compilação em pastas de fontes
Write-Host "Limpando diretórios de código-fonte de compilações antigas..." -ForegroundColor Yellow
Get-ChildItem -Path . -Recurse -Include *.dcu, *.exe, *.bpl, *.dcp, *.identcache, *.local | Where-Object { $_.FullName -notmatch "Output" } | Remove-Item -Force

# 6. Compilar Recursos e Pacote Principal (RadIA.dpk)
Write-Host "Compilando recursos RadIA.rc..." -ForegroundColor Yellow
& brcc32 RadIA.rc

Write-Host "Compilando RadIA.dpk ($platform) em modo $configName..." -ForegroundColor Yellow
$dccParams = @("-Q", "-LUdesignide", "-LUvclie", "-NU$dcuPath", "-LE$bplPath", "-LN$dcpPath")
if ($Release) {
    $dccParams += @('-$D-', '-$L-', '-O+', '-DRELEASE')
} else {
    $dccParams += @('-$D+', '-$L+', '-O-', '-DDEBUG')
}
& $compiler $dccParams RadIA.dpk

# 7. Compilar Suite de Testes (Tests/RadIATests.dpr)
Write-Host "Compilando suite de testes RadIATests.dpr em modo $configName..." -ForegroundColor Yellow
Push-Location Tests
try {
    # DCU e Bin caminhos relativos de dentro da pasta Tests
    $testsDcuPath = "..\Output\$delphiVer\dcu\Win32\$configName"
    $testsBinPath = "..\Output\$delphiVer\bin\Win32\$configName"
    New-Item -ItemType Directory -Force -Path $testsDcuPath, $testsBinPath | Out-Null
    
    $dccParamsTests = @("-Q", "-LUdesignide", "-LUvclie", "-NU$testsDcuPath", "-E$testsBinPath")
    if ($Release) {
        $dccParamsTests += @('-$D-', '-$L-', '-O+', '-DRELEASE')
    } else {
        $dccParamsTests += @('-$D+', '-$L+', '-O-', '-DDEBUG')
    }
    & dcc32 $dccParamsTests RadIATests.dpr
} finally {
    Pop-Location
}

# 8. Executar os Testes Unitários automaticamente
Write-Host "Executando suite de testes..." -ForegroundColor Yellow
$testsExe = ".\Output\$delphiVer\bin\Win32\$configName\RadIATests.exe"
if (Test-Path $testsExe) {
    & $testsExe
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "    Build e Testes Concluídos com Sucesso!   " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
} else {
    Write-Error "O executável de testes não foi gerado em: $testsExe"
}

# 9. Instalação automatizada (se a flag -Install for fornecida)
if ($Install) {
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "         Instalando Plugin no Delphi         " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan

    $publicStudioDir = "C:\Users\Public\Documents\Embarcadero\Studio\$delphiVer"
    $publicBplDir = "$publicStudioDir\Bpl"
    $publicDcpDir = "$publicStudioDir\Dcp"

    $targetBplDir = $publicBplDir
    $targetDcpDir = $publicDcpDir
    if ($IDE64) {
        $targetBplDir = "$publicBplDir\Win64"
        $targetDcpDir = "$publicDcpDir\Win64"
    }

    Write-Host "Criando pastas públicas se não existirem..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $targetBplDir, $targetDcpDir | Out-Null

    $targetBpl = "$targetBplDir\RadIA.bpl"
    $targetDcp = "$targetDcpDir\RadIA.dcp"

    # 9.1 Garantir existência de WebView2Loader.dll na pasta da IDE
    $ideBinDir = "C:\Program Files (x86)\Embarcadero\Studio\$delphiVer\bin"
    $ideBin64Dir = "C:\Program Files (x86)\Embarcadero\Studio\$delphiVer\bin64"
    $dllName = "WebView2Loader.dll"

    if (-not (Test-Path "$ideBinDir\$dllName")) {
        Write-Host "WebView2Loader.dll (32-bit) não encontrada em $ideBinDir." -ForegroundColor Yellow
        $mormotDll = "D:\Delphi\mORMot2\ex\ThirdPartyDemos\tbo\05-WebMustache\$dllName"
        if (Test-Path $mormotDll) {
            Write-Host "Solicitando privilégios para copiar WebView2Loader.dll (32-bit) para a pasta bin da IDE..." -ForegroundColor Yellow
            Start-Process powershell -Verb RunAs -ArgumentList "-Command Copy-Item -Path '$mormotDll' -Destination '$ideBinDir\$dllName' -Force" -Wait
        }
    }

    if (-not (Test-Path "$ideBin64Dir\$dllName")) {
        Write-Host "WebView2Loader.dll (64-bit) não encontrada em $ideBin64Dir." -ForegroundColor Yellow
        $officeDll = "C:\Program Files\Microsoft Office\root\Office16\$dllName"
        if (Test-Path $officeDll) {
            Write-Host "Solicitando privilégios para copiar WebView2Loader.dll (64-bit) para a pasta bin64 da IDE..." -ForegroundColor Yellow
            Start-Process powershell -Verb RunAs -ArgumentList "-Command Copy-Item -Path '$officeDll' -Destination '$ideBin64Dir\$dllName' -Force" -Wait
        }
    }

    Write-Host "Copiando binários e recursos para as pastas da IDE..." -ForegroundColor Yellow
    Copy-Item -Path ".\Output\$delphiVer\bpl\$platform\RadIA.bpl" -Destination $targetBpl -Force
    Copy-Item -Path ".\Output\$delphiVer\dcp\$platform\RadIA.dcp" -Destination $targetDcp -Force

    $targetWeb = "$publicBplDir\Web"
    Write-Host "Copiando pasta de recursos Web locais..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $targetWeb | Out-Null
    Copy-Item -Path ".\Source\UI\Web\*" -Destination $targetWeb -Force -Recurse

    Write-Host "Registrando pacote no Registro do Windows..." -ForegroundColor Yellow
    $regPath = "HKCU:\Software\Embarcadero\BDS\$delphiVer\Known Packages"
    if ($IDE64) {
        $regPath = "HKCU:\Software\Embarcadero\BDS\${delphiVer}_x64\Known Packages"
    }
    
    # Garante que a chave existe no registro antes de gravar
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    New-ItemProperty -Path $regPath -Name $targetBpl -Value "RadIA - AI Assistant for Delphi IDE" -PropertyType String -Force | Out-Null

    Write-Host "=============================================" -ForegroundColor Green
    Write-Host " Plugin instalado com sucesso no Delphi!     " -ForegroundColor Green
    Write-Host " O RadIA estará disponível no próximo startup" -ForegroundColor Green
    Write-Host " da IDE.                                     " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
}
