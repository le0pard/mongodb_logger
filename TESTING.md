Running the suite
=================

Since the logger must run on many versions of Rails, running its test suite is slightly different than you may be used to.

First execute the following command:

    rake vendor_test_gems
    # NOT: bundle exec rake vendor_test_gems

This command will download the various versions of Rails that the notifier must be tested against.

Then, to start the suite, run

    rake cucumber:rails:all

Note: do NOT use 'bundle exec rake cucumber:rails:all'.

For help created file test/test\_all.sh, which run all this testing steps + unit tests. Run this file from root of gem:

    ./test/test_all.sh
    
Versions of testing Rails you can see in file "SUPPORTED_RAILS_VERSIONS". If some tests is faild, you can see 
more information about fallen tests in file "tmp/terminal.log".
