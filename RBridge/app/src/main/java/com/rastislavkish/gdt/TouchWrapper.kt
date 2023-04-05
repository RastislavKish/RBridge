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

import com.rastislavkish.rtk.Speech

class TouchWrapper(val width: Int, val height: Int) {

    private val fingerTracks=mutableMapOf<Int, FingerTrack>()
    private var swipeFingerCount=0

    private var tapFingerCount=0
    private var tapStack=mutableListOf<FingerTrack>()
    private var completedTapStack=mutableListOf<FingerTrack>()

    private var gestureListener: ((Gesture) -> Unit)?=null

    fun onTouchEvent(event: MotionEvent) {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                val pointerIndex=event.actionIndex
                val pointerId=event.getPointerId(pointerIndex)

                val x=event.getX(pointerIndex)
                val y=event.getY(pointerIndex)
                val startTime=event.eventTime

                fingerTracks[pointerId]=FingerTrack(pointerId, Point(x, y), startTime)
                }
            MotionEvent.ACTION_MOVE -> {
                for (fingerTrack in fingerTracks.values)
                fingerTrack.onTouchEvent(event)
                }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP -> {
                val pointerIndex=event.actionIndex
                val pointerId=event.getPointerId(pointerIndex)

                val x=event.getX(pointerIndex)
                val y=event.getY(pointerIndex)
                val endTime=event.eventTime

                fingerTracks[pointerId]?.finish(Point(x, y), endTime)

                releaseFingerTrack(pointerId)
                }
            }
        }

    fun registerGestureListener(listener: (Gesture) -> Unit) {
        gestureListener=listener
        }
    fun unregisterGestureListener() {
        gestureListener=null
        }

    private fun releaseFingerTrack(pointerId: Int) {
        val fingerTrack=fingerTracks.remove(pointerId) ?: return

        //If a track was marked as modifier before, we can release it right away to avoid misdetections
        if (fingerTrack.markedAsModifier)
        return

        if (!fingerTrack.stationary) {
            //A swipe detected
            processSwipe(fingerTrack)
            return
            }
        else if (fingerTrack.duration<=100) {
            //A tap detected
            processTap(fingerTrack)
            return
            }

        }

    private fun processSwipe(fingerTrack: FingerTrack) {
        swipeFingerCount+=1

        //This finger performed a swipe or a swipe sequence. We need to find if there are others in process

        var swipingFinished=true
        for (track in fingerTracks.values) {
            if (!track.stationary) {
                swipingFinished=false
                break
                }
            }

        if (swipingFinished) {
            //No other fingers are performing swipes, we can evaluate and raise the gesture

            //For optimalization purposes, we will mark our modifiers as modifiers. There are only stationary tracks left, so all of them are modifiers at this point
            for (track in fingerTracks.values)
            track.markAsModifier()

            val modifierCount=fingerTracks.values.size //Because there are only stationary tracks left
            val fingerCount=swipeFingerCount
            val startPosition=getFractionalPosition(fingerTrack.startPosition)

            if (fingerTrack.swipes.size==1)
            onGesture(Swipe(fingerTrack.swipes[0], fingerCount, modifierCount, startPosition))
            else if (fingerTrack.swipes.size>1)
            onGesture(SwipeSequence(fingerTrack.swipes.toList(), fingerCount, modifierCount, startPosition))

            swipeFingerCount=0
            }
        }
    private fun processTap(fingerTrack: FingerTrack) {
        //First of all, we should clean the stacks if there are outdated events

        if (tapStack.size>0 && fingerTrack.startTime-tapStack.last().endTime>700) {
            tapStack.clear()
            }
        if (completedTapStack.size>0 && fingerTrack.startTime-completedTapStack.last().endTime>700) {
            completedTapStack.clear()
            }

        //If tapStack is empty, completedTapStakc has to be as well, and there is nothing to process, thus we just add the event and return

        if (tapStack.size==0) {
            tapStack.add(fingerTrack)
            return
            }

        //Otherwise, we check if the new event is a part of a multifinger tap and matches into the stack

        val lastTap=tapStack.last()
        if (fingerTrack.startTime<lastTap.endTime) {
            //The tap matches

            tapStack.add(fingerTrack)

            //If both tapStack and completedTapStack have the same number of elements, we have a tap

            if (tapStack.size==completedTapStack.size) {
                raiseTapEvent()
                return
                }
            }
        else {
            completedTapStack=tapStack
            tapStack=mutableListOf(fingerTrack)

            if (tapStack.size==completedTapStack.size) {
                raiseTapEvent()
                return
                }
            }
        }
    private fun raiseTapEvent() {
        assert(tapStack.size==completedTapStack.size)
        assert(tapStack.size>0)

        //Mark modifiers for optimalization purposes

        for (track in fingerTracks.values)
        track.markAsModifier()

        val fingerCount=tapStack.size
        val modifierCount=fingerTracks.values.size

        var firstTap=completedTapStack.first()
        for (tap in completedTapStack) {
            if (tap.startTime<firstTap.startTime)
            firstTap=tap
            }

        val startPosition=getFractionalPosition(firstTap.startPosition)

        onGesture(Tap(fingerCount, modifierCount, startPosition))

        tapStack.clear()
        completedTapStack.clear()
        }

    private fun onGesture(gesture: Gesture) {
        gestureListener?.invoke(gesture)
        }

    private fun getFractionalPosition(position: Point): Point {
        return Point(position.x/width, position.y/height)
        }
    }
