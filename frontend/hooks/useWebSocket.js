"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export function useWebSocket(url, onMessage) {
  const [status, setStatus] = useState("connecting"); // "connecting" | "open" | "closed"
  const wsRef = useRef(null);

  // Keep the latest onMessage in a ref so the socket's event listener
  // always calls the newest version, without needing to reconnect
  // every time a parent component re-renders with a new callback.
  const onMessageRef = useRef(onMessage);
  useEffect(() => {
    onMessageRef.current = onMessage;
  }, [onMessage]);

  useEffect(() => {
    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen = () => setStatus("open");
    ws.onclose = () => setStatus("closed");
    ws.onerror = (err) => console.error("WebSocket error:", err);

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        onMessageRef.current(data);
      } catch (err) {
        console.error("Failed to parse WebSocket message:", event.data, err);
      }
    };

    return () => {
      ws.close();
    };
  }, [url]);

  const send = useCallback((payload) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(payload));
    } else {
      console.warn("Tried to send while socket was not open:", payload);
    }
  }, []);

  return { status, send };
}