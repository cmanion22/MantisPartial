@IsTest
public class TestUtilTest {

    @isTest
    static void itShouldGenerateValidIDs()
    {
        String id1 = TestUtil.generateId(Account.SObjectType);
        String id2 = TestUtil.generateId(Account.SObjectType);
        String id3 = TestUtil.generateId(Account.SObjectType);
        String id4 = TestUtil.generateId(Account.SObjectType);
        String id5 = TestUtil.generateId(Account.SObjectType);
        String id6 = TestUtil.generateId(Account.SObjectType);
        String id7 = TestUtil.generateId(Account.SObjectType);
        String id8 = TestUtil.generateId(Account.SObjectType);
        String id9 = TestUtil.generateId(Account.SObjectType);
        String id10 = TestUtil.generateId(Account.SObjectType);
        String id11 = TestUtil.generateId(Account.SObjectType);

        System.Assert.areEqual('001000000000001AAA', id1);
        System.Assert.areEqual('001000000000002AAA', id2);
        System.Assert.areEqual('001000000000003AAA', id3);
        System.Assert.areEqual('001000000000004AAA', id4);
        System.Assert.areEqual('001000000000005AAA', id5);
        System.Assert.areEqual('001000000000006AAA', id6);
        System.Assert.areEqual('001000000000007AAA', id7);
        System.Assert.areEqual('001000000000008AAA', id8);
        System.Assert.areEqual('001000000000009AAA', id9);
        System.Assert.areEqual('001000000000010AAA', id10);
        System.Assert.areEqual('001000000000011AAA', id11);
    }

}