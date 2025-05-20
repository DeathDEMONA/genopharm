#!/bin/bash
# Deployment script for Drupal 11 on Hostinger
DEPLOY_DIR="$HOME/domains/genopharm.co.uk/public_html/drupal"
COMPOSER="$HOME/bin/composer"
DRUSH="$DEPLOY_DIR/vendor/bin/drush"
LOG_FILE="$HOME/deploy.log"
CONFIG_SYNC_DIR="$DEPLOY_DIR/config/sync"

# Determine if running interactively (console) or non-interactively (cron)
if [ -t 1 ]; then
    # Interactive: Output to console
    log() { echo "[$(date)] $1"; }
else
    # Non-interactive: Append to log file
    log() { echo "[$(date)] $1" >> "$LOG_FILE"; }
fi

log "Starting deployment"

# Navigate to the Drupal directory
cd "$DEPLOY_DIR" || { log "Failed to cd to $DEPLOY_DIR"; exit 1; }

# Ensure Composer is available
if [ ! -f "$COMPOSER" ]; then
    log "Installing Composer"
    curl -sS https://getcomposer.org/installer | php -- --version=2.8.0
    mv composer.phar ~/bin/composer
    chmod +x ~/bin/composer
fi

# Verify Composer version
"$COMPOSER" --version 2>&1 | while IFS= read -r line; do log "$line"; done || { log "Composer not working"; exit 1; }

# Install Composer dependencies
log "Running composer install"
"$COMPOSER" install --no-dev --optimize-autoloader 2>&1 | while IFS= read -r line; do log "$line"; done || { log "Composer install failed"; exit 1; }

# Ensure Drush is installed
if [ ! -f "$DRUSH" ]; then
    log "Installing Drush"
    "$COMPOSER" require drush/drush:^12 2>&1 | while IFS= read -r line; do log "$line"; done
fi

# Create and set permissions for config sync and files directories
mkdir -p "$CONFIG_SYNC_DIR" 2>&1 | while IFS= read -r line; do log "$line"; done
log "Setting permissions"
chmod -R 775 "$DEPLOY_DIR/web/sites/default/files" "$CONFIG_SYNC_DIR" 2>&1 | while IFS= read -r line; do log "$line"; done
chown -R "$(whoami)":"$(whoami)" "$DEPLOY_DIR/web/sites/default/files" "$CONFIG_SYNC_DIR" 2>&1 | while IFS= read -r line; do log "$line"; done

# Ensure settings.prod.php exists with correct permissions
if [ -f "$DEPLOY_DIR/web/sites/default/settings.prod.php" ]; then
    chmod 644 "$DEPLOY_DIR/web/sites/default/settings.prod.php" 2>&1 | while IFS= read -r line; do log "$line"; done
fi

# Check for database update flag
if [ -f "$DEPLOY_DIR/db-update.txt" ]; then
    log "Database update requested"
    # Import database using Drush
    if [ -f "$DEPLOY_DIR/genopharm.sql.gz" ]; then
        gunzip -c "$DEPLOY_DIR/genopharm.sql.gz" | "$DRUSH" sql:cli 2>&1 | while IFS= read -r line; do log "$line"; done
        log "Database imported via Drush"
        rm "$DEPLOY_DIR/genopharm.sql.gz" 2>&1 | while IFS= read -r line; do log "$line"; done
    else
        log "No genopharm.sql.gz found, skipping DB import"
    fi
    rm "$DEPLOY_DIR/db-update.txt" 2>&1 | while IFS= read -r line; do log "$line"; done
fi

# Run Drupal maintenance tasks with Drush
if [ -f "$DRUSH" ]; then
    log "Running Drush tasks"
    "$DRUSH" cache:rebuild 2>&1 | while IFS= read -r line; do log "$line"; done
    "$DRUSH" updatedb -y 2>&1 | while IFS= read -r line; do log "$line"; done
    "$DRUSH" config:import -y 2>&1 | while IFS= read -r line; do log "$line"; done
    "$DRUSH" cache:rebuild 2>&1 | while IFS= read -r line; do log "$line"; done
else
    log "Drush not found. Skipping Drupal maintenance tasks."
fi

# Compile SCSS for genopharm_theme
THEME_DIR="$DEPLOY_DIR/web/themes/custom/genopharm_theme"
log "Checking for Node.js"
if ! command -v node >/dev/null 2>&1; then
    log "Installing Node.js"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - 2>&1 | while IFS= read -r line; do log "$line"; done
    apt-get install -y nodejs 2>&1 | while IFS= read -r line; do log "$line"; done
fi
log "Navigating to theme directory"
cd "$THEME_DIR" 2>&1 | while IFS= read -r line; do log "$line"; done || { log "Failed to cd to $THEME_DIR"; exit 1; }
log "Installing npm dependencies"
npm install 2>&1 | while IFS= read -r line; do log "$line"; done || { log "npm install failed"; exit 1; }
log "Compiling SCSS"
npm run build 2>&1 | while IFS= read -r line; do log "$line"; done || { log "SCSS compilation failed"; exit 1; }
log "Returning to deploy directory"
cd "$DEPLOY_DIR" 2>&1 | while IFS= read -r line; do log "$line"; done
log "Rebuilding cache after SCSS compilation"
"$DRUSH" cache:rebuild 2>&1 | while IFS= read -r line; do log "$line"; done


log "Deployment completed successfully"