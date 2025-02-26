1. Update `nimv.nuspec` with changes, and version number
2. `choco pack`
3. `choco push nimv.0.0.4.nupkg --source=https://push.chocolatey.org --key=<API_KEY>`