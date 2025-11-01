#!/bin/bash

################################################################################
# OpenSocial (Drupal) Installation Script with DDEV on Ubuntu
# This script automates the installation of OpenSocial using DDEV
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to wrap steps with clear headers
step_header() {
    local step_num=$1
    local step_name=$2
    echo ""
    echo "============================================"
    echo "STEP $step_num: $step_name"
    echo "============================================"
}

step_complete() {
    local step_num=$1
    local step_name=$2
    echo ""
    print_status "✓ STEP $step_num COMPLETE: $step_name"
    echo "============================================"
    echo ""
}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_skip() {
    echo -e "${BLUE}[SKIP]${NC} $1"
}

# Interactive mode flag
INTERACTIVE_MODE=false
SKIP_STEPS=()

# Function to check if a step should be skipped
should_skip_step() {
    local step_num=$1
    for skip in "${SKIP_STEPS[@]}"; do
        if [ "$skip" == "$step_num" ]; then
            return 0  # Should skip
        fi
    done
    return 1  # Should not skip
}

# Function to ask user if they want to run a step
ask_step() {
    local step_num=$1
    local step_name=$2
    
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo ""
        echo -e "${BLUE}Step $step_num: $step_name${NC}"
        read -p "Do you want to run this step? (Y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            SKIP_STEPS+=("$step_num")
            return 1  # Skip
        fi
    fi
    return 0  # Run
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interactive)
            INTERACTIVE_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS] [PROJECT_NAME] [OPENSOCIAL_VERSION]"
            echo ""
            echo "Options:"
            echo "  -i, --interactive    Run in interactive mode (choose which steps to run)"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Run all steps automatically (dev-master)"
            echo "  $0 -i                                 # Run in interactive mode"
            echo "  $0 my-site                            # Custom project name (dev-master)"
            echo "  $0 my-site 12.4.13                    # Custom project name and specific version"
            echo "  $0 my-site 13.0.0-beta1               # Install beta version"
            echo "  $0 -i my-site                         # Interactive with custom name"
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

# Check if running on Ubuntu
if [ ! -f /etc/os-release ]; then
    print_error "Cannot determine OS. This script is designed for Ubuntu."
    exit 1
fi

source /etc/os-release
if [[ ! "$ID" == "ubuntu" ]]; then
    print_warning "This script is designed for Ubuntu. Your OS: $ID"
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Configuration variables
PROJECT_NAME="${1:-opensocial}"
OPENSOCIAL_VERSION="${2:-dev-master}"  # Use dev-master for latest, or specific version like 12.4.13
PHP_VERSION="8.2"
MYSQL_VERSION="8.0"
NODEJS_VERSION="18"

# Site configuration defaults
SITE_NAME="OpenSocial Community"
SITE_MAIL="admin@example.com"
ADMIN_USER="admin"
ADMIN_PASS="admin"
ADMIN_MAIL="admin@example.com"
DEFAULT_COUNTRY="US"
SITE_TIMEZONE="America/New_York"

print_status "Starting OpenSocial installation with DDEV"
print_status "Project name: $PROJECT_NAME"
print_status "OpenSocial version: $OPENSOCIAL_VERSION"
print_status "Note: Use 'dev-master' for latest, or specific versions like '12.4.13', '13.0.0-beta1'"
echo ""
echo "╔════════════════════════════════════════════╗"
echo "║   OpenSocial DDEV Installation Script     ║"
echo "║                                            ║"
echo "║   Steps to be executed:                    ║"
echo "║   [1] System Prerequisites                 ║"
echo "║   [2] DDEV & Docker                        ║"
echo "║   [3] mkcert (HTTPS)                       ║"
echo "║   [4] Project Directory                    ║"
echo "║   [5] DDEV Configuration                   ║"
echo "║   [6] Start DDEV                           ║"
echo "║   [7] Install via Composer                 ║"
echo "║   [8] Install Drupal/OpenSocial            ║"
echo "║   [9] Configure Site Settings              ║"
echo "║   [10] Enable Modules                      ║"
echo "║   [11] User & Content Settings             ║"
echo "║   [12] Cache & Permissions                 ║"
echo "║   [13] Development Settings                ║"
echo "║   [14] Summary & Completion                ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Step 1: Install prerequisites
if ! should_skip_step 1 && ask_step 1 "Install system prerequisites"; then
    echo ""
    echo "============================================"
    echo "STEP 1: Install System Prerequisites"
    echo "============================================"
    print_status "Checking system prerequisites..."
    
    # Check if packages are already installed
    PACKAGES_TO_INSTALL=()
    PACKAGES="ca-certificates curl gnupg lsb-release libnss3-tools apt-transport-https software-properties-common"
    
    for pkg in $PACKAGES; do
        if ! dpkg -l | grep -q "^ii  $pkg"; then
            PACKAGES_TO_INSTALL+=("$pkg")
        fi
    done
    
    if [ ${#PACKAGES_TO_INSTALL[@]} -eq 0 ]; then
        print_skip "All system prerequisites are already installed"
    else
        print_status "Installing missing packages: ${PACKAGES_TO_INSTALL[*]}"
        sudo apt-get update
        sudo apt-get install -y "${PACKAGES_TO_INSTALL[@]}"
        print_status "System prerequisites installed successfully"
    fi
    
    echo ""
    print_status "✓ STEP 1 COMPLETE: System prerequisites ready"
    echo "============================================"
    echo ""
else
    print_skip "Skipping system prerequisites installation"
fi

# Step 2: Install DDEV and Docker if not already installed
if ! should_skip_step 2 && ask_step 2 "Install DDEV and Docker"; then
    echo ""
    echo "============================================"
    echo "STEP 2: Install DDEV and Docker"
    echo "============================================"
    print_status "Checking for DDEV installation..."

    if ! command -v ddev &> /dev/null; then
        print_status "DDEV not found. Installing DDEV..."
        
        # Install Docker if not present
        if ! command -v docker &> /dev/null; then
            print_status "Installing Docker..."
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            fi
            
            # Set up Docker repository
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker Engine
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # Add current user to docker group
            sudo usermod -aG docker $USER
            print_status "✓ Docker installed successfully: $(docker --version)"
            
            # Activate docker group for current session
            print_warning "Added $USER to docker group."
            print_warning "Attempting to activate docker group for this session..."
            
            # Try to activate the group in the current session
            if command -v newgrp &> /dev/null; then
                print_status "You may need to run: newgrp docker"
            fi
            
            echo ""
            print_error "============================================"
            print_error "IMPORTANT: Docker Group Change"
            print_error "============================================"
            print_error "Docker has been installed and your user added to the docker group."
            print_error "However, you need to activate this change by doing ONE of:"
            print_error ""
            print_error "Option 1 (Recommended): Log out and log back in"
            print_error "Option 2: Run this command, then re-run this script:"
            print_error "          newgrp docker"
            print_error "Option 3: Reboot your system"
            print_error ""
            print_error "After doing one of the above, re-run this installation script."
            print_error "============================================"
            exit 0
        else
            print_skip "Docker is already installed: $(docker --version)"
        fi
        
        # Install DDEV
        print_status "Installing DDEV..."
        curl -fsSL https://ddev.com/install.sh | bash
        print_status "✓ DDEV installed successfully: $(ddev version | head -n 1)"
    else
        print_skip "DDEV is already installed: $(ddev version | head -n 1)"
    fi
    
    # Check if user can access Docker (test for permission issue)
    print_status "Verifying Docker permissions..."
    if ! docker ps >/dev/null 2>&1; then
        print_error "============================================"
        print_error "Docker Permission Error Detected"
        print_error "============================================"
        print_error "You don't have permission to access Docker."
        print_error ""
        print_error "Current user: $USER"
        print_error "Docker group membership:"
        groups | grep docker || echo "  NOT in docker group"
        print_error ""
        print_error "FIX THIS ISSUE:"
        print_error ""
        print_error "1. Add yourself to the docker group:"
        print_error "   sudo usermod -aG docker $USER"
        print_error ""
        print_error "2. Activate the change (choose ONE):"
        print_error "   Option A: Log out and log back in (RECOMMENDED)"
        print_error "   Option B: Run: newgrp docker"
        print_error "             Then re-run this script"
        print_error "   Option C: Reboot your system"
        print_error ""
        print_error "3. Verify it works:"
        print_error "   docker ps"
        print_error ""
        print_error "4. Re-run this installation script"
        print_error "============================================"
        exit 1
    else
        print_status "✓ Docker permissions are correct"
        print_status "✓ Successfully connected to Docker daemon"
    fi
    
    echo ""
    print_status "✓ STEP 2 COMPLETE: DDEV and Docker ready"
    echo "============================================"
    echo ""
else
    print_skip "Skipping DDEV and Docker installation"
fi

# Step 3: Install and configure mkcert for HTTPS
if ! should_skip_step 3 && ask_step 3 "Install and configure mkcert for HTTPS"; then
    print_status "Setting up mkcert for local HTTPS..."

    if ! command -v mkcert &> /dev/null; then
        print_status "Installing mkcert..."
        
        # Install mkcert using the official installation method
        curl -fsSL https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64 -o mkcert
        chmod +x mkcert
        sudo mv mkcert /usr/local/bin/
        
        print_status "mkcert installed successfully"
    else
        print_skip "mkcert is already installed: $(mkcert -version)"
    fi

    # Check if CA is already installed
    if [ ! -d "$(mkcert -CAROOT)" ] || [ ! -f "$(mkcert -CAROOT)/rootCA.pem" ]; then
        print_status "Installing local CA certificates..."
        mkcert -install
        print_status "Local CA certificates installed at $(mkcert -CAROOT)"
    else
        print_skip "Local CA certificates already installed at $(mkcert -CAROOT)"
    fi

    # DDEV will automatically detect and use mkcert if it's installed
    print_status "DDEV will automatically use mkcert for HTTPS certificates"
else
    print_skip "Skipping mkcert installation and configuration"
fi

# Step 4: Create project directory
if ! should_skip_step 4 && ask_step 4 "Create project directory"; then
    if [ -d "$PROJECT_NAME" ]; then
        print_warning "Project directory '$PROJECT_NAME' already exists"
        
        # Check if it's a DDEV project
        if [ -f "$PROJECT_NAME/.ddev/config.yaml" ]; then
            # Check if the config file is corrupted
            if ! ddev describe >/dev/null 2>&1 && grep -q "already defined" "$PROJECT_NAME/.ddev/config.yaml" 2>/dev/null; then
                print_error "Detected corrupted DDEV configuration (duplicate keys in config.yaml)"
                echo "Options:"
                echo "  1) Fix configuration (remove duplicate keys)"
                echo "  2) Delete .ddev directory and reconfigure"
                echo "  3) Delete entire project and start fresh"
                echo "  4) Exit"
                read -p "Choose an option (1-4): " -n 1 -r
                echo
                
                case $REPLY in
                    1)
                        print_status "Attempting to fix configuration..."
                        cd "$PROJECT_NAME"
                        # Backup the corrupted config
                        cp .ddev/config.yaml .ddev/config.yaml.backup
                        # Remove lines after the first occurrence of duplicate keys
                        # This is a simple fix - removes everything after line 300
                        head -n 50 .ddev/config.yaml > .ddev/config.yaml.tmp
                        mv .ddev/config.yaml.tmp .ddev/config.yaml
                        print_status "Configuration fixed. Backup saved as config.yaml.backup"
                        ;;
                    2)
                        print_status "Removing .ddev directory..."
                        cd "$PROJECT_NAME"
                        rm -rf .ddev
                        print_status ".ddev directory removed. Will reconfigure."
                        ;;
                    3)
                        print_warning "This will DELETE all data in $PROJECT_NAME"
                        read -p "Are you absolutely sure? Type 'yes' to confirm: " confirmation
                        if [ "$confirmation" == "yes" ]; then
                            print_status "Deleting directory..."
                            rm -rf "$PROJECT_NAME"
                            print_status "Creating fresh project directory..."
                            mkdir -p "$PROJECT_NAME"
                            cd "$PROJECT_NAME"
                        else
                            print_error "Deletion cancelled. Exiting."
                            exit 1
                        fi
                        ;;
                    4)
                        print_status "Exiting..."
                        exit 0
                        ;;
                    *)
                        print_error "Invalid option. Exiting."
                        exit 1
                        ;;
                esac
            else
                print_status "This appears to be an existing DDEV project"
                
                # Detect which step failed or needs to be redone
                cd "$PROJECT_NAME"
                LAST_FAILED_STEP=""
                LAST_FAILED_STEP_NAME=""
                
                # Check various installation states
                if [ ! -f "composer.json" ]; then
                    LAST_FAILED_STEP="7"
                    LAST_FAILED_STEP_NAME="Install OpenSocial via Composer"
                elif ! ddev drush version >/dev/null 2>&1; then
                    LAST_FAILED_STEP="7"
                    LAST_FAILED_STEP_NAME="Install Drush"
                elif ! ddev drush status --fields=bootstrap 2>/dev/null | grep -q "Successful"; then
                    LAST_FAILED_STEP="8"
                    LAST_FAILED_STEP_NAME="Install Drupal/OpenSocial database"
                elif [ -f "html/sites/default/settings.php" ] && ! grep -q "file_private_path" html/sites/default/settings.php; then
                    LAST_FAILED_STEP="8"
                    LAST_FAILED_STEP_NAME="Configure private file path"
                elif ! ddev drush pml --status=enabled 2>/dev/null | grep -q "social_user"; then
                    LAST_FAILED_STEP="10"
                    LAST_FAILED_STEP_NAME="Enable recommended modules"
                fi
                
                cd ..
                
                echo "Options:"
                if [ -n "$LAST_FAILED_STEP" ]; then
                    echo "  1) Resume from last failed/incomplete step: Step $LAST_FAILED_STEP ($LAST_FAILED_STEP_NAME)"
                else
                    echo "  1) Continue with existing project (resume installation)"
                fi
                echo "  2) Delete and start fresh"
                echo "  3) Choose a different project name"
                echo "  4) Exit"
                read -p "Choose an option (1-4): " -n 1 -r
                echo
                
                case $REPLY in
                    1)
                        if [ -n "$LAST_FAILED_STEP" ]; then
                            print_status "Resuming from Step $LAST_FAILED_STEP: $LAST_FAILED_STEP_NAME"
                            cd "$PROJECT_NAME"
                            # Add the failed step to skip list so we DON'T skip it
                            # but skip all steps before it
                            for ((i=1; i<$LAST_FAILED_STEP; i++)); do
                                SKIP_STEPS+=("$i")
                            done
                        else
                            print_status "Continuing with existing project..."
                            cd "$PROJECT_NAME"
                        fi
                        ;;
                    2)
                        print_warning "This will DELETE all data in $PROJECT_NAME"
                        read -p "Are you absolutely sure? Type 'yes' to confirm: " confirmation
                        if [ "$confirmation" == "yes" ]; then
                            print_status "Stopping DDEV if running..."
                            cd "$PROJECT_NAME"
                            ddev stop 2>/dev/null || true
                            ddev delete -O 2>/dev/null || true
                            cd ..
                            print_status "Deleting directory..."
                            rm -rf "$PROJECT_NAME"
                            print_status "Creating fresh project directory..."
                            mkdir -p "$PROJECT_NAME"
                            cd "$PROJECT_NAME"
                        else
                            print_error "Deletion cancelled. Exiting."
                            exit 1
                        fi
                        ;;
                    3)
                        read -p "Enter new project name: " NEW_PROJECT_NAME
                        if [ -z "$NEW_PROJECT_NAME" ]; then
                            print_error "Project name cannot be empty. Exiting."
                            exit 1
                        fi
                        PROJECT_NAME="$NEW_PROJECT_NAME"
                        print_status "Using new project name: $PROJECT_NAME"
                        if [ -d "$PROJECT_NAME" ]; then
                            print_error "Directory $PROJECT_NAME also exists. Please run the script again with a unique name."
                            exit 1
                        fi
                        mkdir -p "$PROJECT_NAME"
                        cd "$PROJECT_NAME"
                        ;;
                    4)
                        print_status "Exiting..."
                        exit 0
                        ;;
                    *)
                        print_error "Invalid option. Exiting."
                        exit 1
                        ;;
                esac
            fi
        else
            # Directory exists but is not a DDEV project
            print_warning "Directory exists but is not a DDEV project"
            echo "Options:"
            echo "  1) Use this directory (will initialize DDEV in it)"
            echo "  2) Delete directory and start fresh"
            echo "  3) Choose a different project name"
            echo "  4) Exit"
            read -p "Choose an option (1-4): " -n 1 -r
            echo
            
            case $REPLY in
                1)
                    print_status "Using existing directory..."
                    cd "$PROJECT_NAME"
                    ;;
                2)
                    print_warning "This will DELETE all data in $PROJECT_NAME"
                    read -p "Are you absolutely sure? Type 'yes' to confirm: " confirmation
                    if [ "$confirmation" == "yes" ]; then
                        print_status "Deleting directory..."
                        rm -rf "$PROJECT_NAME"
                        print_status "Creating fresh project directory..."
                        mkdir -p "$PROJECT_NAME"
                        cd "$PROJECT_NAME"
                    else
                        print_error "Deletion cancelled. Exiting."
                        exit 1
                    fi
                    ;;
                3)
                    read -p "Enter new project name: " NEW_PROJECT_NAME
                    if [ -z "$NEW_PROJECT_NAME" ]; then
                        print_error "Project name cannot be empty. Exiting."
                        exit 1
                    fi
                    PROJECT_NAME="$NEW_PROJECT_NAME"
                    print_status "Using new project name: $PROJECT_NAME"
                    if [ -d "$PROJECT_NAME" ]; then
                        print_error "Directory $PROJECT_NAME also exists. Please run the script again with a unique name."
                        exit 1
                    fi
                    mkdir -p "$PROJECT_NAME"
                    cd "$PROJECT_NAME"
                    ;;
                4)
                    print_status "Exiting..."
                    exit 0
                    ;;
                *)
                    print_error "Invalid option. Exiting."
                    exit 1
                    ;;
            esac
        fi
    else
        print_status "Creating project directory..."
        mkdir -p "$PROJECT_NAME"
        cd "$PROJECT_NAME"
        print_status "Project directory created: $PROJECT_NAME"
    fi
else
    print_skip "Skipping project directory creation"
    if [ -d "$PROJECT_NAME" ]; then
        cd "$PROJECT_NAME"
        print_status "Changed to existing directory: $PROJECT_NAME"
    else
        print_error "Project directory does not exist and step was skipped. Cannot continue."
        exit 1
    fi
fi

# Step 5: Initialize DDEV project
if ! should_skip_step 5 && ask_step 5 "Initialize DDEV project configuration"; then
    if [ -f ".ddev/config.yaml" ]; then
        print_skip "DDEV project is already configured (.ddev/config.yaml exists)"
        print_warning "If you want to reconfigure, delete .ddev directory first"
    else
        print_status "Initializing DDEV project..."
        ddev config --project-type=drupal \
            --docroot=html \
            --php-version=$PHP_VERSION \
            --database=mysql:$MYSQL_VERSION \
            --nodejs-version=$NODEJS_VERSION \
            --project-name="$PROJECT_NAME" \
            --create-docroot

        # Configure additional DDEV settings
        print_status "Configuring additional DDEV settings..."
        
        # Create a custom config file to avoid duplicating keys
        cat > .ddev/config.opensocial.yaml <<EOF
# OpenSocial custom configuration
# This file extends the main config.yaml

# Additional PHP packages
webimage_extra_packages: [php${PHP_VERSION}-gd, php${PHP_VERSION}-uploadprogress]

# Increase PHP memory limit for Drupal
php_memory_limit: 512M

# Hooks for composer
hooks:
  post-start:
    - exec: composer install --no-interaction || true
EOF
        print_status "DDEV project configured successfully"
    fi
else
    print_skip "Skipping DDEV project initialization"
fi

# Step 6: Start DDEV
if ! should_skip_step 6 && ask_step 6 "Start DDEV containers"; then
    step_header 6 "Start DDEV Containers"
    # Check if DDEV is already running
    if ddev describe >/dev/null 2>&1 && ddev status 2>&1 | grep -q "running"; then
        print_skip "DDEV is already running for this project"
    else
        print_status "Starting DDEV..."
        ddev start
        print_status "DDEV started successfully"
    fi
    step_complete 6 "DDEV is running"
else
    print_skip "Skipping DDEV start"
fi

# Step 7: Install Composer dependencies
if ! should_skip_step 7 && ask_step 7 "Install OpenSocial via Composer"; then
    if [ -f "composer.json" ]; then
        print_skip "composer.json already exists. Skipping composer create."
        print_status "Running composer install to ensure dependencies are up to date..."
        ddev composer install
    else
        print_status "Creating Composer project for OpenSocial..."
        
        # Use the correct OpenSocial template
        # For dev-master (latest development version)
        if [ "$OPENSOCIAL_VERSION" = "dev-master" ]; then
            print_status "Installing latest development version (dev-master)..."
            ddev composer create-project goalgorilla/social_template:dev-master . --no-interaction --stability dev
        else
            # For specific version tags (e.g., 12.4.13, 13.0.0-beta1)
            print_status "Installing version $OPENSOCIAL_VERSION..."
            ddev composer create-project goalgorilla/social_template:$OPENSOCIAL_VERSION . --no-interaction
        fi
        
        print_status "OpenSocial Composer project created successfully"
    fi
    
    # Ensure Drush is installed
    print_status "Checking for Drush..."
    if ! ddev drush version >/dev/null 2>&1; then
        print_status "Drush not found. Installing Drush..."
        ddev composer require drush/drush --dev
        print_status "Drush installed successfully"
    else
        print_skip "Drush is already installed"
    fi
    
    # Configure private file path BEFORE installation (required by OpenSocial)
    print_status "Configuring private file path (required by OpenSocial)..."
    
    # Create private directory if it doesn't exist
    if [ ! -d "../private" ]; then
        print_status "Creating private files directory..."
        mkdir -p ../private
        chmod 755 ../private
        print_status "Private directory created at ../private"
    else
        print_skip "Private directory already exists"
    fi
    
    # Create settings.php if it doesn't exist yet
    if [ ! -f "html/sites/default/settings.php" ] && [ -f "html/sites/default/default.settings.php" ]; then
        print_status "Creating settings.php from default.settings.php..."
        cp html/sites/default/default.settings.php html/sites/default/settings.php
        chmod 644 html/sites/default/settings.php
    fi
    
    # Add private file path to settings.php
    if [ -f "html/sites/default/settings.php" ]; then
        if ! grep -q "file_private_path" html/sites/default/settings.php; then
            print_status "Adding private file path to settings.php..."
            cat >> html/sites/default/settings.php <<'PRIVATEOF'

/**
 * Private file path configuration.
 * 
 * This directory should be outside the web root for security.
 * This is REQUIRED by OpenSocial distribution.
 */
$settings['file_private_path'] = '../private';
PRIVATEOF
            print_status "Private file path added to settings.php"
        else
            print_skip "Private file path already configured in settings.php"
        fi
        
        # Verify the configuration
        if grep -q "file_private_path.*private" html/sites/default/settings.php; then
            print_status "✓ Private file path is properly configured and ready for installation"
        else
            print_error "Failed to configure private file path. OpenSocial installation may fail."
        fi
    else
        print_warning "settings.php not found. It will be created during Drupal installation."
        print_warning "Private file path will be configured after installation."
    fi
else
    print_skip "Skipping Composer dependencies installation"
fi

# Step 8: Install Drupal/OpenSocial
if ! should_skip_step 8 && ask_step 8 "Install Drupal/OpenSocial database"; then
    # Check if Drupal is already installed
    if ddev drush status --fields=bootstrap 2>/dev/null | grep -q "Successful"; then
        print_skip "Drupal is already installed"
        print_warning "If you want to reinstall, run: ddev drush site:install social --yes"
    else
        # Get absolute path for better debugging
        CURRENT_DIR=$(pwd)
        print_status "Working directory: $CURRENT_DIR"
        
        # Ensure private directory exists before installation
        PRIVATE_DIR="../private"
        PRIVATE_ABS_PATH="$(cd .. && pwd)/private"
        if [ ! -d "$PRIVATE_DIR" ]; then
            print_status "Creating private files directory..."
            print_status "  Location: $PRIVATE_ABS_PATH"
            mkdir -p "$PRIVATE_DIR"
            chmod 775 "$PRIVATE_DIR"
            print_status "✓ Private directory created at: $PRIVATE_ABS_PATH"
        else
            print_skip "Private directory already exists at: $PRIVATE_ABS_PATH"
        fi
        
        # CRITICAL: Prepare settings.php BEFORE running site:install
        print_status "Preparing settings.php before installation..."
        
        SETTINGS_FILE="html/sites/default/settings.php"
        DEFAULT_SETTINGS="html/sites/default/default.settings.php"
        SETTINGS_ABS_PATH="$CURRENT_DIR/$SETTINGS_FILE"
        
        print_status "  Settings file: $SETTINGS_ABS_PATH"
        
        # Ensure default directory is writable
        chmod 755 html/sites/default
        
        # If settings.php doesn't exist, create it from default
        if [ ! -f "$SETTINGS_FILE" ]; then
            if [ -f "$DEFAULT_SETTINGS" ]; then
                print_status "Creating settings.php from default.settings.php..."
                print_status "  Source: $CURRENT_DIR/$DEFAULT_SETTINGS"
                print_status "  Target: $SETTINGS_ABS_PATH"
                cp "$DEFAULT_SETTINGS" "$SETTINGS_FILE"
                print_status "✓ Created settings.php"
            fi
        else
            print_skip "settings.php already exists at: $SETTINGS_ABS_PATH"
        fi
        
        # Make settings.php writable for installation
        chmod 666 "$SETTINGS_FILE"
        print_status "Set $SETTINGS_FILE to writable (666)"
        
        # Add private file path BEFORE installation (OpenSocial checks this during install)
        if ! grep -q "file_private_path" "$SETTINGS_FILE"; then
            print_status "Adding private file path to settings.php..."
            print_status "  File: $SETTINGS_ABS_PATH"
            print_status "  Adding: \$settings['file_private_path'] = '../private';"
            cat >> "$SETTINGS_FILE" <<'PRIVATEOF'

/**
 * Private file path configuration.
 * 
 * This directory should be outside the web root for security.
 * This is REQUIRED by OpenSocial distribution before installation.
 */
$settings['file_private_path'] = '../private';
PRIVATEOF
            print_status "✓ Private file path added to: $SETTINGS_ABS_PATH"
        else
            print_skip "Private file path already in: $SETTINGS_ABS_PATH"
        fi
        
        # Ensure settings.ddev.php will be included (DDEV creates this file)
        SETTINGS_DDEV="html/sites/default/settings.ddev.php"
        SETTINGS_DDEV_ABS="$CURRENT_DIR/$SETTINGS_DDEV"
        if ! grep -q "settings.ddev.php" "$SETTINGS_FILE"; then
            print_status "Adding settings.ddev.php inclusion..."
            print_status "  To file: $SETTINGS_ABS_PATH"
            print_status "  Will include: $SETTINGS_DDEV_ABS (auto-generated by DDEV)"
            cat >> "$SETTINGS_FILE" <<'DDEVEOF'

/**
 * Automatically generated include for settings managed by ddev.
 */
$ddev_settings = dirname(__FILE__) . '/settings.ddev.php';
if (getenv('IS_DDEV_PROJECT') == 'true' && is_readable($ddev_settings)) {
  require $ddev_settings;
}
DDEVEOF
            print_status "✓ settings.ddev.php inclusion added to: $SETTINGS_ABS_PATH"
        else
            print_skip "settings.ddev.php inclusion already in: $SETTINGS_ABS_PATH"
        fi
        
        print_status "Installing OpenSocial..."

        # Install using Drush
        # DDEV's settings.ddev.php will provide the database connection
        ddev drush site:install social \
            --account-name="$ADMIN_USER" \
            --account-pass="$ADMIN_PASS" \
            --account-mail="$ADMIN_MAIL" \
            --site-name="$SITE_NAME" \
            --site-mail="$SITE_MAIL" \
            --locale=en \
            --yes
        
        print_status "OpenSocial installed successfully"
        
        # Verify and fix settings.php after installation
        print_status "Verifying configuration after installation..."
        print_status "  Checking: $SETTINGS_ABS_PATH"
        
        # Ensure settings.php is writable for post-install configuration
        chmod 666 "$SETTINGS_FILE"
        
        # Re-check private file path (site:install might have modified settings.php)
        if ! grep -q "file_private_path" "$SETTINGS_FILE"; then
            print_warning "Private file path was removed during installation. Re-adding..."
            print_status "  Re-adding to: $SETTINGS_ABS_PATH"
            cat >> "$SETTINGS_FILE" <<'PRIVATEOF2'

/**
 * Private file path configuration.
 * 
 * This directory should be outside the web root for security.
 * This is REQUIRED by OpenSocial distribution.
 */
$settings['file_private_path'] = '../private';
PRIVATEOF2
            print_status "✓ Private file path re-added"
        fi
        
        # Re-check settings.ddev.php inclusion
        if ! grep -q "settings.ddev.php" "$SETTINGS_FILE"; then
            print_warning "settings.ddev.php inclusion was removed during installation. Re-adding..."
            print_status "  Re-adding to: $SETTINGS_ABS_PATH"
            cat >> "$SETTINGS_FILE" <<'DDEVEOF2'

/**
 * Automatically generated include for settings managed by ddev.
 */
$ddev_settings = dirname(__FILE__) . '/settings.ddev.php';
if (getenv('IS_DDEV_PROJECT') == 'true' && is_readable($ddev_settings)) {
  require $ddev_settings;
}
DDEVEOF2
            print_status "✓ settings.ddev.php inclusion re-added"
        fi
        
        # Ensure settings.local.php will be included
        SETTINGS_LOCAL="html/sites/default/settings.local.php"
        SETTINGS_LOCAL_ABS="$CURRENT_DIR/$SETTINGS_LOCAL"
        if ! grep -q "settings.local.php" "$SETTINGS_FILE"; then
            print_status "Adding settings.local.php inclusion..."
            print_status "  To file: $SETTINGS_ABS_PATH"
            print_status "  Will include: $SETTINGS_LOCAL_ABS (created in Step 13)"
            cat >> "$SETTINGS_FILE" <<'LOCALEOF'

/**
 * Load local development override configuration, if available.
 */
if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}
LOCALEOF
            print_status "✓ settings.local.php inclusion added to: $SETTINGS_ABS_PATH"
        else
            print_skip "settings.local.php inclusion already in: $SETTINGS_ABS_PATH"
        fi
        
        # Set proper permissions on settings.php (read-only for security)
        chmod 444 "$SETTINGS_FILE"
        chmod 755 html/sites/default
        print_status "Set proper permissions on: $SETTINGS_ABS_PATH (444 - read-only)"
        
        # Verify final configuration
        print_status "Final verification of: $SETTINGS_ABS_PATH"
        if grep -q "file_private_path" "$SETTINGS_FILE"; then
            print_status "  ✓ Private file path is configured"
        else
            print_error "  ✗ Private file path is missing!"
        fi
        
        if grep -q "settings.ddev.php" "$SETTINGS_FILE"; then
            print_status "  ✓ settings.ddev.php inclusion is configured"
        else
            print_error "  ✗ settings.ddev.php inclusion is missing!"
        fi
        
        if grep -q "settings.local.php" "$SETTINGS_FILE"; then
            print_status "  ✓ settings.local.php inclusion is configured"
        else
            print_error "  ✗ settings.local.php inclusion is missing!"
        fi
        
        # Clear cache to apply all settings
        print_status "Clearing cache to apply settings..."
        ddev drush cr
        
        print_status "=================="
        print_status "Configuration Summary:"
        print_status "=================="
        print_status "Settings file: $SETTINGS_ABS_PATH"
        print_status "Private directory: $PRIVATE_ABS_PATH"
        print_status "DDEV settings: $SETTINGS_DDEV_ABS (auto-created by DDEV)"
        print_status "Local settings: $SETTINGS_LOCAL_ABS (will be created in Step 13)"
        print_status "=================="
        print_status "✓ Installation and configuration complete"
    fi
else
    print_skip "Skipping Drupal/OpenSocial installation"
fi

# Step 9: Configure site settings
if ! should_skip_step 9 && ask_step 9 "Configure site settings"; then
    step_header 9 "Configure Site Settings"
    print_status "Configuring site settings..."

    # Set timezone
    print_status "Setting timezone to $SITE_TIMEZONE..."
    ddev drush config:set system.date timezone.default "$SITE_TIMEZONE" --yes 2>/dev/null || print_warning "Could not set timezone (may already be configured)"

    # Set date formats
    print_status "Configuring date settings..."
    ddev drush config:set system.date timezone.user.configurable 1 --yes 2>/dev/null || print_warning "Could not set user timezone configuration"

    # Configure file system settings
    print_status "Configuring file system paths..."
    ddev drush config:set system.file path.temporary "/tmp" --yes 2>/dev/null || print_warning "Could not set temporary path"

    # Enable clean URLs (should be default, but making sure)
    print_status "Configuring performance settings..."
    ddev drush config:set system.performance css.preprocess 1 --yes 2>/dev/null || print_warning "Could not set CSS preprocessing"
    ddev drush config:set system.performance js.preprocess 1 --yes 2>/dev/null || print_warning "Could not set JS preprocessing"

    # Configure error logging (development settings)
    print_status "Configuring error logging..."
    ddev drush config:set system.logging error_level verbose --yes 2>/dev/null || print_warning "Could not set error level"

    # Note: automated_cron.settings doesn't exist in OpenSocial by default
    # Cron is configured through DDEV or system cron instead
    
    step_complete 9 "Site settings configured"
else
    print_skip "Skipping site settings configuration"
fi

# Step 10: Enable recommended modules
if ! should_skip_step 10 && ask_step 10 "Enable recommended OpenSocial modules"; then
    print_status "Enabling recommended OpenSocial modules..."

    # Core social modules (most should already be enabled, but ensuring)
    ddev drush en -y \
        social_user \
        social_profile \
        social_group \
        social_event \
        social_topic \
        social_search \
        social_comment \
        social_like \
        social_follow_content \
        social_tagging 2>/dev/null || print_warning "Some modules may already be enabled"

    # Enable additional useful modules
    ddev drush en -y \
        admin_toolbar \
        admin_toolbar_tools \
        pathauto 2>/dev/null || print_warning "Some modules may already be enabled"

    print_status "Setting up default permissions..."

    # Set reasonable file upload limits
    ddev drush config:set system.file allow_insecure_uploads false --yes
    
    print_status "Recommended modules enabled successfully"
else
    print_skip "Skipping module enablement"
fi

# Step 11: Set up default content settings
if ! should_skip_step 11 && ask_step 11 "Configure user and content settings"; then
    print_status "Configuring content settings..."

    # Enable user registration with admin approval (more secure default)
    ddev drush config:set user.settings register visitors_admin_approval --yes

    # Configure user email verification
    ddev drush config:set user.settings verify_mail 1 --yes

    # Set default user picture
    ddev drush config:set user.settings anonymous "Anonymous" --yes
    
    print_status "Content settings configured successfully"
else
    print_skip "Skipping content settings configuration"
fi

# Step 12: Clear cache and rebuild
if ! should_skip_step 12 && ask_step 12 "Clear cache and rebuild permissions"; then
    print_status "Clearing Drupal cache and rebuilding..."
    ddev drush cr

    # Rebuild node access permissions
    print_status "Rebuilding node access permissions..."
    ddev drush php-eval "node_access_rebuild();" 2>/dev/null || print_warning "Node access rebuild may have failed (this is OK if no content exists yet)"
    
    print_status "Cache cleared and permissions rebuilt successfully"
else
    print_skip "Skipping cache clear and rebuild"
fi

# Step 13: Set up development settings (optional)
if ! should_skip_step 13 && ask_step 13 "Set up development settings (settings.local.php)"; then
    print_status "Setting up development-friendly settings..."
    
    CURRENT_DIR=$(pwd)
    PRIVATE_DIR="../private"
    PRIVATE_ABS_PATH="$(cd .. && pwd)/private"
    SETTINGS_FILE="html/sites/default/settings.php"
    SETTINGS_LOCAL="html/sites/default/settings.local.php"
    SETTINGS_ABS_PATH="$CURRENT_DIR/$SETTINGS_FILE"
    SETTINGS_LOCAL_ABS="$CURRENT_DIR/$SETTINGS_LOCAL"

    # Verify private directory exists (should have been created in Step 7)
    if [ ! -d "$PRIVATE_DIR" ]; then
        print_warning "Private directory not found. Creating it now..."
        print_status "  Location: $PRIVATE_ABS_PATH"
        mkdir -p "$PRIVATE_DIR"
        chmod 755 "$PRIVATE_DIR"
        print_status "✓ Private directory created at: $PRIVATE_ABS_PATH"
    else
        print_skip "Private directory already exists at: $PRIVATE_ABS_PATH"
    fi

    # Verify private file path in settings.php (should have been added in Step 8)
    if [ -f "$SETTINGS_FILE" ]; then
        if ! grep -q "file_private_path" "$SETTINGS_FILE"; then
            print_warning "Private file path not found in settings.php. Adding it now..."
            print_status "  File: $SETTINGS_ABS_PATH"
            chmod 644 "$SETTINGS_FILE"
            cat >> "$SETTINGS_FILE" <<'PRIVATEOF'

/**
 * Private file path configuration.
 * 
 * This directory should be outside the web root for security.
 * This is REQUIRED by OpenSocial distribution.
 */
$settings['file_private_path'] = '../private';
PRIVATEOF
            chmod 444 "$SETTINGS_FILE"
            print_status "✓ Private file path added to: $SETTINGS_ABS_PATH"
        else
            print_skip "Private file path already configured in: $SETTINGS_ABS_PATH"
        fi
    else
        print_warning "Settings file not found at: $SETTINGS_ABS_PATH"
    fi

    # Create settings.local.php for development
    if [ -f "$SETTINGS_LOCAL" ]; then
        print_skip "settings.local.php already exists at: $SETTINGS_LOCAL_ABS"
    else
        print_status "Creating settings.local.php for development..."
        print_status "  Location: $SETTINGS_LOCAL_ABS"
        cat > "$SETTINGS_LOCAL" <<'LOCALEOF'
<?php

/**
 * Development settings for OpenSocial.
 */

// Disable CSS and JS aggregation.
$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;

// Disable the render cache.
$settings['cache']['bins']['render'] = 'cache.backend.null';

// Disable Dynamic Page Cache.
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';

// Allow test modules and themes.
$settings['extension_discovery_scan_tests'] = TRUE;

// Enable access to rebuild.php.
$settings['rebuild_access'] = TRUE;

// Skip file system permissions hardening.
$settings['skip_permissions_hardening'] = TRUE;

// Show all error messages.
$config['system.logging']['error_level'] = 'verbose';

// Disable CSS and JS preprocessing.
$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;
LOCALEOF

        print_status "✓ Created settings.local.php at: $SETTINGS_LOCAL_ABS"
    fi

    # Ensure settings.php includes settings.local.php
    if [ -f "$SETTINGS_FILE" ]; then
        if ! grep -q "settings.local.php" "$SETTINGS_FILE" 2>/dev/null; then
            print_status "Adding settings.local.php inclusion to settings.php..."
            print_status "  Main file: $SETTINGS_ABS_PATH"
            print_status "  Will include: $SETTINGS_LOCAL_ABS"
            chmod 644 "$SETTINGS_FILE"
            cat >> "$SETTINGS_FILE" <<'SETTINGSEOF'

/**
 * Load local development override configuration, if available.
 */
if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}
SETTINGSEOF
            chmod 444 "$SETTINGS_FILE"
            print_status "✓ settings.local.php inclusion added to: $SETTINGS_ABS_PATH"
        else
            print_skip "settings.local.php inclusion already in: $SETTINGS_ABS_PATH"
        fi
    fi
    
    # Final verification of private file path
    print_status "Final verification..."
    if [ -f "$SETTINGS_FILE" ] && grep -q "file_private_path.*private" "$SETTINGS_FILE"; then
        print_status "  ✓ Private file path is properly configured in: $SETTINGS_ABS_PATH"
    else
        print_error "  ✗ Private file path is not properly configured!"
        print_error "     File: $SETTINGS_ABS_PATH"
        print_error "     Please add: \$settings['file_private_path'] = '../private';"
    fi
    
    print_status "=================="
    print_status "Development Settings Summary:"
    print_status "=================="
    print_status "Settings file: $SETTINGS_ABS_PATH"
    print_status "Local settings: $SETTINGS_LOCAL_ABS"
    print_status "Private directory: $PRIVATE_ABS_PATH"
    print_status "=================="
else
    print_skip "Skipping development settings setup"
fi

# Step 14: Display completion information
print_status "=================================="
print_status "OpenSocial installation complete!"
print_status "=================================="
echo ""
print_status "Project URL: https://$PROJECT_NAME.ddev.site"
print_status "Admin username: $ADMIN_USER"
print_status "Admin password: $ADMIN_PASS"
print_status "Admin email: $ADMIN_MAIL"
echo ""
print_status "Site Configuration:"
echo "  Site name: $SITE_NAME"
echo "  Timezone: $SITE_TIMEZONE"
echo "  PHP version: $PHP_VERSION"
echo "  MySQL version: $MYSQL_VERSION"
echo "  Node.js version: $NODEJS_VERSION"
echo ""
print_status "Installed Features:"
echo "  ✓ Core OpenSocial modules"
echo "  ✓ Admin Toolbar with tools"
echo "  ✓ Pathauto for clean URLs"
echo "  ✓ Development settings configured"
echo "  ✓ User registration (admin approval required)"
echo "  ✓ Email verification enabled"
echo ""
print_status "Useful DDEV commands:"
echo "  ddev start          - Start the project"
echo "  ddev stop           - Stop the project"
echo "  ddev restart        - Restart the project"
echo "  ddev ssh            - SSH into web container"
echo "  ddev drush          - Run Drush commands"
echo "  ddev composer       - Run Composer commands"
echo "  ddev describe       - Show project information"
echo "  ddev logs           - View container logs"
echo "  ddev exec npm       - Run npm commands"
echo ""
print_status "Common Drush commands:"
echo "  ddev drush cr       - Clear cache"
echo "  ddev drush uli      - Generate one-time login link"
echo "  ddev drush status   - Show site status"
echo "  ddev drush pml      - List installed modules"
echo ""
print_status "To access your site, run:"
echo "  ddev launch"
echo ""
print_status "To log in as admin without password:"
echo "  ddev drush uli"
echo ""
print_warning "IMPORTANT SECURITY REMINDERS:"
echo "  1. Change the admin password after first login!"
echo "  2. Update the site email in admin/config/system/site-information"
echo "  3. Review user permissions at admin/people/permissions"
echo "  4. For production, disable development settings in settings.local.php"

# Optional: Launch the site in browser
read -p "Do you want to launch the site in your browser now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ddev launch
fi

print_status "Installation script completed successfully!"
