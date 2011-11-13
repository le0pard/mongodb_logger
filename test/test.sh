#!/bin/bash
rake vendor_test_gems
rake test
rake cucumber:rails:all
