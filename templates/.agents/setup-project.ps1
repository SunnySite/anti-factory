<#
.SYNOPSIS
    Bootstraps a GitHub Project v2 board, Status columns, repository link,
    needs-human label, and updates .agents/factory.config.json.

.EXAMPLE
    .\.agents\setup-project.ps1
    .\.agents\setup-project.ps1 -Title "My App Factory"
#>
param(
    [string]$Title = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptDir "factory.config.json"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config not found at $ConfigPath"
    exit 1
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is not installed or not in PATH."
    exit 1
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$owner = $config.github.owner
$repo = $config.github.repo
$projectOwner = $config.github.project_owner
$needsHumanLabel = $config.qa.needs_human_label

if ($owner -like "your-*" -or $repo -like "your-*" -or $projectOwner -like "your-*") {
    Write-Error "Please set github.owner, github.repo, and github.project_owner in .agents/factory.config.json first."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = "$repo Software Factory"
}

Write-Host "1. Creating GitHub Project v2 '$Title' under '$projectOwner'..."
$projectJson = gh project create --owner $projectOwner --title $Title --format json
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$project = $projectJson | ConvertFrom-Json
$projectNumber = [int]$project.number
Write-Host "   Created Project #$projectNumber"

Write-Host "2. Linking Project #$projectNumber to $owner/$repo..."
gh project link $projectNumber --owner $projectOwner --repo "$owner/$repo"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "3. Configuring Status columns..."
$fieldsJson = gh project field-list $projectNumber --owner $projectOwner --format json
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$fields = ($fieldsJson | ConvertFrom-Json).fields
$statusField = $fields | Where-Object { $_.name -eq "Status" } | Select-Object -First 1

if (-not $statusField) {
    Write-Error "Could not find 'Status' field on Project #$projectNumber."
    exit 1
}

$options = @(
    @{ name = $config.columns.backlog;      color = "GRAY";   description = "Ideas and unprioritized tasks" },
    @{ name = $config.columns.todo;         color = "BLUE";   description = "Ready for factory-coder" },
    @{ name = $config.columns.in_progress;  color = "YELLOW"; description = "Currently being implemented" },
    @{ name = $config.columns.deploy;       color = "ORANGE"; description = "Merged and deploying" },
    @{ name = $config.columns.qa;           color = "PURPLE"; description = "Under automated and browser QA" },
    @{ name = $config.columns.waiting_user; color = "RED";    description = "Needs human review or confirmation" },
    @{ name = $config.columns.done;         color = "GREEN";  description = "Verified and completed" }
)

$graphqlQuery = @'
mutation($fieldId: ID!, $options: [ProjectV2SingleSelectFieldOptionInput!]!) {
  updateProjectV2Field(
    input: {
      fieldId: $fieldId
      singleSelectOptions: $options
    }
  ) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        options { id name }
      }
    }
  }
}
'@

$payload = @{
    query = $graphqlQuery
    variables = @{
        fieldId = $statusField.id
        options = $options
    }
} | ConvertTo-Json -Depth 10

$payload | gh api graphql --input - | Out-Null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "4. Creating label '$needsHumanLabel' in $owner/$repo..."
gh label create $needsHumanLabel --repo "$owner/$repo" --color "D93F0B" --description "Escalated by Software Factory" --force
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "5. Updating $ConfigPath with project_number = $projectNumber..."
$config.github.project_number = $projectNumber
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8

Write-Host ""
Write-Host "Done! Project #$projectNumber is ready at: $($project.url)"
