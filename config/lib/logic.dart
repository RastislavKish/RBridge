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

import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

part 'logic.g.dart';

@JsonSerializable()
class Settings {

    List<Action> actions=<Action>[Action(
        id: 1,
        name: 'Tab',
        forwardShortcut: 'Tab',
        backwardShortcut: 'Shift+Tab',
        ),];
    List<Command> commands=<Command>[Command(
        id: 2,
        name: 'Return',
        shortcut: 'Return',
        ),];
    List<Ring> rings=<Ring>[Ring(
        id: 10,
        name: 'TestRing',
        actions: [1],
        ),];
    List<Scheme> schemes=<Scheme>[Scheme(
        id: 20,
        name: 'TestScheme',
        bindings: Bindings(
            slotBindings: [
                SlotBinding(
                    id: 40,
                    name: 'TestSlotBinding',
                    slot: '2h',
                    ring: 10,
                    defaultAction: 1,
                    ),
                ],
            commandBindings: [
                CommandBinding(
                    id: 41,
                    name: 'TestCommandBinding',
                    gestureShape: GestureShape.Tap,
                    swipeDirections: <Direction>[],
                    command: 2,
                    ),
                ],
            ),
        ),];

    @JsonKey(ignore: true)
    var objectMap=Map<int, ConfigObject>();

    Settings() {
        _finalize();
        }

    void addAction(Action action) {
        action.id=_findFreeId();
        actions.add(action);
        objectMap[action.id]=action;
        }
    bool editAction(Action newAction) {
        for (int i=0;i<actions.length;i++) {
            if (actions[i].id==newAction.id) {
                actions[i]=newAction;
                objectMap[newAction.id]=newAction;
                return true;
                }
            }

        return false;
        }
    void deleteAction(Action action) {
        actions.remove(action);
        objectMap.remove(action.id);
        }

    void addCommand(Command command) {
        command.id=_findFreeId();
        commands.add(command);
        objectMap[command.id]=command;
        }
    bool editCommand(Command newCommand) {
        for (int i=0;i<commands.length;i++) {
            if (commands[i].id==newCommand.id) {
                commands[i]=newCommand;
                objectMap[newCommand.id]=newCommand;
                return true;
                }
            }

        return false;
        }
    void deleteCommand(Command command) {
        commands.remove(command);
        objectMap.remove(command.id);
        }

    void addRing(Ring ring) {
        ring.id=_findFreeId();
        rings.add(ring);
        objectMap[ring.id]=ring;
        }
    bool editRing(Ring newRing) {
        for (int i=0;i<rings.length;i++) {
            if (rings[i].id==newRing.id) {
                rings[i]=newRing;
                objectMap[newRing.id]=newRing;
                return true;
                }
            }

        return false;
        }
    void deleteRing(Ring ring) {
        rings.remove(ring);
        objectMap.remove(ring.id);
        }

    void addScheme(Scheme scheme) {
        scheme.id=_findFreeId();
        schemes.add(scheme);
        objectMap[scheme.id]=scheme;
        }
    bool editScheme(Scheme newScheme) {
        for (int i=0;i<schemes.length;i++) {
            if (schemes[i].id==newScheme.id) {
                schemes[i]=newScheme;
                objectMap[newScheme.id]=newScheme;
                return true;
                }
            }

        return false;
        }
    void deleteScheme(Scheme scheme) {
        schemes.remove(scheme);
        objectMap.remove(scheme.id);
        }

    int _findFreeId() {
        while (true) {
            int id=_random.nextInt(1000000000);

            if (!objectMap.containsKey(id))
            return id;
            }
        }

    static Random _random=Random();

    void _finalize() {
        actions.forEach((action) { objectMap[action.id]=action; });
        rings.forEach((ring) { objectMap[ring.id]=ring; });
        schemes.forEach((scheme) { objectMap[scheme.id]=scheme; });
        }

    factory Settings.fromJson(Map<String, dynamic> json) {
        var settings=_$SettingsFromJson(json);
        settings._finalize();
        return settings;
        }

    Map<String, dynamic> toJson() => _$SettingsToJson(this);
    }

class ConfigObject {

    int id=0;
    String name='';

    }

@JsonSerializable()
class Action implements ConfigObject {
    @override
    int id;

    @override
    String name;

    bool stickyCtrl;
    bool stickyShift;
    bool stickyAlt;
    String forwardShortcut;
    String backwardShortcut;

    Action({required this.id, required this.name, this.stickyCtrl=false, this.stickyShift=false, this.stickyAlt=false, required this.forwardShortcut, required this.backwardShortcut});

    factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);

    Map<String, dynamic> toJson() => _$ActionToJson(this);
    }

@JsonSerializable()
class Command implements ConfigObject {
    @override
    int id;

    @override
    String name;

    bool stickyCtrl;
    bool stickyShift;
    bool stickyAlt;
    String shortcut;

    Command({required this.id, required this.name, this.stickyCtrl=false, this.stickyShift=false, this.stickyAlt=false, required this.shortcut });

    factory Command.fromJson(Map<String, dynamic> json) => _$CommandFromJson(json);

    Map<String, dynamic> toJson() => _$CommandToJson(this);
    }

@JsonSerializable()
class Ring implements ConfigObject {

    @override
    int id;

    @override
    String name;

    List<int> actions;

    Ring({required this.id, required this.name, required this.actions});

    bool addAction(int actionId) {
        if (actions.contains(actionId))
        return false;

        actions.add(actionId);

        return true;
        }
    bool removeAction(int actionId) {
        int action=actions.indexOf(actionId);
        if (action<0)
        return false;

        actions.removeAt(action);

        return true;
        }

    factory Ring.fromJson(Map<String, dynamic> json) => _$RingFromJson(json);

    Map<String, dynamic> toJson() => _$RingToJson(this);
    }

@JsonSerializable()
class Scheme implements ConfigObject {

    @override
    int id;

    @override
    String name;

    Bindings bindings;

    Scheme({required this.id, required this.name, required this.bindings});

    factory Scheme.fromJson(Map<String, dynamic> json) => _$SchemeFromJson(json);

    Map<String, dynamic> toJson() => _$SchemeToJson(this);
    }

@JsonSerializable()
class Bindings {

    List<SlotBinding> slotBindings=[];
    List<CommandBinding> commandBindings=[];

    List<Binding> get bindingList => [...slotBindings, ...commandBindings];

    Bindings({ this.slotBindings=const <SlotBinding>[], this.commandBindings=const <CommandBinding>[] });

    Bindings.from(Bindings bindings)
    : slotBindings=List<SlotBinding>.from(bindings.slotBindings), commandBindings=List<CommandBinding>.from(bindings.commandBindings);

    bool contains(Binding binding) {
        return (
        slotBindings.indexWhere((item) => item.id==binding.id)>=0
        || commandBindings.indexWhere((item) => item.id==binding.id)>=0
        );
        }

    void addBinding(Binding binding) {
        binding.id=_findFreeBindingId();

        if (binding is SlotBinding) {
            slotBindings.add(binding as SlotBinding);
            }
        else if (binding is CommandBinding) {
            commandBindings.add(binding as CommandBinding);
            }
        }
    void editBinding(Binding newBinding) {
        if (newBinding is SlotBinding) {
            int bindingPosition=slotBindings.indexWhere((binding) => binding.id==newBinding.id);

            assert(bindingPosition>=0);

            slotBindings[bindingPosition]=newBinding as SlotBinding;
            }
        else if (newBinding is CommandBinding) {
            int bindingPosition=commandBindings.indexWhere((binding) => binding.id==newBinding.id);

            assert(bindingPosition>=0);

            commandBindings[bindingPosition]=newBinding as CommandBinding;
            }
        }
    void deleteBinding(Binding binding) {
        if (binding is SlotBinding) {
            int bindingPosition=slotBindings.indexWhere((item) => item.id==binding.id);

            assert(bindingPosition>=0);

            slotBindings.removeAt(bindingPosition);
            }
        else if (binding is CommandBinding) {
            int bindingPosition=commandBindings.indexWhere((item) => item.id==binding.id);

            assert(bindingPosition>=0);

            commandBindings.removeAt(bindingPosition);
            }
        }

    int _findFreeBindingId() {
        while (true) {
            int id=_random.nextInt(1000000000);

            if (
            slotBindings.indexWhere((binding) => binding.id==id)==-1
            && commandBindings.indexWhere((binding) => binding.id==id)==-1
            )
            return id;
            }
        }

    static Random _random=Random();

    factory Bindings.fromJson(Map<String, dynamic> json) => _$BindingsFromJson(json);

    Map<String, dynamic> toJson() => _$BindingsToJson(this);
    }

abstract class Binding {

    @override
    int id;

    @override
    String name;

    Binding({ required this.id, required this.name });

    }

@JsonSerializable()
class SlotBinding extends Binding {

    String slot;
    int ring;
    int defaultAction;
    int fingerCount;
    int modifierCount;

    SlotBinding({ required this.slot, required this.ring, required this.defaultAction, this.fingerCount=1, this.modifierCount=0, required int id, required String name }) : super(id: id, name: name);

    factory SlotBinding.fromJson(Map<String, dynamic> json) => _$SlotBindingFromJson(json);

    Map<String, dynamic> toJson() => _$SlotBindingToJson(this);
    }

@JsonSerializable()
class CommandBinding extends Binding {

    GestureShape gestureShape;
    List<Direction> swipeDirections;
    int command;
    int fingerCount;
    int modifierCount;

    CommandBinding({ required this.gestureShape, this.swipeDirections=const <Direction>[], required this.command, this.fingerCount=1, this.modifierCount=0, required int id, required String name }) : super(id: id, name: name);

    factory CommandBinding.fromJson(Map<String, dynamic> json) => _$CommandBindingFromJson(json);

    Map<String, dynamic> toJson() => _$CommandBindingToJson(this);
    }

enum GestureShape {
    Swipe,
    Tap,
    }
enum Direction {
    Left,
    Right,
    Up,
    Down,
    }

class ListMove {
    const ListMove({ required this.shift, required this.absolute });

    final int shift;
    final bool absolute;

    static ListMove? fromString(String input) {
        if (!moveRegExp.hasMatch(input))
        return null;

        final absolute=input.startsWith('/');

        String shiftSubstring;

        if (absolute)
        shiftSubstring=input.substring(1);
        else
        shiftSubstring=input;

        int shift=int.parse(shiftSubstring);

        if (absolute) {
            shift-=1;

            if (shift<0)
            return null;
            }

        return ListMove(shift: shift, absolute: absolute);
        }

    bool applyOn<T>(List<T> list, int index) {
        if (absolute)
        return _positionItem(list, index, shift);
        else
        return _shiftItem(list, index, shift);
        }

    bool _shiftItem<T>(List<T> list, int index, int shift) {
        if (list.length==0 || index<0 || index>=list.length)
        return false;

        if (index+shift<0)
        shift=-index;

        if (index+shift>list.length-1)
        shift=(list.length-1)-index;

        T item=list.removeAt(index);
        list.insert(index+shift, item);

        return true;
        }
    bool _positionItem<T>(List<T> list, int index, int shift) {
        if (list.length==0 || index<0 || index>=list.length || shift<0 || shift>=list.length)
        return false;

        T item=list[index];
        list[index]=list[shift];
        list[shift]=item;

        return true;
        }

    static final RegExp moveRegExp=RegExp(r'^/?[+\-]?\d*$');

    }

