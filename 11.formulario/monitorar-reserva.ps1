$ErrorActionPreference = 'Stop'

$pagePath = Join-Path $PSScriptRoot 'reserva.html'
$pidPath = Join-Path $PSScriptRoot '.reserva-monitor.pid'
$stopPath = Join-Path $PSScriptRoot '.reserva-monitor.stop'

if (-not (Test-Path -LiteralPath $pagePath)) {
    throw "Página não encontrada: $pagePath"
}

Set-Content -LiteralPath $pidPath -Value $PID -Encoding ascii
Remove-Item -LiteralPath $stopPath -Force -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:lastWrite = (Get-Item -LiteralPath $pagePath).LastWriteTimeUtc
$script:pagePath = $pagePath
$script:stopPath = $stopPath
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$script:notifyIcon.Visible = $true
$script:notifyIcon.BalloonTipTitle = 'Monitoramento da reserva'
$script:notifyIcon.BalloonTipText = 'O aviso será exibido quando reserva.html for alterada.'
$script:notifyIcon.ShowBalloonTip(5000)

$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = 1000
$script:timer.Add_Tick({
    if (Test-Path -LiteralPath $script:stopPath) {
        $script:timer.Stop()
        $script:notifyIcon.Visible = $false
        $script:notifyIcon.Dispose()
        Remove-Item -LiteralPath $script:stopPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.reserva-monitor.pid') -Force -ErrorAction SilentlyContinue
        [System.Windows.Forms.Application]::ExitThread()
        return
    }

    try {
        $currentWrite = (Get-Item -LiteralPath $script:pagePath).LastWriteTimeUtc
        if ($currentWrite -gt $script:lastWrite) {
            $script:lastWrite = $currentWrite
            $script:notifyIcon.BalloonTipText = 'A página reserva.html foi alterada.'
            $script:notifyIcon.ShowBalloonTip(8000)
        }
    } catch {
        $script:notifyIcon.BalloonTipText = 'Não foi possível ler reserva.html.'
        $script:notifyIcon.ShowBalloonTip(8000)
    }
})

$script:timer.Start()
[System.Windows.Forms.Application]::Run()
