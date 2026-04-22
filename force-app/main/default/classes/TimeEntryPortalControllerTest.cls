@IsTest
private class TimeEntryPortalControllerTest {
    @IsTest
    static void getProjectOptions_returns_active_projects() {
        Account a = new Account(Name = 'Acct Portal');
        insert a;

        insert new List<Project__c>{
            new Project__c(Name = 'Alpha Portal', Account__c = a.Id, Offering__c = 'Hybrid_On_Prem', Active__c = true),
            new Project__c(Name = 'Beta Hidden', Account__c = a.Id, Offering__c = 'Commercial_Cloud', Active__c = false)
        };

        Test.startTest();
        List<TimeEntryPortalController.ProjectOption> all = TimeEntryPortalController.getProjectOptions('');
        List<TimeEntryPortalController.ProjectOption> filtered = TimeEntryPortalController.getProjectOptions('Alpha');
        Test.stopTest();

        System.assertEquals(1, all.size(), 'Only active projects');
        System.assertEquals('Alpha Portal', all[0].name);
        System.assertEquals(1, filtered.size());
        System.assertEquals('Alpha Portal', filtered[0].name);
    }
}
