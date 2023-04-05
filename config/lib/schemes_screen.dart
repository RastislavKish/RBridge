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

import 'dart:math';

import 'package:config/logic.dart';
import 'package:config/universal_widgets.dart';

class SchemesScreen extends StatefulWidget {
    const SchemesScreen({ super.key, required this.settings });

    final Settings settings;

    @override
    State<SchemesScreen> createState() => _SchemesScreenState();

    }
class _SchemesScreenState extends State<SchemesScreen> {

    List<Scheme> get _schemes => widget.settings.schemes;

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                Expanded(
                    child: ListView.builder(
                        itemCount: _schemes.length,
                        itemBuilder: (context, index) => ListTile(
                            key: ValueKey<int>(_schemes[index].id),
                            title: ElevatedButton(
                                child: Text(_schemes[index].name),
                                onPressed: () {_editScheme(_schemes[index]);},
                                ),
                            ),
                        findChildIndexCallback: (key) {
                            if (!(key is ValueKey<int>))
                            return null;

                            int id=(key as ValueKey<int>).value;
                            for (int i=0;i<_schemes.length;i++)
                            if (_schemes[i].id==id)
                            return i;

                            return null;
                            },
                        ),
                    ),
                Row(
                    children: [
                        ElevatedButton(
                            child: const Text('Add scheme'),
                            onPressed: _addScheme,
                            ),
                        ],
                    ),
                ],
            );
        }

    void _addScheme() async {
        bool result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddSchemeScreen(settings: widget.settings)),
            );

        if (result==true)
        setState(() {});
        }
    void _editScheme(Scheme scheme) async {
        bool result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditSchemeScreen(settings: widget.settings, scheme: scheme)),
            );

        if (result)
        setState(() {});
        }

    }

class AddSchemeScreen extends StatefulWidget {
    const AddSchemeScreen({ super.key, required this.settings });

    final Settings settings;

    @override
    State<AddSchemeScreen> createState() => _AddSchemeScreenState();

    }
class _AddSchemeScreenState extends State<AddSchemeScreen> {

    var _nameCtrl=TextEditingController();
    Bindings _bindings=Bindings();

    @override
    void dispose() {
        _nameCtrl.dispose();

        super.dispose();
        }

    @override
    Widget build(BuildContext context) {
        var slotBindings=List<Binding>.from(_bindings.slotBindings);
        var commandBindings=List<Binding>.from(_bindings.commandBindings);

        var bindingsArea=DefaultTabController(
            length: 2,
            child: Expanded(
                child: Column(
                    children: [
                        const TabBar(
                            tabs: [
                                Tab(text: 'Slot bindings'),
                                Tab(text: 'Command bindings'),
                                ],
                            ),
                        Expanded(
                            child: TabBarView(
                                children: [
                                    BindingListView(bindings: slotBindings, onItemPressed: _editBinding),
                                    BindingListView(bindings: commandBindings, onItemPressed: _editBinding),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            );

        return Scaffold(
            appBar: AppBar(
                title: const Text('Edit scheme'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            ),
                        controller: _nameCtrl,
                        ),
                    bindingsArea,
                    Row(
                        children: [
                            ElevatedButton(
                                child: const Text('Add slot binding'),
                                onPressed: _addSlotBinding,
                                ),
                            ElevatedButton(
                                child: const Text('Add command binding'),
                                onPressed: _addCommandBinding,
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

    void _addSlotBinding() async {
        bool result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddSlotBindingScreen(bindings: _bindings, settings: widget.settings)),
            );

        if (result==true)
        setState(() {});
        }
    void _addCommandBinding() async {
        bool result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCommandBindingScreen(bindings: _bindings, settings: widget.settings)),
            );

        if (result==true)
        setState(() {});
        }
    void _editBinding(Binding binding) async {
        bool result=false;

        if (binding is SlotBinding)
        result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditSlotBindingScreen(bindings: _bindings, binding: binding as SlotBinding, settings: widget.settings )),
            );
        else if (binding is CommandBinding)
        result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditCommandBindingScreen(bindings: _bindings, binding: binding as CommandBinding, settings: widget.settings )),
            );

        if (result==true)
        setState(() {});
        }

    void _addButtonPressHandler() {
        String name=_nameCtrl.text;
        Bindings bindings=_bindings;

        if (name=='')
        return;

        Scheme newScheme=Scheme(
            id: -1,
            name: name,
            bindings: bindings,
            );

        widget.settings.addScheme(newScheme);

        Navigator.pop(context, true);
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context, false);
        }

    }

class EditSchemeScreen extends StatefulWidget {
    const EditSchemeScreen({ super.key, required this.scheme, required this.settings });

    final Scheme scheme;
    final Settings settings;

    @override
    State<EditSchemeScreen> createState() => _EditSchemeScreenState();

    }
class _EditSchemeScreenState extends State<EditSchemeScreen> {

    var _nameCtrl=TextEditingController();
    var _bindings=Bindings();

    @override
    void initState() {
        _nameCtrl.text=widget.scheme.name;
        _bindings=Bindings.from(widget.scheme.bindings);

        super.initState();
        }

    @override
    void dispose() {
        _nameCtrl.dispose();

        super.dispose();
        }

    @override
    Widget build(BuildContext context) {
        var slotBindings=List<Binding>.from(_bindings.slotBindings);
        var commandBindings=List<Binding>.from(_bindings.commandBindings);

        var bindingsArea=DefaultTabController(
            length: 2,
            child: Expanded(
                child: Column(
                    children: [
                        const TabBar(
                            tabs: [
                                Tab(text: 'Slot bindings'),
                                Tab(text: 'Command bindings'),
                                ],
                            ),
                        Expanded(
                            child: TabBarView(
                                children: [
                                    BindingListView(bindings: slotBindings, onItemPressed: _editBinding),
                                    BindingListView(bindings: commandBindings, onItemPressed: _editBinding),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            );

        return Scaffold(
            appBar: AppBar(
                title: const Text('Edit scheme'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            ),
                        controller: _nameCtrl,
                        ),
                    bindingsArea,
                    Row(
                        children: [
                            ElevatedButton(
                                child: const Text('Add slot binding'),
                                onPressed: _addSlotBinding,
                                ),
                            ElevatedButton(
                                child: const Text('Add command binding'),
                                onPressed: _addCommandBinding,
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

    void _addSlotBinding() async {
        bool result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddSlotBindingScreen(bindings: _bindings, settings: widget.settings)),
            );

        if (result==true)
        setState(() {});
        }
    void _addCommandBinding() async {
        bool result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCommandBindingScreen(bindings: _bindings, settings: widget.settings)),
            );

        if (result==true)
        setState(() {});
        }
    void _editBinding(Binding binding) async {
        bool result=false;

        if (binding is SlotBinding)
        result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditSlotBindingScreen(bindings: _bindings, binding: binding as SlotBinding, settings: widget.settings )),
            );
        else if (binding is CommandBinding)
        result=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditCommandBindingScreen(bindings: _bindings, binding: binding as CommandBinding, settings: widget.settings )),
            );

        if (result==true)
        setState(() {});
        }

    void _saveButtonPressHandler() {
        String name=_nameCtrl.text;
        Bindings bindings=_bindings;

        if (name=='')
        return;

        Scheme newScheme=Scheme(
            id: widget.scheme.id,
            name: name,
            bindings: bindings,
            );

        if (widget.settings.editScheme(newScheme))
        Navigator.pop(context, true);
        }
    void _deleteButtonPressHandler() async {
        bool? confirmation=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DeleteConfirmationScreen(subject: widget.scheme.name)),
            );

        if (confirmation==true) {
            widget.settings.deleteScheme(widget.scheme);
            Navigator.pop(context, true);
            }
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context, false);
        }

    }

class BindingListView extends StatefulWidget {
    const BindingListView({ super.key, required this.bindings, this.onItemPressed=null });

    final List<Binding> bindings;
    final Function(Binding)? onItemPressed;

    @override
    State<BindingListView> createState() => _BindingListViewState();
    }
class _BindingListViewState extends State<BindingListView> {

    @override
    Widget build(BuildContext context) {
        return ListView.builder(
            itemCount: widget.bindings.length,
            itemBuilder: (context, index) => ListTile(
                key: ValueKey<int>(widget.bindings[index].id),
                title: ElevatedButton(
                    child: Text(widget.bindings[index].name),
                    onPressed: () {widget.onItemPressed?.call(widget.bindings[index]);},
                    ),
                ),
            findChildIndexCallback: (key) {
                if (!(key is ValueKey<int>))
                return null;

                int id=(key as ValueKey<int>).value;
                for (int i=0;i<widget.bindings.length;i++)
                if (widget.bindings[i].id==id)
                return i;

                return null;
                },
            );
        }

    }

class AddSlotBindingScreen extends StatefulWidget {
    const AddSlotBindingScreen({ super.key, required this.bindings, required this.settings, this.fingerCount=1, this.modifierCount=0 });

    final Bindings bindings;
    final Settings settings;
    final fingerCount;
    final modifierCount;

    @override
    State<AddSlotBindingScreen> createState() => _AddSlotBindingScreenState();
    }
class _AddSlotBindingScreenState extends State<AddSlotBindingScreen> {

    var _nameCtrl=TextEditingController();
    var _slotCtrl=TextEditingController();
    int? _ring=null;
    int? _defaultAction=null;
    var _fingerCountCtrl=TextEditingController();
    var _modifierCountCtrl=TextEditingController();

    @override
    void initState() {
        _fingerCountCtrl.text=widget.fingerCount.toString();
        _modifierCountCtrl.text=widget.modifierCount.toString();
        }

    @override
    void dispose() {
        _nameCtrl.dispose();
        _slotCtrl.dispose();
        _fingerCountCtrl.dispose();
        _modifierCountCtrl.dispose();

        super.dispose();
        }

    @override
    Widget build(BuildContext context) {
        var ringActions=<Action>[];
        if (_ring!=null) {
            (widget.settings.objectMap[_ring]! as Ring).actions.forEach((actionId) {
                ringActions.add(widget.settings.objectMap[actionId]! as Action);
                });
            }

        return Scaffold(
            appBar: AppBar(
                title: const Text('Edit slot binding'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            ),
                        controller: _nameCtrl,
                        ),
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Slot',
                            ),
                        controller: _slotCtrl,
                        ),
                    Row(
                        children: [
                            ConfigObjectDropdownButton(
                                objects: widget.settings.rings,
                                selectedValue: _ring,
                                settings: widget.settings,
                                onChanged: _ringDropdownButtonChangeHandler,
                                hint: const Text('Ring'),
                                ),
                            ConfigObjectDropdownButton(
                                objects: ringActions,
                                selectedValue: _defaultAction,
                                settings: widget.settings,
                                onChanged: _defaultActionDropdownButtonChangeHandler,
                                hint: const Text('Default action'),
                                ),
                            ],
                        ),
                    Row(
                        children: [
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Finger count',
                                        ),
                                    controller: _fingerCountCtrl,
                                    ),
                                ),
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Modifier count',
                                        ),
                                    controller: _modifierCountCtrl,
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

    void _addButtonPressHandler() {
        String name=_nameCtrl.text;
        String slot=_slotCtrl.text;
        int? ring=_ring;
        int? defaultAction=_defaultAction;
        int fingerCount;
        int modifierCount;

        try {
            fingerCount=int.parse(_fingerCountCtrl.text);
            modifierCount=int.parse(_modifierCountCtrl.text);
            }
        catch (e) {
            return;
            }

        if (name=='' || slot=='' || ring==null || defaultAction==null)
        return;

        SlotBinding newBinding=SlotBinding(
            id: -1,
            name: name,
            slot: slot,
            ring: ring!,
            defaultAction: defaultAction!,
            fingerCount: fingerCount,
            modifierCount: modifierCount,
            );

        widget.bindings.addBinding(newBinding);

        Navigator.pop(context, true);
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context, false);
        }

    void _ringDropdownButtonChangeHandler(int? value) {
        setState(() {
            if (value!=_ring)
            _defaultAction=null;

            _ring=value;
            });
        }
    void _defaultActionDropdownButtonChangeHandler(int? value) {
        setState(() {
            _defaultAction=value;
            });
        }

    }

class EditSlotBindingScreen extends StatefulWidget {
    const EditSlotBindingScreen({ super.key, required this.bindings, required this.binding, required this.settings });

    final Bindings bindings;
    final SlotBinding binding;
    final Settings settings;

    @override
    State<EditSlotBindingScreen> createState() => _EditSlotBindingScreenState();
    }
class _EditSlotBindingScreenState extends State<EditSlotBindingScreen> {

    var _nameCtrl=TextEditingController();
    var _slotCtrl=TextEditingController();
    int? _ring=null;
    int? _defaultAction=null;
    var _fingerCountCtrl=TextEditingController();
    var _modifierCountCtrl=TextEditingController();

    @override
    void initState() {
        _nameCtrl.text=widget.binding.name;
        _slotCtrl.text=widget.binding.slot;
        _ring=widget.binding.ring;
        _defaultAction=widget.binding.defaultAction;
        _fingerCountCtrl.text=widget.binding.fingerCount.toString();
        _modifierCountCtrl.text=widget.binding.modifierCount.toString();

        assert(widget.bindings.contains(widget.binding));

        super.initState();
        }

    @override
    void dispose() {
        _nameCtrl.dispose();
        _slotCtrl.dispose();
        _fingerCountCtrl.dispose();
        _modifierCountCtrl.dispose();

        super.dispose();
        }

    @override
    Widget build(BuildContext context) {
        var ringActions=<Action>[];
        if (_ring!=null) {
            (widget.settings.objectMap[_ring]! as Ring).actions.forEach((actionId) {
                ringActions.add(widget.settings.objectMap[actionId]! as Action);
                });
            }

        return Scaffold(
            appBar: AppBar(
                title: const Text('Edit slot binding'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            ),
                        controller: _nameCtrl,
                        ),
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Slot',
                            ),
                        controller: _slotCtrl,
                        ),
                    Row(
                        children: [
                            ConfigObjectDropdownButton(
                                objects: widget.settings.rings,
                                selectedValue: _ring,
                                settings: widget.settings,
                                onChanged: _ringDropdownButtonChangeHandler,
                                hint: const Text('Ring'),
                                ),
                            ConfigObjectDropdownButton(
                                objects: ringActions,
                                selectedValue: _defaultAction,
                                settings: widget.settings,
                                onChanged: _defaultActionDropdownButtonChangeHandler,
                                hint: const Text('Default action'),
                                ),
                            ],
                        ),
                    Row(
                        children: [
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Finger count',
                                        ),
                                    controller: _fingerCountCtrl,
                                    ),
                                ),
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Modifier count',
                                        ),
                                    controller: _modifierCountCtrl,
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

    void _saveButtonPressHandler() {
        String name=_nameCtrl.text;
        String slot=_slotCtrl.text;
        int? ring=_ring;
        int? defaultAction=_defaultAction;
        int fingerCount;
        int modifierCount;

        try {
            fingerCount=int.parse(_fingerCountCtrl.text);
            modifierCount=int.parse(_modifierCountCtrl.text);
            }
        catch (e) {
            return;
            }

        if (name=='' || slot=='' || ring==null || _defaultAction==null)
        return;

        SlotBinding newBinding=SlotBinding(
            id: widget.binding.id,
            name: name,
            slot: slot,
            ring: ring!,
            defaultAction: defaultAction!,
            fingerCount: fingerCount,
            modifierCount: modifierCount,
            );

        widget.bindings.editBinding(newBinding);

        Navigator.pop(context, true);
        }
    void _deleteButtonPressHandler() async {
        bool? confirmation=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DeleteConfirmationScreen(subject: widget.binding.name)),
            );

        if (confirmation==true) {
            widget.bindings.deleteBinding(widget.binding);
            Navigator.pop(context, true);
            }
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context, false);
        }

    void _ringDropdownButtonChangeHandler(int? value) {
        setState(() {
            if (value!=_ring)
            _defaultAction=null;

            _ring=value;
            });
        }
    void _defaultActionDropdownButtonChangeHandler(int? value) {
        setState(() {
            _defaultAction=value;
            });
        }

    }

class AddCommandBindingScreen extends StatefulWidget {
    const AddCommandBindingScreen({ super.key, required this.bindings, required this.settings, this.fingerCount=1, this.modifierCount=0 });

    final Bindings bindings;
    final Settings settings;
    final int fingerCount;
    final int modifierCount;

    @override
    State<AddCommandBindingScreen> createState() => _AddCommandBindingScreenState();
    }
class _AddCommandBindingScreenState extends State<AddCommandBindingScreen> {

    var _nameCtrl=TextEditingController();
    GestureShape? _gestureShape=null;
    var _swipeDirections=<Direction>[];
    int? _command=null;
    var _fingerCountCtrl=TextEditingController();
    var _modifierCountCtrl=TextEditingController();

    @override
    void initState() {
        _fingerCountCtrl.text=widget.fingerCount.toString();
        _modifierCountCtrl.text=widget.modifierCount.toString();

        super.initState();
        }

    @override
    void dispose() {
        _nameCtrl.dispose();
        _fingerCountCtrl.dispose();
        _modifierCountCtrl.dispose();

        super.dispose();
        }

    @override
    Widget build(BuildContext context) {

        return Scaffold(
            appBar: AppBar(
                title: const Text('Add command binding'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            ),
                        controller: _nameCtrl,
                        ),
                    GestureShapePicker(
                        gestureShape: _gestureShape,
                        swipeDirections: _swipeDirections,
                        onGestureShapeChanged: _gestureShapeChangeHandler,
                        onSwipeDirectionsChanged: _swipeDirectionsChangeHandler,
                        ),
                    ConfigObjectDropdownButton(
                        objects: widget.settings.commands,
                        selectedValue: _command,
                        settings: widget.settings,
                        onChanged: _commandDropdownButtonChangeHandler,
                        hint: const Text('Command'),
                        ),
                    Row(
                        children: [
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Finger count',
                                        ),
                                    controller: _fingerCountCtrl,
                                    ),
                                ),
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Modifier count',
                                        ),
                                    controller: _modifierCountCtrl,
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

    void _addButtonPressHandler() {
        String name=_nameCtrl.text;
        GestureShape? gestureShape=_gestureShape;
        var swipeDirections=_swipeDirections;

        if (gestureShape==GestureShape.Tap)
        swipeDirections=<Direction>[];

        int? command=_command;
        int fingerCount;
        int modifierCount;

        try {
            fingerCount=int.parse(_fingerCountCtrl.text);
            modifierCount=int.parse(_modifierCountCtrl.text);
            }
        catch (e) {
            return;
            }

        if (name=='' || gestureShape==null || command==null)
        return;

        if (gestureShape==GestureShape.Swipe && swipeDirections.length==0)
        return;

        CommandBinding binding=CommandBinding(
            id: -1,
            name: name,
            gestureShape: gestureShape!,
            swipeDirections: swipeDirections,
            command: command,
            fingerCount: fingerCount,
            modifierCount: modifierCount,
            );

        widget.bindings.addBinding(binding);

        Navigator.pop(context, true);
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context, false);
        }

    void _gestureShapeChangeHandler(GestureShape? value) {
        setState(() {
            _gestureShape=value;
            });
        }
    void _swipeDirectionsChangeHandler(List<Direction> value) {
        setState(() {
            _swipeDirections=value;
            });
        }
    int? _commandDropdownButtonChangeHandler(int? value) {
        setState(() {
            _command=value;
            });
        }

    }

class EditCommandBindingScreen extends StatefulWidget {
    const EditCommandBindingScreen({ super.key, required this.bindings, required this.binding, required this.settings });

    final Bindings bindings;
    final CommandBinding binding;
    final Settings settings;

    @override
    State<EditCommandBindingScreen> createState() => _EditCommandBindingScreenState();
    }
class _EditCommandBindingScreenState extends State<EditCommandBindingScreen> {

    var _nameCtrl=TextEditingController();
    GestureShape? _gestureShape=null;
    var _swipeDirections=<Direction>[];
    int? _command=null;
    var _fingerCountCtrl=TextEditingController();
    var _modifierCountCtrl=TextEditingController();

    @override
    void initState() {
        _nameCtrl.text=widget.binding.name;
        _gestureShape=widget.binding.gestureShape;
        _swipeDirections=List<Direction>.from(widget.binding.swipeDirections);
        _command=widget.binding.command;
        _fingerCountCtrl.text=widget.binding.fingerCount.toString();
        _modifierCountCtrl.text=widget.binding.modifierCount.toString();

        assert(widget.bindings.contains(widget.binding));

        super.initState();
        }

    @override
    void dispose() {
        _nameCtrl.dispose();
        _fingerCountCtrl.dispose();
        _modifierCountCtrl.dispose();

        super.dispose();
        }

    @override
    Widget build(BuildContext context) {

        return Scaffold(
            appBar: AppBar(
                title: const Text('Edit command binding'),
                ),
            body: Column(
                children: [
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Name',
                            ),
                        controller: _nameCtrl,
                        ),
                    GestureShapePicker(
                        gestureShape: _gestureShape,
                        swipeDirections: _swipeDirections,
                        onGestureShapeChanged: _gestureShapeChangeHandler,
                        onSwipeDirectionsChanged: _swipeDirectionsChangeHandler,
                        ),
                    ConfigObjectDropdownButton(
                        objects: widget.settings.commands,
                        selectedValue: _command,
                        settings: widget.settings,
                        onChanged: _commandDropdownButtonChangeHandler,
                        hint: const Text('Command'),
                        ),
                    Row(
                        children: [
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Finger count',
                                        ),
                                    controller: _fingerCountCtrl,
                                    ),
                                ),
                            Expanded(
                                child: TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Modifier count',
                                        ),
                                    controller: _modifierCountCtrl,
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

    void _saveButtonPressHandler() {
        String name=_nameCtrl.text;
        GestureShape? gestureShape=_gestureShape;
        var swipeDirections=_swipeDirections;

        if (gestureShape==GestureShape.Tap)
        swipeDirections=<Direction>[];

        int? command=_command;
        int fingerCount;
        int modifierCount;

        try {
            fingerCount=int.parse(_fingerCountCtrl.text);
            modifierCount=int.parse(_modifierCountCtrl.text);
            }
        catch (e) {
            return;
            }

        if (name=='' || gestureShape==null || command==null)
        return;

        if (gestureShape==GestureShape.Swipe && swipeDirections.length==0)
        return;

        CommandBinding newBinding=CommandBinding(
            id: widget.binding.id,
            name: name,
            gestureShape: gestureShape!,
            swipeDirections: swipeDirections,
            command: command,
            fingerCount: fingerCount,
            modifierCount: modifierCount,
            );

        widget.bindings.editBinding(newBinding);

        Navigator.pop(context, true);
        }
    void _deleteButtonPressHandler() async {
        bool? confirmation=await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DeleteConfirmationScreen(subject: widget.binding.name)),
            );

        if (confirmation==true) {
            widget.bindings.deleteBinding(widget.binding);
            Navigator.pop(context, true);
            }
        }
    void _cancelButtonPressHandler() {
        Navigator.pop(context, false);
        }

    void _gestureShapeChangeHandler(GestureShape? value) {
        setState(() {
            _gestureShape=value;
            });
        }
    void _swipeDirectionsChangeHandler(List<Direction> value) {
        setState(() {
            _swipeDirections=value;
            });
        }
    int? _commandDropdownButtonChangeHandler(int? value) {
        setState(() {
            _command=value;
            });
        }

    }

