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

import kotlin.math.pow

class Point(
    val x: Float=0.0f,
    val y: Float=0.0f,
    ) {

    fun squaredDistanceFrom(p: Point): Float {
        return (p.x-x).pow(2)+(p.y-y).pow(2)
        }

    override fun equals(other: Any?): Boolean {
        if (other is Point) {
            return x==other.x && y==other.y
            }

        return false
        }
    override fun hashCode(): Int {
        return x.hashCode() xor y.hashCode()
        }

    operator fun plus(other: Point): Point {
        return Point(x+other.x, y+other.y)
        }
    operator fun minus(other: Point): Point {
        return Point(x-other.x, y-other.y)
        }

    }
