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

import androidx.appcompat.app.AppCompatActivity
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.EditText

import kotlinx.serialization.*
import kotlinx.serialization.json.Json

class ConnectActivity : AppCompatActivity() {

    private lateinit var addressEditText: EditText
    private lateinit var portEditText: EditText
    private lateinit var connectButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_connect)

        addressEditText=findViewById(R.id.addressEditText)
        portEditText=findViewById(R.id.portEditText)
        connectButton=findViewById(R.id.connectButton)
        connectButton.setOnClickListener(this::connectButtonClickHandler)
        }

    fun connectButtonClickHandler(view: View) {
        if (addressEditText.text.toString()=="" || portEditText.text.toString()=="")
        return

        val address: String=addressEditText.text.toString()
        val port: Int=portEditText.text.toString().toInt()

        val result=ConnectActivityResult(address, port)

        val resultIntent=Intent()
        resultIntent.putExtra("result", Json.encodeToString(result))
        setResult(RESULT_OK, resultIntent)

        finish()
        }
    }
