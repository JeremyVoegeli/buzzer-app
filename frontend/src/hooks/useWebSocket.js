"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export function useWebSocket(url, onMessage) {
  const [status, setStatus] = useState("connecting"); // "connecting" | "open" | "closed"
  const wsRef = useRef(null);

  const onMessageRef = useRef(onMessage);
  useEffect(() => {
    onMessageRef.current = onMessage;
  }, [onMessage]);

  useEffect(() => {
    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen = () => setStatus("open");
    ws.onclose = () => setStatus("closed");
    ws.onerror = (err) => {
      if (wsRef.current === ws){ //avoids strict-mode only error when launching site
        console.error("Websocket error: ", err)
      }
    }

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