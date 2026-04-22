@IsTest
private class TimeEntryRateServiceTest {
    @IsTest
    static void stamps_rate_from_matching_card() {
        Account acct = new Account(Name = 'CD Test Customer');
        insert acct;

        Project__c proj = new Project__c(
            Name = 'Hybrid Build',
            Account__c = acct.Id,
            Offering__c = 'Hybrid_On_Prem',
            Active__c = true
        );
        insert proj;

        insert new Rate_Card__c(
            Offering__c = 'Hybrid_On_Prem',
            Job_Role__c = 'Engineer',
            Labor_Pool__c = 'Operations',
            Effective_Start__c = Date.today().addDays(-30),
            Effective_End__c = null,
            Hourly_Rate__c = 175
        );

        Time_Entry__c te = new Time_Entry__c(
            Project__c = proj.Id,
            Work_Date__c = Date.today(),
            Hours__c = 2.5,
            Task_Category__c = 'Maintenance',
            Job_Role__c = 'Engineer',
            Labor_Pool__c = 'Operations'
        );
        insert te;

        te = [SELECT Rate_Applied__c, Extended_Amount__c FROM Time_Entry__c WHERE Id = :te.Id];
        System.assertEquals(175, te.Rate_Applied__c);
        System.assertEquals(2.5 * 175, te.Extended_Amount__c);
    }

    @IsTest
    static void picks_latest_effective_card() {
        Account acct = new Account(Name = 'CD Test Customer 2');
        insert acct;

        Project__c proj = new Project__c(
            Name = 'Commercial',
            Account__c = acct.Id,
            Offering__c = 'Commercial_Cloud',
            Active__c = true
        );
        insert proj;

        Date d0 = Date.today().addDays(-10);
        insert new List<Rate_Card__c>{
            new Rate_Card__c(
                Offering__c = 'Commercial_Cloud',
                Job_Role__c = 'DBA',
                Labor_Pool__c = 'Operations',
                Effective_Start__c = d0.addDays(-20),
                Effective_End__c = d0.addDays(-1),
                Hourly_Rate__c = 100
            ),
            new Rate_Card__c(
                Offering__c = 'Commercial_Cloud',
                Job_Role__c = 'DBA',
                Labor_Pool__c = 'Operations',
                Effective_Start__c = d0,
                Effective_End__c = null,
                Hourly_Rate__c = 125
            )
        };

        Time_Entry__c te = new Time_Entry__c(
            Project__c = proj.Id,
            Work_Date__c = d0,
            Hours__c = 1,
            Task_Category__c = 'Patching',
            Job_Role__c = 'DBA',
            Labor_Pool__c = 'Operations'
        );
        insert te;

        te = [SELECT Rate_Applied__c FROM Time_Entry__c WHERE Id = :te.Id];
        System.assertEquals(125, te.Rate_Applied__c);
    }
}
