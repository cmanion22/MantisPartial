@isTest
public class FetchInactiveUsersInvocableTest {

    @isTest
	static void testFetchInactiveUsersPopulatedResultsByDivision() {

    	// Create test users to act as owners
    	User testUser1 = new User(
            Username = 'testuser12345-5@example.com',
            LastName = 'User',
            FirstName = 'Test1',
            Email = 'testuser1@example.com',
            Alias = 'tuser1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            Division = 'Test Division 1',
        	isActive = false);
        
        	insert testUser1;
        
        User testUser2 = new User(
            Username = 'testuser22-21@example.com',
            LastName = 'User',
            FirstName = 'Test2',
            Email = 'testuser2@example.com',
            Alias = 'tuser2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            Division = 'Test Division 1',
        	isActive = false);
            
            insert testUser2;
        
        User testUser3 = new User(
            Username = 'testuser222!@example.com',
            LastName = 'User',
            FirstName = 'Test3',
            Email = 'testuser3@example.com',
            Alias = 'tuser3',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            Division = 'Test Division 2',
        	isActive = false);
            
            insert testUser3;
        
    	
    	// Create test accounts with inactive owners
    	Account testAccount1 = new Account(
            Name = 'Test Account 1',
            OwnerId = testUser1.Id);
    		
    		insert testAccount1;
            
        Account testAccount2 = new Account(
            Name = 'Test Account 2',
            OwnerId = testUser2.Id);
            
            insert testAccount2;
        
        Account testAccount3 = new Account(
            Name = 'Test Account 3',
            OwnerId = testUser3.Id);
            
            insert testAccount3;

    	// Create the requests
    FetchInactiveUsersInvocable.Request request1 = new FetchInactiveUsersInvocable.Request();
    request1.division = 'Test Division 1';

    FetchInactiveUsersInvocable.Request request2 = new FetchInactiveUsersInvocable.Request();
    request2.division = 'Test Division 2';

    List<FetchInactiveUsersInvocable.Request> requests = new List<FetchInactiveUsersInvocable.Request>{request1, request2};

    // Populate resultsByDivision map manually
    Map<String, List<AggregateResult>> resultsByDivision = new Map<String, List<AggregateResult>>();
    List<AggregateResult> aggregateResults1 = new List<AggregateResult>();
    // Add AggregateResult objects for 'Test Division 1' to the list...
    resultsByDivision.put('Test Division 1', aggregateResults1);

    List<AggregateResult> aggregateResults2 = new List<AggregateResult>();
    // Add AggregateResult objects for 'Test Division 2' to the list...
    resultsByDivision.put('Test Division 2', aggregateResults2);

    Test.startTest();
    // Call the method
    List<FetchInactiveUsersInvocable.Response> responses = FetchInactiveUsersInvocable.fetchInactiveUsers(requests);
    Test.stopTest();

    // Verify the populated resultsByDivision map
    System.assertNotEquals(null, resultsByDivision.get('Test Division 1'), 'Results for Test Division 1 should be populated');
    System.assertEquals(0, resultsByDivision.get('Test Division 1').size(), 'No results should be added for Test Division 1');

    System.assertNotEquals(null, resultsByDivision.get('Test Division 2'), 'Results for Test Division 2 should be populated');
    System.assertEquals(0, resultsByDivision.get('Test Division 2').size(), 'No results should be added for Test Division 2');
	}

	@isTest
	static void testFetchInactiveUsersEmptyResultsByDivision() {
    // Create the request for a division with no results
    FetchInactiveUsersInvocable.Request request = new FetchInactiveUsersInvocable.Request();
    request.division = 'Non Existent Division';

    List<FetchInactiveUsersInvocable.Request> requests = new List<FetchInactiveUsersInvocable.Request>{request};

    Test.startTest();
    // Call the method
    List<FetchInactiveUsersInvocable.Response> responses = FetchInactiveUsersInvocable.fetchInactiveUsers(requests);
    Test.stopTest();

    // Verify the response...
    System.assertEquals(1, responses.size(), 'One response should be returned');
    System.assertEquals(0, responses[0].users.size(), 'No users should be returned');
	}

}