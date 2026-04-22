public with sharing class TimeEntryPortalController {
    /**
     * Active projects the running user can read, for Experience / portal pickers.
     */
    @AuraEnabled(cacheable=true)
    public static List<ProjectOption> getProjectOptions(String searchTerm) {
        if (searchTerm == null) {
            searchTerm = '';
        }
        searchTerm = searchTerm.trim();
        String likeTerm = '%' + searchTerm + '%';

        List<Project__c> rows;
        if (String.isBlank(searchTerm)) {
            rows = [
                SELECT Id, Name, Offering__c, Account__r.Name
                FROM Project__c
                WHERE Active__c = TRUE
                ORDER BY Name
                LIMIT 50
            ];
        } else {
            rows = [
                SELECT Id, Name, Offering__c, Account__r.Name
                FROM Project__c
                WHERE
                    Active__c = TRUE
                    AND (Name LIKE :likeTerm OR Account__r.Name LIKE :likeTerm)
                ORDER BY Name
                LIMIT 50
            ];
        }

        List<ProjectOption> out = new List<ProjectOption>();
        for (Project__c p : rows) {
            String acc = p.Account__r == null ? null : p.Account__r.Name;
            out.add(new ProjectOption(p.Id, p.Name, acc, p.Offering__c));
        }
        return out;
    }

    public class ProjectOption {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String accountName;
        @AuraEnabled
        public String offering;

        public ProjectOption(Id id, String name, String accountName, String offering) {
            this.id = id;
            this.name = name;
            this.accountName = accountName;
            this.offering = offering;
        }
    }
}
