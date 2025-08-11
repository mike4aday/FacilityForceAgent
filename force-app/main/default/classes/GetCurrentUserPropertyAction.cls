public with sharing class GetCurrentUserPropertyAction {
    
    // Minimal input wrapper to satisfy Agentforce Builder requirement
    public class Input {
        @InvocableVariable(label='Request Token' description='Dummy input required by Agentforce; not used by logic.' required=false)
        public String requestToken;
    }
    
    // Output wrapper
    public class Output {
        @InvocableVariable(label='Property Id' description='The Id of the Property__c record linked to the current user.')
        public Id propertyId;
    }
    
    @InvocableMethod(
        label='Get Current User Property' 
        description='Finds the Property__c record linked to the current user via the User_Property__c junction object.'
    )
    public static List<Output> getCurrentUserProperty(List<Input> inputs) {
        Id currentUserId = UserInfo.getUserId();
        
        // Query the junction to get the related Property__c record
        User_Property__c link = [
            SELECT Property__c
            FROM User_Property__c
            WHERE User__c = :currentUserId
            LIMIT 1
        ];
        
        Output result = new Output();
        result.propertyId = link.Property__c;
        
        return new List<Output> { result };
    }
}