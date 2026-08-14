// components/ErrorToast.js
"use client";

import { useEffect } from "react";
import { useRoom } from "../context/RoomProvider";

export function ErrorToast() {
  const { errorMessage, dismissError } = useRoom();

  useEffect(() => {
    if (!errorMessage) return;
    const timer = setTimeout(dismissError, 5000);
    return () => clearTimeout(timer);
  }, [errorMessage, dismissError]);

  if (!errorMessage) return null;

  return (
    <div
      style={{
        position: "fixed",
        bottom: "24px",
        left: "50%",
        transform: "translateX(-50%)",
        background: "#dc2626",
        color: "white",
        padding: "12px 20px",
        borderRadius: "8px",
        display: "flex",
        alignItems: "center",
        gap: "12px",
        boxShadow: "0 4px 12px rgba(0,0,0,0.2)",
        zIndex: 1000,
      }}
    >
      <span>{errorMessage}</span>
      <button
        onClick={dismissError}
        style={{ background: "none", border: "none", color: "white", cursor: "pointer", fontWeight: "bold" }}
      >
        ✕
      </button>
    </div>
  );
}