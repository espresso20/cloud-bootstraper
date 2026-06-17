# cloud-bootstraper

Shared preflight for our Terraform cloud stacks. One script makes sure the right
cloud CLI is installed and you've got a live login session *before* `terraform`
runs — so `make plan` doesn't faceplant halfway through on an expired token.

Consumed by the Makefiles in our `aws-*` and `azure-*` stack repos — that glob is
the adoption standard for now (more cloud prefixes as we add them). Those repos
call into this one rather than each carrying their own copy of the logic.

## What it does

```
cloud-preflight.sh aws   [profile]            # verify/login an AWS SSO profile
cloud-preflight.sh azure [subscription_id]    # az login, then select subscription
```

1. **CLI present?** If `az`/`aws` isn't on `PATH`, it asks before installing
   (delegates to `install/az.sh` / `install/aws.sh` — Homebrew on macOS, docs
   pointer elsewhere). Never installs silently in a non-interactive shell.
2. **Authenticated?** Checks for a live session (`az account get-access-token` /
   `aws sts get-caller-identity`) and runs `az login` / `aws sso login` if not.

```
.
├── cloud-preflight.sh     # entrypoint
└── install/
    ├── az.sh              # install Azure CLI
    └── aws.sh             # install AWS CLI v2
```

## How the stacks use it

Each stack's Makefile has a `preflight` target (aliased `auth`) that runs
automatically before `init`/`plan`/`apply`/`destroy`:

```make
BOOTSTRAPER ?= ../cloud-bootstraper
PREFLIGHT   := $(BOOTSTRAPER)/cloud-preflight.sh

plan: preflight
	terraform -chdir=terraform plan ...
```

The default assumes this repo sits next to the stack repos (`~/Documents/`).
Cloned somewhere else? Override per-invocation:

```bash
make plan dev BOOTSTRAPER=/path/to/cloud-bootstraper
# or run the check on its own:
make auth dev
```

## Standalone

The scripts run fine on their own, no Make required:

```bash
./cloud-preflight.sh azure 00000000-0000-0000-0000-000000000000
./install/aws.sh
```
