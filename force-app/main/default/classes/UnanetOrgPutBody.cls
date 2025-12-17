public class UnanetOrgPutBody {
    public String code;
    public String name;
    public Boolean active;
    public Integer typeKey;
    public Integer parentOrgKey;
    public Integer currencyCodeKey;
    public Boolean financialOrg;
    public Boolean legalEntity;
    public Integer legalEntityOrgKey;
    public UdfWrapper udfs;

    public class UdfWrapper {
        public List<UdfValue> values = new List<UdfValue>();  // Initialized to prevent null pointer errors
    }

    public class UdfValue {
        public Integer index;
        public String value;
    }
}