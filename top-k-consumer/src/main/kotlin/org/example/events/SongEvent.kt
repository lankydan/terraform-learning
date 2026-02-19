package org.example.events

import java.io.Serializable

data class SongEvent(val songId: String, val eventType: EventType, val timestamp: Long) : Serializable {
    enum class EventType { START, STOP }
}