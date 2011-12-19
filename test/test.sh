#!/bin/bash
rake vendor_test_gems
rake test
rake jasmine:ci
rake cucumber:rails:all