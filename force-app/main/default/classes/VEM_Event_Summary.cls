public class VEM_Event_Summary {
    @AuraEnabled public String eventTitle;
    @AuraEnabled public String eventSubHeading;

    @AuraEnabled public Integer totalAttendees;
    @AuraEnabled public Integer invitedCount;
    @AuraEnabled public Integer acceptedCount;
    @AuraEnabled public Integer attendedCount;
    @AuraEnabled public Integer noShowCount;

    @AuraEnabled public Decimal totalExpenses;
    @AuraEnabled public Integer expensesCount;
    @AuraEnabled public Integer individualExpenseCount;
    @AuraEnabled public Integer meetingExpensesCount;
}