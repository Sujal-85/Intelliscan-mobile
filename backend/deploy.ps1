Set-Location $PSScriptRoot

$SERVICE_NAME = "intelliscan-backend"
$REGION = "us-central1"
$REPO_NAME = "intelliscan-repo"

Write-Host "Deploying $SERVICE_NAME..."

# gcloud check
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Error "gcloud not installed"
    exit 1
}

# project
$PROJECT_ID = (gcloud config get-value project 2>$null).Trim()
if (-not $PROJECT_ID) {
    Write-Error "No GCP project set"
    exit 1
}

Write-Host "Project: $PROJECT_ID"

# services
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --quiet

# repo check
$repo = gcloud artifacts repositories list --location=$REGION --format="value(name)" | Select-String $REPO_NAME
if (-not $repo) {
    gcloud artifacts repositories create $REPO_NAME `
        --repository-format=docker `
        --location=$REGION `
        --description="IntelliScan backend"
}

# image
$IMAGE = "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$SERVICE_NAME"

# build
gcloud builds submit --tag $IMAGE .
if ($LASTEXITCODE -ne 0) { exit 1 }

# env vars
$ENV_VARS = ""
if (Test-Path ".env") {
    $ENV_VARS = (Get-Content ".env" | Where-Object { $_ -and -not $_.StartsWith("#") }) -join ","
}

# deploy
if ($ENV_VARS) {
    gcloud run deploy $SERVICE_NAME `
        --image $IMAGE `
        --region $REGION `
        --platform managed `
        --allow-unauthenticated `
        --port 8080 `
        --memory 2Gi `
        --timeout 300 `
        --set-env-vars $ENV_VARS
}
else {
    gcloud run deploy $SERVICE_NAME `
        --image $IMAGE `
        --region $REGION `
        --platform managed `
        --allow-unauthenticated `
        --port 8080 `
        --memory 2Gi `
        --timeout 300
}

# url
gcloud run services describe $SERVICE_NAME --region $REGION --format="value(status.url)"
