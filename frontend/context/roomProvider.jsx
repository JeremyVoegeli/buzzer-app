"use client";

import { createContext, useCallback, useContext, useState } from "react";
import { useWebSocket } from "../hooks/useWebSocket";

const RoomContext = createContext(null);

export function RoomProvider({ children }) {
  const [roomId, setRoomId] = useState(null);
  const [userId, setUserId] = useState(null);
  const [username, setUsername] = useState(null); // not returned by the backend — stored locally when submitted
  const [isHost, setIsHost] = useState(false);
  const [lastMessage, setLastMessage] = useState(null);
  const [winner, setWinner] = useState(null); // username of whoever buzzed first, per round; null = no winner yet

  const handleMessage = useCallback((data) => {
    setLastMessage(data);

    // create_user response: room_id + user_id + is_host all present together
    if (data.room_id !== undefined && data.user_id !== undefined && data.is_host !== undefined) {
      setRoomId(data.room_id);
      setUserId(data.user_id);
      setIsHost(Boolean(data.is_host));
      return;
    }

    // buzz: broadcast when someone wins, sent to every connection in the room
    // (including the winner themselves) — shape: "<username> buzzed first"
    if (typeof data.message === "string" && data.message.endsWith(" buzzed first")) {
      setWinner(data.message.replace(" buzzed first", ""));
      return;
    }

    // A losing buzz sends no message at all — nothing to handle here.
    // TODO: handle clear_buzzes and leave_room responses once their shapes are confirmed
  }, []);

  const { status, send } = useWebSocket(process.env.NEXT_PUBLIC_WS_URL, handleMessage);

  const createRoom = useCallback(
    (name) => {
      setUsername(name);
      send({ action: "create_user", username: name });
    },
    [send]
  );

  const joinRoom = useCallback(
    (name, joinRoomId) => {
      setUsername(name);
      send({ action: "create_user", username: name, room_id: joinRoomId });
    },
    [send]
  );

  const buzz = useCallback(() => {
    if (!roomId || !userId) return;
    send({ action: "buzz", room_id: roomId, user_id: userId });
  }, [send, roomId, userId]);

  const clearBuzzes = useCallback(() => {
    if (!roomId) return;
    send({ action: "clear_buzzes", room_id: roomId });
    setWinner(null); // optimistic reset — revisit once clear_buzzes response shape is confirmed
  }, [send, roomId]);

  const leaveRoom = useCallback(() => {
    send({ action: "leave_room" });
    setRoomId(null);
    setUserId(null);
    setUsername(null);
    setIsHost(false);
    setWinner(null);
  }, [send]);

  // Convenience flag: did *this* client win the current round?
  const didIWin = winner !== null && winner === username;

  const value = {
    status,
    roomId,
    userId,
    username,
    isHost,
    winner,
    didIWin,
    lastMessage,
    createRoom,
    joinRoom,
    buzz,
    clearBuzzes,
    leaveRoom,
  };

  return <RoomContext.Provider value={value}>{children}</RoomContext.Provider>;
}

export function useRoom() {
  const ctx = useContext(RoomContext);
  if (!ctx) {
    throw new Error("useRoom must be used within a RoomProvider");
  }
  return ctx;
}