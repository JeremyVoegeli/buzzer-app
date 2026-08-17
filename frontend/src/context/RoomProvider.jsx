"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { useWebSocket } from "../hooks/useWebSocket";

const RoomContext = createContext(null);
const SESSION_KEY = "buzzerSession"; // { roomId, userId, username }

export function RoomProvider({ children }) {
  const [roomId, setRoomId] = useState(null);
  const [userId, setUserId] = useState(null);
  const [username, setUsername] = useState(null);
  const [isHost, setIsHost] = useState(false);
  const [participants, setParticipants] = useState([]);
  const [lastMessage, setLastMessage] = useState(null);
  const [winner, setWinner] = useState(null);

  const [isRejoining, setIsRejoining] = useState(false);
  const [errorMessage, setErrorMessage] = useState(null); // for the toast

  const saveSession = useCallback((data) => {
    sessionStorage.setItem(SESSION_KEY, JSON.stringify(data));
  }, []);

  const clearSession = useCallback(() => {
    sessionStorage.removeItem(SESSION_KEY);
  }, []);

  const handleMessage = useCallback((data) => {
    setLastMessage(data);

    // Generic error channel — any Lambda can send { status: "Error", message }.
    // Rejoin failures land here too: we clear the stale session and stop trying.
    if (data.status === "Error") {
      setIsRejoining(false);
      clearSession();
      setErrorMessage(data.message || "Something went wrong.");
      return;
    }

    // create_user / rejoin_room response to the client itself: room_id + user_id + is_host together
    if (data.room_id !== undefined && data.user_id !== undefined && data.is_host !== undefined) {
      setRoomId(data.room_id);
      setUserId(data.user_id);
      setIsHost(Boolean(data.is_host));
      if (data.username) setUsername(data.username); // present on rejoin_room; create_user already has it set locally
      if (data.roster) setParticipants(data.roster);
      setIsRejoining(false);
      saveSession({ roomId: data.room_id, userId: data.user_id, username: data.username ?? username });
      return;
    }

    if (data.roster !== undefined) {
      setParticipants(data.roster);
      return;
    }

    if (data.message.includes("Successfully cleared all buzzes for room")) {
    setWinner(null);
    return;
  }

    if (typeof data.message === "string" && data.message.endsWith(" buzzed first")) {
      setWinner(data.message.replace(" buzzed first", ""));
      return;
    }
  }, [saveSession, clearSession]);

  const { status, send } = useWebSocket(process.env.NEXT_PUBLIC_WS_URL, handleMessage);

  // Attempt rejoin once the socket is open, if a saved session exists.
  useEffect(() => {
    if (status !== "open") return;

    const saved = sessionStorage.getItem(SESSION_KEY);
    if (!saved) return;
    if (roomId) return; // already joined this session (e.g. status flapped open->open)

    try {
      const { roomId: savedRoomId, userId: savedUserId, username: savedUsername } = JSON.parse(saved);
      if (!savedRoomId || !savedUserId) return;

      setIsRejoining(true);
      send({ action: "rejoin_room", room_id: savedRoomId, user_id: savedUserId });
    } catch {
      clearSession();
    }
  }, [status, roomId, send, clearSession]);

  const createRoom = useCallback((name) => {
    setUsername(name);
    send({ action: "create_user", username: name });
  }, [send]);

  const joinRoom = useCallback((name, joinRoomId) => {
    setUsername(name);
    send({ action: "create_user", username: name, room_id: joinRoomId });
  }, [send]);

  const buzz = useCallback(() => {
    if (!roomId || !userId) return;
    send({ action: "buzz", room_id: roomId, user_id: userId });
  }, [send, roomId, userId]);

  const clearBuzzes = useCallback(() => {
    if (!roomId) return;
    send({ action: "clear_buzzes", room_id: roomId });
  }, [send, roomId]);

  const leaveRoom = useCallback(() => {
    send({ action: "remove_user" });
    clearSession();
    setRoomId(null);
    setUserId(null);
    setUsername(null);
    setIsHost(false);
    setParticipants([]);
    setWinner(null);
    window.location.href = "http://localhost:3000/";
  }, [send, clearSession]);

  const dismissError = useCallback(() => setErrorMessage(null), []);

  const didIWin = winner !== null && winner === username;

  const value = {
    status, roomId, userId, username, isHost, participants, winner, didIWin,
    lastMessage, isRejoining, errorMessage, dismissError,
    createRoom, joinRoom, buzz, clearBuzzes, leaveRoom,
  };

  return <RoomContext.Provider value={value}>{children}</RoomContext.Provider>;
}

export function useRoom() {
  const ctx = useContext(RoomContext);
  if (!ctx) throw new Error("useRoom must be used within a RoomProvider");
  return ctx;
}