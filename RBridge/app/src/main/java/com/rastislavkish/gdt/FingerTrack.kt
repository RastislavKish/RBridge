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

package com.rastislavkish.gdt

import android.view.MotionEvent

import kotlin.math.abs

class FingerTrack {

    val pointerId: Int
    val startPosition: Point
    val startTime: Long
    var endTime: Long=0L
    get() {
        if (finished)
        return field
        else
        return System.currentTimeMillis()
        }

    val duration: Long
    get() = endTime-startTime

    private var lastPosition: Point
    private var lastDragDirection: DragDirection?=null
    private var lastMark: Point
    private var finished=false

    val swipes=mutableListOf<SwipeDirection>()

    val stationary: Boolean
    get() = markedAsModifier || (swipes.size==0 && lastPosition.squaredDistanceFrom(startPosition)<100*100)

    //When markedAsModifier is false, it doesn'ŧ mean the track is not a modifier. This property indicates, whether it was used as one
    var markedAsModifier=false
    private set

    constructor(pointerId: Int, startPosition: Point, startTime: Long) {
        this.pointerId=pointerId
        this.startPosition=startPosition
        this.startTime=startTime
        lastPosition=startPosition
        lastMark=startPosition
        }

    fun onTouchEvent(event: MotionEvent) {
        if (finished)
        return

        val pointerIndex=event.findPointerIndex(pointerId)
        if (pointerIndex<0)
        return

        val position=Point(event.getX(pointerIndex), event.getY(pointerIndex))

        if (position==lastPosition)
        return

        val dragDirection=getDragDirection(lastPosition, position)

        if (dragDirection!=lastDragDirection) {
            //Dragging direction has changed, we need to check if the so far movement qualifies for a swipe

            if (lastPosition.squaredDistanceFrom(lastMark)>=100*100) {
                //qualifies as a swipe

                val swipeDirection=when (getDragDirection(lastMark, lastPosition)) {
                    DragDirection.Left -> SwipeDirection.Left
                    DragDirection.Right -> SwipeDirection.Right
                    DragDirection.Up -> SwipeDirection.Up
                    DragDirection.Down -> SwipeDirection.Down
                    }

                if (swipes.size==0 || swipes.last()!=swipeDirection) {
                    swipes.add(swipeDirection)
                    lastMark=lastPosition
                    }
                }

            lastDragDirection=dragDirection
            }

        lastPosition=position
        }
    fun finish(position: Point, endTime: Long) {
        if (finished)
        return

        this.endTime=endTime

        if (position.squaredDistanceFrom(lastMark)>=100*100) {
            //qualifies as a swipe

            val swipeDirection=when (getDragDirection(lastMark, position)) {
                DragDirection.Left -> SwipeDirection.Left
                DragDirection.Right -> SwipeDirection.Right
                DragDirection.Up -> SwipeDirection.Up
                DragDirection.Down -> SwipeDirection.Down
                }

            if (swipes.size==0 || swipes.last()!=swipeDirection) {
                swipes.add(swipeDirection)
                lastMark=position
                }
            }

        finished=true
        lastPosition=position

        }

    fun markAsModifier() {
        markedAsModifier=true
        }

    private enum class DragDirection {
        Left,
        Right,
        Up,
        Down,
        }

    private fun getDragDirection(a: Point, b: Point): DragDirection {
        assert(a!=b)

        val delta=b-a

        if (abs(delta.x)>abs(delta.y)) {
            if (delta.x<0)
            return DragDirection.Left
            else
            return DragDirection.Right
            }
        else {
            if (delta.y<0)
            return DragDirection.Up
            else
            return DragDirection.Down
            }
        }

    }
