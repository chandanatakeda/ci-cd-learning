public class VEM_Calculate_Event_Risk 
{
    public class Input
    {
        @InvocableVariable
        public String EventId;        
    }
    public class Output
    {   
        @InvocableVariable
        public String RiskLevel;
    }
    @InvocableMethod(Label='Calculate Risk For Event' Description='For a given event it calculates the Risk.It will return HIGH, MEDIUM, LOW OR NO RISK.')
    public static List<Output> CalculateRiskForEvent(List<Input> inputs)
    {
        List<Output> outputs= new List<Output>();
        Input input = inputs.get(0);
        List<VEM_Attendee__c> attendees = [SELECT ID FROM VEM_ATTENDEE__C WHERE VEM_Event__c = :input.EventId and VEM_Status__c = 'Accepted'];
        Integer acceptedAttendeeCount = attendees.size();
        Output output = new Output();
        if(acceptedAttendeeCount < 3) output.RiskLevel='HIGH';
        else if(acceptedAttendeeCount < 6) output.RiskLevel='MEDIUM';
        else if(acceptedAttendeeCount < 10) output.RiskLevel='LOW';
        else output.RiskLevel='NO RISK';
        outputs.add(output);     
            
        return outputs;
    }
}