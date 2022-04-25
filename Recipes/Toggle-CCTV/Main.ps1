$App = "vlc"

Try {

    $GetAllProcess = Get-Process $App -ErrorAction SilentlyContinue 

    If ($GetAllProcess.Count -eq 0) {
        Write-Host "No existing processes throwing..."
        & "./Recipes/Start-CCTV/Main.ps1"
        & "./Recipes/Turn-On-Screen/Main.ps1"
    }
    else {
        Write-Host "Found an existing process $ClientId"
        $GetAllProcess | Stop-Process -Force
        & "./Recipes/Stop-CCTV/Main.ps1"
        & "./Recipes/Turn-Off-Screen/Main.ps1"
    }

}
Catch {
    Write-Host $_
}
