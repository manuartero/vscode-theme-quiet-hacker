// Quiet Hacker - TypeScript Preview
interface Config {
  host: string;
  port: number;
  ssl: boolean;
  retries?: number;
}

type Result<T> = { ok: true; data: T } | { ok: false; error: string };

enum LogLevel {
  Debug = "DEBUG",
  Info = "INFO",
  Warn = "WARN",
  Error = "ERROR",
}

class Logger {
  private level: LogLevel;
  private prefix: string;

  constructor(prefix: string, level: LogLevel = LogLevel.Info) {
    this.prefix = prefix;
    this.level = level;
  }

  info(message: string, meta?: Record<string, unknown>): void {
    if (this.shouldLog(LogLevel.Info)) {
      console.log(`[${this.prefix}] ${message}`, meta ?? "");
    }
  }

  error(message: string, err?: Error): void {
    console.error(`[${this.prefix}] ERROR: ${message}`, err?.stack);
  }

  private shouldLog(level: LogLevel): boolean {
    const levels = Object.values(LogLevel);
    return levels.indexOf(level) >= levels.indexOf(this.level);
  }
}

async function fetchData<T>(url: string, config: Config): Promise<Result<T>> {
  const protocol = config.ssl ? "https" : "http";
  const fullUrl = `${protocol}://${config.host}:${config.port}${url}`;

  try {
    const response = await fetch(fullUrl);
    if (!response.ok) {
      return { ok: false, error: `HTTP ${response.status}` };
    }
    const data = (await response.json()) as T;
    return { ok: true, data };
  } catch (err) {
    return { ok: false, error: (err as Error).message };
  }
}

// Generics & utility types
type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

const defaults: DeepPartial<Config> = { ssl: true, retries: 3 };
const logger = new Logger("app", LogLevel.Debug);
logger.info("Starting", { config: defaults });
