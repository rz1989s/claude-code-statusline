import * as vscode from 'vscode';
import { exec } from 'child_process';
import { promisify } from 'util';
import * as os from 'os';
import * as path from 'path';

const execAsync = promisify(exec);

interface StatuslineData {
  version: string;
  timestamp: number;
  repository: {
    name: string;
    branch: string;
    status: 'clean' | 'dirty';
    commits_today: number;
  };
  cost: {
    session: number;
    daily: number;
    weekly: number;
    monthly: number;
  };
  mcp: {
    connected: number;
    total: number;
    servers: string[];
  };
  github?: {
    enabled: boolean;
    ci_status?: string;
    open_prs?: number;
  };
  system: {
    theme: string;
    modules_loaded: number;
    platform: string;
  };
}

let statusBarItem: vscode.StatusBarItem;
let refreshInterval: NodeJS.Timeout | undefined;
let lastData: StatuslineData | null = null;

export function activate(context: vscode.ExtensionContext) {
  // Create status bar item
  statusBarItem = vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Right,
    100
  );
  statusBarItem.command = 'claude-statusline.show';
  statusBarItem.tooltip = 'Click to see Claude Code details';
  context.subscriptions.push(statusBarItem);

  // Register commands
  context.subscriptions.push(
    vscode.commands.registerCommand('claude-statusline.show', showDetails),
    vscode.commands.registerCommand('claude-statusline.refresh', refresh)
  );

  // Start refresh loop
  startRefreshLoop();

  // Watch for config changes
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('claudeStatusline')) {
        startRefreshLoop();
      }
    })
  );
}

function startRefreshLoop() {
  if (refreshInterval) {
    clearInterval(refreshInterval);
  }

  const config = vscode.workspace.getConfiguration('claudeStatusline');
  const interval = config.get<number>('refreshInterval', 5000);

  refresh();
  refreshInterval = setInterval(refresh, interval);
}

async function refresh() {
  try {
    const data = await fetchStatusline();
    lastData = data;
    updateStatusBar(data);
  } catch (error) {
    statusBarItem.text = '$(warning) Claude: Error';
    statusBarItem.show();
  }
}

async function fetchStatusline(): Promise<StatuslineData> {
  const config = vscode.workspace.getConfiguration('claudeStatusline');
  let scriptPath = config.get<string>(
    'statuslinePath',
    '~/.claude/statusline/statusline.sh'
  );

  // Expand ~ to home directory
  if (scriptPath.startsWith('~')) {
    scriptPath = path.join(os.homedir(), scriptPath.slice(1));
  }

  const { stdout } = await execAsync(`"${scriptPath}" --json`);
  return JSON.parse(stdout);
}

function updateStatusBar(data: StatuslineData) {
  const config = vscode.workspace.getConfiguration('claudeStatusline');
  const parts: string[] = [];

  // Repository info
  const statusIcon = data.repository.status === 'clean' ? '$(check)' : '$(edit)';
  parts.push(`${statusIcon} ${data.repository.name}`);

  // Cost
  if (config.get<boolean>('showCost', true)) {
    parts.push(`$(credit-card) $${data.cost.session.toFixed(2)}`);
  }

  // MCP
  if (config.get<boolean>('showMcp', true) && data.mcp.total > 0) {
    parts.push(`$(server) ${data.mcp.connected}/${data.mcp.total}`);
  }

  statusBarItem.text = parts.join(' | ');
  statusBarItem.show();
}

async function showDetails() {
  if (!lastData) {
    vscode.window.showInformationMessage('No Claude Code data available yet');
    return;
  }

  const panel = vscode.window.createWebviewPanel(
    'claudeStatusline',
    'Claude Code Statusline',
    vscode.ViewColumn.One,
    {}
  );

  panel.webview.html = getWebviewContent(lastData);
}

function getWebviewContent(data: StatuslineData): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Claude Code Statusline</title>
  <style>
    body {
      font-family: var(--vscode-font-family);
      padding: 20px;
      color: var(--vscode-foreground);
      background-color: var(--vscode-editor-background);
    }
    .section {
      margin-bottom: 20px;
      padding: 15px;
      border-radius: 8px;
      background-color: var(--vscode-sideBar-background);
    }
    h2 {
      margin-top: 0;
      color: var(--vscode-textLink-foreground);
    }
    .metric {
      display: flex;
      justify-content: space-between;
      padding: 5px 0;
    }
    .value {
      font-weight: bold;
    }
    .status-clean { color: #4caf50; }
    .status-dirty { color: #ff9800; }
  </style>
</head>
<body>
  <h1>Claude Code Statusline v${data.version}</h1>

  <div class="section">
    <h2>Repository</h2>
    <div class="metric">
      <span>Name</span>
      <span class="value">${data.repository.name}</span>
    </div>
    <div class="metric">
      <span>Branch</span>
      <span class="value">${data.repository.branch}</span>
    </div>
    <div class="metric">
      <span>Status</span>
      <span class="value status-${data.repository.status}">${data.repository.status}</span>
    </div>
    <div class="metric">
      <span>Commits Today</span>
      <span class="value">${data.repository.commits_today}</span>
    </div>
  </div>

  <div class="section">
    <h2>Cost</h2>
    <div class="metric">
      <span>Session</span>
      <span class="value">$${data.cost.session.toFixed(2)}</span>
    </div>
    <div class="metric">
      <span>Daily</span>
      <span class="value">$${data.cost.daily.toFixed(2)}</span>
    </div>
    <div class="metric">
      <span>Weekly</span>
      <span class="value">$${data.cost.weekly.toFixed(2)}</span>
    </div>
    <div class="metric">
      <span>Monthly</span>
      <span class="value">$${data.cost.monthly.toFixed(2)}</span>
    </div>
  </div>

  <div class="section">
    <h2>MCP Servers</h2>
    <div class="metric">
      <span>Connected</span>
      <span class="value">${data.mcp.connected} / ${data.mcp.total}</span>
    </div>
    <div class="metric">
      <span>Servers</span>
      <span class="value">${data.mcp.servers.join(', ') || 'None'}</span>
    </div>
  </div>

  <div class="section">
    <h2>System</h2>
    <div class="metric">
      <span>Theme</span>
      <span class="value">${data.system.theme}</span>
    </div>
    <div class="metric">
      <span>Platform</span>
      <span class="value">${data.system.platform}</span>
    </div>
    <div class="metric">
      <span>Modules Loaded</span>
      <span class="value">${data.system.modules_loaded}</span>
    </div>
  </div>

  <p style="opacity: 0.6; font-size: 12px;">
    Last updated: ${new Date(data.timestamp * 1000).toLocaleString()}
  </p>
</body>
</html>`;
}

export function deactivate() {
  if (refreshInterval) {
    clearInterval(refreshInterval);
  }
}
