$ErrorActionPreference = "Stop"

$python = ".\\.venv\\Scripts\\python.exe"
if (-not (Test-Path $python)) {
    Write-Error "Virtual env not found. Run .\\setup.ps1 first."
}

& $python run.py @args
