/**
 * Apex class with invocable method for upserting Lease records via Agentforce
 * This class handles the creation of new lease records or updates existing ones with proper validation and error handling
 */
public with sharing class UpsertLeaseAction {
    
    /**
     * Input wrapper class for the invocable method
     */
    public class LeaseInput {
        @InvocableVariable(label='Lease ID' description='ID of existing lease record to update (leave blank to create new lease)')
        public String leaseId;
        
        @InvocableVariable(label='Property ID' description='ID of the Property record (required for new leases)' required=false)
        public String propertyId;
        
        @InvocableVariable(label='Premises' description='Specific portion of the property (e.g., Suite 300, Floor 2)')
        public String premises;
        
        @InvocableVariable(label='Monthly Base Rent' description='Base monthly rental amount before additional charges')
        public Decimal monthlyBaseRent;
        
        @InvocableVariable(label='Leased Square Footage' description='Total rentable square footage covered by this lease')
        public Decimal leasedSquareFootage;
        
        @InvocableVariable(label='Start Date' description='Date when the lease term begins')
        public Date startDate;
        
        @InvocableVariable(label='End Date' description='Date when the lease term expires')
        public Date endDate;
        
        @InvocableVariable(label='Lease Structure' description='Type of lease structure (e.g., Triple Net Lease (NNN), Gross Lease)')
        public String structure;
        
        @InvocableVariable(label='Status' description='Current status of the lease (Active, Pending Renewal, Expired, Terminated)')
        public String status;
        
        @InvocableVariable(label='Renewal Option' description='Whether tenant has the right to renew this lease')
        public Boolean renewalOption;
        
        @InvocableVariable(label='Renewal Notice Days' description='Number of days advance notice required for renewal')
        public Integer renewalNoticeDays;
        
        @InvocableVariable(label='Annual CAM Charges' description='Annual Common Area Maintenance charges')
        public Decimal annualCAMCharges;
        
        @InvocableVariable(label='Annual Property Taxes' description='Annual property tax amount tenant pays')
        public Decimal annualPropertyTaxes;
        
        @InvocableVariable(label='Annual Insurance' description='Annual insurance premium tenant pays')
        public Decimal annualInsurance;
    }
    

    /**
     * Invocable method to create a new lease record
     * This method can be called from Flows and used as an Agentforce action
     */
    @InvocableMethod(
        label='Create or Update Lease' 
        description='Creates or updates a lease (Lease__c) record with the provided information. Property ID is required.'
        category='Property Management'
    )
    public static List<Lease__c> upsertLease(List<LeaseInput> inputs) {
        List<Lease__c> results = new List<Lease__c>();
        
        for (LeaseInput input : inputs) {
            Boolean isUpdate = String.isNotBlank(input.leaseId);
            
            try {
                Lease__c leaseRecord;
                
                if (isUpdate) {
                    // Update existing lease
                    List<Lease__c> existingLeases = [
                        SELECT Id, Name, Property__c, Premises__c, Monthly_Base_Rent__c, 
                               Leased_Square_Footage__c, Start_Date__c, End_Date__c, Duration__c,
                               Structure__c, Status__c, Renewal_Option__c, Renewal_Notice_Days__c,
                               Annual_CAM_Charges__c, Annual_Property_Taxes__c, Annual_Insurance__c
                        FROM Lease__c 
                        WHERE Id = :input.leaseId 
                        LIMIT 1
                    ];
                    
                    if (existingLeases.isEmpty()) {
                        throw new IllegalArgumentException('Lease record not found for update. Lease ID: ' + input.leaseId);
                    }
                    
                    leaseRecord = existingLeases[0];
                    
                    // If Property ID is provided in update, validate it exists
                    if (String.isNotBlank(input.propertyId) && input.propertyId != leaseRecord.Property__c) {
                        List<Property__c> properties = [
                            SELECT Id, Name 
                            FROM Property__c 
                            WHERE Id = :input.propertyId 
                            LIMIT 1
                        ];
                        
                        if (properties.isEmpty()) {
                            throw new IllegalArgumentException('Invalid Property ID provided for update: ' + input.propertyId);
                        }
                    }
                    
                } else {
                    // Create new lease - Property ID is required
                    if (String.isBlank(input.propertyId)) {
                        throw new IllegalArgumentException('Property ID is required to create a new lease');
                    }
                    
                    // Verify the Property exists for new lease
                    List<Property__c> properties = [
                        SELECT Id, Name 
                        FROM Property__c 
                        WHERE Id = :input.propertyId 
                        LIMIT 1
                    ];
                    
                    if (properties.isEmpty()) {
                        throw new IllegalArgumentException('Invalid Property ID provided: ' + input.propertyId);
                    }
                    
                    leaseRecord = new Lease__c();
                    leaseRecord.Property__c = input.propertyId;
                }
                
                // Validate date logic if both dates are provided
                Date startDate = input.startDate != null ? input.startDate : leaseRecord.Start_Date__c;
                Date endDate = input.endDate != null ? input.endDate : leaseRecord.End_Date__c;
                
                if (startDate != null && endDate != null && startDate >= endDate) {
                    throw new IllegalArgumentException('Start Date (' + startDate + ') must be before End Date (' + endDate + ')');
                }
                
                // Update fields only if provided (allows partial updates)
                if (String.isNotBlank(input.propertyId)) {
                    leaseRecord.Property__c = input.propertyId;
                }
                
                if (String.isNotBlank(input.premises)) {
                    leaseRecord.Premises__c = input.premises;
                }
                
                if (input.monthlyBaseRent != null) {
                    leaseRecord.Monthly_Base_Rent__c = input.monthlyBaseRent;
                }
                
                if (input.leasedSquareFootage != null) {
                    leaseRecord.Leased_Square_Footage__c = input.leasedSquareFootage;
                }
                
                if (input.startDate != null) {
                    leaseRecord.Start_Date__c = input.startDate;
                }
                
                if (input.endDate != null) {
                    leaseRecord.End_Date__c = input.endDate;
                }
                
                if (String.isNotBlank(input.structure)) {
                    leaseRecord.Structure__c = input.structure;
                }
                
                if (String.isNotBlank(input.status)) {
                    leaseRecord.Status__c = input.status;
                }
                
                if (input.renewalOption != null) {
                    leaseRecord.Renewal_Option__c = input.renewalOption;
                }
                
                if (input.renewalNoticeDays != null) {
                    leaseRecord.Renewal_Notice_Days__c = input.renewalNoticeDays;
                }
                
                if (input.annualCAMCharges != null) {
                    leaseRecord.Annual_CAM_Charges__c = input.annualCAMCharges;
                }
                
                if (input.annualPropertyTaxes != null) {
                    leaseRecord.Annual_Property_Taxes__c = input.annualPropertyTaxes;
                }
                
                if (input.annualInsurance != null) {
                    leaseRecord.Annual_Insurance__c = input.annualInsurance;
                }
                
                // Upsert the lease record
                upsert leaseRecord;
                
                // Query the record to get the current state including auto-generated lease number
                Lease__c finalLease = [
                    SELECT Id, Name, Property__c, Premises__c, Monthly_Base_Rent__c, 
                           Leased_Square_Footage__c, Start_Date__c, End_Date__c, 
                           Structure__c, Status__c, Renewal_Option__c, Renewal_Notice_Days__c,
                           Annual_CAM_Charges__c, Annual_Property_Taxes__c, Annual_Insurance__c
                    FROM Lease__c 
                    WHERE Id = :leaseRecord.Id 
                    LIMIT 1
                ];
                
                results.add(finalLease);
                
            } catch (Exception e) {
                // Re-throw the exception to be handled by the calling flow
                throw new AuraHandledException(e.getMessage());
            }
        }
        
        return results;
    }
    
    /**
     * Helper method to get valid picklist values for lease structure
     * This is a regular public method that can be called separately if needed
     */
    public static List<String> getLeaseStructureOptions() {
        List<String> structureOptions = new List<String>();
        
        try {
            Schema.DescribeFieldResult fieldResult = Lease__c.Structure__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    structureOptions.add(entry.getLabel());
                }
            }
        } catch (Exception e) {
            // Return default options if schema access fails
            structureOptions.addAll(new List<String>{
                'Gross Lease (Full Service Lease)',
                'Triple Net Lease (NNN)',
                'Double Net Lease (NN)',
                'Single Net Lease (N)',
                'Modified Gross Lease',
                'Percentage Lease',
                'Ground Lease',
                'Other'
            });
        }
        
        return structureOptions;
    }
}