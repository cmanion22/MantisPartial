public class Utils {

    public static Boolean isSandbox {
        get {
            if (isSandbox == null) {
                isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return isSandbox;
        }
        set;
    }

    public static Boolean isRestApiRequest {
        get {
            if (isRestApiRequest == null) {
                isRestApiRequest = System.URL.getCurrentRequestUrl().getPath().contains('/services/data');
            }
            return isRestApiRequest;
        }
        set;
    }

    // From https://salesforce.stackexchange.com/a/43826
    public static String generateRandomString(Integer length) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < length) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

}