Feature: Watch files

  Scenario: New spec added
    Given the 'singlePattern.js' Karma config file
    And the simple tests
    And I run the Karma test and keep Karma running
    And the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    When I add a new spec file and wait
    Then the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        },
        "else": {
          "should eq 43": "PASSED"
        }
    }
    """
    And dependencies are not reloaded

  Scenario: New spec and dependency added
    Given the 'customLoadPath.js' Karma config file
    And the add_to_load_path/spec tests
    And I copy spec/integration/add_to_load_path/src_dir to the working directory
    And I run the Karma test and keep Karma running
    And the test passes with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    When I add a new spec file with dependencies and wait
    Then the test passes with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "PASSED"
        },
        "Howdy": {
          "should eq [123]": "PASSED"
        }
    }
    """

  Scenario: A dependency changes
    Given the 'customLoadPath.js' Karma config file
    And the add_to_load_path/spec tests
    And I copy spec/integration/add_to_load_path/src_dir to the working directory
    And I run the Karma test and keep Karma running
    And the test passes with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    When I change the dependency and wait
    Then the test fails with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "FAILED"
        }
    }
    """

  Scenario: File has dependencies and changes but dependencies are same
    Given the 'customLoadPath.js' Karma config file
    And the add_to_load_path/spec tests
    And I copy spec/integration/add_to_load_path/src_dir to the working directory
    And I run the Karma test and keep Karma running
    And the test passes with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    When I modify the spec file that has a dependency and wait
    Then the test passes with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "PASSED"
         },
        "ClassUnderTest nested_something": {
            "should eq 42": "PASSED"
        }
    }
    """
    And dependencies are not reloaded

  Scenario: File changes without dependency change
    Given the 'singlePattern.js' Karma config file
    And the simple tests
    And I run the Karma test and keep Karma running
    And the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    And I modify the spec file and wait
    Then the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        },
        "something nested 2": {
            "should eq 42": "PASSED"
        }
    }
    """
    And dependencies are not reloaded

  Scenario: File changes with dependency change
    Given the 'customLoadPath.js' Karma config file
    And the add_to_load_path/spec tests
    And I copy spec/integration/add_to_load_path/src_dir to the working directory
    And I run the Karma test and keep Karma running
    And the test passes with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    When I modify the spec file with a new dependency and wait
    Then the test passes with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "PASSED"
        },
        "Howdy": {
          "should eq [123]": "PASSED"
        }
    }
    """

  Scenario: File changed with dependency typo
    Given the 'customLoadPath.js' Karma config file
    And the add_to_load_path/spec tests
    And I copy spec/integration/add_to_load_path/src_dir to the working directory
    And I run the Karma test and keep Karma running
    And the test passes with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    And I modify the spec file with a broken dependency and wait
    When I modify the spec file with a new dependency and wait
    Then the test passes with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "PASSED"
        },
        "Howdy": {
          "should eq [123]": "PASSED"
        }
    }
    """

  Scenario: File removed
    Given the 'multiplePatterns.js' Karma config file
    And the mult_patterns tests
    And I run the Karma test and keep Karma running
    And the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        },
        "other nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    When I remove other_test.rb and wait
    Then the running Karma process shows "Executed 1 of 1 SUCCESS"
    And dependencies are not reloaded
