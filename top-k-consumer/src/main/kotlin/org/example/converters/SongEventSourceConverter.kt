package org.example.converters

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import io.nats.client.Message
import io.synadia.flink.message.SourceConverter
import org.apache.flink.api.common.typeinfo.TypeInformation
import org.example.events.SongEvent
import java.io.ObjectInputStream
import java.io.Serial

class SongEventSourceConverter : SourceConverter<SongEvent> {

    @Transient
    private var objectMapper = jacksonObjectMapper()

    override fun convert(message: Message): SongEvent {
        return objectMapper.readValue<SongEvent>(message.data)
    }

    override fun getProducedType(): TypeInformation<SongEvent> {
        return TypeInformation.of(SongEvent::class.java)
    }

    @Serial
    private fun readObject(ois: ObjectInputStream) {
        ois.defaultReadObject()
        objectMapper = jacksonObjectMapper()
    }
}