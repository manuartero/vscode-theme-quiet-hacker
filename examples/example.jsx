// Quiet Hacker - React/JSX Preview
import { useState, useEffect, useCallback, memo } from "react";

const API_URL = "https://api.example.com";
const REFRESH_INTERVAL = 30_000;

function usePolling(url, interval = REFRESH_INTERVAL) {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const fetchData = useCallback(async () => {
    try {
      const res = await fetch(url);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();
      setData(json);
      setError(null);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [url]);

  useEffect(() => {
    fetchData();
    const id = setInterval(fetchData, interval);
    return () => clearInterval(id);
  }, [fetchData, interval]);

  return { data, error, loading, refetch: fetchData };
}

const StatusBadge = memo(function StatusBadge({ status }) {
  const colors = {
    online: "var(--green)",
    offline: "var(--grey)",
    error: "var(--green-dark)",
  };

  return (
    <span
      className="badge"
      style={{
        color: colors[status] ?? colors.offline,
        border: `1px solid ${colors[status] ?? colors.offline}`,
        padding: "2px 8px",
        borderRadius: "4px",
        fontSize: "0.75rem",
      }}
    >
      {status}
    </span>
  );
});

function NodeList({ nodes, onSelect }) {
  if (!nodes?.length) {
    return <p className="empty">No nodes connected.</p>;
  }

  return (
    <ul className="node-list">
      {nodes.map((node) => (
        <li key={node.id} className="node-list__item">
          <button onClick={() => onSelect(node.id)}>
            <span className="node-name">{node.name}</span>
            <StatusBadge status={node.status} />
            <span className="node-latency">{node.latency}ms</span>
          </button>
        </li>
      ))}
    </ul>
  );
}

export default function Dashboard() {
  const { data, error, loading } = usePolling(`${API_URL}/nodes`);
  const [selected, setSelected] = useState(null);

  if (loading) return <div className="loading">Connecting...</div>;
  if (error) return <div className="error">Error: {error}</div>;

  return (
    <main className="dashboard">
      <header>
        <h1>Network Monitor</h1>
        <span>{data?.nodes?.length ?? 0} nodes</span>
      </header>
      <NodeList nodes={data?.nodes} onSelect={setSelected} />
      {selected && <p>Selected: {selected}</p>}
    </main>
  );
}
