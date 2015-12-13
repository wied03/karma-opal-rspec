Feature: Source maps

  Background:
    Given the 'sourceMaps.js' Karma config file

  Scenario: Failed test
    Given the failure tests
    When I run the Karma test
    Then the test fails with JSON results:
      """
      {
          "something failure": {
              "should eq 43": "FAILED"
          }
      }
      """
    And the output should contain "/tmp/aruba/spec/main_spec.js:17 <- /base/spec/main_spec.rb:5:21"

  Scenario: Pure Opal
    Given the simple tests
    When I run the Karma test and keep Karma running
    Then the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    And the following source maps exist:
      | File                    | Map URL          | Original File           | Sources                 |
      | /base/spec/main_spec.js | main_spec.js.map | /base/spec/main_spec.js | /base/spec/main_spec.rb |

  Scenario: Some JS files with no source maps
    Given the sprockets_require tests
    When I run the Karma test and keep Karma running
    Then the test passes with JSON results:
    """
    {
        "something via sprockets": {
            "should eq 22": "PASSED"
        }
    }
    """
    And the following source maps exist:
      | File                    | Map URL          | Original File           | Sources                 |
      | /base/spec/main_spec.js | main_spec.js.map | /base/spec/main_spec.js | /base/spec/main_spec.rb |
    And the following files do not have source maps:
      | File                          |
      | /base/spec/sprockets_style.js |
      | /base/spec/via_sprockets.js   |

  Scenario: Non opal file with a source map entry
    Given the non_opal_sourcemap tests
    When I run the Karma test and keep Karma running
    Then the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    # Putting this step 1st to ensure we can still get source maps after this
    And the following files have unresolvable source maps:
      | File                     |
      | /base/spec/jquery.min.js |
    And the following source maps exist:
      | File                    | Map URL          | Original File           | Sources                 |
      | /base/spec/main_spec.js | main_spec.js.map | /base/spec/main_spec.js | /base/spec/main_spec.rb |
