# Auto-Update Workflow for Fluent Bit Chocolatey Package

This repository includes an automated workflow that checks for new Fluent Bit releases and creates pull requests when updates are available.

## How It Works

### Automated Workflow (`.github/workflows/auto-update.yml`)

The workflow runs every other day at 6 AM UTC and:

1. **Checks for Updates**: Scrapes `https://packages.fluentbit.io/windows/` to find the latest available version
2. **Compares Versions**: Checks the latest version against the current Chocolatey package version
3. **Downloads & Validates**: Downloads both 32-bit and 64-bit installers to calculate SHA256 checksums
4. **Updates Files**: Automatically updates:
   - `fluent-bit.nuspec` - version number and release notes URL
   - `tools/chocolateyinstall.ps1` - download URLs and checksums
5. **Creates Pull Request**: Opens a PR with all changes, including detailed information about the update

### Manual Update Script (`update-package.ps1`)

For manual testing and one-off updates, use the PowerShell script:

```powershell
# Check if an update is available (no changes made)
.\update-package.ps1 -CheckOnly

# Update to the latest version
.\update-package.ps1

# Force update to a specific version
.\update-package.ps1 -Version "4.0.9" -Force

# Update to latest (even if same version)
.\update-package.ps1 -Force
```

## Workflow Schedule

The workflow is configured to run:
- **Automatic**: Every other day at 6 AM UTC (`0 6 */2 * *`)
- **Manual**: Can be triggered manually from the GitHub Actions tab

## Security & Permissions

The workflow requires:
- `contents: write` - To read repository files and create commits
- `pull-requests: write` - To create pull requests
- Uses `GITHUB_TOKEN` which is automatically provided by GitHub

## What Gets Updated

When a new version is found, the workflow updates:

### `fluent-bit.nuspec`
- `<version>` element
- Release notes URL in `<releaseNotes>`

### `tools/chocolateyinstall.ps1`
- Download URLs for both 32-bit and 64-bit installers
- SHA256 checksums for both installers

## Pull Request Details

Auto-generated PRs include:
- Version comparison (old vs new)
- SHA256 checksums for verification
- Links to release notes and package downloads
- Automatic branch naming: `auto-update/v{version}`

## Manual Review Process

⚠️ **Important**: Always review auto-generated PRs before merging:

1. **Verify Version**: Confirm the version number is correct
2. **Check Checksums**: Validate the SHA256 hashes match the actual files
3. **Test Installation**: Run the CI workflow or test locally:
   ```powershell
   choco pack --outputdirectory build
   cd build
   choco install fluent-bit --source ./ -y
   ```
4. **Review Release Notes**: Check the upstream release for breaking changes

## Troubleshooting

### Workflow Fails to Detect Version
- Check if the Fluent Bit packages site format has changed
- Verify the regex patterns in the workflow are still valid

### Download Failures
- Ensure URLs are accessible and files exist
- Check if Fluent Bit has changed their download URL format

### PR Creation Fails
- Verify repository permissions
- Check if a PR for the same version already exists

### Manual Script Issues
- Ensure you're running from the repository root directory
- Check PowerShell execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Monitoring

To monitor the workflow:
1. Go to the **Actions** tab in GitHub
2. Look for "Auto Update Fluent Bit Package" workflow runs
3. Check logs if failures occur

The workflow logs will show:
- Current vs latest version comparison
- Whether an update was needed
- Success/failure of each step

## Customization

To modify the schedule, edit the cron expression in `.github/workflows/auto-update.yml`:

```yaml
schedule:
  # Current: every other day at 6 AM UTC
  - cron: '0 6 */2 * *'
  
  # Examples:
  # Daily at 6 AM UTC: '0 6 * * *'
  # Weekly on Mondays: '0 6 * * 1'
  # Twice a week (Mon & Thu): '0 6 * * 1,4'
```

## Dependencies

The workflow relies on:
- Windows PowerShell environment
- Internet access to download files
- GitHub's `peter-evans/create-pull-request` action