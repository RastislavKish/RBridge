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

class ActionsScreen extends StatefulWidget {
    const ActionsScreen({ super.key, required this.settings });

    final Settings settings;

    @override
    State<ActionsScreen> createState() => _ActionsScreenState();

    }
class _ActionsScreenState extends State<ActionsScreen> {

    List<Action> get _actions => widget.settings.actions;

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                Expanded(
                    child: ListView.builder(
                        itemCount: _actions.length,
                        itemBuilder: (context, index) => ListTile(
                            key: ValueKey<int>(_actions[index].id),
                            title: ElevatedButton(
                                child: Text(_actions[index].name),
                                onPressed: () {_editAction(_actions[index]);},
                                ),
                            ),
                        findChildIndexCallback: (key) {
                            if (!(key is ValueKey<int>))
                            return null;

                            int id=(key as ValueKey<int>).value;
                            for (int i=0;i<_actions.length;i++)
                            if (_actions[i].id==id)
                            return i;

                            return null;
                            },
                        ),
                    ),
                Row(
                    children: [
                        ElevatedButton(
                            child: const Text('Add action'),
                            onPressed: _addAction,
                            ),
                        ],
                    ),
                ],
            );
        }

    void _addAction() async {
        bool result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddActionScreen(settings: widget.settings)),
            );

        if (result)
        setState(() {});
        }
    void _editAction(Action action) async {
        bool result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditActionScreen(settings: widget.settings, action: action)),
            );

        if (result)
        setState(() {});
        }

    }

class AddActionScreen extends StatefulWidget {
    const AddActionScreen({ super.key, required this.settings });

    final Settings settings;

    @override
    State<AddActionScreen> createState() => _AddActionScreenState();

    }
class _AddActionScreenState extends State<AddActionScreen> {

    bool _stickyCtrl=false;
    bool _stickyShift=false;
    bool _stickyAlt=false;

    var _nameCtrl=TextEditingController();
    var _forwardShortcutCtrl=TextEditingController();
    var _backwardShortcutCtrl=TextEditingController();

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar:AppBar(
                title: const Text('Add action'),
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
                    Row(
                        children: [
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Forward shortcut',
                                        ),
                                    controller: _forwardShortcutCtrl,
                                    ),
                                ),
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Backward shortcut',
                                        ),
                                    controller: _backwardShortcutCtrl,
                                    ),
                                ),
                            ],
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
        _forwardShortcutCtrl.dispose();
        _backwardShortcutCtrl.dispose();

        super.dispose();
        }

    void _addButtonPressHandler() {
        String name=_nameCtrl.text;
        bool stickyCtrl=_stickyCtrl;
        bool stickyShift=_stickyShift;
        bool stickyAlt=_stickyAlt;
        String forwardShortcut=_forwardShortcutCtrl.text;
        String backwardShortcut=_backwardShortcutCtrl.text;

        if (name=='' || forwardShortcut=='' || backwardShortcut=='')
        return;

        Action action=Action(
            id: 0,
            name: name,
            stickyCtrl: stickyCtrl,
            stickyShift: stickyShift,
            stickyAlt: stickyAlt,
            forwardShortcut: forwardShortcut,
            backwardShortcut: backwardShortcut,
            );

        widget.settings.addAction(action);

        Navigator.pop(context, true);
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context, false);
        }

    }

class EditActionScreen extends StatefulWidget {
    const EditActionScreen({ super.key, required this.settings, required this.action });

    final Settings settings;
    final Action action;

    @override
    State<EditActionScreen> createState() => _EditActionScreenState();

    }
class _EditActionScreenState extends State<EditActionScreen> {

    bool _stickyCtrl=false;
    bool _stickyShift=false;
    bool _stickyAlt=false;

    var _nameCtrl=TextEditingController();
    var _forwardShortcutCtrl=TextEditingController();
    var _backwardShortcutCtrl=TextEditingController();

    @override
    void initState() {
        super.initState();

        _nameCtrl.text=widget.action.name;
        _stickyCtrl=widget.action.stickyCtrl;
        _stickyShift=widget.action.stickyShift;
        _stickyAlt=widget.action.stickyAlt;
        _forwardShortcutCtrl.text=widget.action.forwardShortcut;
        _backwardShortcutCtrl.text=widget.action.backwardShortcut;
        }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar:AppBar(
                title: const Text('Edit action'),
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
                    Row(
                        children: [
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Forward shortcut',
                                        ),
                                    controller: _forwardShortcutCtrl,
                                    ),
                                ),
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Backward shortcut',
                                        ),
                                    controller: _backwardShortcutCtrl,
                                    ),
                                ),
                            ],
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
        _forwardShortcutCtrl.dispose();
        _backwardShortcutCtrl.dispose();

        super.dispose();
        }

    void _saveButtonPressHandler() {
        String name=_nameCtrl.text;
        bool stickyCtrl=_stickyCtrl;
        bool stickyShift=_stickyShift;
        bool stickyAlt=_stickyAlt;
        String forwardShortcut=_forwardShortcutCtrl.text;
        String backwardShortcut=_backwardShortcutCtrl.text;

        if (name=='' || forwardShortcut=='' || backwardShortcut=='')
        return;

        Action newAction=Action(
            id: widget.action.id,
            name: name,
            stickyCtrl: stickyCtrl,
            stickyShift: stickyShift,
            stickyAlt: stickyAlt,
            forwardShortcut: forwardShortcut,
            backwardShortcut: backwardShortcut,
            );

        if (widget.settings.editAction(newAction))
        Navigator.pop(context, true);
        }
    void _deleteButtonPressHandler() async {
        bool confirmation=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DeleteConfirmationScreen(subject: widget.action.name)),
            );

        if (confirmation) {
            widget.settings.deleteAction(widget.action);
            Navigator.pop(context, true);
            }
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context, false);
        }

    }

