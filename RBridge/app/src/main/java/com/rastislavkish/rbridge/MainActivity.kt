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

import android.content.Intent
import android.os.Bundle
import android.view.MotionEvent

import androidx.appcompat.app.AppCompatActivity
import androidx.activity.result.ActivityResult
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts.StartActivityForResult
import androidx.constraintlayout.widget.ConstraintLayout

import kotlinx.serialization.*
import kotlinx.serialization.json.Json

import com.rastislavkish.rtk.Speech

import com.rastislavkish.gdt.Gesture
import com.rastislavkish.gdt.TouchWrapper

class MainActivity : AppCompatActivity() {

    private lateinit var rBridgeClient: RBridgeClient

    private lateinit var connectActivityLauncher: ActivityResultLauncher<Intent>

    private lateinit var speech: Speech
    private lateinit var touchWrapper: TouchWrapper

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        speech=Speech(this)

        connectActivityLauncher=registerForActivityResult(StartActivityForResult(), this::connectActivityResult)

        startConnectActivity()
        }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (!this::touchWrapper.isInitialized) {
            touchWrapper=TouchWrapper(window.decorView.width, window.decorView.height)
            touchWrapper.registerGestureListener(this::touchWrapperGestureHandler)
            }

        touchWrapper.onTouchEvent(event)

        return true
        }

    private fun touchWrapperGestureHandler(gesture: Gesture) {
        rBridgeClient.sendGesture(gesture)
        }
    private fun rBridgeClientMessageHandler(message: String) {
        speech.speak(message)
        }

    private fun connectActivityResult(result: ActivityResult) {
        if (result.resultCode==RESULT_OK) {
            val connectActivityResult=ConnectActivityResult.fromIntent(result.data, "result", "MainActivity")

            rBridgeClient=RBridgeClient(connectActivityResult.address, connectActivityResult.port)
            rBridgeClient.setOnMessageListener(this::rBridgeClientMessageHandler)
            rBridgeClient.connect()
            }
        else {
            finish()
            }
        }

    private fun startConnectActivity() {
        val intent=Intent(this, ConnectActivity::class.java)
        connectActivityLauncher.launch(intent)
        }
    }
