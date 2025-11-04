# cinstall.sh - Version History

## Version 2.1.0 (Current) - November 2025

### 🎯 Major Fixes

#### Version Flag Support
- Added `-v` or `--version` flag to display version number
- Version shown in script header
- Easy to check which version you're running

```bash
./cinstall.sh -v
# Output: cinstall.sh version 2.1.0
```

#### Directory Handling Improvements
- Fixed issue where script would fail if directory had checkpoint file
- Checkpoint file now temporarily moved during composer create-project
- Better validation that we're in correct directory before operations
- Improved error messages showing current directory

#### Non-Interactive Mode Enhancements
- All prompts now properly respect non-interactive mode (default)
- No user input required for default operation
- Smart defaults for all decisions

#### CD (Change Directory) Fix
- Fixed bug where script wouldn't cd into project directory when resuming
- Now always ensures we're in the project directory before operations
- Added explicit confirmation messages when changing directories

### 🔧 Technical Changes

**Files Modified:**
- `cinstall.sh` - All fixes applied

**New Functions:**
- None (improvements to existing functions)

**Modified Functions:**
- `main()` - Added version flag parsing and display
- `step_setup_directory()` - Always cd into directory, even when resuming
- `step_create_composer_project()` - Temporarily move checkpoint file, verify directory
- `show_help()` - Added version flag documentation

### 🐛 Bugs Fixed

1. **Composer Error: "Project directory is not empty"**
   - **Cause:** Checkpoint file in directory prevented composer from running
   - **Fix:** Temporarily move checkpoint file before composer, restore after
   
2. **Wrong Directory During Composer Install**
   - **Cause:** When resuming, script didn't cd into project directory
   - **Fix:** Always cd into directory, even when step is marked complete

3. **No Way to Check Version**
   - **Fix:** Added `-v` flag

### 📊 Compatibility

- ✅ Fully backward compatible with v2.0.0
- ✅ All existing commands work unchanged
- ✅ Checkpoint files from v2.0.0 compatible

---

## Version 2.0.0 - November 2025

### 🎯 Major Features

#### Checkpoint System
- Save progress to `.cinstall_checkpoint`
- Resume interrupted installations
- Skip completed steps automatically

#### Existing Project Detection
- Detect existing DDEV projects
- Four options when existing project found:
  1. Resume installation
  2. Remove and start fresh
  3. Update only changed components
  4. Cancel

#### Smart Module Updates
- Detect workflow_assignment updates
- Uninstall → Update → Reinstall workflow
- Preserve data during updates

#### Composer Dependency Updates
- Check for outdated packages
- Interactive or automatic updates
- Run database updates after composer update

### 🔧 Technical Changes

**New Functions:**
- `mark_complete()` - Save step completion
- `is_complete()` - Check if step done
- `load_checkpoint()` - Load previous progress
- `check_existing_ddev_project()` - Find existing projects
- `check_for_updates()` - Check all components
- `check_workflow_assignment_update()` - Check specific module
- `check_composer_updates()` - Check dependencies
- `update_workflow_assignment()` - Update module safely

**Modified Functions:**
- All step functions to support checkpoint system
- Interactive mode integration throughout

### 📚 Documentation

- ENHANCED_FEATURES_GUIDE.md (~1200 lines)
- QUICK_REFERENCE.md (~400 lines)
- SUMMARY.md (~800 lines)
- CHANGELOG.md (~500 lines)

---

## Version 1.0.0 - Initial Release

### Features

- Basic installation automation
- Interactive mode
- GitHub token support
- DDEV configuration
- OpenSocial profile installation
- Demo content creation
- Step-by-step progress messages

### Limitations

- No resume capability
- No existing project detection
- No selective updates
- Had to reinstall everything for any change

---

## Version Comparison

| Feature | v1.0.0 | v2.0.0 | v2.1.0 |
|---------|--------|--------|--------|
| Basic installation | ✅ | ✅ | ✅ |
| Interactive mode | ✅ | ✅ | ✅ |
| GitHub token | ✅ | ✅ | ✅ |
| Checkpoint system | ❌ | ✅ | ✅ |
| Resume capability | ❌ | ✅ | ✅ |
| Existing project detection | ❌ | ✅ | ✅ |
| Module updates | ❌ | ✅ | ✅ |
| Composer updates | ❌ | ✅ | ✅ |
| Version flag | ❌ | ❌ | ✅ |
| Directory handling | Basic | Good | Excellent |
| Non-interactive mode | Prompts | Some prompts | No prompts |

---

## Upgrade Path

### From v1.0.0 to v2.1.0

1. **Backup your old script**
   ```bash
   cp cinstall.sh cinstall.sh.v1.0.0.backup
   ```

2. **Replace with new version**
   ```bash
   cp new_cinstall.sh cinstall.sh
   chmod +x cinstall.sh
   ```

3. **Verify version**
   ```bash
   ./cinstall.sh -v
   # Should show: cinstall.sh version 2.1.0
   ```

4. **Test with existing project**
   ```bash
   cd existing-project
   ../cinstall.sh
   # Will auto-detect and offer options
   ```

### From v2.0.0 to v2.1.0

Simply replace the script file. All checkpoint files are compatible.

```bash
cp new_cinstall.sh cinstall.sh
chmod +x cinstall.sh
./cinstall.sh -v
```

---

## Breaking Changes

### None! 🎉

All versions maintain backward compatibility:
- v2.0.0 → v2.1.0: No breaking changes
- v1.0.0 → v2.1.0: No breaking changes

All existing command patterns continue to work.

---

## Future Roadmap

### Potential v2.2.0 Features

- [ ] Automatic backup before updates
- [ ] Remote checkpoint sync
- [ ] Multiple module tracking
- [ ] Progress bar
- [ ] Email notifications
- [ ] Configuration profiles
- [ ] Rollback capability

### Potential v3.0.0 Features

- [ ] Plugin system
- [ ] Custom profiles
- [ ] Multi-site support
- [ ] Cloud deployment integration
- [ ] Advanced monitoring

---

## Checking Your Version

### Command Line
```bash
./cinstall.sh -v
```

### In Script Header
```bash
head -20 cinstall.sh | grep "Version:"
```

### During Installation
Version is shown in the header when script runs.

---

## Version Support

| Version | Status | Support |
|---------|--------|---------|
| v2.1.0 | Current | ✅ Full support |
| v2.0.0 | Previous | ✅ Bug fixes only |
| v1.0.0 | Legacy | ⚠️ Upgrade recommended |

---

## Changelog Format

This document follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version (X.0.0) - Incompatible changes
- **MINOR** version (0.X.0) - New features, backward compatible
- **PATCH** version (0.0.X) - Bug fixes, backward compatible

---

## Contributing

When making changes:
1. Update version number in script header
2. Update VERSION variable
3. Update this version history
4. Document all changes
5. Test thoroughly

---

## Questions?

- **What version am I running?** → `./cinstall.sh -v`
- **Should I upgrade?** → Yes, v2.1.0 has important fixes
- **Will my checkpoint work?** → Yes, fully compatible
- **Any breaking changes?** → No, everything works the same

---

**Current Version:** 2.1.0  
**Release Date:** November 2025  
**Status:** Stable  
**Next Version:** TBD
