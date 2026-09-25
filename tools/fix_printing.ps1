$gradle = Get-ChildItem "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\printing-*\android\build.gradle" | Select-Object -First 1
if (-not $gradle) {
    Write-Host "tripgo: printing plugin not found in pub cache; pub get may not have run."
    exit 1
}
$content = Get-Content $gradle.FullName -Raw
if ($content -match 'compileSdkVersion 36') {
    Write-Host "tripgo: printing plugin already patched (compileSdk 36)."
    exit 0
}
$new = $content -replace 'compileSdkVersion 30', 'compileSdkVersion 36'
Set-Content $gradle.FullName $new -NoNewline
Write-Host "tripgo: patched printing plugin compileSdk 30 -> 36."
exit 0