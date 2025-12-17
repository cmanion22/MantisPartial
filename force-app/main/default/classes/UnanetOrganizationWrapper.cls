public class UnanetOrganizationWrapper {
    public Integer key;
    public String code;
    public String name;
    public Boolean active;
    public OrgType type;
    public OrgParent parentOrg;
    public Integer size;
    public String externalSystemCode;
    public String classification;
    public String sicCode;
    public String industry;
    public String sector;
    public String stockSymbol;
    public String url;
    public Boolean financialOrg;
    public Boolean legalEntity;
    public OrgReference legalEntityOrg;         
    public Boolean entryAllowed;
    public String beginDate;
    public String endDate;
    public OrgReference finParentOrg;           
    public OrgReference costPoolParentOrg;      
    public OrgReference defaultGLPostOrg;       
    public String recipientName1099;
    public Boolean vendor1099;
    public String federalTaxId;
    public String federalTaxIdType;
    public String tax1;
    public String tax2;
    public String tax3;
    public String email1099;
    public OrgReference propertyTemplate;       
    public Integer startWithProjectCodeSeq;
    public Integer lastProjectCodeSeq;
    public Boolean defaultPersonOrg;
    public Boolean requiresActivation;
    public String createdTimestamp;
    public String lastUpdatedTimestamp;
    public UdfWrapper udfs;

    public String getSalesforceId() {
        if (udfs != null && udfs.values != null) {
            for (UdfValueWrapper udf : udfs.values) {
                if (udf != null && udf.metadata != null && udf.metadata.label == 'SF Id') {
                    return udf.value;
                }
            }
        }
        return null;
    }

    public class OrgType {
        public Integer key;
        public String name;
        public String description;
    }

    public class OrgParent {
        public Integer key;
        public String name;
        public String code;
    }

    public class OrgReference {
        public Integer key;
        public String name;
        public String code;
    }

    public class UdfWrapper {
        public List<UdfValueWrapper> values;
    }

    public class UdfValueWrapper {
        public Integer index;
        public String value;
        public MetadataWrapper metadata;
    }

    public class MetadataWrapper {
        public String dataType;
        public String label;
        public String visibility;
        public Boolean required;
        public Boolean active;
        public List<ListOptionWrapper> listOptions;
    }

    public class ListOptionWrapper {
        public Integer order;
        public String value;
        public String text;
    }
}