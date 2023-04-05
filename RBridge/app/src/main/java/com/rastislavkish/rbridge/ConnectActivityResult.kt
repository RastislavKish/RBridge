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

import kotlinx.serialization.*
import kotlinx.serialization.json.Json

@Serializable
class ConnectActivityResult(
    val address: String,
    val port: Int,
    ) {

    companion object {

        fun fromIntent(intent: Intent?, key: String, caller: String=""): ConnectActivityResult {
            if (intent!=null) {
                val extras=intent.extras
                if (extras!=null) {
                    val json=(extras.getCharSequence(key)
                    ?: throw Exception("$caller did not receive a json in received intent on key \"$key\"."))
                    .toString()

                    try {
                        return Json.decodeFromString<ConnectActivityResult>(json)
                        }
                    catch (e: Exception) {
                        throw Exception("ConnectActivityResult received by $caller is invalid.")
                        }
                    }
                else throw Exception("$caller did not receive any extras in the received intent.")
                }
            else throw Exception("$caller did not receive any intent.")
            }

        }
    }
