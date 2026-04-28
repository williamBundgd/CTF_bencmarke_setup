# PipTemp

PipTemp is a reusable Docker-based template for deploying a complete CI/CD environment.

The default setup includes:

- **Gitea** for Git repository hosting
- **Drone CI** for pipeline orchestration
- **Drone Docker runner** for pipeline execution
- **Optional QEMU-based runner VM** for isolated Docker execution
- **Docker Registry** for storing pipeline images
- **Nginx reverse proxy** for routing and TLS
- **Static CSV/YAML configuration files** for users, repositories, secrets, cron jobs, and access rules

The template can be used as-is or modified to build custom CI/CD-based challenges.

---

## Default Domains

The default deployment uses the following domains:

```text
git.bench.test
drone.bench.test
registry.bench.test
internalgit.bench.test
internaldrone.bench.test
internalregistry.bench.test
internalrunnervm.bench.test
internalrunnerlocal.bench.test
```

The setup scripts add these names to `/etc/hosts` and install the local certificate authority.

---

## Requirements

- Linux host, tested on Ubuntu
- Docker
- Docker Compose
- `sudo` privileges for `/etc/hosts` and CA certificate installation
- Optional: QEMU support for the VM runner

---

## Running PipTemp Locally

From the `src/` directory:

```bash
cd src
sudo ./prerun.sh
```

The script performs the following steps:

1. Adds the PipTemp domains to `/etc/hosts`.
2. Installs the local CA certificate if needed.
3. Builds the Docker images.
4. Starts the services with Docker Compose.
5. Opens Gitea and Drone in the browser.

If the certificate is installed for the first time, restart the machine or browser before retrying.

You can also run the steps manually:

```bash
cd src
sudo ./setup.sh
docker compose build
docker compose up -d
```

Stop the environment with:

```bash
docker compose down
```

View logs with:

```bash
docker compose logs -f
```

---

## Default Login

The default user is defined in `src/config/users.csv`:

```text
username,email,password
Anonymous,person@anon.com,password
```

Default login:

```text
Username: Anonymous
Password: password
```

Use this account to access both Gitea and Drone.

---

## Main Configuration Files

### `src/config/users.csv`

Defines Gitea users created during initialization.

```csv
username,email,password
Anonymous,person@anon.com,password
```

Add one row per user.

---

### `src/config/repositories.csv`

Defines repositories that should be created and connected to Drone.

```csv
username,repository,token,hooksecret,private,webhook_config
Anonymous,test1,false,xO3fEwNlMjXLC2C6rcUVFGqCUZi1BpXs,false,{...}
Anonymous,test2,false,Yet4hhBdZBom3GUE1WC0OsEpccdfgNZU,false,{...}
```

Columns:

- `username`: owner of the repository
- `repository`: repository name
- `token`: whether a token should be associated
- `hooksecret`: webhook secret used between Gitea and Drone
- `private`: `true` or `false`
- `webhook_config`: Gitea webhook configuration JSON

Each repository must have a matching git repositry like so:

```text
src/config/repositories/{username}/{repository}/git
```

which is a copy of a `.git` dir form a real git repository. The remaning git project will be regenerated from the `git` dir at runtime.

Please ensure that the "main" branch on the repository is called `main` and not `master`.

---

### `src/config/secrets.csv`

Defines Drone secrets.

```csv
secretname,secretvalue,namespace,pullrequest,repo
docker_username,docker_usr,Anonymous,1,test1
docker_password,docker_psw,Anonymous,1,test1
```

Columns:

- `secretname`: name exposed to Drone
- `secretvalue`: value of the secret
- `namespace`: user or organization namespace
- `pullrequest`: whether the secret is available to pull requests (`1` or `0`)
- `repo`: repository name; leave empty for namespace-level secrets

Secret values can be base64-encoded by prefixing the value with `b64:`.

---

### `src/config/cron_jobs.csv`

Defines scheduled Drone pipeline executions.

```csv
namespace,repo_name,name,expr
Anonymous,test1,every-2-minutes,0 */2 * * *
Anonymous,test2,every-2-minutes,0 */2 * * *
```

Columns:

- `namespace`: repository owner
- `repo_name`: repository name
- `name`: Drone cron job name
- `expr`: cron expression

---

### `src/config/branch_protection.csv`

Defines branch protection rules.

```csv
username,reponame,branch_name,can_push,required_approvals
```

Example:

```csv
Anonymous,challenge,main,false,1
```

---

### `src/config/contributers.csv`

Defines repository collaborators.

```csv
username, reponame, contributers, mode
```

Example:

```csv
Anonymous,challenge,Alice,write
```

---

### `src/config/tokens.csv`

Defines preloaded Gitea access tokens. Modify this only if you need deterministic tokens for automation.

---

### `src/registry/`

The local registry can be used for storing images locally, including pulling and pushing images from / to.

To replace, or append, the docker credentials to the registry, follow the guide in `src/registry/commands.txt`.

The registry cannot come pre-populated with docker images, and must be populated at runtime. This can either be done using the `src/registry/init.sh` script, where the registry container will populate itself at runtime (requires the docker socket to be mounted), or by loading dockerimages into the VM at build-time in `src/base-runner/preconfig.sh` and pusing them at run-time in `src/base-runner/init.sh`.

---

### `src/proxy/ssl/`

The self signed TLS certificates, used by all the containers for authorized network comunication, can be found here. To replace the certificates, see `src/proxy/ssl/create_certs.sh`

---

### URL

It is possible to change the challende URL to something other than `*.bench.test`, however the URL is mostly hardcoded throughout the project. Changeing all the occurences of the URL (i.e. `bench.test`), and then creating new TLS certificates, works.

It is recommended to use the following grep command to find all the instances:

```sh
grep -r "bench.test" ./src/
```

## Existing Example Repositories

The default artifact includes two example repositories:

```text
src/config/repositories/Anonymous/test1/
src/config/repositories/Anonymous/test2/
```

Each repository directory contains:

```text
git/              Git repository data
repo.yml          Repository metadata
issue.yml         Initial issues
pull_request.yml  Initial pull requests
label.yml         Initial labels
```

The `git/` directory is the repository content imported into Gitea at startup.

---

# Creating a New Challenge

This section describes the recommended workflow for adding a new CI/CD challenge to PipTemp.

The example below creates a new challenge repository called `challenge1` owned by the default user `Anonymous`.

---

## Step 1: Create the Challenge Repository Locally

Create a normal Git repository outside PipTemp first:

```bash
mkdir challenge1
cd challenge1
git init
```

Add the files required by the challenge, for example:

```text
challenge1/
├── README.md
├── Dockerfile
├── app.py
└── .drone.yml
```

A minimal `.drone.yml` could be:

```yaml
kind: pipeline
type: docker
name: default

steps:
  - name: test
    image: alpine:latest
    commands:
      - echo "Pipeline executed"
```

Commit the repository:

```bash
git add .
git commit -m "Initial challenge repository"
```

---

## Step 2: Copy the Git Repository into PipTemp

Create the target directory:

```bash
mkdir -p src/config/repositories/Anonymous/challenge1
```

Copy the repository's `.git` directory into PipTemp and name it `git`:

```bash
cp -r challenge1/.git src/config/repositories/Anonymous/challenge1/git
```

The resulting structure should be:

```text
src/config/repositories/Anonymous/challenge1/
└── git/
```

Only the Git database is copied. The worktree files are restored by Gitea when the repository is imported.

---

## Step 3: Add Repository Metadata

Create `src/config/repositories/Anonymous/challenge1/repo.yml`:

```yaml
assets: true
clone_addr: http://localhost:3000/Anonymous/challenge1
comments: true
description: "Challenge 1"
is_private: false
issues: true
labels: true
milestones: true
name: challenge1
original_url: https://git.bench.test/Anonymous/challenge1
owner: Anonymous
pulls: true
releases: true
service_type: 3
wiki: true
```

Create empty metadata files if you do not need issues, pull requests, or labels:

```bash
printf '[]\n' > src/config/repositories/Anonymous/challenge1/issue.yml
printf '[]\n' > src/config/repositories/Anonymous/challenge1/pull_request.yml
printf '[]\n' > src/config/repositories/Anonymous/challenge1/label.yml
```

---

## Step 4: Register the Repository

Add a row to `src/config/repositories.csv`.

Example:

```csv
Anonymous,challenge1,false,challenge1hooksecret,false,{"push_only":true,"send_everything":false,"choose_events":false,"branch_filter":"*","events":{"create":false,"delete":false,"fork":false,"issues":false,"issue_assign":false,"issue_label":false,"issue_milestone":false,"issue_comment":false,"push":false,"pull_request":false,"pull_request_assign":false,"pull_request_label":false,"pull_request_milestone":false,"pull_request_comment":false,"pull_request_review":false,"pull_request_sync":false,"pull_request_review_request":false,"wiki":false,"repository":false,"release":false,"package":false}}
```

Use a unique `hooksecret` per repository.

---

## Step 5: Add Users if Needed

To add a new user, edit `src/config/users.csv`:

```csv
username,email,password
Anonymous,person@anon.com,password
Alice,alice@example.com,password123
```

The user is created automatically when Gitea is initialized.

---

## Step 6: Add Repository Contributors if Needed

To give another user access to the repository, edit `src/config/contributers.csv`:

```csv
username, reponame, contributers, mode
Anonymous,challenge1,Alice,write
```

Typical modes are:

```text
read
write
admin
```

---

## Step 7: Add Branch Protection if Needed

To protect the `main` branch, edit `src/config/branch_protection.csv`:

```csv
username,reponame,branch_name,can_push,required_approvals
Anonymous,challenge1,main,false,1
```

This can be used to force users to work through pull requests instead of direct pushes.

---

## Step 8: Add Drone Secrets

If the challenge requires secrets, add them to `src/config/secrets.csv`:

```csv
secretname,secretvalue,namespace,pullrequest,repo
flag,DDC{example_flag},Anonymous,0,challenge1
```

Use the secret inside `.drone.yml`:

```yaml
kind: pipeline
type: docker
name: default

steps:
  - name: use-secret
    image: alpine:latest
    environment:
      FLAG:
        from_secret: flag
    commands:
      - echo "Secret is available inside the pipeline"
```

Avoid printing real flags directly unless this is intentional.

---

## Step 9: Add Scheduled Pipeline Runs if Needed

To make Drone run the repository pipeline periodically, edit `src/config/cron_jobs.csv`:

```csv
namespace,repo_name,name,expr
Anonymous,challenge1,every-2-minutes,0 */2 * * *
```

This is useful for challenges where one repository produces an artifact and another repository consumes it later.

---

## Step 10: Add Required Docker Images

If the pipeline uses Docker images, make sure they are available at runtime.

### Option A: Runtime registry population

Edit `src/registry/init.sh` and add pull/tag/push commands:

```bash
docker pull alpine:latest
docker tag alpine:latest registry.bench.test/alpine:1
docker push registry.bench.test/alpine:1
```

This requires internet access and Docker socket access at runtime.

### Option B: VM runner preload

Edit `src/base-runner/preconfig.sh` and add images before the final section:

```bash
docker pull alpine:latest
docker tag alpine:latest registry.bench.test/alpine:1
```

This stores images in the VM image at build time, so they are available without internet access at runtime.

Do not remove the existing `drone/git` and `drone/drone-runner-docker:1` pulls unless you know they are not needed.

---

## Step 11: Choose the Runner Mode

PipTemp includes two runner services in `src/docker-compose.yml`.

### Local runner

Service:

```text
drone-runner-local
```

It mounts the host Docker socket:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

Use this for local development or when host Docker access is acceptable.

### VM runner

Service:

```text
drone-runner-vm
```

It runs the Drone runner inside an Alpine-based QEMU VM.

Use this when you want stronger isolation or when the deployment platform does not allow direct Docker socket access.

For a challenge artifact, keep only the runner you need or clearly document which one should be used.

---

## Step 12: Rebuild from a Clean State

After changing configuration files, rebuild the environment:

```bash
cd src
docker compose down
docker compose build
docker compose up -d
```

If Gitea or Drone already initialized old state, remove old containers/images/volumes as needed before rebuilding.

For a clean local rebuild, you may need:

```bash
docker compose down --volumes --remove-orphans
docker compose build --no-cache
docker compose up -d
```

---

## Step 13: Test the Challenge

1. Open `https://git.bench.test/`.
2. Log in as the intended user.
3. Check that the new repository exists.
4. Open `https://drone.bench.test/`.
5. Check that the repository exists in Drone.
6. Trigger a pipeline by pushing a commit, opening a pull request, or waiting for a cron job.
7. Confirm that the pipeline uses the expected runner, images, and secrets.

---

## Step 14: Package the Challenge

Before submission, verify that:

- The intended runner is enabled.
- Unused runners are disabled or documented.
- Required Docker images are preloaded or pushed to the local registry.
- All secrets are present in `src/config/secrets.csv`.
- All users are present in `src/config/users.csv`.
- All repositories are listed in `src/config/repositories.csv`.
- Each repository has a `git/`, `repo.yml`, `issue.yml`, `pull_request.yml`, and `label.yml` file.
- The challenge works from a clean `docker compose build` and `docker compose up -d`.

---

## Changing Domains

The default domain is `bench.test`.

To change it:

1. Search for all occurrences of `bench.test`:

```bash
grep -R "bench.test" -n src
```

2. Replace the domain in:

- `src/docker-compose.yml`
- `src/setup.sh`
- `src/prerun.sh`
- `src/proxy/default.conf`
- repository metadata under `src/config/repositories/`
- runner and registry configuration scripts if needed

3. Regenerate certificates:

```bash
cd src/proxy/ssl
./create_certs.sh
```

4. Reinstall the CA certificate and rebuild the environment.

---

## Registry Credentials

Registry credentials are configured under:

```text
src/registry/htpasswd
src/registry/config/htpasswd
src/registry/config/config.json
```

`src/registry/commands.txt` contains helper commands for generating new credentials.

If you change the registry username or password, update:

- the htpasswd file
- `config.json`
- Drone secrets in `src/config/secrets.csv`
- runner login commands in `src/base-runner/init.sh` or `src/registry/init.sh`

---

## Troubleshooting

### Browser shows certificate errors

Run:

```bash
cd src
sudo ./setup.sh
```

Then restart the browser or the machine.

---

### Gitea or Drone does not start

Check logs:

```bash
docker compose logs -f gitea
docker compose logs -f drone
```

---

### Pipelines do not run

Check:

- the repository is listed in `src/config/repositories.csv`
- the repository contains `.drone.yml`
- the runner is running
- the webhook secret matches the repository configuration
- the branch name matches the configured default branch, usually `main`

---

### Pipeline image cannot be pulled

Check whether the image is:

- available from the local VM cache
- pushed to `registry.bench.test`
- referenced with the correct tag
- accessible with the registry credentials

---

### VM runner does not work locally

The VM runner may depend on host support for QEMU. If it fails locally, test with `drone-runner-local` first, then retry the VM runner on the intended deployment platform.
