# drone-hunter - finds your dronefiles when you have too many repositories.

## Overview

`drone-hunter` is a small utility that trawls whatever GitHub accounts you give it, looking for Drone CI configs.

## Why does this exist?

Because I needed to search across hundreds of repositories across multiple GitHub organizations, searching for drone configs so I could review and compare them. I considered Terraform for this, but opted for Ruby instead, because caching makes iterative development much faster, and I didn't know how to make Terraform do that. Also the GitHub Provider for Terraform didn't handle full repository names for several data sources.

## How do I obtain this majestic tool?

```shell
gem install drone-hunter
```

## How do I use it?

```shell
drone-hunter <owner ...>
```

Where `owner` is either a user or an organization on GitHub.

`drone-hunter` will use the GitHub API to find all the repositories that are visible to you in the accounts you indicated. This means that if you're using private repositories, you'll need a `GITHUB_TOKEN` in the environment that has access to whatever repositories you want it to read from.

With this list of repositories, `drone-hunter` will find the default branches for everything, fetch an index of the tree for the commit at the tip of that branch, dig around for stuff that looks like it might be a drone config, and download all of them.

All of this will be cached.

The current version will output something like this (this may change in future releases):

```json
[
  {
    "repository": "rancherlabs/drone-plugin-golangci-lint",
    "path": ".drone.yml",
    "sha": "d95f9416c3521bdcb4acc0146d9af9fbe42ff165",
    "content": "---\nkind: pipeline\nname: golangci-lint\n\nsteps:\n- name: golangci-lint-run\n  image: rancher/drone-golangci-lint:latest\n  failure: ignore\n\n---\nkind: pipeline\nname: docker\n\nsteps:\n- name: publish\n  image: plugins/docker\n  settings:\n    username:\n      from_secret: docker_username\n    password:\n      from_secret: docker_password\n    repo: rancher/drone-golangci-lint\n    tags: latest\n  when:\n    instance:\n      - drone-publish.rancher.io\n    ref:\n      include:\n        - \"refs/heads/*\"\n        - \"refs/tags/*\"\n        - \"refs/pull/*\"\n    event:\n      - push\n      - tag\n\n"
  }
]
```

By default, it produces JSON output. You can change this with the `--output-format` option. Maybe you want YAML, since that's what drone configs are...

```yaml
- repository: rancherlabs/drone-plugin-golangci-lint
  path: ".drone.yml"
  sha: d95f9416c3521bdcb4acc0146d9af9fbe42ff165
  content: |+
    ---kind: pipelinename: golangci-lintsteps:- name: golangci-lint-run  image: rancher/drone-golangci-lint:latest  failure: ignore---kind: pipelinename: dockersteps:- name: publish  image: plugins/docker  settings:    username:      from_secret: docker_username    password:      from_secret: docker_password    repo: rancher/drone-golangci-lint    tags: latest  when:    instance:      - drone-publish.rancher.io    ref:      include:        - "refs/heads/*"        - "refs/tags/*"        - "refs/pull/*"    event:      - push      - tag
```

Or maybe you want to dump a copy of every dronefile onto the filesystem. Set `--output-format=files` and you'll get something like this:

```shell
find drone-hunter.output -type f
```

```text
drone-hunter.output/rancherlabs/drone-plugin-golangci-lint/.drone.yml
drone-hunter.output/rancherlabs/ssh-pub-keys/.drone.yml
drone-hunter.output/rancherlabs/drone-runner-laboratory/.drone_lab.yml
drone-hunter.output/rancherlabs/rio-website/.drone.yml
drone-hunter.output/rancherlabs/rancher-catalog-stats/.drone.yml
drone-hunter.output/rancherlabs/drone-plugin-fossa/.drone.yml
drone-hunter.output/rancherlabs/swiss-army-knife/.drone.ci.yml
drone-hunter.output/rancherlabs/swiss-army-knife/.drone.yml
drone-hunter.output/rancherlabs/huawei-ui/.drone.yml
drone-hunter.output/rancherlabs/drone-runner-docker/.drone.yml
drone-hunter.output/rancherlabs/k3s-website/.drone.yml
drone-hunter.output/rancherlabs/k3os-website/.drone.yml
drone-hunter.output/rancherlabs/website-theme/.drone.yml
drone-hunter.output/rancherlabs/support-tools/.drone.yml
```

The only limits are your imagination (and the GitHub API Rate Limit).

## License

`drone-hunter` is available under the [MIT License](https://tldrlegal.com/license/mit-license). See `LICENSE.txt` for the full text.
