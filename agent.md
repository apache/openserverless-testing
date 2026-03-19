# Agent Notes

## Mandatory Process

- Update this file at the end of every significant session in this workspace.
- Record decisions, commands or access details that materially changed the outcome.
- Record repository state, pushed branches, opened PRs, merges, releases, blockers, and next steps.

## Access And Release Notes

- Official Apache image publication for `apache/openserverless-operator` is triggered by pushing a release tag to the Apache repository.
- The tag format in use is `0.1.0-incubating.<yymmddHHMM>`.
- The user reported that the official image publish succeeded only after:
  - configuring `~/.ssh/config`
  - running `eval $(ssh-agent)`
  - then pushing tags with:
    - `git push upstream --tags`
- Commit metadata can use `msciabarra@apache.org`, but GitHub repository permissions still depend on the authenticated account and SSH key mapping.

## Session Log

### Repository analysis and documentation

- Analyzed the testing flow across:
  - `openserverless-testing`
  - `openserverless-operator`
  - `openserverless-task`
- Created and updated:
  - `gap.md`
  - `workflow.md`
- Clarified that official operator publication is handled by `openserverless-operator/.github/workflows/image.yml`.
- Verified that official publication is triggered by pushing a numeric release tag, not automatically by PR success.

### PR-triggered testing implementation

- Implemented the initial PR testing flow across the three repositories.
- Added repository-dispatch based PR testing workflows in `openserverless-testing`.
- Added PR trigger workflows in `openserverless-operator` and `openserverless-task`.
- Verified a real end-to-end PR trigger on `nuvolaris/openserverless-operator` with label `kind-amd`.

### OPS branch pinning

- Explicitly pinned `OPS_BRANCH=main` in the GitHub testing flow.

### Contract realignment to `<test>-<hash>`

- Updated analysis and workflow documentation to reflect the newer contract:
  - `<test>-<hash>`
- Implemented the new contract on feature branches:
  - `openserverless-testing`: `feat/test-tag-hash-contract`
  - `openserverless-operator`: `feat/test-tag-hash-contract`
  - `openserverless-task`: `feat/test-tag-hash-contract`
- Added clearer logging to `tests/run-gh-suite.sh` so GitHub Actions output shows step boundaries and resolved test context.

### Official Apache PRs for operator fixes

- Created Apache PR `#93` for the kube-rbac-proxy registry fix:
  - `https://github.com/apache/openserverless-operator/pull/93`
- Apache PR `#93` was merged.
- Created Apache PR `#94` for the Traefik API version fix:
  - `https://github.com/apache/openserverless-operator/pull/94`

### Workspace branches and pushed commits

- `openserverless-operator`
  - branch: `feat/test-tag-hash-contract`
  - commits:
    - `5ea4faf` `Update Traefik API version`
    - `ca6f9a5` `Align testing trigger with <test>-<hash> tags`
- `openserverless-task`
  - branch: `feat/test-tag-hash-contract`
  - commit:
    - `812c19f` `Align testing trigger with <test>-<hash> tags`
- `openserverless-testing`
  - branch: `feat/test-tag-hash-contract`
  - commit:
    - `80f9252` `Align testing workflows with <test>-<hash> tags`

### Official image publication

- Verified Apache PR `#93` merge commit:
  - `eea534a35a6d1334644b6c11fc6cbbd1322d4ec9`
- Verified the post-merge `openserverless-operator-check` run on `apache/main` completed successfully.
- Prepared local release tag:
  - `0.1.0-incubating.2603190853`
- Initial attempts to push the tag from the agent failed due to GitHub permission checks for account `miki3421`.
- The user later confirmed they successfully pushed and generated the Docker image by using SSH config plus `ssh-agent`.

### Targeted k3s test for Traefik CRD/API change

- Created a clean PR on `nuvolaris/openserverless-operator` with only the Traefik API version change:
  - `https://github.com/nuvolaris/openserverless-operator/pull/5`
- Branch used:
  - `test/k3s-traefik-crd`
- Commit on that branch:
  - `94c8124ab498f3fdca3849b83d94585cd0d0e205`
- Added label:
  - `k3s-amd`
- This triggered:
  - `nuvolaris/openserverless-operator` run `23289380340` (`Trigger Testing`) -> success
  - `nuvolaris/openserverless-testing` run `23289385705` (`Operator PR #5 on k3s-amd`) -> failure
- Failure analysis:
  - the dispatch path worked
  - the temporary operator image build/push worked
  - the failure happened inside `Run GitHub Test Suite`, not during PR image build
  - the failing path is the `k3s` server/login initialization sequence
  - the run stalls on `waiting for completing system initialization`
  - it then ends with:
    - `ops: Failed to run task "login": exit status 1`
    - `ops: Failed to run task "server": exit status 1`
- Baseline comparison:
  - the previous `k3s-amd` operator test run `23142045515` failed with the same pattern
  - this strongly suggests the current failure is pre-existing in the `k3s` environment/path and is not yet evidence of a regression caused by the Traefik change

## Current Known Status

- Apache PR `#93` is merged and its main-branch check passed.
- Apache PR `#94` is open.
- The `<test>-<hash>` contract is implemented on feature branches but not yet merged to the main branches of all repos.
- A local file `openserverless-testing.code-workspace` exists in `openserverless-testing` and has intentionally not been committed.

## Next Step Requested

- Investigate the pre-existing `k3s-amd` initialization/login failure in `openserverless-testing` to separate environment issues from application regressions.

## 2026-03-19 Additional Operations

### 1Password and SSH access to the k3s AMD server

- Confirmed that the GitHub workflow uses the 1Password secret `op://OpenServerless/TESTING/ID_RSA_B64` as the private SSH key source for test runs.
- Confirmed that the workflow materializes that secret into `~/.ssh/id_rsa` during `tests/1-deploy.sh`.
- The user needed local access to the same key to debug the remote environment manually.
- Important shell detail discovered:
  - `~/.zshrc` was not sufficient for the non-interactive login shells used by the agent tools.
  - putting `export OP_SERVICE_ACCOUNT_TOKEN=...` in `~/.zprofile` made the token visible to login shells.
- A failed intermediate extraction left an empty `~/.ssh/testing_k3s_id_rsa`; the root cause was an invalid or misformatted service-account token.
- The user then corrected the token setup and successfully extracted the SSH private key locally outside the agent flow.
- The user confirmed that direct SSH to the server works.

### Reinstall of k3s on testing1-k3s-amd.nuvolaris.dev

- Host targeted:
  - `testing1-k3s-amd.nuvolaris.dev`
- Access path:
  - `ssh -i ~/.ssh/testing_k3s_id_rsa root@testing1-k3s-amd.nuvolaris.dev`
- Initial state before reinstall:
  - host name: `testing`
  - OS: `Ubuntu 24.04.4 LTS`
  - kernel: `6.8.0-71-generic`
  - installed k3s version: `v1.27.7-rc1+k3s2`
  - `k3s.service` was active and running
  - `/usr/local/bin/k3s-uninstall.sh` was present
- Reinstall action performed:
  - ran `/usr/local/bin/k3s-uninstall.sh`
  - removed common residual directories:
    - `/etc/rancher/k3s`
    - `/var/lib/rancher/k3s`
    - `/var/lib/kubelet`
    - `/var/lib/cni`
    - `/etc/cni/net.d`
    - `/run/k3s`
    - `/run/flannel`
    - `/var/lib/containerd`
  - reinstalled via the official install script using the stable channel:
    - `curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=stable sh -`
- Stable release selected by the installer:
  - `v1.34.5+k3s1`
- Final verified state after reinstall:
  - `k3s version v1.34.5+k3s1`
  - node name: `testing`
  - node status: `Ready`
  - node role: `control-plane`
  - container runtime: `containerd://2.1.5-k3s1`

### Notes

- A direct request to `https://update.k3s.io/v1-release/channels/stable` from the host returned a GitHub HTML page in this environment, but the official `get.k3s.io` installer correctly resolved the stable channel and installed `v1.34.5+k3s1`.
- This server refresh was done specifically to remove a very old pre-release `k3s` build from the `k3s-amd` test environment before retrying the failing operator test path.

## 2026-03-19 Autossh and K3s API Host Follow-up

### Goal

- Allow the `k3s` test path to keep using a public OpenServerless API host such as `testing.nuvolaris.dev` while reaching the actual machine over SSH and exposing the Kubernetes API through a local tunnel.

### Code changes implemented

- In `openserverless-task` and in the `tasks` submodule checked out inside `openserverless-testing`:
  - added optional tunnel support to `cloud/k3s/opsfile.yml`
  - when `K3S_AUTOSSH=1`, the task now opens a local tunnel to the remote `k3s` apiserver and rewrites the kubeconfig server to `https://127.0.0.1:<local-port>`
  - if `autossh` is unavailable, the task falls back to a plain `ssh -L` tunnel with a warning
  - removed the hardcoded old `k3s` release pin so installs no longer force `v1.27.7-rc1+k3s2`
- In `openserverless-testing/tests/1-deploy.sh`:
  - separated `K3S_AMD_APIHOST` from the SSH host used to reach the machine
  - for the specific `testing.nuvolaris.dev` case, the script now maps SSH to `testing1-k3s-amd.nuvolaris.dev`
  - if the SSH host and API host differ, `K3S_AUTOSSH=1` is enabled automatically
  - equivalent optional support was added for the ARM path
- In Linux GitHub workflows:
  - added an explicit `autossh` install step before running the suite

### Verification done

- `bash -n` on `tests/1-deploy.sh`
- YAML parse of:
  - `operator-pr-test.yaml`
  - `task-pr-test.yaml`
  - `tests.yaml`
  - `tasks/cloud/k3s/opsfile.yml`
- Real smoke test against the refreshed server:
  - generated kubeconfig via the new tunnelized `k3s` task
  - verified the kubeconfig points to `https://127.0.0.1:17443`
  - verified `kubectl get nodes` succeeds and the node is `Ready`

### Remaining manual operational step

- The agent still could not write 1Password secrets directly because `op` was not authenticated in the agent's non-interactive environment.
- The intended value to set is:
  - `OpenServerless / TESTING / K3S_AMD_APIHOST = testing1-k3s-amd.nuvolaris.dev`

## 2026-03-19 Runtime Job Image Propagation Fix

### Problem found on the remote `k3s-amd` run

- The `Operator PR Test` flow in `nuvolaris/openserverless-testing` was correctly:
  - building a temporary PR image
  - pushing it to GHCR
  - patching `_operator/olaris/opsroot.json`
- Even with that patch, the remote `k3s-amd` deployment still failed later in `couchdb-init`.
- The pod log on the remote cluster showed:
  - `registry.hub.docker.com/apache/openserverless-operator:0.1.0-testing.2309191654`
  - `ErrImagePull`
  - `ImagePullBackOff`
- Root cause:
  - the operator StatefulSet used the patched `IMAGES_OPERATOR` image for the controller pod itself
  - but the controller container still inherited `OPERATOR_IMAGE` and `OPERATOR_TAG` defaults baked into the image `Dockerfile`
  - downstream jobs created by the controller therefore still referenced the stale Apache testing tag

### Fix applied on `nuvolaris`

- In `nuvolaris/openserverless-task:main`:
  - commit `1232d0c` `Propagate operator PR image to runtime jobs`
  - updated `setup/kubernetes/opsfile.yml` to derive runtime `OPERATOR_IMAGE` and `OPERATOR_TAG` from `IMAGES_OPERATOR`
  - updated `setup/kubernetes/operator.yaml` to inject those values into the operator pod environment
- In `nuvolaris/openserverless-operator` PR branch:
  - branch `test/k3s-traefik-crd`
  - commit `648b89a` `Use PR operator image for runtime jobs`
  - moved submodule `olaris` forward to task commit `1232d0c`

### Operational note

- For the `nuvolaris` work resumed after the Apache release steps, commits and pushes were switched back to the user's account/key:
  - SSH key: `~/.ssh/id_ed25519`
  - Git email restored to `miki3421@gmail.com` in the operator PR clone before committing the submodule bump

## 2026-03-19 Ops Trace Visibility

### Goal

- Make the GitHub `k3s` test runs show the `ops` shell invocations in clear.
- Keep a small local trace on the remote `k3s` server so deploy-time `ops setup server ...` calls can be correlated with server-side state.

### Changes made

- In `openserverless-testing/tests/run-gh-suite.sh`:
  - enabled tracing by default with:
    - `OPS_TRACE=1`
    - `K3S_SERVER_TRACE=1`
  - changed step execution so shell scripts run through `bash -x` when tracing is enabled
- In `openserverless-testing/tests/1-deploy.sh`:
  - added `run_logged` to print the exact top-level `ops ...` command before execution
  - added `append_remote_trace` to append timestamped entries to:
    - `/var/log/openserverless-testing/ops-trace.log`
    - on the remote `k3s` server
  - wired that trace around the deploy-time `ops config apihost` and `ops setup server ...` calls for:
    - `k3s-amd`
    - `k3s-arm`

### Expected effect on the next rerun

- GitHub Actions logs will show the shell-expanded test scripts and their `ops` invocations.
- The remote server should accumulate a lightweight trace file at:
  - `/var/log/openserverless-testing/ops-trace.log`

## 2026-03-19 K3s Test Sequence Correction

### Problem found

- The `k3s` path in `openserverless-testing/tests/1-deploy.sh` was still using:
  - `ops setup server ... --uninstall`
  - `ops setup server ...`
- This wrapper sequence was not the one the user validated manually for the remote `k3s` environment.

### Sequence aligned in the test flow

- The `k3s-amd` and `k3s-arm` branches now use this direct sequence instead:
  - `ops cloud k3s delete <server> <user>`
  - `ops config apihost <apihost>`
  - `ops cloud k3s create <server> <user>`
  - `ops config slim`
  - `ops setup cluster`

### Reason for the change

- This keeps the GitHub test path aligned with the lower-level `ops cloud k3s` workflow rather than the higher-level `ops setup server` wrapper.

## 2026-03-19 K3s Slim And Full Test Profiles

### Goal

- Split the current `k3s` path into two logical suites:
  - `k3s-amd-slim` / `k3s-arm-slim`
  - `k3s-amd-full` / `k3s-arm-full`
- Keep temporary compatibility with older aliases:
  - `k3s-amd`
  - `k3s-arm`
  - these currently resolve to the `slim` profile

### Changes made in `openserverless-testing`

- `tests/lib/selector.sh`
  - now accepts test names with embedded hyphens before the final `<hash>`
  - exports `TEST_PROFILE`
  - maps:
    - `k3s-amd-slim` -> `k3s-amd` + `slim`
    - `k3s-amd-full` -> `k3s-amd` + `full`
    - `k3s-arm-slim` -> `k3s-arm` + `slim`
    - `k3s-arm-full` -> `k3s-arm` + `full`
- `tests/1-deploy.sh`
  - only runs `ops config slim` when `TEST_PROFILE=slim`
- `tests/run-gh-suite.sh`
  - skips MinIO-specific and static steps for `slim`
- `tests/all.sh`
  - mirrors the same `slim` skips for local all-in-one runs
- `tests/14-runtime-testing.sh`
  - no longer requires MinIO for `slim`
  - skips JS/Python MinIO runtime assertions in `slim`

### Current limitation

- The PR trigger regex in `openserverless-operator` / `openserverless-task` still needs the same naming expansion if the new canonical labels with hash are to be used directly on PRs.
- The current active `k3s-amd` label continues to work because the testing repo maps it to the `slim` profile.
