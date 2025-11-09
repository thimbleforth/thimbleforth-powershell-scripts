<# Powershell tools I use often #>

<# Battery checker and report generator #>

function Get-PowerReport() {
    powercfg /batteryreport /output .\"$(Get-Date -Format yyyyMMdd) - batteryreport.html"    
}

Get-PowerReport