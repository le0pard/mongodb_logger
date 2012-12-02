#!/bin/bash
bundle exec rake test && \
bundle exec rake cucumber:web
#bundle exec rake vendor_test_gems && \
# && \
#rake jasmine:ci && \
#rake cucumber:rails:all