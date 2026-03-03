// Quiet Hacker - Kotlin Preview
package com.quiethacker

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

const val MAX_BUFFER = 64
const val TIMEOUT_MS = 5000L

sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Failure(val error: String) : Result<Nothing>()

    fun <R> map(transform: (T) -> R): Result<R> = when (this) {
        is Success -> Success(transform(data))
        is Failure -> this
    }

    fun getOrNull(): T? = (this as? Success)?.data
}

data class Event(
    val id: Int,
    val type: String,
    val payload: Map<String, Any?>,
    val timestamp: Long = System.currentTimeMillis()
)

interface EventProcessor {
    suspend fun process(event: Event): Result<String>
}

class Pipeline(
    private val processors: List<EventProcessor>,
    private val concurrency: Int = 4
) {
    fun process(events: Flow<Event>): Flow<Result<String>> = events
        .buffer(MAX_BUFFER)
        .flatMapMerge(concurrency) { event ->
            flow {
                for (processor in processors) {
                    val result = withTimeoutOrNull(TIMEOUT_MS) {
                        processor.process(event)
                    } ?: Result.Failure("Timeout processing event ${event.id}")

                    emit(result)
                }
            }
        }

    suspend fun processAll(events: List<Event>): List<Result<String>> =
        process(events.asFlow()).toList()
}

class LogProcessor : EventProcessor {
    override suspend fun process(event: Event): Result<String> {
        delay(10) // simulate work
        return Result.Success("logged:${event.type}:${event.id}")
    }
}

// Extension functions
fun <T> List<Result<T>>.successes(): List<T> =
    filterIsInstance<Result.Success<T>>().map { it.data }

fun <T> List<Result<T>>.failures(): List<String> =
    filterIsInstance<Result.Failure>().map { it.error }

suspend fun main() {
    val pipeline = Pipeline(
        processors = listOf(LogProcessor()),
        concurrency = 4
    )

    val events = (1..20).map { i ->
        Event(id = i, type = "click", payload = mapOf("x" to i * 10, "y" to i * 5))
    }

    val results = pipeline.processAll(events)
    println("OK: ${results.successes().size}, Failed: ${results.failures().size}")
}
