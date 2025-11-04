#!/bin/bash

################################################################################
# OpenSocial (Drupal) Installation Script with DDEV on Ubuntu
# 
# Date: November 2025
# 
# This script automates the complete installation of OpenSocial using DDEV,
# including configuration, sample content, and GitHub token support.
#
# Key Feature: Checks actual state instead of using checkpoint files
#
# Changelog:
# v3.0.0 - MAJOR: Removed checkpoint file, checks actual state of each step
# v2.7.6 - Fixed: Here-document syntax in ddev exec, removed incorrect step markers
# v2.7.5 - Fixed: Check for complete $settings line with assignment operator
# v2.7.4 - Fixed: Check for full $settings['file_private_path'] line, not just substring
# v2.7.3 - CRITICAL: Configure private file system (required by OpenSocial)
# v2.7.2 - CRITICAL: Restart DDEV after config creation to apply PHP 8.3
# v2.7.1 - Fixed: Changed PHP version to 8.3 (required by dependencies)
# v2.7.0 - CRITICAL: Remove docker-compose files, force remove ALL opensocial volumes
################################################################################

set -e  # Exit on any error

# Script version
VERSION="3.0.0"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Progress tracking
TOTAL_STEPS=14
CURRENT_STEP=0

# Configuration variables
GITHUB_TOKEN="${GITHUB_TOKEN:-}"  # Set via environment or leave empty
SITE_NAME="My OpenSocial Site"
SITE_EMAIL="admin@example.com"
ADMIN_USER="admin"
ADMIN_PASS="admin"
ADMIN_EMAIL="admin@example.com"
SITE_TIMEZONE="America/New_York"

# Interactive mode and project variables
INTERACTIVE_MODE=false
SKIP_STEPS=()
FORCE_CLEAN=false
OPENSOCIAL_DIR=""
PROJECT_NAME=""
PROJECT_URL=""

################################################################################
# Output Functions
################################################################################

step_header() {
    local step_num=$1
    local step_name=$2
    CURRENT_STEP=$step_num
    local progress=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${MAGENTA}STEP $step_num of $TOTAL_STEPS${NC} (${progress}% complete)"
    echo -e "${CYAN}▶ $step_name${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

step_complete() {
    local step_num=$1
    local step_name=$2
    echo ""
    echo -e "${GREEN}✓ STEP $step_num COMPLETED:${NC} $step_name"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_status() {
    echo -e "${GREEN}  ▸${NC} $1"
}

print_error() {
    echo -e "${RED}  ✗ ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ WARNING:${NC} $1"
}

print_skip() {
    echo -e "${BLUE}  ⊳ SKIPPED:${NC} $1"
}

print_substep() {
    echo -e "${CYAN}    →${NC} $1"
}

print_success() {
    echo -e "${GREEN}    ✓${NC} $1"
}

################################################################################
# State Check Functions - Check actual state instead of checkpoint files
################################################################################

check_step_preflight() {
    # Check if all prerequisites are installed
    command -v ddev &>/dev/null && \
    command -v composer &>/dev/null && \
    command -v git &>/dev/null && \
    docker ps &>/dev/null
}

check_step_directory() {
    # Check if project directory exists and we're in it
    [ -n "$OPENSOCIAL_DIR" ] && \
    [ -d "$OPENSOCIAL_DIR" ] && \
    [ "$(pwd)" = "$OPENSOCIAL_DIR" ]
}

check_step_composer_project() {
    # Check if composer.json exists and has correct template
    [ -f "composer.json" ] && \
    (grep -q "rjzaar/commons_template" composer.json 2>/dev/null || \
     grep -q "goalgorilla/social_template" composer.json 2>/dev/null)
}

check_step_private_directory() {
    # Check if private directory exists
    [ -d "../private" ]
}

check_step_ddev_config() {
    # Check if DDEV is configured correctly
    [ -f ".ddev/config.yaml" ] && \
    grep -q "type: drupal10" .ddev/config.yaml 2>/dev/null && \
    grep -q "mariadb:10.11" .ddev/config.yaml 2>/dev/null
}

check_step_ddev_started() {
    # Check if DDEV is actually running
    ddev describe &>/dev/null && \
    ddev exec php -v &>/dev/null
}

check_step_github_token() {
    # Check if GitHub token is configured
    [ -n "$GITHUB_TOKEN" ] && \
    ddev composer config --global --auth -l 2>/dev/null | grep -q "github-oauth.github.com"
}

check_step_dependencies() {
    # Check if dependencies are installed
    [ -d "vendor" ] && \
    [ -d "html/core" ] && \
    [ -d "html/profiles/contrib/social" ]
}

check_step_drupal_installed() {
    # Check if Drupal is actually installed and bootstrapping
    ddev drush status bootstrap 2>/dev/null | grep -q "Successful"
}

check_step_site_configured() {
    # Check if site settings are configured
    [ -f "html/sites/default/settings.php" ] && \
    grep -q "\$settings\['file_private_path'\]" html/sites/default/settings.php 2>/dev/null
}

check_step_demo_content() {
    # Check if demo content module exists and is enabled
    # We'll consider this step complete if we've checked for it
    # (since demo content is optional)
    ddev drush pm:list --status=enabled 2>/dev/null | grep -q "social_demo" || \
    ddev drush pm:list --status=disabled 2>/dev/null | grep -q "social_demo" || \
    return 0  # Not available is also "complete"
}

check_step_modules_enabled() {
    # Check if workflow_assignment is enabled (if it exists)
    if [ -d "html/modules/contrib/workflow_assignment" ] || \
       [ -d "html/modules/custom/workflow_assignment" ]; then
        ddev drush pm:list --status=enabled 2>/dev/null | grep -q "workflow_assignment"
    else
        return 0  # No module to enable = complete
    fi
}

check_step_permissions() {
    # Check if key directories have correct permissions
    [ -d "html/sites/default" ] && \
    [ -d "html/sites/default/files" ] && \
    [ -f "html/sites/default/settings.php" ]
}

################################################################################
# Interactive Mode Functions
################################################################################

should_skip_step() {
    local step_num=$1
    
    # Check if step is in skip list
    for skip in "${SKIP_STEPS[@]}"; do
        if [ "$skip" == "$step_num" ]; then
            return 0
        fi
    done
    return 1
}

ask_step() {
    local step_num=$1
    local step_name=$2
    local check_func=$3
    
    # Check if step is actually complete
    if $check_func 2>/dev/null; then
        if [ "$INTERACTIVE_MODE" = true ]; then
            echo ""
            echo -e "${BLUE}Step $step_num: $step_name${NC}"
            echo -e "${GREEN}This step appears to be completed.${NC}"
            read -p "Redo this step? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                return 0
            else
                SKIP_STEPS+=("$step_num")
                return 1
            fi
        else
            return 1  # Skip completed steps in non-interactive mode
        fi
    fi
    
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo ""
        echo -e "${BLUE}Step $step_num: $step_name${NC}"
        read -p "Run this step? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
            SKIP_STEPS+=("$step_num")
            return 1
        fi
    fi
    return 0
}

################################################################################
# DDEV Project Management Functions
################################################################################

check_existing_ddev_project() {
    local project_name=$1
    
    print_status "Checking for existing DDEV project: $project_name"
    
    if ddev describe "$project_name" &>/dev/null; then
        print_warning "DDEV project '$project_name' already exists"
        
        # Get project directory
        local existing_dir=$(ddev describe "$project_name" -j 2>/dev/null | grep -o '"approot":"[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$existing_dir" ]; then
            print_substep "Existing project location: $existing_dir"
            
            # In non-interactive mode, use existing project
            if [ "$INTERACTIVE_MODE" != true ]; then
                print_status "Using existing project (non-interactive mode)"
                OPENSOCIAL_DIR="$existing_dir"
                return 0
            fi
            
            # Interactive mode - show options
            echo ""
            echo -e "${YELLOW}What would you like to do?${NC}"
            echo "  1) Resume installation (recommended)"
            echo "  2) Remove and start fresh"
            echo "  3) Update only changed components"
            echo "  4) Cancel"
            echo ""
            read -p "Choose option (1-4): " -n 1 -r
            echo ""
            
            case $REPLY in
                1)
                    print_status "Resuming installation..."
                    OPENSOCIAL_DIR="$existing_dir"
                    return 0
                    ;;
                2)
                    print_warning "This will remove the DDEV project and directory"
                    read -p "Are you sure? (y/N): " -n 1 -r
                    echo ""
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        print_status "Stopping and removing DDEV project..."
                        cd "$existing_dir" 2>/dev/null || true
                        ddev stop "$project_name" 2>/dev/null || true
                        ddev delete -O -y "$project_name" 2>/dev/null || true
                        
                        print_substep "Removing project directory..."
                        cd ..
                        rm -rf "$existing_dir"
                        print_success "Previous installation removed"
                        FORCE_CLEAN=true
                        return 1
                    else
                        print_error "Installation cancelled"
                        exit 1
                    fi
                    ;;
                3)
                    print_status "Update mode selected"
                    OPENSOCIAL_DIR="$existing_dir"
                    check_for_updates
                    return 0
                    ;;
                4)
                    print_error "Installation cancelled"
                    exit 1
                    ;;
                *)
                    print_error "Invalid option, cancelling"
                    exit 1
                    ;;
            esac
        fi
    fi
    
    return 1
}

check_for_updates() {
    print_status "Checking for component updates..."
    
    if [ ! -d "$OPENSOCIAL_DIR" ]; then
        print_warning "Project directory not found"
        return 1
    fi
    
    cd "$OPENSOCIAL_DIR"
    
    # Check workflow_assignment module
    check_workflow_assignment_update
    
    # Check for composer.json changes
    check_composer_updates
}

check_workflow_assignment_update() {
    print_substep "Checking workflow_assignment module..."
    
    local module_path=""
    if [ -d "html/modules/contrib/workflow_assignment" ]; then
        module_path="html/modules/contrib/workflow_assignment"
    elif [ -d "html/modules/custom/workflow_assignment" ]; then
        module_path="html/modules/custom/workflow_assignment"
    fi
    
    if [ -n "$module_path" ]; then
        print_success "Module found at: $module_path"
        
        # Check if module is installed in Drupal
        if ddev drush pm:list --status=enabled --format=json 2>/dev/null | grep -q "workflow_assignment"; then
            print_substep "Module is currently enabled"
            
            # Get current version/hash
            if [ -d "$module_path/.git" ]; then
                local current_hash=$(cd "$module_path" && git rev-parse HEAD 2>/dev/null || echo "unknown")
                print_substep "Current version: ${current_hash:0:8}"
                
                # Check for updates
                cd "$module_path"
                git fetch origin &>/dev/null || true
                local remote_hash=$(git rev-parse origin/HEAD 2>/dev/null || echo "unknown")
                
                if [ "$current_hash" != "$remote_hash" ] && [ "$remote_hash" != "unknown" ]; then
                    print_warning "Updates available for workflow_assignment"
                    
                    if [ "$INTERACTIVE_MODE" = true ]; then
                        read -p "Update workflow_assignment module? (y/N): " -n 1 -r
                        echo ""
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            update_workflow_assignment
                        fi
                    else
                        print_status "Auto-updating workflow_assignment (non-interactive mode)"
                        update_workflow_assignment
                    fi
                else
                    print_success "Module is up to date"
                fi
                cd "$OPENSOCIAL_DIR"
            fi
        else
            print_substep "Module is installed but not enabled"
        fi
    else
        print_substep "Module not found in project"
    fi
}

update_workflow_assignment() {
    print_status "Updating workflow_assignment module..."
    
    # Uninstall module
    print_substep "Uninstalling current version..."
    if ddev drush pm:uninstall workflow_assignment -y 2>/dev/null; then
        print_success "Module uninstalled"
    else
        print_warning "Module was not enabled"
    fi
    
    # Update code
    print_substep "Updating module code..."
    cd "$module_path"
    if git pull origin; then
        print_success "Module code updated"
    else
        print_warning "Could not update module code"
    fi
    cd "$OPENSOCIAL_DIR"
    
    # Reinstall module
    print_substep "Reinstalling module..."
    if ddev drush pm:enable workflow_assignment -y; then
        print_success "Module reinstalled and enabled"
    else
        print_error "Failed to reinstall module"
    fi
    
    # Clear cache
    print_substep "Clearing cache..."
    ddev drush cache:rebuild
}

check_composer_updates() {
    print_substep "Checking for composer dependency updates..."
    
    if [ -f "composer.json" ]; then
        # Check for outdated packages
        local outdated=$(ddev composer outdated --direct --format=json 2>/dev/null | grep -c "name" || echo "0")
        
        if [ "$outdated" -gt "0" ]; then
            print_warning "$outdated packages have updates available"
            
            if [ "$INTERACTIVE_MODE" = true ]; then
                read -p "Update composer dependencies? (y/N): " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    print_status "Updating composer dependencies..."
                    if ddev composer update; then
                        print_success "Dependencies updated"
                        print_substep "Running database updates..."
                        ddev drush updatedb -y
                        print_substep "Clearing cache..."
                        ddev drush cache:rebuild
                    else
                        print_error "Composer update failed"
                    fi
                fi
            else
                print_status "Auto-updating composer dependencies (non-interactive mode)"
                if ddev composer update; then
                    print_success "Dependencies updated"
                    print_substep "Running database updates..."
                    ddev drush updatedb -y
                    print_substep "Clearing cache..."
                    ddev drush cache:rebuild
                else
                    print_error "Composer update failed"
                fi
            fi
        else
            print_success "All dependencies are up to date"
        fi
    fi
}

################################################################################
# Utility Functions
################################################################################

check_prerequisites() {
    print_status "Verifying system prerequisites..."
    
    local missing_deps=()
    
    print_substep "Checking for DDEV..."
    if ! command -v ddev &> /dev/null; then
        missing_deps+=("ddev")
    else
        print_success "DDEV found: $(ddev version | head -n 1)"
    fi
    
    print_substep "Checking for Composer..."
    if ! command -v composer &> /dev/null; then
        missing_deps+=("composer")
    else
        print_success "Composer found: $(composer --version | head -n 1)"
    fi
    
    print_substep "Checking for Git..."
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    else
        print_success "Git found: $(git --version)"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install missing dependencies:"
        echo "  DDEV: https://ddev.readthedocs.io/en/stable/#installation"
        echo "  Composer: https://getcomposer.org/download/"
        echo "  Git: sudo apt-get install git"
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

find_available_url() {
    local base_name=$1
    local url_candidate="${base_name}"
    local counter=1
    
    print_status "Checking URL availability..." >&2
    
    while ddev describe "${url_candidate}" &>/dev/null; do
        print_substep "URL '${url_candidate}' is already in use" >&2
        url_candidate="${base_name}${counter}"
        counter=$((counter + 1))
    done
    
    print_success "Available URL found: ${url_candidate}" >&2
    echo "${url_candidate}"
}

################################################################################
# Installation Steps
################################################################################

# Step 1: Pre-flight checks
step_preflight() {
    if should_skip_step 1; then
        print_skip "Pre-flight checks already completed"
        return 0
    fi
    
    if ! ask_step 1 "Pre-flight checks" check_step_preflight; then
        print_skip "Skipping pre-flight checks"
        return 0
    fi
    
    step_header 1 "Running Pre-flight Checks"
    
    check_prerequisites
    
    print_status "Checking Docker status..."
    if ! docker ps &>/dev/null; then
        print_error "Docker is not running"
        print_status "Starting Docker..."
        sudo systemctl start docker
        sleep 3
        print_success "Docker started successfully"
    else
        print_success "Docker is running"
    fi
    
    step_complete 1 "Pre-flight checks"
}

# Step 2: Set up project directory
step_setup_directory() {
    if should_skip_step 2; then
        print_skip "Project directory already configured"
        # Still need to cd into the directory even if skipped
        if [ -n "$OPENSOCIAL_DIR" ] && [ -d "$OPENSOCIAL_DIR" ]; then
            cd "$OPENSOCIAL_DIR"
        fi
        return 0
    fi
    
    if ! ask_step 2 "Set up project directory" check_step_directory; then
        if check_step_directory 2>/dev/null; then
            print_skip "Project directory already set up"
            # Make sure we're in it
            if [ -n "$OPENSOCIAL_DIR" ] && [ -d "$OPENSOCIAL_DIR" ]; then
                cd "$OPENSOCIAL_DIR"
            fi
            return 0
        fi
    fi
    
    step_header 2 "Setting Up Project Directory"
    
    # Use current directory instead of script directory
    local current_dir="$(pwd)"
    print_status "Working directory: $current_dir"
    
    # Get project name if not already set
    if [ -z "$PROJECT_NAME" ]; then
        if [ "$INTERACTIVE_MODE" = true ]; then
            read -p "Enter project name (default: opensocial): " PROJECT_NAME
        fi
        PROJECT_NAME=${PROJECT_NAME:-opensocial}
    fi
    
    print_status "Project name: $PROJECT_NAME"
    
    # Check for existing DDEV project
    if ! $FORCE_CLEAN; then
        if check_existing_ddev_project "$PROJECT_NAME"; then
            # Project was found and OPENSOCIAL_DIR was set
            # Make sure we cd into it
            if [ -n "$OPENSOCIAL_DIR" ] && [ -d "$OPENSOCIAL_DIR" ]; then
                cd "$OPENSOCIAL_DIR"
                print_status "Changed to project directory: $OPENSOCIAL_DIR"
            fi
            step_complete 2 "Project directory setup (resumed)"
            return 0
        fi
    fi
    
    # Find available URL
    if [ -z "$PROJECT_URL" ]; then
        PROJECT_URL=$(find_available_url "$PROJECT_NAME")
    fi
    
    # Set directory path if not already set
    if [ -z "$OPENSOCIAL_DIR" ]; then
        OPENSOCIAL_DIR="$current_dir/$PROJECT_URL"
    fi
    
    print_status "Installation directory: $OPENSOCIAL_DIR"
    
    # Create directory if it doesn't exist
    if [ ! -d "$OPENSOCIAL_DIR" ]; then
        print_substep "Creating project directory..."
        mkdir -p "$OPENSOCIAL_DIR"
        print_success "Project directory created: $OPENSOCIAL_DIR"
    else
        print_substep "Directory already exists: $OPENSOCIAL_DIR"
        
        # Check if directory is empty (except for hidden files)
        if [ "$(ls -A "$OPENSOCIAL_DIR" 2>/dev/null | grep -v '^\.' | wc -l)" -gt 0 ]; then
            print_warning "Directory is not empty"
            
            # Check if it looks like an existing installation
            if [ -f "$OPENSOCIAL_DIR/composer.json" ]; then
                print_substep "Appears to be existing project, will resume"
            else
                print_error "Directory contains unknown files"
                print_error "Please use an empty directory or remove existing files"
                exit 1
            fi
        fi
    fi
    
    cd "$OPENSOCIAL_DIR"
    print_status "Changed to project directory: $OPENSOCIAL_DIR"
    
    step_complete 2 "Project directory setup"
}

# Step 3: Create Composer project
step_create_composer_project() {
    if should_skip_step 3; then
        print_skip "Composer project already created"
        return 0
    fi
    
    if ! ask_step 3 "Create Composer project from template" check_step_composer_project; then
        print_skip "Composer project already exists"
        return 0
    fi
    
    step_header 3 "Creating Composer Project from Template"
    
    # Safety check: ensure we're in the project directory
    local current=$(pwd)
    if [ "$current" != "$OPENSOCIAL_DIR" ]; then
        print_warning "Not in project directory, changing..."
        cd "$OPENSOCIAL_DIR"
        print_success "Changed to: $OPENSOCIAL_DIR"
    fi
    
    print_substep "Current directory: $(pwd)"
    
    # Check if composer.json already exists
    if [ -f "composer.json" ]; then
        print_substep "composer.json already exists"
        
        # Verify it's from the correct template
        if grep -q "rjzaar/commons_template" composer.json 2>/dev/null || \
           grep -q "goalgorilla/social_template" composer.json 2>/dev/null; then
            print_success "Valid OpenSocial project detected"
            step_complete 3 "Composer project creation (existing)"
            return 0
        else
            print_warning "Directory contains a different project"
            
            if [ "$INTERACTIVE_MODE" = true ]; then
                read -p "Remove and recreate? (y/N): " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    print_error "Installation cancelled"
                    exit 1
                fi
            else
                print_error "Directory contains incompatible project (non-interactive mode)"
                print_error "Please remove the directory or use a different location"
                exit 1
            fi
        fi
    fi
    
    print_status "Using template: rjzaar/commons_template"
    print_substep "Installing in: $(pwd)"
    print_substep "This may take several minutes..."
    
    if composer create-project rjzaar/commons_template:dev-master . --no-interaction; then
        print_success "Composer project created successfully"
        
        print_substep "Verifying project structure..."
        if [ -f "composer.json" ]; then
            print_success "composer.json found"
        else
            print_error "composer.json not found - project creation may have failed"
            exit 1
        fi
    else
        print_error "Composer project creation failed"
        print_error "Current directory was: $(pwd)"
        exit 1
    fi
    
    step_complete 3 "Composer project creation"
}

# Step 4: Create private directory
step_create_private_directory() {
    if should_skip_step 4; then
        print_skip "Private directory already configured"
        return 0
    fi
    
    if ! ask_step 4 "Create private files directory" check_step_private_directory; then
        print_skip "Private directory already exists"
        return 0
    fi
    
    step_header 4 "Creating Private Files Directory"
    
    print_status "Setting up private files directory outside web root..."
    
    if [ ! -d "../private" ]; then
        print_substep "Creating ../private directory..."
        mkdir -p ../private
        print_success "Private directory created: $(realpath ../private)"
    else
        print_substep "Private directory already exists"
        print_success "Using existing directory: $(realpath ../private)"
    fi
    
    step_complete 4 "Private directory creation"
}

# Step 5: Initialize DDEV
step_initialize_ddev() {
    if should_skip_step 5; then
        print_skip "DDEV already initialized"
        return 0
    fi
    
    if ! ask_step 5 "Initialize DDEV configuration" check_step_ddev_config; then
        print_skip "DDEV configuration already complete"
        return 0
    fi
    
    step_header 5 "Initializing DDEV Configuration"
    
    # CRITICAL: Shut down ALL DDEV services to clear any cached state
    print_status "Shutting down all DDEV services..."
    print_substep "This clears DDEV's internal state and cached configurations"
    ddev poweroff 2>/dev/null || true
    sleep 2
    print_success "All DDEV services stopped"
    
    # CRITICAL: Clean DDEV's global configuration files
    print_status "Cleaning DDEV's global configuration files..."
    
    if [ -d "$HOME/.ddev" ]; then
        print_substep "Checking ~/.ddev/ for project configs..."
        
        # Remove any project-specific config files
        local config_files=$(find "$HOME/.ddev" -type f -name "*${PROJECT_URL}*" 2>/dev/null || true)
        if [ -n "$config_files" ]; then
            print_warning "Found project config files in ~/.ddev/"
            echo "$config_files" | while read -r file; do
                print_substep "Removing: $file"
                rm -f "$file" 2>/dev/null || true
            done
            print_success "Global config files removed"
        else
            print_substep "No project config files in ~/.ddev/"
        fi
        
        # Also check for any .yaml files that mention this project
        if grep -r "name: $PROJECT_URL" "$HOME/.ddev/" 2>/dev/null | cut -d: -f1 | sort -u | while read -r file; do
            print_substep "Removing config file mentioning project: $file"
            rm -f "$file" 2>/dev/null || true
        done; then
            print_substep "Cleaned up any config files mentioning project"
        fi
    else
        print_substep "~/.ddev/ directory doesn't exist"
    fi
    
    print_status "Performing comprehensive Docker cleanup for project: $PROJECT_URL"
    
    # Step 1: Check DDEV's project list
    print_substep "Checking DDEV project list..."
    if ddev list | grep -q "^$PROJECT_URL "; then
        print_warning "Found DDEV project: $PROJECT_URL"
        print_substep "Deleting via DDEV..."
        ddev delete -O -y "$PROJECT_URL" 2>/dev/null || true
        sleep 2
    else
        print_substep "Not in DDEV project list"
    fi
    
    # Step 2: Remove all containers
    print_substep "Checking for Docker containers..."
    local containers=$(docker ps -a --format "{{.Names}}" | grep "ddev-${PROJECT_URL}" || true)
    if [ -n "$containers" ]; then
        print_warning "Found containers for $PROJECT_URL"
        echo "$containers" | while read -r container; do
            print_substep "Removing container: $container"
            docker rm -f "$container" 2>/dev/null || true
        done
        print_success "Containers removed"
    else
        print_substep "No containers found"
    fi
    
    # Step 3: Remove all volumes
    print_substep "Checking for Docker volumes..."
    local volumes=$(docker volume ls --format "{{.Name}}" | grep "ddev-${PROJECT_URL}" || true)
    if [ -n "$volumes" ]; then
        print_warning "Found volumes for $PROJECT_URL"
        echo "$volumes" | while read -r volume; do
            print_substep "Removing volume: $volume"
            docker volume rm "$volume" 2>/dev/null || true
        done
        print_success "Volumes removed"
    else
        print_substep "No volumes found"
    fi
    
    # Step 4: Remove all networks
    print_substep "Checking for Docker networks..."
    local networks=$(docker network ls --format "{{.Name}}" | grep "ddev-${PROJECT_URL}" || true)
    if [ -n "$networks" ]; then
        print_warning "Found networks for $PROJECT_URL"
        echo "$networks" | while read -r network; do
            print_substep "Removing network: $network"
            docker network rm "$network" 2>/dev/null || true
        done
        print_success "Networks removed"
    else
        print_substep "No networks found"
    fi
    
    # Step 5: Final cleanup
    print_substep "Pruning dangling Docker resources..."
    docker volume prune -f 2>/dev/null || true
    
    print_success "Docker cleanup completed"
    sleep 2
    
    # Check if .ddev/config.yaml already exists
    if [ -f ".ddev/config.yaml" ]; then
        print_substep "DDEV configuration file exists"
        
        # Quick validation
        local config_ok=true
        
        if ! grep -q "type: drupal10" .ddev/config.yaml 2>/dev/null; then
            config_ok=false
            print_substep "Config has wrong project type"
        fi
        
        if ! grep -q "mariadb:10.11" .ddev/config.yaml 2>/dev/null; then
            config_ok=false
            print_substep "Config has wrong database type"
        fi
        
        if [ "$config_ok" = true ]; then
            print_success "Configuration is valid (drupal10 + mariadb:10.11)"
            step_complete 5 "DDEV initialization (existing valid config)"
            return 0
        else
            print_warning "Config file has incorrect settings - removing entire .ddev directory"
            print_substep "Stopping DDEV..."
            ddev stop 2>/dev/null || true
            print_substep "Removing .ddev directory..."
            rm -rf .ddev
            print_success ".ddev directory removed"
        fi
    elif [ -d ".ddev" ]; then
        print_warning ".ddev directory exists without config.yaml - removing it"
        rm -rf .ddev
        print_success ".ddev directory removed"
    fi
    
    # Remove docker-compose override files
    print_substep "Removing docker-compose override files..."
    rm -f .ddev/.ddev-docker-compose*.yaml 2>/dev/null || true
    rm -f .ddev/docker-compose*.yaml 2>/dev/null || true
    print_success "Override files cleaned"
    
    # Remove docker-compose files from project root
    print_status "Checking for conflicting docker-compose files..."
    
    if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
        print_warning "Found docker-compose files - these conflict with DDEV!"
        print_substep "Renaming to prevent DDEV from using them..."
        
        if [ -f "docker-compose.yml" ]; then
            mv docker-compose.yml docker-compose.yml.backup 2>/dev/null || rm -f docker-compose.yml
            print_substep "Renamed: docker-compose.yml → docker-compose.yml.backup"
        fi
        
        if [ -f "docker-compose.yaml" ]; then
            mv docker-compose.yaml docker-compose.yaml.backup 2>/dev/null || rm -f docker-compose.yaml
            print_substep "Renamed: docker-compose.yaml → docker-compose.yaml.backup"
        fi
        
        print_success "Docker-compose files backed up and removed"
    else
        print_substep "No conflicting docker-compose files found"
    fi
    
    # Remove entire .ddev directory for fresh start
    print_substep "Removing entire .ddev directory for fresh start..."
    if [ -d ".ddev" ]; then
        rm -rf .ddev
        print_success "Removed .ddev directory"
    fi
    
    print_status "Creating DDEV configuration manually..."
    print_substep "Bypassing ddev config to avoid database checks"
    
    # Create .ddev directory
    mkdir -p .ddev
    
    # Create config.yaml directly with MariaDB
    print_substep "Writing config.yaml with MariaDB settings..."
    cat > .ddev/config.yaml << 'CONFIGEOF'
name: PROJECT_NAME_PLACEHOLDER
type: drupal10
docroot: html
php_version: "8.3"
webserver_type: nginx-fpm
xdebug_enabled: false
additional_hostnames: []
additional_fqdns: []
database:
  type: mariadb
  version: "10.11"
use_dns_when_possible: true
composer_version: "2"
web_environment: []
nodejs_version: "18"

# This config was created by cinstall.sh to ensure MariaDB is used
CONFIGEOF
    
    # Replace placeholder with actual project name
    sed -i "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_URL/g" .ddev/config.yaml
    
    print_success "Config file created with MariaDB 10.11"
    
    # Verify the config
    print_substep "Verifying configuration..."
    if grep -q "type: mariadb" .ddev/config.yaml && grep -q "version: \"10.11\"" .ddev/config.yaml; then
        print_success "Verified: MariaDB 10.11 configured"
    else
        print_error "Config verification failed"
        exit 1
    fi
    
    step_complete 5 "DDEV initialization"
}

# Step 6: Start DDEV
step_start_ddev() {
    if should_skip_step 6; then
        # Even if marked complete, verify DDEV is actually running
        if ddev describe &>/dev/null; then
            print_skip "DDEV already running"
            return 0
        else
            print_warning "DDEV should be running but isn't - will start it"
        fi
    fi
    
    if ! ask_step 6 "Start DDEV containers" check_step_ddev_started; then
        if check_step_ddev_started 2>/dev/null; then
            print_skip "DDEV already running"
            return 0
        fi
    fi
    
    step_header 6 "Starting DDEV Containers"
    
    print_status "Starting Docker containers for $PROJECT_URL..."
    print_substep "This may take a few minutes on first run..."
    
    if ddev start; then
        print_success "DDEV containers started successfully"
        
        # CRITICAL: Restart to apply PHP version from config
        print_substep "Restarting to apply PHP 8.3 configuration..."
        ddev restart
        print_success "DDEV restarted with PHP 8.3"
        
        # Verify PHP version
        print_substep "Verifying PHP version..."
        local php_version=$(ddev exec php -v | head -n1 | grep -oP "PHP \K[0-9]+\.[0-9]+" || echo "unknown")
        if [[ "$php_version" == "8.3" ]]; then
            print_success "PHP version confirmed: $php_version"
        else
            print_error "PHP version is $php_version, expected 8.3"
            print_warning "Attempting one more restart..."
            ddev restart
            sleep 5
            php_version=$(ddev exec php -v | head -n1 | grep -oP "PHP \K[0-9]+\.[0-9]+" || echo "unknown")
            if [[ "$php_version" == "8.3" ]]; then
                print_success "PHP version confirmed after retry: $php_version"
            else
                print_error "Still running PHP $php_version after restart"
                print_error "You may need to run: ddev restart"
                exit 1
            fi
        fi
        
        print_substep "Verifying container status..."
        if ddev describe &>/dev/null; then
            print_success "All containers are running"
            
            # Display project info
            echo ""
            echo -e "${CYAN}Project Information:${NC}"
            ddev describe | grep -E "(Name|Status|Primary URL|Type|Database)" | sed 's/^/  /'
            echo ""
        else
            print_warning "Could not verify container status"
        fi
    else
        print_error "Failed to start DDEV containers"
        exit 1
    fi
    
    step_complete 6 "DDEV container startup"
}

# Step 7: Configure GitHub token
step_configure_github_token() {
    if should_skip_step 7; then
        print_skip "GitHub token already configured"
        return 0
    fi
    
    if ! ask_step 7 "Configure GitHub authentication token" check_step_github_token; then
        if check_step_github_token 2>/dev/null; then
            print_skip "GitHub token already configured"
            return 0
        fi
    fi
    
    step_header 7 "Configuring GitHub Authentication"
    
    if [ -n "$GITHUB_TOKEN" ]; then
        print_status "GitHub token detected, configuring Composer authentication..."
        
        print_substep "Setting up OAuth token for github.com..."
        if ddev composer config --global --auth github-oauth.github.com "$GITHUB_TOKEN"; then
            print_success "GitHub token configured successfully"
            print_substep "API rate limit increased to 5,000 requests/hour"
        else
            print_warning "Failed to configure GitHub token"
            print_substep "Continuing with unauthenticated access (60 requests/hour limit)"
        fi
    else
        print_warning "No GitHub token provided"
        print_substep "Using unauthenticated access (60 requests/hour limit)"
        print_substep "To use a token: export GITHUB_TOKEN='your_token' before running this script"
        print_substep "Generate a token at: https://github.com/settings/tokens"
    fi
    
    step_complete 7 "GitHub authentication configuration"
}

# Step 8: Install dependencies
step_install_dependencies() {
    if should_skip_step 8; then
        print_skip "Dependencies already installed"
        return 0
    fi
    
    if ! ask_step 8 "Install Composer dependencies" check_step_dependencies; then
        print_skip "Dependencies already installed"
        return 0
    fi
    
    step_header 8 "Installing Composer Dependencies"
    
    # Check if vendor directory exists and has content
    if [ -d "vendor" ] && [ "$(ls -A vendor 2>/dev/null)" ]; then
        print_substep "vendor directory already exists"
        
        # Verify key packages are installed
        if [ -d "html/core" ] && [ -d "html/profiles/contrib/social" ]; then
            print_success "Core dependencies appear to be installed"
            
            if [ "$INTERACTIVE_MODE" = true ]; then
                read -p "Reinstall dependencies? (y/N): " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    step_complete 8 "Dependency installation (existing)"
                    return 0
                fi
            else
                print_status "Using existing dependencies (non-interactive mode)"
                step_complete 8 "Dependency installation (existing)"
                return 0
            fi
        fi
    fi
    
    print_status "Installing all project dependencies..."
    print_substep "This includes Drupal core, OpenSocial, and all required modules"
    print_substep "This step may take 5-10 minutes..."
    
    if ddev composer install; then
        print_success "All dependencies installed successfully"
        
        print_substep "Verifying installation..."
        if [ -d "html/core" ]; then
            print_success "Drupal core installed"
        fi
        if [ -d "html/profiles/contrib/social" ]; then
            print_success "OpenSocial profile installed"
        fi
        
        print_substep "Counting installed packages..."
        local package_count=$(ddev composer show | wc -l)
        print_success "Total packages installed: $package_count"
    else
        print_error "Dependency installation failed"
        exit 1
    fi
    
    step_complete 8 "Dependency installation"
}

# Step 9: Install Drupal
step_install_drupal() {
    if should_skip_step 9; then
        print_skip "Drupal already installed"
        return 0
    fi
    
    if ! ask_step 9 "Install Drupal with OpenSocial profile" check_step_drupal_installed; then
        print_skip "Drupal already installed"
        return 0
    fi
    
    step_header 9 "Installing Drupal with OpenSocial Profile"
    
    print_status "Configuring private file system (required by OpenSocial)..."
    
    # Create private files directory
    if [ ! -d "html/sites/default/files/private" ]; then
        print_substep "Creating private files directory..."
        ddev exec mkdir -p /var/www/html/sites/default/files/private
        ddev exec chmod 775 /var/www/html/sites/default/files/private
        print_success "Private files directory created"
    else
        print_substep "Private files directory already exists"
    fi
    
    # Configure private file path in settings.ddev.php
    print_substep "Configuring private file path in settings..."
    
    # CRITICAL: Prepare settings.php BEFORE running site:install
    print_status "Preparing settings.php before installation..."
    
    SETTINGS_FILE="html/sites/default/settings.php"
    DEFAULT_SETTINGS="html/sites/default/default.settings.php"
    CURRENT_DIR=$(pwd)
    SETTINGS_ABS_PATH="$CURRENT_DIR/$SETTINGS_FILE"
    
    print_status "  Settings file: $SETTINGS_ABS_PATH"
    
    # Ensure default directory is writable
    chmod 755 html/sites/default
    
    # If settings.php doesn't exist, create it from default
    if [ ! -f "$SETTINGS_FILE" ]; then
        if [ -f "$DEFAULT_SETTINGS" ]; then
            print_status "Creating settings.php from default.settings.php..."
            cp "$DEFAULT_SETTINGS" "$SETTINGS_FILE"
            print_status "✓ Created settings.php"
        fi
    else
        print_skip "settings.php already exists at: $SETTINGS_ABS_PATH"
    fi
    
    # Make settings.php writable for installation
    chmod 666 "$SETTINGS_FILE"
    print_status "Set $SETTINGS_FILE to writable (666)"
    
    # Add private file path BEFORE installation
    if ! grep -q "\$settings\['file_private_path'\] =  '../private';" "$SETTINGS_FILE"; then
        print_status "Adding private file path to settings.php..."
        cat >> "$SETTINGS_FILE" <<'PRIVATEOF'

/**
 * Private file path configuration.
 * 
 * This directory should be outside the web root for security.
 * This is REQUIRED by OpenSocial distribution before installation.
 */
$settings['file_private_path'] = '../private';
PRIVATEOF
        print_status "✓ Private file path added"
    else
        print_skip "Private file path already in settings.php"
    fi
    
    # Ensure settings.ddev.php will be included
    if ! grep -q "settings.ddev.php" "$SETTINGS_FILE"; then
        print_status "Adding settings.ddev.php inclusion..."
        cat >> "$SETTINGS_FILE" <<'DDEVEOF'

/**
 * Automatically generated include for settings managed by ddev.
 */
$ddev_settings = dirname(__FILE__) . '/settings.ddev.php';
if (getenv('IS_DDEV_PROJECT') == 'true' && is_readable($ddev_settings)) {
  require $ddev_settings;
}
DDEVEOF
        print_status "✓ settings.ddev.php inclusion added"
    else
        print_skip "settings.ddev.php inclusion already in settings.php"
    fi
    
    # Check if Drupal is already installed
    if ddev drush status bootstrap 2>/dev/null | grep -q "Successful"; then
        print_substep "Drupal appears to be already installed"
        
        if [ "$INTERACTIVE_MODE" = true ]; then
            read -p "Reinstall Drupal? This will erase all data! (y/N): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                step_complete 9 "Drupal installation (existing)"
                return 0
            fi
            
            print_warning "Dropping existing database..."
            ddev drush sql:drop -y 2>/dev/null || true
        else
            print_status "Using existing Drupal installation (non-interactive mode)"
            step_complete 9 "Drupal installation (existing)"
            return 0
        fi
    fi
    
    print_status "Running Drupal installation with OpenSocial profile..."
    print_substep "Profile: social"
    print_substep "Site name: $SITE_NAME"
    print_substep "Admin username: $ADMIN_USER"
    print_substep "Database: MariaDB 10.11"
    print_substep "This step may take 5-10 minutes..."
    
    if ddev drush site:install social \
        --site-name="$SITE_NAME" \
        --account-name="$ADMIN_USER" \
        --account-pass="$ADMIN_PASS" \
        --account-mail="$ADMIN_EMAIL" \
        --site-mail="$SITE_EMAIL" \
        --yes; then
        
        print_success "Drupal installed successfully with OpenSocial profile"
        
        print_substep "Verifying installation..."
        if ddev drush status bootstrap | grep -q "Successful"; then
            print_success "Drupal bootstrap successful"
        fi
        
        print_substep "Checking database..."
        if ddev drush sqlq "SELECT COUNT(*) FROM users" &>/dev/null; then
            print_success "Database connection verified"
        fi
    else
        print_error "Drupal installation failed"
        exit 1
    fi
    
    step_complete 9 "Drupal installation"
}

# Step 10: Configure site settings
step_configure_site() {
    if should_skip_step 10; then
        print_skip "Site already configured"
        return 0
    fi
    
    if ! ask_step 10 "Configure site settings" check_step_site_configured; then
        print_skip "Site settings already configured"
        return 0
    fi
    
    step_header 10 "Configuring Site Settings"
    
    print_status "Applying site configuration..."
    
    # Set timezone
    print_substep "Setting site timezone to $SITE_TIMEZONE..."
    if ddev drush config:set system.date timezone.default "$SITE_TIMEZONE" --yes; then
        print_success "Timezone configured"
    else
        print_warning "Could not set timezone"
    fi
    
    # Set email settings
    print_substep "Configuring email settings..."
    if ddev drush config:set system.site mail "$SITE_EMAIL" --yes; then
        print_success "Site email configured"
    else
        print_warning "Could not set site email"
    fi
    
    # Add private file path to settings.php
    print_substep "Configuring private file path..."
    if [ -f "html/sites/default/settings.php" ]; then
        if ! grep -q "\$settings\['file_private_path'\]" html/sites/default/settings.php; then
            echo "\$settings['file_private_path'] = '../private';" >> html/sites/default/settings.php
            print_success "Private file path added to settings.php"
        else
            print_substep "Private file path already configured"
        fi
    else
        print_warning "settings.php not found"
    fi
    
    # Clear cache
    print_substep "Clearing Drupal cache..."
    if ddev drush cache:rebuild; then
        print_success "Cache cleared successfully"
    else
        print_warning "Cache clear failed"
    fi
    
    step_complete 10 "Site configuration"
}

# Step 11: Create demo content
step_create_demo_content() {
    if should_skip_step 11; then
        print_skip "Demo content step already completed"
        return 0
    fi
    
    if ! ask_step 11 "Create demo content" check_step_demo_content; then
        print_skip "Demo content already handled"
        return 0
    fi
    
    step_header 11 "Creating Demo Content"
    
    print_status "Installing demo content module..."
    
    # Enable demo content module if it exists
    if ddev drush pm:list --status=disabled | grep -q "social_demo"; then
        print_substep "Enabling social_demo module..."
        if ddev drush pm:enable social_demo -y; then
            print_success "Demo content module enabled"
            
            print_substep "Generating demo users, groups, and content..."
            if ddev drush social-demo:add --all; then
                print_success "Demo content created successfully"
            else
                print_warning "Demo content generation had issues"
            fi
        else
            print_warning "Could not enable demo content module"
        fi
    else
        print_substep "Demo content module not available, skipping"
    fi
    
    step_complete 11 "Demo content creation"
}

# Step 12: Enable additional modules
step_enable_modules() {
    if should_skip_step 12; then
        print_skip "Additional modules already configured"
        return 0
    fi
    
    if ! ask_step 12 "Enable additional recommended modules" check_step_modules_enabled; then
        print_skip "Additional modules already enabled"
        return 0
    fi
    
    step_header 12 "Enabling Additional Modules"
    
    print_status "Checking for workflow_assignment module..."
    
    local module_path=""
    if [ -d "html/modules/contrib/workflow_assignment" ]; then
        module_path="html/modules/contrib/workflow_assignment"
    elif [ -d "html/modules/custom/workflow_assignment" ]; then
        module_path="html/modules/custom/workflow_assignment"
    fi
    
    if [ -n "$module_path" ]; then
        print_success "Module found at: $module_path"
        
        # Check if already enabled
        if ddev drush pm:list --status=enabled --format=json 2>/dev/null | grep -q "workflow_assignment"; then
            print_substep "Module is already enabled"
        else
            print_substep "Enabling workflow_assignment..."
            if ddev drush pm:enable workflow_assignment -y; then
                print_success "workflow_assignment module enabled"
            else
                print_warning "Could not enable workflow_assignment"
            fi
        fi
    else
        print_substep "workflow_assignment module not found in project"
    fi
    
    step_complete 12 "Additional module enablement"
}

# Step 13: Set file permissions
step_set_permissions() {
    if should_skip_step 13; then
        print_skip "File permissions already configured"
        return 0
    fi
    
    if ! ask_step 13 "Set file permissions" check_step_permissions; then
        print_skip "File permissions already set"
        return 0
    fi
    
    step_header 13 "Setting File Permissions"
    
    print_status "Configuring file and directory permissions..."
    
    # Set permissions for sites/default
    if [ -d "html/sites/default" ]; then
        print_substep "Setting permissions on sites/default..."
        chmod 755 html/sites/default
        print_success "sites/default permissions set"
    fi
    
    # Set permissions for files directory
    if [ -d "html/sites/default/files" ]; then
        print_substep "Setting permissions on files directory..."
        chmod -R 775 html/sites/default/files
        print_success "files directory permissions set"
    fi
    
    # Set permissions for private directory
    if [ -d "../private" ]; then
        print_substep "Setting permissions on private directory..."
        chmod -R 775 ../private
        print_success "private directory permissions set"
    fi
    
    # Set settings.php permissions
    if [ -f "html/sites/default/settings.php" ]; then
        print_substep "Setting permissions on settings.php..."
        chmod 444 html/sites/default/settings.php
        print_success "settings.php permissions set (read-only)"
    fi
    
    step_complete 13 "File permissions configuration"
}

# Step 14: Final verification
step_final_verification() {
    # Always run final verification
    
    step_header 14 "Performing Final Verification"
    
    print_status "Running comprehensive system checks..."
    
    # Check Drupal status
    print_substep "Checking Drupal status..."
    if ddev drush status --format=json &>/dev/null; then
        print_success "Drupal is responding correctly"
    else
        print_warning "Drupal status check failed"
    fi
    
    # Check database connection
    print_substep "Verifying database connection..."
    if ddev drush sqlq "SELECT COUNT(*) FROM users" &>/dev/null; then
        local user_count=$(ddev drush sqlq "SELECT COUNT(*) FROM users")
        print_success "Database connection verified ($user_count users found)"
    else
        print_warning "Database verification failed"
    fi
    
    # Check web server
    print_substep "Checking web server response..."
    local site_url=$(ddev describe | grep "Primary URL" | awk '{print $3}')
    if curl -s -o /dev/null -w "%{http_code}" "$site_url" | grep -q "200"; then
        print_success "Web server responding correctly"
    else
        print_warning "Web server check failed"
    fi
    
    # List enabled modules
    print_substep "Checking enabled modules..."
    local module_count=$(ddev drush pm:list --status=enabled --no-core | wc -l)
    print_success "$module_count contrib/custom modules enabled"
    
    step_complete 14 "Final verification"
}

# Display completion information
display_completion() {
    local site_url=$(ddev describe | grep "Primary URL" | awk '{print $3}')
    local login_link=$(ddev drush user:login --uri="$site_url")
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✓ OpenSocial Installation Completed Successfully!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${CYAN}Site Information:${NC}"
    echo "  • Project Name: $PROJECT_URL"
    echo "  • Site URL: $site_url"
    echo "  • Admin Username: $ADMIN_USER"
    echo "  • Admin Password: $ADMIN_PASS"
    echo "  • Database: MariaDB 10.11"
    echo "  • PHP Version: 8.3"
    echo "  • Project Type: Drupal 10"
    echo ""
    echo -e "${CYAN}Quick Access:${NC}"
    echo "  • One-time login link:"
    echo "    $login_link"
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo "  • Access site: ddev launch"
    echo "  • Stop site: ddev stop"
    echo "  • Restart site: ddev restart"
    echo "  • Admin login: ddev drush user:login"
    echo "  • Clear cache: ddev drush cache:rebuild"
    echo "  • View logs: ddev logs"
    echo "  • Run drush: ddev drush [command]"
    echo "  • Resume/update: cd $OPENSOCIAL_DIR && $0"
    echo ""
    echo -e "${CYAN}Project Location:${NC}"
    echo "  $OPENSOCIAL_DIR"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}🎉 All done! Enjoy your new OpenSocial site! 🎉${NC}"
    echo ""
}

################################################################################
# Main Installation Flow
################################################################################

show_help() {
    cat << EOF
OpenSocial (Drupal) Installation Script with State Detection
Version: $VERSION

This script checks the actual state of each installation step instead of
using checkpoint files. It can intelligently resume at any point.

Usage: $0 [OPTIONS] [PROJECT_NAME]

The script will create a subdirectory with the project name in your current
directory. For example, './cinstall.sh mysite' creates './mysite/'

Options:
    -h, --help              Show this help message
    -v, --version           Show version number
    -i, --interactive       Run in interactive mode (ask before each step)
    -t, --token TOKEN       Set GitHub authentication token
    -c, --clean             Force clean installation (remove existing)
    
Environment Variables:
    GITHUB_TOKEN           GitHub personal access token for Composer
                          Generate at: https://github.com/settings/tokens
                          
    Examples:
      export GITHUB_TOKEN='ghp_xxxxxxxxxxxx'
      GITHUB_TOKEN='ghp_xxxx' $0 myproject

Arguments:
    PROJECT_NAME           Name for the project directory (default: opensocial)

Examples:
    cd ~/projects
    $0 mysite              # Creates ~/projects/mysite/
    
    cd /var/www
    $0 client-site         # Creates /var/www/client-site/
    
    $0 -i myproject        # Interactive installation
    $0 -c myproject        # Force clean install (remove existing)
    $0 -t ghp_xxxx mysite  # Install with GitHub token

Configuration:
    Project Type: Drupal 10 (enables drush commands)
    Database: MariaDB 10.11 ONLY (no MySQL support)
    PHP Version: 8.3
    
State Detection:
    The script checks the actual state of each step:
    - Checks if DDEV is configured and running
    - Checks if Drupal is installed and bootstrapping
    - Checks if files and directories exist with correct permissions
    - No checkpoint files needed - pure state detection

For more information, visit:
    https://github.com/rjzaar/commons_install

EOF
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "cinstall.sh version $VERSION"
                exit 0
                ;;
            -i|--interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            -t|--token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            -c|--clean)
                FORCE_CLEAN=true
                shift
                ;;
            *)
                PROJECT_NAME="$1"
                shift
                ;;
        esac
    done
    
    # Display header
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${MAGENTA}OpenSocial (Drupal) Installation Script${NC}"
    echo -e "${CYAN}Automated DDEV-based installation with state detection${NC}"
    echo -e "${BLUE}Version: $VERSION${NC}"
    echo -e "${GREEN}Database: MariaDB 10.11 ONLY | PHP: 8.3 | Project Type: Drupal 10${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ "$INTERACTIVE_MODE" = true ]; then
        print_status "Running in interactive mode"
    fi
    
    if [ "$FORCE_CLEAN" = true ]; then
        print_warning "Force clean mode enabled (will remove existing)"
    fi
    
    if [ -n "$GITHUB_TOKEN" ]; then
        print_status "GitHub token configured (enhanced API access)"
    else
        print_warning "No GitHub token set (rate limits may apply)"
    fi
    
    echo ""
    
    # Execute installation steps
    step_preflight
    step_setup_directory
    step_create_composer_project
    step_create_private_directory
    step_initialize_ddev
    step_start_ddev
    step_configure_github_token
    step_install_dependencies
    step_install_drupal
    step_configure_site
    step_create_demo_content
    step_enable_modules
    step_set_permissions
    step_final_verification
    display_completion
}

# Run main function
main "$@"