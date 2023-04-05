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

import 'dart:convert';
import 'dart:io';

import 'package:config/logic.dart';
import 'package:config/general_screen.dart';
import 'package:config/actions_screen.dart';
import 'package:config/commands_screen.dart';
import 'package:config/rings_screen.dart';
import 'package:config/schemes_screen.dart';

void main() => runApp(
    ConfigApp()
    );

class ConfigApp extends StatefulWidget {
    const ConfigApp({ super.key });

    @override
    State<ConfigApp> createState() => _ConfigAppState();
    }
class _ConfigAppState extends State<ConfigApp> {

    var _settings=Settings();

    @override
    void initState() {
        super.initState();

        _loadSettings();
        }

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            home: DefaultTabController(
                length: 5,
                child: Scaffold(
                    appBar: AppBar(
                        title: const Text('RBridge config'),
                        bottom: const TabBar(
                            tabs: [
                                Tab(text: 'General'),
                                Tab(text: 'Schemes'),
                                Tab(text: 'Rings'),
                                Tab(text: 'Actions'),
                                Tab(text: 'Commands'),
                                ],
                            ),
                        ),
                    body: TabBarView(
                        children: [
                            GeneralScreen(),
                            SchemesScreen(settings: _settings),
                            RingsScreen(settings: _settings),
                            ActionsScreen(settings: _settings),
                            CommandsScreen(settings: _settings),
                            ],
                        ),
                    persistentFooterButtons: [
                        ElevatedButton(
                            child: const Text('Apply'),
                            onPressed: _applyButtonPressHandler,
                            ),
                        ElevatedButton(
                            child: const Text('Cancel'),
                            onPressed: _cancelButtonPressHandler,
                            ),
                        ElevatedButton(
                            child: const Text('Ok'),
                            onPressed: _okButtonPressHandler,
                            ),
                        ],
                    ),
                ),
            );
        }

    void _applyButtonPressHandler() async {
        await File('settings.json').writeAsString(jsonEncode(_settings));
        }
    void _cancelButtonPressHandler() {
        exit(0);
        }
    void _okButtonPressHandler() async {
        await File('settings.json').writeAsString(jsonEncode(_settings));
        exit(0);
        }

    void _loadSettings() async {
        var f=File('settings.json');

        if (await f.exists()) {
            String json=await f.readAsString();
            var settings=Settings.fromJson(jsonDecode(json));

            setState(() {
                _settings=settings;
                });
            }
        }

    }

