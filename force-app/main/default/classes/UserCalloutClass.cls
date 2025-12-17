public with sharing class UserCalloutClass {

    public static string createUser(Id userId, Id syncUserId) {
        return UserHelper.postCreateUserJson(userId, syncUserId);
    }

}