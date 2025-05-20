#!/bin/bash
# Menu script for Genopharm Drupal project using dialog

# Dialog configuration
DIALOG=${DIALOG:-dialog}
HEIGHT=15
WIDTH=40
MENU_HEIGHT=10

# SSH connection details
SSH_USER="u790209709"
SSH_HOST="194.164.74.4"
SSH_PORT="65002"
SSH_PASS="ks7hro7wOW&*&@Hrf"

# Backup settings
REMOTE_DRUPAL_DIR="domains/genopharm.co.uk/public_html/drupal"
LOCAL_BACKUP_DIR="$HOME/genopharm/DBs"
BACKUP_FILE="genopharm-$(date +%Y%m%d-%H%M%S).sql"

# Secure script permissions
chmod 600 "$0"

# DBs Operations submenu
dbs_menu() {
    while true; do
        # Clear and reset terminal colors before dialog
        clear
        tput reset
        choice=$($DIALOG --clear \
            --colors \
            --title "DBs Operations" \
            --menu "Select a database operation:" $HEIGHT $WIDTH $MENU_HEIGHT \
            1 "Backup PROD DB" \
            2 "Import DB" \
            3 "Back" \
            2>&1 >/dev/tty)

        # Reset terminal colors after dialog
        tput reset
        clear

        case $choice in
            1)
                echo "Backing up production database..."
                # Clean local DBs directory
                echo "Cleaning local DBs directory..."
                rm -f "$LOCAL_BACKUP_DIR"/*.sql.gz
                echo "Local DBs directory cleaned."
                # Create backup on Hostinger
                if sshpass -p "$SSH_PASS" ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" \
                    "cd $REMOTE_DRUPAL_DIR && vendor/bin/drush sql:dump --gzip --result-file=../$BACKUP_FILE 2>&1"; then
                    # Download the backup
                    if sshpass -p "$SSH_PASS" scp -P "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST":domains/genopharm.co.uk/public_html/drupal/$BACKUP_FILE.gz "$LOCAL_BACKUP_DIR/"; then
                        # Remove the backup from Hostinger
                        sshpass -p "$SSH_PASS" ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" \
                            "rm domains/genopharm.co.uk/public_html/drupal/$BACKUP_FILE.gz"
                        echo "Backup downloaded to $LOCAL_BACKUP_DIR/$BACKUP_FILE"
                    else
                        echo "Error downloading backup"
                    fi
                else
                    echo "Error creating backup on Hostinger"
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                echo "Importing database to local DDEV..."
                # Find the single backup file
                IMPORT_FILE=$(ls "$LOCAL_BACKUP_DIR"/*.sql.gz 2>/dev/null | head -n 1)
                if [ -z "$IMPORT_FILE" ]; then
                    echo "No backup file found in $LOCAL_BACKUP_DIR"
                    read -p "Press Enter to continue..."
                    continue
                fi
                if [ -f "$IMPORT_FILE" ]; then
                    echo "Importing $IMPORT_FILE..."
                    ddev drush sql:drop -y
                    zcat "$IMPORT_FILE" | ddev drush sql:cli
                    ddev drush deploy
                    echo "Database imported and deployed."
                else
                    echo "Error: Backup file not found."
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                return
                ;;
            *)
                return
                ;;
        esac
    done
}

# Drush Commands submenu (local via DDEV)
drush_menu() {
    while true; do
        # Clear and reset terminal colors before dialog
        clear
        tput reset
        choice=$($DIALOG --clear \
            --colors \
            --title "Drush Commands (Local)" \
            --menu "Select a Drush command:" $HEIGHT $WIDTH $MENU_HEIGHT \
            1 "Run drush deploy" \
            2 "Back" \
            2>&1 >/dev/tty)

        # Reset terminal colors after dialog
        tput reset
        clear

        case $choice in
            1)
                echo "Running drush deploy locally via DDEV..."
                if ddev drush deploy 2>&1; then
                    echo "Drush deploy completed."
                else
                    echo "Error running drush deploy."
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                return
                ;;
            *)
                return
                ;;
        esac
    done
}

# Main menu function
main_menu() {
    while true; do
        # Clear and reset terminal colors before dialog
        clear
        tput reset
        choice=$($DIALOG --clear \
            --colors \
            --title "Genopharm Drupal Menu" \
            --menu "Select an option:" $HEIGHT $WIDTH $MENU_HEIGHT \
            1 "SSH to Hostinger" \
            2 "DBs Operations" \
            3 "Drush Commands" \
            4 "Exit" \
            2>&1 >/dev/tty)

        # Reset terminal colors after dialog
        tput reset
        clear

        case $choice in
            1)
                echo "Connecting to Hostinger..."
                sshpass -p "$SSH_PASS" ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST"
                ;;
            2)
                dbs_menu
                ;;
            3)
                drush_menu
                ;;
            4)
                exit 0
                ;;
            *)
                exit 0
                ;;
        esac
    done
}

# Trap to clean up dialog and reset colors on exit
trap 'tput reset; clear' EXIT

# Run the main menu
main_menu