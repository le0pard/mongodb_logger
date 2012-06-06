#!/bin/bash
BUNDLE_GEMFILE=test/Gemfile_tests bundle
BUNDLE_GEMFILE=test/Gemfile_tests rake vendor_test_gems && \
rake test && \
rake cucumber:web && \
#rake jasmine:ci && \
rake cucumber:rails:all