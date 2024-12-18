#!/bin/sh
set -ea

if [ "$*" = "strapi" ]; then

  DATABASE_CLIENT=${DATABASE_CLIENT:-sqlite}

  if [ ! -f "package.json" ]; then

    EXTRA_ARGS=${EXTRA_ARGS}

    echo "Using strapi v$STRAPI_VERSION"
    echo "No project found at /srv/app. Creating a new strapi project ..."

    if [ "${STRAPI_VERSION#5}" != "$STRAPI_VERSION" ]; then
      DOCKER=true npx create-strapi-app@${STRAPI_VERSION} . --no-run \
        --js \
        --install \
        --no-git-init \
        --no-example \
        --skip-cloud \
        --skip-db \
        $EXTRA_ARGS
    elif [ "${STRAPI_VERSION#4.25}" != "$STRAPI_VERSION" ]; then
      DOCKER=true npx create-strapi-app@${STRAPI_VERSION} . --no-run \
        --skip-cloud \
        --dbclient=$DATABASE_CLIENT \
        --dbhost=$DATABASE_HOST \
        --dbport=$DATABASE_PORT \
        --dbname=$DATABASE_NAME \
        --dbusername=$DATABASE_USERNAME \
        --dbpassword=$DATABASE_PASSWORD \
        --dbssl=$DATABASE_SSL \
        $EXTRA_ARGS
    else
      DOCKER=true npx create-strapi-app@${STRAPI_VERSION} . --no-run \
        --dbclient=$DATABASE_CLIENT \
        --dbhost=$DATABASE_HOST \
        --dbport=$DATABASE_PORT \
        --dbname=$DATABASE_NAME \
        --dbusername=$DATABASE_USERNAME \
        --dbpassword=$DATABASE_PASSWORD \
        --dbssl=$DATABASE_SSL \
        $EXTRA_ARGS
    fi
    
    echo "" >| 'config/server.js'
    echo "" >| 'config/admin.js'
    echo "" >| 'config/middlewares.js'

    cat <<-EOT >> 'config/server.js'
module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  url: env('PUBLIC_URL', 'http://localhost:1337'),
  app: {
    keys: env.array('APP_KEYS'),
  },
  webhooks: {
    populateRelations: env.bool('WEBHOOKS_POPULATE_RELATIONS', false),
  },
});
EOT

    cat <<-EOT >> 'config/admin.js'
module.exports = ({ env }) => ({
  url: env('ADMIN_URL', 'http://localhost:1337/admin'),
  auth: {
    secret: env('ADMIN_JWT_SECRET'),
  },
  apiToken: {
    salt: env('API_TOKEN_SALT'),
  },
  transfer: {
    token: {
      salt: env('TRANSFER_TOKEN_SALT'),
    },
  },
});
EOT

    cat <<-EOT >> 'config/middlewares.js'
module.exports = ({env}) => ([
  'strapi::logger',
  'strapi::errors',
  {
    name: 'strapi::security',
    config: {
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'connect-src': ["'self'", 'http:', 'https:'],
          'img-src': env('IMG_ORIGIN', "'self',data:,blob:,market-assets.strapi.io").split(','),
          upgradeInsecureRequests: null,
        },
      },
    },
  },
  {
    name: 'strapi::cors',
    config: {
      origin: env('CORS_ORIGIN', '*').split(','),
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'],
      headers: ['Content-Type', 'Authorization', 'Origin', 'Accept'],
      keepHeaderOnError: true,
    }
  },
  'strapi::poweredBy',
  'strapi::query',
  'strapi::body',
  'strapi::session',
  'strapi::favicon',
  'strapi::public',
]);
EOT

  elif [ ! -d "node_modules" ] || [ ! "$(ls -qAL node_modules 2>/dev/null)" ]; then
    echo "Node modules not installed. Installing ..."
    if [ -f "yarn.lock" ]; then
      yarn install --prod
    else
      npm install --only=prod
    fi
  fi

  if [ -f "yarn.lock" ]; then
    current_strapi_version="$(yarn list --pattern strapi --depth=0 | grep @strapi/strapi | cut -d @ -f 3)"
  else
    current_strapi_version="$(npm list | grep @strapi/strapi | cut -d @ -f 3)"
  fi

  get_version_parts() {
    echo "$1" | awk -F. '{print $1, $2, $3}'
  }

  if [ "${STRAPI_VERSION#5}" != "$STRAPI_VERSION" ]; then

    version_parts=$(get_version_parts "$current_strapi_version")
    set -- $version_parts
    current_major=$1
    current_minor=$2
    current_patch=$3

    version_parts=$(get_version_parts "$STRAPI_VERSION")
    set -- $version_parts
    image_major=$1
    image_minor=$2
    image_patch=$3

    if [ "$image_major" -eq "$current_major" ] && [ "$image_minor" -eq "$current_minor" ] && [ "$image_patch" -gt "$current_patch" ]; then
      echo "Patch upgrade needed: v${current_strapi_version} to v${image_major}.${image_minor}.${image_patch}. Upgrading..."
      npx @strapi/upgrade@${STRAPI_VERSION} patch -y || { echo "Patch upgrade failed"; exit 1; }
    fi

    if [ "$image_major" -eq "$current_major" ] && [ "$image_minor" -gt "$current_minor" ]; then
      echo "Minor upgrade needed: v${current_strapi_version} to v${image_major}.${image_minor}.${image_patch}. Upgrading..."
      npx @strapi/upgrade@${STRAPI_VERSION} minor -y || { echo "Minor upgrade failed"; exit 1; }
    fi

    if [ "$image_major" -gt "$current_major" ]; then
      echo "Major upgrade needed: v${current_strapi_version} to v${image_major}.${image_minor}.${image_patch}. Upgrading..."
      echo "Ensuring the current version of Strapi is on the latest minor and patch before major upgrade..."
      echo "Performing pre-upgrade patch updates..."
      npx @strapi/upgrade@${STRAPI_VERSION} patch -y || echo "Pre-upgrade patch update failed or not needed. Check the logs. Continuing..."
      echo "Performing pre-upgrade minor updates..."
      npx @strapi/upgrade@${STRAPI_VERSION} minor -y || echo "Pre-upgrade minor update failed or not needed. Check the logs. Continuing..."
      echo "Performing major upgrade..."
      npx @strapi/upgrade@${STRAPI_VERSION} major -y || { echo "Major upgrade failed"; exit 1; }

      if [ -f "yarn.lock" ]; then
        updated_strapi_version="$(yarn list --pattern strapi --depth=0 | grep @strapi/strapi | cut -d @ -f 3)"
      else
        updated_strapi_version="$(npm list | grep @strapi/strapi | cut -d @ -f 3)"
      fi

      version_parts=$(get_version_parts "$updated_strapi_version")
      set -- $version_parts
      updated_major=$1
      updated_minor=$2
      updated_patch=$3

      if [ "$image_major" -eq "$updated_major" ] && [ "$image_minor" -eq "$updated_minor" ] && [ "$image_patch" -gt "$updated_patch" ]; then
        echo "Post-upgrade patch update needed: v${updated_strapi_version} to v${image_major}.${image_minor}.${image_patch}. Updating..."
        npx @strapi/upgrade@${STRAPI_VERSION} patch -y || { echo "Post-upgrade patch update failed"; exit 1; }
      fi

      if [ "$image_major" -eq "$updated_major" ] && [ "$image_minor" -gt "$updated_minor" ]; then
        echo "Post-upgrade minor update needed: v${updated_strapi_version} to v${image_major}.${image_minor}.${image_patch}. Updating..."
        npx @strapi/upgrade@${STRAPI_VERSION} minor -y || { echo "Post-upgrade minor update failed"; exit 1; }
      fi

    fi
  else
    current_strapi_code="$(echo "${current_strapi_version}" | tr -d "." )"
    image_strapi_code="$(echo "${STRAPI_VERSION}" | tr -d "." )"
    if [ "${image_strapi_code}" -gt "${current_strapi_code}" ]; then
      echo "Strapi update needed: v${current_strapi_version} to v${STRAPI_VERSION}. Updating ..."
      if [ -f "yarn.lock" ]; then
        yarn add "@strapi/strapi@${STRAPI_VERSION}" "@strapi/plugin-users-permissions@${STRAPI_VERSION}" "@strapi/plugin-i18n@${STRAPI_VERSION}" "@strapi/plugin-cloud@${STRAPI_VERSION}" --prod || { echo "Upgrade failed"; exit 1; }
      else
        npm install @strapi/strapi@"${STRAPI_VERSION}" @strapi/plugin-users-permissions@"${STRAPI_VERSION}" @strapi/plugin-i18n@"${STRAPI_VERSION}" @strapi/plugin-cloud@"${STRAPI_VERSION}" --only=prod || { echo "Upgrade failed"; exit 1; }
      fi
    fi
  fi

  if ! grep -q "\"react\"" package.json; then
    echo "Adding React and Styled Components..."
    if [ -f "yarn.lock" ]; then
      yarn add "react@^18.0.0" "react-dom@^18.0.0" "react-router-dom@^5.3.4" "styled-components@^5.3.3" --prod || { echo "Adding React and Styled Components failed"; exit 1; }
    else
      npm install react@"^18.0.0" react-dom@"^18.0.0" react-router-dom@"^5.3.4" styled-components@"^5.3.3" --only=prod || { echo "Adding React and Styled Components failed"; exit 1; }
    fi
  fi

  if [ "${DATABASE_CLIENT}" -eq "postgres" ] && [ ! grep -q "\"pg\"" package.json ]; then
    echo "Adding Postgres packages..."
    if [ -f "yarn.lock" ]; then
      yarn add "pg@^8.13.0" --prod || { echo "Adding Postgres packages failed"; exit 1; }
    else
      npm install pg@"^8.13.0" --only=prod || { echo "Adding Postgres packages failed"; exit 1; }
    fi
  fi

  BUILD=${BUILD:-false}

  if [ "$BUILD" = "true" ]; then
    echo "Building Strapi admin..."
    if [ -f "yarn.lock" ]; then
      yarn build
    else
      npm run build
    fi
  fi

  if [ "$NODE_ENV" = "production" ]; then
    STRAPI_MODE="start"
  elif [ "$NODE_ENV" = "development" ]; then
    STRAPI_MODE="develop"
  fi

  echo "Starting your app (with ${STRAPI_MODE:-develop})..."

  if [ -f "yarn.lock" ]; then
    exec yarn "${STRAPI_MODE:-develop}"
  else
    exec npm run "${STRAPI_MODE:-develop}"
  fi

else
  exec "$@"
fi