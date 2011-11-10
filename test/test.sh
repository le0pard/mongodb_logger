#!/bin/bash
rake vendor_test_gems
rake cucumber:rails:all
rake test
