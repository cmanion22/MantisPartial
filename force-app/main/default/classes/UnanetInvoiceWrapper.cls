public with sharing class UnanetInvoiceWrapper {
    public List<Invoice> items;
    public Integer page;
    public Integer pageSize;
    public Integer pageCount;
    public Integer resultCount;

    public class Invoice {
        public Integer key;
        public Project project;
        public Customer customer;
        public String invoiceNumber;
        public Date invoiceDate;
        public PaymentTerm paymentTerm;
        public Date postDate;
        public String invoiceOption;
        public Decimal amount;
        public Decimal balance;
        public Decimal localAmount;
        public Decimal instanceAmount;
        public InvoiceCurrency localCurrency;
        public Decimal localExchangeRate;
        public Decimal instanceExchangeRate;
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
        public Boolean hasAttachments;
        public Boolean historical;
    }

    public class Project {
        public Integer key;
        public String name;
        public String code;
    }

    public class Customer {
        public Integer key;
        public String name;
        public String code;
    }

    public class PaymentTerm {
        public Integer key;
        public String code;
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