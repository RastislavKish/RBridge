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

class RingsScreen extends StatefulWidget {
    const RingsScreen({ super.key, required this.settings });

    final Settings settings;

    @override
    State<RingsScreen> createState() => _RingsScreenState();

    }
class _RingsScreenState extends State<RingsScreen> {

    List<Ring> get _rings => widget.settings.rings;

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                Expanded(
                    child: ListView.builder(
                        itemCount: _rings.length,
                        itemBuilder: (context, index) => ListTile(
                            key: ValueKey<int>(_rings[index].id),
                            title: ElevatedButton(
                                child: Text(_rings[index].name),
                                onPressed: () {_editRing(_rings[index]);},
                                ),
                            ),
                        findChildIndexCallback: (key) {
                            if (!(key is ValueKey<int>))
                            return null;

                            int id=(key as ValueKey<int>).value;
                            for (int i=0;i<_rings.length;i++)
                            if (_rings[i].id==id)
                            return i;

                            return null;
                            },
                        ),
                    ),
                Row(
                    children: [
                        ElevatedButton(
                            child: const Text('Add ring'),
                            onPressed: _addRingButtonPressHandler,
                            ),
                        ],
                    ),
                ],
            );
        }

    void _addRingButtonPressHandler() async {
        bool? result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRingScreen(settings: widget.settings)),
            );

        if (result==true)
        setState(() {});
        }
    void _editRing(Ring ring) async {
        bool? result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditRingScreen(settings: widget.settings, ring: ring)),
            );

        if (result==true)
        setState(() {});
        }

    }

class AddRingScreen extends StatefulWidget {
    const AddRingScreen({ super.key, required this.settings });

    final Settings settings;

    @override
    State<AddRingScreen> createState() => _AddRingScreenState();
    }
class _AddRingScreenState extends State<AddRingScreen> {

    var _nameCtrl=TextEditingController();
    var _actions=<Action>[];

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Edit ring'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            ),
                        controller: _nameCtrl,
                        ),
                    Expanded(
                        child: ListView.builder(
                            itemCount: _actions.length,
                            itemBuilder: (context, index) => ListTile(
                                key: ValueKey<int>(_actions[index].id),
                                title: ElevatedButton(
                                    child: Text(_actions[index].name),
                                    onPressed: () {_actionPressHandler(index);},
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
                    ElevatedButton(
                        child: const Text('Select actions'),
                        onPressed: _selectActionsButtonPressHandler,
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

        super.dispose();
        }

    void _selectActionsButtonPressHandler() async {
        var actionIds=_actions.map((action) => action.id).toList();

        List<int>? selectedIds=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SelectActionsScreen(settings: widget.settings, selectedIds: actionIds)),
            );

        if (selectedIds==null)
        return;

        setState(() {
            _actions=selectedIds!.map((id) => widget.settings.objectMap[id]! as Action).toList();
            });
        }

    void _addButtonPressHandler() {
        String name=_nameCtrl.text;
        List<int> actions=_actions.map((action) => action.id).toList();

        if (name=='')
        return;

        Ring newRing=Ring(
            id: 0,
            name: name,
            actions: actions,
            );

        widget.settings.addRing(newRing);

        Navigator.pop(context, true);
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context);
        }

    void _actionPressHandler(int actionIndex) async {
        ListMove? listMove=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MoveActionScreen()),
            );

        if (listMove==null)
        return;

        setState(() {
            listMove.applyOn(_actions, actionIndex);
            });
        }
    }

class EditRingScreen extends StatefulWidget {
    const EditRingScreen({ super.key, required this.settings, required this.ring });

    final Settings settings;
    final Ring ring;

    @override
    State<EditRingScreen> createState() => _EditRingScreenState();
    }
class _EditRingScreenState extends State<EditRingScreen> {

    var _nameCtrl=TextEditingController();
    var _actions=<Action>[];

    @override
    void initState() {
        _nameCtrl.text=widget.ring.name;

        widget.ring.actions.forEach((actionId) {
            if (!widget.settings.objectMap.containsKey(actionId))
            return;

            ConfigObject action=widget.settings.objectMap[actionId]!;
            if (!(action is Action))
            return;

            _actions.add(action as Action);
            });

        super.initState();
        }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Edit ring'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            ),
                        controller: _nameCtrl,
                        ),
                    Expanded(
                        child: ListView.builder(
                            itemCount: _actions.length,
                            itemBuilder: (context, index) => ListTile(
                                key: ValueKey<int>(_actions[index].id),
                                title: ElevatedButton(
                                    child: Text(_actions[index].name),
                                    onPressed: () {_actionPressHandler(index);},
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
                    ElevatedButton(
                        child: const Text('Select actions'),
                        onPressed: _selectActionsButtonPressHandler,
                        ),
                    Row(
                        children: [
                            ElevatedButton(
                                child: const Text('Save'),
                                onPressed: _saveButtonPressHandler,
                                ),
                            ElevatedButton(
                                child: const Text('Delete ring'),
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

        super.dispose();
        }

    void _selectActionsButtonPressHandler() async {
        var actionIds=_actions.map((action) => action.id).toList();

        List<int>? selectedIds=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SelectActionsScreen(settings: widget.settings, selectedIds: actionIds)),
            );

        if (selectedIds==null)
        return;

        setState(() {
            _actions=selectedIds!.map((id) => widget.settings.objectMap[id]! as Action).toList();
            });
        }

    void _saveButtonPressHandler() {
        String name=_nameCtrl.text;
        List<int> actions=_actions.map((action) => action.id).toList();

        if (name=='')
        return;

        Ring newRing=Ring(
            id: widget.ring.id,
            name: name,
            actions: actions,
            );

        if (widget.settings.editRing(newRing))
        Navigator.pop(context, true);
        }
    void _deleteButtonPressHandler() async {
        bool? confirmation=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DeleteConfirmationScreen(subject: widget.ring.name)),
            );

        if (confirmation==true) {
            widget.settings.deleteRing(widget.ring);
            Navigator.pop(context, true);
            }
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context);
        }

    void _actionPressHandler(int actionIndex) async {
        ListMove? listMove=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MoveActionScreen()),
            );

        if (listMove==null)
        return;

        setState(() {
            listMove.applyOn(_actions, actionIndex);
            });
        }
    }

class MoveActionScreen extends StatefulWidget {
    const MoveActionScreen({ super.key });

    @override
    State<MoveActionScreen> createState() => _MoveActionScreenState();

    }
class _MoveActionScreenState extends State<MoveActionScreen> {

    var _moveCtrl=TextEditingController();

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Move action'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Move',
                            ),
                        controller: _moveCtrl,
                        ),
                    Row(
                        children: [
                            ElevatedButton(
                                child: const Text('Ok'),
                                onPressed: _okButtonPressHandler,
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
        _moveCtrl.dispose();

        super.dispose();
        }

    void _okButtonPressHandler() {
        String move=_moveCtrl.text;

        var listMove=ListMove.fromString(move);

        if (listMove==null)
        return;

        Navigator.pop(context, listMove!);
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context);
        }

    }

class SelectActionsScreen extends StatefulWidget {
    const SelectActionsScreen({ super.key, required this.settings, required this.selectedIds });

    final Settings settings;
    final List<int> selectedIds;

    @override
    State<SelectActionsScreen> createState() => _SelectActionsScreenState();

    }
class _SelectActionsScreenState extends State<SelectActionsScreen> {

    var _actions=<Action>[];
    var _selectedIds=<int>[];

    @override
    void initState() {
        _actions=List<Action>.from(widget.settings.actions);
        _selectedIds=List<int>.from(widget.selectedIds);

        _actions.sort((a, b) => a.name.compareTo(b.name));

        for (int i=_selectedIds.length-1;i>=0;i--) {
            var selectedId=_selectedIds[i];

            _actions.insert(0, _actions.removeAt(_actions.indexWhere((action) => action.id==selectedId)));
            }

        super.initState();
        }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Select actions'),
                ),
            body: Column(
                children: [
                    Expanded(
                        child: ListView.builder(
                            itemCount: _actions.length,
                            itemBuilder: (context, index) => CheckboxListTile(
                                key: ValueKey<int>(_actions[index].id),
                                value: _selectedIds.contains(_actions[index].id),
                                onChanged: (value) { _actionCheckboxChangeHandler(_actions[index].id, value ?? false); },
                                title: Text(_actions[index].name),
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
                                child: const Text('Ok'),
                                onPressed: _okButtonPressHandler,
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

    void _actionCheckboxChangeHandler(int id, bool value) {
        setState(() {
            if (value==false)
            _selectedIds.remove(id);
            else
            _selectedIds.add(id);

            _actions.sort((a, b) => a.name.compareTo(b.name));

            for (int i=_selectedIds.length-1;i>=0;i--) {
                var selectedId=_selectedIds[i];

                _actions.insert(0, _actions.removeAt(_actions.indexWhere((action) => action.id==selectedId)));
                }
            });
        }

    void _okButtonPressHandler() {
        Navigator.pop(context, _selectedIds);
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context);
        }

    }

