#!/bin/bash

#######################################################
# Moodle Installation Script for Ubuntu with Nginx
# This script installs Moodle LMS on Ubuntu Server
# Features: Resumable, idempotent, checks existing components
#######################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
MOODLE_VERSION="MOODLE_404_STABLE"  # Change this to desired version
MOODLE_DIR="/var/www/moodle"
MOODLE_DATA="/var/moodledata"
DB_NAME="moodle"
DB_USER="moodleuser"
DOMAIN="your-domain.com"  # Change this to your domain
ADMIN_EMAIL="admin@your-domain.com"  # Change this

# Checkpoint file to track progress
CHECKPOINT_FILE="/var/log/moodle_install_progress.txt"
CREDENTIALS_FILE="/root/moodle_credentials.txt"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Moodle Installation Script for Ubuntu/Nginx${NC}"
echo -e "${GREEN}Resumable & Idempotent Version${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Initialize or load checkpoint file
if [ -f "$CHECKPOINT_FILE" ]; then
    echo -e "${BLUE}Found previous installation progress. Resuming...${NC}"
    source "$CHECKPOINT_FILE"
else
    echo -e "${BLUE}Starting fresh installation...${NC}"
    touch "$CHECKPOINT_FILE"
fi

# Load existing database password if it exists
if [ -f "$CREDENTIALS_FILE" ]; then
    echo -e "${BLUE}Loading existing credentials...${NC}"
    DB_PASS=$(grep "Database Password:" "$CREDENTIALS_FILE" | cut -d' ' -f3)
    if [ -z "$DB_PASS" ]; then
        DB_PASS=$(openssl rand -base64 12)
    fi
else
    DB_PASS=$(openssl rand -base64 12)
fi

# Function to mark a step as complete
mark_complete() {
    echo "$1=done" >> "$CHECKPOINT_FILE"
    eval "$1=done"
}

# Function to check if a step is complete
is_complete() {
    grep -q "^$1=done$" "$CHECKPOINT_FILE" 2>/dev/null
    return $?
}

# Function to handle errors
handle_error() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Error occurred in step: $1${NC}"
    echo -e "${RED}========================================${NC}"
    echo -e "${YELLOW}The script can be safely re-run to resume from this point.${NC}"
    echo -e "${YELLOW}Progress has been saved to: $CHECKPOINT_FILE${NC}"
    exit 1
}

# Step 1: Update system
if ! is_complete "STEP_UPDATE"; then
    echo -e "${YELLOW}Step 1: Updating system packages...${NC}"
    if apt update && apt upgrade -y; then
        mark_complete "STEP_UPDATE"
        echo -e "${GREEN}✓ System updated successfully${NC}"
    else
        handle_error "System Update"
    fi
else
    echo -e "${GREEN}✓ Step 1: System already updated (skipping)${NC}"
fi

# Step 2: Check and install required packages
if ! is_complete "STEP_PACKAGES"; then
    echo -e "${YELLOW}Step 2: Checking and installing required packages...${NC}"
    
    # List of required packages
    PACKAGES=(
        "nginx"
        "mariadb-server"
        "php-fpm"
        "php-mysql"
        "php-xml"
        "php-xmlrpc"
        "php-curl"
        "php-gd"
        "php-imagick"
        "php-cli"
        "php-dev"
        "php-imap"
        "php-mbstring"
        "php-opcache"
        "php-soap"
        "php-zip"
        "php-intl"
        "php-ldap"
        "git"
        "curl"
        "certbot"
        "python3-certbot-nginx"
    )
    
    PACKAGES_TO_INSTALL=()
    
    # Check each package
    for package in "${PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            echo -e "${BLUE}  ✓ $package already installed${NC}"
        else
            echo -e "${YELLOW}  → $package needs to be installed${NC}"
            PACKAGES_TO_INSTALL+=("$package")
        fi
    done
    
    # Install missing packages
    if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
        echo -e "${YELLOW}Installing ${#PACKAGES_TO_INSTALL[@]} missing packages...${NC}"
        if apt install -y "${PACKAGES_TO_INSTALL[@]}"; then
            mark_complete "STEP_PACKAGES"
            echo -e "${GREEN}✓ All packages installed successfully${NC}"
        else
            handle_error "Package Installation"
        fi
    else
        echo -e "${GREEN}✓ All required packages already installed${NC}"
        mark_complete "STEP_PACKAGES"
    fi
else
    echo -e "${GREEN}✓ Step 2: Packages already installed (skipping)${NC}"
fi

# Detect PHP version
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || echo "")
if [ -z "$PHP_VERSION" ]; then
    echo -e "${RED}PHP not detected. Please check package installation.${NC}"
    handle_error "PHP Detection"
fi
echo -e "${GREEN}Detected PHP version: $PHP_VERSION${NC}"

# Step 3: Configure PHP
if ! is_complete "STEP_PHP_CONFIG"; then
    echo -e "${YELLOW}Step 3: Configuring PHP...${NC}"
    PHP_INI="/etc/php/$PHP_VERSION/fpm/php.ini"
    
    if [ ! -f "$PHP_INI" ]; then
        echo -e "${RED}PHP configuration file not found: $PHP_INI${NC}"
        handle_error "PHP Configuration File Not Found"
    fi
    
    # Backup original config if not already backed up
    if [ ! -f "$PHP_INI.moodle_backup" ]; then
        cp "$PHP_INI" "$PHP_INI.moodle_backup"
        echo -e "${BLUE}  ✓ Created backup: $PHP_INI.moodle_backup${NC}"
    fi
    
    if sed -i 's/upload_max_filesize = .*/upload_max_filesize = 256M/' $PHP_INI && \
       sed -i 's/post_max_size = .*/post_max_size = 256M/' $PHP_INI && \
       sed -i 's/memory_limit = .*/memory_limit = 512M/' $PHP_INI && \
       sed -i 's/max_execution_time = .*/max_execution_time = 300/' $PHP_INI && \
       sed -i 's/max_input_time = .*/max_input_time = 300/' $PHP_INI && \
       sed -i 's/;max_input_vars = .*/max_input_vars = 5000/' $PHP_INI; then
        mark_complete "STEP_PHP_CONFIG"
        echo -e "${GREEN}✓ PHP configured successfully${NC}"
    else
        handle_error "PHP Configuration"
    fi
else
    echo -e "${GREEN}✓ Step 3: PHP already configured (skipping)${NC}"
fi

# Step 4: Configure MariaDB
if ! is_complete "STEP_MARIADB_START"; then
    echo -e "${YELLOW}Step 4: Starting and enabling MariaDB...${NC}"
    
    # Check if MariaDB is already running
    if systemctl is-active --quiet mariadb; then
        echo -e "${BLUE}  ✓ MariaDB is already running${NC}"
    else
        if systemctl start mariadb; then
            echo -e "${GREEN}  ✓ MariaDB started${NC}"
        else
            handle_error "MariaDB Start"
        fi
    fi
    
    # Check if MariaDB is enabled
    if systemctl is-enabled --quiet mariadb; then
        echo -e "${BLUE}  ✓ MariaDB is already enabled${NC}"
    else
        if systemctl enable mariadb; then
            echo -e "${GREEN}  ✓ MariaDB enabled${NC}"
        else
            handle_error "MariaDB Enable"
        fi
    fi
    
    mark_complete "STEP_MARIADB_START"
    echo -e "${GREEN}✓ MariaDB configured successfully${NC}"
else
    echo -e "${GREEN}✓ Step 4: MariaDB already started (skipping)${NC}"
fi

# Step 5: Secure MariaDB (skip if already done)
if ! is_complete "STEP_MARIADB_SECURE"; then
    echo -e "${YELLOW}Step 5: Securing MariaDB installation...${NC}"
    
    # Check if root password is already set
    if mysql -uroot -e "SELECT 1" &>/dev/null; then
        echo -e "${YELLOW}  → Securing MariaDB...${NC}"
        MYSQL_ROOT_PASS=$(openssl rand -base64 12)
        
        mysql -e "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASS') WHERE User='root'" 2>/dev/null || \
        mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASS'" 2>/dev/null || true
        
        mysql -e "DELETE FROM mysql.user WHERE User=''" || true
        mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')" || true
        mysql -e "DROP DATABASE IF EXISTS test" || true
        mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'" || true
        mysql -e "FLUSH PRIVILEGES"
        
        # Save root password
        echo "MySQL_ROOT_PASSWORD=$MYSQL_ROOT_PASS" >> "$CHECKPOINT_FILE"
        
        mark_complete "STEP_MARIADB_SECURE"
        echo -e "${GREEN}✓ MariaDB secured successfully${NC}"
    else
        echo -e "${BLUE}  ✓ MariaDB already secured${NC}"
        mark_complete "STEP_MARIADB_SECURE"
    fi
else
    echo -e "${GREEN}✓ Step 5: MariaDB already secured (skipping)${NC}"
fi

# Step 6: Create Moodle database and user
if ! is_complete "STEP_DATABASE"; then
    echo -e "${YELLOW}Step 6: Creating Moodle database and user...${NC}"
    
    # Check if database already exists
    if mysql -e "USE $DB_NAME" 2>/dev/null; then
        echo -e "${BLUE}  ✓ Database '$DB_NAME' already exists${NC}"
    else
        if mysql -e "CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"; then
            echo -e "${GREEN}  ✓ Database '$DB_NAME' created${NC}"
        else
            handle_error "Database Creation"
        fi
    fi
    
    # Check if user already exists
    USER_EXISTS=$(mysql -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER' AND host = 'localhost')")
    if [ "$USER_EXISTS" = "1" ]; then
        echo -e "${BLUE}  ✓ User '$DB_USER' already exists${NC}"
        # Update password to ensure it matches our stored one
        mysql -e "ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" 2>/dev/null || \
        mysql -e "SET PASSWORD FOR '$DB_USER'@'localhost' = PASSWORD('$DB_PASS');" 2>/dev/null || true
    else
        if mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"; then
            echo -e "${GREEN}  ✓ User '$DB_USER' created${NC}"
        else
            handle_error "Database User Creation"
        fi
    fi
    
    # Grant privileges
    if mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"; then
        echo -e "${GREEN}  ✓ Privileges granted${NC}"
    else
        handle_error "Database Privileges"
    fi
    
    mysql -e "FLUSH PRIVILEGES;"
    mark_complete "STEP_DATABASE"
    echo -e "${GREEN}✓ Database setup completed successfully${NC}"
else
    echo -e "${GREEN}✓ Step 6: Database already configured (skipping)${NC}"
fi

# Step 7: Download Moodle
if ! is_complete "STEP_MOODLE_DOWNLOAD"; then
    echo -e "${YELLOW}Step 7: Downloading Moodle...${NC}"
    
    # Check if Moodle directory already exists
    if [ -d "$MOODLE_DIR" ]; then
        echo -e "${BLUE}  ✓ Moodle directory already exists at $MOODLE_DIR${NC}"
        
        # Check if it's a valid Moodle installation
        if [ -f "$MOODLE_DIR/version.php" ]; then
            echo -e "${BLUE}  ✓ Valid Moodle installation detected${NC}"
            mark_complete "STEP_MOODLE_DOWNLOAD"
        else
            echo -e "${YELLOW}  → Directory exists but doesn't appear to be Moodle. Backing up and re-downloading...${NC}"
            mv "$MOODLE_DIR" "${MOODLE_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
            
            cd /var/www
            if git clone -b $MOODLE_VERSION git://git.moodle.org/moodle.git; then
                mv moodle $MOODLE_DIR
                mark_complete "STEP_MOODLE_DOWNLOAD"
                echo -e "${GREEN}✓ Moodle downloaded successfully${NC}"
            else
                handle_error "Moodle Download"
            fi
        fi
    else
        cd /var/www
        if git clone -b $MOODLE_VERSION git://git.moodle.org/moodle.git; then
            mv moodle $MOODLE_DIR
            mark_complete "STEP_MOODLE_DOWNLOAD"
            echo -e "${GREEN}✓ Moodle downloaded successfully${NC}"
        else
            handle_error "Moodle Download"
        fi
    fi
else
    echo -e "${GREEN}✓ Step 7: Moodle already downloaded (skipping)${NC}"
fi

# Step 8: Create Moodle data directory
if ! is_complete "STEP_MOODLE_DATA"; then
    echo -e "${YELLOW}Step 8: Creating Moodle data directory...${NC}"
    
    if [ -d "$MOODLE_DATA" ]; then
        echo -e "${BLUE}  ✓ Moodle data directory already exists${NC}"
    else
        if mkdir -p $MOODLE_DATA; then
            echo -e "${GREEN}  ✓ Created directory: $MOODLE_DATA${NC}"
        else
            handle_error "Moodle Data Directory Creation"
        fi
    fi
    
    # Set permissions
    chmod 770 $MOODLE_DATA
    chown -R www-data:www-data $MOODLE_DATA
    chown -R www-data:www-data $MOODLE_DIR
    
    mark_complete "STEP_MOODLE_DATA"
    echo -e "${GREEN}✓ Moodle data directory configured successfully${NC}"
else
    echo -e "${GREEN}✓ Step 8: Moodle data directory already configured (skipping)${NC}"
fi

# Step 9: Create Nginx configuration
if ! is_complete "STEP_NGINX_CONFIG"; then
    echo -e "${YELLOW}Step 9: Configuring Nginx...${NC}"
    
    NGINX_CONFIG="/etc/nginx/sites-available/moodle"
    
    # Backup existing config if it exists
    if [ -f "$NGINX_CONFIG" ]; then
        echo -e "${BLUE}  ✓ Nginx config already exists, backing up...${NC}"
        cp "$NGINX_CONFIG" "${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    cat > $NGINX_CONFIG << 'EOF'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;
    root MOODLE_DIR_PLACEHOLDER;
    index index.php index.html index.htm;

    client_max_body_size 256M;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_index index.php;
        fastcgi_pass unix:/var/run/php/phpPHP_VERSION_PLACEHOLDER-fpm.sock;
        include fastcgi_params;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        fastcgi_read_timeout 300;
    }

    location /dataroot/ {
        internal;
        alias MOODLE_DATA_PLACEHOLDER/;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    # Replace placeholders
    sed -i "s|DOMAIN_PLACEHOLDER|$DOMAIN|g" $NGINX_CONFIG
    sed -i "s|MOODLE_DIR_PLACEHOLDER|$MOODLE_DIR|g" $NGINX_CONFIG
    sed -i "s|MOODLE_DATA_PLACEHOLDER|$MOODLE_DATA|g" $NGINX_CONFIG
    sed -i "s|PHP_VERSION_PLACEHOLDER|$PHP_VERSION|g" $NGINX_CONFIG
    
    # Enable site
    if [ ! -L "/etc/nginx/sites-enabled/moodle" ]; then
        ln -sf /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/
        echo -e "${GREEN}  ✓ Site enabled${NC}"
    else
        echo -e "${BLUE}  ✓ Site already enabled${NC}"
    fi
    
    # Remove default site if it exists
    if [ -L "/etc/nginx/sites-enabled/default" ]; then
        rm -f /etc/nginx/sites-enabled/default
        echo -e "${GREEN}  ✓ Default site disabled${NC}"
    fi
    
    # Test Nginx configuration
    if nginx -t; then
        mark_complete "STEP_NGINX_CONFIG"
        echo -e "${GREEN}✓ Nginx configured successfully${NC}"
    else
        handle_error "Nginx Configuration Test"
    fi
else
    echo -e "${GREEN}✓ Step 9: Nginx already configured (skipping)${NC}"
fi

# Step 10: Restart services
if ! is_complete "STEP_SERVICES"; then
    echo -e "${YELLOW}Step 10: Restarting services...${NC}"
    
    # Restart PHP-FPM
    if systemctl restart php${PHP_VERSION}-fpm; then
        echo -e "${GREEN}  ✓ PHP-FPM restarted${NC}"
    else
        handle_error "PHP-FPM Restart"
    fi
    
    # Restart Nginx
    if systemctl restart nginx; then
        echo -e "${GREEN}  ✓ Nginx restarted${NC}"
    else
        handle_error "Nginx Restart"
    fi
    
    mark_complete "STEP_SERVICES"
    echo -e "${GREEN}✓ Services restarted successfully${NC}"
else
    echo -e "${GREEN}✓ Step 10: Services already restarted (skipping)${NC}"
fi

# Step 11: Create config.php with database credentials
if ! is_complete "STEP_CONFIG_PHP"; then
    echo -e "${YELLOW}Step 11: Creating Moodle configuration...${NC}"
    
    CONFIG_FILE="$MOODLE_DIR/config.php"
    
    # Backup existing config if it exists
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${BLUE}  ✓ Existing config.php found, backing up...${NC}"
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    cat > $CONFIG_FILE << 'CONFIGEOF'
<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = 'DB_NAME_PLACEHOLDER';
$CFG->dbuser    = 'DB_USER_PLACEHOLDER';
$CFG->dbpass    = 'DB_PASS_PLACEHOLDER';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => '',
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot   = 'http://DOMAIN_PLACEHOLDER';
$CFG->dataroot  = 'MOODLE_DATA_PLACEHOLDER';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0770;

require_once(__DIR__ . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!
CONFIGEOF
    
    # Replace placeholders
    sed -i "s|DB_NAME_PLACEHOLDER|$DB_NAME|g" $CONFIG_FILE
    sed -i "s|DB_USER_PLACEHOLDER|$DB_USER|g" $CONFIG_FILE
    sed -i "s|DB_PASS_PLACEHOLDER|$DB_PASS|g" $CONFIG_FILE
    sed -i "s|DOMAIN_PLACEHOLDER|$DOMAIN|g" $CONFIG_FILE
    sed -i "s|MOODLE_DATA_PLACEHOLDER|$MOODLE_DATA|g" $CONFIG_FILE
    
    chown www-data:www-data $CONFIG_FILE
    chmod 640 $CONFIG_FILE
    
    mark_complete "STEP_CONFIG_PHP"
    echo -e "${GREEN}✓ Moodle configuration created successfully${NC}"
else
    echo -e "${GREEN}✓ Step 11: Moodle config.php already exists (skipping)${NC}"
fi

# Step 12: Save credentials
if ! is_complete "STEP_SAVE_CREDENTIALS"; then
    echo -e "${YELLOW}Step 12: Saving installation details...${NC}"
    
    cat > "$CREDENTIALS_FILE" << EOF
========================================
Moodle Installation Details
========================================
Installation Date: $(date)
Moodle Directory: $MOODLE_DIR
Moodle Data Directory: $MOODLE_DATA
Database Name: $DB_NAME
Database User: $DB_USER
Database Password: $DB_PASS
Domain: $DOMAIN
PHP Version: $PHP_VERSION

Next Steps:
1. Update the domain name in /etc/nginx/sites-available/moodle if needed
2. Complete the installation by visiting: http://$DOMAIN
3. Follow the web installer to complete the setup
4. Consider setting up SSL with: certbot --nginx -d $DOMAIN

Optional: To enable SSL after DNS is configured:
sudo certbot --nginx -d $DOMAIN --email $ADMIN_EMAIL --agree-tos --no-eff-email --redirect

Checkpoint File: $CHECKPOINT_FILE
To restart installation from scratch, delete: $CHECKPOINT_FILE
========================================
EOF
    
    chmod 600 "$CREDENTIALS_FILE"
    mark_complete "STEP_SAVE_CREDENTIALS"
    echo -e "${GREEN}✓ Installation details saved${NC}"
else
    echo -e "${GREEN}✓ Step 12: Credentials already saved (skipping)${NC}"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Important Information:${NC}"
echo -e "Credentials saved to: ${GREEN}$CREDENTIALS_FILE${NC}"
echo -e "Progress log saved to: ${GREEN}$CHECKPOINT_FILE${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Update your DNS to point $DOMAIN to this server"
echo "2. Edit /etc/nginx/sites-available/moodle to set your actual domain (if needed)"
echo "3. Run: sudo systemctl restart nginx"
echo "4. Visit http://$DOMAIN to complete the web-based installation"
echo "5. Set up SSL with: sudo certbot --nginx -d $DOMAIN"
echo ""
echo -e "${YELLOW}Database Credentials:${NC}"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Password: $DB_PASS"
echo ""
echo -e "${BLUE}Installation Summary:${NC}"
grep "=done" "$CHECKPOINT_FILE" | wc -l | xargs echo "Completed steps:"
echo ""
echo -e "${GREEN}If you need to restart the installation:${NC}"
echo "  - To resume from where it stopped: just run the script again"
echo "  - To start fresh: sudo rm $CHECKPOINT_FILE && run the script"
echo ""
echo -e "${RED}IMPORTANT: Keep $CREDENTIALS_FILE secure!${NC}"
echo -e "${GREEN}========================================${NC}"
