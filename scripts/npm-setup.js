#!/usr/bin/env node

/**
 * Claude Code Statusline - npm Post-Install Setup
 *
 * This script runs after npm install to:
 * 1. Create the installation directory
 * 2. Copy default configuration
 * 3. Set up Claude Code integration (settings.json)
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// Configuration
const homeDir = os.homedir();
const installDir = path.join(homeDir, '.claude', 'statusline');
const packageRoot = path.resolve(__dirname, '..');

// Claude Code settings paths (cross-platform)
const claudeSettingsPaths = [
  path.join(homeDir, '.claude', 'settings.json'),           // Primary
  path.join(homeDir, '.config', 'claude', 'settings.json'), // XDG
];

console.log('Claude Code Statusline - npm Setup');
console.log('===================================');
console.log('');

// Step 1: Create installation directory
console.log('1. Creating installation directory...');
try {
  fs.mkdirSync(installDir, { recursive: true });
  console.log(`   Created: ${installDir}`);
} catch (err) {
  if (err.code !== 'EEXIST') {
    console.error(`   Error: ${err.message}`);
  }
}

// Step 2: Copy configuration file if not exists
console.log('2. Setting up configuration...');
const configSource = path.join(packageRoot, 'examples', 'Config.toml');
const configDest = path.join(installDir, 'Config.toml');

if (!fs.existsSync(configDest)) {
  try {
    fs.copyFileSync(configSource, configDest);
    console.log(`   Copied default config to: ${configDest}`);
  } catch (err) {
    console.error(`   Error copying config: ${err.message}`);
    console.log(`   You can manually copy from: ${configSource}`);
  }
} else {
  console.log('   Config already exists, skipping.');
}

// Step 3: Create symlink to statusline.sh for Claude Code
console.log('3. Creating statusline symlink...');
const statuslineSource = path.join(packageRoot, 'statusline.sh');
const statuslineDest = path.join(installDir, 'statusline.sh');

try {
  // Remove existing symlink if present
  if (fs.existsSync(statuslineDest)) {
    const stats = fs.lstatSync(statuslineDest);
    if (stats.isSymbolicLink()) {
      fs.unlinkSync(statuslineDest);
    }
  }

  // Create new symlink
  fs.symlinkSync(statuslineSource, statuslineDest);
  console.log(`   Linked: ${statuslineDest} -> ${statuslineSource}`);
} catch (err) {
  console.error(`   Error creating symlink: ${err.message}`);
  console.log('   You may need to run with elevated permissions.');
}

// Step 4: Display Claude Code integration instructions
console.log('4. Claude Code Integration...');
console.log('');
console.log('   To enable the statusline in Claude Code, add to your settings.json:');
console.log('');
console.log('   {');
console.log('     "env": {');
console.log(`       "CLAUDE_CODE_STATUSLINE": "${statuslineDest}"`);
console.log('     }');
console.log('   }');
console.log('');
console.log('   Settings location:');
claudeSettingsPaths.forEach((p) => {
  const exists = fs.existsSync(p);
  console.log(`     ${exists ? '✓' : '○'} ${p}`);
});

// Step 5: Verify installation
console.log('');
console.log('5. Verifying installation...');
const checks = [
  { name: 'statusline.sh', path: statuslineSource },
  { name: 'Config.toml', path: configDest },
  { name: 'lib/', path: path.join(packageRoot, 'lib') },
];

let allPassed = true;
checks.forEach(({ name, path: checkPath }) => {
  const exists = fs.existsSync(checkPath);
  console.log(`   ${exists ? '✓' : '✗'} ${name}`);
  if (!exists) allPassed = false;
});

console.log('');
if (allPassed) {
  console.log('Setup complete! Run `claude-statusline --help` for usage.');
} else {
  console.log('Setup completed with warnings. Some files may be missing.');
}
console.log('');
