# Strapi (v4+ and v5+) containerized

![Strapi](https://github.com/V-Shadbolt/Docker-strapi/blob/main/assets/PNG.logo.purple.dark.png?raw=true)

> Docker image for Strapi v4 and Strapi v5 (latest version)

API creation made simple, secure and fast. The most advanced open-source Content Management Framework to build powerful API with no effort.

[GitHub repository](https://github.com/V-Shadbolt/Docker-strapi)

[Docker Hub](https://hub.Docker.com/r/vshadbolt/strapi)

[![Docker Pulls](https://img.shields.io/docker/pulls/vshadbolt/strapi.svg?style=for-the-badge)](https://hub.Docker.com/r/vshadbolt/strapi)

---

# How to use ?

This image allows you to create a new Strapi project or run an existing Strapi project in Docker.

For either new or existing projects, changing the `NODE_ENV` environment variable will determine how your projects starts.

- `$NODE_ENV = development`: The command that will run in your project
  in dev mode with [`strapi develop`](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html#strapi-develop).

- for `$NODE_ENV = production`: The command that will run in your project
  in prod mode with [`strapi start`](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html#strapi-start).

> The [Content-Type Builder](https://strapi.io/features/content-types-builder) plugin is disabled WHEN `$NODE_ENV = production`.

---

## Creating a new Strapi project

When running this image, Strapi will check if there is a project in the `/srv/app` folder of the container. If there is not an existing project, it will run the [`create strapi-app`](https://docs.strapi.io/dev-docs/quick-start#-part-a-create-a-new-project-with-strapi) command in the containers' `/srv/app` folder.

This command defaults to creating a project with an SQLite database and then starts Strapi on port `1337`.

However, this image overwrites the unconfigured `config/admin.js`, `config/server.js`, and `config/middlewares.js` files to accomodate setting image sources, CORS params, admin url(s), and public server url(s) as Docker ENV variables. See below for example configurations.

- `ADMIN_URL: tobemodified`: Sets a custom sub/domain for your admin page. Ex. `https://api.example.com/admin`. Without adding the command, the config will default to `http://localhost:1337/admin`. 

- `PUBLIC_URL: tobemodified`: Sets a custom domain for your api endpoint(s). Ex. `https://api.example.com`. Without adding the env variable, the config will default to `http://localhost:1337` 

- `IMG_ORIGIN: "toBeModified1,toBeModified2"`: Add new image sources for your project. Ex. `'self',data:,blob:,market-assets.strapi.io,api.example.com`. Without adding the env variable, the config will default to `'self',data:,blob:,market-assets.strapi.io`

- `CORS_ORIGIN: "toBeModified1,toBeModified2"`: Add new CORS origin sources to your project. Ex. `https://myfrontendwebsite.example.com,https://api.example.com`. Without adding the env variable, the config will default to `*`.

> The `ADMIN_URL` and `PUBLIC_URL` default will throw errors if your Docker host is remote. You'll need to set your Docker host IP at the minimum for remote projects. Ex. `http://192.168.1.1:1337`. Ideally use an nginx proxy setup or sub/domain. If your host is not remote, `http://localhost:1337` will work as expected.

Along with the above, the image also supports configuring database settings:

- `DATABASE_CLIENT: tobemodified`: A database provider supported by Strapi: (sqlite, postgres, mysql ,mongo). E.x. postgres

- `DATABASE_HOST: database host IP / container name`: The database host IP or container name. Ex. strapiDB

- `DATABASE_PORT: database host port / container port`: The database host port or container port. Ex. 5432

- `DATABASE_NAME: tobemodified`: The name of the database. Ex. strapi

- `DATABASE_USERNAME: tobemodified`: The username for the database. Ex. strapi

- `DATABASE_PASSWORD: tobemodified`: The password for the database. Ex. strapi

- `DATABASE_SSL: tobemodified`: A boolean for SSL. Ex. false

Next, we can set secrets for Strapi to use. All of these are random strings than can be generated.

- `JWT_SECRET: tobemodified`: A random string. Ex. `JrWfVf/o9TbWQmpMgsJaYp==`

- `ADMIN_JWT_SECRET: tobemodified`: A random string. Ex. `MCpf2/FMiCJthF5d6Qup6iG==`

- `APP_KEYS: toBeModified1,toBeModified2`: Multiple random strings. Ex. `w9/ZTuHUWNF2EP8gdfPcNn==,LqXKC52TsN/z/Y2rUGTa6m==,d7EKo2Tp9SiGf82ZqrmSnB==,TAu2SJx6BDc7aYUyqiwxKs==`

- `API_TOKEN_SALT: tobemodified`: A random string. Ex. `j43/kBRfXULfPpJnzPCJzi==`

- `TRANSFER_TOKEN_SALT: tobemodified`: A random string. Ex. `GCX3NkRSyHrDxhfgwnmCm3==`

Finally, we have a variable for re-building Strapi. After modifying any of the files in the `/config` directory or changing their respective environment variables (`ADMIN_URL`, `PUBLIC_URL`, `IMG_ORIGIN`, `CORS_ORIGIN`), the project will need to be rebuilt to account for the changes. To do so, add the following configuration to the Docker command/compose file. Note that not adding this argument will negate any changes made within the `/config` directory until it is added. It is particularily important for any URL changes or your project will not function as expected. The build will be persisted between container restarts and is specific to `/config` changes.

- `BUILD: tobemodified`: A boolean for re-building the Strapi project. Ex. true

### Reverse Proxy Support

When running Strapi behind a reverse proxy (like Caddy, Nginx, or Traefik) in development mode (`NODE_ENV=development`), you might encounter the error:

```
Blocked request. This host ("api.example.com") is not allowed.
To allow this host, add "api.example.com" to `server.allowedHosts` in vite.config.js.
```

This happens because Vite (the development server) blocks requests from hosts that aren't explicitly allowed. To fix this, you can use:

- `ENABLE_VITE_ALLOWED_HOSTS: tobemodified`: A boolean to enable Vite allowed hosts fix. Ex. `true`

When set to `true`, this will automatically create a `vite.config.js` file that allows all hosts, resolving the reverse proxy issue.

> Here is a completed example [compose file](./examples/strapi-postgres/docker-compose.yml) for the available environment variables as well as the configuration for a postgres database. You can find more examples [here](https://github.com/V-Shadbolt/docker-strapi/tree/main/examples), including a [reverse proxy example](./examples/strapi-reverse-proxy/docker-compose.yml).

- The official documentation for Strapi and these files is linked below.

---

## Migrating an existing Strapi project

To run an existing project that was not created with this image, you can mount the project folder in the container at `/srv/app`. The project will need to be modified directly rather than relying on Docker env variables. Remember to also ensure your existing database is still accessible from the migrated project. It is also possible to migrate your DB to Docker as well and reference it as a volume for your DB image. Ensure the DB image is the same version as your existing DB to avoid hiccups. Remember to backup responsibly.

> For existing projects, `config/admin.js`, `config/server.js`, and `config/middlewares.js` files will need to be configured to not use `http://localhost:1337` if they haven't been already unless your host is local.

For existing projects that were created using this image an your are migrating to a different machine, you can mount the project folder in the container at `/srv/app` and take advantage of the environment variables outlined above to make modifications to your project. Your Database can also be migrated following the same logic.

---

## Updating Strapi

### V4+
To upgrade Strapi v4+, stop your Strapi container and pull the image / update your compose file with the respective tag for the Strapi version you would like to upgrade to: `:4.x.x` or `:latest-v4`. Then re-create your Strapi container with the new image. 

> Note the upgrade process is very slow, automatic, and will upgrade across minor and patch versions. There may be breaking changes between upgrades. Please remember to backup responsibly.

### V4 to V5

:warning: Proceed with caution. To upgrade from Strapi v4 to Strapi v5, stop your Strapi container and pull the latest image / update your compose file with the `latest` or any `:5.x.x` tag. Then re-create your Strapi container with the new image. The image *should* handle the migration without user intervention outside of Database and API changes. Ensure you have a backup in place as the new Strapi [Upgrade Tool](https://docs.strapi.io/dev-docs/upgrade-tool) may fail with unresolvable dependency conflicts, may not properly update the codebase, or cause your existing configuration to break.

[Official Upgrade Guide](https://docs.strapi.io/dev-docs/migration/v4-to-v5/step-by-step) 

> Note the upgrade process can be slow, intensive, and will upgrade across major, minor, and patch versions. There may be breaking changes between upgrades. Please remember to backup responsibly.

### V5+
  
To upgrade Strapi v5+, stop your Strapi container and and pull the image / update your compose file with the respective tag for the Strapi version you would like to upgrade to: `:5.x.x` or `:latest`.. Then re-create your Strapi container with the new image.

> :warning: Strapi v5 now utilizes an [Upgrade Tool](https://docs.strapi.io/dev-docs/upgrade-tool) that may fail with unresolvable dependency conflicts or otherwise loop. Also Note the upgrade process can be slow and will upgrade across minor and patch versions. There may be breaking changes between upgrades. Please remember to backup responsibly.

---

### Missing React modules for Strapi v4.15.5+

The Docker entrypoint and Docker file have been modified to replace the `strapi new` command (now deprecated) with `npx create strapi-app` which will gather the required packages. With this change, the image is now substantially smaller. For existing Strapi projects, the updated entrypoint will add the missing packages [`react`, `react-dom`, `react-router-dom`, `styled-components`] if they haven't already been installed. Please remember to backup responsibly.

---

### Strapi Cloud v4.25.0+

The Docker entrypoint has been modified to skip the Strapi Cloud setup for new Strapi projects. Strapi Cloud is meant to host your Strapi instance which is an alternative to this image. You can read more about Strapi Cloud [here](https://strapi.io/cloud).

---

### Cannot find module 'pg'

The Docker entrypoint has been modified to add the missing `pg` modules if the Strapi database is configured to use Postgres starting in `v5.6.0` and `v4.25.16`.

---

### Cannot find module 'mysql'

The Docker entrypoint has been modified to add the missing `pg` modules if the Strapi database is configured to use Postgres starting in `v5.10.2` and `v4.25.20`.

---

# Official Documentation

- The official documentation of Strapi is available on [https://docs.strapi.io/](https://docs.strapi.io/).

- The official Strapi v3 Docker image is available on [GitHub](https://github.com/strapi/strapi-Docker) (no longer maintained).

- The official Docker documentation for Strapi, including example Dockerfiles, is available on [https://docs.strapi.io/dev-docs/installation/Docker](https://docs.strapi.io/dev-docs/installation/Docker).
