#!/usr/bin/sh

# This script should be run whenever any of the serializable classes change structure to update the serialization code.

flutter pub run build_runner build --delete-conflicting-outputs

