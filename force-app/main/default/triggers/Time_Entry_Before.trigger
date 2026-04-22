trigger Time_Entry_Before on Time_Entry__c(before insert, before update) {
    TimeEntryRateService.applyDefaultsAndRates(Trigger.new, Trigger.oldMap);
}
