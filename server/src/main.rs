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

use std::collections::HashMap;
use std::fs;
use std::path::Path;

use enigo::{Enigo, Key, KeyboardControllable};

use futures_util::{SinkExt, StreamExt};

use lazy_static::lazy_static;
use regex::Regex;

use serde::{Serialize, Deserialize};

use tokio::net::{TcpListener, TcpStream};
use tokio::sync::{broadcast, mpsc};
use tungstenite::Message;
use url::Url;

#[derive(Clone, Serialize, Deserialize)]
#[serde(default)]
#[serde(rename_all(deserialize="camelCase"))]
struct Action {
    id: i32,
    name: String,
    sticky_ctrl: bool,
    sticky_shift: bool,
    sticky_alt: bool,
    forward_shortcut: String,
    backward_shortcut: String,
    #[serde(skip)]
    forward_operation: Operation,
    #[serde(skip)]
    backward_operation: Operation,
    }
impl Action {

    fn new(id: i32, name: &str, sticky_ctrl: bool, sticky_shift: bool, sticky_alt: bool, forward_shortcut: &str, backward_shortcut: &str) -> Action {
        Action { id, name: name.to_string(), sticky_ctrl, sticky_shift, sticky_alt, forward_shortcut: forward_shortcut.to_string(), backward_shortcut: backward_shortcut.to_string(), forward_operation: Operation::from_str(forward_shortcut), backward_operation: Operation::from_str(backward_shortcut) }
        }

    fn finalize(&mut self) -> Result<(), String> {
        self.forward_operation=Operation::from_str(&self.forward_shortcut);
        self.backward_operation=Operation::from_str(&self.backward_shortcut);

        Ok(())
        }
    }
impl Default for Action {

    fn default() -> Action {
        Action::new(-1, "Unknown", false, false, false, "", "")
        }
    }

#[derive(Clone, Serialize, Deserialize)]
#[serde(default)]
#[serde(rename_all(deserialize="camelCase"))]
struct Command {
    id: i32,
    name: String,
    sticky_ctrl: bool,
    sticky_shift: bool,
    sticky_alt: bool,
    shortcut: String,
    #[serde(skip)]
    operation: Operation,
    }
impl Command {

    fn new(id: i32, name: &str, sticky_ctrl: bool, sticky_shift: bool, sticky_alt: bool, shortcut: &str) -> Command {
        Command { id, name: name.to_string(), sticky_ctrl, sticky_shift, sticky_alt, shortcut: shortcut.to_string(), operation: Operation::from_str(shortcut) }
        }

    fn finalize(&mut self) -> Result<(), String> {
        self.operation=Operation::from_str(&self.shortcut);

        Ok(())
        }
    }
impl Default for Command {

    fn default() -> Command {
        Command::new(-1, "Unknown", false, false, false, "")
        }
    }

#[derive(Clone, Serialize, Deserialize)]
#[serde(default)]
#[serde(rename_all(deserialize="camelCase"))]
struct Ring {
    id: i32,
    name: String,
    actions: Vec<i32>,
    #[serde(skip)]
    action_instances: Vec<Action>,
    }
impl Ring {

    fn new(id: i32, name: &str, actions: Vec<i32>) -> Ring {
        Ring { id, name: name.to_string(), actions, action_instances: vec![] }
        }

    fn finalize(&mut self, actions: &Vec<Action>) -> Result<(), String> {
        let mut action_instances: Vec<Action>=Vec::new();

        for action_id in &self.actions {
            let mut id_processed=false;
            for action_instance in actions {
                if action_instance.id==*action_id {
                    action_instances.push(action_instance.clone());
                    id_processed=true;
                    break;
                    }
                }
            if !id_processed {
                return Err(format!("Unable to find action with id {}", action_id));
                }
            }

        self.action_instances=action_instances;

        Ok(())
        }
    }
impl Default for Ring {

    fn default() -> Ring {
        Ring::new(-1, "Unknown", vec![])
        }
    }

#[derive(Clone, Serialize, Deserialize)]
#[serde(default)]
#[serde(rename_all(deserialize="camelCase"))]
struct SlotBinding {
    id: i32,
    name: String,
    slot: String,
    ring: i32,
    default_action: i32,
    finger_count: i32,
    modifier_count: i32,
    #[serde(skip)]
    default_position: usize,
    #[serde(skip)]
    position: usize,
    #[serde(skip)]
    ring_instance: Ring,
    }
impl SlotBinding {

    fn new(id: i32, name: &str, slot: &str, ring: i32, default_action: i32, finger_count: i32, modifier_count: i32) -> SlotBinding {
        SlotBinding { id, name: name.to_string(), slot: slot.to_string(), ring, default_action, finger_count, modifier_count, default_position: 0, position: 0, ring_instance: Ring::default() }
        }

    fn active_action(&self) -> Option<&Action> {
        if self.ring_instance.action_instances.len()==0 {
            return None;
            }

        Some(&self.ring_instance.action_instances[self.position])
        }
    fn previous_action(&mut self) {
        if self.ring_instance.action_instances.len()==0 {
            return;
            }

        if self.position==0 {
            self.position=self.ring_instance.action_instances.len()-1;
            }
        else {
            self.position-=1;
            }
        }
    fn next_action(&mut self) {
        if self.ring_instance.action_instances.len()==0 {
            return;
            }

        self.position+=1;
        self.position%=self.ring_instance.action_instances.len();
        }
    fn default_action(&mut self) {
        self.position=self.default_position;
        }

    fn finalize(&mut self, rings: &Vec<Ring>) -> Result<(), String> {
        for ring in rings {
            if ring.id==self.ring {
                self.ring_instance=ring.clone();

                let mut default_position_set=false;

                for (index, action_id) in ring.actions.iter().enumerate() {
                    if *action_id==self.default_action {
                        self.default_position=index;
                        self.position=self.default_position;
                        default_position_set=true;
                        break;
                        }
                    }

                if !default_position_set {
                    return Err(format!("Error while finalizing SlotBinding {}: Ring {} does nto contain default action {}.", self.id, self.ring, self.default_action));
                    }

                return Ok(());
                }
            }

        return Err(format!("Unable to find ring with id {}", self.ring));
        }
    }
impl Default for SlotBinding {

    fn default() -> SlotBinding {
        SlotBinding::new(-1, "Unknown", "", -1, -1, 1, 0)
        }
    }

#[derive(Clone, Serialize, Deserialize)]
#[serde(default)]
#[serde(rename_all(deserialize="camelCase"))]
struct CommandBinding {
    id: i32,
    name: String,
    gesture_shape: String,
    swipe_directions: Vec<String>,
    command: i32,
    finger_count: i32,
    modifier_count: i32,
    #[serde(skip)]
    gesture_shape_instance: GestureShape,
    #[serde(skip)]
    command_instance: Command,
    }
impl CommandBinding {

    fn new(id: i32, name: &str, gesture_shape: &str, swipe_directions: Vec<String>, command: i32, finger_count: i32, modifier_count: i32) -> CommandBinding {
        CommandBinding { id, name: name.to_string(), gesture_shape: gesture_shape.to_string(), swipe_directions, command, finger_count, modifier_count, gesture_shape_instance: GestureShape::Touch, command_instance: Command::default() }
        }

    fn finalize(&mut self, commands: &Vec<Command>) -> Result<(), String> {
        self.gesture_shape_instance=match &self.gesture_shape[..] {
            "Swipe" => {
                let mut swipe_directions: Vec<Direction>=Vec::new();

                for direction in &self.swipe_directions {
                    swipe_directions.push(match &direction[..] {
                        "Left" => Direction::Left,
                        "Right" => Direction::Right,
                        "Up" => Direction::Up,
                        "Down" => Direction::Down,
                        _ => continue,
                        });
                    }

                GestureShape::Swipe(swipe_directions)
                },
            "Tap" => GestureShape::Tap,
            _ => GestureShape::Touch,
            };

        for command in commands {
            if command.id==self.command {
                self.command_instance=command.clone();

                return Ok(());
                }
            }

        return Err(format!("Unable to find command with id {}", self.command));
        }
    }
impl Default for CommandBinding {

    fn default() -> CommandBinding {
        CommandBinding::new(-1, "Unknown", "Touch", vec![], -1, 1, 0)
        }
    }

#[derive(Clone, Serialize, Deserialize)]
#[serde(default)]
#[serde(rename_all(deserialize="camelCase"))]
struct Bindings {
    slot_bindings: Vec<SlotBinding>,
    command_bindings: Vec<CommandBinding>,
    }
impl Bindings {

    fn new(slot_bindings: Vec<SlotBinding>, command_bindings: Vec<CommandBinding>) -> Bindings {
        Bindings { slot_bindings, command_bindings }
        }

    fn finalize(&mut self, commands: &Vec<Command>, rings: &Vec<Ring>) -> Result<(), String> {
        for binding in &mut self.slot_bindings {
            binding.finalize(rings)?;
            }
        for binding in &mut self.command_bindings {
            binding.finalize(commands)?;
            }

        Ok(())
        }
    }
impl Default for Bindings {

    fn default() -> Bindings {
        Bindings::new(vec![], vec![])
        }
    }

#[derive(Clone, Serialize, Deserialize)]
#[serde(default)]
#[serde(rename_all(deserialize="camelCase"))]
struct Scheme {
    id: i32,
    name: String,
    bindings: Bindings,
    }
impl Scheme {

    fn new(id: i32, name: &str, bindings: Bindings) -> Scheme {
        Scheme { id, name: name.to_string(), bindings }
        }

    fn finalize(&mut self, commands: &Vec<Command>, rings: &Vec<Ring>) -> Result<(), String> {
        self.bindings.finalize(commands, rings)?;

        Ok(())
        }
    }
impl Default for Scheme {

    fn default() -> Scheme {
        Scheme::new(-1, "Unknown", Bindings::default())
        }
    }

#[derive(Clone)]
pub struct BrailleSchemeManager {
    schemes: Vec<BrailleScheme>,
    }
impl BrailleSchemeManager {

    pub fn new() -> BrailleSchemeManager {
        BrailleSchemeManager { schemes: vec![] }
        }

    pub fn from_directory(path: &str) -> Result<BrailleSchemeManager, String> {
        let mut schemes: Vec<BrailleScheme>=Vec::new();

        let path=Path::new(path);

        if !path.exists() {
            return Err(format!("Path {} doesn't exist", path.display()));
            }

        if !path.is_dir() {
            return Err(format!("Path {} is not a directory", path.display()));
            }

        for entry in fs::read_dir(path).map_err(|e| e.to_string())? {
            let entry=entry.map_err(|e| e.to_string())?;
            let scheme_path=entry.path();

            if scheme_path.is_dir() {
                schemes.push(BrailleScheme::from_directory(&scheme_path.display().to_string())?);
                }
            }

        Ok(BrailleSchemeManager { schemes })
        }

    pub fn switch_mapping(&mut self, switch_type: &SwitchType) -> Result<(), String> {
        if self.schemes.len()==0 {
            return Err(format!("no braille schemes"));
            }

        self.schemes[0].switch_mapping(switch_type)?;

        Ok(())
        }
    pub fn translate_combination(&mut self, combination: usize) -> Option<Operation> {
        if self.schemes.len()==0 {
            return None;
            }

        self.schemes[0].translate_combination(combination)
        }

    pub fn current_mapping_name(&self) -> String {
        if self.schemes.len()==0 {
            return "".to_string();
            }

        self.schemes[0].current_mapping_name()
        }

    }

#[derive(Clone)]
pub struct BrailleScheme {
    name: String,
    mapping_stack: Vec<BrailleMappingStackLayer>,
    mappings: HashMap<String, BrailleMapping>,
    }
impl BrailleScheme {

    pub fn from_directory(path: &str) -> Result<BrailleScheme, String> {
        //First, load the files of the scheme

        let files=BrailleScheme::load_bsc_files(path)?;

        let name=Path::new(path).file_name().unwrap().to_str().unwrap().to_string();

        if !files.contains_key("default") {
            return Err(format!("Braille scheme {} doesn't have a default scheme", name));
            }

        let mut mappings: HashMap<String, BrailleMapping>=HashMap::new();

        for key in files.keys() {
            let mapping=BrailleMapping::from_script(key, &files[key])?;

            mappings.insert(key.to_string(), mapping);
            }

        let default_mapping=mappings["default"].clone();
        let mapping_stack: Vec<BrailleMappingStackLayer>=vec![BrailleMappingStackLayer::new(default_mapping, false)];

        Ok(BrailleScheme { name, mapping_stack, mappings })
        }

    pub fn switch_mapping(&mut self, switch_type: &SwitchType) -> Result<(), String> {
        match switch_type {
            SwitchType::Append(name) => {
                if let Some(appended_mapping)=self.mappings.get(name) {
                    let stack_layer=BrailleMappingStackLayer::new(appended_mapping.clone(), false);

                    self.mapping_stack.push(stack_layer);
                    }
                else {
                    return Err(format!("Mapping {} not found", &name));
                    }
                },
            SwitchType::TemporaryAppend(name) => {
                if let Some(appended_mapping)=self.mappings.get(name) {
                    let stack_layer=BrailleMappingStackLayer::new(appended_mapping.clone(), true);

                    self.mapping_stack.push(stack_layer);
                    }
                else {
                    return Err(format!("Mapping {} not found", &name));
                    }
                },
            SwitchType::Return => {
                if self.mapping_stack.len()==1 {
                    return Ok(());
                    }

                self.mapping_stack.pop();
                },
            SwitchType::Default => {
                while self.mapping_stack.len()>1 {
                    self.mapping_stack.pop();
                    }
                },
            }

        Ok(())
        }
    pub fn translate_combination(&mut self, combination: usize) -> Option<Operation> {
        if self.mapping_stack.len()==0 {
            return self.mapping_stack[0].mapping.get(combination);
            }

        let mapping_stack_layer=&self.mapping_stack.last().unwrap();

        let result=mapping_stack_layer.mapping.get(combination);

        if mapping_stack_layer.temporary {
            drop(mapping_stack_layer);
            self.mapping_stack.pop();
            }

        result
        }

    pub fn current_mapping_name(&self) -> String {
        self.mapping_stack.last().unwrap().mapping.name()
        }
    pub fn name(&self) -> String {
        self.name.clone()
        }

    fn load_bsc_files(path: &str) -> Result<HashMap<String, String>, String> {
        let mut files: HashMap<String, String>=HashMap::new();

        let path=Path::new(path);

        if !path.exists() {
            return Err(format!("Path {} doesn't exist", path.display()));
            }

        if !path.is_dir() {
            return Err(format!("Path {} is not a directory", path.display()));
            }

        for entry in fs::read_dir(path).map_err(|e| e.to_string())? {
            let entry=entry.map_err(|e| e.to_string())?;
            let file_path=entry.path();

            if file_path.is_file() && file_path.extension().map_or(false, |ext| ext=="bsc") {
                let file_name=file_path.file_stem().and_then(|n| n.to_str()).unwrap_or("").to_string();
                let file_content=fs::read_to_string(&file_path).map_err(|e| e.to_string())?;

                files.insert(file_name, file_content);
                }

            }

        Ok(files)
        }
    }

#[derive(Clone)]
pub struct BrailleMapping {
    name: String,
    mapping: Vec<Option<Operation>>,
    }
impl BrailleMapping {

    pub fn new(name: &str) -> BrailleMapping {
        BrailleMapping { name: name.to_string(), mapping: vec![None; 64] }
        }

    pub fn from_script(name: &str, script: &str) -> Result<BrailleMapping, String> {
        let mut mapping=BrailleMapping::new(name);

        lazy_static! {
            static ref ASSIGNMENT_REGEX: Regex=Regex::new(r"^.*=([1-6]+)$").unwrap();
            }

        for line in script.lines() {
            if line=="" {
                continue;
                }

            if line.starts_with("//") {
                continue;
                }

            if ASSIGNMENT_REGEX.is_match(line) {
                let caps=ASSIGNMENT_REGEX.captures(line).unwrap();

                let operation_string=caps.get(1).unwrap().as_str();
                let combination_string=caps.get(2).unwrap().as_str();

                let operation=Operation::from_str(operation_string);

                let mut combination=0usize;

                for digit_char in combination_string.chars() {
                    let digit=digit_char.to_digit(10).unwrap() as usize;

                    combination=combination | (2usize.pow((digit-1) as u32));
                    }

                mapping.set(combination, Some(operation));
                }
            else {
                eprintln!("Warning: {}.bsc, invalid line \"{}\"", name, line);
                }
            }

        Ok(mapping)
        }

    pub fn get(&self, combination: usize) -> Option<Operation> {
        assert!(combination<=64);

        self.mapping[combination].clone()
        }
    pub fn set(&mut self, combination: usize, operation: Option<Operation>) {
        assert!(combination<=64);

        self.mapping[combination]=operation;
        }

    pub fn name(&self) -> String {
        self.name.clone()
        }

    }

#[derive(Clone)]
struct BrailleMappingStackLayer {
    pub mapping: BrailleMapping,
    pub temporary: bool,
    }
impl BrailleMappingStackLayer {

    pub fn new(mapping: BrailleMapping, temporary: bool) -> BrailleMappingStackLayer {
        BrailleMappingStackLayer { mapping, temporary }
        }
    }

#[derive(Clone, Serialize, Deserialize)]
#[serde(default)]
#[serde(rename_all(deserialize="camelCase"))]
struct Settings {
    actions: Vec<Action>,
    commands: Vec<Command>,
    rings: Vec<Ring>,
    schemes: Vec<Scheme>,
    #[serde(skip)]
    braille_scheme_manager: BrailleSchemeManager,
    }
impl Settings {

    fn new(actions: Vec<Action>, commands: Vec<Command>, rings: Vec<Ring>, schemes: Vec<Scheme>) -> Settings {
        let braille_scheme_manager=BrailleSchemeManager::new();

        Settings { actions, commands, rings, schemes, braille_scheme_manager }
        }

    fn from_json(json: &str) -> Result<Settings, String> {
        match serde_json::from_str::<Settings>(json) {
            Ok(mut settings) => {
                settings.finalize()?;
                return Ok(settings);
                },
            Err(error) => {
                return Err(error.to_string());
                }
            }
        }

    fn finalize(&mut self) -> Result<(), String> {
        for action in &mut self.actions {
            action.finalize()?;
            }
        for command in &mut self.commands {
            command.finalize()?;
            }
        for ring in &mut self.rings {
            ring.finalize(&self.actions)?;
            }
        for scheme in &mut self.schemes {
            scheme.finalize(&self.commands, &self.rings)?;
            }

        self.braille_scheme_manager=BrailleSchemeManager::from_directory("braille_schemes")?;

        Ok(())
        }

    }
impl Default for Settings {

    fn default() -> Settings {
        Settings::new(vec![], vec![], vec![], vec![])
        }
    }

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(default)]
#[serde(rename_all(deserialize="camelCase"))]
struct Gesture {
    finger_count: i32,
    modifier_count: i32,
    start_x: f32,
    start_y: f32,
    shape: GestureShape,
    }
impl Gesture {

    fn new(finger_count: i32, modifier_count: i32, start_x: f32, start_y: f32, shape: GestureShape) -> Gesture {
        Gesture { finger_count, modifier_count, start_x, start_y, shape }
        }

    fn try_get_slot_operation(&self) -> Result<(&str, SlotOperation), &str> {
        use Direction::{Left, Right, Up, Down};

        if let GestureShape::Swipe(directions)=&self.shape {
            if !(directions.len()>=1 && directions.len()<=3) {
                return Err("Not a slot gesture");
                }

            let initial_direction=&directions[0];

            let slot: &str;

            if *initial_direction==Left || *initial_direction==Right {
                if self.finger_count==1 {
                    slot=if self.start_y<0.2 {
                        "1h"
                        }
                    else if self.start_y<=0.8 {
                        "2h"
                        }
                    else {
                        "3h"
                        };
                    }
                else {
                    slot="h";
                    }
                }
            else {
                if self.finger_count==1 {
                    slot=if self.start_x<0.2 {
                        "1v"
                        }
                    else if self.start_x<=0.8 {
                        "2v"
                        }
                    else {
                        "3v"
                        };
                    }
                else {
                    slot="v";
                    }
                }

            if directions.len()==1 {
                if *initial_direction==Left || *initial_direction==Up {
                    return Ok((slot, SlotOperation::Backward));
                    }
                else if *initial_direction==Right || *initial_direction==Down {
                    return Ok((slot, SlotOperation::Forward));
                    }
                }
            else if directions.len()==2 {
                if *directions==vec![Left, Right] || *directions==vec![Up, Down] {
                    return Ok((slot, SlotOperation::PreviousAction));
                    }
                else if *directions==vec![Right, Left] || *directions==vec![Down, Up] {
                    return Ok((slot, SlotOperation::NextAction));
                    }
                }
            else if directions.len()==3 {
                if *directions==vec![Left, Right, Left]
                || *directions==vec![Right, Left, Right]
                || *directions==vec![Up, Down, Up]
                || *directions==vec![Down, Up, Down] {
                    return Ok((slot, SlotOperation::DefaultAction));
                    }
                }
            }

        Err("Not a slot gesture")
        }
    }
impl Default for Gesture {

    fn default() -> Gesture {
        Gesture::new(0, 0, 0.0f32, 0.0f32, GestureShape::Touch)
        }
    }

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
enum GestureShape {
    Swipe(Vec<Direction>),
    Tap,
    Touch,
    }

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
enum Direction {
    Left,
    Right,
    Up,
    Down,
    }

enum SlotOperation {
    Forward,
    Backward,
    PreviousAction,
    NextAction,
    DefaultAction,
    }

#[derive(Clone, Debug)]
pub enum Operation {
    Shortcut(bool, bool, bool, bool, bool, Key),
    SchemeSwitch(SwitchType),
    None,
    }
impl Operation {

    fn from_str(input: &str) -> Operation {
        //First, check scheme switch since it's case sensitive

        lazy_static! {
            static ref SCHEME_SWITCH_OPERATION_REGEX: Regex=Regex::new(r"^(\&+)([^\&].*)$").unwrap();
            }

        if input.len()>1 {
            if SCHEME_SWITCH_OPERATION_REGEX.is_match(input) {
                let caps=SCHEME_SWITCH_OPERATION_REGEX.captures(input).unwrap();

                let ampersants=caps.get(1).unwrap().as_str();
                let switch_operation=caps.get(2).unwrap().as_str();

                let switch_type=match &switch_operation[..] {
                    "default" => SwitchType::Default,
                    "return" => SwitchType::Return,
                    scheme_name => {
                        if ampersants.len()==1 {
                            SwitchType::TemporaryAppend(scheme_name.to_string())
                            }
                        else {
                            SwitchType::Append(scheme_name.to_string())
                            }
                        },
                    };

                return Operation::SchemeSwitch(switch_type);
                }
            }

        let processed_input=input.trim().to_string().to_lowercase();

        if processed_input=="" { return Operation::None; }

        //Before parsing a full-fledged shortcut, we need to check if the user doesn't want to just press the meta key, since it can be used both as a modifier and an individual key
        if processed_input=="meta" {
            return Operation::Shortcut(false, false, false, false, false, Key::Meta);
            }

        let mut ctrl=false;
        let mut shift=false;
        let mut alt=false;
        let mut meta=false;
        let mut caps_lock=false;
        let mut key: Option<Key>=None;

        for component in processed_input.split("+") {
            let mut modifier=true;
            //Check modifiers
            match component {
                "control" | "ctrl" => ctrl=true,
                "shift" => shift=true,
                "alt" => alt=true,
                "meta" => meta=true,
                "capslock" => caps_lock=true,
                _ => modifier=false,
                }

            if modifier { continue; }

            key=Some(match component {
                "left" => Key::LeftArrow,
                "right" => Key::RightArrow,
                "up" => Key::UpArrow,
                "down" => Key::DownArrow,
                "tab" => Key::Tab,
                "home" => Key::Home,
                "end" => Key::End,
                "pageup" => Key::PageUp,
                "pagedown" => Key::PageDown,
                "delete" => Key::Delete,
                "backspace" => Key::Backspace,
                "return" | "enter" => Key::Return,
                "space" => Key::Space,
                "escape" | "esc" => Key::Escape,
                "f1" => Key::F1,
                "f2" => Key::F2,
                "f3" => Key::F3,
                "f4" => Key::F4,
                "f5" => Key::F5,
                "f6" => Key::F6,
                "f7" => Key::F7,
                "f8" => Key::F8,
                "f9" => Key::F9,
                "f10" => Key::F10,
                "f11" => Key::F11,
                "f12" => Key::F12,
                any => {
                    if any.chars().count()!=1 {
                        continue;
                        }

                    Key::Layout(any.chars().next().unwrap())
                    }
                });
            }

        if let Some(key_instance)=key {
            return Operation::Shortcut(ctrl, shift, alt, meta, caps_lock, key_instance);
            }

        Operation::None
        }
    }

#[derive(Clone, Debug)]
pub enum SwitchType {
    Append(String),
    TemporaryAppend(String),
    Return,
    Default,
    }

#[derive(Clone, Debug)]
enum InputMode {
    Standard,
    Braille,
    }

#[derive(Clone, Debug)]
enum ClientMessage {
    Gesture(Gesture),
    Braille(usize),
    InputMode(InputMode),
    }
impl ClientMessage {

    fn from_bytes(bytes: &Vec<u8>) -> Result<ClientMessage, String> {
        if bytes.len()==0 {
            return Err("empty message".to_string());
            }

        match bytes[0] {
            0 => { //A gesture
                if bytes.len()<6 {
                    return Err(format!("{} bytes is not enough to define a gesture client message.", bytes.len()));
                    }

                let finger_count=bytes[1] as i32;
                let modifier_count=bytes[2] as i32;
                let start_x=(bytes[3] as f32)/100f32;
                let start_y=(bytes[4] as f32)/100f32;

                let shape=match bytes[5] {
                    0 => {//Swipe
                        if bytes.len()<7 {
                            return Err("Received a swipe gesture without swipe directions".to_string());
                            }

                        let mut swipe_directions: Vec<Direction>=Vec::new();

                        for byte in &bytes[6..] {
                            swipe_directions.push(match byte {
                                0 => Direction::Left,
                                1 => Direction::Right,
                                2 => Direction::Up,
                                3 => Direction::Down,
                                direction => return Err(format!("Invalid swipe direction {}", direction)),
                                });
                            }

                        GestureShape::Swipe(swipe_directions)
                        },
                    1 => {//Tap
                        GestureShape::Tap
                        }
                    2 => GestureShape::Touch,
                    shape_identifier => return Err(format!("{} is an unknown gesture shape identifier", shape_identifier)),
                    };

                let gesture=Gesture::new(finger_count, modifier_count, start_x, start_y, shape);

                return Ok(ClientMessage::Gesture(gesture));
                },
            1 => { //Braille input
                if bytes.len()!=2 {
                    return Err(format!("Invalid byte count for a braille client message ({}).", bytes.len()));
                    }

                let combination=bytes[1] as usize;

                return Ok(ClientMessage::Braille(combination));
                },
            2 => { //Input mode change
                if bytes.len()!=2 {
                    return Err(format!("Invalid byte count ({}) for an input mode client message.", bytes.len()));
                    }

                let input_mode=match bytes[1] {
                    0 => InputMode::Standard,
                    1 => InputMode::Braille,
                    identifier => return Err(format!("Invalid input mode identifier ({}) in a client message", identifier)),
                    };

                return Ok(ClientMessage::InputMode(input_mode));
                },
            identifier => return Err(format!("Unknown client message identifier {}.", identifier)),
            }
        }

    }

struct KeyExecutor {
    last_executed_object_id: i32,
    ctrl_down: bool,
    shift_down: bool,
    alt_down: bool,
    meta_down: bool,
    caps_lock_down: bool,
    enigo: Enigo,
    }
impl KeyExecutor {

    fn new() -> KeyExecutor {
        KeyExecutor { last_executed_object_id: -1, ctrl_down: false, shift_down: false, alt_down: false, meta_down: false, caps_lock_down: false, enigo: Enigo::new() }
        }

    fn execute(&mut self, object_id: i32, operation: &Operation, sticky_ctrl: bool, sticky_shift: bool, sticky_alt: bool) {
        if let Operation::Shortcut(ctrl, shift, alt, meta, caps_lock, key)=operation {
            if object_id!=self.last_executed_object_id {
                self.last_executed_object_id=object_id;

                self.release_modifiers();
                }

            if *ctrl { self.ctrl_down(); }
            if *shift { self.shift_down(); }
            if *alt { self.alt_down(); }
            if *meta { self.meta_down(); }
            if *caps_lock { self.caps_lock_down(); }

            self.enigo.key_click(key.clone());

            if !sticky_ctrl { self.ctrl_up(); }
            if !sticky_shift { self.shift_up(); }
            if !sticky_alt { self.alt_up(); }
            self.meta_up();
            self.caps_lock_up();
            }
        }

    fn release_modifiers(&mut self) {
        self.ctrl_up();
        self.shift_up();
        self.alt_up();
        self.meta_up();
        self.caps_lock_up();
        }

    fn ctrl_down(&mut self) {
        if !self.ctrl_down {
            self.enigo.key_down(Key::Control);
            self.ctrl_down=true;
            }
        }
    fn shift_down(&mut self) {
        if !self.shift_down {
            self.enigo.key_down(Key::Shift);
            self.shift_down=true;
            }
        }
    fn alt_down(&mut self) {
        if !self.alt_down {
            self.enigo.key_down(Key::Alt);
            self.alt_down=true;
            }
        }
    fn meta_down(&mut self) {
        if !self.meta_down {
            self.enigo.key_down(Key::Meta);
            self.meta_down=true;
            }
        }
    fn caps_lock_down(&mut self) {
        if !self.caps_lock_down {
            self.enigo.key_down(Key::CapsLock);
            self.caps_lock_down=true;
            }
        }

    fn ctrl_up(&mut self) {
        if self.ctrl_down {
            self.enigo.key_up(Key::Control);
            self.ctrl_down=false;
            }
        }
    fn shift_up(&mut self) {
        if self.shift_down {
            self.enigo.key_up(Key::Shift);
            self.shift_down=false;
            }
        }
    fn alt_up(&mut self) {
        if self.alt_down {
            self.enigo.key_up(Key::Alt);
            self.alt_down=false;
            }
        }
    fn meta_up(&mut self) {
        if self.meta_down {
            self.enigo.key_up(Key::Meta);
            self.meta_down=false;
            }
        }
    fn caps_lock_up(&mut self) {
        if self.caps_lock_down {
            self.enigo.key_up(Key::CapsLock);
            self.caps_lock_down=false;
            }
        }
    }

struct Executor {
    settings: Settings,
    execution_sender: broadcast::Sender<String>,
    key_executor: KeyExecutor,
    }
impl Executor {

    fn new(settings: Settings, execution_sender: broadcast::Sender<String>) -> Executor {
        Executor { settings, execution_sender, key_executor: KeyExecutor::new() }
        }

    fn process_gesture(&mut self, gesture: &Gesture) {
        let active_scheme=&mut self.settings.schemes[0];

        //First, check if the gesture is defined in a command binding

        for binding in &mut active_scheme.bindings.command_bindings {
            if binding.gesture_shape_instance==gesture.shape && binding.finger_count==gesture.finger_count && binding.modifier_count==gesture.modifier_count {
                let command=&binding.command_instance;
                self.key_executor.execute(command.id, &command.operation, command.sticky_ctrl, command.sticky_shift, command.sticky_alt);
                return;
                }
            }

        //If not, check slot bindings

        if let Ok((slot, slot_operation))=gesture.try_get_slot_operation() {
            for binding in &mut active_scheme.bindings.slot_bindings {
                if binding.slot==slot && binding.finger_count==gesture.finger_count && binding.modifier_count==gesture.modifier_count {
                    match slot_operation {
                        SlotOperation::Forward => {
                            if let Some(action)=binding.active_action() {
                                self.key_executor.execute(action.id, &action.forward_operation, action.sticky_ctrl, action.sticky_shift, action.sticky_alt);
                                }
                            },
                        SlotOperation::Backward => {
                            if let Some(action)=binding.active_action() {
                                self.key_executor.execute(action.id, &action.backward_operation, action.sticky_ctrl, action.sticky_shift, action.sticky_alt);
                                }
                            },
                        SlotOperation::PreviousAction => {
                            binding.previous_action();
                            if let Some(active_action)=binding.active_action() {
                                self.execution_sender.send(active_action.name.clone()).unwrap();
                                }
                            }
                        SlotOperation::NextAction => {
                            binding.next_action();
                            if let Some(active_action)=binding.active_action() {
                                self.execution_sender.send(active_action.name.clone()).unwrap();
                                }
                            }
                        SlotOperation::DefaultAction => {
                            binding.default_action();
                            if let Some(active_action)=binding.active_action() {
                                self.execution_sender.send(active_action.name.clone()).unwrap();
                                }
                            }
                        }
                    }
                }
            }
        }
    fn process_braille(&mut self, combination: usize) {
        if let Some(operation)=self.settings.braille_scheme_manager.translate_combination(combination) {
            if let Operation::SchemeSwitch(switch_type)=operation {
                if let Err(e)=self.settings.braille_scheme_manager.switch_mapping(&switch_type) {
                    self.execution_sender.send(e).unwrap();
                    return;
                    }

                let current_mapping_name=self.settings.braille_scheme_manager.current_mapping_name();
                self.execution_sender.send(current_mapping_name).unwrap();
                return;
                }

            let id=-(combination as i32);

            self.key_executor.execute(id, &operation, false, false, false);
            }
        }
    fn process_input_mode(&mut self, _input_mode: InputMode) {

        }
    }

#[tokio::main]
async fn main() {
    let (communication_sender, communication_receiver)=mpsc::channel::<ClientMessage>(10);
    let (execution_sender, _)=broadcast::channel::<String>(10);

    tokio::spawn(execution_thread(communication_receiver, execution_sender.clone()));

    let server=TcpListener::bind(&get_host()).await.unwrap();

    println!("Launched server on {:?}", local_ip_address::local_ip().unwrap());

    while let Ok((stream, _))=server.accept().await {
        println!("Incoming stream");
        let execution_receiver=execution_sender.subscribe();
        tokio::spawn(communication_thread(stream, communication_sender.clone(), execution_receiver));
        }
    }

async fn communication_thread(stream: TcpStream, communication_sender: mpsc::Sender<ClientMessage>, mut execution_receiver: broadcast::Receiver<String>) {
    let ws_stream=tokio_tungstenite::accept_async(stream).await.unwrap();
    let (mut ws_sender, mut ws_receiver)=ws_stream.split();

    println!("New connection established");

    let mut authenticated=false;

    loop {
        tokio::select! {
            msg = ws_receiver.next() => {
                if let Some(Ok(msg))=msg {
                    match msg {
                        Message::Binary(data) => {
                            if !authenticated { continue; }

                            if let Ok(client_message)=ClientMessage::from_bytes(&data) {
                                communication_sender.send(client_message).await.unwrap();
                                }
                            },
                        Message::Text(text) => {
                            if text=="random_password" {
                                authenticated=true;
                                println!("Authenticated!");
                                continue;
                                }
                            },
                        _ => {},
                        }
                    }
                else {
                    break;
                    }
                }
            msg = execution_receiver.recv() => {
                if let Ok(msg)=msg {
                    ws_sender.send(Message::Text(msg)).await.unwrap();
                    }
                }
            }
        }

    println!("A connection closed");
    }
async fn execution_thread(mut communication_receiver: mpsc::Receiver<ClientMessage>, execution_sender: broadcast::Sender<String>) {
    let settings=Settings::from_json(&fs::read_to_string("settings.json").unwrap()).unwrap();

    let mut executor=Executor::new(settings, execution_sender);

    while let Some(client_message)=communication_receiver.recv().await {
        match client_message {
            ClientMessage::Gesture(gesture) => executor.process_gesture(&gesture),
            ClientMessage::Braille(combination) => executor.process_braille(combination),
            ClientMessage::InputMode(input_mode) => executor.process_input_mode(input_mode),
            }
        }
    }

fn get_host() -> String {
    if let Ok(host)=std::env::var("RBRIDGE_HOST") {
        if let Ok(url)=Url::parse(&host) {
            if let Some(port)=url.port() {
                return format!("127.0.0.1:{}", port);
                }
            }
        }

    "0.0.0.0:7321".to_string()
    }
