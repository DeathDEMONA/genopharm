#!/bin/bash
# Deployment script for Drupal 11 on Hostinger
DEPLOY_DIR="$HOME/domains/genopharm.co.uk/public_html/drupal"
COMPOSER="$HOME/bin/composer"
DRUSH="$DEPLOY_DIR/vendor/bin/drush"

# Log file for debugging
LOG_FILE="$HOME/deploy.log"
echo "[$(date)] Starting deployment" >> "$LOG_FILE"

# Navigate to the Drupal directory
cd "$DEPLOY_DIR" || { echo "[$(date)] Failed to cd to $DEPLOY_DIR" >> "$LOG_FILE"; exit 1; }

# Ensure Composer is available
if [ ! -f "$COMPOSER" ]; then
    echo "[$(date)] Installing Composer" >> "$LOG_FILE"
    curl -sS https://getcomposer.org/installer | php -- --version=2.8.0
    mv composer.phar ~/bin/composer
    chmod +x ~/bin/composer
fi

# Verify Composer version
"$COMPOSER" --version >> "$LOG_FILE" 2>&1 || { echo "[$(date)] Composer not working" >> "$LOG_FILE"; exit 1; }

# Install Composer dependencies
echo "[$(date)] Running composer install" >> "$LOG_FILE"
"$COMPOSER" install --no-dev --optimize-autoloader >> "$LOG_FILE" 2>&1 || { echo "[$(date)] Composer install failed" >> "$LOG_FILE"; exit 1; }

# Set permissions for Drupal files directory
echo "[$(date)] Setting permissions" >> "$LOG_FILE"
chmod -R 775 "$DEPLOY_DIR/web/sites/default/files" >> "$LOG_FILE" 2>&1
chown -R "$(whoami)":"$(whoami)" "$DEPLOY_DIR/web/sites/default/files" >> "$LOG_FILE" 2>&1

# Run Drupal maintenance tasks with Drush
if [ -f "$DRUSH" ]; then
    echo "[$(date)] Running Drush tasks" >> "$LOG_FILE"
    "$DRUSH" cache:rebuild >> "$LOG_FILE" 2>&1
    "$DRUSH" updatedb -y >> "$LOG_FILE" 2>&1
else
    echo "[$(date)] Drush not found. Skipping Drupal maintenance tasks." >> "$LOG_FILE"
fi

echo "[$(date)] Deployment completed successfully" >> "$LOG_FILE"