# Script Usage Guide

## Running the Script

### Interactive Mode (Default)
Prompts you for the admin email:
```bash
sudo bash opensocial_moodle_sso_complete_modified.sh
```

### Non-Interactive Mode (All Defaults)
Uses all default values without prompting:
```bash
sudo bash opensocial_moodle_sso_complete_modified.sh --defaults
```
or
```bash
sudo bash opensocial_moodle_sso_complete_modified.sh -d
```

### View Help
```bash
bash opensocial_moodle_sso_complete_modified.sh --help
```

## Default Configuration

When using `--defaults` flag, the script uses:

| Setting | Default Value |
|---------|---------------|
| Admin Email | admin@example.com |
| Admin Username | admin |
| Admin Password | Admin@123 |
| OpenSocial URL | https://opensocial.ddev.site* |
| Moodle URL | https://moodle.ddev.site* |
| Storage Location | Same directory as script |

*URLs will auto-increment if conflicts detected (opensocial1, opensocial2, etc.)

## What the Script Does

1. **System Prerequisites** - Installs required packages
2. **Docker & DDEV** - Installs container environment
3. **OpenSocial (Drupal)** - Downloads and installs social platform
4. **Moodle** - Downloads and installs LMS
5. **OAuth Integration** - Configures SSO between platforms

## File Locations

All files are stored in the same directory as the script:

```
/path/to/script/
├── opensocial_moodle_sso_complete_modified.sh  # The script
├── opensocial/                                   # OpenSocial installation
│   ├── .ddev/                                   # DDEV configuration
│   ├── html/                                    # Web files
│   └── keys/                                    # OAuth keys
├── moodle/                                      # Moodle installation
│   ├── .ddev/                                   # DDEV configuration
│   ├── html/                                    # Web files
│   └── moodledata/                              # Moodle data
├── private/                                     # Private files for OpenSocial
└── opensocial_moodle_ddev_credentials.txt      # Login credentials
```

## After Installation

1. **View credentials:**
   ```bash
   cat opensocial_moodle_ddev_credentials.txt
   ```

2. **Access OpenSocial:**
   - URL: https://opensocial.ddev.site (or as shown in credentials)
   - Login: admin / Admin@123

3. **Access Moodle:**
   - URL: https://moodle.ddev.site (or as shown in credentials)
   - Login: admin / Admin@123

4. **Complete OAuth configuration in Moodle web interface** (instructions in credentials file)

## Managing DDEV Projects

### Start projects:
```bash
cd /path/to/script/opensocial && ddev start
cd /path/to/script/moodle && ddev start
```

### Stop projects:
```bash
cd /path/to/script/opensocial && ddev stop
cd /path/to/script/moodle && ddev stop
```

### View project status:
```bash
cd /path/to/script/opensocial && ddev describe
cd /path/to/script/moodle && ddev describe
```

### Open in browser:
```bash
cd /path/to/script/opensocial && ddev launch
cd /path/to/script/moodle && ddev launch
```

### Get admin login link for OpenSocial:
```bash
cd /path/to/script/opensocial && ddev drush uli
```

## Re-running the Script

The script is **idempotent** - you can run it multiple times safely:
- It checks actual system state
- Skips steps that are already complete
- Only installs/configures what's missing

This is useful if:
- Installation was interrupted
- You want to verify everything is set up correctly
- Something was manually deleted and needs to be recreated

## Environment Variables

You can override defaults with environment variables:

```bash
# Use different project names
OPENSOCIAL_PROJECT=mysite sudo bash script.sh --defaults

# Use different Moodle version
MOODLE_VERSION=MOODLE_405_STABLE sudo bash script.sh --defaults

# Use different OpenSocial version
OPENSOCIAL_VERSION=12.3.0 sudo bash script.sh --defaults
```

## Troubleshooting

### View logs:
```bash
cd /path/to/script/opensocial && ddev logs
cd /path/to/script/moodle && ddev logs
```

### Restart projects:
```bash
cd /path/to/script/opensocial && ddev restart
cd /path/to/script/moodle && ddev restart
```

### Clear Drupal cache:
```bash
cd /path/to/script/opensocial && ddev drush cr
```

### Check OAuth endpoints:
```bash
curl https://opensocial.ddev.site/oauth/authorize
curl https://opensocial.ddev.site/oauth/token
curl https://opensocial.ddev.site/oauth/userinfo
```
