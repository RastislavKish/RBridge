// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings()
  ..actions = (json['actions'] as List<dynamic>)
      .map((e) => Action.fromJson(e as Map<String, dynamic>))
      .toList()
  ..commands = (json['commands'] as List<dynamic>)
      .map((e) => Command.fromJson(e as Map<String, dynamic>))
      .toList()
  ..rings = (json['rings'] as List<dynamic>)
      .map((e) => Ring.fromJson(e as Map<String, dynamic>))
      .toList()
  ..schemes = (json['schemes'] as List<dynamic>)
      .map((e) => Scheme.fromJson(e as Map<String, dynamic>))
      .toList();

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
      'actions': instance.actions,
      'commands': instance.commands,
      'rings': instance.rings,
      'schemes': instance.schemes,
    };

Action _$ActionFromJson(Map<String, dynamic> json) => Action(
      id: json['id'] as int,
      name: json['name'] as String,
      stickyCtrl: json['stickyCtrl'] as bool? ?? false,
      stickyShift: json['stickyShift'] as bool? ?? false,
      stickyAlt: json['stickyAlt'] as bool? ?? false,
      forwardShortcut: json['forwardShortcut'] as String,
      backwardShortcut: json['backwardShortcut'] as String,
    );

Map<String, dynamic> _$ActionToJson(Action instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'stickyCtrl': instance.stickyCtrl,
      'stickyShift': instance.stickyShift,
      'stickyAlt': instance.stickyAlt,
      'forwardShortcut': instance.forwardShortcut,
      'backwardShortcut': instance.backwardShortcut,
    };

Command _$CommandFromJson(Map<String, dynamic> json) => Command(
      id: json['id'] as int,
      name: json['name'] as String,
      stickyCtrl: json['stickyCtrl'] as bool? ?? false,
      stickyShift: json['stickyShift'] as bool? ?? false,
      stickyAlt: json['stickyAlt'] as bool? ?? false,
      shortcut: json['shortcut'] as String,
    );

Map<String, dynamic> _$CommandToJson(Command instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'stickyCtrl': instance.stickyCtrl,
      'stickyShift': instance.stickyShift,
      'stickyAlt': instance.stickyAlt,
      'shortcut': instance.shortcut,
    };

Ring _$RingFromJson(Map<String, dynamic> json) => Ring(
      id: json['id'] as int,
      name: json['name'] as String,
      actions: (json['actions'] as List<dynamic>).map((e) => e as int).toList(),
    );

Map<String, dynamic> _$RingToJson(Ring instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'actions': instance.actions,
    };

Scheme _$SchemeFromJson(Map<String, dynamic> json) => Scheme(
      id: json['id'] as int,
      name: json['name'] as String,
      bindings: Bindings.fromJson(json['bindings'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SchemeToJson(Scheme instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'bindings': instance.bindings,
    };

Bindings _$BindingsFromJson(Map<String, dynamic> json) => Bindings(
      slotBindings: (json['slotBindings'] as List<dynamic>?)
              ?.map((e) => SlotBinding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SlotBinding>[],
      commandBindings: (json['commandBindings'] as List<dynamic>?)
              ?.map((e) => CommandBinding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CommandBinding>[],
    );

Map<String, dynamic> _$BindingsToJson(Bindings instance) => <String, dynamic>{
      'slotBindings': instance.slotBindings,
      'commandBindings': instance.commandBindings,
    };

SlotBinding _$SlotBindingFromJson(Map<String, dynamic> json) => SlotBinding(
      slot: json['slot'] as String,
      ring: json['ring'] as int,
      defaultAction: json['defaultAction'] as int,
      fingerCount: json['fingerCount'] as int? ?? 1,
      modifierCount: json['modifierCount'] as int? ?? 0,
      id: json['id'] as int,
      name: json['name'] as String,
    );

Map<String, dynamic> _$SlotBindingToJson(SlotBinding instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slot': instance.slot,
      'ring': instance.ring,
      'defaultAction': instance.defaultAction,
      'fingerCount': instance.fingerCount,
      'modifierCount': instance.modifierCount,
    };

CommandBinding _$CommandBindingFromJson(Map<String, dynamic> json) =>
    CommandBinding(
      gestureShape: $enumDecode(_$GestureShapeEnumMap, json['gestureShape']),
      swipeDirections: (json['swipeDirections'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$DirectionEnumMap, e))
              .toList() ??
          const <Direction>[],
      command: json['command'] as int,
      fingerCount: json['fingerCount'] as int? ?? 1,
      modifierCount: json['modifierCount'] as int? ?? 0,
      id: json['id'] as int,
      name: json['name'] as String,
    );

Map<String, dynamic> _$CommandBindingToJson(CommandBinding instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'gestureShape': _$GestureShapeEnumMap[instance.gestureShape]!,
      'swipeDirections':
          instance.swipeDirections.map((e) => _$DirectionEnumMap[e]!).toList(),
      'command': instance.command,
      'fingerCount': instance.fingerCount,
      'modifierCount': instance.modifierCount,
    };

const _$GestureShapeEnumMap = {
  GestureShape.Swipe: 'Swipe',
  GestureShape.Tap: 'Tap',
};

const _$DirectionEnumMap = {
  Direction.Left: 'Left',
  Direction.Right: 'Right',
  Direction.Up: 'Up',
  Direction.Down: 'Down',
};
