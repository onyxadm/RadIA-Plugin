param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Release,
    [switch]$IDE64,
    [string]$DelphiVersion
)
$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "         Iniciando Build do RadIA            " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Detectar instalacoes do Delphi no Registro do Windows
$installations = @()
$regBDS = "HKCU:\Software\Embarcadero\BDS"
if (Test-Path $regBDS) {
    $bdsKeys = Get-ChildItem $regBDS | Where-Object { $_.PSChildName -match '^\d+\.\d+$' }
    foreach ($key in $bdsKeys) {
        $ver = $key.PSChildName
        $rootDir = (Get-ItemProperty -Path $key.PSPath -Name "RootDir" -ErrorAction SilentlyContinue).RootDir
        if ($rootDir -and (Test-Path $rootDir)) {
            $friendlyName = ""
            switch ($ver) {
                "21.0" { $friendlyName = "Delphi 10.4 Sydney" }
                "22.0" { $friendlyName = "Delphi 11 Alexandria" }
                "23.0" { $friendlyName = "Delphi 12 Athens" }
                "37.0" { $friendlyName = "Delphi 13" }
                default { $friendlyName = "Delphi (BDS $ver)" }
            }
            $installations += [PSCustomObject]@{
                Version  = $ver
                RootDir  = $rootDir
                Name     = $friendlyName
                Registry = $key.PSPath
            }
        }
    }
}

# 2. Selecionar a versao do Delphi a ser utilizada
$selectedInstall = $null

if ($DelphiVersion) {
    # Tentar encontrar a versao informada pelo usuario
    $selectedInstall = $installations | Where-Object { 
        $_.Version -eq $DelphiVersion -or 
        $_.Name -like "*$DelphiVersion*"
    } | Select-Object -First 1
    
    if (-not $selectedInstall) {
        Write-Warning "Versao do Delphi '$DelphiVersion' nao encontrada no registro. Tentando prosseguir com o PATH padrao."
    } else {
        Write-Host "Versao do Delphi selecionada via parametro: $($selectedInstall.Name) ($($selectedInstall.Version))" -ForegroundColor Green
    }
}

# Se for instalar ou desinstalar e nao houver versao pre-definida, resolvemos dinamicamente
if (-not $selectedInstall -and ($Install -or $Uninstall)) {
    if ($installations.Count -eq 0) {
        Write-Host "Nenhuma instalacao do Delphi encontrada no Registro do Windows. Tentando prosseguir com o PATH padrao." -ForegroundColor Yellow
    } elseif ($installations.Count -eq 1) {
        $selectedInstall = $installations[0]
        Write-Host "Unica instalacao do Delphi detectada: $($selectedInstall.Name) ($($selectedInstall.Version))" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Multiplas versoes do Delphi detectadas no sistema:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $installations.Count; $i++) {
            Write-Host "  [$($i + 1)] $($installations[$i].Name) ($($installations[$i].Version)) em $($installations[$i].RootDir)" -ForegroundColor Yellow
        }
        Write-Host "  [$($installations.Count + 1)] Cancelar Operacao" -ForegroundColor Red
        Write-Host ""
        
        $choice = 0
        while ($choice -lt 1 -or $choice -gt ($installations.Count + 1)) {
            $inputVal = Read-Host "Selecione a versao do Delphi desejada (1-$($installations.Count + 1))"
            if ($inputVal -match "^\d+$") {
                $choice = [int]$inputVal
            }
        }
        
        if ($choice -eq ($installations.Count + 1)) {
            Write-Host "Operacao cancelada pelo usuario." -ForegroundColor Red
            Exit
        }
        
        $selectedInstall = $installations[$choice - 1]
        Write-Host "Versao selecionada: $($selectedInstall.Name)" -ForegroundColor Green
    }
}

# Se selecionou uma versao, injeta a pasta bin correspondente no PATH para compilar com ela
if ($selectedInstall) {
    $delphiBinDir = Join-Path $selectedInstall.RootDir "bin"
    if (Test-Path $delphiBinDir) {
        Write-Host "Configurando PATH temporario com compilador de: $delphiBinDir" -ForegroundColor Yellow
        $env:PATH = "$delphiBinDir;" + $env:PATH
    }
}

# 3. Obter a versao do compilador dcc32 ativo
Write-Host "Detectando versao do compilador Delphi..." -ForegroundColor Yellow
$dccOut = (dcc32 2>&1 | Out-String)
$compilerVersion = 0.0

if ($dccOut -match "version (\d+\.\d+)") {
    $compilerVersion = [double]$Matches[1]
    Write-Host "Compilador DCC32 Versao: $compilerVersion" -ForegroundColor Green
} else {
    Write-Error "Compilador dcc32 nao encontrado no PATH ou versao invalida."
}

# 4. Validar compatibilidade e mapear versao do compilador para a versao do Delphi (DelphiVer)
if ($compilerVersion -lt 34.0) {
    Write-Host ""
    Write-Host "=========================================================================" -ForegroundColor Red
    Write-Host "ERRO: A versao do compilador Delphi detectada ($compilerVersion) nao e suportada." -ForegroundColor Red
    Write-Host "O RadIA exige obrigatoriamente o Delphi 10.4 Sydney ou superior (DCC32 >= 34.0)" -ForegroundColor Red
    Write-Host "devido ao uso de recursos nativos da API de WebView2 (TEdgeBrowser)." -ForegroundColor Red
    Write-Host "=========================================================================" -ForegroundColor Red
    Write-Host ""
    throw "Versao do Delphi nao suportada."
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

Write-Host "Versao do Delphi correspondente (DelphiVer): $delphiVer" -ForegroundColor Green


# Processar Desinstalacao (se a flag -Uninstall for fornecida)
if ($Uninstall) {
    if (Get-Process bds -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "=========================================================================" -ForegroundColor Red
        Write-Host "ERRO: A IDE do Delphi (bds.exe) esta aberta no momento." -ForegroundColor Red
        Write-Host "Por favor, salve seu trabalho e feche todas as instancias da IDE" -ForegroundColor Red
        Write-Host "antes de executar a desinstalacao do plugin RadIA para evitar arquivos travados." -ForegroundColor Red
        Write-Host "=========================================================================" -ForegroundColor Red
        Write-Host ""
        throw "A IDE do Delphi esta aberta."
    }

    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "       Desinstalando Plugin do Delphi        " -ForegroundColor Cyan
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

    $targetBpl = "$targetBplDir\RadIA.bpl"
    $targetDcp = "$targetDcpDir\RadIA.dcp"
    $targetWeb = "$publicBplDir\Web"

    Write-Host "Removendo pacote do Registro do Windows..." -ForegroundColor Yellow
    $regPath = "HKCU:\Software\Embarcadero\BDS\$delphiVer\Known Packages"
    if ($IDE64) {
        $regPath = "HKCU:\Software\Embarcadero\BDS\${delphiVer}_x64\Known Packages"
    }
    if (Test-Path $regPath) {
        Remove-ItemProperty -Path $regPath -Name $targetBpl -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Host "Removendo binarios e recursos do sistema..." -ForegroundColor Yellow
    if (Test-Path $targetBpl) {
        Remove-Item -Path $targetBpl -Force | Out-Null
    }
    if (Test-Path $targetDcp) {
        Remove-Item -Path $targetDcp -Force | Out-Null
    }
    if (Test-Path $targetWeb) {
        Remove-Item -Path $targetWeb -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Host "=============================================" -ForegroundColor Green
    Write-Host " Plugin desinstalado com sucesso do Delphi!  " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Exit
}

# 3. Definir plataforma e compilador do pacote
$platform = "Win32"
$compiler = "dcc32"

if ($IDE64) {
    $platform = "Win64"
    $compiler = "dcc64"
    Write-Host "Configurando compilacao para IDE de 64 bits (Win64)..." -ForegroundColor Yellow
} else {
    Write-Host "Configurando compilacao para IDE de 32 bits (Win32)..." -ForegroundColor Yellow
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
Write-Host "Criando diretorios de output..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $dcuPath, $binPath, $bplPath, $dcpPath | Out-Null

# 5. Limpeza de arquivos temporarios de compilacao em pastas de fontes
Write-Host "Limpando diretorios de codigo-fonte de compilacoes antigas..." -ForegroundColor Yellow
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
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "=========================================================================" -ForegroundColor Red
    Write-Host "ERRO: A compilacao do pacote principal RadIA.dpk falhou." -ForegroundColor Red
    Write-Host "Por favor, corrija os erros de compilacao listados acima." -ForegroundColor Red
    Write-Host "=========================================================================" -ForegroundColor Red
    Write-Host ""
    throw "Compilacao do pacote principal falhou."
}

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
    
    # 7.1 Resolver Search Paths globais do Delphi no Registro para que compile com as mesmas units da IDE
    if ($selectedInstall) {
        $libRegPath = "HKCU:\Software\Embarcadero\BDS\$delphiVer\Library\Win32"
        if (Test-Path $libRegPath) {
            $searchPath = (Get-ItemProperty -Path $libRegPath -Name "Search Path" -ErrorAction SilentlyContinue)."Search Path"
            if ($searchPath) {
                # Substitui as macro-variaveis do Delphi pelo caminho fisico correspondente
                $resolvedPath = $searchPath.Replace('$(BDS)', $selectedInstall.RootDir)
                $resolvedPath = $resolvedPath.Replace('$(BDSCOMMONDIR)', "C:\Users\Public\Documents\Embarcadero\Studio\$delphiVer")
                $dccParamsTests += "-U$resolvedPath"
            }
        }
        
        # Fallback de seguranca caso o DUnitX nao esteja no Search Path do registro mas exista na pasta source
        $dunitxPath = Join-Path $selectedInstall.RootDir "source\DUnitX"
        if (Test-Path $dunitxPath) {
            $dccParamsTests += "-U$dunitxPath"
            $dccParamsTests += "-U$(Join-Path $dunitxPath 'src')"
        }
    }
    
    & dcc32 $dccParamsTests RadIATests.dpr
} finally {
    Pop-Location
}

# 8. Executar os Testes Unitarios automaticamente
Write-Host "Executando suite de testes..." -ForegroundColor Yellow
$testsExe = ".\Output\$delphiVer\bin\Win32\$configName\RadIATests.exe"
if (Test-Path $testsExe) {
    & $testsExe
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "    Build e Testes Concluidos com Sucesso!   " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
} else {
    Write-Error "O executavel de testes nao foi gerado em: $testsExe"
}

# 9. Instalacao automatizada (se a flag -Install for fornecida)
if ($Install) {
    if (Get-Process bds -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "=========================================================================" -ForegroundColor Red
        Write-Host "ERRO: A IDE do Delphi (bds.exe) esta aberta no momento." -ForegroundColor Red
        Write-Host "Por favor, salve seu trabalho e feche todas as instancias da IDE" -ForegroundColor Red
        Write-Host "antes de executar a instalacao do plugin RadIA para evitar arquivos travados" -ForegroundColor Red
        Write-Host "ou problemas de carregamento na memoria." -ForegroundColor Red
        Write-Host "=========================================================================" -ForegroundColor Red
        Write-Host ""
        throw "A IDE do Delphi esta aberta."
    }

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

    Write-Host "Criando pastas publicas se nao existirem..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $targetBplDir, $targetDcpDir | Out-Null

    $targetBpl = "$targetBplDir\RadIA.bpl"
    $targetDcp = "$targetDcpDir\RadIA.dcp"

    # 9.1 Garantir existencia de WebView2Loader.dll na pasta da IDE
    $rootDir = "C:\Program Files (x86)\Embarcadero\Studio\$delphiVer"
    if ($selectedInstall) {
        $rootDir = $selectedInstall.RootDir
    }
    $ideBinDir = Join-Path $rootDir "bin"
    $ideBin64Dir = Join-Path $rootDir "bin64"
    $dllName = "WebView2Loader.dll"

    if (-not (Test-Path "$ideBinDir\$dllName")) {
        Write-Host "WebView2Loader.dll (32-bit) nao encontrada em $ideBinDir." -ForegroundColor Yellow
        $redist32 = ".\Redist\Win32\$dllName"
        if (Test-Path $redist32) {
            Write-Host "Solicitando privilegios para copiar WebView2Loader.dll (32-bit) para a pasta bin da IDE..." -ForegroundColor Yellow
            Start-Process powershell -Verb RunAs -ArgumentList "-Command Copy-Item -Path '$redist32' -Destination '$ideBinDir\$dllName' -Force" -Wait
        }
    }

    if (-not (Test-Path "$ideBin64Dir\$dllName")) {
        Write-Host "WebView2Loader.dll (64-bit) nao encontrada em $ideBin64Dir." -ForegroundColor Yellow
        $redist64 = ".\Redist\Win64\$dllName"
        if (Test-Path $redist64) {
            Write-Host "Solicitando privilegios para copiar WebView2Loader.dll (64-bit) para a pasta bin64 da IDE..." -ForegroundColor Yellow
            Start-Process powershell -Verb RunAs -ArgumentList "-Command Copy-Item -Path '$redist64' -Destination '$ideBin64Dir\$dllName' -Force" -Wait
        }
    }

    Write-Host "Copiando binarios e recursos para as pastas da IDE..." -ForegroundColor Yellow
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
    Write-Host " O RadIA estara disponivel no proximo startup" -ForegroundColor Green
    Write-Host " da IDE.                                     " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
}

