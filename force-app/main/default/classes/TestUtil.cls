/**
 * A collection of static utility methods for unit testing.
 */
@IsTest
public class TestUtil {

    private static Integer fakeIdCount = 0;
    private static final String ID_PATTERN = '000000000000';

    /**
     * Generate a fake Salesforce Id for the given SObjectType
     */
    public static Id generateId(Schema.SObjectType sobjectType) {
        String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
        fakeIdCount++;

        String fakeIdPrefix = ID_PATTERN.substring(0, ID_PATTERN.length() - String.valueOf(fakeIdCount).length());

        return Id.valueOf(keyPrefix + fakeIdPrefix + fakeIdCount);
    }

}