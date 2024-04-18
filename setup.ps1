[CmdletBinding()]
param()

git flow config 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Verbose -Message "git flow not found, installing..."
    git flow init -d
}
