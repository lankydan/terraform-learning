package org.example.events

data class SongEvent(val songId: String, val eventType: EventType) {
    enum class EventType { START, STOP }
}