#!/bin/bash

################################################################################
# OpenSocial (Drupal) Installation Script with DDEV on Ubuntu
# 
# This script automates the complete installation of OpenSocial using DDEV,
# including configuration, sample content, and GitHub token support.
#
# Recent updates:
# - Removed ultimate_cron workaround code (patch now handles this)
# - Enhanced step clarity with detailed progress messages
# - Improved status reporting throughout installation
################################################################################

set -e  # Exit on any error

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

################################################################################
# Output Functions - Enhanced for better clarity
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
# Interactive Mode Functions
################################################################################

INTERACTIVE_MODE=false
SKIP_STEPS=()

should_skip_step() {
    local step_num=$1
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
    
    print_status "Checking URL availability..."
    
    while ddev describe "${url_candidate}" &>/dev/null; do
        print_substep "URL '${url_candidate}' is already in use"
        url_candidate="${base_name}${counter}"
        counter=$((counter + 1))
    done
    
    print_success "Available URL found: ${url_candidate}"
    echo "${url_candidate}"
}

################################################################################
# Installation Steps
################################################################################

# Step 1: Pre-flight checks
step_preflight() {
    if ! should_skip_step 1 && ask_step 1 "Pre-flight checks"; then
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
    else
        print_skip "Skipping pre-flight checks"
    fi
}

# Step 2: Set up project directory
step_setup_directory() {
    if ! should_skip_step 2 && ask_step 2 "Set up project directory"; then
        step_header 2 "Setting Up Project Directory"
        
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        print_status "Script directory: $script_dir"
        
        # Get project name
        if [ -z "$PROJECT_NAME" ]; then
            read -p "Enter project name (default: opensocial): " PROJECT_NAME
            PROJECT_NAME=${PROJECT_NAME:-opensocial}
        fi
        
        print_status "Project name: $PROJECT_NAME"
        
        # Find available URL
        PROJECT_URL=$(find_available_url "$PROJECT_NAME")
        
        # Set directory path
        OPENSOCIAL_DIR="$script_dir/$PROJECT_URL"
        print_status "Installation directory: $OPENSOCIAL_DIR"
        
        # Create directory
        if [ -d "$OPENSOCIAL_DIR" ]; then
            print_warning "Directory already exists: $OPENSOCIAL_DIR"
            read -p "Remove existing directory and continue? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_substep "Removing existing directory..."
                rm -rf "$OPENSOCIAL_DIR"
                print_success "Directory removed"
            else
                print_error "Installation cancelled"
                exit 1
            fi
        fi
        
        print_substep "Creating project directory..."
        mkdir -p "$OPENSOCIAL_DIR"
        cd "$OPENSOCIAL_DIR"
        print_success "Project directory created: $OPENSOCIAL_DIR"
        
        step_complete 2 "Project directory setup"
    else
        print_skip "Skipping directory setup"
    fi
}

# Step 3: Create Composer project
step_create_composer_project() {
    if ! should_skip_step 3 && ask_step 3 "Create Composer project from template"; then
        step_header 3 "Creating Composer Project from Template"
        
        print_status "Using template: rjzaar/commons_template"
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
            exit 1
        fi
        
        step_complete 3 "Composer project creation"
    else
        print_skip "Skipping Composer project creation"
    fi
}

# Step 4: Create private directory
step_create_private_directory() {
    if ! should_skip_step 4 && ask_step 4 "Create private files directory"; then
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
    else
        print_skip "Skipping private directory creation"
    fi
}

# Step 5: Initialize DDEV
step_initialize_ddev() {
    if ! should_skip_step 5 && ask_step 5 "Initialize DDEV configuration"; then
        step_header 5 "Initializing DDEV Configuration"
        
        print_status "Configuring DDEV for project: $PROJECT_URL"
        print_substep "Project type: php"
        print_substep "Docroot: html"
        print_substep "Project name: $PROJECT_URL"
        
        if ddev config --project-type=php --docroot=html --project-name="$PROJECT_URL" --php-version=8.2; then
            print_success "DDEV configuration created"
            
            print_substep "Verifying DDEV configuration..."
            if [ -f ".ddev/config.yaml" ]; then
                print_success ".ddev/config.yaml created successfully"
            else
                print_error "DDEV config file not found"
                exit 1
            fi
        else
            print_error "DDEV configuration failed"
            exit 1
        fi
        
        step_complete 5 "DDEV initialization"
    else
        print_skip "Skipping DDEV initialization"
    fi
}

# Step 6: Start DDEV
step_start_ddev() {
    if ! should_skip_step 6 && ask_step 6 "Start DDEV containers"; then
        step_header 6 "Starting DDEV Containers"
        
        print_status "Starting Docker containers for $PROJECT_URL..."
        print_substep "This may take a few minutes on first run..."
        
        if ddev start; then
            print_success "DDEV containers started successfully"
            
            print_substep "Verifying container status..."
            if ddev describe &>/dev/null; then
                print_success "All containers are running"
                
                # Display project info
                echo ""
                echo -e "${CYAN}Project Information:${NC}"
                ddev describe | grep -E "(Name|Status|Primary URL)" | sed 's/^/  /'
                echo ""
            else
                print_warning "Could not verify container status"
            fi
        else
            print_error "Failed to start DDEV containers"
            exit 1
        fi
        
        step_complete 6 "DDEV container startup"
    else
        print_skip "Skipping DDEV startup"
    fi
}

# Step 6.5: Configure GitHub token
step_configure_github_token() {
    if ! should_skip_step 6.5 && ask_step 6.5 "Configure GitHub authentication token"; then
        step_header 6.5 "Configuring GitHub Authentication"
        
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
        
        step_complete 6.5 "GitHub authentication configuration"
    else
        print_skip "Skipping GitHub token configuration"
    fi
}

# Step 7: Install dependencies
step_install_dependencies() {
    if ! should_skip_step 7 && ask_step 7 "Install Composer dependencies"; then
        step_header 7 "Installing Composer Dependencies"
        
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
        
        step_complete 7 "Dependency installation"
    else
        print_skip "Skipping dependency installation"
    fi
}

# Step 8: Install Drupal
step_install_drupal() {
    if ! should_skip_step 8 && ask_step 8 "Install Drupal with OpenSocial profile"; then
        step_header 8 "Installing Drupal with OpenSocial Profile"
        
        print_status "Running Drupal installation with OpenSocial profile..."
        print_substep "Profile: social"
        print_substep "Site name: $SITE_NAME"
        print_substep "Admin username: $ADMIN_USER"
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
        
        step_complete 8 "Drupal installation"
    else
        print_skip "Skipping Drupal installation"
    fi
}

# Step 9: Configure site settings
step_configure_site() {
    if ! should_skip_step 9 && ask_step 9 "Configure site settings"; then
        step_header 9 "Configuring Site Settings"
        
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
            if ! grep -q "\$settings\['file_private_path'\] =  '../private';" html/sites/default/settings.php; then
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
        
        step_complete 9 "Site configuration"
    else
        print_skip "Skipping site configuration"
    fi
}

# Step 10: Create demo content
step_create_demo_content() {
    if ! should_skip_step 10 && ask_step 10 "Create demo content"; then
        step_header 10 "Creating Demo Content"
        
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
        
        step_complete 10 "Demo content creation"
    else
        print_skip "Skipping demo content creation"
    fi
}

# Step 11: Enable additional modules
step_enable_modules() {
    if ! should_skip_step 11 && ask_step 11 "Enable additional recommended modules"; then
        step_header 11 "Enabling Additional Modules"
        
        print_status "Checking for workflow_assignment module..."
        
        if [ -d "html/modules/contrib/workflow_assignment" ] || [ -d "html/modules/custom/workflow_assignment" ]; then
            print_substep "workflow_assignment module found"
            print_substep "Enabling workflow_assignment..."
            
            if ddev drush pm:enable workflow_assignment -y; then
                print_success "workflow_assignment module enabled"
            else
                print_warning "Could not enable workflow_assignment"
            fi
        else
            print_substep "workflow_assignment module not found in project"
        fi
        
        step_complete 11 "Additional module enablement"
    else
        print_skip "Skipping additional module enablement"
    fi
}

# Step 12: Set file permissions
step_set_permissions() {
    if ! should_skip_step 12 && ask_step 12 "Set file permissions"; then
        step_header 12 "Setting File Permissions"
        
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
        
        step_complete 12 "File permissions configuration"
    else
        print_skip "Skipping file permissions setup"
    fi
}

# Step 13: Final verification
step_final_verification() {
    if ! should_skip_step 13 && ask_step 13 "Perform final verification"; then
        step_header 13 "Performing Final Verification"
        
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
        
        step_complete 13 "Final verification"
    else
        print_skip "Skipping final verification"
    fi
}

# Step 14: Display completion information
step_display_completion() {
    if ! should_skip_step 14 && ask_step 14 "Display completion information"; then
        step_header 14 "Installation Complete!"
        
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
        echo ""
        echo -e "${CYAN}Project Location:${NC}"
        echo "  $OPENSOCIAL_DIR"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        step_complete 14 "Installation summary displayed"
    else
        print_skip "Skipping completion information display"
    fi
}

################################################################################
# Main Installation Flow
################################################################################

show_help() {
    cat << EOF
OpenSocial (Drupal) Installation Script

Usage: $0 [OPTIONS] [PROJECT_NAME]

Options:
    -h, --help              Show this help message
    -i, --interactive       Run in interactive mode (ask before each step)
    -t, --token TOKEN       Set GitHub authentication token
    
Environment Variables:
    GITHUB_TOKEN           GitHub personal access token for Composer
                          Generate at: https://github.com/settings/tokens
                          Required scopes: repo (for private repos)
                          
    Examples:
      export GITHUB_TOKEN='ghp_xxxxxxxxxxxx'
      GITHUB_TOKEN='ghp_xxxx' $0 myproject

Arguments:
    PROJECT_NAME           Name for the project (default: opensocial)

Examples:
    $0                     # Install with default settings
    $0 mysite              # Install with project name 'mysite'
    $0 -i                  # Interactive installation
    $0 -t ghp_xxxx mysite  # Install with GitHub token

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
            -i|--interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            -t|--token)
                GITHUB_TOKEN="$2"
                shift 2
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
    echo -e "${CYAN}Automated DDEV-based installation for OpenSocial communities${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ "$INTERACTIVE_MODE" = true ]; then
        print_status "Running in interactive mode"
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
    step_display_completion
    
    echo ""
    echo -e "${GREEN}🎉 All done! Enjoy your new OpenSocial site! 🎉${NC}"
    echo ""
}

# Run main function
main "$@"
