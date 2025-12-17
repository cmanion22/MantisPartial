public class UnanetInvoiceIndividualWrapper {
    public Integer key;
    public Project project;
    public Organization organization;
    public Organization billedOrganization;
    public BilledAccount billedAccount;
    public String invoiceNumber;
    public Date invoiceDate;
    public Date billingThroughDate;
    public Date billingPeriodFromDate;
    public PaymentTerm paymentTerm;
    public Date dueDate;
    public Date discountDate;
    public Address billToAddress;
    public Address shipToAddress;
    public Address remitToAddress;
    public ContactRef billToContact;
    public ContactRef shipToContact;
    public ContactRef remitToContact;
    public String contractNumber;
    public String orderNumber;
    public Decimal fundedValue;
    public Decimal remainingFundedValue;
    public String memo;
    public String description;
    public Decimal amount;
    public Decimal discountAmount;
    public Decimal localAmount;
    public Decimal instanceAmount;
    public InvoiceCurrency localCurrency;
    public Decimal localExchangeRate;
    public Decimal instanceExchangeRate;
    public String invoiceOption;
    public Date postDate;
    public Boolean allowACHPayments;
    public Boolean allowCreditCardPayments;
    public Boolean allowElectronicPayments;
    public Decimal creditCardMinAmount;
    public Decimal creditCardMaxAmount;
    public Decimal achMinAmount;
    public Decimal achMaxAmount;
    public UserRef completedBy;
    public Datetime completedTimestamp;
    public UserRef createdBy;
    public Datetime createdTimestamp;
    public UserRef emailedBy;
    public Datetime emailedTimestamp;
    public UserRef extractedBy;
    public Datetime extractedTimestamp;
    public UserRef printedBy;
    public Datetime printedTimestamp;
    public Integer voidingInvoiceKey;
    public Integer voidedInvoiceKey;
    public UserRef submittedBy;
    public Datetime submittedTimestamp;
    public String status;
    public UserRef controller;

    public class Project {
        public Integer key;
        public String name;
        public String code;
    }

    public class Organization {
        public Integer key;
        public String name;
        public String code;
    }

    public class BilledAccount {
        public Integer key;
        public String code;
    }

    public class PaymentTerm {
        public Integer key;
        public String code;
    }

    public class Address {
        public String streetLine1;
        public String streetLine2;
        public String streetLine3;
        public String city;
        public String stateProvince;
        public String country;
        public String postalCode;
    }

    public class ContactRef {
        public String name;
    }

    public class InvoiceCurrency {
        public Integer key;
        public String name;
        public String code;
        public Integer decimals;
    }

    public class UserRef {
        public Integer key;
        public String name;
    }
}