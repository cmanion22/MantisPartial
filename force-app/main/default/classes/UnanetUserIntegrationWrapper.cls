public class UnanetUserIntegrationWrapper {
    // Used for both /people/list (items[]) and /people/{id} (single object)
    public List<UnanetPerson> items;
    public Integer page;
    public Integer pageSize;
    public Integer pageCount;
    public Integer resultCount;

    public class UnanetPerson {
        public Integer key;
        public String username;
        public String firstName;
        public String lastName;
        public Boolean active;

        public Organization organization;
        public String personCode;
        public EmployeeType employeeType;
    }

    public class Organization {
        public Integer key;
        public String name;
        public String code;
    }

    public class EmployeeType {
        public Integer key;
        public String name;
    }
}