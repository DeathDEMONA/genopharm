#!/bin/bash
# Deployment script for Drupal 11 on Hostinger
DEPLOY_DIR="$HOME/public_html/drupal"
DRUSH="$DEPLOY_DIR/vendor/bin/drush"

# Navigate to the Drupal directory
cd "$DEPLOY_DIR" || exit

# Ensure Composer is installed
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar ~/bin/composer
fi

# Install Composer dependencies
composer install --no-dev --optimize-autoloader

# Set permissions for Drupal files directory
chmod -R 775 "$DEPLOY_DIR/web/sites/default/files"
chown -R $(whoami):$(whoami) "$DEPLOY_DIR/web/sites/default/files"

# Run Drupal maintenance tasks with Drush
if [ -f "$DRUSH" ]; then
    "$DRUSH" cache:rebuild
    "$DRUSH" updatedb -y
else
    echo "Drush not found. Skipping Drupal maintenance tasks."
fi

echo "Deployment completed successfully."
