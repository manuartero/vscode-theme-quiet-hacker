// Quiet Hacker - JavaScript Preview
import { EventEmitter } from "events";

const MAX_RETRIES = 3;
const API_URL = "https://api.example.com/v2";

class ConnectionPool extends EventEmitter {
  #connections = new Map();
  #active = 0;

  constructor(options = {}) {
    super();
    this.maxSize = options.maxSize ?? 10;
    this.timeout = options.timeout ?? 5000;
  }

  async acquire(key) {
    if (this.#connections.has(key)) {
      return this.#connections.get(key);
    }

    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
      try {
        const conn = await this.#createConnection(key);
        this.#connections.set(key, conn);
        this.#active++;
        this.emit("acquired", { key, active: this.#active });
        return conn;
      } catch (err) {
        if (attempt === MAX_RETRIES - 1) throw err;
      }
    }
  }

  async #createConnection(key) {
    const response = await fetch(`${API_URL}/connect?key=${key}`, {
      signal: AbortSignal.timeout(this.timeout),
    });
    return response.json();
  }

  release(key) {
    const conn = this.#connections.get(key);
    if (!conn) return false;
    this.#connections.delete(key);
    this.#active--;
    this.emit("released", { key, remaining: this.#active });
    return true;
  }

  get size() {
    return this.#connections.size;
  }
}

// Usage
const pool = new ConnectionPool({ maxSize: 5 });
pool.on("acquired", ({ key }) => console.log(`Connected: ${key}`));

const data = await pool.acquire("main-db");
console.log(data?.status ?? "unknown");
