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

import 'package:flutter/material.dart' hide Action;

import 'package:config/logic.dart';
import 'package:config/universal_widgets.dart';

class CommandsScreen extends StatefulWidget {
    const CommandsScreen({ super.key, required this.settings });

    final Settings settings;

    @override
    State<CommandsScreen> createState() => _CommandsScreenState();

    }
class _CommandsScreenState extends State<CommandsScreen> {

    List<Command> get _commands => widget.settings.commands;

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                Expanded(
                    child: ListView.builder(
                        itemCount: _commands.length,
                        itemBuilder: (context, index) => ListTile(
                            key: ValueKey<int>(_commands[index].id),
                            title: ElevatedButton(
                                child: Text(_commands[index].name),
                                onPressed: () {_editCommand(_commands[index]);},
                                ),
                            ),
                        findChildIndexCallback: (key) {
                            if (!(key is ValueKey<int>))
                            return null;

                            int id=(key as ValueKey<int>).value;
                            int index=_commands.indexWhere((command) => command.id==id);

                            return (index>=0) ? index: null;
                            },
                        ),
                    ),
                Row(
                    children: [
                        ElevatedButton(
                            child: const Text('Add command'),
                            onPressed: _addCommand,
                            ),
                        ],
                    ),
                ],
            );
        }

    void _addCommand() async {
        bool result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCommandScreen(settings: widget.settings)),
            );

        if (result)
        setState(() {});
        }
    void _editCommand(Command command) async {
        bool result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditCommandScreen(settings: widget.settings, command: command)),
            );

        if (result)
        setState(() {});
        }

    }

class AddCommandScreen extends StatefulWidget {
    const AddCommandScreen({ super.key, required this.settings });

    final Settings settings;

    @override
    State<AddCommandScreen> createState() => _AddCommandScreenState();

    }
class _AddCommandScreenState extends State<AddCommandScreen> {

    bool _stickyCtrl=false;
    bool _stickyShift=false;
    bool _stickyAlt=false;

    var _nameCtrl=TextEditingController();
    var _shortcutCtrl=TextEditingController();

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar:AppBar(
                title: const Text('Add command'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            ),
                        controller: _nameCtrl,
                        ),
                    Row(
                        children: [
                            Expanded(
                                child: CheckboxListTile(
                                    value: _stickyCtrl,
                                    onChanged: (value) {setState(() { _stickyCtrl=value ?? false; });},
                                    title: const Text('Sticky ctrl'),
                                    ),
                                ),
                            Expanded(
                                child: CheckboxListTile(
                                    value: _stickyShift,
                                    onChanged: (value) {setState(() { _stickyShift=value ?? false; });},
                                    title: const Text('Sticky shift'),
                                    ),
                                ),
                            Expanded(
                                child: CheckboxListTile(
                                    value: _stickyAlt,
                                    onChanged: (value) {setState(() { _stickyAlt=value ?? false; });},
                                    title: const Text('Sticky alt'),
                                    ),
                                ),
                            ],
                        ),
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Shortcut',
                            ),
                        controller: _shortcutCtrl,
                        ),
                    Row(
                        children: [
                            ElevatedButton(
                                child: const Text('Add'),
                                onPressed: _addButtonPressHandler,
                                ),
                            ElevatedButton(
                                child: const Text('Cancel'),
                                onPressed: _cancelButtonPressHandler,
                                ),
                            ],
                        ),
                    ],
                ),
            );
        }

    @override
    void dispose() {
        _nameCtrl.dispose();
        _shortcutCtrl.dispose();

        super.dispose();
        }

    void _addButtonPressHandler() {
        String name=_nameCtrl.text;
        bool stickyCtrl=_stickyCtrl;
        bool stickyShift=_stickyShift;
        bool stickyAlt=_stickyAlt;
        String shortcut=_shortcutCtrl.text;

        if (name=='' || shortcut=='')
        return;

        Command command=Command(
            id: -1,
            name: name,
            stickyCtrl: stickyCtrl,
            stickyShift: stickyShift,
            stickyAlt: stickyAlt,
            shortcut: shortcut,
            );

        widget.settings.addCommand(command);

        Navigator.pop(context, true);
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context, false);
        }

    }

class EditCommandScreen extends StatefulWidget {
    const EditCommandScreen({ super.key, required this.settings, required this.command });

    final Settings settings;
    final Command command;

    @override
    State<EditCommandScreen> createState() => _EditCommandScreenState();

    }
class _EditCommandScreenState extends State<EditCommandScreen> {

    bool _stickyCtrl=false;
    bool _stickyShift=false;
    bool _stickyAlt=false;

    var _nameCtrl=TextEditingController();
    var _shortcutCtrl=TextEditingController();

    @override
    void initState() {
        super.initState();

        _nameCtrl.text=widget.command.name;
        _stickyCtrl=widget.command.stickyCtrl;
        _stickyShift=widget.command.stickyShift;
        _stickyAlt=widget.command.stickyAlt;
        _shortcutCtrl.text=widget.command.shortcut;
        }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar:AppBar(
                title: const Text('Edit command'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            ),
                        controller: _nameCtrl,
                        ),
                    Row(
                        children: [
                            Expanded(
                                child: CheckboxListTile(
                                    value: _stickyCtrl,
                                    onChanged: (value) {setState(() { _stickyCtrl=value ?? false; });},
                                    title: const Text('Sticky ctrl'),
                                    ),
                                ),
                            Expanded(
                                child: CheckboxListTile(
                                    value: _stickyShift,
                                    onChanged: (value) {setState(() { _stickyShift=value ?? false; });},
                                    title: const Text('Sticky shift'),
                                    ),
                                ),
                            Expanded(
                                child: CheckboxListTile(
                                    value: _stickyAlt,
                                    onChanged: (value) {setState(() { _stickyAlt=value ?? false; });},
                                    title: const Text('Sticky alt'),
                                    ),
                                ),
                            ],
                        ),
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Shortcut',
                            ),
                        controller: _shortcutCtrl,
                        ),
                    Row(
                        children: [
                            ElevatedButton(
                                child: const Text('Save'),
                                onPressed: _saveButtonPressHandler,
                                ),
                            ElevatedButton(
                                child: const Text('Delete'),
                                onPressed: _deleteButtonPressHandler,
                                ),
                            ElevatedButton(
                                child: const Text('Cancel'),
                                onPressed: _cancelButtonPressHandler,
                                ),
                            ],
                        ),
                    ],
                ),
            );
        }

    @override
    void dispose() {
        _nameCtrl.dispose();
        _shortcutCtrl.dispose();

        super.dispose();
        }

    void _saveButtonPressHandler() {
        String name=_nameCtrl.text;
        bool stickyCtrl=_stickyCtrl;
        bool stickyShift=_stickyShift;
        bool stickyAlt=_stickyAlt;
        String shortcut=_shortcutCtrl.text;

        if (name=='' || shortcut=='')
        return;

        Command newCommand=Command(
            id: widget.command.id,
            name: name,
            stickyCtrl: stickyCtrl,
            stickyShift: stickyShift,
            stickyAlt: stickyAlt,
            shortcut: shortcut,
            );

        if (widget.settings.editCommand(newCommand))
        Navigator.pop(context, true);
        }
    void _deleteButtonPressHandler() async {
        bool confirmation=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DeleteConfirmationScreen(subject: widget.command.name)),
            );

        if (confirmation) {
            widget.settings.deleteCommand(widget.command);
            Navigator.pop(context, true);
            }
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context, false);
        }

    }

