public with sharing class QueryPropertyVendorsAction { 

    /**
     * Request wrapper
     */
    public class Request {
        @InvocableVariable(label='Property' description='Property__c record to find vendors for' required=true)
        public Property__c Property;
    }
    
    /**
     * Response wrapper
     */
    public class Response {
        @InvocableVariable(label='Prompt' description='List of Property_Vendor__c records with vendor details')
        public List<Property_Vendor__c> Prompt;
    }

    @InvocableMethod(label='Query Property Vendors' description='Retrieves Property_Vendor__c records for properties to ground Agentforce responses')
    public static List<Response> getPropertyVendorsForGrounding(List<Request> requests) {

        List<Response> responses = new List<Response>();
        
        for (Request request : requests) {
            Response response = new Response();
            
            if (request.Property == null) {
                response.Prompt = new List<Property_Vendor__c>();
                responses.add(response);
                continue;
            }
            
            // Query for all Property_Vendor__c records for the property with active contracts
            List<Property_Vendor__c> propertyVendors = [
                SELECT Id, Property__c, Property__r.Name, Property__r.Street__c, 
                       Property__r.City__c, Property__r.State__c, Property__r.Zip_Code__c, 
                       Vendor__c, Service_Type__c, Contract_Start_Date__c, Contract_End_Date__c, Expired_Contract__c,
                       Preferred_Vendor__c, Emergency_Contact__c, Notes__c, 
                       Vendor__r.Id, Vendor__r.Name, Vendor__r.Type, Vendor__r.Phone, 
                       Vendor__r.Website, Vendor__r.BillingStreet, Vendor__r.BillingCity, 
                       Vendor__r.BillingState, Vendor__r.BillingPostalCode, 
                       Vendor__r.BillingCountry, Vendor__r.Description, 
                       Vendor__r.SicDesc, Vendor__r.Sic 
                FROM Property_Vendor__c 
                WHERE Property__c = :request.Property.Id 
                AND Expired_Contract__c = FALSE
                ORDER BY Preferred_Vendor__c DESC, Vendor__r.Name
            ];
            
            response.Prompt = propertyVendors;
            responses.add(response);
        }
        
        return responses;
    }
}