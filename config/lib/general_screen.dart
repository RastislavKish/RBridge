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

import 'package:flutter/material.dart';

import 'package:config/logic.dart';

class GeneralScreen extends StatefulWidget {
    const GeneralScreen({ super.key });

    @override
    State<GeneralScreen> createState() => _GeneralScreenState();

    }
class _GeneralScreenState extends State<GeneralScreen> {

    @override
    Widget build(BuildContext context) {
        return const Text('General screen');
        }

    }

