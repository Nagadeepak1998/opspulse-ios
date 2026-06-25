# Security

OpsPulse is designed as a safe SRE demo. It does not execute infrastructure commands.

## Credentials

- Demo mode needs no credentials.
- Live API tokens are stored only in Keychain.
- Tokens are sent as bearer tokens only when live mode is explicitly configured.
- Tokens are never printed by app code, tests, scripts, or docs.
- `.gitignore` blocks env files, provisioning files, certificates, private keys, and local build products.

## Runbook Commands

Runbooks can display safe reference commands, but the app has no execution path for shell commands, Kubernetes commands, deployment commands, or destructive infrastructure actions.

## Network Safety

The live adapter uses typed errors so authentication, timeout, decoding, server, and connectivity failures can be shown without exposing secrets.

## Local Data

Demo state is stored as a local Codable snapshot. It contains deterministic sample data only.
