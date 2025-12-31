#!/usr/bin/env node

/**
 * Claude Code Statusline - CLI Wrapper
 *
 * This is the npm entry point that delegates to the bash statusline script.
 * It handles cross-platform execution and provides a familiar npm interface.
 *
 * Usage:
 *   npx claude-code-statusline [options]
 *   claude-statusline [options]
 */

const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// Get the statusline script path
const packageRoot = path.resolve(__dirname, '..');
const statuslineScript = path.join(packageRoot, 'statusline.sh');

// Installation directory (where config lives)
const installDir = path.join(os.homedir(), '.claude', 'statusline');

// Parse command line arguments
const args = process.argv.slice(2);

// Handle special npm-specific commands
if (args.includes('--npm-info')) {
  const pkg = require('../package.json');
  console.log(`claude-code-statusline v${pkg.version}`);
  console.log(`Package root: ${packageRoot}`);
  console.log(`Install dir: ${installDir}`);
  console.log(`Script: ${statuslineScript}`);
  process.exit(0);
}

if (args.includes('--npm-setup')) {
  // Run setup manually
  require('./npm-setup');
  process.exit(0);
}

// Ensure statusline script exists
if (!fs.existsSync(statuslineScript)) {
  console.error('Error: statusline.sh not found at:', statuslineScript);
  console.error('The package may not be installed correctly.');
  console.error('Try reinstalling: npm install -g claude-code-statusline');
  process.exit(1);
}

// Determine bash executable
let bashPath = '/bin/bash';

// On macOS, try to use Homebrew bash for better compatibility
if (process.platform === 'darwin') {
  const homebrewBash = '/opt/homebrew/bin/bash';
  const usrLocalBash = '/usr/local/bin/bash';

  if (fs.existsSync(homebrewBash)) {
    bashPath = homebrewBash;
  } else if (fs.existsSync(usrLocalBash)) {
    bashPath = usrLocalBash;
  }
}

// Execute the statusline script
const child = spawn(bashPath, [statuslineScript, ...args], {
  stdio: 'inherit',
  env: {
    ...process.env,
    // Pass npm package info to the script
    NPM_PACKAGE_ROOT: packageRoot,
    NPM_PACKAGE_VERSION: require('../package.json').version,
  },
});

child.on('error', (err) => {
  console.error('Failed to execute statusline:', err.message);
  process.exit(1);
});

child.on('exit', (code) => {
  process.exit(code || 0);
});
