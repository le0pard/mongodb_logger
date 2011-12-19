#!/bin/bash
rake vendor_test_gems
rake test
rake cucumber:web:all
rake cucumber:rails:all