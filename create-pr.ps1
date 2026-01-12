# Script to help create a PR for the bridge feature
# Prerequisites: You need to fork https://github.com/tari-project/wallet-ios on GitHub first

Write-Host "=== Bridge Feature PR Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if fork remote exists
$forkRemote = git remote get-url fork 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Please provide your GitHub username:" -ForegroundColor Yellow
    $username = Read-Host
    
    if ($username) {
        Write-Host "Adding fork remote..." -ForegroundColor Green
        git remote add fork "https://github.com/$username/wallet-ios.git"
        Write-Host "✓ Fork remote added" -ForegroundColor Green
    } else {
        Write-Host "Username required. Exiting." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Pushing bridge branch to your fork..." -ForegroundColor Green
git push -u fork bridge

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Successfully pushed to your fork!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://github.com/tari-project/wallet-ios" -ForegroundColor White
    Write-Host "2. Click 'New Pull Request'" -ForegroundColor White
    Write-Host "3. Select 'compare across forks'" -ForegroundColor White
    Write-Host "4. Choose your fork and 'bridge' branch → 'tari-project/wallet-ios' 'master'" -ForegroundColor White
    Write-Host "5. Fill in PR title: 'Add bridge feature implementation'" -ForegroundColor White
    Write-Host "6. Add description and submit" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Push failed. Please check:" -ForegroundColor Red
    Write-Host "- You have forked the repository on GitHub" -ForegroundColor Yellow
    Write-Host "- Your fork URL is correct" -ForegroundColor Yellow
    Write-Host "- You have push access to your fork" -ForegroundColor Yellow
}
