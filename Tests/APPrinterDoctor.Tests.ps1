BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot '..' 'APPrinterDoctor.ps1'
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
}

Describe 'APPrinterDoctor - Sintaxis' {
    It 'Parsea sin errores de sintaxis' {
        $errors | Should -BeNullOrEmpty
    }

    It 'Requiere PowerShell 5.1 o superior' {
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match '#requires -Version 5\.1'
    }
}

Describe 'APPrinterDoctor - Parametros' {
    It 'Declara Action con ValidateSet' {
        $param = $ast.ParamBlock.Parameters | Where-Object { $_.Name.Extent.Text -eq '$Action' }
        $param | Should -Not -BeNullOrEmpty
        $validateSet = $param.Attributes | Where-Object { $_.TypeName.Name -eq 'ValidateSet' }
        $validateSet | Should -Not -BeNullOrEmpty
    }

    It 'Declara ForceComponentRepair como switch' {
        $param = $ast.ParamBlock.Parameters | Where-Object { $_.Name.Extent.Text -eq '$ForceComponentRepair' }
        $param | Should -Not -BeNullOrEmpty
        ($param.Attributes | Where-Object { $_.TypeName.Name -eq 'switch' }) | Should -Not -BeNullOrEmpty
    }
}

Describe 'APPrinterDoctor - Estructura' {
    It 'Define las funciones principales' {
        $functions = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        foreach ($name in @('Write-APLog','Test-APAdministrator','Assert-APWindows','Get-APHealthCheck','Repair-APSpooler','Clear-APPrintQueue','Repair-APPrintToPDF','Invoke-APFullRepair','Show-APMenu')) {
            ($functions | Where-Object { $_.Name -eq $name }) | Should -Not -BeNullOrEmpty
        }
    }

    It 'Implementa rotacion de logs' {
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'LogRetentionDays'
    }
}

AfterAll {
    if ($errors) { Write-Host "Errores de parseo: $($errors | Out-String)" }
}
