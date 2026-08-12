"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useRoom } from "../context/RoomProvider";

export default function HomePage() {
  const router = useRouter();
  const { status, roomId, createRoom, joinRoom } = useRoom();
  const [username, setUsername] = useState("");
  const [joinCode, setJoinCode] = useState("");
  const [mode, setMode] = useState("create"); // "create" | "join"

  const canSubmit = status === "open" && username.trim().length > 0 && (mode === "create" || joinCode.trim().length === 6);

  function handleSubmit(e) {
    e.preventDefault();
    if (!canSubmit) return;
    if (mode === "create") {
      createRoom(username.trim());
    } else {
      joinRoom(username.trim(), joinCode.trim().toUpperCase());
    }
  }

  // Once the backend confirms room_id, move to the game screen.
  if (roomId) {
    router.push("/room");
  }

  return (
    <main className="min-h-screen bg-[#121218] text-[#F4F2ED] flex flex-col items-center justify-center px-6">
      <div className="w-full max-w-sm">
        <h1 className="font-['Archivo_Black',_sans-serif] text-5xl tracking-tight text-center mb-2">
          BUZZ<span className="text-[#FF4438]">IN</span>
        </h1>
        <p className="text-center text-[#8A8DA8] text-sm mb-10">
          {status === "open" ? "Ready to play" : "Connecting..."}
        </p>

        <div className="flex mb-6 rounded-full bg-[#22222C] p-1">
          <button
            type="button"
            onClick={() => setMode("create")}
            className={`flex-1 py-2 rounded-full text-sm font-semibold transition-colors ${
              mode === "create" ? "bg-[#FFB627] text-[#121218]" : "text-[#8A8DA8]"
            }`}
          >
            Host a room
          </button>
          <button
            type="button"
            onClick={() => setMode("join")}
            className={`flex-1 py-2 rounded-full text-sm font-semibold transition-colors ${
              mode === "join" ? "bg-[#FF4438] text-[#F4F2ED]" : "text-[#8A8DA8]"
            }`}
          >
            Join a room
          </button>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div>
            <label className="block text-xs uppercase tracking-wide text-[#8A8DA8] mb-1">
              Your name
            </label>
            <input
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="What should we call you?"
              maxLength={24}
              className="w-full bg-[#22222C] rounded-lg px-4 py-3 text-[#F4F2ED] placeholder-[#8A8DA8]/60 outline-none focus:ring-2 focus:ring-[#FFB627]"
            />
          </div>

          {mode === "join" && (
            <div>
              <label className="block text-xs uppercase tracking-wide text-[#8A8DA8] mb-1">
                Room code
              </label>
              <input
                value={joinCode}
                onChange={(e) => setJoinCode(e.target.value.toUpperCase().slice(0, 6))}
                placeholder="ABCDEF"
                className="w-full bg-[#22222C] rounded-lg px-4 py-3 font-['Archivo_Black',_sans-serif] tracking-[0.3em] text-center text-2xl text-[#F4F2ED] placeholder-[#8A8DA8]/40 outline-none focus:ring-2 focus:ring-[#FF4438]"
              />
            </div>
          )}

          <button
            type="submit"
            disabled={!canSubmit}
            className="mt-2 w-full py-4 rounded-lg font-bold text-lg bg-[#FF4438] text-[#F4F2ED] disabled:opacity-40 disabled:cursor-not-allowed transition-opacity"
          >
            {mode === "create" ? "Create room" : "Join room"}
          </button>
        </form>
      </div>
    </main>
  );
}