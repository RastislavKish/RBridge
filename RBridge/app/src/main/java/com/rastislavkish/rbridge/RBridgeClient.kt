/*
* Copyright (C) 2023 Rastislav Kish
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, version 3.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program. If not, see <https://www.gnu.org/licenses/>.
*/

package com.rastislavkish.rbridge

import java.net.URI
import java.nio.ByteBuffer

import kotlinx.serialization.*
import kotlinx.serialization.json.Json

import org.java_websocket.client.WebSocketClient
import org.java_websocket.handshake.ServerHandshake

import com.rastislavkish.gdt.Gesture
import com.rastislavkish.gdt.Swipe
import com.rastislavkish.gdt.SwipeSequence
import com.rastislavkish.gdt.Tap
import com.rastislavkish.gdt.SwipeDirection

class RBridgeClient(
    val address: String,
    val port: Int,
    ) : WebSocketClient(URI("ws://$address:$port")) {

    private var onMessageListener: ((String) -> Unit)?=null

    fun sendGesture(gesture: Gesture) {
        if (gesture is Swipe) {
            val buffer=ByteBuffer.allocate(7)

            buffer.put(b(0)) //ClientMessage::Gesture
            buffer.put(b(gesture.fingerCount))
            buffer.put(b(gesture.modifierCount))
            buffer.put(b((gesture.startPosition.x*100).toInt()))
            buffer.put(b((gesture.startPosition.y*100).toInt()))
            buffer.put(b(0)) //GestureShape::Swipe

            buffer.put(b(swipeDirectionToInt(gesture.direction)))

            buffer.rewind()

            send(buffer)
            }
        else if (gesture is SwipeSequence) {
            val buffer=ByteBuffer.allocate(6+gesture.directions.size)

            buffer.put(b(0)) //ClientMessage::Gesture
            buffer.put(b(gesture.fingerCount))
            buffer.put(b(gesture.modifierCount))
            buffer.put(b((gesture.startPosition.x*100).toInt()))
            buffer.put(b((gesture.startPosition.y*100).toInt()))
            buffer.put(b(0)) //GestureShape::Swipe

            for (direction in gesture.directions)
            buffer.put(b(swipeDirectionToInt(direction)))

            buffer.rewind()

            send(buffer)
            }
        else if (gesture is Tap) {
            val buffer=ByteBuffer.allocate(6)

            buffer.put(b(0)) //ClientMessage::Gesture
            buffer.put(b(gesture.fingerCount))
            buffer.put(b(gesture.modifierCount))
            buffer.put(b((gesture.startPosition.x*100).toInt()))
            buffer.put(b((gesture.startPosition.y*100).toInt()))
            buffer.put(b(1)) //GestureShape::Tap

            buffer.rewind()

            send(buffer)
            }
        }

    fun setOnMessageListener(listener: (String) -> Unit) {
        onMessageListener=listener
        }

    override fun onOpen(handshakeData: ServerHandshake) {
        android.util.Log.d("RBridge", "Connection established")
        send("random_password")
        }

    override fun onClose(code: Int, reason: String, remote: Boolean) {

        }

    override fun onMessage(message: String) {
        onMessageListener?.invoke(message)
        }

    override fun onMessage(message: ByteBuffer) {

        }

    override fun onError(ex: Exception) {
        android.util.Log.d("RBridge", "Error: ${ex.toString()}")
        }

    @Serializable
    class SwipeGestureInfo(
        val fingerCount: Int,
        val modifierCount: Int,
        val startX: Float,
        val startY: Float,
        val shape: Map<String, List<String>>,
        ) {

        }

    @Serializable
    class TapGestureInfo(
        val fingerCount: Int,
        val modifierCount: Int,
        val startX: Float,
        val startY: Float,
        val shape: String,
        ) {

        }

    private fun swipeToSwipeGestureInfo(swipe: Swipe): SwipeGestureInfo {
        return SwipeGestureInfo(
            swipe.fingerCount,
            swipe.modifierCount,
            swipe.startPosition.x,
            swipe.startPosition.y,
            mapOf<String, List<String>>(
                "Swipe" to listOf<String>(swipe.direction.toString()),
                ),
            );
        }
    private fun swipeSequenceToSwipeGestureInfo(swipeSequence: SwipeSequence): SwipeGestureInfo {
        return SwipeGestureInfo(
            swipeSequence.fingerCount,
            swipeSequence.modifierCount,
            swipeSequence.startPosition.x,
            swipeSequence.startPosition.y,
            mapOf<String, List<String>>(
                "Swipe" to swipeSequence.directions.map({direction -> direction.toString()}).toList(),
                ),
            );
        }
    private fun tapToTapGestureInfo(tap: Tap): TapGestureInfo {
        return TapGestureInfo(
            tap.fingerCount,
            tap.modifierCount,
            tap.startPosition.x,
            tap.startPosition.y,
            "Tap",
            );
        }

    private fun swipeDirectionToInt(direction: SwipeDirection) = when (direction) {
        SwipeDirection.Left -> 0
        SwipeDirection.Right -> 1
        SwipeDirection.Up -> 2
        SwipeDirection.Down -> 3
        }

    private fun b(input: Int) = input.toByte()
    }
