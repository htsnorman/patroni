Feature: standby cluster
  Scenario: check permanent logical slots are preserved on failover/switchover
    Given I start postgres1
    Then postgres1 is a leader after 10 seconds
    When I issue a PATCH request to http://127.0.0.1:8009/config with {"slots": {"test_logical": {"type": "logical", "database": "postgres", "plugin": "test_decoding"}}}
    Then I receive a response code 200
    And Response on GET http://127.0.0.1:8009/config contains slots after 10 seconds
    When I issue a PATCH request to http://127.0.0.1:8009/config with {"slots": {"pm_1": {"type": "physical"}}, "postgresql": {"parameters": {"wal_level": "logical"}}}
    Then I receive a response code 200
    When I start postgres0 with callback configured
    Then "members/postgres0" key in DCS has state=running after 10 seconds
    When I shut down postgres1
    Then postgres0 is a leader after 10 seconds
    And I sleep for 2 seconds
    When I issue a GET request to http://127.0.0.1:8008/
    Then I receive a response code 200
    And there is a label with "test_logical" in postgres0 data directory

  Scenario: check replication of a single table in a standby cluster
    Given I start postgres1 in a standby cluster batman1 as a clone of postgres0
    Then postgres1 is a leader of batman1 after 10 seconds
    When I issue a PATCH request to http://127.0.0.1:8009/config with {"ttl": 20, "loop_wait": 2}
    And I add the table foo to postgres0
    Then table foo is present on postgres1 after 20 seconds
    When I start postgres2 in a cluster batman1
    Then postgres2 role is the replica after 24 seconds
    And table foo is present on postgres2 after 20 seconds

  Scenario: check failover
    When I kill postgres1
    And I kill postmaster on postgres1
    Then postgres2 is replicating from postgres0 after 20 seconds