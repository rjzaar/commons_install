# commons_install
This is an bash script to install commons_template on ubuntu.

![Test C Install](https://github.com/rjzaar/commons_install/actions/workflows/test-cinstall.yml/badge.svg)

# Updated cinstall Script

## Overview

This is your updated `cinstall` script with significantly improved clarity and removed obsolete workarounds. The script now provides crystal-clear progress reporting throughout the OpenSocial installation process.

---

## 🚀 Quick Start

### Installation

1. **Make the script executable:**
   ```bash
   chmod +x cinstall
   ```

2. **Run the installation:**
   ```bash
   ./cinstall myproject
   ```

### With GitHub Token (Recommended)

```bash
export GITHUB_TOKEN='ghp_xxxxxxxxxxxx'
./cinstall myproject
```

Generate a token at: https://github.com/settings/tokens

### Interactive Mode

```bash
./cinstall -i myproject
```

Choose which steps to run interactively.

---

## 📖 Usage

### Basic Syntax

```bash
./cinstall [OPTIONS] [PROJECT_NAME]
```

### Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-i, --interactive` | Run in interactive mode |
| `-t, --token TOKEN` | Set GitHub authentication token |

### Examples

```bash
# Default installation
./cinstall

# Named project
./cinstall mysite

# With GitHub token
./cinstall -t ghp_xxxx mysite

# Interactive mode
./cinstall -i mysite

# Using environment variable
GITHUB_TOKEN='ghp_xxxx' ./cinstall mysite
```

Useful steps

# Delete all stopped opensocial instances
for i in {2..28}; do
  ddev delete opensocial$i --omit-snapshot --yes
done

# Delete all stopped moodle instances  
for i in {1..14}; do
  ddev delete moodle$i --omit-snapshot --yes
done
ddev delete moodle --omit-snapshot --yes

---

## 📊 Installation Steps

The script performs **14 steps** (simplified from 15):

1. **Pre-flight Checks** - Verify system prerequisites
2. **Project Directory** - Set up installation directory
3. **Composer Project** - Create project from template
4. **Private Directory** - Create private files directory
5. **DDEV Config** - Initialize DDEV configuration
6. **Start DDEV** - Launch Docker containers
7. **GitHub Token** - Configure authentication (optional)
8. **Install Dependencies** - Download all packages
9. **Install Drupal** - Install with OpenSocial profile
10. **Configure Site** - Apply site settings
11. **Demo Content** - Create sample content (optional)
12. **Enable Modules** - Enable additional modules
13. **Set Permissions** - Configure file permissions
14. **Completion** - Display summary and access info

**Estimated Time:** 15-30 minutes (depending on internet speed)

---

## ✨ New Features

### Progress Tracking

Every step shows your progress:
```
STEP 7 of 14 (50% complete)
```

This helps you:
- Know exactly where you are
- Estimate remaining time
- Plan your next coffee break ☕

### Time Estimates

Long-running steps include time estimates:
- "This may take several minutes..."
- "This step may take 5-10 minutes..."

### Verification Steps

After each major operation:
```
  ▸ Installing all project dependencies...
    ✓ All dependencies installed successfully
    → Verifying installation...
    ✓ Drupal core installed
    ✓ OpenSocial profile installed
```

### Enhanced Completion Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ OpenSocial Installation Completed Successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Site Information:
  • Project Name: mysite
  • Site URL: https://mysite.ddev.site
  • Admin Username: admin
  • Admin Password: admin

Quick Access:
  • One-time login link:
    https://mysite.ddev.site/user/reset/1/...

Useful Commands:
  • Access site: ddev launch
  • Stop site: ddev stop
  • Admin login: ddev drush user:login
  • Clear cache: ddev drush cache:rebuild

Project Location:
  /home/user/projects/mysite

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 All done! Enjoy your new OpenSocial site! 🎉
```

---

## 🔧 Requirements

### System Requirements

- **Operating System:** Ubuntu/Debian Linux (tested on Ubuntu 22.04+)
- **Docker:** For DDEV containers
- **Disk Space:** At least 2GB free space

### Required Software

| Software | Minimum Version | Check Command |
|----------|----------------|---------------|
| **DDEV** | v1.21+ | `ddev version` |
| **Composer** | v2.0+ | `composer --version` |
| **Git** | v2.0+ | `git --version` |
| **Docker** | v20.0+ | `docker --version` |

### Installation Links

- **DDEV:** https://ddev.readthedocs.io/en/stable/#installation
- **Composer:** https://getcomposer.org/download/
- **Git:** `sudo apt-get install git`
- **Docker:** https://docs.docker.com/engine/install/

---

## 🎓 What Changed?

### Removed Code

**Step 8.5 - Ultimate Cron Workaround**
- This entire step has been removed
- The patch in commons_template now handles this properly
- Cleaner, more maintainable code

**Error Handling in Step 9**
- Simplified configuration code
- No more ultimate_cron-specific error handling
- Direct config commands work reliably

### Enhanced Code

**Output Functions**
- New `print_substep()` for detailed progress
- New `print_success()` for success confirmations
- Enhanced `step_header()` with progress percentage

**Step Details**
- Every step has detailed progress messages
- Verification added to all major operations
- Success confirmations for each action
- Time estimates where appropriate

**Color Scheme**
- Consistent color coding throughout
- Better visual hierarchy
- Easier to scan output

---

## 🐛 Troubleshooting

### Installation Fails

**With the new output, you'll see exactly where:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 7 of 14 (50% complete)
▶ Installing Composer Dependencies
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ▸ Installing all project dependencies...
    ✗ ERROR: Dependency installation failed
```

**What to do:**
1. Note the step number (7 in this example)
2. Read the error message
3. Check the specific sub-step that failed
4. Retry or seek help with specific step info

### Common Issues

**Docker not running:**
```
  ✗ ERROR: Docker is not running
  ▸ Starting Docker...
```
The script will try to start Docker automatically.

**GitHub rate limit:**
```
  ⚠ WARNING: No GitHub token provided
    → Using unauthenticated access (60 requests/hour limit)
```
Solution: Set `GITHUB_TOKEN` environment variable

**DDEV URL conflict:**
```
  ▸ Checking URL availability...
    → URL 'mysite' is already in use
    ✓ Available URL found: mysite1
```
The script automatically finds an available URL.

---

## 📚 Documentation

### Included Files

| Document | What's Inside |
|----------|--------------|
| **CHANGELOG.md** | Comprehensive technical changes, step-by-step details |
| **QUICK_REFERENCE.md** | Visual comparisons, before/after examples |
| **README.md** | This file - overview and quick start |

### External Resources

- **GitHub Repository:** https://github.com/rjzaar/commons_install
- **Commons Template:** https://github.com/rjzaar/commons_template
- **DDEV Documentation:** https://ddev.readthedocs.io/
- **OpenSocial:** https://www.drupal.org/project/social

---

## 🔄 Backward Compatibility

**Good News:** Everything still works the same way!

✅ All command-line options work
✅ Interactive mode works
✅ GitHub token support works
✅ Project naming works
✅ Resume capability works
✅ URL conflict detection works

**The only differences:**
- Better output (that's the point!)
- No more Step 8.5 (obsolete workaround removed)
- Steps now numbered 1-14 instead of 1-15

---

## 🧪 Testing

### Recommended Tests

**1. Fresh Installation**
```bash
./cinstall test-fresh
```
Verify all steps complete successfully.

**2. With GitHub Token**
```bash
export GITHUB_TOKEN='your_token'
./cinstall test-token
```
Verify token configuration displays correctly.

**3. Interactive Mode**
```bash
./cinstall -i test-interactive
```
Verify interactive prompts work.

**4. URL Conflict**
```bash
./cinstall mysite
./cinstall mysite  # Second time
```
Verify automatic URL resolution (should use mysite1).

---

## 💡 Pro Tips

### Speed Up Installation

**Use a GitHub Token:**
- Increases rate limit from 60 to 5,000 requests/hour
- Prevents rate limit errors
- Speeds up Composer operations

**Pre-download Docker Images:**
```bash
ddev pull
```

### Resume Failed Installation

If installation fails, you can resume:
```bash
cd existing-project-directory
../cinstall
```
Choose option to resume existing installation.

### Multiple Projects

Install multiple projects easily:
```bash
./cinstall project1
./cinstall project2
./cinstall project3
```

Each gets its own URL automatically.

---

## 🤝 Contributing

Found a bug? Have a suggestion?

1. Check existing issues: https://github.com/rjzaar/commons_install/issues
2. Open a new issue with:
   - The step number where the issue occurred
   - Complete error message
   - Your system info (OS, DDEV version, etc.)
   - Any relevant output

---

## 📝 Version History

### Current Version (November 2025)
- ✨ Enhanced step clarity with detailed progress messages
- ❌ Removed ultimate_cron workaround code (handled by patch now)
- 📊 Added progress percentage tracking
- 🎨 Improved visual design with better colors and symbols
- ✅ Added comprehensive verification steps
- 📋 Enhanced completion summary

### Previous Versions
- Added GitHub token support
- Added interactive mode
- Added URL conflict detection
- Initial release

---

## 📧 Support

**Questions or Issues?**

1. **Read the documentation:**
   - Start with QUICK_REFERENCE.md for examples
   - Check CHANGELOG.md for technical details

2. **Common issues:**
   - Ensure ultimate_cron patch is in commons_template
   - Verify all prerequisites are installed
   - Check Docker is running

3. **Still stuck?**
   - Open an issue: https://github.com/rjzaar/commons_install/issues
   - Include: step number, error message, system info

---

## 📜 License

This script is part of the commons_install project.

---

## 🙏 Credits

**Maintained by:** rjzaar  
**Based on:** OpenSocial (Drupal distribution)  
**Infrastructure:** DDEV (Docker-based development environment)  
**Template:** commons_template

---

## 🎯 Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────────┐
│ cinstall - Quick Reference                                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ BASIC USAGE                                                         │
│   ./cinstall myproject                                              │
│                                                                     │
│ WITH GITHUB TOKEN                                                   │
│   export GITHUB_TOKEN='ghp_xxxx'                                    │
│   ./cinstall myproject                                              │
│                                                                     │
│ INTERACTIVE MODE                                                    │
│   ./cinstall -i myproject                                           │
│                                                                     │
│ HELP                                                                │
│   ./cinstall --help                                                 │
│                                                                     │
│ USEFUL COMMANDS (after installation)                                │
│   ddev launch            # Open site in browser                     │
│   ddev drush uli         # Get admin login link                     │
│   ddev drush cr          # Clear cache                              │
│   ddev stop              # Stop containers                          │
│   ddev restart           # Restart containers                       │
│   ddev logs              # View logs                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

**Ready to install? Let's go! 🚀**

```bash
./cinstall myproject
```

**Questions?** Check out QUICK_REFERENCE.md for examples or CHANGELOG.md for technical details.

**Happy installing!** 🎉
