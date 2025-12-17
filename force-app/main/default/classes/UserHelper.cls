public class UserHelper {
    public static String postCreateUserJson(Id userId, Id syncUserId) {
        User usr = GetUser(userId);
        String body = '{"event": "create_user", "data": {"user": ' + Helper.getFormattedJson(usr) + '}}';
        System.enqueueJob(new HttpRetryAsync(ESBController.getESBUrl(syncUserId), 'POST', body, 'CreateUser'));

        return body;
    }

    public static User GetUser(ID userId) {
        System.debug('UserHelper-->GetUser-->userId--> ' + userId);
        
        String query = Helper.generateSelectQuery('User');
        query = query + ' WHERE ID= :userId';

        User user = database.query(query);
        System.debug('UserHelper-->GetUser-->User--> ' + user);

        return User;
    }
}