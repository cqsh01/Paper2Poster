param(
    [string]$PaperPath = "/Paper2Poster-data/mypaper/paper.pdf",
    [double]$Width = 16.54,
    [double]$Height = 11.69,
    [int]$MaxWorkers = 1,
    [switch]$FastMode
)

$ErrorActionPreference = "Stop"

if (!(Test-Path ".env")) {
    throw "Missing .env. Please create .env with QWEN_API_KEY and DASHSCOPE_API_KEY."
}

if (!(Test-Path "hf_cache")) {
    New-Item -ItemType Directory -Path "hf_cache" | Out-Null
}

if (!(Test-Path "output_posters")) {
    New-Item -ItemType Directory -Path "output_posters" | Out-Null
}

$extraArgs = @()
if ($FastMode) {
    $extraArgs += "--no_blank_detection"
}

docker run --rm `
  --env-file ".env" `
  -e HF_HUB_DISABLE_XET=1 `
  -e HF_HUB_ENABLE_HF_TRANSFER=0 `
  -e HF_HOME=/hf_cache `
  -v "${PWD}:/app" `
  -v "${PWD}/hf_cache:/hf_cache" `
  -v "${PWD}/Paper2Poster-data:/Paper2Poster-data" `
  -v "${PWD}/output_posters:/app/output_posters" `
  paper2poster `
  python -m PosterAgent.new_pipeline `
  --poster_path="$PaperPath" `
  --model_name_t=qwen3-vl-plus `
  --model_name_v=qwen3-vl-plus `
  --poster_width_inches=$Width `
  --poster_height_inches=$Height `
  --max_workers=$MaxWorkers `
  @extraArgs
