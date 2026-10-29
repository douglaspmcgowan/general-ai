# Reviewed base CLI pins for hosted Linux agent environments.
# Owned by ONBOARDING/CLOUD-AGENTS.md ("Required base toolchain").
# Agent CLIs use exact pins. Language runtimes use supported release lines.

NODE_RELEASE_LINE=22
PYTHON_RELEASE_LINE=3
GH_VERSION=2.94.0
VERCEL_CLI_VERSION=58.0.0
BWS_VERSION=2.1.0
PLAYWRIGHT_VERSION=1.61.1
# Official Obsidian Headless client (npm `obsidian-headless`, Dynalist Inc.).
# Read-only vault transport; see .agents/cloud/VAULT-CONTRACT.md. Needs Node 22+.
OBSIDIAN_HEADLESS_VERSION=0.0.14
# PowerShell 7 is the Work Scope runtime. The guarded-write tools are the only
# supported way to change `.agents/work/state.json`, so a hosted agent without
# `pwsh` can read Work Scope state but cannot legally write it.
POWERSHELL_VERSION=7.4.6

# SHA-256 of each downloaded Linux archive, keyed by CPU architecture so a release line
# binds both the selected asset and its bytes. A mismatch refuses installation. Update both
# entries for a tool when its version changes, using the publisher release metadata.
GH_SHA256_AMD64=a757f1ba6db18f4de8cbadb244843a5f89bc75b5e7c6fc127d2bd77fbd12ed62
GH_SHA256_ARM64=705a23b70b0f1b7ba4c302fdcef392ce3edaacfa7ce8e85e4d93d72ea800a538
BWS_SHA256_AMD64=ba8233c3a4aee5d43e3c73bbd04d99e9bc5aba13bbbfd06d89b073abe732b860
BWS_SHA256_ARM64=18253757286e119d450133a87eb463bf8c1ce418ce24c834f4f250d60cba6f9e
POWERSHELL_SHA256_AMD64=6f6015203c47806c5cc444c19d8ed019695e610fbd948154264bf9ca8e157561
POWERSHELL_SHA256_ARM64=c0159b03e85f44ae1e7697818a011558da6c813d0aae848bf5ac13bf435d8624

# Installation root for reviewed downloads inside the disposable environment.
CLOUD_TOOL_ROOT=.local/agent-tools
