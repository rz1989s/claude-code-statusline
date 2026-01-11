import * as vscode from 'vscode';
import { exec } from 'child_process';
import { promisify } from 'util';
import * as os from 'os';
import * as path from 'path';

const execAsync = promisify(exec);

// ============================================================================
// Types
// ============================================================================

interface StatuslineData {
  version: string;
  timestamp: number;
  repository: {
    name: string;
    branch: string;
    status: 'clean' | 'dirty';
    commits_today: number;
    path?: string;
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

// ============================================================================
// Global State
// ============================================================================

let statusBarItem: vscode.StatusBarItem;
let refreshInterval: NodeJS.Timeout | undefined;
let lastData: StatuslineData | null = null;
let outputChannel: vscode.OutputChannel;

// Tree data providers
let repositoryProvider: StatuslineTreeDataProvider;
let costProvider: StatuslineTreeDataProvider;
let mcpProvider: StatuslineTreeDataProvider;
let systemProvider: StatuslineTreeDataProvider;

// ============================================================================
// Tree Data Provider
// ============================================================================

class StatuslineTreeItem extends vscode.TreeItem {
  constructor(
    public readonly label: string,
    public readonly value: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState = vscode.TreeItemCollapsibleState.None,
    public readonly iconId?: string
  ) {
    super(label, collapsibleState);
    this.description = value;
    if (iconId) {
      this.iconPath = new vscode.ThemeIcon(iconId);
    }
  }
}

class StatuslineTreeDataProvider implements vscode.TreeDataProvider<StatuslineTreeItem> {
  private _onDidChangeTreeData: vscode.EventEmitter<StatuslineTreeItem | undefined | null | void> = new vscode.EventEmitter<StatuslineTreeItem | undefined | null | void>();
  readonly onDidChangeTreeData: vscode.Event<StatuslineTreeItem | undefined | null | void> = this._onDidChangeTreeData.event;

  private items: StatuslineTreeItem[] = [];

  refresh(): void {
    this._onDidChangeTreeData.fire();
  }

  setItems(items: StatuslineTreeItem[]): void {
    this.items = items;
    this.refresh();
  }

  getTreeItem(element: StatuslineTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(): Thenable<StatuslineTreeItem[]> {
    return Promise.resolve(this.items);
  }
}

// ============================================================================
// Activation
// ============================================================================

export function activate(context: vscode.ExtensionContext) {
  // Create output channel for debugging
  outputChannel = vscode.window.createOutputChannel('Claude Statusline');
  log('Extension activating...');

  // Create status bar item
  const config = vscode.workspace.getConfiguration('claudeStatusline');
  const position = config.get<string>('statusBarPosition', 'right');
  const priority = config.get<number>('statusBarPriority', 100);

  statusBarItem = vscode.window.createStatusBarItem(
    position === 'left' ? vscode.StatusBarAlignment.Left : vscode.StatusBarAlignment.Right,
    priority
  );
  statusBarItem.command = 'claude-statusline.show';
  statusBarItem.tooltip = 'Click to see Claude Code details';
  context.subscriptions.push(statusBarItem);

  // Initialize tree data providers
  repositoryProvider = new StatuslineTreeDataProvider();
  costProvider = new StatuslineTreeDataProvider();
  mcpProvider = new StatuslineTreeDataProvider();
  systemProvider = new StatuslineTreeDataProvider();

  // Register tree views
  context.subscriptions.push(
    vscode.window.registerTreeDataProvider('claudeStatuslineRepository', repositoryProvider),
    vscode.window.registerTreeDataProvider('claudeStatuslineCost', costProvider),
    vscode.window.registerTreeDataProvider('claudeStatuslineMcp', mcpProvider),
    vscode.window.registerTreeDataProvider('claudeStatuslineSystem', systemProvider)
  );

  // Register commands
  context.subscriptions.push(
    vscode.commands.registerCommand('claude-statusline.show', showDetails),
    vscode.commands.registerCommand('claude-statusline.refresh', () => {
      vscode.window.showInformationMessage('Refreshing Claude Statusline...');
      refresh();
    }),
    vscode.commands.registerCommand('claude-statusline.toggleStatusBar', toggleStatusBar)
  );

  // Start refresh loop
  startRefreshLoop();

  // Watch for config changes
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('claudeStatusline')) {
        log('Configuration changed, restarting refresh loop');
        startRefreshLoop();
      }
    })
  );

  log('Extension activated');
}

// ============================================================================
// Logging
// ============================================================================

function log(message: string): void {
  const timestamp = new Date().toISOString();
  outputChannel.appendLine(`[${timestamp}] ${message}`);
}

// ============================================================================
// Status Bar
// ============================================================================

function toggleStatusBar(): void {
  const config = vscode.workspace.getConfiguration('claudeStatusline');
  const current = config.get<boolean>('showStatusBar', true);
  config.update('showStatusBar', !current, vscode.ConfigurationTarget.Global);
  vscode.window.showInformationMessage(`Status bar ${!current ? 'enabled' : 'disabled'}`);
}

function startRefreshLoop(): void {
  if (refreshInterval) {
    clearInterval(refreshInterval);
  }

  const config = vscode.workspace.getConfiguration('claudeStatusline');
  const interval = config.get<number>('refreshInterval', 5000);

  log(`Starting refresh loop with ${interval}ms interval`);
  refresh();
  refreshInterval = setInterval(refresh, interval);
}

async function refresh(): Promise<void> {
  try {
    const data = await fetchStatusline();
    lastData = data;
    updateStatusBar(data);
    updateTreeViews(data);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    log(`Fetch error: ${errorMessage}`);

    statusBarItem.text = '$(warning) Claude: Error';
    statusBarItem.tooltip = `Error: ${errorMessage}\nClick to see details`;

    const config = vscode.workspace.getConfiguration('claudeStatusline');
    if (config.get<boolean>('showStatusBar', true)) {
      statusBarItem.show();
    }
  }
}

// ============================================================================
// Data Fetching
// ============================================================================

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

  log(`Fetching from: ${scriptPath}`);

  const { stdout, stderr } = await execAsync(`"${scriptPath}" --json`, {
    timeout: 10000,
    maxBuffer: 1024 * 1024
  });

  if (stderr) {
    log(`Script stderr: ${stderr}`);
  }

  const data = JSON.parse(stdout);
  log(`Fetched data for: ${data.repository?.name || 'unknown'}`);
  return data;
}

// ============================================================================
// Status Bar Update
// ============================================================================

function updateStatusBar(data: StatuslineData): void {
  const config = vscode.workspace.getConfiguration('claudeStatusline');

  if (!config.get<boolean>('showStatusBar', true)) {
    statusBarItem.hide();
    return;
  }

  const parts: string[] = [];

  // Repository info
  if (config.get<boolean>('showRepo', true)) {
    const statusIcon = data.repository.status === 'clean' ? '$(check)' : '$(edit)';
    parts.push(`${statusIcon} ${data.repository.name}`);
  }

  // Cost
  if (config.get<boolean>('showCost', true) && data.cost.session > 0) {
    parts.push(`$(credit-card) $${data.cost.session.toFixed(2)}`);
  }

  // MCP
  if (config.get<boolean>('showMcp', true) && data.mcp.total > 0) {
    parts.push(`$(server) ${data.mcp.connected}/${data.mcp.total}`);
  }

  statusBarItem.text = parts.length > 0 ? parts.join(' | ') : '$(robot) Claude';
  statusBarItem.tooltip = createTooltip(data);
  statusBarItem.show();
}

function createTooltip(data: StatuslineData): vscode.MarkdownString {
  const md = new vscode.MarkdownString();
  md.isTrusted = true;
  md.supportHtml = true;

  md.appendMarkdown(`## Claude Code Statusline v${data.version}\n\n`);
  md.appendMarkdown(`**Repository:** ${data.repository.name}\n\n`);
  md.appendMarkdown(`**Branch:** ${data.repository.branch}\n\n`);
  md.appendMarkdown(`**Status:** ${data.repository.status === 'clean' ? '✅ Clean' : '⚠️ Dirty'}\n\n`);
  md.appendMarkdown(`---\n\n`);
  md.appendMarkdown(`**Session Cost:** $${data.cost.session.toFixed(2)}\n\n`);
  md.appendMarkdown(`**Daily Cost:** $${data.cost.daily.toFixed(2)}\n\n`);

  if (data.mcp.total > 0) {
    md.appendMarkdown(`---\n\n`);
    md.appendMarkdown(`**MCP Servers:** ${data.mcp.connected}/${data.mcp.total}\n\n`);
  }

  md.appendMarkdown(`\n\n*Click for details*`);

  return md;
}

// ============================================================================
// Tree View Updates
// ============================================================================

function updateTreeViews(data: StatuslineData): void {
  // Repository section
  const repoItems: StatuslineTreeItem[] = [
    new StatuslineTreeItem('Name', data.repository.name, vscode.TreeItemCollapsibleState.None, 'repo'),
    new StatuslineTreeItem('Branch', data.repository.branch, vscode.TreeItemCollapsibleState.None, 'git-branch'),
    new StatuslineTreeItem('Status', data.repository.status, vscode.TreeItemCollapsibleState.None,
      data.repository.status === 'clean' ? 'check' : 'edit'),
    new StatuslineTreeItem('Commits Today', String(data.repository.commits_today), vscode.TreeItemCollapsibleState.None, 'git-commit'),
  ];

  // Add GitHub info if available
  if (data.github?.enabled) {
    repoItems.push(
      new StatuslineTreeItem('CI Status', data.github.ci_status || 'N/A', vscode.TreeItemCollapsibleState.None, 'testing-passed-icon'),
      new StatuslineTreeItem('Open PRs', String(data.github.open_prs || 0), vscode.TreeItemCollapsibleState.None, 'git-pull-request')
    );
  }

  repositoryProvider.setItems(repoItems);

  // Cost section
  costProvider.setItems([
    new StatuslineTreeItem('Session', `$${data.cost.session.toFixed(2)}`, vscode.TreeItemCollapsibleState.None, 'credit-card'),
    new StatuslineTreeItem('Daily', `$${data.cost.daily.toFixed(2)}`, vscode.TreeItemCollapsibleState.None, 'calendar'),
    new StatuslineTreeItem('Weekly', `$${data.cost.weekly.toFixed(2)}`, vscode.TreeItemCollapsibleState.None, 'calendar'),
    new StatuslineTreeItem('Monthly', `$${data.cost.monthly.toFixed(2)}`, vscode.TreeItemCollapsibleState.None, 'calendar'),
  ]);

  // MCP section
  const mcpItems: StatuslineTreeItem[] = [
    new StatuslineTreeItem('Connected', `${data.mcp.connected}/${data.mcp.total}`, vscode.TreeItemCollapsibleState.None, 'server'),
  ];

  for (const server of data.mcp.servers) {
    mcpItems.push(new StatuslineTreeItem(server, '', vscode.TreeItemCollapsibleState.None, 'server-process'));
  }

  mcpProvider.setItems(mcpItems);

  // System section
  systemProvider.setItems([
    new StatuslineTreeItem('Theme', data.system.theme, vscode.TreeItemCollapsibleState.None, 'symbol-color'),
    new StatuslineTreeItem('Platform', data.system.platform, vscode.TreeItemCollapsibleState.None, 'device-desktop'),
    new StatuslineTreeItem('Modules', String(data.system.modules_loaded), vscode.TreeItemCollapsibleState.None, 'extensions'),
  ]);
}

// ============================================================================
// Webview Panel
// ============================================================================

async function showDetails(): Promise<void> {
  if (!lastData) {
    vscode.window.showInformationMessage('No Claude Code data available yet. Fetching...');
    await refresh();
    if (!lastData) {
      vscode.window.showErrorMessage('Could not fetch Claude Code data');
      return;
    }
  }

  const panel = vscode.window.createWebviewPanel(
    'claudeStatusline',
    'Claude Code Statusline',
    vscode.ViewColumn.One,
    {
      enableScripts: true,
      retainContextWhenHidden: true
    }
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
    :root {
      --section-bg: var(--vscode-sideBar-background, #252526);
      --border-color: var(--vscode-panel-border, #3c3c3c);
      --text-muted: var(--vscode-descriptionForeground, #8b8b8b);
      --accent: var(--vscode-textLink-foreground, #4fc1ff);
      --success: #4caf50;
      --warning: #ff9800;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: var(--vscode-font-family, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif);
      font-size: var(--vscode-font-size, 13px);
      padding: 24px;
      color: var(--vscode-foreground, #cccccc);
      background-color: var(--vscode-editor-background, #1e1e1e);
      line-height: 1.5;
    }

    .header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 24px;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--border-color);
    }

    .header-icon {
      font-size: 32px;
    }

    .header-text h1 {
      font-size: 20px;
      font-weight: 600;
      margin-bottom: 4px;
    }

    .header-text .version {
      color: var(--text-muted);
      font-size: 12px;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 16px;
    }

    .section {
      background-color: var(--section-bg);
      border-radius: 8px;
      padding: 16px;
      border: 1px solid var(--border-color);
    }

    .section-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      font-weight: 600;
      color: var(--accent);
      margin-bottom: 12px;
      padding-bottom: 8px;
      border-bottom: 1px solid var(--border-color);
    }

    .metric {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 0;
      border-bottom: 1px solid var(--border-color);
    }

    .metric:last-child {
      border-bottom: none;
    }

    .metric-label {
      color: var(--text-muted);
    }

    .metric-value {
      font-weight: 500;
      font-family: var(--vscode-editor-font-family, 'Consolas', monospace);
    }

    .status-clean { color: var(--success); }
    .status-dirty { color: var(--warning); }

    .server-list {
      margin-top: 8px;
    }

    .server-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 6px 8px;
      background: var(--vscode-editor-background);
      border-radius: 4px;
      margin-top: 4px;
      font-size: 12px;
    }

    .server-dot {
      width: 8px;
      height: 8px;
      background: var(--success);
      border-radius: 50%;
    }

    .footer {
      margin-top: 24px;
      padding-top: 16px;
      border-top: 1px solid var(--border-color);
      color: var(--text-muted);
      font-size: 12px;
      text-align: center;
    }

    @media (max-width: 600px) {
      body {
        padding: 16px;
      }

      .grid {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <div class="header">
    <span class="header-icon">🤖</span>
    <div class="header-text">
      <h1>Claude Code Statusline</h1>
      <span class="version">v${data.version} • ${data.system.platform}</span>
    </div>
  </div>

  <div class="grid">
    <div class="section">
      <div class="section-title">
        <span>📁</span>
        <span>Repository</span>
      </div>
      <div class="metric">
        <span class="metric-label">Name</span>
        <span class="metric-value">${data.repository.name}</span>
      </div>
      <div class="metric">
        <span class="metric-label">Branch</span>
        <span class="metric-value">${data.repository.branch}</span>
      </div>
      <div class="metric">
        <span class="metric-label">Status</span>
        <span class="metric-value status-${data.repository.status}">
          ${data.repository.status === 'clean' ? '✓ Clean' : '● Dirty'}
        </span>
      </div>
      <div class="metric">
        <span class="metric-label">Commits Today</span>
        <span class="metric-value">${data.repository.commits_today}</span>
      </div>
    </div>

    <div class="section">
      <div class="section-title">
        <span>💰</span>
        <span>Cost</span>
      </div>
      <div class="metric">
        <span class="metric-label">Session</span>
        <span class="metric-value">$${data.cost.session.toFixed(2)}</span>
      </div>
      <div class="metric">
        <span class="metric-label">Daily</span>
        <span class="metric-value">$${data.cost.daily.toFixed(2)}</span>
      </div>
      <div class="metric">
        <span class="metric-label">Weekly</span>
        <span class="metric-value">$${data.cost.weekly.toFixed(2)}</span>
      </div>
      <div class="metric">
        <span class="metric-label">Monthly</span>
        <span class="metric-value">$${data.cost.monthly.toFixed(2)}</span>
      </div>
    </div>

    <div class="section">
      <div class="section-title">
        <span>⚡</span>
        <span>MCP Servers</span>
      </div>
      <div class="metric">
        <span class="metric-label">Connected</span>
        <span class="metric-value">${data.mcp.connected} / ${data.mcp.total}</span>
      </div>
      ${data.mcp.servers.length > 0 ? `
      <div class="server-list">
        ${data.mcp.servers.map(server => `
          <div class="server-item">
            <span class="server-dot"></span>
            <span>${server}</span>
          </div>
        `).join('')}
      </div>
      ` : ''}
    </div>

    ${data.github?.enabled ? `
    <div class="section">
      <div class="section-title">
        <span>🐙</span>
        <span>GitHub</span>
      </div>
      <div class="metric">
        <span class="metric-label">CI Status</span>
        <span class="metric-value">${data.github.ci_status || 'N/A'}</span>
      </div>
      <div class="metric">
        <span class="metric-label">Open PRs</span>
        <span class="metric-value">${data.github.open_prs || 0}</span>
      </div>
    </div>
    ` : ''}

    <div class="section">
      <div class="section-title">
        <span>⚙️</span>
        <span>System</span>
      </div>
      <div class="metric">
        <span class="metric-label">Theme</span>
        <span class="metric-value">${data.system.theme}</span>
      </div>
      <div class="metric">
        <span class="metric-label">Platform</span>
        <span class="metric-value">${data.system.platform}</span>
      </div>
      <div class="metric">
        <span class="metric-label">Modules Loaded</span>
        <span class="metric-value">${data.system.modules_loaded}</span>
      </div>
    </div>
  </div>

  <div class="footer">
    Last updated: ${new Date(data.timestamp * 1000).toLocaleString()}
  </div>
</body>
</html>`;
}

// ============================================================================
// Deactivation
// ============================================================================

export function deactivate(): void {
  log('Extension deactivating...');
  if (refreshInterval) {
    clearInterval(refreshInterval);
  }
}
