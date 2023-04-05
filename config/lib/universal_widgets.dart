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

class DeleteConfirmationScreen extends StatelessWidget {
    const DeleteConfirmationScreen({ super.key, required this.subject });

    final String subject;

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Confirmation'),
                ),
            body: Center(
                child: Column(
                    children: [
                        Text('Are you sure you want to delete ${subject}?'),
                        Row(
                            children: [
                                ElevatedButton(
                                    child: const Text('Yes'),
                                    onPressed: () { Navigator.pop(context, true); },
                                    ),
                                ElevatedButton(
                                    child: const Text('No'),
                                    onPressed: () { Navigator.pop(context, false); },
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            );
        }

    }

class ConfigObjectDropdownButton extends StatefulWidget {
    const ConfigObjectDropdownButton({ super.key, required this.objects, required this.selectedValue, required this.settings, this.onChanged, this.hint });

    final List<ConfigObject> objects;
    final int? selectedValue;
    final Settings settings;
    final Function(int? value)? onChanged;
    final Widget? hint;

    State<ConfigObjectDropdownButton> createState() => _ConfigObjectDropdownButtonState();

    }
class _ConfigObjectDropdownButtonState extends State<ConfigObjectDropdownButton> {

    int? _selectedValue=null;

    @override
    void initState() {
        _selectedValue=widget.selectedValue;

        if (_selectedValue!=null)
        assert(widget.objects.indexWhere((item) => item.id==_selectedValue)>=0);

        super.initState();
        }

    @override
    Widget build(BuildContext context) {
        return DropdownButton<int>(
            onChanged: _dropdownButtonChangeHandler,
            hint: widget.hint,
            value: _selectedValue,
            items: widget.objects.map<DropdownMenuItem<int>>((item) => DropdownMenuItem<int>(
                value: item.id,
                child: Text(item.name),
                )).toList(),
            );
        }

    void _dropdownButtonChangeHandler(int? value) {
        setState(() {
            _selectedValue=value;
            widget.onChanged?.call(value);
            });
        }

    }

class GestureShapeDropdownButton extends StatefulWidget {
    const GestureShapeDropdownButton({ super.key, this.selectedValue=null, this.onChanged=null, this.hint=null });

    final GestureShape? selectedValue;
    final Function(GestureShape? value)? onChanged;
    final Widget? hint;

    @override
    State<GestureShapeDropdownButton> createState() => _GestureShapeDropdownButtonState();
    }
class _GestureShapeDropdownButtonState extends State<GestureShapeDropdownButton> {

    GestureShape? _selectedValue=null;
    var _values=<GestureShape>[GestureShape.Swipe, GestureShape.Tap];

    @override
    void initState() {
        _selectedValue=widget.selectedValue;

        super.initState();
        }

    @override
    Widget build(BuildContext context) {
        return DropdownButton<GestureShape>(
            onChanged: _dropdownButtonChangeHandler,
            hint: widget.hint,
            value: _selectedValue,
            items: _values.map<DropdownMenuItem<GestureShape>>((item) => DropdownMenuItem<GestureShape>(
                value: item,
                child: Text(_gestureShapeToString(item)),
                )).toList(),
            );
        }

    void _dropdownButtonChangeHandler(GestureShape? value) {
        setState(() {
            _selectedValue=value;
            widget.onChanged?.call(value);
            });
        }

    String _gestureShapeToString(GestureShape gestureShape) {
        switch (gestureShape) {
            case GestureShape.Swipe:
            return "Swipe";
            case GestureShape.Tap:
            return "Tap";
            default:
            return "Unknown";
            }
        }
    }

class SwipeDirectionDropdownButton extends StatefulWidget {
    const SwipeDirectionDropdownButton({ super.key, this.selectedValue=null, this.onChanged=null, this.hint=null });

    final Direction? selectedValue;
    final Function(Direction? value)? onChanged;
    final Widget? hint;

    @override
    State<SwipeDirectionDropdownButton> createState() => _SwipeDirectionDropdownButtonState();
    }
class _SwipeDirectionDropdownButtonState extends State<SwipeDirectionDropdownButton> {

    Direction? _selectedValue=null;
    var _values=<Direction?>[null, Direction.Left, Direction.Right, Direction.Up, Direction.Down];

    @override
    void initState() {
        _selectedValue=widget.selectedValue;

        super.initState();
        }

    @override
    Widget build(BuildContext context) {
        return DropdownButton<Direction>(
            onChanged: _dropdownButtonChangeHandler,
            hint: widget.hint,
            value: _selectedValue,
            items: _values.map<DropdownMenuItem<Direction>>((item) => DropdownMenuItem<Direction>(
                value: item,
                child: Text(_directionToString(item)),
                )).toList(),
            );
        }

    void _dropdownButtonChangeHandler(Direction? value) {
        setState(() {
            _selectedValue=value;
            widget.onChanged?.call(value);
            });
        }

    String _directionToString(Direction? direction) {
        switch (direction) {
            case Direction.Left:
            return "Swipe left";
            case Direction.Right:
            return "Swipe right";
            case Direction.Up:
            return "Swipe up";
            case Direction.Down:
            return "Swipe down";
            default:
            return "None";
            }
        }
    }

class GestureShapePicker extends StatefulWidget {
    const GestureShapePicker({ super.key, this.gestureShape=null, this.swipeDirections=const <Direction>[], this.onGestureShapeChanged=null, this.onSwipeDirectionsChanged=null });

    final GestureShape? gestureShape;
    final List<Direction> swipeDirections;
    final Function(GestureShape?)? onGestureShapeChanged;
    final Function(List<Direction>)? onSwipeDirectionsChanged;

    @override
    State<GestureShapePicker> createState() => _GestureShapePickerState();
    }
class _GestureShapePickerState extends State<GestureShapePicker> {

    GestureShape? _gestureShape=null;
    var _swipeDirections=<Direction>[];
    var _lastUsedId=0;

    @override
    void initState() {
        _gestureShape=widget.gestureShape;
        _swipeDirections=List<Direction>.from(widget.swipeDirections);
        }

    @override
    Widget build(BuildContext context) {
        var components=<Widget>[
            GestureShapeDropdownButton(
                selectedValue: _gestureShape,
                onChanged: _gestureShapeDropdownButtonChangeHandler,
                hint: const Text('Gesture shape'),
                ),
            ];

        if (_gestureShape==GestureShape.Swipe) {
            for (int i=0;i<_swipeDirections.length;i++)
            components.add(SwipeDirectionDropdownButton(
                key: ValueKey<int>(_getUnusedId()),
                selectedValue: _swipeDirections[i],
                onChanged: (value) {_swipeDirectionDropdownButtonChangeHandler(i, value);},
                ));

            components.add(SwipeDirectionDropdownButton(
                key: ValueKey<int>(_getUnusedId()),
                selectedValue: null,
                onChanged: (value) {_swipeDirectionDropdownButtonChangeHandler(_swipeDirections.length, value);},
                hint: const Text('+'),
                ));
            }

        return Row(
            children: components,
            );
        }

    void _gestureShapeDropdownButtonChangeHandler(GestureShape? value) {
        setState(() {
            _gestureShape=value;

            widget.onGestureShapeChanged?.call(_gestureShape);
            });
        }
    void _swipeDirectionDropdownButtonChangeHandler(int index, Direction? value) {
        setState(() {
            if (index<_swipeDirections.length) {
                if (value==null)
                _swipeDirections.removeAt(index);
                else
                _swipeDirections[index]=value!;
                }
            else {
                if (value!=null)
                _swipeDirections.add(value!);
                }

            widget.onSwipeDirectionsChanged?.call(_swipeDirections);
            });
        }

    int _getUnusedId() {
        _lastUsedId+=1;
        return _lastUsedId;
        }
    }

