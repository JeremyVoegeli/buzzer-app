"use client";

import { useEffect, useState } from "react";
import { useRoom } from "../../context/RoomProvider";

export default function RoomPage() {
  const { roomId, username, isHost, participants, winner, didIWin, status, buzz, clearBuzzes, leaveRoom } =
    useRoom();
  const [flash, setFlash] = useState(false);

  // Trigger the full-screen flash any time a new winner comes in.
  useEffect(() => {
    if (!winner) return;
    setFlash(true);
    const t = setTimeout(() => setFlash(false), 600);
    return () => clearTimeout(t);
  }, [winner]);

  const buzzerLocked = winner !== null;

  return (
    <main className="min-h-screen bg-[#121218] text-[#F4F2ED] flex flex-col items-center px-6 py-8 relative overflow-hidden">
      {/* Signature moment: full-bleed color flash when someone buzzes */}
      <div
        className={`pointer-events-none fixed inset-0 transition-opacity duration-500 ${
          flash ? "opacity-100" : "opacity-0"
        }`}
        style={{ backgroundColor: didIWin ? "#FFB627" : "#FF4438" }}
      />

      <div className="relative z-10 w-full max-w-md flex flex-col items-center">
        <div className="flex items-center gap-3 mb-1">
          <span className="text-xs uppercase tracking-wide text-[#8A8DA8]">Room</span>
          <span className="font-['Archivo_Black',_sans-serif] text-2xl tracking-[0.3em]">{roomId}</span>
        </div>
        <p className="text-xs text-[#8A8DA8] mb-8">
          {status === "open" ? "Connected" : "Reconnecting..."}
        </p>

        {/* Winner banner */}
        <div className="h-14 mb-6 flex items-center justify-center">
          {winner && (
            <p className="font-['Archivo_Black',_sans-serif] text-2xl text-center">
              {didIWin ? "You buzzed first!" : `${winner} buzzed first!`}
            </p>
          )}
        </div>

        {/* Buzzer */}
        <button
          onClick={buzz}
          disabled={buzzerLocked}
          className={`w-56 h-56 rounded-full font-['Archivo_Black',_sans-serif] text-3xl tracking-wide transition-transform active:scale-95 disabled:opacity-40 disabled:cursor-not-allowed ${
            buzzerLocked ? "bg-[#22222C] text-[#8A8DA8]" : "bg-[#FF4438] text-[#F4F2ED] shadow-[0_0_60px_rgba(255,68,56,0.4)]"
          }`}
        >
          {buzzerLocked ? "LOCKED" : "BUZZ"}
        </button>

        {isHost && (
          <button
            onClick={clearBuzzes}
            className="mt-8 px-6 py-2 rounded-full text-sm font-semibold bg-[#FFB627] text-[#121218]"
          >
            Reset buzzer
          </button>
        )}

        {/* Participant roster */}
        <div className="mt-10 w-full">
          <h2 className="text-xs uppercase tracking-wide text-[#8A8DA8] mb-3">
            In this room ({participants.length})
          </h2>
          <ul className="flex flex-col gap-2">
            {participants.map((p) => (
              <li
                key={p.username}
                className="flex items-center justify-between bg-[#22222C] rounded-lg px-4 py-2"
              >
                <span className={p.username === username ? "font-semibold" : ""}>
                  {p.username}
                  {p.username === username && <span className="text-[#8A8DA8] text-sm"> (you)</span>}
                </span>
                {p.is_host && (
                  <span className="text-xs font-bold uppercase tracking-wide text-[#FFB627]">
                    Host
                  </span>
                )}
              </li>
            ))}
          </ul>
        </div>

        <button
          onClick={leaveRoom}
          className="mt-10 text-sm text-[#8A8DA8] underline underline-offset-2"
        >
          Leave room
        </button>
      </div>
    </main>
  );
}