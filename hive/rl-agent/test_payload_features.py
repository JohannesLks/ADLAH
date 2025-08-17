#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# ADLAH - Adaptive Deep Learning Anomaly Detection Honeynet <https://github.com/JohannesLks/ADLAH/>
# Copyright (C) 2025  Lukas Johannes Möller
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""
Test script for payload feature extraction.
"""
import sys
import os

# Add the rl_agent directory to the path so we can import from it
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'rl_agent'))

from rl_agent.features import extract_payload_features

def test_payload_features():
    """Test payload feature extraction with sample data."""
    # Test case 1: Valid hex string
    payload_str = "48454c500d0a"  # "HELP\r\n" in hex
    features = extract_payload_features(payload_str)
    print(f"Test 1 - Payload: {payload_str}")
    print(f"Features: {features}")
    print()
    
    # Test case 2: Empty string
    payload_str = ""
    features = extract_payload_features(payload_str)
    print(f"Test 2 - Payload: {payload_str}")
    print(f"Features: {features}")
    print()
    
    # Test case 3: Valid hex string with non-printable characters
    payload_str = "010100000000"
    features = extract_payload_features(payload_str)
    print(f"Test 3 - Payload: {payload_str}")
    print(f"Features: {features}")
    print()
    
    # Test case 4: Invalid hex string
    payload_str = "invalidhex"
    features = extract_payload_features(payload_str)
    print(f"Test 4 - Payload: {payload_str}")
    print(f"Features: {features}")
    print()

if __name__ == "__main__":
    test_payload_features()