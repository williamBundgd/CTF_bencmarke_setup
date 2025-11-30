# Bencmarking pipeline setup

A pipeline setup meant to benchmark its own performance, but no real benchmarking scripts has been added.
In stead, this pipeline, its architecture, and setup, is meant to be reused for creating DevOps based CTFs or other projects.
It can be heavily modified to suite your needs. You can add users, repositories, pipeline secrets, contribution rules, branch protection rules,
and cron jobs using simple config files under `src/config/{filename}.csv`.

To add repositories, you can use the .git file of a git repo, and insert it as `src/config/repositories/{username}/{reponame}/git`.
There are other config files per repository, so make sure to have a look at them to understand their configurations.

Use the drone runner directly, or in a VM. Both methods are included here. Both are likely not needed, so you can remove the one you don't need.
If your pipeline will not have access to internet or other resources on the host, you likely need the VM version.
Both runners can be customised to your need.

The local registry allows you to build, push and store images dynamically for your pipeline needs. However, if you want to populate it with
images on startup, you need access to both internet and outside resources from the host. If you do not have access to this, 
there is a way to pull and tag images onto the VM at build time under `src/base-runner/preconfig.sh` without the need for internet access at runtime.

Changing the domain name is a little more annoying at the current version. You have to both change the domain everywhere it is used manually. A simple grep command can help you.
Secondly, you need to create new ca-certificates for the new domain name. I have added a script under `src/proxy/ssl/create_certs.sh` that can be used to create new certificates. The file itself contains a guide on how to use it.

Please feel free to change, remove or add to the architecture in any way you see fit. You can either reuse the architecture, or you can modify it or replace parts.

## Domain Names
- `git.bench.test`
- `drone.bench.test`
- `registry.bench.test`
- `internalgit.bench.test`
- `internaldrone.bench.test`
- `internalrunner.bench.test`
- `internalregistry.bench.test`

# Descriptions

## How to run locally

This project was developed with linux in mind, so it might not work well for other OS.

You need docker with docker compose installed on a linux computer.

- Open the terminal and go to the `{path_to_project}/src/` folder.
- `sudo ./prerun.sh`
- This should set everything up and open the websites. If this is your first time running the project, you might need to restart your PC to make sure the ca-certificates work


- got to git.bench.test and drone.bench.test in you browser. 
- You should be able to see both a Gitea server and a Drone CI server
- Log in to the servers with username = William, password = password
- Please note that I have had some trouble getting the VM in the runner docker container to work. It does not work on all systems, but it seems to work well on Haaukins servers.
