@show 
Feature: Show a document
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  Scenario: Visit Document Show Page
    Given I am on the show document page for druid:cm234kq4672
    Then the "Title:" term should contain "Letter from Ellie Engelmore to Wemara Lichty" 
    And the "Date:" term should contain "1984-6-4" 
    And the "Document Type:" term should contain "Paper Document"
    And I should not see the "access" term 
    And I should not see the "document ID" term 
    #And I should not see a link to the "raw OCR"
    And I should not see a link to "the edit document page for druid:cm234kq4672"
    
  @wip
  Scenario: Donor visits Document Show Page
    Given I am logged in as "francis" on the show document page for druid:cm234kq4672 
    Then I should see the "ID:" term 
    #Then I should see the "access" term 
    #And I should see a link to download "raw OCR"
    And I should see a link to "the edit document page for druid:cm234kq4672"
    And related links are displayed as urls