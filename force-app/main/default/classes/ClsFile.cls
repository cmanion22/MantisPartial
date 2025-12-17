public class ClsFile
{
    public ID Id { get; set; }
    public string DistributionPublicUrl { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public string FileExtension { get; set; }
    public integer ContentSize { get; set; }
    public ID OpportunityId { get; set; }
    public ID CreatedById { get; set; }
    public DateTime CreatedDate { get; set; }
    public ID LastModifiedById { get; set; }
    public DateTime LastModifiedDate { get; set; }
    public Boolean IsArchived { get; set; }
    public ID ArchivedById { get; set; }
    public Date ArchivedDate { get; set; }
    public Boolean IsDeleted { get; set; }
    public ID OwnerId { get; set; }
    public DateTime SystemModstamp { get; set; }
    public string PublishStatus { get; set; }
    public ID LatestPublishedVersionId { get; set; }
    public ID ParentId { get; set; }
    public DateTime LastViewedDate { get; set; }
    public DateTime LastReferencedDate { get; set; }
    public string FileType { get; set; }
    public string SharingOption { get; set; }
    public string SharingPrivacy { get; set; }
    public DateTime ContentModifiedDate { get; set; }
    public ID ContentAssetId { get; set; }
}